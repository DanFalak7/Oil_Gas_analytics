# Project Methodology

## 1. Objective

Build an end-to-end analytics solution for a simulated upstream oil and gas operation. The work covers production, asset reliability, operating expenditure and HSE monitoring.

## 2. Data scope

The project uses ten synthetic datasets covering 1 January 2024 to 31 December 2026:

- production_records
- oil_gas_fields
- wells
- production_facilities
- equipment
- equipment_maintenance
- daily_operating_costs
- hse_incidents
- operators_contractors
- date_dimension

The loaded project dataset contains 67,023 records in total. Dataset-level counts and the data dictionary should be published alongside the source schema when available.

## 3. Workflow

### Stage A — Source inspection

Inspect column names, data types, date formats, missing values, duplicate records, category consistency, value ranges and key uniqueness before loading or joining data.

### Stage B — Relational database

Use PostgreSQL to organise the source data into raw/staging, cleaned and analytical layers. Preserve source values where appropriate and document transformations. Define primary and foreign keys only where the data supports them.

### Stage C — Data quality and validation

Check:
- Missing and duplicate records.
- Invalid dates and numeric values.
- Inconsistent categorical labels.
- Non-negative production and cost measures where required by the business rules.
- Primary-key uniqueness.
- Orphaned foreign-key references.
- Derived KPI calculations and denominator validity.

Resolve or explicitly document issues before using the affected fields in reporting.

### Stage D — SQL analytical layer

Create reusable analytical views for Power BI and business analysis. Aggregate fact tables at their correct grain before joining them to avoid fan-out and double-counting. Preserve date, field, well, facility and equipment dimensions needed for filtering and drill-down.

### Stage E — Python analysis

Use the Jupyter notebook for exploratory and statistical analysis. Document the variables, sample sizes, assumptions, method selection, effect direction, uncertainty and interpretation for each test. Distinguish descriptive patterns, statistical association and causal claims.

### Stage F — Power BI

Use the validated analytical layer to build five reporting pages:
1. Management Overview
2. Production Performance
3. Equipment Reliability
4. Cost & Financial Performance
5. HSE Performance

Each page should support a management question and make it possible to investigate relevant dimensions.

### Stage G — Management interpretation

For each material finding, state:
- What the analysis shows.
- The evidence and period covered.
- The operational or financial implication.
- What cannot be concluded from the available data.
- A practical follow-up or management action.

## 4. Analytical integrity

- Synthetic data findings describe this simulated dataset only.
- Correlation does not establish causation.
- Avoid joining multiple one-to-many fact tables before aggregation.
- Do not publish unsupported KPIs.
- State units and denominators for every rate or ratio.
- Record assumptions and limitations next to the relevant analysis.

## 5. Reproducibility

The repository should include the SQL scripts, notebook, dashboard file or screenshots, data dictionary, and methodology documentation. Do not publish confidential or oversized source files. If data redistribution is not appropriate, publish schema documentation and reproducible instructions instead.
