# Evidencia 13 — Manipulación de la auditoría

**Estudiante:** Luis Alejandro Navarrete Diaz

**Actividad:** 14

## Comando ejecutado

Terminal (cuenta de la aplicación):

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes"
```

Administrador:

```sql
ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
SELECT count(*) FROM auditoria.cambios_clientes;

SELECT linea FROM dba.bitacora
WHERE linea ~ 'statement: (ALTER TABLE clientes (DIS|EN)ABLE|UPDATE clientes SET rfc = .GAMA780912GHI)'
ORDER BY num;
```

## Resultado obtenido

**Errores de app_ventas:**

```powershell
PS C:\Users\alexd> psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercial?application_name=appventas-web" -c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE
>> TRIGGER trg_auditoria_clientes"
ERROR:  permission denied for schema auditoria
LÍNEA 1: DELETE FROM auditoria.cambios_clientes
                     ^
ERROR:  must be owner of table clientes
```
**Conteo de la tabla de auditoría tras el cambio con el disparador desactivado:**

| count |
| :--- |
| 4 |

**Líneas de la bitácora:**

| num | linea |
| :--- | :--- |
| 375 | `2026-11-18 16:34:43.595 CST [31180] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` |
| 379 | `2026-11-18 16:35:05.178 CST [24228] user=postgres db=comercial app=pgAdmin 4 - CONN:5123666 client=::1 LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;` |
| 380 | `2026-11-18 16:35:07.084 CST [24228] user=postgres db=comercial app=pgAdmin 4 - CONN:5123666 client=::1 LOG:  statement: UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;` |
| 381 | `2026-11-18 16:35:09.103 CST [24228] user=postgres db=comercial app=pgAdmin 4 - CONN:5123666 client=::1 LOG:  statement: ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;` |

[REEMPLAZA: pega tu resultado]

## Interpretación

La primera línea de la bitácora es el intento de `app_ventas`: con `ddl` (incluido en `mod`), la sentencia se registra antes de ejecutarse, aunque después falle. La tabla de auditoría detalla el dato (antes y después), pero la puede desactivar el propietario de la tabla. La bitácora registra que el mecanismo se desactivó, pero la puede alterar quien controle el servidor. Ningún mecanismo dentro del propio servidor protege contra un administrador con control total.

**1. ¿Qué evidencia permite detectar que hubo un cambio sin auditar?**
La bitácora: las líneas `DISABLE TRIGGER` y `ENABLE TRIGGER` de `postgres`, y el `UPDATE ... rfc = 'GAMA780912GHI'` que aparece en la bitácora sin un evento correspondiente en `auditoria.cambios_clientes` (el conteo no aumentó).

**2. ¿Qué control administrativo (no técnico) reduciría este riesgo?**
Enviar las bitácoras a un sistema externo administrado por un área distinta a la que opera la base, con revisión periódica independiente que compare bitácora y auditoría, y un procedimiento de cambios que exija autorización previa para desactivar mecanismos de auditoría.

**3. Relación con el principio de separación de funciones de la Unidad II.**
Quien opera la base de datos no debe ser quien custodia la evidencia de lo que opera. `app_ventas` no pudo borrar la auditoría ni desactivar el disparador (no es propietaria), pero `postgres` sí. Si la misma persona puede hacer cambios y borrar o desactivar su registro, el control pierde valor, por lo que la custodia de la evidencia debe estar en otra función.