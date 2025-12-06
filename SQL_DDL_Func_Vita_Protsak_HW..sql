-- Use core schema for these objects
CREATE SCHEMA IF NOT EXISTS core;

SET search_path = core, public;


--------------------------------------------------------------------------------
-- Task 1: View - sales_revenue_by_category_qtr
-- Dynamic: uses current_date so when quarter advances the view reflects new quarter
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW core.sales_revenue_by_category_qtr AS
SELECT
    c.category_id,
    c.name AS category,
    SUM(p.amount) AS total_revenue,
    EXTRACT(quarter FROM current_date)::int AS qtr,
    EXTRACT(year FROM current_date)::int AS yr
FROM
    public.payment p
    JOIN public.rental r ON r.rental_id = p.rental_id
    JOIN public.inventory i ON i.inventory_id = r.inventory_id
    JOIN public.film f ON f.film_id = i.film_id
    JOIN public.film_category fc ON fc.film_id = f.film_id
    JOIN public.category c ON c.category_id = fc.category_id
WHERE
    -- payment_date in current quarter and year
    EXTRACT(quarter FROM p.payment_date) = EXTRACT(quarter FROM current_date)
    AND EXTRACT(year FROM p.payment_date) = EXTRACT(year FROM current_date)
GROUP BY c.category_id, c.name
HAVING SUM(p.amount) > 0
ORDER BY total_revenue DESC;

--------------------------------------------------------------------------------
-- Task 2: Query-language function - get_sales_revenue_by_category_qtr
-- Accepts qtr (1..4) and yr (yyyy) and returns same shape as view.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.get_sales_revenue_by_category_qtr(
    in_qtr INT,
    in_yr INT
)
RETURNS TABLE (
    category_id INT,
    category TEXT,
    total_revenue NUMERIC,
    qtr INT,
    yr INT
)
LANGUAGE SQL
AS $$
    SELECT
        c.category_id,
        c.name AS category,
        SUM(p.amount) AS total_revenue,
        in_qtr AS qtr,
        in_yr AS yr
    FROM
        public.payment p
        JOIN public.rental r ON r.rental_id = p.rental_id
        JOIN public.inventory i ON i.inventory_id = r.inventory_id
        JOIN public.film f ON f.film_id = i.film_id
        JOIN public.film_category fc ON fc.film_id = f.film_id
        JOIN public.category c ON c.category_id = fc.category_id
    WHERE
        EXTRACT(quarter FROM p.payment_date) = in_qtr
        AND EXTRACT(year FROM p.payment_date) = in_yr
    GROUP BY c.category_id, c.name
    HAVING SUM(p.amount) > 0
    ORDER BY total_revenue DESC;
