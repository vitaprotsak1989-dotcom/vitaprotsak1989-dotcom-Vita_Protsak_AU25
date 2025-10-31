
WITH movie_rentals AS (
SELECT
f.film_id,
f.title,
COUNT(r.rental_id) AS number_of_rentals,
CASE f.rating
WHEN 'G' THEN 0
WHEN 'PG' THEN 10
WHEN 'PG-13' THEN 13
WHEN 'R' THEN 17
WHEN 'NC-17' THEN 18
ELSE NULL
END AS expected_age
FROM film AS f
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating )
SELECT title, number_of_rentals, expected_age
FROM movie_rentals
ORDER BY number_of_rentals DESC
LIMIT 5;