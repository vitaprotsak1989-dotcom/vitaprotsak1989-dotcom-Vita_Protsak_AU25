-- ====================
-- Task 1
-- ====================
WITH channel_sales AS (
    SELECT
        co.country_region      AS country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold)     AS amount_sold
    FROM sh.sales s
    JOIN sh.times t
        ON s.time_id = t.time_id
    JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    JOIN sh.customers cu
        ON s.cust_id = cu.cust_id
    JOIN sh.countries co
        ON cu.country_id = co.country_id
    WHERE t.calendar_year BETWEEN 1999 AND 2001
      AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY
        co.country_region,
        t.calendar_year,
        ch.channel_desc
),
percentages AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        ROUND(
            amount_sold
            / SUM(amount_sold) OVER (
                PARTITION BY country_region, calendar_year
            ) * 100,
            2
        ) AS pct_by_channels
    FROM channel_sales
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    ROUND(amount_sold, 2) AS amount_sold,
    pct_by_channels       AS "% BY CHANNELS",
    LAG(pct_by_channels) OVER (
        PARTITION BY country_region, channel_desc
        ORDER BY calendar_year
    )                     AS "% PREVIOUS PERIOD",
    ROUND(
        pct_by_channels
        - LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ),
        2
    )                     AS "% DIFF"
FROM percentages
ORDER BY
    country_region,
    calendar_year,
    channel_desc;
-- ======================
-- Task 2
-- ======================
WITH daily_sales AS (
    SELECT
        t.time_id,
        t.calendar_year,
        t.calendar_week_number,
        t.day_name,
        SUM(s.amount_sold) AS daily_amount
    FROM sh.sales s
    JOIN sh.times t
        ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
      AND t.calendar_week_number IN (49, 50, 51)
    GROUP BY
        t.time_id,
        t.calendar_year,
        t.calendar_week_number,
        t.day_name
),
calc AS (
    SELECT
        time_id,
        calendar_week_number,
        day_name,
        daily_amount,

        /* Weekly cumulative sum */
        SUM(daily_amount) OVER (
            PARTITION BY calendar_week_number
            ORDER BY time_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum,

        /* Centered moving average with special rules */
        CASE
            /* Monday: Sat + Sun + Mon + Tue */
            WHEN day_name = 'Monday' THEN
                AVG(daily_amount) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
                )

            /* Friday: Thu + Fri + Sat + Sun */
            WHEN day_name = 'Friday' THEN
                AVG(daily_amount) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
                )

            /* Normal centered 3-day average */
            ELSE
                AVG(daily_amount) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                )
        END AS centered_3_day_avg

    FROM daily_sales
)
SELECT
    calendar_week_number,
    time_id,
    day_name,
    ROUND(daily_amount, 2)       AS daily_amount,
    ROUND(cum_sum, 2)            AS cum_sum,
    ROUND(centered_3_day_avg, 2) AS centered_3_day_avg
FROM calc
ORDER BY
    calendar_week_number,
    time_id;

--===========================
-- Task 3
--===========================

--===========================
-- ROWS
--===========================

SELECT
    t.calendar_week_number,
    t.time_id,
    SUM(s.amount_sold) AS daily_amount,

    SUM(SUM(s.amount_sold)) OVER (
        PARTITION BY t.calendar_week_number
        ORDER BY t.time_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_week_total
FROM sh.sales s
JOIN sh.times t
    ON s.time_id = t.time_id
WHERE t.calendar_year = 1999
GROUP BY
    t.calendar_week_number,
    t.time_id
ORDER BY
    t.calendar_week_number,
    t.time_id;
	
-- ROWS counts physical rows
-- Each day is exactly one row
-- Guarantees step-by-step accumulation
-- Not affected by duplicate values in time_id
-- Best choice for running totals, moving sums, and exact row positioning


--===========================
-- RANGE
--===========================
SELECT
    t.time_id,
    SUM(s.amount_sold) AS daily_amount,

    SUM(SUM(s.amount_sold)) OVER (
        ORDER BY t.time_id
        RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_total
FROM sh.sales s
JOIN sh.times t
    ON s.time_id = t.time_id
WHERE t.calendar_year = 1999
GROUP BY
    t.time_id
ORDER BY
    t.time_id;


-- RANGE works on ORDER BY values
-- ncludes all rows within the date interval
-- Correct even if:
-- some days are missing
-- multiple rows share the same date
-- Best choice for time-based windows (last 7 days, last month, etc.)


--===========================
-- GROUPS
--===========================

SELECT
    p.prod_category,
    p.prod_id,
    SUM(s.amount_sold) AS product_sales,

    SUM(SUM(s.amount_sold)) OVER (
        PARTITION BY p.prod_category
        ORDER BY p.prod_id
        GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS category_running_total
FROM sh.sales s
JOIN sh.products p
    ON s.prod_id = p.prod_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000
GROUP BY
    p.prod_category,
    p.prod_id
ORDER BY
    p.prod_category,
    p.prod_id;

-- GROUPS operates on peer groups (same ORDER BY value)
-- Ensures all equal keys are processed together
-- Prevents partial accumulation within the same logical group
-- Best choice when ORDER BY values repeat and must be treated as a unit