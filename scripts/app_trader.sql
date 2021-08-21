/*SELECT
	name,
	price,
	CAST((CASE WHEN price <= 1.00 THEN 10000
	ELSE (price*10000) END) AS money) AS purchase_cost,
	review_count,
	rating,
	ROUND((rating/.5), 1) AS longevity,
	content_rating,
	primary_genre AS genres
FROM app_store_apps AS iphone;*/

/*SELECT DISTINCT a.name, p.name, a.price, p.price, a.rating, p.rating, a.primary_genre, p.genres,
CASE WHEN a.price <= 1.00 THEN 10000
ELSE (a.price * 10000) END AS purchase_cost,
CASE WHEN CAST(p.price AS numeric) <= 1.00 THEN 10000
ELSE CAST(p.price AS numeric) * 10000 END AS purchase_cost_2
FROM app_store_apps as a
JOIN play_store_apps as p
ON a.name = p.name
ORDER BY a.name, a.price, a.rating;*/

-- Full Join with play store and combining columns
SELECT
-- combine iphone and google name columns - if one is null, take value from the other
	CASE WHEN p.name IS NULL THEN a.name
	WHEN a.name IS NULL THEN p.name
	ELSE p.name || '-' || a.name END AS combname,
	INITCAP(p.category) AS category,
-- effort to combine disparate categories  (didn't work right)
	CASE WHEN a.primary_genre IS NULL THEN p.genres
	WHEN p.genres IS NULL THEN a.primary_genre
	ELSE p.genres END AS subcategory,
-- need to distill into sub genres with cleaning
--	a.primary_genre,
--	p.genres,
	p.rating AS p_rating, CAST(ROUND(p.rating/.5) AS decimal) AS round_p,
	p.review_count AS p_reviews,
	p.install_count AS play_installs,
	a.rating AS a_rating, CAST(ROUND(a.rating/.5) AS decimal) AS round_a,
	a.review_count AS a_reviews,
	p.price AS p_price,
	a.price AS a_price,
	p.content_rating,
	a.content_rating,
-- if no title in play store, label it iphone app, if no name in iphone store, label it android - if matched name, label it both
	CASE WHEN p.name IS NULL THEN 'iPhone'
	WHEN a.name IS NULL THEN 'Android'
	ELSE 'Both' END AS Store
FROM play_store_apps AS p
FULL JOIN app_store_apps AS a
ON p.name = a.name

ORDER BY combname, p.rating DESC, a.rating DESC;









