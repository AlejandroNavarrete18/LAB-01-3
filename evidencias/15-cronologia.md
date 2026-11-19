# Evidencia 15 — Cronología y respuestas a Dirección

**Estudiante:** [REEMPLAZA: tu nombre]
**Actividad:** 17

## Comando ejecutado

Consulta 1 (bitácora, eventos relevantes):

```sql
SELECT num, linea FROM dba.bitacora
WHERE linea ~ 'changed to|FATAL|ERROR|connection authorized|disconnection|statement: (REVOKE|GRANT|ALTER|CREATE|UPDATE|DELETE|INSERT)'
ORDER BY num;
```

Consulta 2 (tabla de auditoría):

```sql
SELECT id_evento, momento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues,
       valores_antes ->> 'telefono' AS tel_antes, valores_despues ->> 'telefono' AS tel_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
```

Consulta 3 (accesos fallidos):

```sql
SELECT num, linea FROM dba.bitacora
WHERE linea LIKE '%FATAL:%password authentication failed%'
ORDER BY num;
```

Consulta 4 (archivos de bitácora, incluidos los anteriores al reinicio):

```sql
SELECT f.name AS archivo, t.n AS num, t.linea
FROM pg_ls_logdir() f,
     LATERAL regexp_split_to_table(convert_from(pg_read_binary_file('log/' || f.name), 'LATIN1'), E'\n')
       WITH ORDINALITY AS t(linea, n)
WHERE t.linea ~ 'changed to|statement: ALTER SYSTEM'
ORDER BY f.modification, t.n;
```

## Resultado obtenido

**Nota sobre las fuentes.** `num` es el número de línea de la vista `dba.bitacora` (archivo de bitácora vigente, que inicia el 2026-11-18 a las 14:50:22 CST por el reinicio del equipo). En el archivo exportado `bitacora-lab01.log` el mismo evento se localiza por su fecha/hora y PID. Las horas están en CST (`log_timezone`). En varias líneas la aplicación aparece como `appventas-web` (sin guion) porque así quedó escrito `application_name` en mis comandos; es un valor que declara el cliente. La fila 1 proviene de un archivo anterior al reinicio (`postgresql-2026-11-17_000000.log`), consultado con `pg_ls_logdir()` y `pg_read_binary_file()`. Se decodificó como LATIN1 porque WIN1252 falló con el byte 0x81.

**Cronología:**

