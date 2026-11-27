#!/usr/bin/env python
# coding: utf-8

# In[1]:


# %pip install pandas numpy sqlalchemy psycopg2-binary scipy statsmodels scikit-learn matplotlib seaborn jupyter


# In[2]:


from getpass import getpass
from sqlalchemy import URL, create_engine
from sqlalchemy import text


# In[3]:


import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import seaborn as sns

from sqlalchemy import create_engine, URL, text
from getpass import getpass

from scipy import stats
import statsmodels.api as sm
import statsmodels.formula.api as smf

import warnings
warnings.filterwarnings("ignore")

# Display settings
pd.set_option("display.max_columns", None)
pd.set_option("display.max_rows", 100)
pd.set_option("display.float_format", "{:,.2f}".format)

sns.set_theme(style="whitegrid")

print("Libraries imported successfully.")


# In[4]:


# PostgreSQL connection details

host = "localhost"
port = 5432
database = "oil_gas_analytics"
username = "postgres"

# Enter your password securely
password = getpass("Enter your PostgreSQL password: ")

# Create database connection
connection_url = URL.create(
    drivername="postgresql+psycopg2",
    username=username,
    password=password,
    host=host,
    port=port,
    database=database
)

engine = create_engine(connection_url)

# Test connection
try:
    with engine.connect() as connection:
        result = connection.execute(text("SELECT version();"))
        print("PostgreSQL connection successful.")
        print(result.scalar())

except Exception as error:
    print("Connection failed:")
    print(error)


# In[5]:


# Inspect the analytical schema
query = """
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'analytics'
ORDER BY table_type, table_name;
"""

schema_objects = pd.read_sql(query, engine)

display(schema_objects)


# In[6]:


# Verify the production data
production_df = pd.read_sql(
    "SELECT * FROM analytics.vw_production_daily LIMIT 10;",
    engine
)

display(production_df)

print("Rows retrieved:", len(production_df))
print("Columns:", production_df.columns.tolist())


# In[7]:


#  Load the complete production dataset


production_df = pd.read_sql_query(
    "SELECT * FROM analytics.vw_production_daily;",
    engine
)

print("Production dataset loaded successfully.")
print("Dataset shape:", production_df.shape)

display(production_df.head())


# In[8]:


# 1. Inspect data types and non-null counts
print("DATASET INFORMATION")
production_df.info()

# 2. Check missing values
print("\nMISSING VALUES")
missing_values = production_df.isnull().sum()

missing_summary = pd.DataFrame({
    "Missing Values": missing_values,
    "Missing Percentage": (
        missing_values / len(production_df)
    ) * 100
})

display(missing_summary)

# 3. Check duplicate rows
print("\nDUPLICATE ROWS")
print("Number of duplicate rows:", production_df.duplicated().sum())

# 4. Check date column
print("\nDATE COLUMN TYPE")
print(production_df["production_date"].dtype)


# In[9]:


# covert production_date to date data type
production_df["production_date"] = pd.to_datetime(
    production_df["production_date"]
).dt.date

print("Date conversion completed.")
print("Data type:", production_df["production_date"].dtype)

display(production_df[["production_date"]].head())


# In[10]:


# Select numerical variables for descriptive analysis

numeric_columns = [
    "production_records",
    "active_wells",
    "total_oil_produced_bbl",
    "total_gas_produced_mscf",
    "total_water_produced_bbl",
    "total_production_target_bbl",
    "total_actual_production_bbl",
    "total_production_variance_bbl",
    "production_target_achievement_pct",
    "weighted_water_cut_pct",
    "total_operating_hours",
    "total_downtime_hours"
]

# Generate descriptive statistics
descriptive_stats = production_df[numeric_columns].describe().T

# Display results
display(descriptive_stats)


# In[11]:


# Calculate additional statistical measures

additional_stats = pd.DataFrame(index=numeric_columns)

additional_stats["Variance"] = production_df[numeric_columns].var()
additional_stats["Range"] = (
    production_df[numeric_columns].max()
    - production_df[numeric_columns].min()
)
additional_stats["Skewness"] = production_df[numeric_columns].skew()
additional_stats["Kurtosis"] = production_df[numeric_columns].kurt()

display(additional_stats)


# In[12]:


# Compare mean and median

# Compare mean and median

mean_median_comparison = pd.DataFrame({
    "Mean": production_df[numeric_columns].mean(),
    "Median": production_df[numeric_columns].median()
})

