# SQL Workflow

This folder contains the PostgreSQL scripts used to create the raw, staging and analytical layers, validate the data, resolve referential-integrity issues and prepare reporting views.

The scripts are designed for the `oil_gas_analytics` database and were managed through pgAdmin. The source datasets are synthetic.

## Repository scripts and recommended execution order

| Order | Script | Purpose |
|---:|---|---|
| 1 | [`raw_schema_and_tables.sql`](./raw_schema_and_tables.sql) | Defines the ten raw tables and includes record-count checks. The `raw` schema must already exist before this script is run. |
| 2 | [`duplicate_check.sql`](./duplicate_check.sql) | Checks the ten raw tables for duplicate primary-key values. The script comments specify that no rows should be returned. Investigate duplicates before proceeding. |
| 3 | [`staging_schema_and_table_import.sql`](./staging_schema_and_table_import.sql) | Creates the `staging` schema and typed staging tables, transfers data from the raw tables, and includes row-count checks. |
| 4 | [`data_validation.sql`](./data_validation.sql) | Checks calculated fields and applies the validation-related corrections included in the script. Review the query results and updates before moving on. |
| 5 | [`orphan_foreign_keys_handling.sql`](./orphan_foreign_keys_handling.sql) | Identifies orphaned references in staging tables and contains updates for the affected relationships. Review the identified records and resulting checks. |
| 6 | [`analytics_schema_and_table_loading.sql`](./analytics_schema_and_table_loading.sql) | Creates the ten analytical tables, defines primary and foreign keys, loads data from staging and includes verification queries. |
| 7 | [`analytical_views.sql`](./analytical_views.sql) | Creates the reporting views for daily production, well performance, facility performance, maintenance performance, operating costs, HSE performance and maintenance-event detail. |

## Important execution notes

- **Create the `raw` schema first.** The raw-table script defines tables under `raw`, but does not create that schema.
- **Load the source files into the raw tables** using the import process in pgAdmin before running duplicate checks and staging transformations. The raw-table script defines table structures; it does not load the source CSV files by itself.
- Run the staging script only after the raw tables have been populated.
- The validation and orphan-reference scripts operate on the staging layer. Review their outputs and the records they update. The orphan-reference script distinguishes NULL references from non-NULL missing references and includes post-correction checks.
- The hard-coded orphan-ID mappings in the orphan-reference script are specific to this synthetic dataset. They are guarded by matching/reference checks and must not be reused for another dataset without re-investigation.
- The validation script uses tolerances for selected calculated fields. Missing values and incomplete cost components should be interpreted according to the source-data definitions, not automatically assumed to be zero.
- Run the analytics loading script after staging data and relationships have been checked. It creates and populates the analytical tables.
- Create the analytical views after the analytical tables have been loaded.
- These scripts are not a single unattended deployment pipeline. Some steps require manual CSV import and review of query results in pgAdmin.

## Data model overview

The project uses three database layers:

- `raw`: source-aligned tables holding imported data.
- `staging`: typed tables used for transformation, validation and relationship checks.
- `analytics`: relational tables and views prepared for business analysis and Power BI reporting.

Ten datasets are represented across operators and contractors, date dimension, fields, facilities, wells, equipment, production records, equipment maintenance, daily operating costs and HSE incidents.

## Analytical views

The views script creates:

- `analytics.vw_production_daily`
- `analytics.vw_well_performance`
- `analytics.vw_facility_performance`
- `analytics.vw_maintenance_performance`
- `analytics.vw_operating_costs`
- `analytics.vw_hse_performance`
- `analytics.vw_maintenance_event_detail`

These views support the Power BI reporting layer. The project also includes a separate Python notebook and script for statistical analysis.

## Reproducibility and data disclosure

- Database: PostgreSQL, `oil_gas_analytics`.
- SQL client: pgAdmin.
- Data: synthetic datasets; no actual operator or company operational records are represented.
- Do not commit database passwords, connection strings containing credentials, or other secrets.

The execution order above reflects the dependencies visible in the published scripts. It does not replace reviewing each script and its query results in the target database before execution.
