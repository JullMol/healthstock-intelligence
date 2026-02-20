DROP SCHEMA IF EXISTS dwh CASCADE;
CREATE SCHEMA dwh;
SET search_path TO dwh;

-- SUB-DIMENSION TABLES (Level 3 — leaf nodes of snowflake)
-- Dim_Island_Group
-- Highest geographic level: groups of islands
CREATE TABLE dwh.dim_island_group (
    island_group_id     SERIAL          PRIMARY KEY,
    island_group_name   VARCHAR(80)     NOT NULL UNIQUE,
    description         TEXT
);
COMMENT ON TABLE dwh.dim_island_group IS
    'Top-level geographic grouping: Sumatera, Jawa, Kalimantan, Sulawesi, Maluku-Papua.';


-- Dim_Category
-- Product category master (sub-dimension of Dim_Product)
CREATE TABLE dwh.dim_category (
    category_id         SERIAL          PRIMARY KEY,
    category_name       VARCHAR(50)     NOT NULL UNIQUE,
    is_health_related   BOOLEAN         NOT NULL DEFAULT FALSE,
    description         TEXT
);
COMMENT ON TABLE dwh.dim_category IS
    'FMCG product category. is_health_related flags nutrition/hygiene categories.';

-- DIMENSION TABLES (Level 2 — mid nodes of snowflake)
-- Dim_Region
-- PL distribution region, references Dim_Island_Group
CREATE TABLE dwh.dim_region (
    region_id           SERIAL          PRIMARY KEY,
    pl_region           VARCHAR(20)     NOT NULL UNIQUE,  -- PL-Central, PL-North, etc.
    island_group_id     INT             NOT NULL REFERENCES dwh.dim_island_group(island_group_id),
    region_description  VARCHAR(100)
);
COMMENT ON TABLE dwh.dim_region IS
    'FMCG distribution region (PL-codes). References Dim_Island_Group.';

-- Dim_Product
-- Product master, references Dim_Category
CREATE TABLE dwh.dim_product (
    product_id          SERIAL          PRIMARY KEY,
    sku_code            VARCHAR(20)     NOT NULL,
    brand_name          VARCHAR(50)     NOT NULL,
    market_segment      VARCHAR(50)     NOT NULL,
    pack_type           VARCHAR(30)     NOT NULL,
    category_id         INT             NOT NULL REFERENCES dwh.dim_category(category_id),
    UNIQUE (sku_code, pack_type)
);
COMMENT ON TABLE dwh.dim_product IS
    'FMCG product. References Dim_Category (snowflake normalization).';

-- DIMENSION TABLES (Level 1 — direct FK to Fact tables)
-- Dim_Time
CREATE TABLE dwh.dim_time (
    time_id             SERIAL          PRIMARY KEY,
    full_date           DATE            NOT NULL UNIQUE,
    year                SMALLINT        NOT NULL,
    quarter             SMALLINT        NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    month               SMALLINT        NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name          VARCHAR(20)     NOT NULL,
    week_of_year        SMALLINT        NOT NULL,
    day_of_week         SMALLINT        NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    day_name            VARCHAR(20)     NOT NULL,
    is_weekend          BOOLEAN         NOT NULL DEFAULT FALSE,
    year_month          CHAR(7)         NOT NULL,
    is_rainy_season     BOOLEAN         NOT NULL DEFAULT FALSE,
    is_dengue_peak      BOOLEAN         NOT NULL DEFAULT FALSE,
    is_school_holiday   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_ramadan          BOOLEAN         NOT NULL DEFAULT FALSE,
    is_lebaran          BOOLEAN         NOT NULL DEFAULT FALSE
);
COMMENT ON TABLE dwh.dim_time IS
    'Full date spine 2022-01-01 to 2024-12-31 with Indonesian seasonal flags.';

-- Dim_Location
-- Province level, references Dim_Region (which references Dim_Island_Group)
CREATE TABLE dwh.dim_location (
    location_id         SERIAL          PRIMARY KEY,
    province_name       VARCHAR(100)    NOT NULL UNIQUE,
    region_id           INT             NOT NULL REFERENCES dwh.dim_region(region_id)
);
COMMENT ON TABLE dwh.dim_location IS
    '38 Indonesian provinces. References Dim_Region → Dim_Island_Group (snowflake chain).';