mean_median_comparison["Difference"] = (
    mean_median_comparison["Mean"]
    - mean_median_comparison["Median"]
)

display(mean_median_comparison)


# In[13]:


# 1. Investigate negative downtime
negative_downtime = production_df[
    production_df["total_downtime_hours"] < 0
].copy()

print("NEGATIVE DOWNTIME RECORDS")
print("Number of records:", len(negative_downtime))

display(
    negative_downtime[
        [
            "production_date",
            "field_name",
            "facility_name",
            "total_operating_hours",
            "total_downtime_hours"
        ]
    ]
)


# 2. Investigate target achievement above 100%
high_achievement = production_df[
    production_df["production_target_achievement_pct"] > 100
].copy()

print("\nTARGET ACHIEVEMENT ABOVE 100%")
print("Number of records:", len(high_achievement))

display(
    high_achievement[
        [
            "production_date",
            "field_name",
            "facility_name",
            "total_production_target_bbl",
            "total_actual_production_bbl",
            "production_target_achievement_pct"
        ]
    ].sort_values(
        "production_target_achievement_pct",
        ascending=False
    ).head(10)
)


# 3. Validate production variance
production_df["calculated_variance"] = (
    production_df["total_actual_production_bbl"]
    - production_df["total_production_target_bbl"]
)

production_df["variance_difference"] = (
    production_df["total_production_variance_bbl"]
    - production_df["calculated_variance"]
)

print("\nPRODUCTION VARIANCE VALIDATION")
print(
    "Records with a variance difference greater than 0.01 bbl:",
    (production_df["variance_difference"].abs() > 0.01).sum()
)

print(
    "Largest absolute variance difference:",
    production_df["variance_difference"].abs().max()
)

display(
    production_df[
        production_df["variance_difference"].abs() > 0.01
    ][
        [
            "production_date",
            "field_name",
            "total_production_target_bbl",
            "total_actual_production_bbl",
            "total_production_variance_bbl",
            "calculated_variance",
            "variance_difference"
        ]
    ].head(10)
)


# In[14]:


# Count distinct field-facility combinations
field_facility_pairs = (
    production_df.groupby(
        ["field_id", "field_name", "facility_id", "facility_name"]
    )
    .agg(
        production_observations=("production_date", "count"),
        total_oil=("total_oil_produced_bbl", "sum"),
        total_actual=("total_actual_production_bbl", "sum")
    )
    .reset_index()
    .sort_values(
        ["field_id", "facility_id"]
    )
)

print("Number of distinct field-facility combinations:",
      len(field_facility_pairs))

display(field_facility_pairs)


# In[15]:


# Hostograms of production variables

# Select variables for histogram analysis

histogram_columns = [
    "total_oil_produced_bbl",
    "total_gas_produced_mscf",
    "total_water_produced_bbl",
    "production_target_achievement_pct"
]

# Create a 2x2 histogram layout
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

for column, ax in zip(histogram_columns, axes.flatten()):

    sns.histplot(
        data=production_df,
        x=column,
        bins=40,
        kde=True,
        ax=ax
    )

    ax.set_title(f"Distribution of {column}")
    ax.set_xlabel(column)
    ax.set_ylabel("Frequency")

plt.tight_layout()
plt.show()


# In[16]:


# Boxplots of production variables
# Create boxplots for production variables

boxplot_columns = [
    "total_oil_produced_bbl",
    "total_gas_produced_mscf",
    "total_water_produced_bbl",
    "production_target_achievement_pct"
]

fig, axes = plt.subplots(2, 2, figsize=(15, 10))

for column, ax in zip(boxplot_columns, axes.flatten()):

    sns.boxplot(
        data=production_df,
        x=column,
        ax=ax
    )

    ax.set_title(f"Boxplot of {column}")
    ax.set_xlabel(column)

plt.tight_layout()
plt.show()


# In[17]:


# Quantify potential outliers

# Calculate outliers using the IQR method

outlier_results = []

for column in boxplot_columns:

    Q1 = production_df[column].quantile(0.25)
    Q3 = production_df[column].quantile(0.75)

    IQR = Q3 - Q1

    lower_bound = Q1 - (1.5 * IQR)
    upper_bound = Q3 + (1.5 * IQR)

    outliers = production_df[
        (production_df[column] < lower_bound) |
        (production_df[column] > upper_bound)
    ]

    outlier_results.append({
        "Variable": column,
        "Lower Bound": lower_bound,
        "Upper Bound": upper_bound,
        "Outlier Count": len(outliers),
        "Outlier Percentage": (
            len(outliers) / len(production_df)
        ) * 100
    })

