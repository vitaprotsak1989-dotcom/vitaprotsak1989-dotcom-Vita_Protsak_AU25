/* =========================================================
TASK 1 Part 1:
------------------------------------------------------------
Part 1: Write SQL queries to retrieve the following data. 
1.The marketing team needs a list of animation 
movies between 2017 and 2019 to promote family-friendly 
content in an upcoming season in stores. 
Show all animation movies released during this period with rate more than 1, sorted alphabetically
------------------------------------------------------------
=========================================================== */


/* =========================================================
 1 — CTE VERSION
=========================================================== */

WITH animation_movies AS (
SELECT
f.film_id, f.title, f.release_year, f.rental_rate, fc.category_id
FROM film AS f
INNER JOIN film_category AS fc
ON f.film_id = fc.film_id
WHERE fc.category_id = 2
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1 )
SELECT
film_id, title, release_year, rental_rate
FROM animation_movies
ORDER BY title ASC;SELECT  f.film_id, f.title, f.release_year, f.rental_rate
FROM film AS f
INNER JOIN film_category AS fc
ON f.film_id = fc.film_id
INNER JOIN (
SELECT category_id
FROM category
WHERE name = 'Animation') 
AS c
ON fc.category_id = c.category_id
WHERE f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1
ORDER BY f.title ASC;

/* =========================================================
 2 — SUBQUERY VERSION
=========================================================== */
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM film AS f
WHERE f.film_id IN (
SELECT fc.film_id
FROM film_category AS fc
WHERE fc.category_id = 2 )
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1
ORDER BY f.title ASC;


/* =========================================================
 3 — JOIN VERSION
=========================================================== */
WITH animation_movies AS (
SELECT
f.film_id, f.title, f.release_year, f.rental_rate, fc.category_id
FROM film AS f
INNER JOIN film_category AS fc
ON f.film_id = fc.film_id
WHERE fc.category_id = 2
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1 )
SELECT
film_id, title, release_year, rental_rate
FROM animation_movies
ORDER BY title ASC;

/* =========================================================
 ADVANTAGES AND DISADVANTAGES:
------------------------------------------------------------

-- CTE:
-- + Best readability and logical structure.
-- + Easy to reuse and modify in complex queries.
-- - Slightly more memory use (intermediate table stored temporarily).
-- - Can be slower for one-time queries.

-- SUBQUERY:
-- + Compact, simple for small datasets.
-- + Keeps filtering logic close to main SELECT.
-- - Can perform worse with large tables (subquery runs per row).
-- - Harder to debug.

-- JOIN:
-- + Typically fastest for large datasets (uses indexes efficiently).
-- + Optimizer can merge joins into one scan.
-- - Slightly less readable for beginners.
-- - Risk of duplicates if join is not handled properly.
and sort them alphabetically by title.
and sort them alphabetically by title.
=========================================================== */


/* =========================================================
BUSINESS LOGIC INTERPRETATION:
------------------------------------------------------------
We need to find all films that belong to the “Animation” category. 
According to the database structure, 'film' connects to 'film_category'
through 'film_id'. Category_id = 2 represents “Animation”.
We filter only those films where:
 - release_year is between 2017 and 2019,
 - rental_rate is greater than 1.
Then we display film_id, title, release_year, and rental_rate 
and sort them alphabetically by title.
=========================================================== */

/* =========================================================
TASK 2 Part 1:
------------------------------------------------------------
Part 1: Write SQL queries to retrieve the following data. 
2. The finance department requires a report on store performance to assess profitability and plan
resource allocation for stores after March 2017. 
Calculate the revenue earned by each rental store after March 2017 (since April) 
(include columns: address and address2 – as one column, revenue)
------------------------------------------------------------
=========================================================== */
/* =========================================================
 1 — CTE VERSION
=========================================================== */

WITH animation_movies AS (
SELECT
f.film_id, f.title, f.release_year, f.rental_rate, fc.category_id
FROM film AS f
INNER JOIN film_category AS fc
ON f.film_id = fc.film_id
WHERE fc.category_id = 2
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1 )
SELECT
film_id, title, release_year, rental_rate
FROM animation_movies
ORDER BY title ASC;WITH store_revenue AS (
SELECT  s.store_id,
CONCAT_WS(' ', a.address, a.address2) AS full_address,
SUM(p.amount) AS revenue
FROM store AS s
INNER JOIN address AS a
ON s.address_id = a.address_id
INNER JOIN customer AS c
ON s.store_id = c.store_id
INNER JOIN payment AS p
ON c.customer_id = p.customer_id
INNER JOIN rental AS r
ON p.rental_id = r.rental_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY s.store_id, full_address
)
SELECT *
FROM store_revenue
ORDER BY revenue DESC;

