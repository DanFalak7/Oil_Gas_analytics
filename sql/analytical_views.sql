		-- CREATE ANALYTICAL VIEWS --

-- Daily Production Performance
CREATE VIEW analytics.vw_production_daily AS
SELECT
    pr.production_date,
    pr.field_id,
    f.field_name,
    pr.facility_id,
    pf.facility_name,
    COUNT(*) AS production_records,
    COUNT(DISTINCT pr.well_id) AS active_wells,
    SUM(pr.crude_oil_produced_bbl) AS total_oil_produced_bbl,
    SUM(pr.natural_gas_produced_mscf) AS total_gas_produced_mscf,
    SUM(pr.water_produced_bbl) AS total_water_produced_bbl,
    SUM(pr.production_target_bbl) AS total_production_target_bbl,
    SUM(pr.actual_production_bbl) AS total_actual_production_bbl,
    SUM(pr.production_variance_bbl) AS total_production_variance_bbl,
    ROUND(
        SUM(pr.actual_production_bbl)
        / NULLIF(SUM(pr.production_target_bbl), 0) * 100,
        2 ) AS production_target_achievement_pct,
    ROUND(
        SUM(pr.water_produced_bbl)
        / NULLIF(SUM(pr.crude_oil_produced_bbl)
            + SUM(pr.water_produced_bbl), 0) * 100,
		2 ) AS weighted_water_cut_pct,
    SUM(pr.operating_hours) AS total_operating_hours,
    SUM(pr.downtime_hours) AS total_downtime_hours
FROM analytics.production_records pr
LEFT JOIN analytics.oil_gas_fields f
    USING(field_id)
LEFT JOIN analytics.production_facilities pf
    USING(facility_id)
GROUP BY
    pr.production_date,
    pr.field_id,
    f.field_name,
    pr.facility_id,
    pf.facility_name;


-- Well Production Performance
CREATE VIEW analytics.vw_well_performance AS
SELECT
    w.well_id,
    w.well_name,
    w.field_id,
    f.field_name,
    w.well_type,
    w.well_classification,
    w.well_status,
    w.artificial_lift_type,
    w.initial_production_rate_bopd,
    w.current_production_rate_bopd,
    COUNT(pr.production_id) AS production_records,
    COUNT(DISTINCT pr.production_date) AS production_days,
    SUM(pr.crude_oil_produced_bbl) AS total_oil_produced_bbl,
    SUM(pr.natural_gas_produced_mscf) AS total_gas_produced_mscf,
    SUM(pr.water_produced_bbl) AS total_water_produced_bbl,
    -- Average per production record; this is not necessarily a calendar-day average
    -- when a well has multiple records on the same date.
    ROUND(AVG(pr.actual_production_bbl), 2) AS average_daily_actual_production_bbl,
    ROUND(
        SUM(pr.water_produced_bbl)
        / NULLIF(
            SUM(pr.crude_oil_produced_bbl)
            + SUM(pr.water_produced_bbl), 0 )
        * 100, 2 ) AS weighted_water_cut_pct,
    SUM(pr.operating_hours) AS total_operating_hours,
    SUM(pr.downtime_hours) AS total_downtime_hours
FROM analytics.wells w
LEFT JOIN analytics.oil_gas_fields f
    USING(field_id)
LEFT JOIN analytics.production_records pr
    USING(well_id)
GROUP BY
    w.well_id,
    w.well_name,
    w.field_id,
    f.field_name,
    w.well_type,
    w.well_classification,
    w.well_status,
    w.artificial_lift_type,
    w.initial_production_rate_bopd,
    w.current_production_rate_bopd;


-- Facility production performance
CREATE VIEW analytics.vw_facility_performance AS
SELECT
    pf.facility_id,
    pf.facility_name,
    pf.field_id,
    f.field_name,
    pf.facility_type,
    pf.operational_status,
    pf.processing_capacity_bopd,
    pf.gas_processing_capacity_mmscfd,
    COUNT(DISTINCT pr.production_date) AS production_days,
    COUNT(DISTINCT pr.well_id) AS wells_recorded,
    SUM(pr.crude_oil_produced_bbl) AS total_oil_produced_bbl,
    SUM(pr.natural_gas_produced_mscf) AS total_gas_produced_mscf,
    SUM(pr.water_produced_bbl) AS total_water_produced_bbl,
    SUM(pr.operating_hours) AS total_operating_hours,
    SUM(pr.downtime_hours) AS total_downtime_hours
FROM analytics.production_facilities pf
LEFT JOIN analytics.oil_gas_fields f
    ON pf.field_id = f.field_id
LEFT JOIN analytics.production_records pr
    ON pf.facility_id = pr.facility_id
GROUP BY
    pf.facility_id,
    pf.facility_name,
    pf.field_id,
    f.field_name,
    pf.facility_type,
    pf.operational_status,
    pf.processing_capacity_bopd,
    pf.gas_processing_capacity_mmscfd;

