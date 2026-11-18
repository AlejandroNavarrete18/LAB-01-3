# Evidencia 06 — Privilegios y estructura

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 6

## Comando ejecutado

Ver `sql/03-privilegios-estructura.sql`:

```sql
REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
DROP ROLE rol_temporal;
SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;
```

## Resultado obtenido

| LINEA |
| :--- |
| `2026-11-18 15:06:15.141 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| `2026-11-18 15:06:18.204 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: GRANT UPDATE ON clientes TO app_ventas;` |
| `2026-11-18 15:06:20.143 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);` |
| `2026-11-18 15:06:28.960 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';` |
| `2026-11-18 15:06:40.363 CST [34320] user=postgres db=comercial app=pgAdmin 4 - CONN:8090263 client=::1 LOG:  statement: DROP ROLE rol_temporal;` |
| `2026-11-18 15:15:12.129 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG:  statement: ` |
| `2026-11-18 15:15:33.195 CST [28868] user=app_ventas db=comercial app=appventas-web client=127.0.0.1 LOG:  statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3` |
| `2026-11-18 15:18:14.683 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG:  statement: ALTER SYSTEM SET log_statement = 'mod';` |
| `2026-11-18 15:20:58.731 CST [35204] user=postgres db=comercial app=pgAdmin 4 - CONN:7734158 client=::1 LOG:  statement: ALTER SYSTEM SET log_statement = 'mod';` |
| `2026-11-18 15:24:00.479 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| `2026-11-18 15:24:03.578 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;` |
| `2026-11-18 15:24:06.465 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: GRANT UPDATE ON clientes TO app_ventas;` |
| `2026-11-18 15:24:07.680 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);` |
| `2026-11-18 15:24:12.586 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';` |
| `2026-11-18 15:24:13.744 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 LOG:  statement: DROP ROLE rol_temporal;` |

## Interpretación

La bitácora muestra quién (user=postgres), cuándo, desde dónde (client=[local]) y qué sentencia se ejecutó en cada cambio. La contraseña de `rol_temporal` quedó en texto claro en la bitácora y eliminar el rol no la borra. `\password` calcula el resumen SCRAM en el cliente y envía al servidor solo ese resumen.

**1. ¿Qué tipo de evento es cada una de las tres primeras sentencias?**
- `REVOKE UPDATE ON clientes FROM soporte_ana`: privilegio.
- `GRANT UPDATE ON clientes TO app_ventas`: privilegio.
- `ALTER TABLE clientes ADD COLUMN segmento ...`: estructura.

**2. ¿Por qué GRANT y REVOKE quedan registrados con `log_statement = 'ddl'`?**
Porque el nivel `ddl` registra las sentencias de definición de datos (CREATE, ALTER, DROP) y también GRANT, REVOKE y COMMENT.

**3. Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relación con la gestión de secretos de la Unidad II.**
Solo el administrador o el custodio designado de la evidencia. Si la bitácora contiene secretos, hay que tratarla como un secreto más: acceso restringido, no subirla a repositorios sin revisarla y retirar las contraseñas antes de exportarla. Por eso en la Unidad II las contraseñas no se escriben en sentencias, sino que se usan `\password`, un gestor de secretos o `.pgpass`.