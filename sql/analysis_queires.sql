-- BQ-01: PRIORITY ZONES
-- Q-01A: Strategic quadrant summary
SELECT
    dhc.year,
    dr.pl_region,
    dig.island_group_name,
    dhc.health_risk_score,
    dhc.risk_category,
    dhc.stock_category,
    dhc.strategic_quadrant,
    dhc.priority_rank
FROM dwh.dim_health_context dhc
JOIN dwh.dim_region         dr  ON dhc.region_id      = dr.region_id
JOIN dwh.dim_island_group   dig ON dr.island_group_id  = dig.island_group_id
ORDER BY dhc.priority_rank ASC, dhc.year ASC;

-- Q-01B: Critical Gap regions with full snowflake traversal
SELECT
    dhc.year,
    dr.pl_region,
    dig.island_group_name,
    dhc.health_risk_score,
    dhc.strategic_quadrant,
    SUM(fs.units_sold)        AS actual_units_sold,
    AVG(fs.stock_rate)        AS avg_stock_rate,
    AVG(fs.stock_available)   AS avg_stock_available,
    SUM(fs.revenue)           AS actual_revenue
FROM dwh.dim_health_context dhc
JOIN dwh.dim_region         dr  ON dhc.region_id      = dr.region_id
JOIN dwh.dim_island_group   dig ON dr.island_group_id  = dig.island_group_id
JOIN dwh.dim_location       dl  ON dl.region_id        = dr.region_id
JOIN dwh.fact_sales         fs  ON fs.location_id      = dl.location_id
JOIN dwh.dim_time           dt  ON fs.time_id          = dt.time_id
                                AND dt.year            = dhc.year
WHERE dhc.strategic_quadrant = '🔴 Critical Gap'
GROUP BY dhc.year, dr.pl_region, dig.island_group_name,
         dhc.health_risk_score, dhc.strategic_quadrant
ORDER BY dhc.health_risk_score DESC, dhc.year;

-- Q-01C: Health risk score by province (province-level detail)
-- Traverses: Fact_Health_Index → Dim_Location → Dim_Region → Dim_Island_Group
SELECT
    fhi.year,
    dl.province_name,
    dr.pl_region,
    dig.island_group_name,
    fhi.health_complaint_pct,
    fhi.health_risk_score,
    CASE
        WHEN fhi.health_risk_score >= 66 THEN 'HIGH'
        WHEN fhi.health_risk_score >= 33 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_level
FROM dwh.fact_health_index  fhi
JOIN dwh.dim_location        dl  ON fhi.location_id    = dl.location_id
JOIN dwh.dim_region          dr  ON dl.region_id        = dr.region_id
JOIN dwh.dim_island_group    dig ON dr.island_group_id  = dig.island_group_id
ORDER BY fhi.year, fhi.health_risk_score DESC;

-- Q-01D: Stock availability heatmap per region per month
SELECT
    dt.year_month,
    dt.year,
    dt.month_name,
    dr.pl_region,
    AVG(fs.stock_rate)      AS avg_stock_rate,
    AVG(fs.stock_available) AS avg_stock_level,
    SUM(CASE WHEN fs.units_sold = 0 AND fs.stock_available = 0
             THEN 1 ELSE 0 END)::NUMERIC /
    COUNT(fs.sale_id) * 100 AS stockout_rate_pct
FROM dwh.fact_sales     fs
JOIN dwh.dim_time       dt  ON fs.time_id     = dt.time_id
JOIN dwh.dim_location   dl  ON fs.location_id = dl.location_id
JOIN dwh.dim_region     dr  ON dl.region_id   = dr.region_id
GROUP BY dt.year_month, dt.year, dt.month_name, dr.pl_region
ORDER BY dt.year_month, dr.pl_region;

-- BQ-02: REVENUE GAP ANALYSIS
-- Q-02A: Revenue summary by region and quadrant
SELECT
    dt.year,
    dr.pl_region,
    dig.island_group_name,
    dhc.strategic_quadrant,
    dhc.priority_rank,
    dhc.health_risk_score,
    SUM(fs.revenue)       AS total_revenue,
    SUM(fs.gross_margin)  AS total_gross_margin,
    SUM(fs.units_sold)    AS total_units_sold,
    AVG(fs.stock_rate)    AS avg_stock_rate,
    ROUND(SUM(fs.gross_margin) / NULLIF(SUM(fs.revenue), 0) * 100, 2) AS margin_pct
FROM dwh.fact_sales         fs
JOIN dwh.dim_time           dt  ON fs.time_id      = dt.time_id
JOIN dwh.dim_location       dl  ON fs.location_id  = dl.location_id
JOIN dwh.dim_region         dr  ON dl.region_id    = dr.region_id
JOIN dwh.dim_island_group   dig ON dr.island_group_id = dig.island_group_id
JOIN dwh.dim_health_context dhc ON dhc.region_id   = dr.region_id
                                AND dhc.year        = dt.year
