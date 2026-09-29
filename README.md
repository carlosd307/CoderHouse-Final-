# Proyecto Capstone — Análisis Exploratorio de Datos (EDA) en PostgreSQL

Alumno: Carlos Contreras

## Problema de negocio

Trabajo con los datos de una tienda de e-commerce (clientes, productos y pedidos) que lleva cuatro meses de operación (junio a septiembre de 2026). El objetivo es responder preguntas que le importan al negocio, no solo mostrar que las consultas corren:

- ¿Quiénes son los clientes que más facturación generan, para priorizarlos en una campaña de fidelización?
- ¿Cómo evolucionó la facturación mes a mes, y hay algún mes que valga la pena revisar?
- ¿Qué productos tienen poca rotación y son candidatos a sacar del catálogo o poner en oferta?
- Dentro de cada categoría, ¿qué producto es el que más ingresos genera?
- ¿Qué clientes están registrados pero nunca compraron, o compran muy poco?

## Estructura del repositorio

- `estructura.sql`: crea la base `capstone_project`, las tablas `clientes`, `productos` y `pedidos`, y carga los datos de ejemplo.
- `analisis.sql`: limpieza de datos y las consultas de análisis, todas comentadas.
- `README.md`: este archivo.

## Cómo ejecutar

1. Abrir pgAdmin 4 o DBeaver y conectarse al servidor de PostgreSQL.
2. Ejecutar `estructura.sql` completo. La primera línea crea la base `capstone_project`; hay que conectarse a esa base antes de correr el resto del script (crear tablas y cargar datos).
3. Sobre la misma conexión a `capstone_project`, ejecutar `analisis.sql`.

## Sobre el dataset

Es un dataset propio, generado a mano en vez de descargado, para poder incluir a propósito algunos valores nulos en columnas críticas de `pedidos` (`precio_unitario`, `cantidad`, `fecha_pedido`) y así mostrar un proceso de limpieza real, en vez de trabajar sobre datos ya perfectos. `pedidos` tiene un registro por línea de pedido (un cliente compra un producto en una fecha, con una cantidad y un precio).

## Limpieza de datos

Antes de analizar nada, `analisis.sql` hace un diagnóstico de nulos en `pedidos` (encontró 3 en `precio_unitario`, 2 en `cantidad` y 2 en `fecha_pedido`) y los gestiona de forma distinta según qué tan seguro es inferirlos:

- **precio_unitario**: se completa con `COALESCE` usando el precio vigente del producto en el catálogo. No es perfecto si el precio cambió desde la venta, pero es la mejor estimación disponible.
- **cantidad**: se completa con `COALESCE` asumiendo 1 unidad, el mínimo posible para que el pedido exista.
- **fecha_pedido**: acá decidí *no* forzar una fecha con `COALESCE`, porque no hay ningún otro dato que permita inferir cuándo se hizo el pedido, y poner una fecha inventada podría distorsionar el análisis mensual. En cambio, esos 2 pedidos se identifican explícitamente y se excluyen solo de la consulta de ventas por mes; se mantienen en las consultas que no dependen de la fecha (top clientes, productos menos vendidos), porque ahí sí aportan información real.

Los tipos de datos ya quedaron bien definidos desde `estructura.sql` (`DATE` para fechas, `NUMERIC(10,2)` para montos), así que no hizo falta castear nada en el análisis.

## Hallazgos principales

**Top 5 clientes por gasto total**: Tomás Rivero lidera con $285.000, muy cerca de Sofía Martínez con $280.000 — entre los dos representan una porción grande de la facturación total, y son los primeros candidatos para un programa de fidelización. El resto del top 5 (Valentina Acosta, Agustina Torres y Bruno Medina) está bastante parejo, entre $225.000 y $259.000.

**Ventas por mes**: la facturación subió de $574.000 en junio a un pico de $635.000 en julio, pero cayó fuerte en agosto a $423.000 (el mes más bajo del período) antes de recuperarse parcialmente a $508.000 en septiembre. Esa caída de agosto es la señal más clara del análisis: vale la pena revisar qué pasó ese mes puntual (¿menos tráfico?, ¿algún problema operativo?) antes de asumir que es solo estacionalidad.

**Productos menos vendidos**: Mancuernas Ajustables 10kg (2 unidades), Cafetera Express Compacta (3 unidades) y Set de Sábanas Premium (4 unidades) son los de menor rotación. Los tres son productos de ticket alto y compra poco frecuente, así que antes de sacarlos del catálogo tendría sentido probarlos en alguna promoción puntual en vez de asumir directamente que no interesan.

**Ranking por categoría**: en Electrónica la pelea está muy reñida entre Auriculares Bluetooth X200 ($360.000) y Smartwatch Fit 3 ($356.000), casi empatados — cualquier acción de marketing puede inclinar la balanza. En cambio, en Deportes hay un líder claro y sin discusión: Zapatillas Running Pro ($375.000) le saca una diferencia enorme a Mancuernas Ajustables ($82.000).

**Segmentación de clientes**: 9 de los 11 clientes registrados son "frecuentes" (4 pedidos o más en los 4 meses), Franco Aguirre quedó como "ocasional" con solo 2 pedidos, y Lucas Herrera está registrado pero nunca compró. Este último es el caso más accionable: es un cliente que ya dio sus datos pero no convirtió, un candidato directo para una campaña de bienvenida o un primer descuento.

## Conclusión

El negocio tiene una base de clientes bastante fiel (la mayoría compra seguido), pero con una caída puntual en agosto que merece revisarse antes de sacar conclusiones apresuradas sobre el resto del año. Los productos de ticket alto y baja rotación (mancuernas, cafetera, sábanas) son los primeros candidatos para una promoción, y hay al menos un cliente registrado sin ninguna compra que representa una oportunidad de conversión directa.
