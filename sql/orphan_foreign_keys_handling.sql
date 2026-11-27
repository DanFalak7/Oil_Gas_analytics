-- Referential-integrity review and correction in the staging layer.
-- NULL foreign keys are reported separately from non-NULL orphan references.
-- Review the investigation queries before running the UPDATE statements.

-- 1. Missing versus orphaned references: wells -> fields
SELECT w.well_id, w.field_id,
       CASE WHEN w.field_id IS NULL THEN 'MISSING' ELSE 'ORPHANED' END AS issue
FROM staging.wells w
WHERE w.field_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = w.field_id);

-- 2. Facilities -> fields
SELECT pf.facility_id, pf.field_id,
       CASE WHEN pf.field_id IS NULL THEN 'MISSING' ELSE 'ORPHANED' END AS issue
FROM staging.production_facilities pf
WHERE pf.field_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = pf.field_id);

-- 3. Equipment -> facilities
SELECT e.equipment_id, e.facility_id,
       CASE WHEN e.facility_id IS NULL THEN 'MISSING' ELSE 'ORPHANED' END AS issue
FROM staging.equipment e
WHERE e.facility_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM staging.production_facilities pf WHERE pf.facility_id = e.facility_id);

-- 4. Production records -> wells, fields, facilities, operators and dates
SELECT pr.production_id, pr.well_id, pr.field_id, pr.facility_id, pr.operator_id, pr.date_id
FROM staging.production_records pr
WHERE pr.well_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.wells w WHERE w.well_id = pr.well_id)
   OR pr.field_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = pr.field_id)
   OR pr.facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.production_facilities pf WHERE pf.facility_id = pr.facility_id)
   OR pr.operator_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.operators_contractors o WHERE o.operator_id = pr.operator_id)
   OR pr.date_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.date_dimension d WHERE d.date_id = pr.date_id);

-- 5. Maintenance records -> equipment and facilities
SELECT m.maintenance_id, m.equipment_id, m.facility_id
FROM staging.equipment_maintenance m
WHERE m.equipment_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.equipment e WHERE e.equipment_id = m.equipment_id)
   OR m.facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.production_facilities pf WHERE pf.facility_id = m.facility_id);

-- 6. Operating costs -> fields, facilities and dates
SELECT c.cost_id, c.field_id, c.facility_id, c.date_id
FROM staging.daily_operating_costs c
WHERE c.field_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = c.field_id)
   OR c.facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.production_facilities pf WHERE pf.facility_id = c.facility_id)
   OR c.date_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.date_dimension d WHERE d.date_id = c.date_id);

-- 7. HSE incidents -> fields, facilities and dates
SELECT h.incident_id, h.field_id, h.facility_id, h.date_id
FROM staging.hse_incidents h
WHERE h.field_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = h.field_id)
   OR h.facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.production_facilities pf WHERE pf.facility_id = h.facility_id)
   OR h.date_id IS NULL OR NOT EXISTS (SELECT 1 FROM staging.date_dimension d WHERE d.date_id = h.date_id);

-- 8. Investigate the five known maintenance equipment IDs.
-- A candidate must match both equipment name and facility, and the mapping below
-- must resolve to exactly one registered equipment record.
WITH id_map(orphan_id, expected_equipment_id) AS (
    VALUES (900001,150), (900002,230), (900003,195), (900004,142), (900005,44)
)
SELECT m.maintenance_id, m.equipment_id AS orphan_equipment_id,
       m.equipment_name AS maintenance_equipment_name, m.facility_id,
       mp.expected_equipment_id, e.equipment_name AS registered_equipment_name,
       COUNT(e.equipment_id) OVER (PARTITION BY m.maintenance_id) AS candidate_matches
FROM staging.equipment_maintenance m
JOIN id_map mp ON mp.orphan_id = m.equipment_id
LEFT JOIN staging.equipment e
  ON e.equipment_id = mp.expected_equipment_id
 AND e.facility_id = m.facility_id
 AND LOWER(BTRIM(e.equipment_name)) = LOWER(BTRIM(m.equipment_name));

