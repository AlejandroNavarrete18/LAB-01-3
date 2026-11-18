--6.3 Identificar la instalación desde el motor
SELECT version();
SHOW data_directory;
SHOW config_file;
SHOW hba_file;
--6.4 Revisar las reglas de autenticación
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE database = '{all}';
--6.5 Preparar los datos y los roles
CREATE TABLE clientes ( id BIGSERIAL PRIMARY KEY, nombre VARCHAR(120) NOT NULL,
 correo VARCHAR(150) NOT NULL,
 telefono VARCHAR(20),
 rfc VARCHAR(13),
 edad INTEGER,
 ciudad VARCHAR(80),
 codigo_postal VARCHAR(10),
 fecha_alta DATE DEFAULT CURRENT_DATE);

 INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal) VALUES
('Ana López', 'ana.lopez@example.test', '6671234567', 'LOAA850315ABC', 41, 'Culiacán', '80000'),
('Carlos Pérez', 'carlos.perez@example.test', '6672345678', 'PECA900720DEF', 35, 'Culiacán',
'80100'),
('María García', 'maria.garcia@example.test', '6673456789', 'GAMA780912GHI', 47, 'Mazatlán',
'82000'),
('Luis Torres', 'luis.torres@example.test', '6674567890', 'TOLU920201JKL', 34, 'Los Mochis', '81200'),
('Laura Sánchez', 'laura.sanchez@example.test', '6675678901', 'SALA880525MNO', 38, 'Culiacán',
'80200');
--Crea los roles sin escribir la contraseña en la sentencia:
CREATE ROLE app_ventas LOGIN;
CREATE ROLE soporte_ana LOGIN;

--\password app_ventas
--\password soporte_ana

--Usa Ventas_Practica_2026 y Soporte_Practica_2026, respectivamente. Otorga los privilegios del escenario:
GRANT SELECT, UPDATE ON clientes TO app_ventas;
GRANT SELECT ON clientes TO soporte_ana;

--PARTE A — Bitácora del servidor
--7. Actividad 1 — Revisar la configuración de registro por defecto
SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
 'log_connections', 'log_disconnections', 'log_line_prefix',
 'log_statement', 'log_min_error_statement', 'log_timezone') ORDER BY name;