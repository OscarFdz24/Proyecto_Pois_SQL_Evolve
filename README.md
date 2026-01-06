# **Proyecto SQL - Análisis de POIs**
## **Autor:** Óscar Fernández-Chinchilla López
## **Máster:** Data: Science e IA Generativa - Evolve Academy

## Objetivo:
Diseñar e implementar una base de datos relacional para analizar POIs (Points of Interest), aplicando normalización, integridad de datos y análisis exploratorio en SQL con el objetivo de obtener insights de negocio relevantes.

## Modelo de datos
El proyecto utiliza un **modelo tipo estrella**, compuesto por:
- **Tabla de hechos:** fact_poi_activity (visitas, ingresos, rating)
- **Dimensiones:** países, ciudades, POIs, categorías y subcategorías
- **Staging:** pois_22_12 (CSV original usado solo como fuente de datos)
El identificador original del CSV se reutiliza en dim_poi para mantener trazabilidad sin acoplar el modelo analítico a la tabla de staging.

## Alcance del análisis
La actividad registrada en fact_poi_activity corresponde únicamente a POIs ubicados en España y está limitada manualmente a 5000.
Los KPIs de visitas e ingresos se interpretan dentro de este contexto.
No se realizan comparativas internacionales de actividad debido a las dos observaciones anteriores.

## Análisis realizado (EDA)
El EDA incluye:
- Validación de calidad y normalización del dato
- Análisis geográfico por países y ciudades
- Rankings con funciones de ventana
- Análisis por categorías y subcategorías
- Análisis temporal mensual
- CTEs, subqueries y lógica condicional
- KPIs como revenue por visita

## Reporting
Se crean vistas de resumen para facilitar el análisis recurrente:
- KPIs por ciudad
- KPIs por ciudad y categoría
También se implementan funciones reutilizables para el cálculo de métricas agregadas.

## Decisiones de negocio
El analisis permite:
- Priorizar ciudades y categorías más rentables
- Detectar estacionalidad en visitas e ingresos
- Identificar categorías con alto volumen y baja valoración
- Facilitar la toma de decisiones basada en KPIs consolidados

## Observaciones realizadas durante el proceso
Por alguna razón, al realizar querys sobre la tabla de dimensiones 'dim_city', aparece el campo 'city_name' para algunos casos como NULL.
Tras notar esta incoherencia y realizar comprobaciones varias como calcular que registros tienen el nombre de la ciudad como NULO, ya que de tipo
Null o un caracter de texto NULL, en todas las comprobaciones siempre ha resultado ser 0, por lo que tras realizar el EDA por completo, se sigue sin saber
la causa de este error o incoherencia.

## Observaciones y aclaraciones sobre la estructura el proyecto
- 01_schema.sql (archivo donde se crean la estructura de la BDD y las tablas artificiales)
- 02_data1.sql (archivo donde con transacciones se insertan en la tabla `pois_22_12` todos los datos del csv original para que sea un solo ejecutable)
- 02_data2.sql (archivo donde se pueblan las tablas artificiales en base a la creada anteriormente)
- 02_data3.sql (archivo de creación de hechos de actividad artificiales solamente para España)
- 03_EDA.sql (archivo de análisis EDA)
- EER_Pois_imagen.png 
- MER_POI.mwb
- README.md

En mi caso, utilizo 3 archivos de inserción de datos para mantener una organización más limpia, ya que al tener un volumen de datos bastante cosiderable en el csv
original (+ 300k registros), utilizar un solo archivo sql habría sido muy poco legible y pesado para visualizar en Github.
Para este proyecto he decidido tener todos los insert manuales del csv en un solo archivo dedicado a ellos mismo, para cumplir con el requisito de únicamente tener
archivos que funcionen con una sola ejecución en orden, y que a su vez, vea todo lo posible que hemos aprendido en el módulo de SQL (insert, SELECT, etc).
Una forma más óptima en entorno real, sería realizar un Import Data Wizard para ahorrar el archivo de importación grande, solamente aclarar que se hace de esta
manera aposta para utilizar lo visto en el módulo del máster.