outlier_summary = pd.DataFrame(outlier_results)

display(outlier_summary)


# In[20]:


production_df["production_date"] = pd.to_datetime(
    production_df["production_date"],
    format="%Y-%m-%d",
    errors="coerce"
)

print(production_df["production_date"].dtype)
display(production_df[["production_date"]].head())


# In[21]:


# Create a monthly grouping column
production_df["month"] = (
    production_df["production_date"].dt.to_period("M")
)

# Aggregate production data monthly
monthly_production = (
    production_df
    .groupby("month")
    .agg(
        total_oil=("total_oil_produced_bbl", "sum"),
        total_gas=("total_gas_produced_mscf", "sum"),
        total_water=("total_water_produced_bbl", "sum"),
        total_target=("total_production_target_bbl", "sum"),
        total_actual=("total_actual_production_bbl", "sum"),
        total_operating_hours=("total_operating_hours", "sum"),
        total_downtime_hours=("total_downtime_hours", "sum"),
        production_days=("production_date", "nunique")
    )
    .reset_index()
)

# Convert month back to timestamp for plotting
monthly_production["month"] = (
    monthly_production["month"].dt.to_timestamp()
)

# Calculate weighted performance indicators
monthly_production["target_achievement_pct"] = (
    monthly_production["total_actual"]
    / monthly_production["total_target"]
) * 100

monthly_production["water_cut_pct"] = (
    monthly_production["total_water"]
    / (
        monthly_production["total_oil"]
        + monthly_production["total_water"]
    )
) * 100

monthly_production["production_variance"] = (
    monthly_production["total_actual"]
    - monthly_production["total_target"]
)

display(monthly_production.round(2))

print("Monthly observations:", len(monthly_production))


# In[28]:


# Annual Comparison
# Extract year from the month column
monthly_production["year"] = monthly_production["month"].dt.year

# Aggregate monthly figures into annual figures
annual_production = (
    monthly_production.groupby("year")
    .agg(
        total_oil=("total_oil", "sum"),
        total_gas=("total_gas", "sum"),
        total_water=("total_water", "sum"),
        total_target=("total_target", "sum"),
        total_actual=("total_actual", "sum"),
        total_operating_hours=("total_operating_hours", "sum"),
        total_downtime_hours=("total_downtime_hours", "sum")
    )
    .reset_index()
)

# Calculate annual performance indicators
annual_production["target_achievement_pct"] = (
    annual_production["total_actual"]
    / annual_production["total_target"]
) * 100

annual_production["water_cut_pct"] = (
    annual_production["total_water"]
    / (annual_production["total_oil"] + annual_production["total_water"])
) * 100

annual_production["downtime_pct"] = (
    annual_production["total_downtime_hours"]
    / (
        annual_production["total_operating_hours"]
        + annual_production["total_downtime_hours"]
    )
) * 100

display(annual_production.round(2))


# In[30]:


# Correlation Analysis

# Select variables for correlation analysis
correlation_df = production_df[
    [
        "total_oil_produced_bbl",
        "total_gas_produced_mscf",
        "total_water_produced_bbl",
        "total_operating_hours",
        "total_downtime_hours",
        "weighted_water_cut_pct",
        "production_target_achievement_pct"
    ]
].copy()

# Calculate Pearson correlation
pearson_corr = correlation_df.corr(method="pearson")

# Calculate Spearman correlation
spearman_corr = correlation_df.corr(method="spearman")

print("PEARSON CORRELATION")
display(pearson_corr.round(3))

print("SPEARMAN CORRELATION")
display(spearman_corr.round(3))


# In[31]:


# Visualize relationship

import matplotlib.pyplot as plt

# Relationships to visualize
relationships = [
    ("total_oil_produced_bbl", "total_gas_produced_mscf"),
    ("total_oil_produced_bbl", "total_operating_hours"),
    ("total_downtime_hours", "production_target_achievement_pct"),
    ("total_water_produced_bbl", "weighted_water_cut_pct")
]

fig, axes = plt.subplots(2, 2, figsize=(14, 10))

