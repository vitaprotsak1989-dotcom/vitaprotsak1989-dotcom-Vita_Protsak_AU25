SELECT
s.first_name, s.last_name, s.store_id,
SUM(p.amount) AS revenue
FROM staff AS s
INNER JOIN payment AS p
ON s.staff_id = p.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY s.staff_id, s.first_name, s.last_name, s.store_id
ORDER BY revenue DESC
LIMIT 3;