-- T-01: BUILD DIM_ISLAND_GROUP
INSERT INTO dwh.dim_island_group (island_group_name, description) VALUES
    ('Sumatera & Kalimantan Barat', 'Western Indonesia: Sumatera island group and West Kalimantan'),
    ('Jawa, Bali & Nusa Tenggara',  'Central Indonesia: Java, Bali and Lesser Sunda Islands'),
    ('Kalimantan & Sulawesi',        'Northern Indonesia: Borneo (excl. West) and Sulawesi'),
    ('Maluku & Papua',               'Eastern Indonesia: Maluku archipelago and Papua');

-- T-02: BUILD DIM_CATEGORY
INSERT INTO dwh.dim_category (category_name, is_health_related, description) VALUES
    ('Juice',     TRUE,  'Fruit-based beverages'),
    ('Milk',      TRUE,  'Dairy products'),
    ('ReadyMeal', FALSE, 'Ready-to-eat meal products'),
    ('SnackBar',  FALSE, 'Confectionery and cereal bars'),
    ('Yogurt',    FALSE, 'Cultured dairy products');

-- T-03: BUILD DIM_REGION
INSERT INTO dwh.dim_region (pl_region, island_group_id, region_description)
SELECT
    pl_region,
    island_group_id,
    region_description
FROM (VALUES
    ('PL-West',    1, 'Sumatera & West Kalimantan distribution zone'),
    ('PL-Central', 2, 'Java, Bali & Nusa Tenggara distribution zone'),
    ('PL-North',   3, 'Kalimantan & Sulawesi distribution zone'),
    ('PL-South',   4, 'Maluku & Papua distribution zone')
) AS t(pl_region, island_group_id, region_description);

-- T-04: BUILD DIM_LOCATION
INSERT INTO dwh.dim_location (province_name, region_id)
SELECT province_name, dr.region_id
FROM (VALUES
    -- PL-West (Sumatera + Kalimantan Barat)
    ('ACEH',                 'PL-West'),
    ('SUMATERA UTARA',       'PL-West'),
    ('SUMATERA BARAT',       'PL-West'),
    ('RIAU',                 'PL-West'),
    ('JAMBI',                'PL-West'),
    ('SUMATERA SELATAN',     'PL-West'),
    ('BENGKULU',             'PL-West'),
    ('LAMPUNG',              'PL-West'),
    ('KEP. BANGKA BELITUNG', 'PL-West'),
    ('KEP. RIAU',            'PL-West'),
    ('KALIMANTAN BARAT',     'PL-West'),
    -- PL-Central (Jawa + Bali + Nusa Tenggara)
    ('DKI JAKARTA',          'PL-Central'),
    ('JAWA BARAT',           'PL-Central'),
    ('JAWA TENGAH',          'PL-Central'),
    ('DI YOGYAKARTA',        'PL-Central'),
    ('JAWA TIMUR',           'PL-Central'),
    ('BANTEN',               'PL-Central'),
    ('BALI',                 'PL-Central'),
    ('NUSA TENGGARA BARAT',  'PL-Central'),
    ('NUSA TENGGARA TIMUR',  'PL-Central'),
    -- PL-North (Kalimantan + Sulawesi)
    ('KALIMANTAN TENGAH',    'PL-North'),
    ('KALIMANTAN SELATAN',   'PL-North'),
    ('KALIMANTAN TIMUR',     'PL-North'),
    ('KALIMANTAN UTARA',     'PL-North'),
    ('SULAWESI UTARA',       'PL-North'),
    ('SULAWESI TENGAH',      'PL-North'),
    ('SULAWESI SELATAN',     'PL-North'),
    ('SULAWESI TENGGARA',    'PL-North'),
    ('GORONTALO',            'PL-North'),
    ('SULAWESI BARAT',       'PL-North'),
    -- PL-South (Maluku + Papua)
    ('MALUKU',               'PL-South'),
    ('MALUKU UTARA',         'PL-South'),
    ('PAPUA BARAT',          'PL-South'),
    ('PAPUA BARAT DAYA',     'PL-South'),
    ('PAPUA',                'PL-South'),
    ('PAPUA SELATAN',        'PL-South'),
    ('PAPUA TENGAH',         'PL-South'),
    ('PAPUA PEGUNUNGAN',     'PL-South')
) AS t(province_name, pl_region)
JOIN dwh.dim_region dr ON dr.pl_region = t.pl_region;

-- T-05: NORMALIZE HEALTH RISK SCORE (0–100)
SELECT
    province,
    year,
    health_complaint_pct,
    ROUND(
        (health_complaint_pct - MIN(health_complaint_pct) OVER ()) /
        NULLIF(MAX(health_complaint_pct) OVER () - MIN(health_complaint_pct) OVER (), 0) * 100,
    2) AS health_risk_score_normalized
