USE `pois`;

START TRANSACTION;

-- Limpieza previa
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

-- Limpieza de valores no válidos
UPDATE fact_poi_activity
SET avg_rating = NULL
WHERE visits = 0;

DELETE FROM fact_poi_activity
WHERE visits = 0;

COMMIT;
