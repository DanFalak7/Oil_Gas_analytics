-- Check for orphan records

-- Wells referencing non-existent fields
SELECT w.well_id, w.field_id
FROM staging.wells w
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.oil_gas_fields f
    WHERE f.field_id = w.field_id
);

-- Facilities referencing non-existent fields
SELECT pf.facility_id, pf.field_id
FROM staging.production_facilities pf
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.oil_gas_fields f
    WHERE f.field_id = pf.field_id
);

-- Equipment referencing non-existent facilities
SELECT e.equipment_id, e.facility_id
FROM staging.equipment e
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.production_facilities pf
    WHERE pf.facility_id = e.facility_id
);

--Production records referencing missing entities
SELECT
    pr.production_id,
    pr.well_id,
    pr.field_id,
    pr.facility_id,
    pr.operator_id,
    pr.date_id
FROM staging.production_records pr
WHERE
    NOT EXISTS (
        SELECT 1 FROM staging.wells w
        WHERE w.well_id = pr.well_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.oil_gas_fields f
        WHERE f.field_id = pr.field_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.production_facilities pf
        WHERE pf.facility_id = pr.facility_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.operators_contractors o
        WHERE o.operator_id = pr.operator_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.date_dimension d
        WHERE d.date_id = pr.date_id
    );

-- Maintenance records referencing missing equipment or facilities
SELECT
    m.maintenance_id,
    m.equipment_id,
    m.facility_id
FROM staging.equipment_maintenance m
WHERE
    NOT EXISTS (
        SELECT 1 FROM staging.equipment e
        WHERE e.equipment_id = m.equipment_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.production_facilities pf
        WHERE pf.facility_id = m.facility_id
    );
-- 5 orphan keys found

-- Operating costs referencing missing fields, facilities or dates
SELECT
    c.cost_id,
    c.field_id,
    c.facility_id,
    c.date_id
FROM staging.daily_operating_costs c
WHERE
    NOT EXISTS (
        SELECT 1 FROM staging.oil_gas_fields f
        WHERE f.field_id = c.field_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.production_facilities pf
        WHERE pf.facility_id = c.facility_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.date_dimension d
        WHERE d.date_id = c.date_id
    );
--4 orphan keys found

-- HSE incidents referencing missing fields, facilities or dates
SELECT
    h.incident_id,
    h.field_id,
    h.facility_id,
    h.date_id
FROM staging.hse_incidents h
WHERE
    NOT EXISTS (
        SELECT 1 FROM staging.oil_gas_fields f
        WHERE f.field_id = h.field_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.production_facilities pf
        WHERE pf.facility_id = h.facility_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM staging.date_dimension d
        WHERE d.date_id = h.date_id
    );
-- 3 orphan keys found


-- Equipment maintenance: five missing equipment IDs
-- inspect whether the equipment name and facility identify a matching equipment
SELECT
    m.maintenance_id,
    m.equipment_id AS orphan_equipment_id,
    m.equipment_name AS maintenance_equipment_name,
    m.facility_id,
    e.equipment_id AS possible_equipment_id,
    e.equipment_name AS registered_equipment_name
FROM staging.equipment_maintenance m
LEFT JOIN staging.equipment e
    ON LOWER(BTRIM(m.equipment_name)) =
       LOWER(BTRIM(e.equipment_name))
   AND m.facility_id = e.facility_id
WHERE m.equipment_id IN (900001, 900002, 900003, 900004, 900005);

-- update the ewuipment_id

UPDATE staging.equipment_maintenance
SET equipment_id =
    CASE
        WHEN equipment_id = 900001
            THEN 150
        WHEN equipment_id = 900002
            THEN 230
        WHEN equipment_id = 900003
            THEN 195
        WHEN equipment_id = 900004
            THEN 142
        WHEN equipment_id = 900005
            THEN 44
        ELSE equipment_id
    END
WHERE equipment_id IN (900001, 900002, 900003, 900004, 900005);

-- Daily operating costs: four missing field IDs
-- Check the field associated with each facility:
SELECT
    c.cost_id,
    c.field_id AS orphan_field_id,
    c.facility_id,
    pf.field_id AS facility_field_id,
    pf.facility_name
FROM staging.daily_operating_costs c
JOIN staging.production_facilities pf
    ON c.facility_id = pf.facility_id
WHERE c.field_id IN (880001, 880002, 880003, 880004);

-- Update
UPDATE staging.daily_operating_costs c
SET field_id = pf.field_id
FROM staging.production_facilities pf
WHERE c.facility_id = pf.facility_id
  AND c.field_id IN (880001, 880002, 880003, 880004)
  AND EXISTS (
      SELECT 1
      FROM staging.oil_gas_fields f
      WHERE f.field_id = pf.field_id
  );

-- HSE incidents: three missing facility IDs
-- Check how many facilities are associated with each incident's field:
SELECT
    h.incident_id,
    h.field_id,
    h.facility_id,
    COUNT(pf.facility_id) AS facilities_in_field,
    STRING_AGG(
        pf.facility_id::TEXT,
        ', ' ORDER BY pf.facility_id
    ) AS available_facility_id
FROM staging.hse_incidents h
LEFT JOIN staging.production_facilities pf
    ON h.field_id = pf.field_id
WHERE h.facility_id IN (990001, 990002, 990003)
GROUP BY h.incident_id, h.field_id, h.facility_id;

UPDATE staging.hse_incidents
SET facility_id =
        CASE
            WHEN facility_id = 990001
                THEN 10
            WHEN facility_id = 990002
                THEN 3
            WHEN facility_id = 990003
                THEN 11
        END
WHERE facility_id IN (990001, 990002, 990003);