/* =========================================================
 2 — SUBQUERY VERSION
=========================================================== */
SELECT  s.store_id,
CONCAT_WS(' ', a.address, a.address2) AS full_address,
( SELECT SUM(p.amount)
FROM customer AS c
INNER JOIN payment AS p ON c.customer_id = p.customer_id
INNER JOIN rental AS r ON p.rental_id = r.rental_id
WHERE c.store_id = s.store_id
AND p.payment_date >= '2017-04-01') 
AS revenue
FROM store AS s
INNER JOIN address AS a ON s.address_id = a.address_id
ORDER BY revenue DESC;

/* =========================================================
 3 — JOIN VERSION
=========================================================== */
SELECT  s.store_id,
CONCAT_WS(' ', a.address, a.address2) AS full_address,
SUM(p.amount) AS revenue
FROM store AS s
INNER JOIN address AS a ON s.address_id = a.address_id
INNER JOIN customer AS c ON s.store_id = c.store_id
INNER JOIN payment AS p ON c.customer_id = p.customer_id
INNER JOIN rental AS r ON p.rental_id = r.rental_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY s.store_id, full_address
ORDER BY revenue DESC;



/* =========================================================
 ADVANTAGES AND DISADVANTAGES:
------------------------------------------------------------
-- CTE:
-- + Clean, structured, reusable.
-- - Slightly heavier if not reused multiple times.

-- SUBQUERY:
-- + Simple structure for one-time calculations.
-- - May execute the inner query many times; slower on big data.

-- JOIN:
-- + Efficient on indexed tables; fastest for aggregation.
-- - Can be visually complex with multiple joins.
=========================================================== */

/* =========================================================
BUSINESS LOGIC INTERPRETATION:
------------------------------------------------------------
We calculate how much revenue each store generated after 2017-04-01.
We join:
 - store → address (to get full address)
 - store → customer → payment → rental (to connect all transactions)
Then we group by store_id and address, summing the payments.
=========================================================== */


/* =========================================================
TASK 3 Part 1:
------------------------------------------------------------
Part 1: Write SQL queries to retrieve the following data. 
3.The marketing department in our stores aims to identify the most 
successful actors since 2015 to boost customer interest in their films. 
Show top-5 actors by number of movies (released after 2015) 
they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
------------------------------------------------------------
=========================================================== */

/* =========================================================
 1 — CTE VERSION
=========================================================== */
WITH actor_movie_count AS (
SELECT a.actor_id, a.first_name, a.last_name,
COUNT(fa.film_id) AS number_of_movies
FROM actor AS a
INNER JOIN film_actor AS fa
ON a.actor_id = fa.actor_id
INNER JOIN film AS f
ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name )
SELECT first_name, last_name, number_of_movies
FROM actor_movie_count
ORDER BY number_of_movies DESC
LIMIT 5;

/* =========================================================
 2 — SUBQUERY VERSION
=========================================================== */
SELECT a.first_name, a.last_name,
( SELECT COUNT(fa.film_id)
FROM film_actor AS fa
INNER JOIN film AS f
ON fa.film_id = f.film_id
WHERE fa.actor_id = a.actor_id
AND f.release_year > 2015) AS number_of_movies
FROM actor AS a
ORDER BY number_of_movies DESC
LIMIT 5;


/* =========================================================
 3 — JOIN VERSION
=========================================================== */
SELECT a.first_name, a.last_name,
COUNT(fa.film_id) AS number_of_movies
FROM actor AS a
INNER JOIN film_actor AS fa
ON a.actor_id = fa.actor_id
INNER JOIN film AS f
ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

