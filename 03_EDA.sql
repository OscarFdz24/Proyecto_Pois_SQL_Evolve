/*
=====================================================
Proyecto SQL – POIs
Autor: Óscar Fernández-Chinchilla López
Archivo: 03_EDA.sql

Descripción:
Análisis exploratorio de datos (EDA) sobre los POIs.
Incluye KPIs, joins, CTEs, window functions, vistas y conclusiones de negocio.
=====================================================
*/

/*
-----------------------------------------------------
BLOQUE 0 — Contexto y Setup
Objetivo:
El objetivo general de este EDA es el análisis de los POIs cargados previamente
para identificar cuales son los más importantes, que zonas tienen más volumen
de estos mismos, POIs por ciudades o métricas de hechos y actividad.
-----------------------------------------------------
*/

-- Utilizamos la sentencia USE para utilizar la BDD correpondiente a los POIs
USE pois;


/*
-----------------------------------------------------
BLOQUE 1 — Volumen y calidad de datos
Objetivo:
El objetivo de este bloque es comprobar que los datos tienen sentido y que están 
lo suficientemente preparados como para realizar un análisis posterior con el 
menor número de incoherencias posibles. 
Al ser algunos datos artificiales, sería normal encontrar alguna serie de incoherencias (o no) 
al realizar el análisis.
-----------------------------------------------------
*/

-- ¿Cuantos Pois existen en la BDD?
SELECT COUNT(*) FROM pois_22_12;
-- Existen 311658 Pois en la BDD

-- ¿Cuántas categorías y subcategorías existen tras la limpieza?
SELECT COUNT(DISTINCT c.category_id) as num_categorias,  
	   COUNT(DISTINCT s.subcategory_id) as num_subcategorias 
FROM dim_category as c
INNER JOIN dim_subcategory as s ON c.category_id=s.category_id ;
-- Existen 10 categorias y 36 subcategorias

-- ¿Cuántos POIs tienen actividad registrada (FACT) frente al total de POIs?
SELECT COUNT(*) FROM fact_poi_activity;
-- 5000 POIs tienen actividad, es normal ya que se puso como limite 5000 en la creación de esta tabla artificial

-- ¿Cuántos POIs no tienen actividad registrada?
SELECT COUNT(*) AS  pois_sin_actividad FROM dim_poi dm
LEFT JOIN fact_poi_activity fpa ON dm.poi_id = fpa.poi_id
WHERE fpa.poi_id IS NULL;
-- Para este proyecto, hay 306564 pois sin actividad relacionada

-- ¿Hay POIs sin categoría o sin subcategoría?
SELECT * FROM pois_22_12
WHERE category IS NULL OR subcategory IS NULL;
-- Hay 4 POIs en total que no contienen categoria o subcategoria ya que estan practicamente vacios

-- Realizamos esta query pora consultar en la tabla de POIs normalizada "dim_poi" si se han normalizado todos y tienen una subcategoria asignada
SELECT COUNT(*) FROM dim_poi
WHERE subcategory_id IS NULL;
-- Los POIs sin subcategoría solo existen en el CSV, no en la tabla normalizada ya que da 0.

-- Existen valores nulos en métricas clave (visits, revenue, rating)?
SELECT COUNT(*) FROM fact_poi_activity
WHERE visits IS NULL OR revenue_eur IS NULL OR avg_rating IS NULL;
-- El resultado da 0, por lo que en esa tabla no hay ninguna con valores clave nulos

/*
-----------------------------------------------------
BLOQUE 2 — Limpieza previa al análisis
Objetivo:
En este bloque realizo un update para limpiar algunos datos de la tabla artificial
dim_city, ya que por alguna razón sale un valor como 'NULL'.
En el bloque 3, se podrá visualizar esta incoherencia aunque no se solucione el problema en este bloque.
-----------------------------------------------------
*/

