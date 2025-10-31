WITH actor_films AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year
    FROM actor AS a
    INNER JOIN film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN film AS f
        ON fa.film_id = f.film_id
),
ordered_films AS (
    SELECT
        actor_id,
        first_name,
        last_name,
        release_year,
        LAG(release_year) OVER (PARTITION BY actor_id ORDER BY release_year) AS prev_year
    FROM actor_films
),
gaps AS (
    SELECT
        actor_id,
        first_name,
        last_name,
        release_year,
        prev_year,
        release_year - prev_year AS gap_years
    FROM ordered_films
    WHERE prev_year IS NOT NULL
)
SELECT
    first_name,
    last_name,
    MAX(gap_years) AS max_gap_years
FROM gaps
GROUP BY actor_id, first_name, last_name
ORDER BY max_gap_years DESC
LIMIT 10;
