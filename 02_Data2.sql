-- 02_dims_from_pois.sql
USE `pois`;

START TRANSACTION;

INSERT IGNORE INTO dim_country (country_name, country_latitude, country_longitude)
SELECT DISTINCT name, country_latitude, country_longitude
FROM pois_22_12
WHERE name IS NOT NULL AND name <> '';

INSERT IGNORE INTO dim_city (country_id, city_name, city_latitude, city_longitude)
SELECT DISTINCT c.country_id, p.city, p.city_latitude, p.city_longitude
FROM pois_22_12 p
JOIN dim_country c ON c.country_name = p.name
WHERE p.city IS NOT NULL AND p.city <> '';

INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT category
FROM pois_22_12
WHERE category IS NOT NULL AND category <> '';

INSERT IGNORE INTO dim_subcategory (category_id, subcategory_name)
SELECT DISTINCT c.category_id, p.subcategory
FROM pois_22_12 p
JOIN dim_category c ON c.category_name = p.category
WHERE p.subcategory IS NOT NULL AND p.subcategory <> '';

INSERT IGNORE INTO dim_poi
(poi_id, city_id, subcategory_id, poi_name, poi_latitude, poi_longitude, value_en)
SELECT
  p.id,
  ci.city_id,
  sc.subcategory_id,
  p.poi,
  p.poi_latitude,
  p.poi_longitude,
  p.value_en
FROM pois_22_12 p
JOIN dim_country co ON co.country_name = p.name
JOIN dim_city ci ON ci.city_name = p.city AND ci.country_id = co.country_id
JOIN dim_category ca ON ca.category_name = p.category
JOIN dim_subcategory sc ON sc.subcategory_name = p.subcategory AND sc.category_id = ca.category_id;

COMMIT;
