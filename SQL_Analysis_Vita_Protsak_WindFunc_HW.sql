

-- ============================================
-- Task 1: Топ-5 клієнтів по каналах + KPI
-- Обчислюємо суму продажів по клієнту та обчислюємо sales_percentage
-- ============================================

WITH channel_totals AS (
    SELECT channel_id, SUM(amount_sold) AS channel_total
    FROM sh.sales
    GROUP BY channel_id
)
SELECT
    ch.channel_desc AS channel,
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    ROUND(SUM(s.amount_sold),2) AS total_sales,
    ROUND(SUM(s.amount_sold) / ct.channel_total * 100,4) || '%' AS sales_percentage
FROM sh.sales s
JOIN sh.customers cu ON s.cust_id = cu.cust_id
JOIN sh.channels ch ON s.channel_id = ch.channel_id
JOIN channel_totals ct ON s.channel_id = ct.channel_id
GROUP BY ch.channel_desc, cu.cust_first_name, cu.cust_last_name, ct.channel_total
ORDER BY ch.channel_desc, total_sales DESC;

-- ============================================
-- Task 2: Продажі категорії Photo в Азії за 2000 рік
-- ============================================

WITH sales_filtered AS (
    SELECT p.product_name, SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.customers cu ON s.cust_id = cu.cust_id
    JOIN sh.countries co ON cu.country_id = co.country_id
    WHERE p.category = 'Photo'
      AND co.region = 'Asia'
      AND EXTRACT(YEAR FROM s.time_id) = 2000
    GROUP BY p.product_name
)
SELECT product_name, ROUND(total_sales,2) AS total_sales
FROM sales_filtered
ORDER BY total_sales DESC;

-- ============================================
-- Task 3: Топ-300 клієнтів по роках і каналах
-- ============================================

WITH yearly_sales AS (
    SELECT s.cust_id, s.channel_id, EXTRACT(YEAR FROM s.time_id) AS year, SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    WHERE EXTRACT(YEAR FROM s.time_id) IN (1998,1999,2001)
    GROUP BY s.cust_id, s.channel_id, EXTRACT(YEAR FROM s.time_id)
),
channel_top_300 AS (
    SELECT ys1.cust_id, ys1.channel_id, ys1.year, ys1.total_sales
    FROM yearly_sales ys1
    WHERE (
        SELECT COUNT(*) 
        FROM yearly_sales ys2 
        WHERE ys2.channel_id = ys1.channel_id 
          AND ys2.year = ys1.year 
          AND ys2.total_sales >= ys1.total_sales
    ) <= 300
)
SELECT 
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    ch.channel_desc AS channel,
    ct.year,
    ROUND(ct.total_sales,2) AS total_sales
FROM channel_top_300 ct
JOIN sh.customers cu ON ct.cust_id = cu.cust_id
JOIN sh.channels ch ON ct.channel_id = ch.channel_id
ORDER BY ct.year, ch.channel_desc, total_sales DESC;

-- ============================================
-- Task 4: Продажі Jan–Mar 2000 для Europe та Americas
-- ============================================

SELECT 
    EXTRACT(MONTH FROM s.time_id) AS month,
    p.category,
    ROUND(SUM(s.amount_sold),2) AS total_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
JOIN sh.customers cu ON s.cust_id = cu.cust_id
JOIN sh.countries co ON cu.country_id = co.country_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000
  AND EXTRACT(MONTH FROM s.time_id) IN (1,2,3)
  AND co.region IN ('Europe','Americas')
GROUP BY month, p.category
ORDER BY month, p.category;






-- ============================================
-- Task 1: Top 5 customers for each channel + KPI
-- ============================================

WITH channel_totals AS (
    SELECT channel_id, SUM(amount_sold) AS channel_total
    FROM sh.sales
    GROUP BY channel_id
),
sales_per_customer AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
)
SELECT
    ch.channel_desc AS channel,
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    ROUND(spc.total_sales,2) AS total_sales,
    ROUND(spc.total_sales / ct.channel_total * 100,4) || '%' AS sales_percentage
FROM sales_per_customer spc
JOIN sh.channels ch ON spc.channel_id = ch.channel_id
JOIN sh.customers cu ON spc.cust_id = cu.cust_id
JOIN channel_totals ct ON spc.channel_id = ct.channel_id
ORDER BY ch.channel_desc, total_sales DESC
LIMIT 5;  -- топ-5 клієнтів для каналу (для кожного каналу можна зробити окремий SELECT UNION ALL, якщо потрібно строго по 5 на канал)

-- ============================================
-- Task 2: Sales photo category in the Asian region for the year 2000
-- ============================================

WITH sales_filtered AS (
    SELECT p.prod_name, SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.customers cu ON s.cust_id = cu.cust_id
    JOIN sh.countries co ON cu.country_id = co.country_id
    WHERE p.prod_category = 'Photo'
      AND co.country_region = 'Asia'
      AND EXTRACT(YEAR FROM s.time_id) = 2000
    GROUP BY p.prod_name
)
SELECT prod_name, ROUND(total_sales,2) AS total_sales
FROM sales_filtered
ORDER BY total_sales DESC;

-- ============================================
-- Task 3: TOP -300 customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001. 
-- ============================================

WITH yearly_sales AS (
    SELECT s.cust_id, s.channel_id, EXTRACT(YEAR FROM s.time_id) AS year, SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    WHERE EXTRACT(YEAR FROM s.time_id) IN (1998,1999,2001)
    GROUP BY s.cust_id, s.channel_id, EXTRACT(YEAR FROM s.time_id)
),
top_300_per_channel AS (
    SELECT ys1.cust_id, ys1.channel_id, ys1.year, ys1.total_sales
    FROM yearly_sales ys1
    WHERE (
        SELECT COUNT(*) 
        FROM yearly_sales ys2 
        WHERE ys2.channel_id = ys1.channel_id 
          AND ys2.year = ys1.year 
          AND ys2.total_sales >= ys1.total_sales
    ) <= 300
)
SELECT 
    cu.cust_first_name || ' ' || cu.cust_last_name AS customer_name,
    ch.channel_desc AS channel,
    t3.year,
    ROUND(t3.total_sales,2) AS total_sales
FROM top_300_per_channel t3
JOIN sh.customers cu ON t3.cust_id = cu.cust_id
JOIN sh.channels ch ON t3.channel_id = ch.channel_id
ORDER BY t3.year, ch.channel_desc, total_sales DESC;

-- ============================================
-- Task 4: Sales Jan–Mar 2000 for Europe and Americas
-- ============================================

SELECT 
    EXTRACT(MONTH FROM s.time_id) AS month,
    p.prod_category,
    ROUND(SUM(s.amount_sold),2) AS total_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
JOIN sh.customers cu ON s.cust_id = cu.cust_id
JOIN sh.countries co ON cu.country_id = co.country_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000
  AND EXTRACT(MONTH FROM s.time_id) IN (1,2,3)
  AND co.country_region IN ('Europe','Americas')
GROUP BY month, p.prod_category
ORDER BY month, p.prod_category;