GROUP BY dt.year, dr.pl_region, dig.island_group_name,
         dhc.strategic_quadrant, dhc.priority_rank, dhc.health_risk_score
ORDER BY dhc.priority_rank, dt.year;

-- Q-02B: Monthly revenue trend with seasonal context
SELECT
    dt.year_month,
    dt.year,
    dt.month_name,
    dr.pl_region,
    dt.is_rainy_season,
    dt.is_ramadan,
    dt.is_dengue_peak,
    SUM(fs.revenue)      AS total_revenue,
    SUM(fs.units_sold)   AS total_units,
    AVG(fs.stock_rate)   AS avg_stock_rate,
    SUM(fs.promotion_flag::INT) AS total_promotions
FROM dwh.fact_sales   fs
JOIN dwh.dim_time     dt ON fs.time_id     = dt.time_id
JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
JOIN dwh.dim_region   dr ON dl.region_id   = dr.region_id
GROUP BY dt.year_month, dt.year, dt.month_name, dr.pl_region,
         dt.is_rainy_season, dt.is_ramadan, dt.is_dengue_peak
ORDER BY dt.year_month, dr.pl_region;

-- Q-02C: Revenue by product category & health relevance
SELECT
    dt.year,
    dr.pl_region,
    dc.category_name,
    dc.is_health_related,
    SUM(fs.units_sold)   AS total_units,
    SUM(fs.revenue)      AS total_revenue,
    SUM(fs.gross_margin) AS total_margin,
    AVG(fs.price_unit)   AS avg_price
FROM dwh.fact_sales         fs
JOIN dwh.dim_time           dt  ON fs.time_id     = dt.time_id
JOIN dwh.dim_location       dl  ON fs.location_id = dl.location_id
JOIN dwh.dim_region         dr  ON dl.region_id   = dr.region_id
JOIN dwh.dim_product        dp  ON fs.product_id  = dp.product_id
JOIN dwh.dim_category       dc  ON dp.category_id = dc.category_id
GROUP BY dt.year, dr.pl_region, dc.category_name, dc.is_health_related
ORDER BY dt.year, total_revenue DESC;

-- Q-02D: Promotion effectiveness analysis
SELECT
    dr.pl_region,
    fs.promotion_flag,
    COUNT(fs.sale_id)    AS transaction_count,
    AVG(fs.units_sold)   AS avg_units_sold,
    AVG(fs.revenue)      AS avg_revenue,
    AVG(fs.stock_rate)   AS avg_stock_rate
FROM dwh.fact_sales   fs
JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
JOIN dwh.dim_region   dr ON dl.region_id   = dr.region_id
GROUP BY dr.pl_region, fs.promotion_flag
ORDER BY dr.pl_region, fs.promotion_flag;

-- BQ-03: SEASONAL DEMAND PATTERNS
-- Q-03A: Monthly demand pattern by seasonal flags
SELECT
    dt.month,
    dt.month_name,
    dt.is_rainy_season,
    dt.is_ramadan,
    dt.is_lebaran,
    dt.is_dengue_peak,
    dt.is_school_holiday,
    dr.pl_region,
    AVG(fs.units_sold)   AS avg_units_sold,
    AVG(fs.revenue)      AS avg_revenue,
    AVG(fs.stock_rate)   AS avg_stock_rate
FROM dwh.fact_sales   fs
JOIN dwh.dim_time     dt ON fs.time_id     = dt.time_id
JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
JOIN dwh.dim_region   dr ON dl.region_id   = dr.region_id
GROUP BY dt.month, dt.month_name, dt.is_rainy_season, dt.is_ramadan,
         dt.is_lebaran, dt.is_dengue_peak, dt.is_school_holiday, dr.pl_region
ORDER BY dt.month, dr.pl_region;

-- Q-03B: Year-over-Year growth per region
SELECT
    dr.pl_region,
    dt.year,
    SUM(fs.units_sold)   AS total_units,
    SUM(fs.revenue)      AS total_revenue,
    LAG(SUM(fs.revenue)) OVER (
        PARTITION BY dr.pl_region
        ORDER BY dt.year
    ) AS prev_year_revenue,
    ROUND(
        (SUM(fs.revenue) - LAG(SUM(fs.revenue)) OVER (
            PARTITION BY dr.pl_region ORDER BY dt.year
        )) / NULLIF(LAG(SUM(fs.revenue)) OVER (
            PARTITION BY dr.pl_region ORDER BY dt.year
        ), 0) * 100,
    2) AS yoy_growth_pct
