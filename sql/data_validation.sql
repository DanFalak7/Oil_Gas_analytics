-- Validate Existing Calculations --
-- Validate production variance

SELECT production_id, 
        production_variance_bbl,
        actual_production_bbl - production_target_bbl AS calculated_variance
FROM staging.production_records
WHERE production_target_bbl IS NOT NULL
  AND actual_production_bbl IS NOT NULL
  AND (
      production_variance_bbl IS NULL
      OR ABS(production_variance_bbl -
             (actual_production_bbl - production_target_bbl)) > 0.01
  ) -- tolerance for rounding differences; NULL calculated values are also reported
ORDER BY 1;

-- Update Variance calculation

UPDATE staging.production_records
SET production_variance_bbl = actual_production_bbl - production_target_bbl
WHERE production_target_bbl IS NOT NULL
  AND actual_production_bbl IS NOT NULL
  AND (
      production_variance_bbl IS NULL
      OR ABS(production_variance_bbl -
             (actual_production_bbl - production_target_bbl)) > 0.01
  );

-- Validate water cut percentage
SELECT
    production_id,
    water_cut_percentage,
    ROUND( ( water_produced_bbl /
            NULLIF( crude_oil_produced_bbl + water_produced_bbl,
                0 )
        ) * 100, 2) AS calculated_water_cut
FROM staging.production_records
WHERE crude_oil_produced_bbl IS NOT NULL
  AND water_produced_bbl IS NOT NULL
  AND crude_oil_produced_bbl + water_produced_bbl > 0
  AND (
      water_cut_percentage IS NULL
      OR ABS(water_cut_percentage -
          (water_produced_bbl /
           NULLIF(crude_oil_produced_bbl + water_produced_bbl, 0) * 100)
      ) > 0.5
  )
ORDER BY production_date;

-- Update water_cut_percentage
UPDATE staging.production_records
SET water_cut_percentage =
    ROUND( ( water_produced_bbl /
            NULLIF( crude_oil_produced_bbl + water_produced_bbl,
                0 )
        ) * 100, 2)
WHERE crude_oil_produced_bbl IS NOT NULL
  AND water_produced_bbl IS NOT NULL
  AND crude_oil_produced_bbl + water_produced_bbl > 0
  AND ABS(
      water_cut_percentage -
      ( water_produced_bbl /
          NULLIF(
              crude_oil_produced_bbl + water_produced_bbl,
              0 ) * 100
      ) ) > 0.5;


-- Validate total operating costs
SELECT
    cost_id,
    total_operating_cost_usd,
    (
        COALESCE(labour_cost_usd, 0) +
        COALESCE(maintenance_cost_usd, 0) +
        COALESCE(logistics_cost_usd, 0) +
        COALESCE(energy_cost_usd, 0) +
        COALESCE(chemicals_cost_usd, 0) +
        COALESCE(transportation_cost_usd, 0) +
        COALESCE(other_operating_cost_usd, 0)
    ) AS calculated_total_cost
FROM staging.daily_operating_costs
WHERE total_operating_cost_usd IS NOT NULL
  AND ABS(
      total_operating_cost_usd -
      (
          COALESCE(labour_cost_usd, 0) +
          COALESCE(maintenance_cost_usd, 0) +
          COALESCE(logistics_cost_usd, 0) +
          COALESCE(energy_cost_usd, 0) +
          COALESCE(chemicals_cost_usd, 0) +
          COALESCE(transportation_cost_usd, 0) +
          COALESCE(other_operating_cost_usd, 0)
      )
  ) > 0.02 -- increased the threshold because of multiple approximated columns
ORDER BY transaction_date;

-- Validate cost_variance
SELECT
    cost_id,
    cost_variance_usd,
    total_operating_cost_usd - budgeted_cost_usd
        AS calculated_cost_variance
