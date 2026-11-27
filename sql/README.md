# SQL Workflow

This folder contains the PostgreSQL scripts used to build and prepare the analytical layer of the Oil & Gas Analytics project.

## Analytical schema and table creation

[`analytics_schema_and_table_loading.sql`](./analytics_schema_and_table_loading.sql)

This script:

1. Creates the `analytics` schema.
2. Creates the ten analytical tables using the corresponding structures in the `staging` schema.
3. Defines primary keys for the analytical tables.
4. Adds foreign-key constraints to connect operators, fields, facilities, wells, equipment, production, maintenance, operating costs, HSE incidents and the date dimension.
5. Includes a metadata query to verify table creation.

### Execution context

Run this script in the `oil_gas_analytics` PostgreSQL database after the staging tables have been created and populated. It expects the `staging` schema and its ten source-aligned tables to exist.

The script creates the analytical table structures and constraints; it does not, by itself, document or perform the complete raw-data import, staging transformations, data-quality remediation, analytical-view creation or business-question analysis.

## Reproducibility notes

- Database platform: PostgreSQL (managed through pgAdmin).
- Database: `oil_gas_analytics`.
- Schema flow: `raw` → `staging` → `analytics`.
- The project uses synthetic data. It does not contain actual operating data from an oil and gas company.

As the remaining SQL workflow scripts are added to this folder, document each script here with its purpose, execution order, prerequisites and outputs. Avoid placing database passwords or other credentials in SQL files.
