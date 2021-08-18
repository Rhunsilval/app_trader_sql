SELECT
	name
FROM app_store_apps
UNION ALL
SELECT
	name
FROM play_store_apps
ORDER BY name;