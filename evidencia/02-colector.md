# Evidencia 02 — Colector de bitácora

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 2

## Comando ejecutado

Ver `sql/01-colector-y-vista.sql`. Resumen:

```sql
ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();
SELECT linea FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;
CREATE VIEW dba.bitacora AS ...;   -- definición completa en el .sql
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;
```

## Resultado obtenido

**pending_restart antes del reinicio:**
| name | setting | pending_restart |
| :--- | :--- | :--- |
| `logging_collector` | `on` | `false` |

**logging_collector y pg_current_logfile() después del reinicio:**

| name | setting | source |
| :--- | :--- | :--- |
| `logging_collector` | `on` | `configuration file` |
- **`pg_current_logfile`**: `log/postgresql-2026-11-17_000000.log`

**Contenido del archivo de bitácora y últimas 10 líneas de dba.bitacora:**

| num | linea |
| :--- | :--- |
| 35 | `2026-11-17 18:39:51 CST LOG: checkpoint complete: wrote 1 buffers (0.0%), wrote 0 SLRU buffers; 0 WAL file(s) added, 0 removed, 0 recycled; write=0.102 s, sync=0.003 s, total=0.123 s; sync files=1, longest=0.003 s, average=0.003 s; distance=4 kB, estimate=2770 kB; lsn=0/2E2CEA8, redo lsn=0/2E2CE50` |
| 34 | `2026-11-17 18:39:51 CST LOG: empezando checkpoint: time` |
| 33 | `2026-11-17 18:34:54 CST LOG: checkpoint complete: wrote 26 buffers (0.2%), wrote 1 SLRU buffers; 0 WAL file(s) added, 0 removed, 0 recycled; write=2.626 s, sync=0.045 s, total=2.685 s; sync files=23, longest=0.004 s, average=0.002 s; distance=99 kB, estimate=3077 kB; lsn=0/2E2BC20, redo lsn=0/2E2BBC8` |
| 32 | `2026-11-17 18:34:51 CST LOG: empezando checkpoint: time` |
| 31 | `2026-11-17 18:32:30 CST SENTENCIA: CREATE VIEW dba.bitacora AS` |
| 30 | `2026-11-17 18:32:30 CST ERROR: syntax error at end of input at character 28` |
| 29 | `SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';` |
| 28 | `2026-11-17 18:28:53 CST SENTENCIA: ALTER SYSTEM SET logging_collector = on;` |
| 27 | `2026-11-17 18:28:53 CST ERROR: ALTER SYSTEM cannot run inside a transaction block` |
| 26 | `2026-11-17 18:19:52 CST LOG: checkpoint complete: wrote 3 buffers (0.0%), wrote 0 SLRU buffers; 0 WAL file(s) added, 0 removed, 0 recycled; write=0.302 s, sync=0.009 s, total=0.846 s; sync files=2, longest=0.006 s, average=0.005 s; distance=19 kB, estimate=3408 kB; lsn=0/2E12CB0, redo lsn=0/2E12C58` |

## Interpretación

**1. ¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?**
El colector es un proceso del servidor que debe capturar stderr desde el arranque, por lo que solo puede activarse al iniciar el servicio. `log_statement` es un valor que cada sesión consulta al decidir si registra una sentencia, así que el servidor lo relee con `pg_reload_conf()` sin cortar sesiones.

**2. ¿Qué ventaja tiene leer la bitácora con SQL? ¿Qué riesgo introduce?**
Ventaja: no depende del sistema operativo, del contenedor ni de los permisos del usuario del servicio. El servidor lee su propio archivo y se puede filtrar con SQL o expresiones regulares, igual en cualquier plataforma. Riesgo: `pg_read_file` puede leer cualquier archivo que el proceso del servidor pueda leer, y la bitácora puede contener secretos y datos sensibles. Quien tenga acceso a la vista o a esa función queda expuesto a ese contenido.

**3. ¿Quién debería poder consultar `dba.bitacora`?**
Solo el administrador (superusuario) o el rol designado como custodio de la evidencia. El esquema `dba` no tiene acceso para PUBLIC, y no deben acceder `app_ventas` ni `soporte_ana`.