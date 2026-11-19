# Evidencia 07 — Modificaciones de datos: ddl frente a mod

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 7

## Comando ejecutado

Con `log_statement = 'ddl'`. Terminal:

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"
```

Administrador:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;
```

Cambio de nivel:

```sql
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();
```

Terminal (con `mod`):

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"
```

Administrador:

```sql
SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;
```

## Resultado obtenido

**Con ddl:**

| LINEA |
| :--- |
| `2026-11-18 15:15:33.229 CST [28868] user=app_ventas db=comercial app=appventas-web client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.061 user=app_ventas database=comercial host=127.0.0.1 port=49757` |
| `2026-11-18 15:15:33.195 CST [28868] user=app_ventas db=comercial app=appventas-web client=127.0.0.1 LOG:  statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3` |
| `2026-11-18 15:15:33.192 CST [28868] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercial application_name=appventas-web SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)` |
**Con mod:**

| linea |
| :--- |
| `ALTER SYSTEM SET log_statement = 'mod';` |
| `2026-11-18 15:15:33.195 CST [28868] user=app_ventas db=comercial app=appventas-web client=127.0.0.1 LOG: statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3` |
| `2026-11-18 15:18:14.683 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG: statement: ALTER SYSTEM SET log_statement = 'mod';` |
| `2026-11-18 15:20:58.731 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG: statement: ALTER SYSTEM SET log_statement = 'mod';` |

## Interpretación

Con `ddl` aparecen la conexión y la desconexión de `app_ventas`, pero no el UPDATE. Con `mod` aparecen quién, cuándo, desde dónde, con qué aplicación y qué sentencia. El SELECT que leyó el RFC no aparece (con `mod` las lecturas no se registran), y la bitácora no muestra el valor anterior del teléfono.

**1. ¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?**
`log_statement = 'all'`. En un servidor con miles de consultas por minuto, la bitácora crecería enormemente: más almacenamiento, más escritura en disco, más dificultad para encontrar eventos relevantes y mucho más riesgo de registrar datos sensibles.

**2. ¿Qué le falta a esta bitácora para revertir el cambio con certeza?**
El valor anterior del dato. Solo registra la sentencia nueva (`telefono = '6679990000'`), no el teléfono que tenía el registro antes del cambio. Esto se resuelve en la Parte B.