-- Al visualizar la tabla de dim_city o alguno de sus campos, aparece un valor extraño como NULL.
-- Por lo que realizo para el nombre un set y le atribuyo el valor 'Unknown' para normalizarlo.
UPDATE dim_city
SET city_name = 'Unknown'
WHERE city_name IS NULL;

/*
-----------------------------------------------------
BLOQUE 3 — Análisis geográfico
Objetivo:
En este bloque el objetivo es analizar la distribución geográfica de los POIs del dataset, analizando
paises, ciudades, realizando rankings y a su vez utilizando funciones de agregación para obtener métricas 
y KPIs.
-----------------------------------------------------
*/

-- ¿Qué países concentran más POIs?
SELECT 	p.name,
		COUNT(dm.poi_id) as num_POIs,
		RANK() OVER (ORDER BY COUNT(dm.poi_id) DESC) AS ranking_pais
FROM dim_poi dm
INNER JOIN pois_22_12 p ON dm.poi_id=p.id
GROUP BY p.name
ORDER BY num_POIs DESC
LIMIT 10;
-- El resultado nos muestra los 10 paises con más POIs ordenados en un ranking

-- ¿Qué ciudades tienen mayor número de POIs?
SELECT 	c.city_name, 
		COUNT(*) AS num_pois,
		RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking_ciudades,
        CASE
			WHEN c.city_name IS NULL THEN 'No'
            ELSE 'Si'
		END AS Valor_normalizado
FROM dim_poi p
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY c.city_name
ORDER BY num_pois DESC
LIMIT 10;
-- En este caso ocurre algo extraño, aparece que hay una fila 'NULL' con 39K Pois, pero tras hacer varias comprobaciones no doy con la razón de porque aparecen.
-- En todo caso, abajo aparecen las ciudades ordenadas por el numero de POIs que tiene cada una y su ranking equivalente.

-- Realizo esta query para comprobar el resultado anterior
SELECT COUNT(*) FROM dim_city
WHERE city_name IS NULL;
-- En esta query nos dice que hay 0 ciudades con city_name nulo.

-- ¿Qué ciudades generan más visitas totales?
SELECT 	c.city_name AS ciudad,
		SUM(fpa.visits) AS total_visitas
FROM fact_poi_activity fpa
INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY p.city_id, c.city_name
ORDER BY total_visitas DESC
LIMIT 10;
-- Barcelona y Madrid son las ciudades que más visitas generan.

-- ¿Qué ciudades generan más ingresos totales?
SELECT
  c.city_name AS ciudad,
  SUM(fpa.revenue_eur) AS ingresos_totales
FROM fact_poi_activity fpa
INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
INNER JOIN dim_city c ON p.city_id = c.city_id
GROUP BY p.city_id, c.city_name
ORDER BY ingresos_totales DESC
LIMIT 10;
-- Madrid y Barcelona también son las ciudades que mas ingreso mensual generan

/*
-----------------------------------------------------
BLOQUE 4 — Categorías y tipologías
Objetivo:
En este bloque el objetivo es analizar las categorias y subcategorias, calculando
métricas clave con funciones de agregación para sacar insights de negocio y analisis 
de los POIs .
-----------------------------------------------------
*/

-- ¿Qué categorías tienen más POIs?
SELECT 	dc.category_name, 
		COUNT(dp.poi_id) as num_POIs,
        RANK () OVER(ORDER BY COUNT(dp.poi_id) DESC) as ranking_categorias
FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
GROUP BY dc.category_name
ORDER BY num_POIs DESC;
-- Las categorias que contienen más POIs son 'Religioso', 'Historico' y 'Cultural'

-- ¿Qué categorías concentran más visitas en total?
SELECT 	dc.category_name, 
		SUM(fpa.visits) as num_visitas,
        RANK () OVER(ORDER BY SUM(fpa.visits) DESC) as ranking_categorias
FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY num_visitas DESC;
-- Las categorias de 'Cultural', 'Monumento' y 'Religioso' son las que concentran más visitas en total

