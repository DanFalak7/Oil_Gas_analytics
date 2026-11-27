# Power BI Dashboard Documentation

## Overview

The Power BI report provides an operational performance view of a synthetic oil and gas business. It is designed to help management examine production, equipment reliability, operating costs and HSE performance.

The report connects to the project's PostgreSQL analytical layer, which contains relational analytical tables and views prepared from the staging schema.

> **Data disclosure:** This is a portfolio project built with synthetic data. It does not represent actual operational, safety, production or financial information from an oil and gas operator.

## Report structure

The supplied Power BI report contains five pages. Each page uses a 1920 × 1080 canvas.

| Page | Visual count | Focus |
|---|---:|---|
| Management | 20 | Management-level overview of operational performance |
| Production | 22 | Production volumes, targets, variance and well/field performance |
| Equipment | 18 | Equipment reliability, maintenance activity and downtime |
| Cost Financial | 22 | Operating expenditure, cost categories and budget variance |
| HSE Performance | 19 | Incident categories, severity and HSE performance |

**Total: 101 visuals across five report pages.**

## Analytical areas

### Management
Provides a consolidated view of the project's major operational performance areas for management review.

### Production
Examines daily production performance and supports analysis of crude oil, natural gas, water production, production targets, production variance and operating conditions.

### Equipment
Supports review of maintenance activity, equipment failures and downtime to help identify reliability concerns and maintenance priorities.

### Cost Financial
Examines operating expenditure by category and supports comparison of actual costs against budgeted costs.

### HSE Performance
Supports analysis of incident categories, severity, injury information and environmental impact.

## Data and model architecture

The report is built on the PostgreSQL `analytics` schema. The database workflow is documented in the SQL and methodology files in this repository:

1. Raw source tables.
2. Typed and cleaned staging tables.
3. Data-quality checks and corrections.
4. Analytics tables with primary and foreign-key constraints.
5. Analytical views for reporting and analysis.
6. Power BI semantic model and report pages.

The report includes a custom Bullet Chart visual.

## Reproducing the report

1. Set up the PostgreSQL database using the SQL scripts in this repository.
2. Load and validate the staging and analytics tables.
3. Create the analytical views.
4. Open the Power BI report in Power BI Desktop.
5. Configure the PostgreSQL connection for your local environment and refresh the model.

Connection credentials and machine-specific settings should be configured locally and must not be committed to the repository.

## Interpretation and limitations

- The dataset is synthetic and should be treated as an analytical demonstration, not as evidence about a real operator.
- Dashboard findings depend on the assumptions and definitions embedded in the synthetic dataset and report measures.
- HSE indicators should only be interpreted using the fields actually available in the dataset. Rates requiring workforce-hours exposure data, such as TRIR or LTIFR, should not be inferred without that denominator.
