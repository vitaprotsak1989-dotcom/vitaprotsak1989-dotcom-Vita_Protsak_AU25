WITH actor_latest AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS latest_release_year
    FROM actor AS a
    INNER JOIN film_actor AS fa ON a.actor_id = fa.actor_id
    INNER JOIN film AS f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT
    first_name,
    last_name,
    latest_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - latest_release_year AS gap_years
FROM actor_latest
ORDER BY gap_years DESC
LIMIT 10;