for ax, (x, y) in zip(axes.flatten(), relationships):

    plot_data = production_df[[x, y]].dropna()

    ax.scatter(
        plot_data[x],
        plot_data[y],
        alpha=0.25,
        s=12
    )

    ax.set_xlabel(x.replace("_", " ").title())
    ax.set_ylabel(y.replace("_", " ").title())
    ax.set_title(f"{x} vs {y}")
    ax.grid(alpha=0.3)

plt.tight_layout()
plt.show()


# In[32]:


# statistical significance testing

from scipy.stats import pearsonr, spearmanr
import pandas as pd

# Relationships selected for testing
relationships = [
    ("Oil vs Gas",
     "total_oil_produced_bbl",
     "total_gas_produced_mscf"),

    ("Oil vs Operating Hours",
     "total_oil_produced_bbl",
     "total_operating_hours"),

    ("Downtime vs Target Achievement",
     "total_downtime_hours",
     "production_target_achievement_pct"),

    ("Water vs Water Cut",
     "total_water_produced_bbl",
     "weighted_water_cut_pct")
]

results = []

for name, x, y in relationships:

    # Remove missing observations
    data = production_df[[x, y]].dropna()

    # Pearson test
    pearson_r, pearson_p = pearsonr(data[x], data[y])

    # Spearman test
    spearman_r, spearman_p = spearmanr(data[x], data[y])

    results.append({
        "Relationship": name,
        "Sample Size": len(data),
        "Pearson r": pearson_r,
        "Pearson p-value": pearson_p,
        "Spearman rho": spearman_r,
        "Spearman p-value": spearman_p
    })

significance_results = pd.DataFrame(results)

display(significance_results.round(6))


# In[33]:


# Calculate 95% confidence intervals

import numpy as np
from scipy.stats import pearsonr, spearmanr
import pandas as pd

relationships = [
    ("Oil vs Gas", "total_oil_produced_bbl",
     "total_gas_produced_mscf"),

    ("Oil vs Operating Hours", "total_oil_produced_bbl",
     "total_operating_hours"),

    ("Downtime vs Target Achievement", "total_downtime_hours",
     "production_target_achievement_pct"),

    ("Water vs Water Cut", "total_water_produced_bbl",
     "weighted_water_cut_pct")
]

results = []

for name, x, y in relationships:

    data = production_df[[x, y]].dropna()
    n = len(data)

    # Pearson correlation and p-value
    r, pearson_p = pearsonr(data[x], data[y])

    # Spearman correlation and p-value
    rho, spearman_p = spearmanr(data[x], data[y])

    # Fisher transformation for approximate 95% CI
    z = np.arctanh(r)
    standard_error = 1 / np.sqrt(n - 3)

    lower = np.tanh(z - 1.96 * standard_error)
    upper = np.tanh(z + 1.96 * standard_error)

    results.append({
        "Relationship": name,
        "Sample Size": n,
        "Pearson r": r,
        "95% CI Lower": lower,
        "95% CI Upper": upper,
        "Pearson p-value": pearson_p,
        "Spearman rho": rho,
        "Spearman p-value": spearman_p
    })

confidence_results = pd.DataFrame(results)

display(confidence_results.round(6))

# Display p-values in scientific notation
for _, row in confidence_results.iterrows():
    print(
        f"{row['Relationship']}: "
        f"Pearson p = {row['Pearson p-value']:.3e}, "
        f"Spearman p = {row['Spearman p-value']:.3e}"
    )


# In[35]:


# comparing production performance across fields
# Prepare field-level production data

# Aggregate facility observations into daily field-level observations
field_daily = (
    production_df
    .groupby(
        ["production_date", "field_id", "field_name"],
        as_index=False
    )
    .agg(
        daily_oil=("total_oil_produced_bbl", "sum"),
        daily_gas=("total_gas_produced_mscf", "sum"),
        daily_water=("total_water_produced_bbl", "sum"),
        daily_operating_hours=("total_operating_hours", "sum"),
        daily_downtime_hours=("total_downtime_hours", "sum"),
        daily_target=("total_production_target_bbl", "sum"),
        daily_actual=("total_actual_production_bbl", "sum")
    )
)

print("Dataset shape:", field_daily.shape)

print(
    "Number of fields:",
    field_daily["field_name"].nunique()
)

