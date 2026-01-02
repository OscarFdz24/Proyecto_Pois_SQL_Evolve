-- EDA POis
-- BLOQUE 1

-- ¿Cuantos Pois existen en la BDD?
USE pois;
SELECT COUNT(*) FROM pois_22_12;
-- Existen 311658 Pois en la BDD

-- ¿Cuántas categorías y subcategorías existen tras la limpieza?
SELECT COUNT(DISTINCT c.category_id) as num_categorias,  COUNT(DISTINCT s.subcategory_id) as num_subcategorias FROM dim_category as c
JOIN dim_subcategory as s ON c.category_id=s.category_id ;
-- Existen 10 categorias y 36 subcategorias

-- ¿Cuántos POIs tienen actividad registrada (FACT) frente al total de POIs?
SELECT COUNT(*) FROM fact_poi_activity;
-- 5000 POIs tienen actividad, es normal ya que se puso como limite 5000 en la creación de esta tabla

-- ¿Cuántos POIs no tienen actividad registrada?
SELECT COUNT(*) AS  pois_sin_actividad FROM dim_poi dm
LEFT JOIN fact_poi_activity fpa ON dm.poi_id = fpa.poi_id
WHERE fpa.poi_id IS NULL;

-- ¿Hay POIs sin categoría o sin subcategoría?
SELECT * FROM pois_22_12
WHERE category IS NULL OR subcategory IS NULL;
-- Hay 4 POIs en total que no contienen categoria o subcategoria ya que estan practicamente vacios

-- Realizamos esta query pora consultar en la tabla de POIs normalizada "dim_poi" si también están o es solo en el original
SELECT COUNT(*) FROM dim_poi
WHERE subcategory_id IS NULL;
-- El resultado es 0, solo están en la tabla original del csv sin normalizar

-- Existen valores nulos en métricas clave (visits, revenue, rating)?
SELECT COUNT(*) FROM fact_poi_activity
WHERE visits IS NULL OR revenue_eur IS NULL OR avg_rating IS NULL;
-- El resultado da 0, por lo que en esa tabla no hay ninguna con valores clave nulos

-- BLOQUE 2
-- ¿Qué países concentran más POIs?
SELECT p.name, COUNT(dm.poi_id) as num_POIs FROM dim_poi dm
INNER JOIN pois_22_12 p ON dm.poi_id=p.id
GROUP BY p.name
ORDER BY num_POIs DESC
LIMIT 10;
-- El resultado nos muestra los 10 paises con más POIs

-- ¿Qué ciudades tienen mayor número de POIs?
SELECT c.city_name, COUNT(*) AS num_pois
FROM dim_poi p
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY c.city_name
ORDER BY num_pois DESC
LIMIT 10;
-- En este caso ocurre algo extraño, aparece que hay una fila 'NULL' con 39K Pois, pero tras hacer varias comprobaciones no doy con la razón de porque aparecen
-- En todo caso, abajo aparecen las ciudades ordenadas por el numero de POIs que tiene cada una.

UPDATE dim_city
SET city_name = 'Unknown'
WHERE city_name IS NULL;

-- ¿Qué ciudades generan más visitas totales?
SELECT
  c.city_name AS ciudad,
  SUM(fpa.visits) AS total_visitas
FROM fact_poi_activity fpa
INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY p.city_id, c.city_name
ORDER BY total_visitas DESC
LIMIT 10;

-- ¿Qué ciudades generan más ingresos totales?
SELECT
  c.city_name AS ciudad,
  SUM(fpa.revenue_eur) AS media_ingresos_mensual
FROM fact_poi_activity fpa
INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY p.city_id, c.city_name
ORDER BY media_ingresos_mensual DESC
LIMIT 10;
-- Madrid y Barcelona son las ciudades que mas ingreso mensual generan

-- BLOQUE 3 — Categorías y tipologías
-- ¿Qué categorías tienen más POIs?
SELECT dc.category_name, COUNT(dp.poi_id) as num_POIs FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
GROUP BY dc.category_name
ORDER BY num_POIs DESC;
-- Las categorias que contienen más POIs son 'Religioso' e 'Historico' 

-- ¿Qué categorías concentran más visitas?
SELECT dc.category_name, SUM(fpa.visits) as num_visitas FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY num_visitas DESC;

-- ¿Qué categorías generan más ingresos?
SELECT dc.category_name, SUM(fpa.revenue_eur) as total_ingresos FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY total_ingresos DESC;

-- ¿Qué categorías tienen mejor valoración media?
SELECT dc.category_name, ROUND(AVG(fpa.avg_rating),2) as valoracion_media FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY valoracion_media DESC;

