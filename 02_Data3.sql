-- 03_fact_simple.sql
USE `pois`;

START TRANSACTION;

DELETE FROM fact_poi_activity;

INSERT INTO fact_poi_activity
(poi_id, activity_date, visits, revenue_eur, avg_rating)
SELECT
  poi_id,
  '2025-01-01',
  FLOOR(RAND() * 50),
  ROUND(RAND() * 500, 2),
  ROUND(2.5 + RAND() * 2.5, 2)
FROM dim_poi
LIMIT 5000;

UPDATE fact_poi_activity
SET avg_rating = NULL
WHERE visits = 0;

DELETE FROM fact_poi_activity
WHERE visits = 0;

COMMIT;
