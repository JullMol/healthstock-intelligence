# Phase 1: Business Understanding
## HealthStock Intelligence — Business Case Document

> **Version:** 1.0  
> **Status:** ✅ Complete  
> **Last Updated:** February 2026

---

## 1. Executive Summary

This project addresses a critical operational inefficiency in Unilever Indonesia's FMCG distribution network: the misalignment between regional public health demand signals and product stock availability. By integrating sales data with regional disease incidence data, we build a predictive intelligence system that enables proactive, health-aware supply chain decisions.

---

## 2. Background & Context

### 2.1 Industry Context

Fast-Moving Consumer Goods (FMCG) companies like Unilever operate on thin margins where **distribution efficiency directly determines profitability**. In Indonesia's archipelago geography, logistics costs can account for up to 15–25% of total operational costs, making supply chain optimization a top strategic priority.

### 2.2 The Gap We're Addressing

Public health data from BPS (Badan Pusat Statistik) and Kemenkes consistently shows **seasonal and regional patterns** in communicable disease outbreaks — ISPA (acute respiratory infections), diarrhea, and dengue fever follow predictable cycles correlated with rainfall, population density, and sanitation access.

However, Unilever's distribution model currently does **not incorporate health risk signals** as a demand driver. This creates a structural blind spot:

- Regions experiencing disease outbreaks = sudden spike in demand for hygiene products
- Current system = reactive restocking after stockout is reported
- Result = lost sales, lost public health impact, damaged retailer relationships

### 2.3 Business Opportunity

If health risk signals can be operationalized as a **leading indicator** for product demand, then Unilever can:
- Pre-position stock before demand spikes
- Prioritize logistics resources to high-opportunity regions
- Quantify and reduce potential lost revenue from stockouts

---

## 3. Problem Statement

> *"Unilever Indonesia's current distribution model is reactive and geography-blind to public health dynamics, resulting in consistent stockouts of hygiene and nutrition products in regions with the highest disease burden and therefore the highest demand potential."*

---

## 4. Business Questions

This project is structured to answer three primary business questions, ordered by strategic priority:

### BQ-01 | Priority Zones
**"Which regions have the largest gap between health risk level and current product availability?"**

- **Why it matters:** Identifies where intervention will have the highest combined business and social impact
- **Output:** Regional segmentation map with 4 quadrants (High/Low Risk × High/Low Stock)
- **Decision it enables:** Where to redirect logistics budget and stock allocation

### BQ-02 | Revenue Gap
**"How much potential revenue is lost due to stockouts in high-risk regions?"**

- **Why it matters:** Translates health risk insight into a financial argument that justifies operational change
- **Output:** Rp-denominated lost revenue estimate per region per quarter
- **Decision it enables:** ROI justification for increasing distribution capacity in priority zones

### BQ-03 | Demand Forecast
**"What is the optimal stock requirement per priority region for the next 3 months?"**

- **Why it matters:** Moves the model from diagnostic to prescriptive — not just "where is the problem" but "what should we do"
- **Output:** 3-month demand forecast with confidence intervals per region
- **Decision it enables:** Proactive purchase orders and logistics scheduling

---

## 5. Success Metrics

| Metric | Definition | Target |
|---|---|---|
| **Forecast Accuracy** | MAPE (Mean Absolute Percentage Error) of Prophet model | < 15% |
| **Clustering Quality** | Silhouette Score of K-Means segmentation | > 0.4 |
| **Health-Demand Correlation** | Pearson/Spearman r between Health Risk Score & Sales Volume | Statistically significant (p < 0.05) |
| **Revenue Gap Quantification** | Ability to calculate Rp lost revenue per region | Fully computable from available data |
| **Dashboard Usability** | All 3 BQs answered within 2 clicks on dashboard | Validated by peer review |

---

## 6. Stakeholder Map

| Stakeholder | Role | Interest |
|---|---|---|
| Supply Chain Director | Primary Decision Maker | Stock allocation efficiency, logistics cost reduction |
| Regional Sales Manager | Data Consumer | Regional performance, target achievement |
| Finance Controller | Data Consumer | Revenue gap visibility, budget justification |
| Public Health Partner | External Stakeholder | Hygiene product access in underserved regions |

---

## 7. Scope & Boundaries

### In Scope
- FMCG product categories: Personal Care (soap, sanitizer) and Home Care (disinfectant)
- Geographic scope: Indonesia, aggregated at Provincial level
- Time period: Historical 2–3 years of sales data + 3-month forward forecast
- Health data: Communicable disease incidence rates (ISPA, Diare, DBD) from BPS

### Out of Scope
- Pricing optimization
- Supplier-side analysis
- Individual SKU-level forecasting (aggregated at category level)
- Real-time data pipeline (static batch analysis)

---

## 8. Assumptions & Risks

| Assumption | Risk if Wrong | Mitigation |
|---|---|---|
| Disease incidence data correlates with hygiene product demand | Correlation may be weak → model loses its core premise | Run correlation test early (EDA phase); pivot to economic indicators if needed |
| BPS regional codes can be mapped to FMCG sales region codes | Mapping mismatch → integration fails | Build explicit mapping table; document all manual decisions |
| Historical sales data is sufficient for meaningful forecasting | Too little data → high forecast error | Check data length before committing to Prophet; fallback to moving average |
| Seasonal disease patterns are relatively stable year-over-year | COVID-19 type disruptions may skew historical patterns | Flag anomaly years; use median instead of mean for baseline |

---

## 9. Analytical Approach Overview

```
Raw Data (FMCG Sales + BPS Health Data)
          │
          ▼
    [Phase 2] Pre-processing & Integration
    → Missing value imputation
    → Outlier detection & handling
    → Region code mapping & merging
    → Health Risk Score engineering (0–100)
          │
          ▼
    [Phase 3] Data Warehouse
    → Snowflake Schema design
    → ETL pipeline (Python + SQL)
    → Fact & Dimension tables
          │
          ▼
    [Phase 4] Analysis & Modeling
    → Correlation analysis (Health Risk vs Sales)
    → K-Means clustering (4-quadrant segmentation)
    → Facebook Prophet forecasting (3-month horizon)
    → Revenue gap calculation
          │
          ▼
    [Phase 5] Power BI Dashboard
    → Executive Summary (KPIs + Map)
    → Health-Demand Correlation view
    → Forecast view with confidence intervals
    → What-If recommendation engine
```

---

## 10. Timeline (Self-Paced Estimate)

| Phase | Estimated Effort | Key Deliverable |
|---|---|---|
| Phase 1: Business Understanding | 1–2 days | This document + README |
| Phase 2: Pre-processing | 3–5 days | Clean datasets + integration notebook |
| Phase 3: Data Warehouse | 2–3 days | SQL schema + ETL script |
| Phase 4: Analysis & ML | 4–6 days | Clustering + forecasting notebooks |
| Phase 5: Dashboard | 3–4 days | Power BI .pbix file |
| **Total** | **~2–3 weeks** | **Full portfolio project** |

---

*Next: [Data Dictionary](data_dictionary.md) → [Methodology](methodology.md)*