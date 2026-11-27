-- Duplicate primary-key checks across the ten raw source tables.
-- Expected result: zero rows. Any returned row identifies a key occurring
-- more than once and should be investigated before loading the staging layer.

SELECT 'daily_operating_costs' AS table_name,
       cost_id AS duplicate_key,
       COUNT(*) AS occurrences
FROM raw.daily_operating_costs
GROUP BY cost_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'date_dimension',
       date_id,
       COUNT(*)
FROM raw.date_dimension
GROUP BY date_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'equipment',
       equipment_id,
       COUNT(*)
FROM raw.equipment
GROUP BY equipment_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'equipment_maintenance',
       maintenance_id,
       COUNT(*)
FROM raw.equipment_maintenance
GROUP BY maintenance_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'hse_incidents',
       incident_id,
       COUNT(*)
FROM raw.hse_incidents
GROUP BY incident_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'oil_gas_fields',
       field_id,
       COUNT(*)
FROM raw.oil_gas_fields
GROUP BY field_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'operators_contractors',
       operator_id,
       COUNT(*)
FROM raw.operators_contractors
GROUP BY operator_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'production_facilities',
       facility_id,
       COUNT(*)
FROM raw.production_facilities
GROUP BY facility_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'production_records',
       production_id,
       COUNT(*)
FROM raw.production_records
GROUP BY production_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'wells',
       well_id,
       COUNT(*)
FROM raw.wells
GROUP BY well_id
HAVING COUNT(*) > 1
ORDER BY table_name, duplicate_key;
