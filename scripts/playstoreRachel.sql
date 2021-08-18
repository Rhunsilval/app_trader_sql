SELECT name, rating, category
FROM play_store_apps
WHERE rating IS NOT NULL
ORDER BY rating DESC;


