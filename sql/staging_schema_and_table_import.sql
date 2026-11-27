CREATE SCHEMA IF NOT EXISTS staging;

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name IN (
      'production_records',
      'oil_gas_fields',
      'wells',
      'production_facilities',
      'equipment',
      'equipment_maintenance',
      'daily_operating_costs',
      'hse_incidents',
      'operators_contractors',
      'date_dimension'
  )
ORDER BY
    CASE table_name
        WHEN 'operators_contractors' THEN 1
        WHEN 'date_dimension' THEN 2
        WHEN 'oil_gas_fields' THEN 3
        WHEN 'production_facilities' THEN 4
        WHEN 'wells' THEN 5
        WHEN 'equipment' THEN 6
        WHEN 'production_records' THEN 7
        WHEN 'equipment_maintenance' THEN 8
        WHEN 'daily_operating_costs' THEN 9
        WHEN 'hse_incidents' THEN 10
    END,
    ordinal_position;

-- Create operators_contractors table
CREATE TABLE staging.operators_contractors (
    operator_id INTEGER,
    company_name VARCHAR(150),
    company_type VARCHAR(100),
    country VARCHAR(100),
    contract_start_date DATE,
    contract_end_date DATE,
    service_category VARCHAR(150),
    contract_value_usd NUMERIC(18,2),
    contract_status VARCHAR(50)
);
-- Import data
INSERT INTO staging.operators_contractors (
    operator_id,
    company_name,
    company_type,
    country,
    contract_start_date,
    contract_end_date,
    service_category,
    contract_value_usd,
    contract_status
)
SELECT
    NULLIF(BTRIM(operator_id), '')::INTEGER,
    NULLIF(BTRIM(company_name), ''),
    NULLIF(BTRIM(company_type), ''),
    NULLIF(BTRIM(country), ''),
    TO_DATE(NULLIF(BTRIM(contract_start_date), ''), 'DD/MM/YYYY'),
    TO_DATE(NULLIF(BTRIM(contract_end_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(service_category), ''),
    NULLIF(BTRIM(contract_value_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(contract_status), '')
FROM raw.operators_contractors;

-- Create dimension table
CREATE TABLE staging.date_dimension (
    date_id INTEGER,
    full_date DATE,
    day INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    quarter VARCHAR(2),
    year INTEGER,
    week_number INTEGER,
    day_name VARCHAR(20),
    weekend_flag BOOLEAN,
    financial_year VARCHAR(20),
    financial_quarter VARCHAR(20)
);
-- Import dimension table
INSERT INTO staging.date_dimension (
    date_id,
    full_date,
    day,
    month,
    month_name,
    quarter,
    year,
    week_number,
    day_name,
    weekend_flag,
    financial_year,
    financial_quarter
)
SELECT
    NULLIF(BTRIM(date_id), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(full_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(day), '')::INTEGER,
    NULLIF(BTRIM(month), '')::INTEGER,
    NULLIF(BTRIM(month_name), ''),
    NULLIF(BTRIM(quarter), ''),
    NULLIF(BTRIM(year), '')::INTEGER,
    NULLIF(BTRIM(week_number), '')::INTEGER,
    NULLIF(BTRIM(day_name), ''),
    CASE
        WHEN LOWER(BTRIM(weekend_flag)) IN ('true', 't', 'yes', 'y', '1')
            THEN TRUE
        WHEN LOWER(BTRIM(weekend_flag)) IN ('false', 'f', 'no', 'n', '0')
            THEN FALSE
        ELSE NULL
    END,
    NULLIF(BTRIM(financial_year), ''),
    NULLIF(BTRIM(financial_quarter), '')
FROM raw.date_dimension;

-- create oil and gas table
CREATE TABLE staging.oil_gas_fields (
    field_id INTEGER,
    field_name VARCHAR(150),
    field_type VARCHAR(100),
    basin VARCHAR(100),
    geographical_region VARCHAR(100),
    country VARCHAR(100),
    discovery_year INTEGER,
    development_year INTEGER,
    field_status VARCHAR(50),
    reservoir_type VARCHAR(100),
    estimated_recoverable_reserves_mmboe NUMERIC(15,2),
    field_operator_id INTEGER,
    water_depth_meters NUMERIC(12,2)
);

-- import oil and gas table
INSERT INTO staging.oil_gas_fields (
    field_id,
    field_name,
    field_type,
    basin,
    geographical_region,
    country,
    discovery_year,
    development_year,
    field_status,
    reservoir_type,
    estimated_recoverable_reserves_mmboe,
    field_operator_id,
    water_depth_meters
)
SELECT
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(field_name), ''),
    NULLIF(BTRIM(field_type), ''),
    NULLIF(BTRIM(basin), ''),
    NULLIF(BTRIM(geographical_region), ''),
    NULLIF(BTRIM(country), ''),
    NULLIF(BTRIM(discovery_year), '')::INTEGER,
    NULLIF(BTRIM(development_year), '')::INTEGER,
    NULLIF(BTRIM(field_status), ''),
    NULLIF(BTRIM(reservoir_type), ''),
    NULLIF(BTRIM(estimated_recoverable_reserves_mmboe), '')::NUMERIC(15,2),
    NULLIF(BTRIM(field_operator_id), '')::INTEGER,
    NULLIF(BTRIM(water_depth_meters), '')::NUMERIC(12,2)
FROM raw.oil_gas_fields;

-- Create production_facilities table
CREATE TABLE staging.production_facilities (
    facility_id INTEGER,
    facility_name VARCHAR(150),
    field_id INTEGER,
    facility_type VARCHAR(100),
    processing_capacity_bopd INTEGER,
    gas_processing_capacity_mmscfd NUMERIC(12,2),
    installation_date DATE,
    operational_status VARCHAR(50),
    location VARCHAR(150),
    facility_manager_id INTEGER
);
-- import production_facilities table
INSERT INTO staging.production_facilities (
    facility_id,
    facility_name,
    field_id,
    facility_type,
    processing_capacity_bopd,
    gas_processing_capacity_mmscfd,
    installation_date,
    operational_status,
    location,
    facility_manager_id
)
SELECT
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    NULLIF(BTRIM(facility_name), ''),
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(facility_type), ''),
    NULLIF(BTRIM(processing_capacity_bopd), '')::INTEGER,
    NULLIF(BTRIM(gas_processing_capacity_mmscfd), '')::NUMERIC(12,2),
    TO_DATE(NULLIF(BTRIM(installation_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(operational_status), ''),
    NULLIF(BTRIM(location), ''),
    NULLIF(BTRIM(facility_manager_id), '')::INTEGER
FROM raw.production_facilities;

-- Create wells table
CREATE TABLE staging.wells (
    well_id INTEGER,
    field_id INTEGER,
    well_name VARCHAR(100),
    well_type VARCHAR(50),
    well_classification VARCHAR(100),
    spud_date DATE,
    completion_date DATE,
    first_production_date DATE,
    total_depth_meters NUMERIC(12,2),
    measured_depth_meters NUMERIC(12,2),
    well_status VARCHAR(50),
    artificial_lift_type VARCHAR(100),
    reservoir_zone VARCHAR(100),
    initial_production_rate_bopd NUMERIC(14,2),
    current_production_rate_bopd NUMERIC(14,2),
    cumulative_oil_production_bbl NUMERIC(18,2),
    water_cut_percentage NUMERIC(7,2)
);
-- import wells table
INSERT INTO staging.wells (
    well_id,
    field_id,
    well_name,
    well_type,
    well_classification,
    spud_date,
    completion_date,
    first_production_date,
    total_depth_meters,
    measured_depth_meters,
    well_status,
    artificial_lift_type,
    reservoir_zone,
    initial_production_rate_bopd,
    current_production_rate_bopd,
    cumulative_oil_production_bbl,
    water_cut_percentage
)
SELECT
    NULLIF(BTRIM(well_id), '')::INTEGER,
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(well_name), ''),
    NULLIF(BTRIM(well_type), ''),
    NULLIF(BTRIM(well_classification), ''),
    TO_DATE(NULLIF(BTRIM(spud_date), ''), 'DD/MM/YYYY'),
    TO_DATE(NULLIF(BTRIM(completion_date), ''), 'DD/MM/YYYY'),
    TO_DATE(NULLIF(BTRIM(first_production_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(total_depth_meters), '')::NUMERIC(12,2),
    NULLIF(BTRIM(measured_depth_meters), '')::NUMERIC(12,2),
    NULLIF(BTRIM(well_status), ''),
    NULLIF(BTRIM(artificial_lift_type), ''),
    NULLIF(BTRIM(reservoir_zone), ''),
    NULLIF(BTRIM(initial_production_rate_bopd), '')::NUMERIC(14,2),
    NULLIF(BTRIM(current_production_rate_bopd), '')::NUMERIC(14,2),
    NULLIF(BTRIM(cumulative_oil_production_bbl), '')::NUMERIC(18,2),
    NULLIF(BTRIM(water_cut_percentage), '')::NUMERIC(7,2)
FROM raw.wells;

-- Create equipment
CREATE TABLE staging.equipment (
    equipment_id INTEGER,
    facility_id INTEGER,
    equipment_name VARCHAR(150),
    equipment_category VARCHAR(100),
    manufacturer VARCHAR(100),
    installation_date DATE,
    expected_lifespan_years NUMERIC(8,2),
    equipment_status VARCHAR(50),
    criticality_level VARCHAR(50),
    replacement_cost_usd NUMERIC(18,2),
    last_maintenance_date DATE,
    operating_hours NUMERIC(14,2),
    equipment_condition VARCHAR(100)
);
-- import equipment table
INSERT INTO staging.equipment (
    equipment_id,
    facility_id,
    equipment_name,
    equipment_category,
    manufacturer,
    installation_date,
    expected_lifespan_years,
    equipment_status,
    criticality_level,
    replacement_cost_usd,
    last_maintenance_date,
    operating_hours,
    equipment_condition
)
SELECT
    NULLIF(BTRIM(equipment_id), '')::INTEGER,
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    NULLIF(BTRIM(equipment_name), ''),
    NULLIF(BTRIM(equipment_category), ''),
    NULLIF(BTRIM(manufacturer), ''),
    TO_DATE(NULLIF(BTRIM(installation_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(expected_lifespan_years), '')::NUMERIC(8,2),
    NULLIF(BTRIM(equipment_status), ''),
    NULLIF(BTRIM(criticality_level), ''),
    NULLIF(BTRIM(replacement_cost_usd), '')::NUMERIC(18,2),
    TO_DATE(NULLIF(BTRIM(last_maintenance_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(operating_hours), '')::NUMERIC(14,2),
    NULLIF(BTRIM(equipment_condition), '')
FROM raw.equipment;

-- Create production_records table
CREATE TABLE staging.production_records (
    production_id INTEGER,
    production_date DATE,
    field_id INTEGER,
    well_id INTEGER,
    facility_id INTEGER,
    operator_id INTEGER,
    crude_oil_produced_bbl NUMERIC(14,2),
    natural_gas_produced_mscf NUMERIC(14,2),
    water_produced_bbl NUMERIC(14,2),
    water_cut_percentage NUMERIC(7,2),
    gas_oil_ratio NUMERIC(14,2),
    production_target_bbl NUMERIC(14,2),
    actual_production_bbl NUMERIC(14,2),
    production_variance_bbl NUMERIC(14,2),
    operating_hours NUMERIC(8,2),
    downtime_hours NUMERIC(8,2),
    downtime_reason VARCHAR(255),
    choke_size NUMERIC(8,2),
    wellhead_pressure_psi NUMERIC(12,2),
    flowline_pressure_psi NUMERIC(12,2),
    reservoir_pressure_psi NUMERIC(12,2),
    temperature_celsius NUMERIC(8,2),
    artificial_lift_type VARCHAR(100),
    production_status VARCHAR(50),
    measurement_method VARCHAR(100),
    recorded_by VARCHAR(100),
    record_timestamp TIMESTAMP,
    source_event_reference VARCHAR(150),
    date_id INTEGER
);
-- Import production_records
INSERT INTO staging.production_records (
    production_id,
    production_date,
    field_id,
    well_id,
    facility_id,
    operator_id,
    crude_oil_produced_bbl,
    natural_gas_produced_mscf,
    water_produced_bbl,
    water_cut_percentage,
    gas_oil_ratio,
    production_target_bbl,
    actual_production_bbl,
    production_variance_bbl,
    operating_hours,
    downtime_hours,
    downtime_reason,
    choke_size,
    wellhead_pressure_psi,
    flowline_pressure_psi,
    reservoir_pressure_psi,
    temperature_celsius,
    artificial_lift_type,
    production_status,
    measurement_method,
    recorded_by,
    record_timestamp,
    source_event_reference,
    date_id
)
SELECT
    NULLIF(BTRIM(production_id), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(production_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(well_id), '')::INTEGER,
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    NULLIF(BTRIM(operator_id), '')::INTEGER,
    NULLIF(BTRIM(crude_oil_produced_bbl), '')::NUMERIC(14,2),
    NULLIF(BTRIM(natural_gas_produced_mscf), '')::NUMERIC(14,2),
    NULLIF(BTRIM(water_produced_bbl), '')::NUMERIC(14,2),
    NULLIF(BTRIM(water_cut_percentage), '')::NUMERIC(7,2),
    NULLIF(BTRIM(gas_oil_ratio), '')::NUMERIC(14,2),
    NULLIF(BTRIM(production_target_bbl), '')::NUMERIC(14,2),
    NULLIF(BTRIM(actual_production_bbl), '')::NUMERIC(14,2),
    NULLIF(BTRIM(production_variance_bbl), '')::NUMERIC(14,2),
    NULLIF(BTRIM(operating_hours), '')::NUMERIC(8,2),
    NULLIF(BTRIM(downtime_hours), '')::NUMERIC(8,2),
    NULLIF(BTRIM(downtime_reason), ''),
    NULLIF(BTRIM(choke_size), '')::NUMERIC(8,2),
    NULLIF(BTRIM(wellhead_pressure_psi), '')::NUMERIC(12,2),
    NULLIF(BTRIM(flowline_pressure_psi), '')::NUMERIC(12,2),
    NULLIF(BTRIM(reservoir_pressure_psi), '')::NUMERIC(12,2),
    NULLIF(BTRIM(temperature_celsius), '')::NUMERIC(8,2),
    NULLIF(BTRIM(artificial_lift_type), ''),
    NULLIF(BTRIM(production_status), ''),
    NULLIF(BTRIM(measurement_method), ''),
    NULLIF(BTRIM(recorded_by), ''),
    CASE
        WHEN NULLIF(BTRIM(record_timestamp), '') IS NULL THEN NULL
        WHEN BTRIM(record_timestamp) ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}'
            THEN TO_TIMESTAMP(BTRIM(record_timestamp), 'DD/MM/YYYY HH24:MI:SS')
        ELSE BTRIM(record_timestamp)::TIMESTAMP
    END,
    NULLIF(BTRIM(source_event_reference), ''),
    NULLIF(BTRIM(date_id), '')::INTEGER
FROM raw.production_records;

-- Create equipment_maintenance table
CREATE TABLE staging.equipment_maintenance (
    maintenance_id INTEGER,
    equipment_id INTEGER,
    facility_id INTEGER,
    maintenance_date DATE,
    equipment_category VARCHAR(100),
    equipment_name VARCHAR(150),
    maintenance_type VARCHAR(100),
    failure_category VARCHAR(100),
    failure_description TEXT,
    downtime_hours NUMERIC(10,2),
    repair_duration_hours NUMERIC(10,2),
    maintenance_cost_usd NUMERIC(18,2),
    spare_parts_cost_usd NUMERIC(18,2),
    labour_cost_usd NUMERIC(18,2),
    maintenance_priority VARCHAR(50),
    maintenance_status VARCHAR(50),
    next_scheduled_maintenance_date DATE,
    source_work_order_reference VARCHAR(150),
    maintenance_start_timestamp TIMESTAMP,
    maintenance_completion_timestamp TIMESTAMP
);
-- Import equipment_maintenance
INSERT INTO staging.equipment_maintenance (
    maintenance_id,
    equipment_id,
    facility_id,
    maintenance_date,
    equipment_category,
    equipment_name,
    maintenance_type,
    failure_category,
    failure_description,
    downtime_hours,
    repair_duration_hours,
    maintenance_cost_usd,
    spare_parts_cost_usd,
    labour_cost_usd,
    maintenance_priority,
    maintenance_status,
    next_scheduled_maintenance_date,
    source_work_order_reference,
    maintenance_start_timestamp,
    maintenance_completion_timestamp
)
SELECT
    NULLIF(BTRIM(maintenance_id), '')::INTEGER,
    NULLIF(BTRIM(equipment_id), '')::INTEGER,
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(maintenance_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(equipment_category), ''),
    NULLIF(BTRIM(equipment_name), ''),
    NULLIF(BTRIM(maintenance_type), ''),
    NULLIF(BTRIM(failure_category), ''),
    NULLIF(BTRIM(failure_description), ''),
    NULLIF(BTRIM(downtime_hours), '')::NUMERIC(10,2),
    NULLIF(BTRIM(repair_duration_hours), '')::NUMERIC(10,2),
    NULLIF(BTRIM(maintenance_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(spare_parts_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(labour_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(maintenance_priority), ''),
    NULLIF(BTRIM(maintenance_status), ''),
    TO_DATE(NULLIF(BTRIM(next_scheduled_maintenance_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(source_work_order_reference), ''),
    CASE
        WHEN NULLIF(BTRIM(maintenance_start_timestamp), '') IS NULL THEN NULL
        WHEN BTRIM(maintenance_start_timestamp) ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}'
            THEN TO_TIMESTAMP(BTRIM(maintenance_start_timestamp), 'DD/MM/YYYY HH24:MI:SS')
        ELSE BTRIM(maintenance_start_timestamp)::TIMESTAMP
    END,
    CASE
        WHEN NULLIF(BTRIM(maintenance_completion_timestamp), '') IS NULL THEN NULL
        WHEN BTRIM(maintenance_completion_timestamp) ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}'
            THEN TO_TIMESTAMP(BTRIM(maintenance_completion_timestamp), 'DD/MM/YYYY HH24:MI:SS')
        ELSE BTRIM(maintenance_completion_timestamp)::TIMESTAMP
    END
FROM raw.equipment_maintenance;

-- Create daily_operating_costs table
CREATE TABLE staging.daily_operating_costs (
    cost_id INTEGER,
    transaction_date DATE,
    field_id INTEGER,
    facility_id INTEGER,
    cost_category VARCHAR(100),
    cost_description TEXT,
    labour_cost_usd NUMERIC(18,2),
    maintenance_cost_usd NUMERIC(18,2),
    logistics_cost_usd NUMERIC(18,2),
    energy_cost_usd NUMERIC(18,2),
    chemicals_cost_usd NUMERIC(18,2),
    transportation_cost_usd NUMERIC(18,2),
    other_operating_cost_usd NUMERIC(18,2),
    total_operating_cost_usd NUMERIC(18,2),
    budgeted_cost_usd NUMERIC(18,2),
    cost_variance_usd NUMERIC(18,2),
    currency VARCHAR(10),
    date_id INTEGER
);
-- Import daily_operating_costs
INSERT INTO staging.daily_operating_costs (
    cost_id,
    transaction_date,
    field_id,
    facility_id,
    cost_category,
    cost_description,
    labour_cost_usd,
    maintenance_cost_usd,
    logistics_cost_usd,
    energy_cost_usd,
    chemicals_cost_usd,
    transportation_cost_usd,
    other_operating_cost_usd,
    total_operating_cost_usd,
    budgeted_cost_usd,
    cost_variance_usd,
    currency,
    date_id
)
SELECT
    NULLIF(BTRIM(cost_id), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(transaction_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    NULLIF(BTRIM(cost_category), ''),
    NULLIF(BTRIM(cost_description), ''),
    NULLIF(BTRIM(labour_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(maintenance_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(logistics_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(energy_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(chemicals_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(transportation_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(other_operating_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(total_operating_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(budgeted_cost_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(cost_variance_usd), '')::NUMERIC(18,2),
    NULLIF(BTRIM(currency), ''),
    NULLIF(BTRIM(date_id), '')::INTEGER
FROM raw.daily_operating_costs;

-- Create hse_incidents table
CREATE TABLE staging.hse_incidents (
    incident_id INTEGER,
    incident_date DATE,
    field_id INTEGER,
    facility_id INTEGER,
    incident_category VARCHAR(100),
    incident_description TEXT,
    severity_level VARCHAR(50),
    injury_count INTEGER,
    environmental_impact VARCHAR(100),
    spill_volume_litres NUMERIC(14,2),
    lost_time_injury BOOLEAN,
    regulatory_reportable BOOLEAN,
    incident_status VARCHAR(50),
    resolution_date DATE,
    source_incident_reference VARCHAR(150),
    date_id INTEGER
);
-- Import hse_incidents
INSERT INTO staging.hse_incidents (
    incident_id,
    incident_date,
    field_id,
    facility_id,
    incident_category,
    incident_description,
    severity_level,
    injury_count,
    environmental_impact,
    spill_volume_litres,
    lost_time_injury,
    regulatory_reportable,
    incident_status,
    resolution_date,
    source_incident_reference,
    date_id
)
SELECT
    NULLIF(BTRIM(incident_id), '')::INTEGER,
    TO_DATE(NULLIF(BTRIM(incident_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(field_id), '')::INTEGER,
    NULLIF(BTRIM(facility_id), '')::INTEGER,
    NULLIF(BTRIM(incident_category), ''),
    NULLIF(BTRIM(incident_description), ''),
    NULLIF(BTRIM(severity_level), ''),
    NULLIF(BTRIM(injury_count), '')::INTEGER,
    NULLIF(BTRIM(environmental_impact), ''),
    NULLIF(BTRIM(spill_volume_litres), '')::NUMERIC(14,2),
    CASE
        WHEN LOWER(BTRIM(lost_time_injury)) IN ('true', 't', 'yes', 'y', '1')
            THEN TRUE
        WHEN LOWER(BTRIM(lost_time_injury)) IN ('false', 'f', 'no', 'n', '0')
            THEN FALSE
        ELSE NULL
    END,
    CASE
        WHEN LOWER(BTRIM(regulatory_reportable)) IN ('true', 't', 'yes', 'y', '1')
            THEN TRUE
        WHEN LOWER(BTRIM(regulatory_reportable)) IN ('false', 'f', 'no', 'n', '0')
            THEN FALSE
        ELSE NULL
    END,
    NULLIF(BTRIM(incident_status), ''),
    TO_DATE(NULLIF(BTRIM(resolution_date), ''), 'DD/MM/YYYY'),
    NULLIF(BTRIM(source_incident_reference), ''),
    NULLIF(BTRIM(date_id), '')::INTEGER
FROM raw.hse_incidents;


-- Verify tables
SELECT 'operators_contractors' AS table_name, COUNT(*) AS total_records
FROM staging.operators_contractors
UNION ALL
SELECT 'date_dimension', COUNT(*)
FROM staging.date_dimension
UNION ALL
SELECT 'oil_gas_fields', COUNT(*)
FROM staging.oil_gas_fields
UNION ALL
SELECT 'production_facilities', COUNT(*)
FROM staging.production_facilities
UNION ALL
SELECT 'wells', COUNT(*)
FROM staging.wells
UNION ALL
SELECT 'equipment', COUNT(*)
FROM staging.equipment
UNION ALL
SELECT 'production_records', COUNT(*)
FROM staging.production_records
UNION ALL
SELECT 'equipment_maintenance', COUNT(*)
FROM staging.equipment_maintenance
UNION ALL
SELECT 'daily_operating_costs', COUNT(*)
FROM staging.daily_operating_costs
UNION ALL
SELECT 'hse_incidents', COUNT(*)
FROM staging.hse_incidents
ORDER BY table_name;