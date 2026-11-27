		-- Create Analytics Scehma and Tables --

-- Create schema with tables and their primary keys
BEGIN;

CREATE SCHEMA IF NOT EXISTS analytics;

-- 1. Operators and contractors
CREATE TABLE analytics.operators_contractors (
    LIKE staging.operators_contractors,
    CONSTRAINT pk_operators_contractors
        PRIMARY KEY (operator_id)
);

-- 2. Date dimension
CREATE TABLE analytics.date_dimension (
    LIKE staging.date_dimension,
    CONSTRAINT pk_date_dimension
        PRIMARY KEY (date_id),
    CONSTRAINT uq_date_dimension_full_date
        UNIQUE (full_date)
);

-- 3. Oil and gas fields
CREATE TABLE analytics.oil_gas_fields (
    LIKE staging.oil_gas_fields,
    CONSTRAINT pk_oil_gas_fields
        PRIMARY KEY (field_id)
);

-- 4. Production facilities
CREATE TABLE analytics.production_facilities (
    LIKE staging.production_facilities,
    CONSTRAINT pk_production_facilities
        PRIMARY KEY (facility_id)
);

-- 5. Wells
CREATE TABLE analytics.wells (
    LIKE staging.wells,
    CONSTRAINT pk_wells
        PRIMARY KEY (well_id)
);

-- 6. Equipment
CREATE TABLE analytics.equipment (
    LIKE staging.equipment,
    CONSTRAINT pk_equipment
        PRIMARY KEY (equipment_id)
);

-- 7. Production records
CREATE TABLE analytics.production_records (
    LIKE staging.production_records,
    CONSTRAINT pk_production_records
        PRIMARY KEY (production_id)
);

-- 8. Equipment maintenance
CREATE TABLE analytics.equipment_maintenance (
    LIKE staging.equipment_maintenance,
    CONSTRAINT pk_equipment_maintenance
        PRIMARY KEY (maintenance_id)
);

-- 9. Daily operating costs
CREATE TABLE analytics.daily_operating_costs (
    LIKE staging.daily_operating_costs,
    CONSTRAINT pk_daily_operating_costs
        PRIMARY KEY (cost_id)
);

-- 10. HSE incidents
CREATE TABLE analytics.hse_incidents (
    LIKE staging.hse_incidents,
    CONSTRAINT pk_hse_incidents
        PRIMARY KEY (incident_id)
);

COMMIT;

-- Add foreign key constraints
BEGIN;

-- Oil and gas fields → Operators and contractors
ALTER TABLE analytics.oil_gas_fields
ADD CONSTRAINT fk_fields_operator
FOREIGN KEY (field_operator_id)
REFERENCES analytics.operators_contractors (operator_id);

-- Production facilities → Oil and gas fields
ALTER TABLE analytics.production_facilities
ADD CONSTRAINT fk_facilities_field
FOREIGN KEY (field_id)
REFERENCES analytics.oil_gas_fields (field_id);

-- Wells → Oil and gas fields
ALTER TABLE analytics.wells
ADD CONSTRAINT fk_wells_field
FOREIGN KEY (field_id)
REFERENCES analytics.oil_gas_fields (field_id);

-- Equipment → Production facilities
ALTER TABLE analytics.equipment
ADD CONSTRAINT fk_equipment_facility
FOREIGN KEY (facility_id)
REFERENCES analytics.production_facilities (facility_id);

-- Production records → Related tables
ALTER TABLE analytics.production_records
ADD CONSTRAINT fk_production_field
FOREIGN KEY (field_id)
REFERENCES analytics.oil_gas_fields (field_id);

ALTER TABLE analytics.production_records
ADD CONSTRAINT fk_production_well
FOREIGN KEY (well_id)
REFERENCES analytics.wells (well_id);

ALTER TABLE analytics.production_records
ADD CONSTRAINT fk_production_facility
FOREIGN KEY (facility_id)
REFERENCES analytics.production_facilities (facility_id);

ALTER TABLE analytics.production_records
ADD CONSTRAINT fk_production_operator
FOREIGN KEY (operator_id)
REFERENCES analytics.operators_contractors (operator_id);

ALTER TABLE analytics.production_records
ADD CONSTRAINT fk_production_date
FOREIGN KEY (date_id)
REFERENCES analytics.date_dimension (date_id);

-- Equipment maintenance → Equipment and facilities
ALTER TABLE analytics.equipment_maintenance
ADD CONSTRAINT fk_maintenance_equipment
FOREIGN KEY (equipment_id)
REFERENCES analytics.equipment (equipment_id);

ALTER TABLE analytics.equipment_maintenance
ADD CONSTRAINT fk_maintenance_facility
FOREIGN KEY (facility_id)
REFERENCES analytics.production_facilities (facility_id);

-- Daily operating costs → Related tables
ALTER TABLE analytics.daily_operating_costs
ADD CONSTRAINT fk_costs_field
FOREIGN KEY (field_id)
REFERENCES analytics.oil_gas_fields (field_id);