-- Dim_Health_Context
-- Regional health risk per year, references Dim_Region
CREATE TABLE dwh.dim_health_context (
    context_id              SERIAL          PRIMARY KEY,
    year                    SMALLINT        NOT NULL,
    region_id               INT             NOT NULL REFERENCES dwh.dim_region(region_id),
    health_complaint_pct    NUMERIC(5,2),
    health_risk_score       NUMERIC(5,2)    CHECK (health_risk_score BETWEEN 0 AND 100),
    risk_category           VARCHAR(10)     NOT NULL CHECK (risk_category IN ('HIGH','MEDIUM','LOW')),
    stock_category          VARCHAR(10)     NOT NULL CHECK (stock_category IN ('HIGH','MEDIUM','LOW')),
    strategic_quadrant      VARCHAR(30)     NOT NULL,
    priority_rank           SMALLINT        NOT NULL CHECK (priority_rank BETWEEN 1 AND 4),
    UNIQUE (year, region_id, stock_category)
);
COMMENT ON TABLE dwh.dim_health_context IS
    'Regional health risk context per year. References Dim_Region.';

-- FACT TABLES
-- Fact_Sales
CREATE TABLE dwh.fact_sales (
    sale_id             BIGSERIAL       PRIMARY KEY,
    time_id             INT             NOT NULL REFERENCES dwh.dim_time(time_id),
    product_id          INT             NOT NULL REFERENCES dwh.dim_product(product_id),
    location_id         INT             NOT NULL REFERENCES dwh.dim_location(location_id),
    units_sold          INT             NOT NULL DEFAULT 0 CHECK (units_sold >= 0),
    delivered_qty       INT             NOT NULL DEFAULT 0,
    revenue             NUMERIC(12,2)   NOT NULL DEFAULT 0,
    gross_margin        NUMERIC(12,2)   NOT NULL DEFAULT 0,
    stock_available     INT             NOT NULL DEFAULT 0,
    stock_rate          NUMERIC(6,4),
    price_unit          NUMERIC(8,2)    NOT NULL CHECK (price_unit > 0),
    promotion_flag      BOOLEAN         NOT NULL DEFAULT FALSE,
    delivery_days       SMALLINT,
    channel             VARCHAR(30)
);
COMMENT ON TABLE dwh.fact_sales IS
    '~190K transaction-level FMCG sales. FKs chain through snowflake to sub-dims.';

-- Fact_Health_Index
CREATE TABLE dwh.fact_health_index (
    health_id               BIGSERIAL       PRIMARY KEY,
    location_id             INT             NOT NULL REFERENCES dwh.dim_location(location_id),
    context_id              INT             REFERENCES dwh.dim_health_context(context_id),
    year                    SMALLINT        NOT NULL,
    health_complaint_pct    NUMERIC(5,2),
    health_risk_score       NUMERIC(5,2)    CHECK (health_risk_score BETWEEN 0 AND 100)
);
COMMENT ON TABLE dwh.fact_health_index IS
    'Province-level annual health complaint rates from BPS (2020-2024).';

-- INDEXES
CREATE INDEX idx_fact_sales_time      ON dwh.fact_sales(time_id);
CREATE INDEX idx_fact_sales_product   ON dwh.fact_sales(product_id);
CREATE INDEX idx_fact_sales_location  ON dwh.fact_sales(location_id);
CREATE INDEX idx_fact_health_loc      ON dwh.fact_health_index(location_id);
CREATE INDEX idx_fact_health_year     ON dwh.fact_health_index(year);
CREATE INDEX idx_dim_time_yearmonth   ON dwh.dim_time(year_month);
CREATE INDEX idx_dim_location_region  ON dwh.dim_location(region_id);
CREATE INDEX idx_dim_product_category ON dwh.dim_product(category_id);
CREATE INDEX idx_dim_region_island    ON dwh.dim_region(island_group_id);