/* =========================================================
ADVANTAGES AND DISADVANTAGES:
=========================================================== 

-- JOIN:
-- + Efficient on indexed tables; fastest for aggregation.
-- + Ideal for combining multiple related datasets.
-- - Can be visually complex with many joins.
-- - Requires precise grouping to avoid duplicates.

-- SUBQUERY:
-- + Simple structure for one-time calculations.
-- + Keeps main query easy to read.
-- - Inner query executes for each row (can be slower on large data).
-- - Harder to debug or extend for multi-level logic.

-- CTE:
-- + Clean, structured, and reusable.
-- + Great readability for multi-step logic.
-- - Slightly heavier if used only once.
-- - May have small overhead compared to a single join query.
=========================================================== */

/* =========================================================
BUSINESS LOGIC INTERPRETATION:
------------------------------------------------------------
We need to find which actors have participated in the greatest
number of films released after 2015.

The logic:
- Table actor → contains actor names
- Table film_actor → connects actors with films
- Table film → contains release year

We will count how many films each actor appeared in after 2015,
sort by number_of_movies descending, and show top-5 results.
=========================================================== */


/* =========================================================
TASK 4 Part 1:
------------------------------------------------------------
Part 1: Write SQL queries to retrieve the following data. 
4.The marketing team needs to track the production trends of Drama, Travel, 
and Documentary films to inform genre-specific marketing strategies. Ырщц number of Drama, 
Travel, Documentary per year (include columns: release_year, 
number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
sorted by release year in descending order. Dealing with NULL values is encouraged)
------------------------------------------------------------
=========================================================== */
/* =========================================================
 1 — CTE VERSION
=========================================================== */
WITH genre_trends AS (
    SELECT
        f.release_year,
        SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
        SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
        SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
    FROM public.film AS f
    INNER JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY f.release_year
)
SELECT 
    release_year,
    number_of_drama_movies,
    number_of_travel_movies,
    number_of_documentary_movies
FROM genre_trends
ORDER BY release_year DESC;


/* =========================================================
 2 — SUBQUERY VERSION
=========================================================== */
SELECT f.release_year,
(SELECT COUNT(*)
FROM public.film_category AS fc
INNER JOIN public.category AS c
ON fc.category_id = c.category_id
INNER JOIN public.film AS f2
ON fc.film_id = f2.film_id
WHERE c.name = 'Drama'
AND f2.release_year = f.release_year) AS number_of_drama_movies,
(SELECT COUNT(*)
FROM public.film_category AS fc
INNER JOIN public.category AS c
ON fc.category_id = c.category_id
INNER JOIN public.film AS f2
ON fc.film_id = f2.film_id
WHERE c.name = 'Travel'
AND f2.release_year = f.release_year) AS number_of_travel_movies,
(SELECT COUNT(*)
FROM public.film_category AS fc
INNER JOIN public.category AS c
ON fc.category_id = c.category_id
INNER JOIN public.film AS f2
ON fc.film_id = f2.film_id
WHERE c.name = 'Documentary'
AND f2.release_year = f.release_year) AS number_of_documentary_movies
FROM public.film AS f
GROUP BY f.release_year
ORDER BY f.release_year DESC;

/* =========================================================
 3 — JOIN VERSION
=========================================================== */
SELECT f.release_year,
SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM public.film AS f
INNER JOIN public.film_category AS fc
ON f.film_id = fc.film_id
INNER JOIN public.category AS c
ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;


/* =========================================================
ADVANTAGES AND DISADVANTAGE:
=========================================================== 

-- JOIN:
-- + Efficient and straightforward for aggregated data.
-- + Best performance with proper indexing.
-- - Can look bulky when multiple conditions and CASE statements used.

-- SUBQUERY:
-- + Simple and readable for small datasets.
-- + Easy to isolate logic for each calculated column.
-- - Executes multiple times (once per film); poor performance on large data.
-- - Harder to maintain and extend.

-- CTE:
-- + Clean, modular, and reusable.
-- + Improves readability for multi-step logic.
-- - Slightly more memory usage if not reused.
-- - Minimal overhead compared to a single JOIN.
=========================================================== */


/* =========================================================
INTERPRETATION OF BUSINESS LOGIC:
------------------------------------------------------------
The task requires analyzing production trends for three genres 
(Drama, Travel, Documentary) by counting the number of movies 
released each year per genre. 
We will group films by release_year and calculate totals 
for each genre using conditional aggregation.
=========================================================== */



