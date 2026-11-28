-- Consultas del tablero del CCO sobre gold (workgroup latam-bigdata, base de datos latam_bigdata).
-- Las tablas las registra el crawler de Glue al final del notebook 14.

-- K1 puntualidad de salida por hub y mes
SELECT year, month, origen,
       SUM(salidas_operadas)                                                         AS operadas,
       ROUND(CAST(SUM(salidas_puntuales) AS DOUBLE) / NULLIF(SUM(salidas_operadas), 0), 4) AS k1_puntualidad
FROM kpi_diario
WHERE origen IN ('SBGR', 'SBSP')
GROUP BY year, month, origen
ORDER BY year, month, origen;

-- K2 alertas emitidas por día en Guarulhos (último mes cargado)
SELECT fecha_local, k2_alertas_ambar, k2_alertas_rojas, salidas_programadas
FROM kpi_diario
WHERE origen = 'SBGR'
  AND year * 100 + month = (SELECT MAX(year * 100 + month) FROM kpi_diario)
ORDER BY fecha_local;

-- K3 índice de propagación: aeropuertos donde la red llega más atrasada a T-2 h
SELECT origen, ROUND(AVG(k3_indice_propagacion), 4) AS k3_promedio, SUM(salidas_programadas) AS salidas
FROM kpi_diario
GROUP BY origen
HAVING SUM(salidas_programadas) > 1000
ORDER BY k3_promedio DESC
LIMIT 15;

-- K4 calidad de la alerta por mes (valid se usó para elegir el umbral; test, 2025, es la evaluación sin sesgo)
SELECT anio_mes, particion, k4_precision_ambar, k4_recall_ambar, k4_precision_roja, k4_recall_roja, vuelos
FROM kpi_alerta_mensual
ORDER BY anio_mes;

-- Tasa de demora según la condición de vuelo del METAR a T-2 h
SELECT c.condicion_clima_key, c.descripcion, COUNT(*) AS salidas, ROUND(AVG(f.es_demora15), 4) AS tasa_demora15
FROM fact_vuelo f
JOIN dim_condicion_clima c ON f.condicion_clima_key = c.condicion_clima_key
WHERE f.cancelado = 0 AND f.es_demora15 IS NOT NULL
GROUP BY c.condicion_clima_key, c.descripcion, c.severidad
ORDER BY c.severidad;

-- Lista del día que recibe el jefe de turno (capa de velocidad, última corrida)
SELECT numero_vuelo, origen, destino, salida_prog_utc, nivel_alerta, prob_demora15, prob_demora60,
       o_categoria_vuelo, minutos_antes_de_salida
FROM alertas_tiempo_real
WHERE run = (SELECT MAX(run) FROM alertas_tiempo_real WHERE run NOT LIKE '%replay')
  AND nivel_alerta IN ('ambar', 'rojo')
ORDER BY salida_prog_utc;

-- Linaje: de una cifra del tablero a los vuelos que la forman (id_vuelo lleva hasta silver y el archivo de la ANAC)
SELECT f.id_vuelo, f.numero_vuelo, f.origen_key, f.destino_key, f.salida_prog_utc, f.demora_salida_min, f.nivel_alerta
FROM fact_vuelo f
WHERE f.fecha_key = 20250115 AND f.origen_key = 'SBGR'
ORDER BY f.salida_prog_utc
LIMIT 50;
