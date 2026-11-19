# Evidencia 11 — Incidente auditado

**Estudiante:** Luis Alejandro Navarrete Diaz

**Actividad:** 11 (preguntas) y 12

## Comando ejecutado

Actividad 11 (ver `sql/05-funcion-disparador.sql`):

```sql
SELECT tgname, tgenabled, tgrelid::regclass FROM pg_trigger WHERE NOT tgisinternal;
SELECT num, linea FROM dba.bitacora WHERE linea ~ 'statement: (CREATE|REVOKE)' ORDER BY num;
```

Actividad 12. Terminal:

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial" -c "SELECT * FROM auditoria.cambios_clientes"
```

Administrador (ver `sql/06-campos-modificados.sql`):

```sql
\x
SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;
\x

SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
 d.key AS campo,
 a.valores_antes ->> d.key AS antes,
 d.value #>> '{}' AS despues
FROM auditoria.cambios_clientes a CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE' AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;
```

## Resultado obtenido

**Disparador habilitado (pg_trigger):**

| tgname | tgenabled | tgrelid |
| :--- | :--- | :--- |
| `trg_auditoria_clientes` | `O` | `clientes` |

**Líneas de bitácora de la creación del esquema, tabla, función y disparador:**

| num | linea |
| :--- | :--- |
| 40 | `2026-11-18 15:06:15.141 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| 43 | `2026-11-18 15:06:28.960 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';` |
| 86 | `2026-11-18 15:24:00.479 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| 93 | `2026-11-18 15:24:03.578 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| 98 | `2026-11-18 15:24:12.586 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';` |
| 145 | `2026-11-18 15:44:29.335 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: CREATE SCHEMA auditoria;` |
| 146 | `2026-11-18 15:44:30.936 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;` |
| 147 | `2026-11-18 15:44:32.945 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: CREATE TABLE auditoria.cambios_clientes ( id_evento BIGSERIAL PRIMARY KEY,` |
| 163 | `2026-11-18 15:47:48.923 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: CREATE SCHEMA auditoria;` |
| 166 | `2026-11-18 15:47:51.433 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;` |
| 197 | `2026-11-18 15:49:29.882 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: CREATE SCHEMA auditoria;` |
| 200 | `2026-11-18 15:49:36.643 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;` |
| 201 | `2026-11-18 15:49:40.691 CST [9312] user=postgres db=comercial app=pgAdmin 4 - CONN:792644 client=::1 LOG:  statement: CREATE TABLE auditoria.cambios_clientes ( id_evento BIGSERIAL PRIMARY KEY,` |
| 253 | `2026-11-18 15:55:15.707 CST [34280] user=postgres db=comercial app=pgAdmin 4 - CONN:5137444 client=::1 LOG:  statement: REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;` |
| 277 | `2026-11-18 16:11:18.201 CST [34280] user=postgres db=comercial app=pgAdmin 4 - CONN:5137444 client=::1 LOG:  statement: CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()` |
| 300 | `2026-11-18 16:11:20.801 CST [34280] user=postgres db=comercial app=pgAdmin 4 - CONN:5137444 client=::1 LOG:  statement: REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;` |
| 301 | `2026-11-18 16:11:23.025 CST [34280] user=postgres db=comercial app=pgAdmin 4 - CONN:5137444 client=::1 LOG:  statement: CREATE TRIGGER trg_auditoria_clientes` |   

**Salida de los dos psql de app_ventas (UPDATE y SELECT sobre auditoría):**

```powershell
PS C:\Users\alexd> psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
UPDATE 1

PS C:\Users\alexd> psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercial" -c "SELECT * FROM auditoria.cambios_clientes"
ERROR:  permission denied for schema auditoria
LÍNEA 1: SELECT * FROM auditoria.cambios_clientes

```

**Registro de auditoría (vista vertical):**

| id_evento | momento | usuario_sesion | usuario_efectivo | aplicacion | ip_cliente | operacion | id_cliente |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `2026-11-18 15:59:34.955456-06` | `app_ventas` | `postgres` | `appventas-web` | `127.0.0.1` | `UPDATE` | 3 |
| 2 | `2026-11-18 16:13:22.109663-06` | `app_ventas` | `postgres` | `app-ventas-web` | `127.0.0.1` | `UPDATE` | 3 |

**Campo modificado (consulta con jsonb_each):**

| id_evento | momento | usuario_sesion | ip_cliente | campo | antes | despues |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `2026-11-18 15:59:34.955456-06` | `app_ventas` | `127.0.0.1` | `rfc` | `GAMA780912XYZ` | `GAMA780912ZZZ` |

## Interpretación

### Preguntas de la Actividad 11

**1. ¿Por qué `REVOKE ALL ON FUNCTION ... FROM PUBLIC` si el disparador seguirá funcionando para `app_ventas`?**
Porque por defecto PUBLIC recibe EXECUTE sobre las funciones nuevas, y se revoca por mínimo privilegio para que ningún rol pueda invocar la función directamente. El disparador sigue funcionando porque PostgreSQL no verifica EXECUTE al usuario que dispara la operación (solo a quien crea el disparador), y además la función corre con los privilegios de su propietario.

**2. ¿Qué pasaría si la función no fuera SECURITY DEFINER? (hipótesis)**
La función se ejecutaría con los privilegios de `app_ventas`, que no tiene acceso al esquema `auditoria` ni INSERT sobre su tabla. El INSERT de auditoría fallaría con `permission denied` y, como el disparador forma parte de la operación, el UPDATE de la aplicación también fallaría.

**3. ¿Quedó registrada en `dba.bitacora` la creación del esquema, la tabla, la función y el disparador? ¿Por qué?**
Sí. En la bitácora aparecen `CREATE SCHEMA auditoria` (num 145), `CREATE TABLE auditoria.cambios_clientes` (num 147), `CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()` (num 277) y `CREATE TRIGGER trg_auditoria_clientes` (num 301), junto con los `REVOKE ALL` sobre el esquema y la función. Quedaron registradas porque `log_statement` valía `mod`, nivel que incluye todo lo de `ddl` (CREATE, ALTER, DROP, GRANT, REVOKE).

### Preguntas de la Actividad 12

**1. Compara tu hipótesis de la Actividad 11 con este resultado.**
Con SECURITY DEFINER el UPDATE de `app_ventas` funcionó (`UPDATE 1`) y se escribió la auditoría aunque `app_ventas` no puede leer ni escribir en el esquema `auditoria` (`permission denied for schema auditoria` al intentar el SELECT). Esto confirma la hipótesis: la escritura se hace con los privilegios del propietario. `usuario_efectivo` es `postgres` y `usuario_sesion` es `app_ventas`.

**2. Sentencia UPDATE que restauraría el valor anterior:**

```sql
UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
```

**3. ¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?**
`ip_cliente` conserva más valor, porque la obtiene el servidor de la conexión misma. `aplicacion` (`application_name`) la declara el propio cliente, así que es la más fácil de falsificar; sirve para distinguir aplicaciones legítimas, pero no es evidencia fuerte de identidad.