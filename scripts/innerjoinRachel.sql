-- apps in both stores with 5-star ratings (longevity) and $0 initial cost (maximum investment)
WITH app AS (
	SELECT name AS app_name,
		rating AS app_rating,
		price AS app_price
	FROM app_store_apps
	WHERE rating = 5
		AND price = '0.00'),
play AS (
	SELECT name AS play_name,
		rating AS play_rating,
		price AS play_price
	FROM play_store_apps
	WHERE rating = 5.0
		AND price = '0')
SELECT app_name,
	app_rating,
	app_price,
	play_name,
	play_rating,
	play_price
FROM app
LEFT JOIN play
	ON app.app_name = play.play_name;
-- is not working?  on either left or inner join

--try again, simpler this time
SELECT a.name AS app_store_name,
	a.rating AS app_store_rating,
	p.rating AS play_store_rating,
	a.price AS app_store_price,
	p.price AS play_store_price,
	primary_genre AS app_store_genre, 
	category AS play_store_category
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
	ON a.name = p.name
ORDER BY app_store_rating DESC, play_store_rating DESC;
--553 results.  

-- what if it's just apps with 5 stars?
SELECT a.name AS app_store_name,
	a.rating AS app_store_rating,
	p.rating AS play_store_rating,
	a.price AS app_store_price,
	p.price AS play_store_price,
	primary_genre AS app_store_genre, 
	category AS play_store_category
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
	ON a.name = p.name
WHERE a.rating = '5.0'
ORDER BY play_store_rating DESC;
-- gives me 10 results ... this can't be right
-- one of them is in there twice, another is $6.99 in both stores ... not a good option.


-- okay, trying it again.
SELECT 
	p.name AS play_name,
	a.name AS app_name,
	p.install_count,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name;
-- i get 553 results.  apps in both stores with same name

-- let's narrow it down.  i want top rated apps.
SELECT 
	p.name AS play_name,
	a.name AS app_name,
	p.install_count,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, install_count DESC;
--yes!  can i narrow it down more.  i don't have install counts, but i have review counts for both

SELECT 
	DISTINCT p.name AS play_name,
	a.name AS app_name,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating,
	p.install_count AS play_installations,
--	p.review_count AS play_reviews,
--	a.review_count::integer AS app_reviews,
-- why are my app reviews text? fixed!
	(p.review_count + a.review_count::integer) AS total_reviews
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, play_installations DESC, total_reviews DESC;

-- can i do something with the price?  calculate initial investment price?
SELECT 
	DISTINCT p.name AS play_name,
	a.name AS app_name,
	p.price::money AS play_price,
	a.price::money AS app_price,
	CASE 
		WHEN p.price::money = '$0.00' AND a.price::money = '$0.00' THEN '$20,000'
		WHEN p.price::money = '$0.00' AND a.price::money > '$0.00' THEN ('$10000' + (a.price::money*10000))
		WHEN p.price::money > '$0.00' AND a.price::money = '$0.00' THEN ((p.price::money*10000) + '$10000')
		WHEN p.price::money > '$0.00' AND a.price::money > '$0.00' THEN (p.price::money + a.price::money)*10000
		ELSE '$0' END AS investment_cost,
--	p.rating AS play_rating,
--	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating,
	p.install_count AS play_installations,
--	p.review_count AS play_reviews,
--	a.review_count::integer AS app_reviews,
-- why are my app reviews text? fixed!
	(p.review_count + a.review_count::integer) AS total_reviews,
	p.genres AS play_genre,
	a.primary_genre AS app_genre,
	p.content_rating AS play_content,
	a.content_rating AS app_content
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, investment_cost, play_installations;



-- can i get rid of duplicates?  the play store is the guilty party ... 
WITH app_query AS(
	SELECT 
		DISTINCT p.name AS play_name,
		a.name AS app_name,
		--trying to get a window to give row numbers
		ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),
		p.price::money AS play_price,
		a.price::money AS app_price,
		CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END AS investment_cost,
	-- fixed the money since less than $1 = 10k, not just $0
		ROUND(((p.rating + a.rating)/2),1) AS avg_rating,
	-- can i calculate profit potential?!  
	-- longevity in months (12 + 24*average star rating) 
		-- calculated based on 12-month increases every .5 ratings = 2.4 months for every .1 stars
	-- times 9000 (5000/month earnings from each store minus 1000/month marketing cost total)
	-- minus initial investment cost (CASE calculation above)
		(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*9000)::money - 
			(CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit,
		p.install_count AS play_installations,
		(p.review_count + a.review_count::integer) AS total_reviews,
		p.genres AS play_genre,
		a.primary_genre AS app_genre,
		p.content_rating AS play_content,
		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY potential_profit DESC, play_installations)
SELECT *
FROM app_query
WHERE row_number = 1
	AND avg_rating > 4.0;
	
-- can i fix the play installations filter - change that to numeric or integer data?
--CTE with window to remove duplicates
WITH app_query AS(
	SELECT 
		DISTINCT p.name AS play_name,
		a.name AS app_name,
		--trying to get a window to give row numbers
		ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),
		p.price::money AS play_price,
		a.price::money AS app_price,
		CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END AS investment_cost,
		ROUND(((p.rating + a.rating)/2),1) AS avg_rating,
	-- can i calculate profit potential?!  
	-- longevity in months (12 + 24*average star rating) 
		-- calculated based on 12-month increases every .5 ratings = 2.4 months for every .1 stars
	-- times 9000 (5000/month earnings from each store minus 1000/month marketing cost total)
	-- minus initial investment cost (CASE calculation above)
		(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*9000)::money - 
			(CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit,
	-- turning play_installations into a# so it can sort properly
		(REPLACE(TRIM('+' FROM install_count),',',''))::int AS play_installations,
		(p.review_count + a.review_count::integer) AS total_reviews,
		p.genres AS play_genre,
		a.primary_genre AS app_genre,
		p.content_rating AS play_content,
		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY potential_profit DESC, play_installations DESC )
SELECT *
FROM app_query
WHERE row_number = 1
	AND avg_rating > 4.0;
	
