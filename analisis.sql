--------------------------------------------------------
-- PROYECTO CAPSTONE
-- Análisis Exploratorio de Datos (EDA) en PostgreSQL
-- analisis.sql — limpieza de datos y consultas de análisis
-- Alumno: Carlos Contreras
--------------------------------------------------------
-- Este script asume que ya se corrió estructura.sql sobre la base
-- capstone_project. Primero se identifican y gestionan los nulos en las
-- columnas críticas de pedidos, y recién después se corre el análisis.
--------------------------------------------------------


--------------------------------------------------------
-- 1. LIMPIEZA DE DATOS
--------------------------------------------------------

-- 1.1 Diagnóstico: cuántos nulos hay por columna crítica antes de tocar nada.
-- Esto es lo primero que miraría antes de confiar en cualquier número que
-- salga de pedidos: si no sé cuánta info falta, no sé cuánto sesgo puedo
-- estar metiendo en el análisis.
SELECT
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS nulos_precio,
    COUNT(*) FILTER (WHERE cantidad IS NULL)        AS nulos_cantidad,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL)    AS nulos_fecha
FROM pedidos;

-- 1.2 precio_unitario: se puede inferir con confianza usando el precio
-- vigente del producto en el catálogo. No es perfecto (el precio pudo haber
-- cambiado desde la venta), pero es la mejor estimación disponible y muchísimo
-- mejor que dejar el pedido afuera del cálculo de ingresos.
UPDATE pedidos AS p
SET precio_unitario = COALESCE(p.precio_unitario, prod.precio)
FROM productos AS prod
WHERE p.producto_id = prod.producto_id
  AND p.precio_unitario IS NULL;

-- 1.3 cantidad: cuando no quedó registrada, se asume 1 unidad (el mínimo
-- posible para que exista el pedido), en vez de inventar un número mayor.
UPDATE pedidos
SET cantidad = COALESCE(cantidad, 1)
WHERE cantidad IS NULL;

-- 1.4 fecha_pedido: a diferencia del precio y la cantidad, una fecha no se
-- puede inferir sin arriesgarse a inventar información (no hay ningún otro
-- campo que indique cuándo se hizo el pedido). Por eso, en vez de forzar una
-- fecha con COALESCE, estas filas se identifican y se excluyen explícitamente
-- de los análisis que agrupan por fecha (por ejemplo, ventas por mes), pero
-- se mantienen en los análisis que no dependen de la fecha (top clientes,
-- productos menos vendidos), porque ahí sí aportan información válida.
SELECT pedido_id, cliente_id, producto_id, cantidad, precio_unitario
FROM pedidos
WHERE fecha_pedido IS NULL;
-- -> 2 pedidos sin fecha (id 23 y 39). Quedan marcados y se filtran con
--    "WHERE fecha_pedido IS NOT NULL" en la consulta de ventas por mes.

-- 1.5 Verificación de tipos: precio_unitario y precio son NUMERIC(10,2), y
-- fecha_pedido / fecha_alta son DATE (definido así desde estructura.sql), así
-- que no hace falta castear nada acá: los tipos ya son los correctos.


--------------------------------------------------------
-- 2. TOP 5 CLIENTES POR GASTO TOTAL
--------------------------------------------------------
-- Problema de negocio:
-- Identificar a los clientes que más facturación generan, para poder
-- priorizarlos en una futura campaña de fidelización.

SELECT
    c.cliente_id,
    c.nombre,
    c.ciudad,
    SUM(p.cantidad * p.precio_unitario) AS gasto_total
FROM pedidos AS p
INNER JOIN clientes AS c
    ON p.cliente_id = c.cliente_id
GROUP BY
    c.cliente_id,
    c.nombre,
    c.ciudad
ORDER BY gasto_total DESC
LIMIT 5;


--------------------------------------------------------
-- 3. VENTAS TOTALES POR MES
--------------------------------------------------------
-- Problema de negocio:
-- Ver la evolución mes a mes de la facturación, para detectar tendencias o
-- caídas que ameriten revisar qué pasó en un período puntual.
--
-- Se excluyen los pedidos sin fecha_pedido (ver punto 1.4): incluirlos acá
-- rompería la agrupación mensual.

SELECT
    DATE_TRUNC('month', fecha_pedido) AS mes,
    SUM(cantidad * precio_unitario) AS venta_total
FROM pedidos
WHERE fecha_pedido IS NOT NULL
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY mes;


--------------------------------------------------------
-- 4. LOS 3 PRODUCTOS MENOS VENDIDOS
--------------------------------------------------------
-- Problema de negocio:
-- Detectar productos con poca rotación: candidatos a sacar del catálogo,
-- poner en oferta, o dejar de reponer stock.

SELECT
    prod.producto_id,
    prod.nombre,
    prod.categoria,
    COALESCE(SUM(p.cantidad), 0) AS unidades_vendidas
FROM productos AS prod
LEFT JOIN pedidos AS p
    ON prod.producto_id = p.producto_id
GROUP BY
    prod.producto_id,
    prod.nombre,
    prod.categoria
ORDER BY unidades_vendidas ASC
LIMIT 3;


--------------------------------------------------------
-- 5. RANKING DE PRODUCTOS POR INGRESO DENTRO DE SU CATEGORÍA
--------------------------------------------------------
-- Problema de negocio:
-- Dentro de cada categoría, saber cuál es el producto que más ingresos
-- genera, para decidir a cuál priorizar en la vidriera de la categoría.
--
-- RANK() permite ver la posición de cada producto en su categoría; si dos
-- productos empatan en ingresos, comparten posición (a diferencia de
-- ROW_NUMBER(), que los desempataría de forma arbitraria).

WITH ingresos_por_producto AS (

    SELECT
        prod.producto_id,
        prod.nombre,
        prod.categoria,
        SUM(p.cantidad * p.precio_unitario) AS ingreso_total

    FROM productos AS prod

    INNER JOIN pedidos AS p
        ON prod.producto_id = p.producto_id

    GROUP BY
        prod.producto_id,
        prod.nombre,
        prod.categoria
)

SELECT
    categoria,
    nombre,
    ingreso_total,
    RANK() OVER (
        PARTITION BY categoria
        ORDER BY ingreso_total DESC
    ) AS posicion_en_categoria
FROM ingresos_por_producto
ORDER BY
    categoria,
    posicion_en_categoria;


--------------------------------------------------------
-- 6. SEGMENTACIÓN DE CLIENTES POR FRECUENCIA DE COMPRA
--------------------------------------------------------
-- Problema de negocio:
-- Separar clientes frecuentes de ocasionales para tratarlos distinto en
-- marketing (por ejemplo, a los frecuentes se les puede ofrecer un programa
-- de puntos, a los ocasionales una promo de reactivación).
--
-- El corte de 3 pedidos es arbitrario pero razonable para esta base: con
-- 4 meses de datos, 3 pedidos o más ya marca un cliente que vuelve seguido.

SELECT
    c.cliente_id,
    c.nombre,
    COUNT(p.pedido_id) AS cantidad_pedidos,
    CASE
        WHEN COUNT(p.pedido_id) >= 3 THEN 'Cliente frecuente'
        WHEN COUNT(p.pedido_id) BETWEEN 1 AND 2 THEN 'Cliente ocasional'
        ELSE 'Sin compras'
    END AS segmento
FROM clientes AS c
LEFT JOIN pedidos AS p
    ON c.cliente_id = p.cliente_id
GROUP BY
    c.cliente_id,
    c.nombre
ORDER BY cantidad_pedidos DESC;
