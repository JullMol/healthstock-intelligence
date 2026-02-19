# 🏥 HealthStock Intelligence
### Predicting Consumer Health Demand for FMCG Distribution Optimization

> **Role:** Data Analyst & Data Scientist  
> **Industry:** FMCG (Consumer Goods) × Public Health × Supply Chain Analytics  
> **Stack:** Python · SQL · Power BI · Prophet · Scikit-learn

---

## 🚨 The Problem

Unilever Indonesia spends billions on logistics — yet hygiene and nutrition products (soap, vitamins, sanitizers) consistently run out in the regions that need them most. The current distribution model is **reactive**: restock happens after stockout. Meanwhile, public health data shows predictable patterns of disease outbreaks that directly drive demand spikes.

**The result:** Lost revenue, missed public health impact, and inefficient supply chains.

---

## 💡 The Solution

HealthStock Intelligence is an end-to-end data pipeline that integrates **FMCG sales data** with **regional public health data** to answer three critical business questions:

| # | Business Question | Output |
|---|---|---|
| 1 | Which regions have the largest gap between health risk and product availability? | Priority Zone Map |
| 2 | How much potential revenue is lost due to stockouts in high-risk areas? | Revenue Gap Report |
| 3 | What is the optimal stock requirement per region for the next 3 months? | Demand Forecast |

---

## 📊 Key Results

> *(To be updated after analysis is complete)*

- 🔴 **X regions** identified as High Risk – Low Stock priority zones
- 💸 **Rp X billion** in potential lost revenue identified
- 📦 **X% improvement** in stock allocation efficiency (simulated)
- 📈 Demand forecast accuracy: **X% MAPE** using Facebook Prophet

---

## 🗂️ Project Structure

```
healthstock-intelligence/
│
├── 📁 data/
│   ├── raw/                    # Original datasets (untouched)
│   └── processed/              # Cleaned & integrated datasets
│
├── 📁 notebooks/
│   ├── 01_eda_fmcg.ipynb           # Exploratory Data Analysis - Sales
│   ├── 02_eda_health.ipynb         # Exploratory Data Analysis - Health
│   ├── 03_preprocessing.ipynb      # Data Cleaning & Integration
│   ├── 04_dwh_etl.ipynb            # ETL Pipeline to DWH Schema
│   ├── 05_analysis_clustering.ipynb # K-Means Segmentation
│   └── 06_forecasting.ipynb        # Demand Forecasting with Prophet
│
├── 📁 sql/
│   ├── schema_dwh.sql          # Snowflake Schema DDL
│   ├── etl_transform.sql       # ETL transformation queries
│   └── analysis_queries.sql    # Business insight queries
│
├── 📁 dashboard/
│   └── healthstock_dashboard.pbix  # Power BI Dashboard
│
├── 📁 docs/
│   ├── business_case.md        # Phase 1: Business Understanding
│   ├── data_dictionary.md      # Field definitions & sources
│   └── methodology.md          # Technical approach & decisions
│
└── README.md
```

---

## 🔄 Project Phases

```
Phase 1: Business Understanding      ✅ Done
Phase 2: Data Pre-processing         🔄 In Progress
Phase 3: Data Warehouse (DWH)        ⏳ Pending
Phase 4: Analysis & ML Modeling      ⏳ Pending
Phase 5: Power BI Dashboard          ⏳ Pending
```

---

## 📦 Datasets Used

| Dataset | Source | Description |
|---|---|---|
| FMCG Sales & Demand | Kaggle | Product-level sales transactions by region |
| Regional Disease Data | BPS / Kemenkes | Incidence rates of communicable diseases per province |
| Seasonal Calendar | BMKG / Custom | Rainy season & epidemiological calendar features |

---

## 🛠️ Tech Stack

| Layer | Tools |
|---|---|
| Data Cleaning & EDA | Python (Pandas, NumPy, Matplotlib, Seaborn) |
| Machine Learning | Scikit-learn (K-Means), Facebook Prophet |
| Data Warehouse | PostgreSQL (Snowflake Schema) |
| Visualization | Power BI |
| Version Control | Git & GitHub |

---

## 🧠 Methodology Highlights

- **Health Risk Score:** Custom-engineered feature (0–100) normalized from BPS disease incidence data per province — maps regional health burden to a single comparable metric
- **K-Means Clustering:** Segments all regions into 4 strategic quadrants based on Health Risk Score vs Stock Availability
- **Facebook Prophet:** Time-series forecasting with automatic seasonality detection (rainy season, Eid, etc.) for 3-month stock demand prediction
- **Revenue Gap Analysis:** Quantifies lost opportunity = `(Predicted Demand − Actual Stock) × Avg Selling Price`

---

## 📬 Contact

**Dimas Rafi Izzulhaq**  
[LinkedIn](www.linkedin.com/in/dimas-rafi-izzulhaq-b94058378) · [dimasrafii@gmail.com](mailto:dimasizzulhaq35@gmail.com) · [GitHub](https://github.com/JullMol)

---

*This project is built as a portfolio capstone demonstrating end-to-end data analytics and data science capabilities across business intelligence, data engineering, and predictive modeling.*