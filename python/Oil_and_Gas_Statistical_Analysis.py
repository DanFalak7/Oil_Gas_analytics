#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Oil & Gas Analytics — statistical analysis
Reads analytics.vw_production_daily from the oil_gas_analytics PostgreSQL database.

Install dependencies:
    pip install pandas numpy sqlalchemy psycopg2-binary scipy statsmodels matplotlib seaborn
"""

from getpass import getpass
from itertools import combinations
import math
import warnings

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import URL, create_engine, text
from scipy.stats import pearsonr, spearmanr, levene, kruskal, mannwhitneyu, linregress
from statsmodels.stats.multitest import multipletests

try:
    from IPython.display import display
except ImportError:
    display = print

warnings.filterwarnings("ignore")
pd.set_option("display.max_columns", None)
pd.set_option("display.float_format", "{:,.3f}".format)
sns.set_theme(style="whitegrid")


def connect_database():
    """Connect to the local PostgreSQL analytics database."""
    url = URL.create(
        "postgresql+psycopg2",
        username="postgres",
        password=getpass("PostgreSQL password: "),
        host="localhost",
        port=5432,
        database="oil_gas_analytics",
    )
    engine = create_engine(url)
    with engine.connect() as conn:
        print("PostgreSQL connection successful.")
        print(conn.execute(text("SELECT version()")).scalar())
    return engine


def load_production_data(engine):
    """Load the production view and perform initial data checks."""
    objects = pd.read_sql(
        """
        SELECT table_name, table_type
        FROM information_schema.tables
        WHERE table_schema = 'analytics'
        ORDER BY table_type, table_name
        """,
        engine,
    )
    print("\nANALYTICS SCHEMA OBJECTS")
    display(objects)

    df = pd.read_sql_query(
        "SELECT * FROM analytics.vw_production_daily",
        engine,
    )
    df["production_date"] = pd.to_datetime(df["production_date"], errors="coerce")
    if df["production_date"].isna().any():
        raise ValueError("Some production_date values could not be parsed.")

    print("\nPRODUCTION DATA")
    print("Shape:", df.shape)
    print("Duplicate rows:", df.duplicated().sum())
    display(df.head())
    missing = pd.DataFrame({
        "Missing Values": df.isna().sum(),
        "Missing Percentage": df.isna().mean().mul(100),
    })
    display(missing)
    return df


def descriptive_and_quality_analysis(df):
    numeric = [
        "production_records", "active_wells", "total_oil_produced_bbl",
        "total_gas_produced_mscf", "total_water_produced_bbl",
        "total_production_target_bbl", "total_actual_production_bbl",
        "total_production_variance_bbl", "production_target_achievement_pct",
        "weighted_water_cut_pct", "total_operating_hours", "total_downtime_hours",
    ]
    numeric = [c for c in numeric if c in df.columns]
    print("\nDESCRIPTIVE STATISTICS")
    display(df[numeric].describe().T)
    extra = pd.DataFrame(index=numeric)
    extra["Variance"] = df[numeric].var()
    extra["Range"] = df[numeric].max() - df[numeric].min()
    extra["Skewness"] = df[numeric].skew()
    extra["Kurtosis"] = df[numeric].kurt()
    display(extra)
    display(pd.DataFrame({
        "Mean": df[numeric].mean(),
        "Median": df[numeric].median(),
        "Mean - Median": df[numeric].mean() - df[numeric].median(),
    }))

    if "total_downtime_hours" in df:
        negative = df[df["total_downtime_hours"] < 0]
        print("\nNegative downtime records:", len(negative))
        display(negative.head(10))

    if {"total_actual_production_bbl", "total_production_target_bbl",
        "total_production_variance_bbl"}.issubset(df.columns):
        calculated = df["total_actual_production_bbl"] - df["total_production_target_bbl"]
        difference = df["total_production_variance_bbl"] - calculated
        print("Variance mismatches above 0.01 bbl:", (difference.abs() > 0.01).sum())
        print("Largest absolute variance difference:", difference.abs().max())


def monthly_and_annual_analysis(df):
    d = df.copy()
    d["month"] = d["production_date"].dt.to_period("M")
    monthly = d.groupby("month").agg(
        total_oil=("total_oil_produced_bbl", "sum"),
        total_gas=("total_gas_produced_mscf", "sum"),
        total_water=("total_water_produced_bbl", "sum"),
        total_target=("total_production_target_bbl", "sum"),
        total_actual=("total_actual_production_bbl", "sum"),
        total_operating_hours=("total_operating_hours", "sum"),
        total_downtime_hours=("total_downtime_hours", "sum"),
        production_days=("production_date", "nunique"),
    ).reset_index()
    monthly["month"] = monthly["month"].dt.to_timestamp()
    monthly["target_achievement_pct"] = (
        monthly["total_actual"] / monthly["total_target"].replace(0, np.nan) * 100
    )
    monthly["water_cut_pct"] = (
        monthly["total_water"]
        / (monthly["total_oil"] + monthly["total_water"]).replace(0, np.nan) * 100
    )
    monthly["production_variance"] = monthly["total_actual"] - monthly["total_target"]
    print("\nMONTHLY PRODUCTION")
    display(monthly.round(2))

    monthly["year"] = monthly["month"].dt.year
    annual = monthly.groupby("year").agg(
        total_oil=("total_oil", "sum"),
        total_gas=("total_gas", "sum"),
        total_water=("total_water", "sum"),
        total_target=("total_target", "sum"),
        total_actual=("total_actual", "sum"),
        total_operating_hours=("total_operating_hours", "sum"),
        total_downtime_hours=("total_downtime_hours", "sum"),
    ).reset_index()
    annual["target_achievement_pct"] = (
        annual["total_actual"] / annual["total_target"].replace(0, np.nan) * 100
    )
    annual["water_cut_pct"] = (
        annual["total_water"]
        / (annual["total_oil"] + annual["total_water"]).replace(0, np.nan) * 100
    )
    annual["downtime_pct"] = (
        annual["total_downtime_hours"]
        / (annual["total_operating_hours"] + annual["total_downtime_hours"]).replace(0, np.nan)
        * 100
    )
    print("\nANNUAL PRODUCTION")
    display(annual.round(2))
    return monthly


def correlation_analysis(df):
    variables = [
        "total_oil_produced_bbl", "total_gas_produced_mscf",
        "total_water_produced_bbl", "total_operating_hours",
        "total_downtime_hours", "weighted_water_cut_pct",
        "production_target_achievement_pct",
    ]
    variables = [c for c in variables if c in df.columns]
    corr_data = df[variables]
    print("\nPEARSON CORRELATION")
    display(corr_data.corr(method="pearson").round(3))
    print("\nSPEARMAN CORRELATION")
    display(corr_data.corr(method="spearman").round(3))

    relationships = [
        ("Oil vs Gas", "total_oil_produced_bbl", "total_gas_produced_mscf"),
        ("Oil vs Operating Hours", "total_oil_produced_bbl", "total_operating_hours"),
        ("Downtime vs Target Achievement", "total_downtime_hours",
         "production_target_achievement_pct"),
        ("Water vs Water Cut", "total_water_produced_bbl", "weighted_water_cut_pct"),
    ]
    results = []
    for name, x, y in relationships:
        if x not in df or y not in df:
            continue
        data = df[[x, y]].dropna()
        if len(data) < 4 or data[x].nunique() < 2 or data[y].nunique() < 2:
            continue
        r, p_r = pearsonr(data[x], data[y])
        rho, p_s = spearmanr(data[x], data[y])
        z = np.arctanh(np.clip(r, -0.999999, 0.999999))
        se = 1 / np.sqrt(len(data) - 3)
        results.append({
            "Relationship": name, "N": len(data), "Pearson r": r,
            "Pearson CI lower": np.tanh(z - 1.96 * se),
            "Pearson CI upper": np.tanh(z + 1.96 * se),
            "Pearson p": p_r, "Spearman rho": rho, "Spearman p": p_s,
        })
    result_df = pd.DataFrame(results)
    if not result_df.empty:
        p_cols = ["Pearson p", "Spearman p"]
        raw = result_df[p_cols].to_numpy().ravel()
        _, adjusted, _, _ = multipletests(raw, method="holm")
        result_df["Pearson Holm p"] = adjusted[0::2]
        result_df["Spearman Holm p"] = adjusted[1::2]
        print("\nCORRELATION TESTS AND APPROXIMATE PEARSON CONFIDENCE INTERVALS")
        display(result_df.round(6))
    print(
        "Caution: daily observations may be serially dependent. Conventional "
        "correlation p-values and Fisher-z confidence intervals do not adjust "
        "for time-series dependence and should be treated as exploratory."
    )


def field_level_analysis(df):
    field_daily = df.groupby(
        ["production_date", "field_id", "field_name"], as_index=False
    ).agg(
        daily_oil=("total_oil_produced_bbl", "sum"),
        daily_gas=("total_gas_produced_mscf", "sum"),
        daily_water=("total_water_produced_bbl", "sum"),
        daily_operating_hours=("total_operating_hours", "sum"),
        daily_downtime_hours=("total_downtime_hours", "sum"),
        daily_target=("total_production_target_bbl", "sum"),
        daily_actual=("total_actual_production_bbl", "sum"),
    )
    print("\nFIELD-LEVEL PRODUCTION SUMMARY")
    display(field_daily.groupby("field_name").agg(
        observations=("daily_oil", "count"),
        mean_daily_oil=("daily_oil", "mean"),
        median_daily_oil=("daily_oil", "median"),
        total_oil=("daily_oil", "sum"),
    ).round(2).sort_values("mean_daily_oil", ascending=False))

    groups = {
        name: group["daily_oil"].dropna().to_numpy()
        for name, group in field_daily.groupby("field_name")
    }
    groups = {name: values for name, values in groups.items() if len(values)}
    if len(groups) < 2:
        print("At least two fields with observations are required for group tests.")
        return field_daily, None

    values = list(groups.values())
    lev_stat, lev_p = levene(*values, center="median")
    kw_stat, kw_p = kruskal(*values)
    print("\nMEDIAN-CENTRED LEVENE TEST:", lev_stat, lev_p)
    print("KRUSKAL-WALLIS TEST:", kw_stat, kw_p)
    print(
        "Levene tests equality of variances. Kruskal-Wallis tests equality of "
        "rank distributions; it is not automatically a test of medians unless "
        "distribution shapes are comparable."
    )

    pairwise = []
    for field1, field2 in combinations(sorted(groups), 2):
        a, b = groups[field1], groups[field2]
        u, p = mannwhitneyu(a, b, alternative="two-sided", method="asymptotic")
        n1, n2 = len(a), len(b)
        pairwise.append({
            "Field 1": field1, "Field 2": field2, "N 1": n1, "N 2": n2,
            "Mean 1": a.mean(), "Mean 2": b.mean(),
            "Median 1": np.median(a), "Median 2": np.median(b),
            "Mean Difference (1-2)": a.mean() - b.mean(),
            "Median Difference (1-2)": np.median(a) - np.median(b),
            "Rank-Biserial r (1 vs 2)": 2 * u / (n1 * n2) - 1,
            "Raw p-value": p,
        })
    pair_df = pd.DataFrame(pairwise)
    if not pair_df.empty:
        reject, adj, _, _ = multipletests(pair_df["Raw p-value"], method="holm")
        pair_df["Holm-adjusted p-value"] = adj
        pair_df["Significant (Holm, 0.05)"] = reject
        pair_df = pair_df.sort_values("Holm-adjusted p-value")
        print("\nPAIRWISE MANN-WHITNEY TESTS")
        display(pair_df.round(5))
        print(
            "Positive rank-biserial values mean Field 1 tends to rank higher "
            "than Field 2; negative values mean the reverse. Reversing field "
            "order reverses the sign."
        )
    print(
        "Design limitation: daily observations within fields may be serially "
        "dependent. These independent-sample tests are exploratory and are "
        "not time-series-adjusted."
    )
    return field_daily, pair_df


def field_trend_analysis(field_daily):
    # Exclude November 2026 and later because November is incomplete.
    completed = field_daily[
        field_daily["production_date"] < pd.Timestamp("2026-11-01")
    ].copy()
    completed["month"] = completed["production_date"].dt.to_period("M")
    monthly_field = completed.groupby(
        ["month", "field_name"], as_index=False
    ).agg(
        monthly_oil=("daily_oil", "sum"),
        observed_daily_records=("daily_oil", "count"),
    )

    stability = monthly_field.groupby("field_name")["monthly_oil"].agg(
        months_observed="count", mean_monthly_oil="mean",
        median_monthly_oil="median", std_monthly_oil="std",
        minimum="min", maximum="max",
    )
    stability["CV_pct"] = (
        stability["std_monthly_oil"] / stability["mean_monthly_oil"].replace(0, np.nan) * 100
    )
    print("\nMONTHLY FIELD PRODUCTION STABILITY")
    display(stability.sort_values("CV_pct").round(2))

    trends = []
    for field, group in monthly_field.groupby("field_name"):
        group = group.sort_values("month").copy()
        month_index = group["month"].map(lambda p: p.year * 12 + p.month)
        x = (month_index - month_index.min()).to_numpy(dtype=float)
        y = group["monthly_oil"].to_numpy(dtype=float)
        if len(y) < 3 or np.unique(x).size < 2:
            continue
        fit = linregress(x, y)
        mean_y = y.mean()
        first, last = y[:3].mean(), y[-3:].mean()
        trends.append({
            "field_name": field, "months_observed": len(y),
            "monthly_slope_bbl": fit.slope,
            "slope_pct_of_mean_per_month": fit.slope / mean_y * 100 if mean_y else np.nan,
            "first_3_observed_month_avg": first,
            "last_3_observed_month_avg": last,
            "first_last_change_pct": (last - first) / first * 100 if first else np.nan,
            "r_squared": fit.rvalue ** 2, "p_value": fit.pvalue,
        })
    trend_df = pd.DataFrame(trends).sort_values("monthly_slope_bbl")
    print("\nLINEAR MONTHLY PRODUCTION TRENDS")
    display(trend_df.round(3))
    print(
        "Trend p-values are ordinary least-squares results and do not account "
        "for potential autocorrelation in monthly production series."
    )

    monthly_field = monthly_field.sort_values(["field_name", "month"]).copy()
    monthly_field["rolling_3m"] = monthly_field.groupby("field_name")["monthly_oil"].transform(
        lambda s: s.rolling(3, min_periods=1).mean()
    )
    monthly_field["plot_month"] = monthly_field["month"].dt.to_timestamp()
    fields = sorted(monthly_field["field_name"].unique())
    ncols = 3
    nrows = math.ceil(len(fields) / ncols)
    fig, axes = plt.subplots(nrows, ncols, figsize=(20, 4 * nrows), squeeze=False)
    axes = axes.flatten()
    for i, field in enumerate(fields):
        subset = monthly_field[monthly_field["field_name"] == field]
        axes[i].plot(subset["plot_month"], subset["monthly_oil"],
                     label="Monthly production", alpha=0.45)
        axes[i].plot(subset["plot_month"], subset["rolling_3m"],
                     label="3-month rolling average", linewidth=2)
        axes[i].set_title(field)
        axes[i].set_ylabel("Oil production (bbl)")
        axes[i].tick_params(axis="x", rotation=45)
        axes[i].grid(alpha=0.3)
        axes[i].legend(fontsize=8)
    for ax in axes[len(fields):]:
        ax.set_visible(False)
    plt.suptitle("Monthly Oil Production Trends by Field (Jan 2024–Oct 2026)")
    plt.tight_layout()
    plt.show()
    return monthly_field, trend_df


def main():
    engine = connect_database()
    try:
        production_df = load_production_data(engine)
        descriptive_and_quality_analysis(production_df)
        monthly_and_annual_analysis(production_df)
        correlation_analysis(production_df)
        field_daily, _ = field_level_analysis(production_df)
        field_trend_analysis(field_daily)
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