-- VIEWS (Business-ready query layer)
-- Fully-resolved sales view (traverses entire snowflake chain)
CREATE OR REPLACE VIEW dwh.vw_sales_full AS
SELECT
    dt.year_month,
    dt.year,
    dt.month_name,
    dt.is_rainy_season,
    dt.is_ramadan,
    dt.is_dengue_peak,
    dl.province_name,
    dr.pl_region,
    dig.island_group_name,
    dc.category_name,
    dc.is_health_related,
    dp.sku_code,
    dp.brand_name,
    dp.pack_type,
    fs.units_sold,
    fs.revenue,
    fs.gross_margin,
    fs.stock_available,
    fs.stock_rate,
    fs.promotion_flag,
    fs.channel
FROM dwh.fact_sales fs
JOIN dwh.dim_time         dt  ON fs.time_id     = dt.time_id
JOIN dwh.dim_location     dl  ON fs.location_id = dl.location_id
JOIN dwh.dim_region       dr  ON dl.region_id   = dr.region_id
JOIN dwh.dim_island_group dig ON dr.island_group_id = dig.island_group_id
JOIN dwh.dim_product      dp  ON fs.product_id  = dp.product_id
JOIN dwh.dim_category     dc  ON dp.category_id = dc.category_id;

-- Monthly revenue by region
CREATE OR REPLACE VIEW dwh.vw_monthly_revenue_by_region AS
SELECT
    dt.year_month,
    dt.year,
    dt.month_name,
    dr.pl_region,
    dig.island_group_name,
    dt.is_rainy_season,
    dt.is_ramadan,
    SUM(fs.units_sold)   AS total_units_sold,
    SUM(fs.revenue)      AS total_revenue,
    SUM(fs.gross_margin) AS total_gross_margin,
    AVG(fs.stock_rate)   AS avg_stock_rate,
    COUNT(fs.sale_id)    AS transaction_count
FROM dwh.fact_sales fs
JOIN dwh.dim_time         dt  ON fs.time_id     = dt.time_id
JOIN dwh.dim_location     dl  ON fs.location_id = dl.location_id
JOIN dwh.dim_region       dr  ON dl.region_id   = dr.region_id
JOIN dwh.dim_island_group dig ON dr.island_group_id = dig.island_group_id
GROUP BY dt.year_month, dt.year, dt.month_name,
         dr.pl_region, dig.island_group_name,
         dt.is_rainy_season, dt.is_ramadan;

-- Strategic quadrant with revenue
CREATE OR REPLACE VIEW dwh.vw_strategic_quadrant AS
SELECT
    dhc.year,
    dr.pl_region,
    dig.island_group_name,
    dhc.health_risk_score,
    dhc.risk_category,
    dhc.stock_category,
    dhc.strategic_quadrant,
    dhc.priority_rank,
    SUM(fs.revenue)         AS total_revenue,
    SUM(fs.units_sold)      AS total_units_sold,
    AVG(fs.stock_rate)      AS avg_stock_rate
FROM dwh.dim_health_context dhc
JOIN dwh.dim_region       dr  ON dhc.region_id      = dr.region_id
JOIN dwh.dim_island_group dig ON dr.island_group_id = dig.island_group_id
JOIN dwh.dim_location     dl  ON dl.region_id        = dr.region_id
JOIN dwh.fact_sales       fs  ON fs.location_id      = dl.location_id
JOIN dwh.dim_time         dt  ON fs.time_id           = dt.time_id
                              AND dt.year             = dhc.year
GROUP BY dhc.year, dr.pl_region, dig.island_group_name,
         dhc.health_risk_score, dhc.risk_category,
         dhc.stock_category, dhc.strategic_quadrant, dhc.priority_rank;

-- Province health risk (for map visualization in Power BI)
CREATE OR REPLACE VIEW dwh.vw_province_health_risk AS
SELECT
    fhi.year,
    dl.province_name,
    dr.pl_region,
    dig.island_group_name,
    fhi.health_complaint_pct,
    fhi.health_risk_score,
    dhc.risk_category,
    dhc.strategic_quadrant,
    dhc.priority_rank
FROM dwh.fact_health_index  fhi
JOIN dwh.dim_location        dl  ON fhi.location_id  = dl.location_id
JOIN dwh.dim_region          dr  ON dl.region_id      = dr.region_id
JOIN dwh.dim_island_group    dig ON dr.island_group_id= dig.island_group_id
LEFT JOIN dwh.dim_health_context dhc
    ON dhc.region_id = dr.region_id AND dhc.year = fhi.year
ORDER BY fhi.year, fhi.health_risk_score DESC;