display(
    field_daily.groupby("field_name")
    .agg(
        observation_count=("daily_oil", "count"),
        average_daily_oil=("daily_oil", "mean"),
        median_daily_oil=("daily_oil", "median"),
        total_oil=("daily_oil", "sum")
    )
    .round(2)
    .sort_values("average_daily_oil", ascending=False)
)


# In[36]:


# Before hypothesis testing: visualize field distributions
import matplotlib.pyplot as plt
import seaborn as sns

plt.figure(figsize=(16, 8))

sns.boxplot(
    data=field_daily,
    x="field_name",
    y="daily_oil"
)

plt.title("Daily Oil Production Distribution Across Fields")
plt.xlabel("Oil Field")
plt.ylabel("Daily Oil Production (bbl)")
plt.xticks(rotation=45)
plt.grid(axis="y", alpha=0.3)

plt.tight_layout()
plt.show()


# In[38]:


# violin plot to examine the shape of each field's production distribution:
plt.figure(figsize=(16, 8))

sns.violinplot(
    data=field_daily,
    x="field_name",
    y="daily_oil",
    inner="quartile",
    cut=0
)

plt.title("Daily Oil Production Distribution by Field")
plt.xlabel("Oil Field")
plt.ylabel("Daily Oil Production (bbl)")
plt.xticks(rotation=45)

plt.tight_layout()
plt.show()


# In[40]:


# Test differences between field distributions

from scipy.stats import levene, kruskal
import pandas as pd

# Create production groups for each field
field_groups = [
    group["daily_oil"].dropna().values
    for name, group in field_daily.groupby("field_name")
]

# Test equality of variances
levene_stat, levene_p = levene(
    *field_groups,
    center="median"
)

# Kruskal-Wallis test
kruskal_stat, kruskal_p = kruskal(
    *field_groups
)

print("LEVENE'S TEST")
print("Statistic:", round(levene_stat, 4))
print("P-value:", levene_p)

print("\nKRUSKAL-WALLIS TEST")
print("Statistic:", round(kruskal_stat, 4))
print("P-value:", kruskal_p)


# In[42]:


# identify which fields differ

from scipy.stats import mannwhitneyu
from statsmodels.stats.multitest import multipletests
from itertools import combinations
import pandas as pd

# Store production observations by field
field_data = {
    name: group["daily_oil"].dropna().values
    for name, group in field_daily.groupby("field_name")
}

results = []

# Compare every possible pair of fields
for field1, field2 in combinations(field_data.keys(), 2):

    values1 = field_data[field1]
    values2 = field_data[field2]

    # Mann-Whitney U test
    statistic, p_value = mannwhitneyu(
        values1,
        values2,
        alternative="two-sided"
    )

    # Rank-biserial correlation based on the Mann-Whitney U statistic.
    # Positive values indicate that Field 1 tends to have higher values
    # than Field 2; negative values indicate the reverse.
    effect_size = (
        (2 * statistic) / (len(values1) * len(values2))
    ) - 1

    results.append({
        "Field 1": field1,
        "Field 2": field2,
        "Mean 1": values1.mean(),
        "Mean 2": values2.mean(),
        "Mean Difference": values1.mean() - values2.mean(),
        "Median 1": np.median(values1),
        "Median 2": np.median(values2),
        "Median Difference": np.median(values1) - np.median(values2),
        "Rank-Biserial Correlation": effect_size,
        "Raw p-value": p_value
    })

pairwise_results = pd.DataFrame(results)

# Correct for multiple comparisons using Holm's method
reject, adjusted_p, _, _ = multipletests(
    pairwise_results["Raw p-value"],
    alpha=0.05,
    method="holm"
)

pairwise_results["Adjusted p-value"] = adjusted_p
pairwise_results["Significant"] = reject

# Sort by adjusted p-value
pairwise_results = pairwise_results.sort_values(
    "Adjusted p-value"
)

display(pairwise_results.round(5))


# In[45]:


# quantify which fields are most consistent

field_stability = (
    field_daily.groupby("field_name")["daily_oil"]
    .agg(
        observations="count",
        mean="mean",
        median="median",
        std="std",
        minimum="min",
        maximum="max",
        q1=lambda x: x.quantile(0.25),
        q3=lambda x: x.quantile(0.75)
    )
)

field_stability["CV_pct"] = (
    field_stability["std"] / field_stability["mean"]
) * 100

field_stability["IQR"] = (
    field_stability["q3"] - field_stability["q1"]
)

