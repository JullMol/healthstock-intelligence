# Methodology
## HealthStock Intelligence — Technical Approach

> **Version:** 1.0  
> **Status:** 🔄 Living Document (updated per phase)

---

## 1. Overall Approach

This project follows a **business-first, data-second** methodology. Every technical decision is made in service of answering the three core business questions (see `business_case.md`). This means:

- We do **not** apply a technique unless it produces an interpretable business output
- We **document every decision** including why alternatives were rejected
- We **acknowledge uncertainty** explicitly (e.g., confidence intervals in forecasting)

---

## 2. Phase 2 — Pre-processing Methodology

### 2.1 Missing Value Treatment

| Scenario | Method | Rationale |
|---|---|---|
| Sales volume missing (<5% of column) | Median imputation | Robust to skewed sales distributions |
| Sales volume missing (>5% of column) | Forward-fill (time series) | Preserves temporal continuity |
| Stock level missing | Linear interpolation | Stock levels change gradually |
| Health incidence missing | Province-year mean imputation | Avoid cross-year contamination |
| Missing entire region | Flag & document; exclude from model | Do not impute structural missingness |

> **Key principle:** We never impute target variables (units_sold) that will be used in forecasting training. If target is missing, the row is dropped.

### 2.2 Outlier Detection & Handling

Method: **IQR-based detection** with manual review for business context.

```
Lower Bound = Q1 - 1.5 × IQR
Upper Bound = Q3 + 1.5 × IQR
```

**Important distinction:**
- Outliers from **data entry errors** (e.g., negative units sold, revenue = 0 with units > 0) → **Remove**
- Outliers from **genuine demand spikes** (e.g., sales surge during disease outbreak) → **Keep & flag**

> This distinction is critical. Blindly removing all outliers would destroy the exact signal we are trying to capture.

### 2.3 Health Risk Score Engineering

**Formula:**
```
HRS = (0.35 × norm_ISPA) + (0.30 × norm_Diare) + (0.25 × norm_DBD) + (0.10 × norm_Pneumonia)
```

**Normalization:** Min-Max per disease type across all provinces and years.
```python
norm_x = (x - x.min()) / (x.max() - x.min())
```

**Validation:** After engineering, correlation between HRS and hygiene product sales will be tested. If Pearson r < 0.2 and p > 0.05, weights will be reassigned or alternative health indicators explored.

### 2.4 Region Code Standardization

FMCG datasets often use internal naming conventions that differ from BPS official province codes. Steps:
1. Extract unique region names from FMCG dataset
2. Manually map to BPS province codes
3. Validate coverage (flag any unmapped regions)
4. Store in `data/processed/region_mapping.csv`

---

## 3. Phase 3 — Data Warehouse Methodology

### 3.1 Schema Design: Snowflake Schema

We chose **Snowflake Schema** over Star Schema because:
- `Dim_Location` requires normalization (Province → Island Group hierarchy)
- `Dim_Health_Context` is a dependent dimension of `Dim_Location`
- Storage efficiency matters less than query clarity for this analytical use case

### 3.2 ETL Pipeline

```
Extract:   Load raw CSVs into Python (Pandas)
Transform: Apply all Phase 2 cleaning steps
           Engineer HRS feature
           Build surrogate keys
           Enforce referential integrity
Load:      Write to PostgreSQL using SQLAlchemy
```

All ETL steps are logged. Transformation decisions are recorded in notebook `04_dwh_etl.ipynb`.

---

## 4. Phase 4 — Analysis & Modeling Methodology

### 4.1 Correlation Analysis

**Method:** Pearson correlation (if normality confirmed via Shapiro-Wilk) or Spearman rank correlation (if non-normal).

**Variables:**
- X: Health Risk Score (HRS) per province per quarter
- Y: Sales volume of hygiene products per province per quarter

**Reporting:** r value, p-value, and scatter plot with regression line.

### 4.2 K-Means Clustering

**Features used:**
- Health Risk Score (HRS) — normalized
- Stock Availability Rate = `(avg_stock_level / avg_demand)` — normalized

**K selection:** Elbow method + Silhouette score. We expect K=4 to naturally emerge (2×2 quadrant logic), but will validate empirically.

**Cluster Labels (expected):**
| Cluster | HRS | Stock Rate | Label | Priority |
|---|---|---|---|---|
| A | High | Low | 🔴 Critical Gap | 1 |
| B | High | High | 🟡 Well-Served | 3 |
| C | Low | Low | 🟠 Underserved | 2 |
| D | Low | High | 🟢 Surplus | 4 |

### 4.3 Demand Forecasting (Facebook Prophet)

**Why Prophet over ARIMA:**
- Handles multiple seasonality (yearly disease cycle + Ramadan + rainy season) automatically
- Provides interpretable trend decomposition
- More robust to missing data and irregular timestamps
- Forecast output is easier to explain to non-technical stakeholders

**Model inputs:**
- Time series: monthly units sold per product category per province
- Regressors: `is_rainy_season`, `is_ramadan`, `health_risk_score` (lagged 1 month)

**Forecast horizon:** 3 months

**Evaluation:** Train on all data except last 3 months; evaluate on holdout using MAPE.

**Target:** MAPE < 15%

### 4.4 Revenue Gap Analysis

```
Potential Lost Revenue = (Forecasted Demand - Actual Stock) × Avg Selling Price

where:
  Forecasted Demand  = Prophet prediction for next quarter
  Actual Stock       = Current stock level from latest data snapshot
  Avg Selling Price  = Category-level average from historical data
  (only calculated where Forecasted Demand > Actual Stock)
```

---

## 5. Phase 5 — Dashboard Design Methodology

### 5.1 Dashboard Structure

The dashboard follows a **Pyramid of Insight** layout — starting from the highest-level summary and allowing drill-down into detail.

| Page | Title | Primary Audience | Key Visual |
|---|---|---|---|
| 1 | Executive Summary | C-Level / Director | KPI Cards + Indonesia Choropleth Map |
| 2 | Health-Demand Analysis | Analyst / Manager | Scatter Plot + Segmentation Table |
| 3 | Demand Forecast | Supply Chain Team | Prophet Chart + Confidence Bands |
| 4 | What-If Simulator | Business User | Sliders + Dynamic Revenue Projection |

### 5.2 Design Principles

- **One message per visual:** Each chart answers exactly one question
- **Color consistency:** Red = High Risk / Alert, Green = Healthy, Grey = Neutral
- **No decoration:** Every visual element must carry information
- **Mobile-aware layout:** Key KPIs visible without scrolling on 1080p screen

---

## 6. Decision Log

> All significant analytical decisions are recorded here for transparency.

| Date | Decision | Alternatives Considered | Reason for Choice |
|---|---|---|---|
| Feb 2026 | Use Facebook Prophet for forecasting | ARIMA, LSTM | Better seasonality handling; more interpretable |
| Feb 2026 | Use BPS health data over Kaggle stroke dataset | Kaggle stroke prediction | BPS is province-aggregated; directly mappable to FMCG regions |
| Feb 2026 | Snowflake schema over Star schema | Star schema | Location hierarchy requires normalization |
| Feb 2026 | K=4 as initial K-Means target | K=3, K=5 | 2×2 quadrant logic aligns with business framing; validated empirically |

---

*This document is updated at each phase milestone.*