-- ¿Existen categorías con muchas visitas pero bajo rating medio?
-- Para este ejercicio supondremos que consideramos bajo un rating por debajo de 3.75 de valoracion media
-- De la misma manera consideraremos que tiene muchas visitas cuando supera las 10000
SELECT
  dc.category_id,
  dc.category_name,
  SUM(fpa.visits) AS num_visitas,
  AVG(fpa.avg_rating) AS valoracion_media
FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_id, dc.category_name
HAVING AVG(fpa.avg_rating) < 3.75 AND SUM(fpa.visits) >= 10000
ORDER BY num_visitas DESC;

-- BLOQUE 4 — Análisis temporal (MONTH / YEAR)
-- ¿Cómo se distribuye la actividad a lo largo del año?
SELECT
  MONTH(fpa.activity_date) AS mes,
  SUM(fpa.visits) AS total_visitas
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date)
ORDER BY mes;
-- ¿Qué meses concentran más visitas?
SELECT
  MONTH(fpa.activity_date) AS mes,
  CASE
	WHEN MONTH(fpa.activity_date) = 1 THEN 'Enero'
    WHEN MONTH(fpa.activity_date) = 2 THEN 'Febrero'
    WHEN MONTH(fpa.activity_date) = 3 THEN 'Marzo'
    WHEN MONTH(fpa.activity_date) = 4 THEN 'Abril'
    WHEN MONTH(fpa.activity_date) = 5 THEN 'Mayo'
    WHEN MONTH(fpa.activity_date) = 6 THEN 'Junio'
    WHEN MONTH(fpa.activity_date) = 7 THEN 'Julio'
    WHEN MONTH(fpa.activity_date) = 8 THEN 'Agosto'
    WHEN MONTH(fpa.activity_date) = 9 THEN 'Septiembre'
    WHEN MONTH(fpa.activity_date) = 10 THEN 'Octubre'
    WHEN MONTH(fpa.activity_date) = 11 THEN 'Noviembre'
    WHEN MONTH(fpa.activity_date) = 12 THEN 'Diciembre'
    ELSE 'Fuera del rango'
  END AS nombre_mes,
  SUM(fpa.visits) AS total_visitas
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date),nombre_mes
ORDER BY total_visitas DESC;
-- ¿Qué meses generan más ingresos?
SELECT
  MONTH(fpa.activity_date) AS mes,
  CASE
	WHEN MONTH(fpa.activity_date) = 1 THEN 'Enero'
    WHEN MONTH(fpa.activity_date) = 2 THEN 'Febrero'
    WHEN MONTH(fpa.activity_date) = 3 THEN 'Marzo'
    WHEN MONTH(fpa.activity_date) = 4 THEN 'Abril'
    WHEN MONTH(fpa.activity_date) = 5 THEN 'Mayo'
    WHEN MONTH(fpa.activity_date) = 6 THEN 'Junio'
    WHEN MONTH(fpa.activity_date) = 7 THEN 'Julio'
    WHEN MONTH(fpa.activity_date) = 8 THEN 'Agosto'
    WHEN MONTH(fpa.activity_date) = 9 THEN 'Septiembre'
    WHEN MONTH(fpa.activity_date) = 10 THEN 'Octubre'
    WHEN MONTH(fpa.activity_date) = 11 THEN 'Noviembre'
    WHEN MONTH(fpa.activity_date) = 12 THEN 'Diciembre'
    ELSE 'Fuera del rango'
  END AS nombre_mes,
  SUM(fpa.revenue_eur) AS total_ingresos_mensuales
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date),nombre_mes
ORDER BY total_ingresos_mensuales DESC;

-- ¿Existen meses “débiles” en actividad o revenue?
SELECT
  MONTH(activity_date) AS mes,
  SUM(visits) AS total_visitas,
  SUM(revenue_eur) AS total_ingresos
FROM fact_poi_activity
GROUP BY MONTH(activity_date)
ORDER BY total_visitas ASC;

-- ¿Qué ciudades están por encima de la media de visitas por POI?
WITH visitas_por_ciudad AS (
  SELECT
    c.city_id,
    c.city_name,
    AVG(fpa.visits) AS visitas_media
  FROM fact_poi_activity fpa
  INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
  INNER JOIN dim_city c ON p.city_id = c.city_id
  GROUP BY c.city_id, c.city_name
),
media_global AS (
  SELECT AVG(visitas_media) AS media
  FROM visitas_por_ciudad
)
SELECT * FROM visitas_por_ciudad
WHERE visitas_media > (SELECT media FROM media_global)
ORDER BY visitas_media DESC;