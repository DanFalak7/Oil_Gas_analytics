# Oil & Gas Operations Analytics

An end-to-end business intelligence project analysing synthetic oil and gas operational data across production performance, equipment reliability, operating expenditure and HSE.

**Tools:** PostgreSQL · SQL · Python · Pandas · NumPy · Statistical Analysis · Power BI

> **Data disclosure:** This is an independent portfolio project built with synthetic data. It does not represent the operations, financial performance or safety record of a real oil and gas operator.

## Project at a glance

| Project component | Scope |
|---|---|
| Reporting period | 1 January 2024 – 31 December 2026 |
| Source datasets | 10 relational datasets |
| Validated records | 67,023 |
| Database | PostgreSQL |
| Analytical layer | 6 SQL analytical views |
| Statistical work | Python/Jupyter Notebook |
| Business intelligence | Five-page Power BI dashboard |

The solution follows a practical analytics workflow: inspect and validate source data, build a relational database, prepare analytical views, investigate business questions, and communicate findings through an interactive dashboard and management reporting.

## Business context

Oil and gas operators need reliable information to monitor production, understand operational interruptions, manage asset reliability, control expenditure and identify recurring health, safety and environmental (HSE) concerns.

This project simulates that environment and develops an integrated analytical solution for operational and management stakeholders.

## Business questions investigated

### 1. Production performance
- How does actual production compare with production targets?
- Which fields and wells contribute most to production?
- How do production trends vary over time?
- Where do downtime and production performance warrant further investigation?

### 2. Equipment reliability
- Which equipment categories account for the largest maintenance workload?
- Where are corrective maintenance and unplanned downtime concentrated?
- Which assets or facilities may require maintenance attention?
- What patterns appear in maintenance frequency and expenditure?

### 3. Cost and financial performance
- How does operating expenditure compare with budget?
- Which fields contribute most to operating costs?
- What is the relationship between operating expenditure and production?
- How is expenditure distributed across operating cost categories?

### 4. HSE performance
- Which facilities record the highest incident counts?
- Which incident categories occur most frequently?
- What patterns appear in incident severity and resolution?
- Where should HSE teams investigate recurring risks?

### 5. Management oversight
- What are the key operational performance indicators?
- Which areas show material variances or emerging concerns?
- Where should management prioritise further investigation?

## Technical workflow

1. **Data inspection and profiling** — review the ten source datasets and identify data quality issues.
2. **PostgreSQL database development** — load the datasets into a relational database and establish primary/foreign-key relationships.
3. **Data cleaning and validation** — address missing values, inconsistent categories, invalid values and referential-integrity issues.
4. **SQL analytics** — prepare analytical views and query the operational business questions.
5. **Python statistical analysis** — explore distributions, trends, relationships and potential anomalies in the prepared data.
6. **Power BI reporting** — build an interactive dashboard for operational and management users.
7. **Business interpretation** — communicate findings, limitations and recommended areas for investigation.

## Power BI dashboard

The completed dashboard contains five pages, designed at 1920 × 1080:

| Page | Audience / focus |
|---|---|
| Management Overview | Senior management; consolidated performance and areas requiring attention |
| Production Performance | Production trends, targets and operational performance |
| Equipment Reliability | Maintenance activity, equipment failures and downtime |
| Cost & Financial Performance | Operating expenditure, budgets and cost patterns |
| HSE Performance | Incident frequency, categories and severity |

Dashboard screenshots and the Power BI file will be added to the repository as project assets.

## Repository guide

The repository is being organised around the following structure:

```text
Oil_Gas_analytics/
├── README.md
├── sql/
│   ├── database_schema.sql
│   ├── data_cleaning.sql
│   ├── analytical_views.sql
│   └── business_analysis.sql
├── python/
│   └── Oil_and_Gas_Statistical_Analysis.ipynb
├── powerbi/
│   └── Oil_and_Gas_Dashboard.pbix
├── images/
│   ├── management_overview.png
│   ├── production_performance.png
│   ├── equipment_reliability.png
│   ├── cost_financial_performance.png
│   └── hse_performance.png
└── documentation/
    ├── project_methodology.md
    ├── database_architecture.md
    ├── data_dictionary.md
    ├── data_quality_and_validation.md
    ├── business_findings.md
    └── limitations.md
```

Files will be added as the publication package is assembled. The structure above describes the intended organisation; it does not imply that every listed asset is already present.

## Key data and analytical considerations

- The source data is synthetic and intended for learning and portfolio demonstration.
- The database contains 67,023 records across ten datasets after the project’s loading and validation workflow.
- Referential integrity and data-quality checks were part of the preparation process.
- Statistical association should not be interpreted as proof of causation.
- Some operational KPIs require denominators or source fields that may not be available. Unsupported measures should be identified rather than estimated.
- The repository will document analytical assumptions and limitations alongside the outputs.

## Reproducibility

The SQL scripts, notebook and supporting documentation will be published to make the workflow understandable and reproducible. The Power BI report requires a compatible Power BI Desktop installation. Where source data cannot be redistributed, the repository will provide schema and data-dictionary documentation rather than imply that the original datasets are included.

## Author

**Mahabubulah Adebiyi**  
Data Analyst | Business Intelligence Analyst

- GitHub: [@DanFalak7](https://github.com/DanFalak7)
- Portfolio: [GitHub repositories](https://github.com/DanFalak7?tab=repositories)

---

*This project demonstrates an end-to-end analytical workflow, from relational data preparation to statistical investigation and business intelligence reporting.*
