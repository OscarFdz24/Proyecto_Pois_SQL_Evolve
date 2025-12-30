-- 01_schema.sql
/*
En este archivo se crearán tanto el Schema de la base de datos donde se importarán los datos de un csv con datos reales
sobre puntos de interes turisticos (Pois) con la finalidad de realizar un EDA finalizar para comprender u analizar los datos.
Este archivo se puede ejecutar de una sola vez
*/
CREATE DATABASE IF NOT EXISTS `pois`;
USE `pois`;

DROP TABLE IF EXISTS `pois_22_12`;

CREATE TABLE `pois_22_12` (
  `id` BIGINT PRIMARY KEY,
  `name` MEDIUMTEXT,
  `country_latitude` DOUBLE,
  `country_longitude` DOUBLE,
  `city` MEDIUMTEXT,
  `city_latitude` DOUBLE,
  `city_longitude` DOUBLE,
  `poi` MEDIUMTEXT,
  `poi_latitude` DOUBLE,
  `poi_longitude` DOUBLE,
  `category` MEDIUMTEXT,
  `subcategory` MEDIUMTEXT,
  `value_en` MEDIUMTEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  
-- Realizamos un drop de todas las tablas con la condición "IF EXISTS" para que las elimine si esta misma se cumple
-- Los realizo todos seguidos y en orden para que no haya problemas de eliminación en cascada por Foreign Keys
DROP TABLE IF EXISTS `fact_poi_activity`;
DROP TABLE IF EXISTS `dim_poi`;
DROP TABLE IF EXISTS `dim_subcategory`;
DROP TABLE IF EXISTS `dim_category`;
DROP TABLE IF EXISTS `dim_city`;
DROP TABLE IF EXISTS `dim_country`;

-- Posteriormente creamos todas las tablas con sus valores y constraints necesarios.
CREATE TABLE `dim_country` (
  `country_id` INT PRIMARY KEY AUTO_INCREMENT,
  `country_name` VARCHAR(100) NOT NULL UNIQUE,
  `country_latitude` DOUBLE,
  `country_longitude` DOUBLE
) ENGINE=InnoDB;

CREATE TABLE `dim_city` (
  `city_id` INT PRIMARY KEY AUTO_INCREMENT,
  `country_id` INT NOT NULL,
  `city_name` VARCHAR(150) NOT NULL,
  `city_latitude` DOUBLE,
  `city_longitude` DOUBLE,
  UNIQUE (`country_id`, `city_name`),
  FOREIGN KEY (`country_id`) REFERENCES `dim_country` (`country_id`)
) ENGINE=InnoDB;

CREATE TABLE `dim_category` (
  `category_id` INT PRIMARY KEY AUTO_INCREMENT,
  `category_name` VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE `dim_subcategory` (
  `subcategory_id` INT PRIMARY KEY AUTO_INCREMENT,
  `category_id` INT NOT NULL,
  `subcategory_name` VARCHAR(120) NOT NULL,
  UNIQUE (`category_id`, `subcategory_name`),
  FOREIGN KEY (`category_id`) REFERENCES `dim_category` (`category_id`)
) ENGINE=InnoDB;

CREATE TABLE `dim_poi` (
  `poi_id` BIGINT PRIMARY KEY,
  `city_id` INT NOT NULL,
  `subcategory_id` INT NOT NULL,
  `poi_name` VARCHAR(255) NOT NULL,
  `poi_latitude` DOUBLE,
  `poi_longitude` DOUBLE,
  `value_en` VARCHAR(120),
  FOREIGN KEY (`city_id`) REFERENCES `dim_city` (`city_id`),
  FOREIGN KEY (`subcategory_id`) REFERENCES `dim_subcategory` (`subcategory_id`)
) ENGINE=InnoDB;

CREATE TABLE `fact_poi_activity` (
  `activity_id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `poi_id` BIGINT NOT NULL,
  `activity_date` DATE NOT NULL,
  `visits` INT NOT NULL,
  `revenue_eur` DECIMAL(10,2) NOT NULL,
  `avg_rating` DECIMAL(3,2),
  FOREIGN KEY (`poi_id`) REFERENCES `dim_poi` (`poi_id`)
) ENGINE=InnoDB;