-- Correct only when the target ID exists and matches the maintenance record's
-- equipment name and facility. Rows failing these checks remain unchanged.
WITH id_map(orphan_id, expected_equipment_id) AS (
    VALUES (900001,150), (900002,230), (900003,195), (900004,142), (900005,44)
)
UPDATE staging.equipment_maintenance m
SET equipment_id = mp.expected_equipment_id
FROM id_map mp
WHERE m.equipment_id = mp.orphan_id
  AND EXISTS (
      SELECT 1
      FROM staging.equipment e
      WHERE e.equipment_id = mp.expected_equipment_id
        AND e.facility_id = m.facility_id
        AND LOWER(BTRIM(e.equipment_name)) = LOWER(BTRIM(m.equipment_name))
  );

-- 9. Correct four known cost field IDs using the field registered to the facility.
-- The facility must resolve to an existing field; otherwise the row is not changed.
SELECT c.cost_id, c.field_id AS orphan_field_id, c.facility_id,
       pf.field_id AS facility_field_id, pf.facility_name
FROM staging.daily_operating_costs c
JOIN staging.production_facilities pf ON pf.facility_id = c.facility_id
WHERE c.field_id IN (880001,880002,880003,880004);

UPDATE staging.daily_operating_costs c
SET field_id = pf.field_id
FROM staging.production_facilities pf
WHERE c.facility_id = pf.facility_id
  AND c.field_id IN (880001,880002,880003,880004)
  AND EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = pf.field_id);

-- 10. Investigate the three known HSE facility IDs. Show all facilities in the
-- incident's field; the mapping is only safe if the specified facility belongs
-- to that same field.
WITH id_map(orphan_id, expected_facility_id) AS (
    VALUES (990001,10), (990002,3), (990003,11)
)
SELECT h.incident_id, h.field_id, h.facility_id AS orphan_facility_id,
       mp.expected_facility_id, pf.field_id AS candidate_field_id,
       pf.facility_name,
       COUNT(pf.facility_id) OVER (PARTITION BY h.incident_id) AS candidate_matches
FROM staging.hse_incidents h
JOIN id_map mp ON mp.orphan_id = h.facility_id
LEFT JOIN staging.production_facilities pf
  ON pf.facility_id = mp.expected_facility_id
 AND pf.field_id = h.field_id;

UPDATE staging.hse_incidents h
SET facility_id = mp.expected_facility_id
FROM (VALUES (990001,10), (990002,3), (990003,11)) AS mp(orphan_id, expected_facility_id)
WHERE h.facility_id = mp.orphan_id
  AND EXISTS (
      SELECT 1
      FROM staging.production_facilities pf
      WHERE pf.facility_id = mp.expected_facility_id
        AND pf.field_id = h.field_id
  );

-- 11. Re-run relationship checks after corrections. Any returned row needs
-- investigation before loading the analytics schema.
SELECT 'maintenance_equipment' AS relationship, m.maintenance_id::TEXT AS record_id,
       m.equipment_id::TEXT AS reference_id
FROM staging.equipment_maintenance m
WHERE m.equipment_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM staging.equipment e WHERE e.equipment_id = m.equipment_id)
UNION ALL
SELECT 'cost_field', c.cost_id::TEXT, c.field_id::TEXT
FROM staging.daily_operating_costs c
WHERE c.field_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM staging.oil_gas_fields f WHERE f.field_id = c.field_id)
UNION ALL
SELECT 'hse_facility', h.incident_id::TEXT, h.facility_id::TEXT
FROM staging.hse_incidents h
WHERE h.facility_id IS NULL
   OR NOT EXISTS (
       SELECT 1 FROM staging.production_facilities pf
       WHERE pf.facility_id = h.facility_id AND pf.field_id = h.field_id
   )
ORDER BY relationship, record_id;