-- ¿Qué categorías generan más ingresos totales?
SELECT 	dc.category_name, 
		SUM(fpa.revenue_eur) as total_ingresos,
        RANK () OVER(ORDER BY SUM(fpa.revenue_eur) DESC) as ranking_categorias
FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY total_ingresos DESC;
-- Las categorias de 'Cultural', 'Religioso' y 'Monumento' son las que tienen mas ingresos totales

-- ¿Qué categorías tienen mejor valoración media?
SELECT 	dc.category_name, 
		ROUND(AVG(fpa.avg_rating),2) as valoracion_media,
        RANK () OVER(ORDER BY ROUND(AVG(fpa.avg_rating),2) DESC) as ranking_categorias
FROM dim_category dc
INNER JOIN dim_subcategory ds ON dc.category_id = ds.category_id
INNER JOIN dim_poi dp ON ds.subcategory_id = dp.subcategory_id
INNER JOIN fact_poi_activity fpa ON dp.poi_id = fpa.poi_id
GROUP BY dc.category_name
ORDER BY valoracion_media DESC;
-- Las categorias con mejor valoracion media son 'Puente', 'Administrativo' y 'Parque'

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
-- Existen solo 3 categorias con bajo rating pero muchas visitas

/*
-----------------------------------------------------
BLOQUE 5 — Análisis temporal
Objetivo:
El objetivo de este bloque es hallar la distribución de varias métricas realizando
un analisis temporal a lo largo del año de la tabla de hechos y actividades de los POIs.
Para las querys de este bloque no utilizaré rankings ni limits, ya que el número de registros
a obtener son un máximo de 12.
-----------------------------------------------------
*/

-- ¿Cómo se distribuye la actividad a lo largo del año?
SELECT
  MONTH(fpa.activity_date) AS mes,
  SUM(fpa.visits) AS total_visitas
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date)
ORDER BY mes;
-- Esta query nos da como resultado el total de visitas de cada mes

-- ¿Qué meses concentran más visitas?
SELECT 	MONTH(fpa.activity_date) AS mes,
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
		SUM(fpa.visits) AS total_visitas,
        CASE
			WHEN SUM(fpa.visits) >= 10000 THEN 'Elevado'
			WHEN SUM(fpa.visits) BETWEEN 9500 AND 9999 THEN 'Medio'
			WHEN SUM(fpa.visits) <= 9499 THEN 'Bajo'
			ELSE 'Fuera del rango'
		END AS nivel_de_visitas
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date),nombre_mes
ORDER BY total_visitas DESC;
-- Nos da como resultado los meses ordenados por el total de visitas de cada uno

-- ¿Qué meses generan más ingresos?
SELECT 	MONTH(fpa.activity_date) AS mes,
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
		SUM(fpa.revenue_eur) AS total_ingresos_mensuales,
        CASE
			WHEN SUM(fpa.revenue_eur) >= 100000 THEN 'Elevado'
			WHEN SUM(fpa.revenue_eur) BETWEEN 95000 AND 99999 THEN 'Medio'
			WHEN SUM(fpa.revenue_eur) <= 94999 THEN 'Bajo'
			ELSE 'Fuera del rango'
		END AS nivel_de_ingresos
FROM fact_poi_activity fpa
GROUP BY MONTH(fpa.activity_date),nombre_mes
ORDER BY total_ingresos_mensuales DESC;
-- La query anterior nos da como resultado todos los meses de año ordenados por el total de ingresos

-- ¿Existen meses “débiles” en actividad o revenue?
SELECT
  MONTH(activity_date) AS mes,
  SUM(visits) AS total_visitas,
  SUM(revenue_eur) AS total_ingresos
FROM fact_poi_activity
GROUP BY MONTH(activity_date)
ORDER BY total_visitas ASC;
-- Todos mantienen métricas y valores equilibrados entre si

