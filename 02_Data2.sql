-- 02_Data2.sql
/*
En este archivo se pueblan todas las tablas artificiales utilizando transaciones. La finalidad de este archivo es acceder a la 
base de datos creada anteriormente, para acceder a los datos y de esta manera poblar las tablas artificiales utilizandor los
propios datos reales del csv original.
*/
USE `pois`;
-- Comenzamos una transacción para ejecutar todo en bloque
START TRANSACTION;

/* 
En este insert, realizamos un IGNORE para ignorar aquellas filas (si es que hay) y no romper la transacción.
Utilizo un select dentro del INSERT para acceder a los datos fila por fila y atribuir los valores a cada campo de la tabla artificial "dim_country".
Utilizo como condición que se verifiquen que el nombre del pais no sea nulo y que no contenga espacios.
*/
INSERT IGNORE INTO dim_country (country_name, country_latitude, country_longitude)
SELECT DISTINCT
  TRIM(name) AS country_name,
  country_latitude,
  country_longitude
FROM pois_22_12
WHERE name IS NOT NULL AND TRIM(name) <> '';

/* 
Este insert realiza lo mismo que el anterior para la tabla artificial "dim_country", aunque en este realizamos un join 
para acceder y relacionar el id del pais de la tabla anterior, ya que en el original no existe y lo hemos normalizado previamente.
*/
INSERT IGNORE INTO dim_city (country_id, city_name, city_latitude, city_longitude)
SELECT DISTINCT
  c.country_id,
  TRIM(p.city) AS city_name,
  p.city_latitude,
  p.city_longitude
FROM pois_22_12 p
JOIN dim_country c ON c.country_name = TRIM(p.name)
WHERE p.city IS NOT NULL AND TRIM(p.city) <> '';

/* 
Este insert realiza lo mismo que el anterior para la tabla artificial "dim_category". En la query de este instert,
necesitamos realizar un regexp para asegurarnos de que los unicos valores que se introducen en esta tabla son las categorias. 
Esto lo hago porque previamente, algunas filas del csv no estaban bien alineadas y generaban incoherencias 
poniendo latitudes y longitudes como nombres de categoria.
*/
INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT
  TRIM(category) AS category_name
FROM pois_22_12
WHERE category IS NOT NULL
  AND TRIM(category) <> ''
  -- descarta valores que son SOLO números (lat/long colados)
  AND TRIM(category) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

/* 
Este insert realiza lo mismo que el anterior para la tabla artificial "dim_subcategory". En esta realizo un join para poder acceder al id
de la categoria una vez creada la tabla anterior, ya que el csv original no le atribuia un id a cada categoria.
*/
INSERT IGNORE INTO dim_subcategory (category_id, subcategory_name)
SELECT DISTINCT
  c.category_id,
  TRIM(p.subcategory) AS subcategory_name
FROM pois_22_12 p
JOIN dim_category c ON c.category_name = TRIM(p.category)
WHERE p.subcategory IS NOT NULL
  AND TRIM(p.subcategory) <> ''
  AND TRIM(p.subcategory) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

/* 
Este insert realiza lo mismo que el anterior para la tabla artificial "dim_poi". En esta realizo varios joins para poder 
poblar la tabla con todos los datos de las tablas creadas anteriormente. Esta tabla es una  tabla de poi reducida para generar
menos ruido y tener solamente los valores necesarios de ese propio poi.
*/
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