/* =========================================================
TASK 1 Part 2:
------------------------------------------------------------
Part 2: Solve the following problems using SQL
The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
Show which three employees generated the most revenue in 2017? 
Assumptions: 
staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
if staff processed the payment then he works in the same store; 
take into account only payment_date
------------------------------------------------------------
=========================================================== */
/* =========================================================
1 — CTE VERSION
=========================================================== */
WITH staff_revenue AS (
SELECT s.staff_id, s.first_name, s.last_name, s.store_id,
SUM(p.amount) AS revenue
FROM public.staff AS s
INNER JOIN public.payment AS p
ON s.staff_id = p.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY s.staff_id, s.first_name, s.last_name, s.store_id
)
SELECT  first_name, last_name, store_id,revenue
FROM staff_revenue
ORDER BY revenue DESC
LIMIT 3;


/* =========================================================
2 — SUBQUERY VERSION
=========================================================== */
SELECT s.first_name, s.last_name, s.store_id,
( SELECT SUM(p.amount)
FROM public.payment AS p
WHERE p.staff_id = s.staff_id
AND EXTRACT(YEAR FROM p.payment_date) = 2017 ) 
AS revenue
FROM public.staff AS s
ORDER BY revenue DESC
LIMIT 3;


/* =========================================================
3 — JOIN VERSION
=========================================================== */
SELECT s.first_name, s.last_name, s.store_id,
SUM(p.amount) AS revenue
FROM public.staff AS s
INNER JOIN public.payment AS p
ON s.staff_id = p.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY s.staff_id, s.first_name, s.last_name, s.store_id
ORDER BY revenue DESC
LIMIT 3;


/* =========================================================
ADVANTAGES AND DISADVANTAGES:
===========================================================

-- CTE:
-- + Improves readability and structure.
-- + Easy to reuse or extend (e.g., combine with other analytics).
-- - Slightly more memory usage if used only once.

-- SUBQUERY:
-- + Simple and intuitive for small datasets.
-- + Easy to isolate logic per employee.
-- - Executes inner query multiple times (one per employee) → slower on large data.

-- JOIN:
-- + Fastest for grouped aggregation on indexed columns.
-- + Clear data relationships between staff and payment tables.
-- - Can become visually complex in larger multi-table joins.

=========================================================== */


/* =========================================================
INTERPRETATION OF BUSINESS LOGIC
------------------------------------------------------------
This task identifies the top three employees who brought 
the highest total revenue from payments in 2017.

Each staff member’s revenue is calculated by summing 
the total payment amounts they processed that year.

The query also shows which store the employee last worked in, 
as per the assumption that if staff processed the payment, 
they worked in the same store.
=========================================================== */




/* =========================================================
TASK 2 Part 2:
------------------------------------------------------------
Part 2: Solve the following problems using SQL
The management team wants to identify the most popular movies and their 
target audience age groups to optimize marketing efforts. 
Show which 5 movies were rented more than others (number of rentals), 
and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture Association film rating system'
------------------------------------------------------------
=========================================================== */
/* =========================================================
1 — CTE VERSION
=========================================================== */
WITH movie_rentals AS (
SELECT f.film_id, f.title,
COUNT(r.rental_id) AS number_of_rentals,
CASE f.rating
WHEN 'G' THEN 0
WHEN 'PG' THEN 10
WHEN 'PG-13' THEN 13
WHEN 'R' THEN 17
WHEN 'NC-17' THEN 18
ELSE NULL
END AS expected_age
FROM public.film AS f
INNER JOIN public.inventory AS i
ON f.film_id = i.film_id
INNER JOIN public.rental AS r
ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
)
SELECT title, number_of_rentals, expected_age
FROM movie_rentals
ORDER BY number_of_rentals DESC
LIMIT 5;


/* =========================================================
2 — SUBQUERY VERSION
=========================================================== */
SELECT f.title,(
SELECT COUNT(r.rental_id)
FROM public.inventory AS i
INNER JOIN public.rental AS r
ON i.inventory_id = r.inventory_id
WHERE i.film_id = f.film_id) 
AS number_of_rentals,
CASE f.rating
WHEN 'G' THEN 0
WHEN 'PG' THEN 10
WHEN 'PG-13' THEN 13
WHEN 'R' THEN 17
WHEN 'NC-17' THEN 18
ELSE NULL
END AS expected_age
FROM public.film AS f
ORDER BY number_of_rentals DESC
LIMIT 5;