field_stability = field_stability.sort_values("CV_pct")

display(field_stability.round(2))


# In[46]:


# monthly production stability by field

# Exclude incomplete November 2026 and future-dated records
completed_daily = field_daily[
    field_daily["production_date"] < "2026-11-01"
].copy()

# Create monthly field-level production
completed_daily["month"] = (
    completed_daily["production_date"].dt.to_period("M")
)

monthly_field = (
    completed_daily
    .groupby(["month", "field_name"], as_index=False)
    .agg(
        monthly_oil=("daily_oil", "sum"),
        active_days=("daily_oil", "count")
    )
)

# Summarise monthly production for each field
monthly_stability = (
    monthly_field
    .groupby("field_name")["monthly_oil"]
    .agg(
        months_observed="count",
        mean_monthly_oil="mean",
        median_monthly_oil="median",
        std_monthly_oil="std",
        minimum="min",
        maximum="max"
    )
)

monthly_stability["CV_pct"] = (
    monthly_stability["std_monthly_oil"]
    / monthly_stability["mean_monthly_oil"]
) * 100

monthly_stability = monthly_stability.sort_values("CV_pct")

display(monthly_stability.round(2))


# In[48]:


# visualise monthly production trends

import matplotlib.pyplot as plt
import pandas as pd

# Ensure months are in chronological order
monthly_field = monthly_field.sort_values(
    ["field_name", "month"]
).copy()

# Calculate 3-month rolling average for each field
monthly_field["rolling_3m"] = (
    monthly_field
    .groupby("field_name")["monthly_oil"]
    .transform(
        lambda x: x.rolling(window=3, min_periods=1).mean()
    )
)

# Convert monthly Period to datetime for plotting
monthly_field["plot_month"] = (
    monthly_field["month"].dt.to_timestamp()
)

# Create a separate subplot for each field
fields = sorted(monthly_field["field_name"].unique())

fig, axes = plt.subplots(
    nrows=5,
    ncols=3,
    figsize=(20, 18)
)

axes = axes.flatten()

for i, field in enumerate(fields):

    field_data = monthly_field[
        monthly_field["field_name"] == field
    ]

    axes[i].plot(
        field_data["plot_month"],
        field_data["monthly_oil"],
        label="Monthly production",
        alpha=0.45
    )

    axes[i].plot(
        field_data["plot_month"],
        field_data["rolling_3m"],
        label="3-month rolling average",
        linewidth=2
    )

    axes[i].set_title(field)
    axes[i].set_ylabel("Oil production (bbl)")
    axes[i].tick_params(axis="x", rotation=45)
    axes[i].grid(alpha=0.3)
    axes[i].legend(fontsize=8)

plt.suptitle(
    "Monthly Oil Production Trends by Field (Jan 2024–Oct 2026)",
    fontsize=16,
    y=1.01
)

plt.tight_layout()
plt.show()


# In[49]:


# statistically measure each field's production trend

from scipy.stats import linregress
import numpy as np
import pandas as pd

trend_results = []

for field, group in monthly_field.groupby("field_name"):

    group = group.sort_values("month").reset_index(drop=True)

    # Use calendar-month positions rather than row positions. This preserves
    # elapsed time when one or more months have no recorded observations.
    x = group["month"].map(lambda period: period.ordinal).to_numpy(dtype=float)
    x = x - x.min()  # express the timeline as months since the first observation
    y = group["monthly_oil"].to_numpy(dtype=float)

    # Linear regression across observed months using actual calendar spacing.
    regression = linregress(x, y)

    mean_production = y.mean()

    # First 3 months and last 3 months
    first_3_months = y[:3].mean()
    last_3_months = y[-3:].mean()

    change_pct = (
        (last_3_months - first_3_months)
        / first_3_months
    ) * 100

    trend_results.append({
        "field_name": field,
        "mean_monthly_oil": mean_production,
        "monthly_slope_bbl": regression.slope,
        "slope_pct_per_month": (
            regression.slope / mean_production
        ) * 100,
        "first_3_month_avg": first_3_months,
        "last_3_month_avg": last_3_months,
        "first_last_change_pct": change_pct,
        "r_squared": regression.rvalue ** 2,
        "p_value": regression.pvalue
    })

field_trends = pd.DataFrame(trend_results)

field_trends = field_trends.sort_values(
    "monthly_slope_bbl"
)

display(field_trends.round(3))

