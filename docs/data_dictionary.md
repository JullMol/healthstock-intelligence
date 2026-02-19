# Data Dictionary
## HealthStock Intelligence

> **Version:** 1.0  
> **Status:** 🔄 Draft (to be updated after data acquisition)

---

## 1. Data Sources

### DS-01 | FMCG Sales & Demand Data
| Attribute | Detail |
|---|---|
| **Source** | Kaggle: FMCG Sales & Demand Forecasting |
| **Format** | CSV |
| **Granularity** | Transaction-level (per product, per region, per date) |
| **Expected Fields** | Product ID, Product Category, Region, Date, Units Sold, Revenue, Stock Level |
| **Known Issues** | Missing values in stock fields, inconsistent region naming |

### DS-02 | Regional Health Incidence Data
| Attribute | Detail |
|---|---|
| **Source** | BPS (bps.go.id) — Statistik Kesehatan / Kemenkes |
| **Format** | XLS / CSV |
| **Granularity** | Province-level, annual or quarterly |
| **Expected Fields** | Province Code, Province Name, Year, Disease Type, Incidence Rate (per 1000 population) |
| **Diseases Tracked** | ISPA, Diare, DBD (Dengue), Pneumonia |

### DS-03 | Seasonal / Calendar Features
| Attribute | Detail |
|---|---|
| **Source** | BMKG / Custom-engineered |
| **Format** | CSV (manually constructed) |
| **Granularity** | Monthly, national |
| **Fields** | Month, Is_Rainy_Season (bool), Is_Ramadan (bool), Is_School_Holiday (bool) |

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
| **Rationale** | ISPA and Diare weighted higher as they have strongest correlation with hygiene product demand (hand soap, sanitizer, oral rehydration) |

> **Note:** Weights above are initial assumptions and will be validated against correlation analysis results in Phase 4.

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
| gross_margin | DECIMAL(15,2) | Revenue minus COGS |
| stock_level | INT | Remaining stock at time of sale |

### Fact_Health_Index
| Field | Type | Description |
|---|---|---|
| health_id | INT (PK) | Surrogate key |
| location_id | INT (FK) | → Dim_Location |
| time_id | INT (FK) | → Dim_Time |
| ispa_rate | DECIMAL(8,2) | ISPA incidence per 1000 population |
| diare_rate | DECIMAL(8,2) | Diarrhea incidence per 1000 population |
| dbd_rate | DECIMAL(8,2) | Dengue incidence per 1000 population |
| pneumonia_rate | DECIMAL(8,2) | Pneumonia incidence per 1000 population |
| health_risk_score | DECIMAL(5,2) | Engineered HRS (0–100) |

### Dim_Product
| Field | Type | Description |
|---|---|---|
| product_id | INT (PK) | Surrogate key |
| product_name | VARCHAR(100) | Product name |
| category | VARCHAR(50) | e.g., Personal Care, Home Care |
| subcategory | VARCHAR(50) | e.g., Hand Soap, Disinfectant |
| brand | VARCHAR(50) | Unilever brand name |

### Dim_Location
| Field | Type | Description |
|---|---|---|
| location_id | INT (PK) | Surrogate key |
| province_code | VARCHAR(10) | BPS province code |
| province_name | VARCHAR(100) | Province name (standardized) |
| island_group | VARCHAR(50) | e.g., Jawa, Sumatera, Kalimantan |
| bps_code | VARCHAR(10) | Official BPS region code for data joining |

### Dim_Time
| Field | Type | Description |
|---|---|---|
| time_id | INT (PK) | Surrogate key |
| date | DATE | Full date |
| year | INT | Year |
| quarter | INT | Quarter (1–4) |
| month | INT | Month (1–12) |
| month_name | VARCHAR(20) | Month name |
| is_rainy_season | BOOLEAN | Based on BMKG definition |
| is_ramadan | BOOLEAN | Ramadan period flag |

### Dim_Health_Context
| Field | Type | Description |
|---|---|---|
| context_id | INT (PK) | Surrogate key |
| location_id | INT (FK) | → Dim_Location |
| risk_category | VARCHAR(20) | HIGH / MEDIUM / LOW |
| cluster_label | VARCHAR(30) | K-Means cluster result (e.g., "High Risk - Low Stock") |
| priority_rank | INT | Rank 1 = most urgent intervention needed |

---

## 4. Region Code Mapping Table

> *(To be built manually during Phase 2)*

This table is critical for joining DS-01 (FMCG data, which may use internal region names) with DS-02 (BPS data, which uses official province codes). Any unmapped regions must be documented here.

| FMCG Region Name | BPS Province Code | BPS Province Name | Mapping Status |
|---|---|---|---|
| *(To be filled)* | *(To be filled)* | *(To be filled)* | ⏳ Pending |

---

*Next: [Methodology](methodology.md)*