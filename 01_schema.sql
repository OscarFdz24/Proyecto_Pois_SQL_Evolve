-- 01_schema.sql
-- Ejecutar TODO de una vez (incluye tabla origen + modelo simple)

CREATE DATABASE IF NOT EXISTS `pois`;
USE `pois`;

DROP TABLE IF EXISTS `pois_22_12`;

CREATE TABLE `pois_22_12` (
  `id` BIGINT PRIMARY KEY,
  `name` TEXT,
  `country_latitude` DOUBLE,
  `country_longitude` DOUBLE,
  `city` TEXT,
  `city_latitude` DOUBLE,
  `city_longitude` DOUBLE,
  `poi` TEXT,
  `poi_latitude` DOUBLE,
  `poi_longitude` DOUBLE,
  `category` TEXT,
  `subcategory` TEXT,
  `value_en` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- Ajuste de columnas de texto para evitar Error 1406 (Data too long)
ALTER TABLE `pois_22_12`
  MODIFY `name` MEDIUMTEXT,
  MODIFY `city` MEDIUMTEXT,
  MODIFY `poi` MEDIUMTEXT,
  MODIFY `category` MEDIUMTEXT,
  MODIFY `subcategory` MEDIUMTEXT,
  MODIFY `value_en` MEDIUMTEXT;
DROP TABLE IF EXISTS `fact_poi_activity`;
DROP TABLE IF EXISTS `dim_poi`;
DROP TABLE IF EXISTS `dim_subcategory`;
DROP TABLE IF EXISTS `dim_category`;
DROP TABLE IF EXISTS `dim_city`;
DROP TABLE IF EXISTS `dim_country`;

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
