SELECT
price,
SUM(CAST(install_count AS integer))
FROM
(SELECT
price,
CASE
	WHEN install_count = '0+' THEN '1000'
	WHEN install_count = '1+' THEN '1000'
	WHEN install_count = '5+' THEN '1000'
	WHEN install_count = '10+' THEN '1000'
	WHEN install_count = '50+' THEN '1000'
 	WHEN install_count = '100+' THEN '1000'
 	WHEN install_count = '500+' THEN '1000'
 	WHEN install_count = '1,000+' THEN '5000'
 	WHEN install_count = '5,000+' THEN '10000'
 	WHEN install_count = '10,000+' THEN '50000'
 	WHEN install_count = '50,000+' THEN '100000'
 	WHEN install_count = '100,000+' THEN '500000'
 	WHEN install_count = '500,000+' THEN '1000000'
 	WHEN install_count = '1,000,000+' THEN '5000000'
 	WHEN install_count = '5,000,000+' THEN '10000000'
 	WHEN install_count = '10,000,000+' THEN '50000000'
 	WHEN install_count = '50,000,000+' THEN '100000000'
 	WHEN install_count = '100,000,000+' THEN '500000000'
 	WHEN install_count = '500,000,000+' THEN '1000000000'
END AS install_count
FROM play_store_apps
WHERE price <> '0') AS p
GROUP BY price
ORDER BY price

SELECT DISTINCT install_count
FROM play_store_apps


SELECT
category,
COUNT(category)
FROM (SELECT
CASE
	WHEN primary_genre = 'Games' THEN 'Entertainment & Games'
	WHEN primary_genre = 'Entertainment' THEN 'Entertainment & Games'
	ELSE primary_genre
	END AS category
FROM app_store_apps
--WHERE rating >= '4')
	  )AS apps
GROUP BY category
ORDER BY count DESC

SELECT
category,
COUNT(category)
FROM (SELECT
CASE
	WHEN category = 'GAME' THEN 'Family & Games'
	WHEN category = 'FAMILY' THEN 'Family & Games'
	ELSE category
	END AS category
FROM play_store_apps
--WHERE rating >= '4')
	  )AS apps
GROUP BY category
ORDER BY count DESC

select COUNT(*) AS count,
primary_genre
FROM app_store_apps
GROUP BY primary_genre
ORDER BY count DESC

select name,
primary_genre
FROM app_store_apps
WHERE name iLIKE '%Fitbit'

select name,
category
FROM play_store_apps
WHERE name iLIKE '%Fitbit'

SELECT COUNT(*) AS count,
category
FROM play_store_apps
GROUP BY category
ORDER BY count DESC

SELECT a.name,
a.primary_genre,
p.name,
p.category
FROM app_store_apps AS a
FULL JOIN play_store_apps AS p
ON a.name = p.name
WHERE a.primary_genre iLIKE '%Health%'
OR p.category iLIKE '%Health%'