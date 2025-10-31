WITH actor_movie_count AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS number_of_movies
    FROM actor AS a
    INNER JOIN film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN film AS f
        ON fa.film_id = f.film_id
    WHERE f.release_year > 2015
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name, number_of_movies
FROM actor_movie_count
ORDER BY number_of_movies DESC
LIMIT 5;


