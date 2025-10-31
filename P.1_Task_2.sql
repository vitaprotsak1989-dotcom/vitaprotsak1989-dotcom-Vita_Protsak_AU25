WITH store_revenue AS (
    SELECT
        s.store_id,
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