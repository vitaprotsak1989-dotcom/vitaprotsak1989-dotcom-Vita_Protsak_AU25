-- =========================
-- STEP 1 — Insert 3 favorite films 
-- Law Abiding Citizen  -> rental_rate 4.99, rental_duration 7
-- Pretty Woman         -> rental_rate 9.99, rental_duration 14
-- Four Weddings and a Funeral  -> rental_rate 19.99, rental_duration 21
-- WHERE NOT EXISTS + RETURNING
-- =========================
INSERT INTO public.film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    last_update
)
SELECT
    'Law Abiding Citizen',
    'Crime thriller — favorite',
    2009,
    lang.language_id,  
    7,
    4.99,
    current_date
FROM public.language AS lang
WHERE lang.name = 'English'
  AND NOT EXISTS (
        SELECT 1 
        FROM public.film
        WHERE title = 'Law Abiding Citizen')
RETURNING film_id, title, last_update;

COMMIT;


INSERT INTO public.film (
  title, 
  description,
  release_year, 
  language_id,
  rental_duration, 
  rental_rate, 
  last_update
)
SELECT
  'PRETTY WOMAN',
  'Romantic comedy — favorite',
  1990,
  1,
  14,     -- 2 weeks
  9.99,
  current_date
WHERE NOT EXISTS (
  SELECT 1 FROM public.film 
  WHERE title = 'PRETTY WOMAN')
  RETURNING film_id, title, last_update;

COMMIT;


INSERT INTO public.film (
  title, description, release_year, language_id,
  rental_duration, rental_rate, last_update
)
SELECT
  'Four Weddings and a Funeral',
  'Romantic comedy-drama — favorite',
  1994,
  1,
  21,     -- 3 weeks
  19.99,
  current_date
WHERE NOT EXISTS (
  SELECT 1 FROM public.film WHERE title = 'Four Weddings and a Funeral')
RETURNING film_id, title, last_update;

COMMIT;




-- =========================
-- STEP 2 — Insert actors (6) and map to films (film_actor) — idempotent
-- Actors: Gerard Butler, Jamie Foxx, Richard Gere, Julia Roberts, Hugh Grant, Andie MacDowell
-- =========================

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT v.first_name, v.last_name, current_date
FROM (VALUES
  ('GERARD','BUTLER'),
  ('JAMIE','FOXX'),
  ('RICHARD','GERE'),
  ('JULIA','ROBERTS'),
  ('HUGH','GRANT'),
  ('ANDIE','MACDOWELL')
) AS v(first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.actor a WHERE a.first_name = v.first_name AND a.last_name = v.last_name)
  
RETURNING v.first_name, v.last_name, current_date;

COMMIT;

-- Map actors to films, skip existing mappings
-- Law Abiding Citizen -  Gerard Butler, Jamie Foxx
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title = 'Law Abiding Citizen'
WHERE (a.first_name, a.last_name) IN (('GERARD','BUTLER'),('JAMIE','FOXX'))
  AND NOT EXISTS (
    SELECT 1 FROM public.film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

-- Pretty Woman - Richard Gere, Julia Roberts
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title = 'PRETTY WOMAN'
WHERE (a.first_name, a.last_name) IN (('RICHARD','GERE'),('JULIA','ROBERTS'))
  AND NOT EXISTS (
    SELECT 1 FROM public.film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

-- Four Weddings - Hugh Grant, Andie MacDowell
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title = 'Four Weddings and a Funeral'
WHERE (a.first_name, a.last_name) IN (('HUGH','GRANT'),('ANDIE','MACDOWELL'))
  AND NOT EXISTS (
    SELECT 1 FROM public.film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

COMMIT;

-- Verify mappings
SELECT f.title, a.first_name, a.last_name
FROM public.film_actor fa
JOIN public.film f ON fa.film_id = f.film_id
JOIN public.actor a ON fa.actor_id = a.actor_id
WHERE f.title IN (
  'Law Abiding Citizen','PRETTY WOMAN','Four Weddings and a Funeral'
)
ORDER BY f.title, a.last_name;


-- =========================
-- STEP 3 — Add films to inventory 
-- =========================


WITH one_store AS (
  SELECT store_id FROM public.store LIMIT 1
)
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, current_date
FROM public.film f
CROSS JOIN one_store s
WHERE f.title IN (
  'Law Abiding Citizen','PRETTY WOMAN','Four Weddings and a Funeral'
)
AND NOT EXISTS (
  SELECT 1 FROM public.inventory inv WHERE inv.film_id = f.film_id AND inv.store_id = s.store_id
);




SELECT inv.inventory_id, f.title, inv.store_id, inv.last_update
FROM public.inventory inv
JOIN public.film f ON inv.film_id = f.film_id
WHERE f.title IN (
  'Law Abiding Citizen','PRETTY WOMAN','Four Weddings and a Funeral'
)
ORDER BY f.title;


-- =========================
STEP 4 — Find an existing customer with at least 43 rentals and 43 payments.
-- Then update that customer's personal data to my data.
-- The requirement: "Alter any existing customer in the database with at least 43 rental and 43 payment records."
-- We will FIRST SELECT candidate customers so you can VERIFY before the UPDATE runs.
-- If none exist, we will stop and show a message so you can create / choose another approach.
-- =========================


SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(DISTINCT r.rental_id) AS rental_count,
       COUNT(DISTINCT p.payment_id) AS payment_count
FROM public.customer c
JOIN public.rental r ON r.customer_id = c.customer_id
JOIN public.payment p ON p.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT r.rental_id) >= 43
   AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY c.customer_id
LIMIT 1;
COMMIT;


UPDATE customer
SET
    store_id = 1,
    first_name = 'Vita',
    last_name = 'Protsak',
    email = 'vita@example.com',
    address_id = 1,
    active = 1
WHERE customer_id = 1;

SELECT customer_id, first_name, last_name, email, address_id, active
FROM customer
WHERE customer_id = 1;
RETURNING customer_id, first_name, last_name, email, address_id, last_update;



 =========================================================
-- STEP 5 — Remove any records related to the chosen customer from all tables
-- except 'customer' and 'inventory'. We will DELETE from dependent tables (payment, rental, etc).
-- BEFORE deleting, we SHOW the rows to be deleted so you can verify them.
-- After your approval, run the DELETEs (the script below will perform them).
-- NOTE: deleting payments then rentals in correct order to respect FKs.
-- =========================================================