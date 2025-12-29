-- 02_Data.sql (corregido)
USE `pois`;

START TRANSACTION;

-- =========================
-- DIM_COUNTRY
-- =========================
INSERT IGNORE INTO dim_country (country_name, country_latitude, country_longitude)
SELECT DISTINCT
  TRIM(name) AS country_name,
  country_latitude,
  country_longitude
FROM pois_22_12
WHERE name IS NOT NULL AND TRIM(name) <> '';

-- =========================
-- DIM_CITY
-- =========================
INSERT IGNORE INTO dim_city (country_id, city_name, city_latitude, city_longitude)
SELECT DISTINCT
  c.country_id,
  TRIM(p.city) AS city_name,
  p.city_latitude,
  p.city_longitude
FROM pois_22_12 p
JOIN dim_country c ON c.country_name = TRIM(p.name)
WHERE p.city IS NOT NULL AND TRIM(p.city) <> '';

-- =========================
-- DIM_CATEGORY (FILTRANDO NUMÉRICOS)
-- =========================
INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT
  TRIM(category) AS category_name
FROM pois_22_12
WHERE category IS NOT NULL
  AND TRIM(category) <> ''
  -- descarta valores que son SOLO números (lat/long colados)
  AND TRIM(category) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

-- =========================
-- DIM_SUBCATEGORY (FILTRANDO NUMÉRICOS)
-- =========================
INSERT IGNORE INTO dim_subcategory (category_id, subcategory_name)
SELECT DISTINCT
  c.category_id,
  TRIM(p.subcategory) AS subcategory_name
FROM pois_22_12 p
JOIN dim_category c ON c.category_name = TRIM(p.category)
WHERE p.subcategory IS NOT NULL
  AND TRIM(p.subcategory) <> ''
  AND TRIM(p.subcategory) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

-- =========================
-- DIM_POI
-- =========================
INSERT IGNORE INTO dim_poi
(poi_id, city_id, subcategory_id, poi_name, poi_latitude, poi_longitude, value_en)
SELECT
  p.id,
  ci.city_id,
  sc.subcategory_id,
  TRIM(p.poi) AS poi_name,
  p.poi_latitude,
  p.poi_longitude,
  NULLIF(TRIM(p.value_en), '') AS value_en
FROM pois_22_12 p
JOIN dim_country co ON co.country_name = TRIM(p.name)
JOIN dim_city ci ON ci.city_name = TRIM(p.city) AND ci.country_id = co.country_id
JOIN dim_category ca ON ca.category_name = TRIM(p.category)
JOIN dim_subcategory sc ON sc.subcategory_name = TRIM(p.subcategory) AND sc.category_id = ca.category_id
WHERE p.id IS NOT NULL
  AND p.poi IS NOT NULL AND TRIM(p.poi) <> '';

COMMIT;