$$;
--------------------------------------------------------------------------------
-- Task 3: Procedure-language function - most popular film(s) by countries array
-- Returns most popular film per provided country (by rental count).
-- Input: array of country names (text[])
-- Output: setof rows: country, film_id, title, rentals_count
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.most_popular_films_by_countries(
    country_names TEXT[]
)
RETURNS TABLE (
    country_name TEXT,
    film_id INT,
    title TEXT,
    rentals_count BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    c TEXT;
    existing_count INT;
BEGIN
    -- validate input
    IF country_names IS NULL OR array_length(country_names, 1) IS NULL THEN
        RAISE EXCEPTION 'Input country list cannot be NULL or empty';
    END IF;

    -- Iterate over array and compute top film per country
    FOREACH c IN ARRAY country_names
    LOOP
        -- Ensure country exists
        SELECT COUNT(*) INTO existing_count FROM public.country WHERE name = c;
        IF existing_count = 0 THEN
            RAISE NOTICE 'Country "%" does not exist in country table - returning no rows for it.', c;
            CONTINUE;
        END IF;

        RETURN QUERY
        WITH film_rentals AS (
            SELECT
                f.film_id,
                f.title,
                COUNT(r.rental_id) AS cnt
            FROM public.rental r
            JOIN public.inventory i ON i.inventory_id = r.inventory_id
            JOIN public.film f ON f.film_id = i.film_id
            JOIN public.customer cu ON cu.customer_id = r.customer_id
            JOIN public.address a ON a.address_id = cu.address_id
            JOIN public.city ci ON ci.city_id = a.city_id
            JOIN public.country co ON co.country_id = ci.country_id
            WHERE co.name = c
            GROUP BY f.film_id, f.title
        ),
        ranked AS (
            SELECT *,
                ROW_NUMBER() OVER (ORDER BY cnt DESC, film_id) AS rn
            FROM film_rentals
        )
        SELECT c AS country_name, film_id, title, cnt::bigint AS rentals_count
        FROM ranked
        WHERE rn = 1;
    END LOOP;

    RETURN;
END;
$$;


--------------------------------------------------------------------------------
-- Task 4: Procedure-language function - films_in_stock_by_title(pattern)
-- Returns rows with row_num, inventory_id, film_id, title, store_id
-- If none found, returns a single row with row_num = 0 and message in title
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION core.films_in_stock_by_title(in_pattern TEXT)
RETURNS TABLE (
    row_num INT,
    inventory_id INT,
    film_id INT,
    title TEXT,
    store_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF in_pattern IS NULL OR trim(in_pattern) = '' THEN
        RAISE EXCEPTION 'Pattern must be provided, e.g., %%love%%';
    END IF;

    RETURN QUERY
    WITH available_inventory AS (
        SELECT i.inventory_id, i.film_id, i.store_id
        FROM public.inventory i
        LEFT JOIN public.rental r ON r.inventory_id = i.inventory_id AND r.return_date IS NULL
        WHERE r.rental_id IS NULL
    ),
    matched AS (
        SELECT
            ai.inventory_id,
            ai.film_id,
            f.title,
            ai.store_id
        FROM available_inventory ai
        JOIN public.film f ON f.film_id = ai.film_id
        WHERE f.title ILIKE in_pattern
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY title, inventory_id) AS row_num,
        inventory_id,
        film_id,
        title,
        store_id
    FROM matched;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0 AS row_num, NULL::INT AS inventory_id, NULL::INT AS film_id,
            'No available films in stock matching pattern: ' || in_pattern AS title, NULL::INT AS store_id;
    END IF;
END;
$$;
--------------------------------------------------------------------------------
-- Task 5: Procedure-language function - new_movie
-- Inserts a new film with given title (and optional release_year, language).
-- Defaults: rental_rate = 4.99, rental_duration = 3, replacement_cost = 19.99,
-- release_year defaults to current_year, language defaults to 'Klingon'.
-- Verifies language exists. If a similar film already exists (same title and language_id and release_year), returns existing film_id.
--------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION core.new_movie(
    in_title TEXT,
    in_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    in_language_name TEXT DEFAULT 'Klingon'
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_language_id INT;
    v_existing_film_id INT;
    v_new_film_id INT;
BEGIN
    -- Validate title
    IF in_title IS NULL OR trim(in_title) = '' THEN
        RAISE EXCEPTION 'Title must be provided';
    END IF;

    -- Find language id
    SELECT language_id INTO v_language_id
    FROM public.language
    WHERE name = in_language_name
    LIMIT 1;

    IF v_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" not found in language table', in_language_name;
    END IF;

    -- Check if film already exists
    SELECT film_id INTO v_existing_film_id
    FROM public.film
    WHERE title = in_title
      AND COALESCE(release_year, EXTRACT(YEAR FROM CURRENT_DATE)::INT) = in_release_year
      AND language_id = v_language_id
    LIMIT 1;

    IF v_existing_film_id IS NOT NULL THEN
        RETURN v_existing_film_id;  -- Return existing film id
    END IF;

    -- Insert new film
    INSERT INTO public.film(title, release_year, language_id, rental_duration, rental_rate, replacement_cost)
    VALUES (in_title, in_release_year, v_language_id, 3, 4.99, 19.99)
    RETURNING film_id INTO v_new_film_id;

    RETURN v_new_film_id;
END;
$$;
--------------------------------------------------------------------------------
-- Task 5: Procedure-language function - new_movie
-- Inserts a new film with given title (and optional release_year, language).
-- Defaults: rental_rate = 4.99, rental_duration = 3, replacement_cost = 19.99,
-- release_year defaults to current_year, language defaults to 'Klingon'.
-- Verifies language exists. If a similar film already exists (same title and language_id and release_year), returns existing film_id.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.new_movie(
    in_title TEXT,
    in_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    in_language_name TEXT DEFAULT 'Klingon'
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_language_id INT;
    v_existing_film_id INT;
    v_new_film_id INT;
BEGIN
    IF in_title IS NULL OR trim(in_title) = '' THEN
        RAISE EXCEPTION 'Title must be provided';
    END IF;

    -- Find language id
    SELECT language_id INTO v_language_id FROM public.language WHERE name = in_language_name LIMIT 1;
    IF v_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" not found in language table', in_language_name;
    END IF;

    -- Check if film already exists (avoid hardcoding IDs)
    SELECT film_id INTO v_existing_film_id
    FROM public.film
    WHERE title = in_title
      AND COALESCE(release_year, EXTRACT(YEAR FROM CURRENT_DATE)::INT) = in_release_year
      AND language_id = v_language_id
    LIMIT 1;

    IF v_existing_film_id IS NOT NULL THEN
        -- return existing id
        RETURN v_existing_film_id;
    END IF;

    -- Insert new film (use DEFAULT values for columns not provided)
    INSERT INTO public.film(
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        replacement_cost,
        rating,
        last_update
    ) VALUES (
        in_title,
        NULL,
        in_release_year,
        v_language_id,
        3,          -- rental_duration default 3 days
        4.99,       -- rental_rate default
        NULL,
        19.99,      -- replacement_cost default
        NULL,
        CURRENT_TIMESTAMP
    )
    RETURNING film_id INTO v_new_film_id;

    IF v_new_film_id IS NULL THEN
        RAISE EXCEPTION 'Failed to insert new film "%" (unexpected).', in_title;
    END IF;

    RETURN v_new_film_id;
END;
$$;
