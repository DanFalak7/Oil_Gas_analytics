# PostgreSQL Database and SQL Workflow

## Database context

Database: `oil_gas_analytics`

The uploaded SQL scripts document a staged PostgreSQL workflow across three schemas:

- `raw` — source records initially loaded as text to preserve incoming values and support inspection.
- `staging` — typed and prepared tables used for standardisation and validation.
- `analytics` — relational analytical tables with primary/foreign-key constraints and views designed for analysis and Power BI.

## Source datasets

The project covers ten subject areas:

1. `daily_operating_costs`
2. `date_dimension`
3. `equipment`
4. `equipment_maintenance`
5. `hse_incidents`
6. `oil_gas_fields`
7. `operators_contractors`
8. `production_facilities`
9. `production_records`
10. `wells`

## SQL workflow represented by the supplied scripts

| Script | Purpose |
|---|---|
| `raw_schema_and_tables.sql` | Creates raw source tables |
| `staging_schema_and_table_import.sql` | Creates staging tables and supports raw-to-staging loading |
| `duplicate_check.sql` | Checks duplicate key values in raw tables |
| `missing_values_whitespace_and_standardization.sql` | Audits missing values and standardises text values |
| `data_validation.sql` | Checks and corrects selected derived values |
| `orphan_foreign_keys_handling.sql` | Identifies and handles orphaned relationship keys |
| `analytics_schema_and_table.sql` | Creates analytics schema tables and relational constraints |
| `analytical_views.sql` | Creates reusable analytical views |
| `business_problem_analysis.sql` | Contains SQL investigations for the business questions |

## Relational and analytical design

The analytics layer establishes key relationships between operational entities and facts. Analytical views expose aggregated production, maintenance, cost and HSE measures for downstream analysis.

When joining multiple fact tables, aggregate each fact table to a compatible grain before joining. This prevents row multiplication and inflated totals. Check the grain and join keys of every view before using it in a dashboard.

## Validation principles

The workflow includes duplicate checks, missing-value and whitespace audits, category standardisation, derived-value validation and orphan foreign-key checks. The project reports 67,023 records loaded across the ten source datasets after the cleaning and validation workflow.

## Execution notes

Run scripts in dependency order and inspect the statements before execution. Some scripts contain data-modifying statements such as UPDATE or DELETE; use a backup or transaction-controlled environment when re-running them.

The scripts are supplied as project artefacts. A clean-room execution should be tested against the published schema and dataset version before describing the repository as fully reproducible.