/*
-----------------------------------------------------
BLOQUE 6 — Comparativas y “advanced analytics”
Objetivo:
El objetivo de este bloque es realizar compativas y análisis más avanzados
utilizando CTE's con subquerys, funciones de ventana y casteos para sacar algunos
de los insights más importantes del EDA.
-----------------------------------------------------
*/

-- ¿Qué ciudades están por encima de la media de visitas por POI?
WITH visitas_por_ciudad AS (
  SELECT
    c.city_id,
    c.city_name,
    ROUND(AVG(fpa.visits),2) AS visitas_media
  FROM fact_poi_activity fpa
  INNER JOIN dim_poi p ON fpa.poi_id = p.poi_id
  INNER JOIN dim_city c ON p.city_id = c.city_id
  GROUP BY c.city_id, c.city_name
),
media_global AS (
  SELECT AVG(visitas_media) AS media
  FROM visitas_por_ciudad
  -- La media es 24.45
)
SELECT * FROM visitas_por_ciudad
WHERE visitas_media > (SELECT media FROM media_global)
ORDER BY visitas_media DESC;
-- Anzuola es la ciudad con más media de visitas, seguida por Sacecorbo

-- Ranking de ciudades por visitas dentro de cada pais (solo España por el momento)
SELECT
  co.country_name,
  ci.city_name,
  SUM(fpa.visits) AS total_visits,
  RANK() OVER (
    PARTITION BY co.country_name
    ORDER BY SUM(fpa.visits) DESC
  ) AS rank_in_country
FROM fact_poi_activity fpa
INNER JOIN dim_poi p  ON fpa.poi_id = p.poi_id
INNER JOIN dim_city ci ON p.city_id = ci.city_id
INNER JOIN dim_country co ON ci.country_id = co.country_id
GROUP BY co.country_name, ci.city_name
ORDER BY co.country_name, rank_in_country;
-- El resultado solo abarca para España ya que los 5000 registros artificiales fueron unicamente para este mismo
-- De no ser así, tambien saldrian varios top 1,2,3 etc de varios paises.

-- Calcular el beneficio por visita de cada categoria
SELECT
  dc.category_name,
  SUM(fpa.revenue_eur) AS revenue,
  SUM(fpa.visits) AS visits,
  CAST(SUM(fpa.revenue_eur) / NULLIF(SUM(fpa.visits),0) AS DECIMAL(10,2)) AS revenue_per_visit
  -- En la sentencia anterior calculo la media de beneficio por visita para cada categoria
  -- El null if lo incluyo para que si el numero de visitas = 0, no de error por division zero
  -- Y finalmente casteo el resultado al tipo decimal con dos decimales
FROM fact_poi_activity fpa
JOIN dim_poi dp ON fpa.poi_id = dp.poi_id
JOIN dim_subcategory ds ON dp.subcategory_id = ds.subcategory_id
JOIN dim_category dc ON ds.category_id = dc.category_id
GROUP BY dc.category_name
ORDER BY revenue_per_visit DESC;

/*
-----------------------------------------------------
BLOQUE 7 — Funciones reutilizables
Objetivo:
El objetivo de este bloque es realizar una serie de funciones reutilizables.
-----------------------------------------------------
*/
DELIMITER $$

