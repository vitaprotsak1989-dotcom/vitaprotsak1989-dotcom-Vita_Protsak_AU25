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
  