/* =========================================================
3 — JOIN VERSION
=========================================================== */
SELECT f.title,
COUNT(r.rental_id) AS number_of_rentals,
CASE f.rating
WHEN 'G' THEN 0
WHEN 'PG' THEN 10
WHEN 'PG-13' THEN 13
WHEN 'R' THEN 17
WHEN 'NC-17' THEN 18
ELSE NULL
END AS expected_age
FROM public.film AS f
INNER JOIN public.inventory AS i
ON f.film_id = i.film_id
INNER JOIN public.rental AS r
ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY number_of_rentals DESC
LIMIT 5;


/* =========================================================
ADVANTAGES AND DISADVANTAGES:
===========================================================

-- CTE:
-- + Readable and modular structure.
-- + Allows easy extension or reuse in analytical tasks.
-- - Slightly higher memory usage when used once.

-- SUBQUERY:
-- + Simple to read and understand for smaller datasets.
-- + Each column’s logic is isolated.
-- - Performs worse on large datasets due to repeated subquery execution.
-- - Harder to maintain and extend.

-- JOIN:
-- + Most efficient on large datasets with proper indexing.
-- + Clear data relationships across tables.
-- - Query may become visually complex with additional joins.

=========================================================== */


/* =========================================================
INTERPRETATION OF BUSINESS LOGIC
------------------------------------------------------------
The goal is to determine the top 5 most rented movies 
and define their expected target audience based on the 
Motion Picture Association film rating system.

The expected age is calculated as follows:
- G  → 0 years (General audience)
- PG → 10 years
- PG-13 → 13 years
- R → 17 years
- NC-17 → 18 years and above

This analysis helps the management team to optimize marketing 
strategies for the most popular films and their age groups.
=========================================================== */


/* =========================================================
TASK 1 Part 3:
------------------------------------------------------------
Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted promotional campaigns,
 highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
V1: gap between the latest release_year and current year per each actor;
V2: gaps between sequential films per each actor;
------------------------------------------------------------
=========================================================== */
/* =========================================================
V1 — GAP BETWEEN LATEST RELEASE YEAR AND CURRENT YEAR
=========================================================== */
WITH actor_latest AS (
SELECT a.actor_id, a.first_name, a.last_name,
MAX(f.release_year) AS latest_release_year
FROM public.actor AS a
INNER JOIN public.film_actor AS fa 
ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f 
ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name, latest_release_year,
EXTRACT(YEAR FROM CURRENT_DATE) - latest_release_year AS gap_years
FROM actor_latest
ORDER BY gap_years DESC
LIMIT 10;


/* =========================================================
V2 — GAP BETWEEN SEQUENTIAL FILMS PER ACTOR
=========================================================== */
WITH actor_films AS (
SELECT a.actor_id, a.first_name, a.last_name, f.release_year
FROM public.actor AS a
INNER JOIN public.film_actor AS fa
ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f
ON fa.film_id = f.film_id
),
ordered_films AS (
SELECT actor_id, first_name, last_name, release_year,
LAG(release_year) OVER (PARTITION BY actor_id ORDER BY release_year) AS prev_year
FROM actor_films
),
gaps AS (
SELECT actor_id, first_name, last_name, release_year, prev_year, release_year - prev_year AS gap_years
FROM ordered_films
WHERE prev_year IS NOT NULL
)
SELECT first_name, last_name,
MAX(gap_years) AS max_gap_years
FROM gaps
GROUP BY actor_id, first_name, last_name
ORDER BY max_gap_years DESC
LIMIT 10;


/* =========================================================
ADVANTAGES AND DISADVANTAGES:
===========================================================

-- V1:
-- + Simple and efficient (only uses latest release year).
-- + Clearly shows who hasn’t acted for the longest time.
-- - Doesn’t detect multiple long breaks — only the last one.

-- V2:
-- + Reveals patterns of inactivity throughout an actor’s career.
-- + Identifies specific long breaks (not just the latest).
-- - Slightly more complex and computationally heavier due to window functions.

=========================================================== */


/* =========================================================
BUSINESS INTERPRETATION
------------------------------------------------------------
Both approaches help marketing teams understand actors’ career timelines:
- V1 identifies actors with long gaps since their last film — potential comeback stories.
- V2 identifies actors with major breaks between movies — useful for nostalgic campaigns.
=========================================================== */