| # | Fecha y hora (CST) | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-17 19:00:17.627 | postgres | N/A | Configuración | ALTER SYSTEM SET log_connections = on (pgAdmin 4 - CONN:6989817, desde ::1) | Sí | postgresql-2026-11-17_000000.log, línea 40 |
| 2 | 2026-11-18 14:51:09.967 | app_ventas | N/A | Acceso | Intento de conexión desde 127.0.0.1 con contraseña incorrecta (se repite a las 14:51:09.994) | No | bitácora 17 y 20 |
| 3 | 2026-11-18 14:51:16.125 | usuario_inexistente | N/A | Acceso | Intento de conexión con un rol que no existe, desde 127.0.0.1 (se repite a las 14:51:16.153) | No | bitácora 23 y 27 |
| 4 | 2026-11-18 14:51:20.709 | app_ventas | N/A | Acceso | Conexión exitosa (app-ventas-web, 127.0.0.1); desconexión a las 14:51:20.752 (0.067 s) | Sí | bitácora 32 y 33 |
| 5 | 2026-11-18 15:06:15.141 | postgres | N/A | Privilegio | REVOKE UPDATE ON clientes FROM soporte_ana; a las 15:06:18 GRANT UPDATE ON clientes TO app_ventas | Sí | bitácora 40 y 41 |
| 6 | 2026-11-18 15:06:20.143 | postgres | N/A | Estructura | ALTER TABLE clientes ADD COLUMN segmento | Sí | bitácora 42 |
| 7 | 2026-11-18 15:15:33.195 | app_ventas | id 3 | Datos | UPDATE del teléfono a 6679990000 (appventas-web, 127.0.0.1) | Sí | bitácora 76 |
| 8 | 2026-11-18 15:18:14.683 | postgres | N/A | Configuración | ALTER SYSTEM SET log_statement = 'mod'; se repite a las 15:20:58.731 | Sí | bitácora 80 y 81 |
| 9 | 2026-11-18 15:30:41.805 | soporte_ana | id 5 | Error | DELETE rechazado: permission denied for table clientes | No | bitácora 125 y 126 |
| 10 | 2026-11-18 15:59:34.955 | app_ventas | id 3 | Datos | UPDATE del RFC a GAMA780912ZZZ; la auditoría conserva rfc_antes GAMA780912XYZ | Sí | bitácora 266; id_evento 1 |
| 11 | 2026-11-18 16:23:55.822 | postgres | id 6 | Datos | INSERT y DELETE de Pedro Ruiz | Sí | bitácora 333; id_evento 3 y 4 |
| 12 | 2026-11-18 16:34:43.595 | app_ventas | N/A | Estructura | Intento de DISABLE TRIGGER rechazado (must be owner of table clientes), tras un DELETE rechazado sobre auditoria.cambios_clientes | No | bitácora 372 a 376 |
| 13 | 2026-11-18 16:35:05.178 | postgres | N/A | Estructura | DISABLE TRIGGER trg_auditoria_clientes | Sí | bitácora 379 |
| 14 | 2026-11-18 16:35:07.084 | postgres | id 3 | Datos | UPDATE del RFC a GAMA780912GHI con el disparador desactivado; no generó evento de auditoría | Sí | bitácora 380 (sin id_evento) |
| 15 | 2026-11-18 16:35:09.103 | postgres | N/A | Estructura | ENABLE TRIGGER trg_auditoria_clientes | Sí | bitácora 381 |
| 16 | 2026-11-18 16:40:54.821 | postgres | ids 1 a 5 | Datos | UPDATE masivo (Actividad 15): 5 filas auditadas; se repite a las 16:42:21.160 | Sí | id_evento 7 a 11 y 12 a 16 |
| 17 | 2026-11-18 16:49:37.446 a 16:51:27.235 | postgres | N/A | Acceso | 18 intentos de conexión fallidos desde ::1 (contraseña incorrecta) | No | bitácora 424 a 478 |

**Resultado de la consulta 4:**

| archivo | num | linea |
|---|---|---|
| postgresql-2026-11-17_000000.log | 40 | 2026-11-17 19:00:17.627 CST [12140] user=postgres db=comercial app=pgAdmin 4 - CONN:6989817 client=::1 LOG:  statement: ALTER SYSTEM SET log_connections = on; |
| postgresql-2026-11-18_000000.log | 80 | 2026-11-18 15:18:14.683 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG:  statement: ALTER SYSTEM SET log_statement = 'mod'; |
| postgresql-2026-11-18_000000.log | 81 | 2026-11-18 15:20:58.731 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG:  statement: ALTER SYSTEM SET log_statement = 'mod'; |

La línea 497 del archivo del 18-nov corresponde al texto de una ejecución anterior de esta misma consulta, que falló por la codificación (WIN1252); no es un evento y se excluye de la cronología.

**Huecos (eventos sin registro; no tienen hora y no se estiman):**
- Cambio de RFC a `GAMA780912XXX` (Actividad 3): en ese momento no había bitácora ni auditoría.
- Sentencia que cambió el RFC a `GAMA780912XYZ` (Actividad 7): con `ddl` no se registran los UPDATE; solo quedó la conexión y desconexión de app_ventas.
- Valor anterior del teléfono antes del UPDATE de las 15:15:33: aún no existía el disparador.
- Actividad 4 (17-nov): del archivo anterior al reinicio solo se consultaron las líneas de configuración. Se conserva la sentencia `ALTER SYSTEM SET log_connections = on` (línea 40). La ejecución inicial de la Actividad 4, hecha cuando `log_statement` valía `none`, no quedó registrada, como anticipa la guía.

**Extracto de la tabla de auditoría (solo las filas necesarias):**

