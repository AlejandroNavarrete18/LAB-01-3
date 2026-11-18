# Evidencia 08 — Errores y operaciones rechazadas

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 8

## Comando ejecutado

Terminal:

```bash
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "DELETE FROM clientes WHERE id = 5"
```

Administrador:

```sql
DROP ROLE soporte_ana;

SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|STATEMENT|DETAIL): (permission|privileges|role|DELETE|DROP)'
ORDER BY num;
```



## Resultado obtenido

| linea |
| :--- |
| `2026-11-18 15:27:43.832 CST [20868] user=soporte_ana db=comercial app=psql client=127.0.0.1 ERROR:  permission denied for table clientes` |
| `2026-11-18 15:27:43.832 CST [20868] user=soporte_ana db=comercial app=psql client=127.0.0.1 STATEMENT:  DELETE FROM` |
| `2026-11-18 15:27:56.849 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it` |
| `2026-11-18 15:27:56.849 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 DETAIL:  privileges for table clientes` |
| `2026-11-18 15:27:56.849 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 STATEMENT:  DROP ROLE soporte_ana;` |
| `2026-11-18 15:29:25.110 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it` |
| `2026-11-18 15:29:25.110 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 DETAIL:  privileges for table clientes` |
| `2026-11-18 15:29:25.110 CST [10128] user=postgres db=comercial app=pgAdmin 4 - CONN:6841707 client=::1 STATEMENT:  DROP ROLE soporte_ana;` |
| `2026-11-18 15:30:41.805 CST [20500] user=soporte_ana db=comercial app=psql client=127.0.0.1 ERROR:  permission denied for table clientes` |
| `2026-11-18 15:30:41.805 CST [20500] user=soporte_ana db=comercial app=psql client=127.0.0.1 STATEMENT:  DELETE FROM clientes WHERE id = 5` |

## Interpretación

Las sentencias que provocan errores se registran gracias a `log_min_error_statement = error`, independientemente de `log_statement`.

**1. ¿El intento de `soporte_ana` causó algún daño? ¿Por qué debe auditarse de todos modos?**
No causó daño porque el DELETE fue rechazado. Debe auditarse porque es un intento de una operación no autorizada que puede indicar un error de la aplicación, un abuso, una cuenta comprometida o privilegios mal asignados. Si se repite, forma un patrón que revela intención.

**2. ¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?**
La autenticación responde "¿quién eres?" y falla antes de crear la sesión (FATAL: contraseña incorrecta o rol inexistente). La autorización responde "¿qué puedes hacer?": la identidad ya fue validada, la sesión existe y el motor rechaza la operación (ERROR: permission denied), registrando además la sentencia.

**3. ¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?**
Que primero hay que retirar los privilegios que el rol tiene sobre los objetos (y reasignar o eliminar los objetos que posea) y solo después eliminar el rol.