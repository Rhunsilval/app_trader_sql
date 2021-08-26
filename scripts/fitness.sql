SELECT a.name,
a.primary_genre,
p.name,
p.category
FROM app_store_apps AS a
FULL JOIN play_store_apps AS p
ON a.name = p.name
WHERE a.primary_genre iLIKE '%Health%'
OR p.category iLIKE '%Health%'