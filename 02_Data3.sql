-- 02_Data3.sql
/*
En este archivo se generan datos artificiales en base a los originales para la tabla de hechos de la actividad de cada Poi.
Solamente genero 5000, ya que al no tener una datos de actividad reales, generar uno por cada Poi (más de 300k filas) se 
vuelve innecesario cuando con menos ya se puede simular un analisis con fechas y valores interesantes.
*/
USE `pois`;
-- Con esta query comienza la transacción
START TRANSACTION;

-- Limpieza previa de cualquier dato que haya en la tabla "fact_poi_activity"
DELETE FROM fact_poi_activity;

-- Inserción de hechos con fechas distribuidas a lo largo del año
INSERT INTO fact_poi_activity
(poi_id, activity_date, visits, revenue_eur, avg_rating)
SELECT
  poi_id,
  DATE_ADD(
    '2024-01-01',
    INTERVAL FLOOR(RAND() * 365) DAY
  ) AS activity_date,
  FLOOR(RAND() * 50),
  ROUND(RAND() * 500, 2),
  ROUND(2.5 + RAND() * 2.5, 2)
FROM dim_poi
LIMIT 5000;

-- Limpieza de valores no válidos por condición de visitas
UPDATE fact_poi_activity
SET avg_rating = NULL
WHERE visits = 0;

-- Aqui borramos cualquier hecho con 0 visitas ya que no seria relevante que sin visitas tuviera otros datos
DELETE FROM fact_poi_activity
WHERE visits = 0;

COMMIT;
