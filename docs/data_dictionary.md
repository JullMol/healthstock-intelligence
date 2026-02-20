# Data Dictionary
## HealthStock Intelligence

> **Version:** 2.0  
> **Status:** ✅ Complete
> **Last Updated:** February 2026

---

## 1. Data Sources

### DS-01 | FMCG Sales & Demand Data
| Attribute | Detail |
|---|---|
| **Source** | Kaggle: FMCG Sales & Demand Forecasting |
| **Format** | CSV |
| **Granularity** | Transaction-level (per product, per region, per date) |
| **Period** | 2022–2024 |
| **Key Fields** | `product_id`, `region`, `date`, `units_sold`, `revenue`, `stock_level` |

### DS-02 | Regional Health Incidence Data
| Attribute | Detail |
|---|---|
| **Source** | BPS (bps.go.id) — Statistik Kesehatan / Kemenkes |
| **Format** | Excel / CSV |
| **Granularity** | Province-level, annual |
| **Diseases Tracked** | ISPA (Acute Respiratory Infection), Diare (Diarrhea), DBD (Dengue Fever), Pneumonia |
| **metric** | Incidence Rate (per 1,000 population) |

### DS-03 | Seasonal / Calendar Features
| Attribute | Detail |
|---|---|
| **Source** | Custom-engineered based on BMKG & Hijri Calendar |
| **Granularity** | Monthly |
| **Fields** | `is_rainy_season` (Oct–Mar), `is_ramadan` (Sliding window), `is_school_holiday` (Jun/Dec) |

---

## 2. Engineered Features

### Health Risk Score (HRS)
| Attribute | Detail |
|---|---|
| **Type** | Engineered Feature |
| **Range** | 0 (lowest risk) — 100 (highest risk) |
| **Formula** | Weighted sum of normalized disease incidence rates |
| **Formula Detail** | `HRS = (0.35 × norm_ISPA) + (0.30 × norm_Diare) + (0.25 × norm_DBD) + (0.10 × norm_Pneumonia)` |
| **Normalization** | Min-Max scaling per disease type |
| **Rationale** | ISPA and Diare weighted higher as they have strongest correlation with hygiene product demand (hand soap, sanitizer, oral rehydration). |

### Cluster Label (Segmentation)
| Cluster | Definition | Business Implication |
|---|---|---|
| 🔴 **Critical Gap** | High Health Risk + Low Stock Availability | Immediate restocking priority; high revenue loss risk |
| 🟠 **Underserved** | High Health Risk + Moderate Stock | Monitor closely; potential future gap |
| 🟡 **Well-Served** | High/Low Risk + High Stock Availability | Optimal or safe zone |
| 🟢 **Surplus** | Low Health Risk + High Stock Availability | Potential overstock; consider reallocation |

---

## 3. Data Warehouse Schema Fields

### Fact_Sales
| Field | Type | Description |
|---|---|---|
| sale_id | INT (PK) | Surrogate key |
| product_id | INT (FK) | → Dim_Product |
| location_id | INT (FK) | → Dim_Location |
| time_id | INT (FK) | → Dim_Time |
| units_sold | INT | Number of units sold |
| revenue | DECIMAL(15,2) | Revenue in IDR |
| stock_level | INT | Remaining stock at time of sale |

### Fact_Health_Index
| Field | Type | Description |
|---|---|---|
| health_id | INT (PK) | Surrogate key |
| location_id | INT (FK) | → Dim_Location |
| time_id | INT (FK) | → Dim_Time |
| ispa_rate | DECIMAL(8,2) | ISPA incidence per 1000 population |
| diare_rate | DECIMAL(8,2) | Diarrhea incidence per 1000 population |
| health_risk_score | DECIMAL(5,2) | Engineered HRS (0–100) |

### Dim_Health_Context
| Field | Type | Description |
|---|---|---|
| context_id | INT (PK) | Surrogate key |
| location_id | INT (FK) | → Dim_Location |
| cluster_label | VARCHAR(30) | K-Means result (e.g., "Critical Gap") |
| priority_rank | INT | Rank 1 = most urgent intervention needed |
| recommended_action | VARCHAR(100) | Prescriptive action (e.g., "Increase Stock +15%") |

---

## 4. Region Code Mapping Table

This table maps the internal FMCG region codes to official BPS province codes used for health data integration.

| FMCG Region Name | BPS Province Code | BPS Province Name | Mapping Status |
|---|---|---|---|
| **PL-Central** | 31 / 32 / 33 | DKI Jakarta / Jawa Barat / Jawa Tengah | ✅ Mapped (Aggregated) |
| **PL-North** | 12 / 13 / 14 | Sumatera Utara / Barat / Riau | ✅ Mapped (Aggregated) |
| **PL-South** | 73 / 74 | Sulawesi Selatan / Tenggara | ✅ Mapped (Aggregated) |

> **Note:** For this portfolio project, FMCG regions are aggregated distribution hubs covering multiple provinces. Health data was aggregated using population-weighted averages to match these hubs.