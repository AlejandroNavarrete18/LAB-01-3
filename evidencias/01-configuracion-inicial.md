# Evidencia 01 — Configuración inicial de registro

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 1 

## Comando ejecutado

Identificación de la instalación (6.3):

```sql
SELECT version();
SHOW data_directory;
SHOW config_file;
SHOW hba_file;
```

Reglas de autenticación (6.4):

```sql
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE database = '{all}';
```

Configuración de registro (Actividad 1):

```sql
SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
 'log_connections', 'log_disconnections', 'log_line_prefix',
 'log_statement', 'log_min_error_statement', 'log_timezone') ORDER BY name;
```

## Resultado obtenido

**6.3 version, data_directory, config_file, hba_file:**

- **`version`**: `PostgreSQL 18.0 on x86_64-windows, compiled by msvc-19.44.35217, 64-bit`
- **`data_directory`**: `C:/Program Files/PostgreSQL/18/data`
- **`config_file`**: `C:/Program Files/PostgreSQL/18/data/postgresql.conf`
- **`hba_file`**: `C:/Program Files/PostgreSQL/18/data/pg_hba.conf`

**6.4 pg_hba_file_rules (antes y después del ajuste de trust a scram-sha-256):**

| line_number | type | database | user_name | address | auth_method |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 113 | `local` | `{all}` | `{all}` | | `scram-sha-256` |
| 115 | `host` | `{all}` | `{all}` | `127.0.0.1` | `scram-sha-256` |
| 117 | `host` | `{all}` | `{all}` | `::1` | `scram-sha-256` |

**Actividad 1 (pg_settings con su source):**

| name | setting | source |
| :--- | :--- | :--- |
| `log_connections` | | `default` |
| `log_destination` | `stderr` | `configuration file` |
| `log_directory` | `log` | `default` |
| `log_disconnections` | `off` | `default` |
| `log_filename` | `postgresql-%Y-%m-%d_%H%M%S.log` | `default` |
| `log_line_prefix` | `%t ` | `configuration file` |
| `log_min_error_statement` | `error` | `default` |
| `log_statement` | `none` | `default` |
| `log_timezone` | `America/Chihuahua` | `configuration file` |
| `logging_collector` | `on` | `configuration file` |

## Interpretación

**Pregunta de 6.4. ¿Por qué una regla `trust` afecta lo que la bitácora puede demostrar sobre la identidad del usuario?**
Con `trust` el servidor acepta cualquier conexión sin verificar contraseña. La bitácora solo registra el nombre de usuario que el cliente declara, así que cualquiera podría declararse `app_ventas` y la línea no probaría que fue la aplicación. Además, nunca se verían accesos fallidos.

**1. ¿Se registra quién se conecta?** No. `log_connections = off`.

**2. ¿Se registran los UPDATE?** No. `log_statement = none`.

**3. ¿La línea incluye usuario o IP del cliente?** No. El prefijo por defecto `%m [%p]` solo tiene fecha/hora y PID.

**4. ¿Zona horaria y por qué importa?** `log_timezone` = America/Chihuahua/configuration file. Importa porque para reconstruir una cronología hay que comparar la bitácora con otras fuentes (tabla de auditoría, reportes, otros sistemas). Si no se sabe en qué zona está cada marca de tiempo, los eventos se desfasan y el orden de los hechos puede quedar mal.

**5. Con `logging_collector = off`, ¿quién decide dónde termina la bitácora?** El mecanismo con que se desplegó el servidor (script de arranque, servicio de Homebrew, contenedor), no PostgreSQL. PostgreSQL solo escribe en stderr.
En mi servidor logging_collector ya estaba en on, así que el destino lo decide PostgreSQL (log_directory).