ALTER TABLE analytics.daily_operating_costs
ADD CONSTRAINT fk_costs_facility
FOREIGN KEY (facility_id)
REFERENCES analytics.production_facilities (facility_id);

ALTER TABLE analytics.daily_operating_costs
ADD CONSTRAINT fk_costs_date
FOREIGN KEY (date_id)
REFERENCES analytics.date_dimension (date_id);

-- HSE incidents → Related tables
ALTER TABLE analytics.hse_incidents
ADD CONSTRAINT fk_hse_field
FOREIGN KEY (field_id)
REFERENCES analytics.oil_gas_fields (field_id);

ALTER TABLE analytics.hse_incidents
ADD CONSTRAINT fk_hse_facility
FOREIGN KEY (facility_id)
REFERENCES analytics.production_facilities (facility_id);

ALTER TABLE analytics.hse_incidents
ADD CONSTRAINT fk_hse_date
FOREIGN KEY (date_id)
REFERENCES analytics.date_dimension (date_id);

COMMIT;

-- Verify tables creation
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'analytics'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify primary and foreign key constraints
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema
LEFT JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
   AND tc.constraint_schema = ccu.constraint_schema
WHERE tc.constraint_schema = 'analytics'
  AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;


-- Insert data into the tables
BEGIN;

-- =====================================================
-- 1. OPERATORS AND CONTRACTORS
-- =====================================================

INSERT INTO analytics.operators_contractors (
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
    operator_id,
    company_name,
    company_type,
    country,
    contract_start_date,
    contract_end_date,
    service_category,
    contract_value_usd,
    contract_status
FROM staging.operators_contractors;


-- =====================================================
-- 2. DATE DIMENSION
-- =====================================================

INSERT INTO analytics.date_dimension (
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
FROM staging.date_dimension;


-- =====================================================
-- 3. OIL AND GAS FIELDS
-- =====================================================

INSERT INTO analytics.oil_gas_fields (
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
FROM staging.oil_gas_fields;


-- =====================================================
-- 4. PRODUCTION FACILITIES
-- =====================================================

INSERT INTO analytics.production_facilities (
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
FROM staging.production_facilities;


-- =====================================================
-- 5. WELLS
-- =====================================================

INSERT INTO analytics.wells (
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
FROM staging.wells;


-- =====================================================
-- 6. EQUIPMENT
-- =====================================================

INSERT INTO analytics.equipment (
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
FROM staging.equipment;


-- =====================================================
-- 7. PRODUCTION RECORDS
-- =====================================================

INSERT INTO analytics.production_records (
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
FROM staging.production_records;


-- =====================================================
-- 8. EQUIPMENT MAINTENANCE
-- =====================================================

INSERT INTO analytics.equipment_maintenance (
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
FROM staging.equipment_maintenance;


-- =====================================================
-- 9. DAILY OPERATING COSTS
-- =====================================================

INSERT INTO analytics.daily_operating_costs (
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
FROM staging.daily_operating_costs;


-- =====================================================
-- 10. HSE INCIDENTS
-- =====================================================

INSERT INTO analytics.hse_incidents (
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
FROM staging.hse_incidents;


COMMIT;

-- Verify the loaded data
SELECT 'operators_contractors' AS table_name, COUNT(*) AS total_records
FROM analytics.operators_contractors
UNION ALL
SELECT 'date_dimension', COUNT(*) FROM analytics.date_dimension
UNION ALL
SELECT 'oil_gas_fields', COUNT(*) FROM analytics.oil_gas_fields
UNION ALL
SELECT 'production_facilities', COUNT(*) FROM analytics.production_facilities
UNION ALL
SELECT 'wells', COUNT(*) FROM analytics.wells
UNION ALL
SELECT 'equipment', COUNT(*) FROM analytics.equipment
UNION ALL
SELECT 'production_records', COUNT(*) FROM analytics.production_records
UNION ALL
SELECT 'equipment_maintenance', COUNT(*) FROM analytics.equipment_maintenance
UNION ALL
SELECT 'daily_operating_costs', COUNT(*) FROM analytics.daily_operating_costs
UNION ALL
SELECT 'hse_incidents', COUNT(*) FROM analytics.hse_incidents
UNION ALL
SELECT 'TOTAL', SUM(total_records)
FROM (
    SELECT COUNT(*) AS total_records FROM analytics.operators_contractors
    UNION ALL SELECT COUNT(*) FROM analytics.date_dimension
    UNION ALL SELECT COUNT(*) FROM analytics.oil_gas_fields
    UNION ALL SELECT COUNT(*) FROM analytics.production_facilities
    UNION ALL SELECT COUNT(*) FROM analytics.wells
    UNION ALL SELECT COUNT(*) FROM analytics.equipment
    UNION ALL SELECT COUNT(*) FROM analytics.production_records
    UNION ALL SELECT COUNT(*) FROM analytics.equipment_maintenance
    UNION ALL SELECT COUNT(*) FROM analytics.daily_operating_costs
    UNION ALL SELECT COUNT(*) FROM analytics.hse_incidents
) AS counts;
