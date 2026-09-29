--------------------------------------------------------
-- PROYECTO CAPSTONE
-- Análisis Exploratorio de Datos (EDA) en PostgreSQL
-- estructura.sql — creación de la base y carga de datos
-- Alumno: Carlos Contreras
--------------------------------------------------------
-- Dataset propio de una tienda de e-commerce: clientes, productos y pedidos.
-- Se generó a mano en vez de usar un dataset externo para poder introducir
-- a propósito valores nulos en columnas críticas (precio_unitario, cantidad
-- y fecha_pedido) y así mostrar un proceso de limpieza real en analisis.sql,
-- en vez de trabajar sobre datos ya perfectos.
--------------------------------------------------------

CREATE DATABASE capstone_project;

-- Conectarse a la base de datos capstone_project antes de continuar.

--------------------------------------------------------
-- CREACIÓN DE TABLAS
--------------------------------------------------------

CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    ciudad VARCHAR(60) NOT NULL,
    fecha_alta DATE NOT NULL
);

CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    categoria VARCHAR(60) NOT NULL,
    precio NUMERIC(10,2) NOT NULL CHECK (precio > 0),
    stock INT NOT NULL CHECK (stock >= 0)
);

-- pedidos: un registro por línea de pedido (cliente + producto + cantidad).
-- precio_unitario y fecha_pedido se dejan sin NOT NULL a propósito: son las
-- columnas que en un sistema real suelen llegar incompletas desde el punto
-- de venta o la importación, y son justamente las que se limpian más
-- adelante en analisis.sql antes de analizar nada.
CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(cliente_id),
    producto_id INT NOT NULL REFERENCES productos(producto_id),
    cantidad INT CHECK (cantidad IS NULL OR cantidad > 0),
    precio_unitario NUMERIC(10,2) CHECK (precio_unitario IS NULL OR precio_unitario > 0),
    fecha_pedido DATE
);

--------------------------------------------------------
-- CARGA DE DATOS
--------------------------------------------------------

BEGIN;

--------------------------------------------------------
-- CLIENTES
--------------------------------------------------------

INSERT INTO clientes (nombre, email, ciudad, fecha_alta) VALUES
('Sofía Martínez',    'sofia.martinez@mail.com',    'Buenos Aires', '2026-01-15'),
('Tomás Rivero',       'tomas.rivero@mail.com',      'Córdoba',      '2026-01-22'),
('Valentina Acosta',   'valentina.acosta@mail.com',  'Rosario',      '2026-02-03'),
('Bruno Medina',       'bruno.medina@mail.com',      'Buenos Aires', '2026-02-10'),
('Agustina Torres',    'agustina.torres@mail.com',   'Mendoza',      '2026-02-18'),
('Ezequiel Paz',       'ezequiel.paz@mail.com',      'La Plata',     '2026-03-01'),
('Milagros Sosa',      'milagros.sosa@mail.com',     'Córdoba',      '2026-03-09'),
('Ignacio Vega',       'ignacio.vega@mail.com',      'Buenos Aires', '2026-03-20'),
('Catalina Núñez',     'catalina.nunez@mail.com',    'Rosario',      '2026-04-02'),
('Franco Aguirre',     'franco.aguirre@mail.com',    'Mendoza',      '2026-04-15'),
('Lucas Herrera',      'lucas.herrera@mail.com',     'La Plata',     '2026-04-20');

--------------------------------------------------------
-- PRODUCTOS
--------------------------------------------------------

INSERT INTO productos (nombre, categoria, precio, stock) VALUES
('Auriculares Bluetooth X200',    'Electrónica',   45000, 40),
('Smartwatch Fit 3',              'Electrónica',   89000, 25),
('Cafetera Express Compacta',     'Hogar',         62000, 15),
('Set de Sábanas Premium',        'Hogar',         31000, 30),
('Campera Rompeviento',           'Indumentaria',  28000, 50),
('Zapatillas Running Pro',        'Deportes',      75000, 20),
('Mochila Urbana 20L',            'Indumentaria',  34000, 35),
('Mancuernas Ajustables 10kg',    'Deportes',      41000, 18),
('Libro Clean Code',              'Libros',        19000, 60),
('Parlante Portátil Boom',        'Electrónica',   53000, 22);

--------------------------------------------------------
-- PEDIDOS
--------------------------------------------------------
-- cliente_id y producto_id referencian el orden de inserción de arriba
-- (1 a 10 en cada tabla). Algunas filas tienen cantidad, precio_unitario
-- o fecha_pedido en NULL a propósito, simulando datos que llegaron
-- incompletos desde el sistema de origen.

INSERT INTO pedidos (cliente_id, producto_id, cantidad, precio_unitario, fecha_pedido) VALUES
-- Junio 2026
(1,  1, 1, 45000, '2026-06-03'),
(2,  6, 1, 75000, '2026-06-04'),
(3,  9, 3, 19000, '2026-06-05'),
(4,  2, 1, 89000, '2026-06-08'),
(5,  5, 2, NULL,  '2026-06-10'),
(6,  7, 1, 34000, '2026-06-12'),
(7,  3, 1, 62000, '2026-06-15'),
(8, 10, 1, 53000, '2026-06-18'),
(1,  4, 2, 31000, '2026-06-20'),
(9,  8, 1, 41000, '2026-06-25'),
-- Julio 2026
(2,  1, 2, 45000, '2026-07-02'),
(3,  6, 1, 75000, '2026-07-04'),
(4,  9, NULL, 19000, '2026-07-06'),
(5,  2, 1, 89000, '2026-07-09'),
(6,  5, 3, 28000, '2026-07-11'),
(7,  7, 1, 34000, '2026-07-14'),
(8,  3, 1, 62000, '2026-07-16'),
(10, 10, 2, 53000, '2026-07-19'),
(1,  1, 1, 45000, '2026-07-22'),
(9,  4, 1, NULL,  '2026-07-25'),
-- Agosto 2026
(2,  6, 1, 75000, '2026-08-01'),
(3,  9, 2, 19000, '2026-08-03'),
(4,  2, 1, 89000, NULL),
(5,  5, 1, 28000, '2026-08-08'),
(6,  7, 2, 34000, '2026-08-10'),
(7,  1, 1, 45000, '2026-08-13'),
(8,  8, 1, 41000, '2026-08-16'),
(1, 10, 1, 53000, '2026-08-22'),
(9,  6, 1, 75000, '2026-08-27'),
-- Septiembre 2026
(2,  1, 1, 45000, '2026-09-02'),
(3,  2, 1, 89000, '2026-09-04'),
(4,  5, NULL, 28000, '2026-09-07'),
(5,  9, 4, 19000, '2026-09-09'),
(6,  7, 1, 34000, '2026-09-11'),
(7,  3, 1, 62000, '2026-09-14'),
(8, 10, 1, NULL,  '2026-09-17'),
(10, 1, 2, 45000, '2026-09-20'),
(1,  6, 1, 75000, NULL),
(9,  4, 1, 31000, '2026-09-24');

COMMIT;

--------------------------------------------------------
-- VERIFICACIÓN INICIAL
--------------------------------------------------------

SELECT * FROM clientes;
SELECT * FROM productos;
SELECT * FROM pedidos;
