# Python Statistical Analysis — Methodology

Notebook: `Oil_and_Gas_Statistical_Analysis.ipynb`

## Analytical dataset

The notebook connects to the PostgreSQL database `oil_gas_analytics` and retrieves the production analytical view `analytics.vw_production_daily`. The analysis is therefore based on the prepared daily production view, not directly on all ten source tables.

The selected production measures include oil, gas and water volumes, production targets and actuals, production variance, target achievement, water cut, operating hours and downtime.

## Methods implemented in the notebook

### 1. Descriptive statistics
Uses Pandas `describe()` to calculate count, mean, standard deviation, minimum, quartiles and maximum. Additional measures include variance, range, skewness, kurtosis, and mean-versus-median comparison.

**Purpose:** describe scale, spread, distribution shape and potential asymmetry in the production measures.

### 2. Data-quality and calculation checks
Investigates negative downtime and target-achievement values above 100%. Recalculates production variance as actual production minus target production and compares it with the stored variance, using a 0.01 barrel tolerance.

**Purpose:** identify suspicious operational values and validate a derived production KPI before interpreting it.

### 3. Distribution and outlier exploration
Uses histograms and boxplots to inspect selected production variables. Quantifies potential outliers using the interquartile range (IQR) rule:

- Lower threshold = Q1 − 1.5 × IQR
- Upper threshold = Q3 + 1.5 × IQR

These are statistical flags for investigation, not automatic evidence of erroneous records.

### 4. Time-series aggregation
Aggregates production measures monthly and annually. Calculates weighted target achievement from summed actual production divided by summed target production, and water cut from total water divided by total water plus total oil. Annual downtime percentage is calculated as downtime divided by operating hours plus downtime.

**Purpose:** compare production and operating indicators over time using aggregated numerators and denominators.

### 5. Correlation analysis
Calculates both:
- **Pearson product-moment correlation** to assess linear association.
- **Spearman rank correlation** to assess monotonic association using ranked observations.

The notebook examines oil versus gas, oil versus operating hours, downtime versus target achievement, and water production versus water cut.

It also calculates p-values for both correlation coefficients and approximate 95% confidence intervals for Pearson's correlation using Fisher's z transformation.

**Interpretation:** correlation describes association, not causation. Very large sample sizes can produce small p-values for modest associations; coefficient magnitude and confidence intervals should be considered alongside statistical significance.

### 6. Field-level production comparison
Aggregates facility observations to daily field-level oil production before comparing fields. Uses boxplots and violin plots to examine distributions.

The notebook applies:
- **Levene's test (median-centred)** to test equality of variances across field groups.
- **Kruskal–Wallis H test** to test whether the field distributions differ overall.
- **Pairwise Mann–Whitney U tests** to investigate field pairs.
- **Holm adjustment** to control family-wise error across pairwise comparisons.
- **Rank-biserial correlation** as an effect-size measure for pairwise comparisons.

### 7. Production stability
Calculates field-level standard deviation, interquartile range and coefficient of variation (CV) for daily oil production. It also calculates monthly production CV using monthly field aggregates.

A lower CV indicates lower relative variability around the mean; it should be interpreted with the underlying production scale and observation count.

### 8. Production trend analysis
Uses SciPy's `linregress` for each field, with the x-variable based on calendar-month ordinals rather than compressed row positions. This preserves elapsed calendar time when a month has no recorded observation. Reports the monthly slope, slope as a percentage of mean monthly production, first-three versus last-three-observed-month average change, R-squared and regression p-value.

This is a linear trend summary over the analysed period, not a reservoir-decline model and not evidence of the cause of a production trend.

## Interpretation and review notes

The pairwise-comparison output reports group means and medians separately, including their differences. The rank-biserial effect-size calculation is oriented to the order of the two field groups: positive values indicate that Field 1 tends to have higher observations than Field 2; negative values indicate the reverse.

The notebook uses non-parametric field comparisons, but it does not include a formal normality test. Do not claim that normality was tested.

Correlation p-values are not adjusted for multiple testing. The Fisher z confidence intervals are conventional approximations and are not adjusted for serial dependence. Daily production observations may be serially dependent, so conventional p-values, confidence intervals and independent-sample test results should be treated as exploratory.

Before interpreting results, review the actual sample sizes, missing-data handling, test statistics and operational context. Statistical significance does not automatically imply operational importance, and none of these observational analyses establishes causation.
