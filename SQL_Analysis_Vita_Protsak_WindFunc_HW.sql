-- ====================
-- Task 1
-- ====================
WITH customer_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
),
ranked_customers AS (
    SELECT
        cs.channel_id,
        cs.cust_id,
        cs.total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY cs.channel_id
            ORDER BY cs.total_sales DESC
        ) AS rn
    FROM customer_sales cs
),
channel_totals AS (
    SELECT
        channel_id,
        SUM(total_sales) AS channel_total
    FROM customer_sales
    GROUP BY channel_id
)
SELECT
    ch.channel_desc AS channel,
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    ROUND(r.total_sales, 2) AS total_sales,
    ROUND((r.total_sales / ct.channel_total) * 100, 4) || '%' AS sales_percentage
FROM ranked_customers r
INNER JOIN sh.customers cu
    ON r.cust_id = cu.cust_id
INNER JOIN sh.channels ch
    ON r.channel_id = ch.channel_id
INNER JOIN channel_totals ct
    ON r.channel_id = ct.channel_id
WHERE r.rn <= 5
ORDER BY
    ch.channel_desc,
    r.total_sales DESC;



-- ====================
-- Task 2
-- ==================== 

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    prod_name,
    ROUND(COALESCE(q1, 0), 2) AS q1,
    ROUND(COALESCE(q2, 0), 2) AS q2,
    ROUND(COALESCE(q3, 0), 2) AS q3,
    ROUND(COALESCE(q4, 0), 2) AS q4,
    ROUND(
        COALESCE(q1, 0) +
        COALESCE(q2, 0) +
        COALESCE(q3, 0) +
        COALESCE(q4, 0), 2
    ) AS year_sum
FROM crosstab(
    $$
    SELECT
        p.prod_name,
        'Q' || EXTRACT(QUARTER FROM s.time_id)::int AS quarter,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.products p   ON s.prod_id = p.prod_id
    INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id
    INNER JOIN sh.countries c  ON cu.country_id = c.country_id
    WHERE UPPER(p.prod_category) = 'PHOTO'
      AND UPPER(c.country_region) = 'ASIA'
      AND EXTRACT(YEAR FROM s.time_id) = 2000
    GROUP BY p.prod_name, EXTRACT(QUARTER FROM s.time_id)
    ORDER BY p.prod_name, quarter
    $$,
    $$ VALUES ('Q1'), ('Q2'), ('Q3'), ('Q4') $$
) AS ct (
    prod_name TEXT,
    q1 NUMERIC,
    q2 NUMERIC,
    q3 NUMERIC,
    q4 NUMERIC
)
ORDER BY year_sum DESC;




-- ====================
-- Task 3
-- ====================
WITH channel_year_sales AS (
    SELECT
        ch.channel_desc,
        s.cust_id,
        cu.cust_last_name,
        cu.cust_first_name,
        EXTRACT(YEAR FROM s.time_id) AS sales_year,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    INNER JOIN sh.customers cu
        ON s.cust_id = cu.cust_id
    WHERE EXTRACT(YEAR FROM s.time_id) IN (1998, 1999, 2001)
    GROUP BY
        ch.channel_desc,
        s.cust_id,
        cu.cust_last_name,
        cu.cust_first_name,
        EXTRACT(YEAR FROM s.time_id)
),
ranked_customers AS (
    SELECT
        channel_desc,
        cust_id,
        cust_last_name,
        cust_first_name,
        sales_year,
        total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY channel_desc, sales_year
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM channel_year_sales
)
SELECT
    channel_desc,
    cust_id,
    cust_first_name || ' ' || cust_last_name AS customer_name,
    ROUND(total_sales, 2) AS total_sales
FROM ranked_customers
WHERE sales_rank <= 300
ORDER BY
    channel_desc,
    sales_year,
    total_sales DESC;


-- ====================
-- Task 4
-- ====================
SELECT
    TO_CHAR(s.time_id, 'YYYY-MM') AS month,
    p.prod_category AS product_category,
    ROUND(SUM(CASE WHEN UPPER(co.country_region) = 'EUROPE' THEN s.amount_sold ELSE 0 END), 2) AS europe_sales,
    ROUND(SUM(CASE WHEN UPPER(co.country_region) = 'AMERICAS' THEN s.amount_sold ELSE 0 END), 2) AS americas_sales
FROM sh.sales s
INNER JOIN sh.products p ON s.prod_id = p.prod_id
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.countries co ON c.country_id = co.country_id
WHERE s.time_id >= DATE '2000-01-01'
  AND s.time_id < DATE '2000-04-01'
  AND UPPER(co.country_region) IN ('EUROPE', 'AMERICAS')
GROUP BY month, p.prod_category
ORDER BY month, p.prod_category;