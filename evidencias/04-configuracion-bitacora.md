# Evidencia 04 — Configuración de la bitácora

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 4

## Comando ejecutado

Ver `sql/02-configuracion-bitacora.sql`:

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;
```

## Resultado obtenido

**pg_settings (en una consulta posterior a la recarga):**

| name | setting | source | sourcefile |
| :--- | :--- | :--- | :--- |
| `log_connections` | `on` | `configuration file` | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |
| `log_line_prefix` | `%m [%p] user=%u db=%d app=%a client=%h ` | `configuration file` | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |
| `log_statement` | `ddl` | `configuration file` | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |



## Interpretación

Los valores provienen de `postgresql.auto.conf` (source = configuration file). Las sentencias `ALTER SYSTEM` no aparecen porque `log_statement` todavía valía `none` cuando se ejecutaron. Sí aparece el cambio de configuración (`parameter ... changed to ...`), y mi propia sesión de administrador ya queda registrada.

**1. ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?**
Mi sesión solo escribió el valor en `postgresql.auto.conf` y envió la señal de recarga. Quien relee la configuración y aplica los valores es el proceso principal del servidor (PID 1 en la guía), y por eso es el que escribe el mensaje.

**2. ¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?**
Sí. Mientras `log_statement` valga `ddl` o `mod`, el propio `ALTER SYSTEM` queda registrado como sentencia (con usuario, IP y aplicación), y al recargar el proceso principal registra `parameter "log_statement" changed to "none"`. Después de eso dejarían de registrarse sentencias, pero el cambio ya quedó asentado.

**3. ¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?**
Porque lo administra PostgreSQL: `ALTER SYSTEM` valida el parámetro y reescribe el archivo, y una edición manual puede dejar valores o formato inválidos que compliquen la recarga o el arranque. Una edición manual tampoco queda registrada como sentencia en la bitácora.