FROM dwh.fact_sales   fs
JOIN dwh.dim_time     dt ON fs.time_id     = dt.time_id
JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
JOIN dwh.dim_region   dr ON dl.region_id   = dr.region_id
GROUP BY dr.pl_region, dt.year
ORDER BY dr.pl_region, dt.year;

-- Q-03C: Rainy season vs dry season demand comparison
SELECT
    dr.pl_region,
    dt.is_rainy_season,
    CASE WHEN dt.is_rainy_season THEN 'Rainy Season' ELSE 'Dry Season' END AS season,
    AVG(fs.units_sold)   AS avg_units,
    AVG(fs.revenue)      AS avg_revenue,
    AVG(fs.stock_rate)   AS avg_stock_rate,
    COUNT(DISTINCT dt.year_month) AS months_observed
FROM dwh.fact_sales   fs
JOIN dwh.dim_time     dt ON fs.time_id     = dt.time_id
JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
JOIN dwh.dim_region   dr ON dl.region_id   = dr.region_id
GROUP BY dr.pl_region, dt.is_rainy_season
ORDER BY dr.pl_region, dt.is_rainy_season DESC;

-- Q-03D: Top SKUs by region (for stock prioritization)
SELECT
    dr.pl_region,
    dc.category_name,
    dp.sku_code,
    dp.brand_name,
    dp.pack_type,
    SUM(fs.units_sold)   AS total_units,
    SUM(fs.revenue)      AS total_revenue,
    AVG(fs.stock_rate)   AS avg_stock_rate,
    RANK() OVER (
        PARTITION BY dr.pl_region
        ORDER BY SUM(fs.units_sold) DESC
    ) AS rank_in_region
FROM dwh.fact_sales       fs
JOIN dwh.dim_location     dl  ON fs.location_id = dl.location_id
JOIN dwh.dim_region       dr  ON dl.region_id   = dr.region_id
JOIN dwh.dim_product      dp  ON fs.product_id  = dp.product_id
JOIN dwh.dim_category     dc  ON dp.category_id = dc.category_id
GROUP BY dr.pl_region, dc.category_name, dp.sku_code, dp.brand_name, dp.pack_type
QUALIFY rank_in_region <= 5   -- Top 5 SKUs per region
ORDER BY dr.pl_region, rank_in_region;

-- KPI-01: Overall project KPIs (single-row summary)
SELECT
    COUNT(DISTINCT dl.province_name)                    AS total_provinces,
    COUNT(DISTINCT dr.pl_region)                        AS total_regions,
    SUM(fs.units_sold)                                  AS grand_total_units,
    ROUND(SUM(fs.revenue), 2)                           AS grand_total_revenue,
    ROUND(SUM(fs.gross_margin), 2)                      AS grand_total_margin,
    ROUND(AVG(fs.stock_rate) * 100, 2)                  AS avg_stock_rate_pct,
    COUNT(DISTINCT CASE WHEN dhc.strategic_quadrant = '🔴 Critical Gap'
                        THEN dr.pl_region END)          AS critical_gap_regions,
    MIN(dt.full_date)                                   AS data_start_date,
    MAX(dt.full_date)                                   AS data_end_date
FROM dwh.fact_sales         fs
JOIN dwh.dim_time           dt  ON fs.time_id      = dt.time_id
JOIN dwh.dim_location       dl  ON fs.location_id  = dl.location_id
JOIN dwh.dim_region         dr  ON dl.region_id    = dr.region_id
JOIN dwh.dim_health_context dhc ON dhc.region_id   = dr.region_id
                                AND dhc.year        = dt.year;

-- KPI-02: Health risk vs revenue scatter (for Power BI scatter chart)
SELECT
    dhc.year,
    dr.pl_region,
    dhc.health_risk_score,
    dhc.strategic_quadrant,
    dhc.priority_rank,
    SUM(fs.revenue)     AS total_revenue,
    AVG(fs.stock_rate)  AS avg_stock_rate,
    SUM(fs.units_sold)  AS total_units
FROM dwh.dim_health_context dhc
JOIN dwh.dim_region         dr  ON dhc.region_id   = dr.region_id
JOIN dwh.dim_location       dl  ON dl.region_id     = dr.region_id
JOIN dwh.fact_sales         fs  ON fs.location_id   = dl.location_id
JOIN dwh.dim_time           dt  ON fs.time_id        = dt.time_id
                                AND dt.year          = dhc.year
GROUP BY dhc.year, dr.pl_region, dhc.health_risk_score,
         dhc.strategic_quadrant, dhc.priority_rank
ORDER BY dhc.priority_rank, dhc.year;