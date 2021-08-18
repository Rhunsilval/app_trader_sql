SELECT DISTINCT *
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
ON a.name = p.name
ORDER By a.price, p.price, a.rating DESC, p.rating DESC
LIMIT 20;








