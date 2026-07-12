-- ============================================================
-- WDW Ticket Pricing Analysis v1
-- Author: Andrew Gentilcore
-- Engine: DuckDB (run: duckdb, then .read analysis.sql)
-- Data: hand-collected 1-day base ticket prices from Disney's
--       public date-based pricing calendar. See README for method.
-- ============================================================

-- Load the data and derive calendar features once, reuse everywhere.
CREATE OR REPLACE TABLE prices AS
SELECT
    date::DATE                         AS visit_date,
    park,
    price_usd,
    is_holiday::BOOLEAN                AS is_holiday,
    is_school_break::BOOLEAN           AS is_school_break,
    dayname(date::DATE)                AS day_of_week,
    CASE WHEN dayofweek(date::DATE) IN (0, 6) THEN 1 ELSE 0 END AS is_weekend,
    strftime(date::DATE, '%Y-%m')      AS year_month
FROM read_csv('wdw_ticket_prices.csv', header=true, null_padding=true, normalize_names=true);

-- ------------------------------------------------------------
-- Q1: Sanity check. Row count, date range, price range.
-- Always look at your data before analyzing it.
-- ------------------------------------------------------------
SELECT
    COUNT(*)              AS days_collected,
    MIN(visit_date)       AS first_date,
    MAX(visit_date)       AS last_date,
    MIN(price_usd)        AS min_price,
    MAX(price_usd)        AS max_price,
    ROUND(AVG(price_usd), 2) AS avg_price
FROM prices;

-- ------------------------------------------------------------
-- Q2: Average price by day of week.
-- The core question: how much does WHEN you go matter?
-- ------------------------------------------------------------
SELECT
    day_of_week,
    COUNT(*)                    AS n_days,
    ROUND(AVG(price_usd), 2)    AS avg_price,
    MIN(price_usd)              AS min_price,
    MAX(price_usd)              AS max_price
FROM prices
GROUP BY day_of_week
ORDER BY avg_price DESC;

-- ------------------------------------------------------------
-- Q3: The weekend premium, in dollars and percent.
-- One clean number for the README headline.
-- ------------------------------------------------------------
WITH by_type AS (
    SELECT
        is_weekend,
        AVG(price_usd) AS avg_price
    FROM prices
    GROUP BY is_weekend
)
SELECT
    ROUND(wknd.avg_price - wkdy.avg_price, 2)                          AS weekend_premium_usd,
    ROUND(100.0 * (wknd.avg_price - wkdy.avg_price) / wkdy.avg_price, 1) AS weekend_premium_pct
FROM (SELECT avg_price FROM by_type WHERE is_weekend = 1) wknd,
     (SELECT avg_price FROM by_type WHERE is_weekend = 0) wkdy;

-- ------------------------------------------------------------
-- Q4: What does demand seasonality cost? Holiday and school-break
-- premiums vs. an ordinary day.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN is_holiday      THEN 'Holiday period'
        WHEN is_school_break THEN 'School break'
        ELSE 'Ordinary day'
    END                         AS day_type,
    COUNT(*)                    AS n_days,
    ROUND(AVG(price_usd), 2)    AS avg_price,
    ROUND(AVG(price_usd) - (SELECT AVG(price_usd) FROM prices WHERE NOT is_holiday AND NOT is_school_break), 2) AS premium_vs_ordinary
FROM prices
GROUP BY day_type
ORDER BY avg_price DESC;

-- ------------------------------------------------------------
-- Q5: 7-day rolling average price (window function).
-- Smooths daily noise and shows the seasonal price curve.
-- Export this one for the README chart.
-- ------------------------------------------------------------
SELECT
    visit_date,
    price_usd,
    ROUND(AVG(price_usd) OVER (
        ORDER BY visit_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7d_avg
FROM prices
ORDER BY visit_date;

-- ------------------------------------------------------------
-- Q6: The ten most and least expensive days collected, ranked.
-- Great for the README: "the same ticket costs $X more on ___."
-- ------------------------------------------------------------
(SELECT 'Most expensive' AS bucket, visit_date, day_of_week, price_usd,
        RANK() OVER (ORDER BY price_usd DESC) AS rnk
 FROM prices ORDER BY price_usd DESC LIMIT 10)
UNION ALL
(SELECT 'Least expensive', visit_date, day_of_week, price_usd,
        RANK() OVER (ORDER BY price_usd ASC)
 FROM prices ORDER BY price_usd ASC LIMIT 10)
ORDER BY bucket, rnk;