| id_evento | momento | usuario_sesion | aplicacion | ip_cliente | operacion | id_cliente | rfc_antes | rfc_despues |
|---|---|---|---|---|---|---|---|---|
| 1 | 2026-11-18 15:59:34.955456-06 | app_ventas | appventas-web | 127.0.0.1 | UPDATE | 3 | GAMA780912XYZ | GAMA780912ZZZ |
| 2 | 2026-11-18 16:13:22.109663-06 | app_ventas | app-ventas-web | 127.0.0.1 | UPDATE | 3 | GAMA780912ZZZ | GAMA780912ZZZ |
| 11 | 2026-11-18 16:40:54.821614-06 | postgres | pgAdmin 4 - CONN:5123666 | ::1 | UPDATE | 3 | GAMA780912GHI | GAMA780912GHI |

## Interpretación

**1. ¿Quién cambió el RFC?**
- **Actividad 3 (`XXX`): No hay evidencia.** En ese momento `log_connections`, `log_statement` y la auditoría no estaban configurados, así que nada quedó escrito.
- **Actividad 7 (`XYZ`): No hay evidencia de la sentencia.** Con `ddl` no se registran los UPDATE. Solo quedó la conexión de `app_ventas` desde 127.0.0.1 a las 15:13:30.122 y su desconexión (bitácora 61 y 62), que no prueba qué ejecutó. El valor `XYZ` solo se conoce por el `rfc_antes` del id_evento 1.
- **Actividad 12 (`ZZZ`):** `app_ventas`, desde 127.0.0.1, con aplicación declarada `appventas-web`, el 2026-11-18 a las 15:59:34.955 (bitácora 266, id_evento 1). La repetición de las 16:13:22 (bitácora 315, id_evento 2) no cambió el valor (`ZZZ` a `ZZZ`).
- **Actividad 14 (`GHI`):** `postgres`, desde `::1`, con aplicación `pgAdmin 4 - CONN:5123666`, a las 16:29:14.727 (bitácora 360) y de nuevo a las 16:35:07.084 (bitácora 380). Quedó en la bitácora, pero no en la auditoría.

**2. ¿Quién cambió el teléfono?** `app_ventas`, desde 127.0.0.1, con aplicación declarada `appventas-web`, el 2026-11-18 a las 15:15:33.195 (bitácora 76). Valor anterior: **No hay evidencia**, porque aún no existía el disparador y la bitácora no guarda valores anteriores.

**3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**
Sí.
- `app_ventas`: 6 intentos desde 127.0.0.1 (14:51:09.967, 14:51:09.994, 15:12:38.711, 15:12:38.738, 15:12:50.257 y 15:12:50.288; bitácora 17, 20, 48, 51, 54 y 57).
- `usuario_inexistente`: 2 intentos desde 127.0.0.1 (14:51:16.125 y 14:51:16.153; bitácora 23 y 27).
- `postgres`: 18 intentos desde `::1` entre las 16:49:37 y las 16:51:27 (bitácora 424 a 478). Corresponden a intentos propios con una contraseña que no recordaba y a la extensión SQLTools de VS Code, que tenía guardada la contraseña anterior. La bitácora solo prueba el rol declarado y la IP; no distingue quién estaba frente al equipo (la bitácora registra el rol, no la persona).
- En varios casos los intentos aparecen en pares separados por milisegundos, lo que indica un reintento automático del cliente.
- **No hay evidencia** de intentos anteriores a las 14:50:22, porque el archivo vigente inicia ahí y antes no se registraban conexiones.

**4. ¿Qué valor tenía el RFC antes de cada cambio?**
- Cambio de la Actividad 3 (`XXX`): **No hay evidencia.**
- Cambio de la Actividad 7 (`XYZ`): **No hay evidencia.**
- Cambio de la Actividad 12: `GAMA780912XYZ` (`valores_antes` del id_evento 1).
- Cambio de la Actividad 14 (`GHI`): **No hay evidencia directa**, porque el disparador estaba desactivado. El último valor auditado era `ZZZ` (id_evento 2), y el id_evento 11 (16:40:54) muestra `rfc_antes = GHI`. Esa diferencia revela que el valor cambió fuera de la auditoría.