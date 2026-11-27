CREATE TABLE raw.daily_operating_costs(
	cost_id TEXT,
	transaction_date TEXT,
	field_id TEXT,
	facility_id TEXT,
	cost_category TEXT,
	cost_description TEXT,
	labour_cost_usd TEXT,
	maintenance_cost_usd TEXT,
	logistics_cost_usd TEXT,
	energy_cost_usd TEXT,
	chemicals_cost_usd TEXT,
	transportation_cost_usd TEXT,
	other_operating_cost_usd TEXT,
	total_operating_cost_usd TEXT,
	budgeted_cost_usd TEXT,
	cost_variance_usd TEXT,
	currency TEXT,
	date_id TEXT
);


CREATE TABLE raw.date_dimension(
	date_id TEXT,
	full_date TEXT,
	day TEXT,
	month TEXT,
	month_name TEXT,
	quarter TEXT,
	year TEXT,
	week_number TEXT,
	day_name TEXT,
	weekend_flag TEXT,
	financial_year TEXT,
	financial_quarter TEXT
);


CREATE TABLE raw.equipment(
	equipment_id TEXT,
	facility_id TEXT,
	equipment_name TEXT,
	equipment_category TEXT,
	manufacturer TEXT,
	installation_date TEXT,
	expected_lifespan_years TEXT,
	equipment_status TEXT,
	criticality_level TEXT,
	replacement_cost_usd TEXT,
	last_maintenance_date TEXT,
	operating_hours TEXT,
	equipment_condition TEXT
);


CREATE TABLE raw.equipment_maintenance(
	maintenance_id TEXT,
	equipment_id TEXT,
	facility_id TEXT,
	maintenance_date TEXT,
	equipment_category TEXT,
	equipment_name TEXT,
	maintenance_type TEXT,
	failure_category TEXT,
	failure_description TEXT,
	downtime_hours TEXT,
	repair_duration_hours TEXT,
	maintenance_cost_usd TEXT,
	spare_parts_cost_usd TEXT,
	labour_cost_usd TEXT,
	maintenance_priority TEXT,
	maintenance_status TEXT,
	next_scheduled_maintenance_date TEXT,
	source_work_order_reference TEXT,
	maintenance_start_timestamp TEXT,
	maintenance_completion_timestamp TEXT
);


CREATE TABLE raw.hse_incidents(
	incident_id TEXT,
	incident_date TEXT,
	field_id TEXT,
	facility_id	TEXT,
	incident_category TEXT,
	incident_description TEXT,
	severity_level TEXT,
	injury_count TEXT,
	environmental_impact TEXT,
	spill_volume_litres TEXT,
	lost_time_injury TEXT,
	regulatory_reportable TEXT,
	incident_status TEXT,
	resolution_date TEXT,
	source_incident_reference TEXT,
	date_id TEXT
);

CREATE TABLE raw.oil_gas_fields(
	field_id TEXT,
	field_name TEXT,
	field_type TEXT,
	basin TEXT,
	geographical_region TEXT,
	country TEXT,
	discovery_year TEXT,
	development_year TEXT,
	field_status TEXT,
	reservoir_type TEXT,
	estimated_recoverable_reserves_mmboe TEXT,
	field_operator_id TEXT,
	water_depth_meters TEXT
);


CREATE TABLE raw.operators_contractors(
	operator_id TEXT,
	company_name TEXT,
	company_type TEXT,
	country TEXT,
	contract_start_date TEXT,
	contract_end_date TEXT,
	service_category TEXT,
	contract_value_usd TEXT,
	contract_status TEXT
);


CREATE TABLE raw.production_facilities(
	facility_id TEXT,
	facility_name TEXT,
	field_id TEXT,
	facility_type TEXT,
	processing_capacity_bopd TEXT,
	gas_processing_capacity_mmscfd TEXT,
	installation_date TEXT,
	operational_status TEXT,
	location TEXT,
	facility_manager_id TEXT
);


CREATE TABLE raw.production_records(
	production_id TEXT,
	production_date TEXT,
	field_id TEXT,
	well_id TEXT,
	facility_id TEXT,
	operator_id TEXT,
	crude_oil_produced_bbl TEXT,
	natural_gas_produced_mscf TEXT,
	water_produced_bbl TEXT,
	water_cut_percentage TEXT,
	gas_oil_ratio TEXT,
	production_target_bbl TEXT,
	actual_production_bbl TEXT,
	production_variance_bbl TEXT,
	operating_hours TEXT,
	downtime_hours TEXT,
	downtime_reason TEXT,
	choke_size TEXT,
	wellhead_pressure_psi TEXT,
	flowline_pressure_psi TEXT,
	reservoir_pressure_psi TEXT,
	temperature_celsius TEXT,
	artificial_lift_type TEXT,
	production_status TEXT,
	measurement_method TEXT,
	recorded_by TEXT,
	record_timestamp TEXT,
	source_event_reference TEXT,
	date_id TEXT
);


CREATE TABLE raw.wells(
	well_id TEXT,
	field_id TEXT,
	well_name TEXT,
	well_type TEXT,
	well_classification TEXT,
	spud_date TEXT,
	completion_date TEXT,
	first_production_date TEXT,
	total_depth_meters TEXT,
	measured_depth_meters TEXT,
	well_status TEXT,
	artificial_lift_type TEXT,
	reservoir_zone TEXT,
	initial_production_rate_bopd TEXT,
	current_production_rate_bopd TEXT,
	cumulative_oil_production_bbl TEXT,
	water_cut_percentage TEXT
);


-- confirm each table's row counts
SELECT 'daily_operating_costs' AS table,
		COUNT(*) AS rows
FROM raw.daily_operating_costs
UNION ALL
SELECT 'date_dimension', 
		COUNT(*)
FROM raw.date_dimension
UNION ALL
SELECT 'equipment',
		COUNT(*)
FROM raw.equipment
UNION ALL
SELECT 'equipment_maintenance',
		COUNT(*)
FROM raw.equipment_maintenance
UNION ALL
SELECT 'hse_incidents',
		COUNT(*)
FROM raw.hse_incidents
UNION ALL
SELECT 'oil_gas_fields',
		COUNT(*)
FROM raw.oil_gas_fields
UNION ALL
SELECT 'operators_contractors',
		COUNT(*)
FROM raw.operators_contractors
UNION ALL 
SELECT 'production_facilities',
		COUNT(*)
FROM raw.production_facilities
UNION ALL
SELECT 'production_records',
		COUNT(*)
FROM raw.production_records
UNION ALL
SELECT 'wells',
		COUNT(*)
FROM raw.wells
;
