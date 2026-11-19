# Evidencia 09 — Sesiones activas con pg_stat_activity

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 9

## Comando ejecutado

Segunda terminal:

```bash
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial?application_name=reporte-mensual" -c "SELECT pg_sleep(90)"
```

Administrador (mientras corre el reporte):

```sql
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
```

Búsqueda del PID en la bitácora (sustituir por el PID real):

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[189]%' ORDER BY num;
```

Después de que termina el reporte, repetir la consulta a `pg_stat_activity`.

## Resultado obtenido

**pg_stat_activity durante el reporte:**

| pid | usename | application_name | client_addr | backend_start | state | query |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2920 | `postgres` | `pgAdmin 4 - CONN:6841707` | `::1` | `2026-11-18 15:28:55.074781-06` | `idle` | `SELECT linea FROM dba.bitacora` |
| 10128 | `postgres` | `pgAdmin 4 - CONN:6841707` | `::1` | `2026-11-18 15:23:17.888939-06` | `active` | `SELECT pid, usename, applicati` |
| 35204 | `postgres` | `pgAdmin 4 - CONN:7734158` | `::1` | `2026-11-18 15:14:23.873272-06` | `idle` | `SELECT oid, pg_catalog.format_` |
| 14740 | `postgres` | `pgAdmin 4 - CONN:4331168` | `::1` | `2026-11-18 14:51:52.603774-06` | `idle` | `SELECT oid, pg_catalog.format_` |
| 10548 | `postgres` | `pgAdmin 4 - CONN:533153` | `::1` | `2026-11-18 14:50:25.195541-06` | `idle` | |
| 13900 | `postgres` | `pgAdmin 4 - CONN:533153` | `::1` | `2026-11-18 14:50:24.850419-06` | `idle` | `SELECT ro` |
| 34400 | `postgres` | `pgAdmin 4 - CONN:5574195` | `::1` | `2026-11-18 14:50:24.73366-06` | `idle` | `SELECT ro` |
| 24632 | `postgres` | `pgAdmin 4 - DB:comercial` | `::1` | `2026-11-18 14:50:22.282334-06` | `idle` | `SELECT COUNT(*) F` |
| 12220 | `postgres` | `pgAdmin 4 - DB:postgres` | `::1` | `2026-11-18 14:50:22.14228-06` | `idle` | `SELECT db.oid as did, db.` |
| 18404 | `soporte_ana` | `reporte-mensual` | `127.0.0.1` | `2026-11-18 15:35:02.482079-06` | `active` | `SELECT pg_sleep(90)` |

**Líneas de bitácora del PID de la sesión de soporte_ana:**

| linea |
| :--- |
| `2026-11-18 15:35:02.487 CST [18404] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=51534` |
| `2026-11-18 15:35:02.507 CST [18404] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="soporte_ana" method=scram-sha-256 (C:/Program Files/PostgreSQL/18/data/pg_hba.conf:115)` |
| `2026-11-18 15:35:02.507 CST [18404] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)` |
| `2026-11-18 15:36:32.552 CST [18404] user=soporte_ana db=comercial app=reporte-mensual client=127.0.0.1 LOG:  disconnection: session time: 0:01:30.069 user=soporte_ana database=comercial host=127.0.0.1 port=51534` |

**pg_stat_activity después de que terminó el reporte:**

| pid | usename | application_name | client_addr | backend_start | state | query |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2920 | `postgres` | `pgAdmin 4 - CONN:6841707` | `::1` | `2026-11-18 15:28:55.074781-06` | `idle` | `SELECT linea FROM dba.bitacora` |
| 10128 | `postgres` | `pgAdmin 4 - CONN:6841707` | `::1` | `2026-11-18 15:23:17.888939-06` | `active` | `SELECT pid, usename, applicati` |
| 35204 | `postgres` | `pgAdmin 4 - CONN:7734158` | `::1` | `2026-11-18 15:14:23.873272-06` | `idle` | `SELECT oid, pg_catalog.format_` |
| 14740 | `postgres` | `pgAdmin 4 - CONN:4331168` | `::1` | `2026-11-18 14:51:52.603774-06` | `idle` | `SELECT oid, pg_catalog.format_` |
| 10548 | `postgres` | `pgAdmin 4 - CONN:533153` | `::1` | `2026-11-18 14:50:25.195541-06` | `idle` | |
| 13900 | `postgres` | `pgAdmin 4 - CONN:533153` | `::1` | `2026-11-18 14:50:24.850419-06` | `idle` | `SELECT ro` |
| 34400 | `postgres` | `pgAdmin 4 - CONN:5574195` | `::1` | `2026-11-18 14:50:24.73366-06` | `idle` | `SELECT ro` |
| 24632 | `postgres` | `pgAdmin 4 - DB:comercial` | `::1` | `2026-11-18 14:50:22.282334-06` | `idle` | `SELECT COUNT(*) F` |
| 12220 | `postgres` | `pgAdmin 4 - DB:postgres` | `::1` | `2026-11-18 14:50:22.14228-06` | `idle` | `SELECT db.oid as did, db.` |

## Interpretación

`pg_stat_activity` es una fotografía de lo que ocurre en este momento: mientras el reporte corre aparece la sesión, y al terminar desaparece. La bitácora es la historia: conserva la sesión después de que termina.

**1. ¿Qué columna permite relacionar una sesión con sus líneas de bitácora?** `pid`, que corresponde al `[PID]` (`%p`) del prefijo de cada línea de la bitácora.

**2. Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?** La bitácora (con `log_connections` y `log_disconnections`). `pg_stat_activity` ya no la muestra.

**3. ¿Por qué `client_addr` aparece vacío en la sesión del administrador?** En mi servidor (Windows) no apareció vacío: mi sesión de administrador se conectó por TCP desde ::1. En la guía aparece vacío porque allí el administrador se conecta por socket Unix local, y en ese tipo de conexión no hay dirección IP de cliente.