FROM (
    -- This would reference the raw BPS staging table
    -- In our pipeline, this transformation is done in Python (03_preprocessing.ipynb)
    SELECT 'ACEH' AS province, 2022 AS year, 32.91 AS health_complaint_pct
    UNION ALL
    SELECT 'DI YOGYAKARTA', 2022, 35.73
    -- ... all provinces loaded here
) raw_health
ORDER BY health_risk_score_normalized DESC;

-- T-06: DERIVE REVENUE & GROSS MARGIN
SELECT
    date,
    sku,
    region,
    units_sold,
    price_unit,
    -- Derived columns
    ROUND(units_sold * price_unit, 2)                    AS revenue,
    ROUND(units_sold * price_unit * 0.30, 2)             AS gross_margin,  -- 30% industry benchmark
    ROUND(
        stock_available::NUMERIC /
        NULLIF(stock_available + units_sold + 1, 0),     -- +1 avoids div/0
    4)                                                   AS stock_rate,
    CASE WHEN units_sold = 0 AND stock_available = 0
         THEN TRUE ELSE FALSE END                        AS is_stockout
FROM dwh.fact_sales
LIMIT 10;

-- T-07: ASSIGN STRATEGIC QUADRANT
SELECT
    year,
    pl_region,
    health_risk_score,
    stock_category,
    CASE
        WHEN health_risk_score >= 50 AND stock_category = 'LOW'    THEN '🔴 Critical Gap'
        WHEN health_risk_score >= 50 AND stock_category != 'LOW'   THEN '🟡 Well-Served'
        WHEN health_risk_score < 50  AND stock_category = 'LOW'    THEN '🟠 Underserved'
        ELSE                                                             '🟢 Surplus'
    END AS strategic_quadrant,
    CASE
        WHEN health_risk_score >= 50 AND stock_category = 'LOW'  THEN 1
        WHEN health_risk_score >= 50 AND stock_category != 'LOW' THEN 3
        WHEN health_risk_score < 50  AND stock_category = 'LOW'  THEN 2
        ELSE 4
    END AS priority_rank
FROM dwh.dim_health_context
ORDER BY priority_rank, health_risk_score DESC;

-- T-08: VERIFY REFERENTIAL INTEGRITY (Post-Load Checks)
-- Check 1: All fact_sales location_id exist in dim_location
SELECT COUNT(*) AS orphan_location_count
FROM dwh.fact_sales fs
LEFT JOIN dwh.dim_location dl ON fs.location_id = dl.location_id
WHERE dl.location_id IS NULL;
-- Expected: 0

-- Check 2: All fact_sales product_id exist in dim_product
SELECT COUNT(*) AS orphan_product_count
FROM dwh.fact_sales fs
LEFT JOIN dwh.dim_product dp ON fs.product_id = dp.product_id
WHERE dp.product_id IS NULL;
-- Expected: 0

-- Check 3: All fact_sales time_id exist in dim_time
SELECT COUNT(*) AS orphan_time_count
FROM dwh.fact_sales fs
LEFT JOIN dwh.dim_time dt ON fs.time_id = dt.time_id
WHERE dt.time_id IS NULL;
-- Expected: 0

-- Check 4: All dim_location region_id exist in dim_region
SELECT COUNT(*) AS orphan_region_count
FROM dwh.dim_location dl
LEFT JOIN dwh.dim_region dr ON dl.region_id = dr.region_id
WHERE dr.region_id IS NULL;
-- Expected: 0

-- Check 5: All dim_region island_group_id exist in dim_island_group
SELECT COUNT(*) AS orphan_island_count
FROM dwh.dim_region dr
LEFT JOIN dwh.dim_island_group dig ON dr.island_group_id = dig.island_group_id
WHERE dig.island_group_id IS NULL;
-- Expected: 0

-- Check 6: Row counts per table
SELECT 'dim_island_group'   AS tbl, COUNT(*) AS rows FROM dwh.dim_island_group   UNION ALL
SELECT 'dim_category',               COUNT(*)          FROM dwh.dim_category       UNION ALL
SELECT 'dim_region',                 COUNT(*)          FROM dwh.dim_region         UNION ALL
SELECT 'dim_product',                COUNT(*)          FROM dwh.dim_product        UNION ALL
SELECT 'dim_time',                   COUNT(*)          FROM dwh.dim_time           UNION ALL
SELECT 'dim_location',               COUNT(*)          FROM dwh.dim_location       UNION ALL
SELECT 'dim_health_context',         COUNT(*)          FROM dwh.dim_health_context UNION ALL
SELECT 'fact_sales',                 COUNT(*)          FROM dwh.fact_sales         UNION ALL
SELECT 'fact_health_index',          COUNT(*)          FROM dwh.fact_health_index
ORDER BY tbl;