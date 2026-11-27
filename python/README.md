# Python Statistical Analysis

This directory contains the Python analysis of the project's PostgreSQL production reporting view.

## Files

- `Oil_and_Gas_Statistical_Analysis.ipynb` — executed Jupyter notebook with analysis code, outputs and visualisations.
- `Oil_and_Gas_Statistical_Analysis.py` — Python script version of the analysis.

## Analysis scope

The notebook connects to `oil_gas_analytics` and retrieves `analytics.vw_production_daily`. It explores production distributions and potential outliers, Pearson and Spearman correlations, field-level differences, production stability and monthly field trends.

The analysis uses Pandas, NumPy, SciPy, Statsmodels, SQLAlchemy, psycopg2, Matplotlib and Seaborn. The statistical methods and interpretation cautions are documented in [Python statistical methods](../documentation/python_statistical_methods.md).

## Environment setup

Use Python 3.10 or later and install the required packages:

```bash
python -m pip install -r requirements.txt
```

The root-level `requirements.txt` is the dependency source of truth for this repository. It includes the packages imported by the published analysis script; `scikit-learn` is not required by the current analysis.

You also need:

- PostgreSQL running locally or at a reachable database host.
- The project database `oil_gas_analytics`.
- The analytics schema and view `analytics.vw_production_daily`, created using the SQL workflow in [../sql/README.md](../sql/README.md).

## Database connection

The script currently uses these local connection defaults:

- Host: `localhost`
- Port: `5432`
- Database: `oil_gas_analytics`
- Username: `postgres`

Edit the connection variables in the notebook/script if your PostgreSQL setup differs. The password is requested interactively using Python's `getpass`; do not hard-code or commit database credentials.

## Run the analysis

From the repository root:

```bash
jupyter notebook python/Oil_and_Gas_Statistical_Analysis.ipynb
```

Alternatively, run the script:

```bash
python python/Oil_and_Gas_Statistical_Analysis.py
```

The analysis is based on the prepared daily production view rather than all ten source datasets. Because the data is synthetic and daily observations may be serially dependent, interpret inferential statistics as exploratory, not causal evidence.