FROM staging.daily_operating_costs
WHERE total_operating_cost_usd IS NOT NULL
  AND budgeted_cost_usd IS NOT NULL
  AND cost_variance_usd IS NOT NULL
  AND ABS(
      cost_variance_usd -
      (total_operating_cost_usd - budgeted_cost_usd)
  ) > 0.01
ORDER BY transaction_date;

-- Validate Date Dimension Attributes

WITH date_cte AS (
SELECT
    date_id,
    full_date,
    day,
    EXTRACT(DAY FROM full_date) AS expected_day,
    month,
    EXTRACT(MONTH FROM full_date) AS expected_month,
    quarter,
    CASE EXTRACT(QUARTER FROM full_date)
            WHEN 1 THEN 'Q1'
            WHEN 2 THEN 'Q2'
            WHEN 3 THEN 'Q3'
            ELSE 'Q4' 
    END AS expected_quarter,
    year,
    EXTRACT(YEAR FROM full_date) AS expected_year,
    month_name,
    TO_CHAR(full_date, 'FMMonth') AS expected_month_name,
    day_name,
    TO_CHAR(full_date, 'FMDay') AS expected_day_name
FROM staging.date_dimension
WHERE day IS DISTINCT FROM EXTRACT(DAY FROM full_date)::INTEGER
   OR month IS DISTINCT FROM EXTRACT(MONTH FROM full_date)::INTEGER
   OR year IS DISTINCT FROM EXTRACT(YEAR FROM full_date)::INTEGER
   OR LOWER(BTRIM(month_name)) IS DISTINCT FROM LOWER(TO_CHAR(full_date, 'FMMonth'))
   OR LOWER(BTRIM(day_name)) IS DISTINCT FROM LOWER(TO_CHAR(full_date, 'FMDay'))
   OR quarter IS DISTINCT FROM
      CASE EXTRACT(QUARTER FROM full_date)
          WHEN 1 THEN 'Q1' WHEN 2 THEN 'Q2'
          WHEN 3 THEN 'Q3' ELSE 'Q4'
      END
)
SELECT *
FROM date_cte
ORDER BY full_date;

-- Validate Production Operating Hours and Downtime
SELECT
    production_id,
    production_date,
    well_id,
    operating_hours,
    downtime_hours,
    operating_hours + downtime_hours AS total_hours
FROM staging.production_records
WHERE operating_hours < 0
   OR downtime_hours < 0
   OR operating_hours > 24
   OR downtime_hours > 24
   OR operating_hours + downtime_hours > 24.01
ORDER BY production_date;

-- Validate Maintenance Cost Components
SELECT
    maintenance_id,
    equipment_id,
    maintenance_cost_usd,
    spare_parts_cost_usd,
    labour_cost_usd,
    COALESCE(spare_parts_cost_usd, 0) +
    COALESCE(labour_cost_usd, 0) AS calculated_cost
FROM staging.equipment_maintenance
WHERE maintenance_cost_usd IS NOT NULL
  AND spare_parts_cost_usd IS NOT NULL
  AND labour_cost_usd IS NOT NULL
  AND ABS(
      maintenance_cost_usd -
      (spare_parts_cost_usd + labour_cost_usd)
  ) > 0.01;

-- Update maintenance cost
UPDATE staging.equipment_maintenance
SET maintenance_cost_usd =
    spare_parts_cost_usd + labour_cost_usd
WHERE maintenance_cost_usd IS NOT NULL
  AND spare_parts_cost_usd IS NOT NULL
  AND labour_cost_usd IS NOT NULL
  AND ABS(
      maintenance_cost_usd -
      (spare_parts_cost_usd + labour_cost_usd)
  ) > 0.01;

-- Validate wells completion_date/spud_date and first_production/completion_date
SELECT
    well_id,
    well_name,
    spud_date,
    completion_date,
    first_production_date
FROM staging.wells
WHERE (completion_date < spud_date)
   OR (first_production_date < completion_date);

-- Validate HSE incident date
SELECT
    incident_id,
    incident_date,
    resolution_date,
    incident_status
FROM staging.hse_incidents
WHERE resolution_date < incident_date;