DROP FUNCTION IF EXISTS fn_num_pois_city $$
CREATE FUNCTION fn_num_pois_city(p_city_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE total_pois INT;

  SELECT COUNT(*)
    INTO total_pois
  FROM dim_poi dp
  WHERE dp.city_id = p_city_id;

  RETURN total_pois;
END $$

DELIMITER ;

-- Utilizamos la funcion para sacar el numero de POIs de cada ciudad
SELECT
  t.city_name,
  fn_num_pois_city(t.city_id) AS num_pois
FROM (
  SELECT
    dc.city_id,
    dc.city_name
  FROM dim_city dc
  JOIN dim_poi dp ON dp.city_id = dc.city_id
  GROUP BY dc.city_id, dc.city_name
  ORDER BY COUNT(*) DESC
  LIMIT 10
) AS t
ORDER BY num_pois DESC;

/* ------------------------------------- */

DELIMITER $$

DROP FUNCTION IF EXISTS fn_num_pois_country $$
CREATE FUNCTION fn_num_pois_country(p_country_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE total_pois INT;

  SELECT COUNT(*)
    INTO total_pois
  FROM dim_poi dp
  JOIN dim_city dc ON dp.city_id = dc.city_id
  WHERE dc.country_id = p_country_id;

  RETURN total_pois;
END $$

DELIMITER ;

-- Utilizamos la función anterior para sacar el numero de POIs de cada pais
SELECT
  c.country_name,
  fn_num_pois_country(c.country_id) AS num_pois
FROM dim_country c
WHERE c.country_id IN (
  SELECT dc.country_id
  FROM dim_city dc
  JOIN dim_poi dp ON dp.city_id = dc.city_id
  GROUP BY dc.country_id
)
ORDER BY num_pois DESC;

/*
-----------------------------------------------------
BLOQUE 8 — Views / Reporting final (resultado del proyecto)
Objetivo:
Crear vistas de resumen con KPIs agregados para facilitar análisis recurrentes y reporting, 
evitando repetir joins complejos y mejorando la reutilización de las consultas.
-----------------------------------------------------
*/
CREATE OR REPLACE VIEW vw_city_kpis AS
SELECT
  co.country_name,
  ci.city_name,
  COUNT(DISTINCT dp.poi_id) AS pois,
  SUM(fpa.visits) AS total_visits,
  SUM(fpa.revenue_eur) AS total_revenue,
  ROUND(AVG(fpa.avg_rating),2) AS avg_rating
FROM dim_city ci
JOIN dim_country co ON ci.country_id = co.country_id
JOIN dim_poi dp ON dp.city_id = ci.city_id
LEFT JOIN fact_poi_activity fpa ON fpa.poi_id = dp.poi_id
GROUP BY co.country_name, ci.city_name;

SELECT *
FROM vw_city_kpis
ORDER BY total_revenue DESC
LIMIT 20;

-- Vista de top categorias por ciudad
CREATE OR REPLACE VIEW vw_city_category_kpis AS
SELECT
  co.country_name,
  ci.city_name,
  dc.category_name,
  COUNT(DISTINCT dp.poi_id) AS pois,
  SUM(fpa.visits) AS total_visits,
  SUM(fpa.revenue_eur) AS total_revenue,
  ROUND(AVG(fpa.avg_rating),2) AS avg_rating
FROM dim_city ci
JOIN dim_country co ON ci.country_id = co.country_id
JOIN dim_poi dp ON dp.city_id = ci.city_id
JOIN dim_subcategory ds ON dp.subcategory_id = ds.subcategory_id
JOIN dim_category dc ON ds.category_id = dc.category_id
LEFT JOIN fact_poi_activity fpa ON fpa.poi_id = dp.poi_id
GROUP BY
  co.country_name,
  ci.city_name,
  dc.category_name;
  
SELECT *
FROM vw_city_category_kpis
ORDER BY total_revenue DESC
LIMIT 20;

/*
-----------------------------------------------------
CIERRE DEL EDA
Resumen:
El análisis exploratorio confirma la correcta normalización del modelo 
y la consistencia de los datos de actividad de POIs.

Alcance del análisis:
- Los KPIs de visitas e ingresos se basan en la tabla fact_poi_activity, 
que contiene actividad simulada para POIs ubicados en España.
- El análisis no pretende realizar comparativas internacionales de actividad,
ya que los datos son simulados a excepción de la BDD original.

Algunas decisiones de negocio realizadas en el EDA:
- Identificar ciudades y categorías con mayor generación de ingresos.
- Detectar meses con mayor o menor actividad para optimizar campañas o recursos.
- Priorizar categorías con alto revenue por visita.
- Identificar ciudades estratégicas para inversión o expansión.
- Apostar por categorias más rentables
- Ajustar recursos en picos de demanda temporal
-----------------------------------------------------
*/