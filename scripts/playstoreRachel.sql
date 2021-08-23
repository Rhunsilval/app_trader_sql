SELECT name, rating, category
FROM play_store_apps
WHERE rating IS NOT NULL
ORDER BY rating DESC;

-- The longer an app lives, the more money you can make on it
-- app lifespan is determined by star rating
-- so which apps have the highest rating
SELECT DISTINCT name,
	rating, 
	price,
	review_count,
	genres,
	category
FROM play_store_apps
--WHERE rating IS NOT NULL
--	AND price = '0'
ORDER BY price DESC, rating DESC;
--7594 results