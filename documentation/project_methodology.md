# Project Methodology

## 1. Project overview

This project develops an end-to-end analytics solution for a simulated upstream oil and gas operation. It brings together relational data preparation, SQL-based operational analysis, Python statistical investigation and Power BI reporting.

The analysis focuses on five management areas:

- Production performance and target achievement.
- Equipment reliability, maintenance activity and downtime.
- Operating expenditure and budget performance.
- Health, safety and environmental (HSE) incidents.
- Consolidated management oversight.

The objective is to demonstrate how operational data can be transformed into structured analysis and decision-support reporting. The findings describe the synthetic dataset used in this project; they are not claims about a real oil and gas operator.

## 2. Data scope

The project uses ten synthetic datasets covering 1 January 2024 to 31 December 2026:

- `production_records`
- `oil_gas_fields`
- `wells`
- `production_facilities`
- `equipment`
- `equipment_maintenance`
- `daily_operating_costs`
- `hse_incidents`
- `operators_contractors`
- `date_dimension`

The loaded project dataset contains 67,023 records in total. Dataset-level counts and a complete data dictionary should be published alongside the source schema when available.

## 3. Data and analytics workflow

### Stage A — Source inspection

Inspect column names, data types, date formats, missing values, duplicate records, category consistency, value ranges and key uniqueness before loading or joining data.

### Stage B — PostgreSQL database development

Use PostgreSQL to organise the source data into three schemas:

- `raw` — source data as initially loaded.
- `staging` — data prepared for cleaning, standardisation and validation.
- `analytics` — analytical tables and reusable views for querying and reporting.

Preserve source values where appropriate and document transformations. Define primary and foreign keys only where the data supports them.

### Stage C — Data quality and validation

Check:

- Missing and duplicate records.
- Invalid dates and numeric values.
- Inconsistent categorical labels.
- Non-negative production and cost measures where required by the business rules.
- Primary-key uniqueness.
- Orphaned foreign-key references.
- Derived KPI calculations and denominator validity.

Resolve or explicitly document issues before using the affected fields in reporting. Validate relationships after loading the analytical tables.

### Stage D — SQL analytical layer

Create reusable analytical views for business analysis and Power BI. Aggregate fact tables at their correct grain before joining them to avoid fan-out and double-counting. Preserve the date, field, well, facility and equipment dimensions needed for filtering and drill-down.

The project includes seven reusable analytical views, including maintenance-event detail.

### Stage E — Python statistical analysis

Use the Jupyter notebook to explore the prepared daily production data retrieved from `analytics.vw_production_daily`. The analysis includes:

- Descriptive statistics: mean, median, variance, standard deviation, range, skewness and kurtosis.
- Interquartile-range (IQR) screening to flag potential outliers for investigation.
- Pearson and Spearman correlation analysis, with significance tests and approximate Fisher z-transformation confidence intervals for Pearson correlation.
- Median-centred Levene's test to compare variance across field groups.
- Kruskal–Wallis testing for field-level production comparisons.
- Pairwise Mann–Whitney U tests with Holm adjustment for multiple comparisons and rank-biserial effect sizes.
- Coefficient of variation to examine daily and monthly production stability.
- Linear regression of monthly field production trends, using calendar-month spacing and reporting slope, R-squared and p-values.

The statistical results are exploratory. Correlation does not establish causation. Daily observations may be serially dependent, so conventional significance tests and confidence intervals should be interpreted cautiously. The notebook's production analysis should not be mistaken for statistical analysis of every source dataset.

### Stage F — Power BI reporting

Use the validated analytical layer to build five reporting pages:

1. Management Overview.
2. Production Performance.
3. Equipment Reliability.
4. Cost & Financial Performance.
5. HSE Performance.

Each page should address a management question and support investigation through relevant dimensions and filters. The report is intended to communicate operational patterns, variances and areas requiring further review.

### Stage G — Management interpretation

For each material finding, state:

- What the analysis shows.
- The evidence and period covered.
- The operational or financial implication.
- What cannot be concluded from the available data.
- A practical follow-up or management action.

Avoid presenting an observed pattern as a confirmed root cause unless the available evidence supports that conclusion.

## 4. Analytical integrity and limitations

- The data is synthetic; findings describe this simulated dataset only.
- Correlation and regression patterns do not establish causation.
- Daily observations may not be independent over time; inferential results should be treated as exploratory.
- Avoid joining multiple one-to-many fact tables before aggregation.
- Do not publish unsupported KPIs.
- State units, definitions and denominators for every rate or ratio.
- Potential outliers are investigation flags, not automatically erroneous observations.
- A reliable TRIR or LTIFR requires workforce-hours, which are not available in the described source data. Do not estimate exposure-adjusted safety rates without the required denominator.
- Record assumptions and limitations alongside the relevant analysis.

## 5. Reproducibility

The repository includes SQL scripts, the Python notebook and companion script, Power BI report assets, and supporting documentation. Reproduction requires a compatible PostgreSQL environment and the project database objects. The Python analysis connects to the local PostgreSQL database and prompts for the database password at runtime; credentials should not be stored in the notebook or committed to the repository.

Do not publish confidential or oversized source files. If source data cannot be redistributed, provide schema documentation, data definitions and reproducible loading instructions instead.
