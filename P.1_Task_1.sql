SELECT  f.film_id, f.title, f.release_year, f.rental_rate
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