-- Equipment maintenance performance
CREATE VIEW analytics.vw_maintenance_performance AS
SELECT
    e.equipment_id,
    e.equipment_name,
    e.equipment_category,
    e.equipment_status,
    e.criticality_level,
    e.equipment_condition,
    pf.facility_id,
    pf.facility_name,
    COUNT(m.maintenance_id) AS total_maintenance_records,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(m.maintenance_type) = 'corrective'
    	) AS corrective_maintenance_records,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(m.maintenance_type) = 'preventive'
    	) AS preventive_maintenance_records,
    SUM(m.downtime_hours) AS total_maintenance_downtime_hours,
    SUM(m.repair_duration_hours) AS total_repair_duration_hours,
    SUM(m.maintenance_cost_usd) AS total_maintenance_cost_usd,
    SUM(m.spare_parts_cost_usd) AS total_spare_parts_cost_usd,
    SUM(m.labour_cost_usd) AS total_labour_cost_usd,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(m.maintenance_status) = 'completed'
    	) AS completed_maintenance_records,
    COUNT(*) FILTER (
        WHERE m.failure_category IS NOT NULL
    ) AS records_with_failure_category
FROM analytics.equipment e
LEFT JOIN analytics.production_facilities pf
    ON e.facility_id = pf.facility_id
LEFT JOIN analytics.equipment_maintenance m
    ON e.equipment_id = m.equipment_id
GROUP BY
    e.equipment_id,
    e.equipment_name,
    e.equipment_category,
    e.equipment_status,
    e.criticality_level,
    e.equipment_condition,
    pf.facility_id,
    pf.facility_name;

--Operating costs and budget performance
CREATE VIEW analytics.vw_operating_costs AS
SELECT
    c.transaction_date,
    c.date_id,
    c.field_id,
    f.field_name,
    c.facility_id,
    pf.facility_name,
    c.cost_category,
    c.currency,
    COUNT(*) AS cost_records,
    SUM(c.labour_cost_usd) AS total_labour_cost_usd,
    SUM(c.maintenance_cost_usd) AS total_maintenance_cost_usd,
    SUM(c.logistics_cost_usd) AS total_logistics_cost_usd,
    SUM(c.energy_cost_usd) AS total_energy_cost_usd,
    SUM(c.chemicals_cost_usd) AS total_chemicals_cost_usd,
    SUM(c.transportation_cost_usd) AS total_transportation_cost_usd,
    SUM(c.other_operating_cost_usd) AS total_other_operating_cost_usd,
    SUM(c.total_operating_cost_usd) AS total_operating_cost_usd,
    SUM(c.budgeted_cost_usd) AS total_budgeted_cost_usd,
    SUM(c.cost_variance_usd) AS total_cost_variance_usd,
    COUNT(*) 
		FILTER (
        	WHERE c.total_operating_cost_usd IS NULL
    	) AS records_missing_total_cost
FROM analytics.daily_operating_costs c
LEFT JOIN analytics.oil_gas_fields f
    ON c.field_id = f.field_id
LEFT JOIN analytics.production_facilities pf
    ON c.facility_id = pf.facility_id
GROUP BY
    c.transaction_date,
    c.date_id,
    c.field_id,
    f.field_name,
    c.facility_id,
    pf.facility_name,
    c.cost_category,
    c.currency;

-- HSE performance
CREATE VIEW analytics.vw_hse_performance AS
SELECT
    h.incident_date,
    h.date_id,
    h.field_id,
    f.field_name,
    h.facility_id,
    pf.facility_name,
    COUNT(h.incident_id) AS total_incidents,
    SUM(h.injury_count) AS total_injuries,
    COUNT(*) 
		FILTER (
        	WHERE h.lost_time_injury IS TRUE
    	) AS lost_time_incident_count,
    COUNT(*) 
		FILTER (
        	WHERE h.regulatory_reportable IS TRUE
    	) AS regulatory_reportable_incidents,
    SUM(h.spill_volume_litres) AS total_spill_volume_litres,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(h.severity_level) = 'high'
    	) AS high_severity_incidents,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(h.severity_level) = 'medium'
    	) AS medium_severity_incidents,
    COUNT(*) 
		FILTER (
        	WHERE LOWER(h.severity_level) = 'low'
    	) AS low_severity_incidents
FROM analytics.hse_incidents h
LEFT JOIN analytics.oil_gas_fields f
    ON h.field_id = f.field_id
LEFT JOIN analytics.production_facilities pf
    ON h.facility_id = pf.facility_id
GROUP BY
    h.incident_date,
    h.date_id,
    h.field_id,
    f.field_name,
    h.facility_id,
    pf.facility_name;


-- maintenance_event_detail
CREATE OR REPLACE VIEW analytics.vw_maintenance_event_detail AS
SELECT
    m.maintenance_id,
    m.equipment_id,
    e.equipment_name,
    e.equipment_category,
    e.installation_date,
    e.expected_lifespan_years,
    e.equipment_status,
    e.criticality_level,
    e.equipment_condition,
    e.replacement_cost_usd,
    e.operating_hours,
    m.facility_id,
    pf.facility_name,
    m.maintenance_date,
    m.maintenance_type,
    m.maintenance_status,
    m.failure_category,
    m.failure_description,
    m.maintenance_priority,
    m.downtime_hours,
    m.repair_duration_hours,
    m.maintenance_cost_usd,
    m.spare_parts_cost_usd,
    m.labour_cost_usd,
    m.next_scheduled_maintenance_date,
    m.maintenance_start_timestamp,
    m.maintenance_completion_timestamp
FROM analytics.equipment_maintenance m
LEFT JOIN analytics.equipment e
    ON m.equipment_id = e.equipment_id
LEFT JOIN analytics.production_facilities pf
    ON m.facility_id = pf.facility_id;


SELECT COUNT(*)
FROM analytics.vw_maintenance_performance;