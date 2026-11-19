# Informe — LAB-01 Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** Luis Alejandro Navarrete Diaz

## 1. Despliegue y situación inicial

El servidor es una instalación nativa en Windows (instalador de EDB) con PostgreSQL 18.0. La sesión de administrador se abrió desde pgAdmin 4 como `postgres` sobre la base `comercial`, y las sesiones de `app_ventas` y `soporte_ana` con `psql` desde PowerShell hacia 127.0.0.1.

Diferencias con la guía, que cambian cómo se ve la evidencia:
- La versión es 18 y no 16.
- El administrador se conecta por TCP (`client=::1`), no por socket local (`client=[local]`).
- Las sentencias del administrador salen con `app=pgAdmin 4 - CONN:...`, no con `app=psql`.
- Las horas de la bitácora están en CST (UTC-6).


Configuración por defecto: `logging_collector` = on (configuration file), `log_connections` = vacío, equivalente a desactivado (default), `log_disconnections` = off (default), `log_statement` = none (default) y `log_line_prefix` = `%t ` (configuration file). Con esa configuración no se registraban las conexiones ni las sentencias, y las líneas solo incluían la fecha y hora, sin usuario, base de datos, aplicación ni IP, de modo que no era posible responder a Dirección quién cambió el RFC, cuándo, desde dónde, si hubo accesos fallidos ni qué valor tenía antes (Actividad 3: el cambio a `GAMA780912XXX` no dejó ningún rastro). Las reglas `host` de 127.0.0.1 y ::1 en `pg_hba.conf` ya exigían contraseña (`scram-sha-256`), por lo que no fue necesario modificarlas.      

## 2. Configuración aplicada

| Parámetro | Valor | Requirió | Justificación |
|---|---|---|---|
| logging_collector | on | Reinicio | El servidor administra su propia bitácora en archivos, igual en cualquier despliegue|
| log_connections | on | Recarga | Registrar accesos exitosos y fallidos |
| log_disconnections | on | Recarga | Registrar el fin y la duración de cada sesión |
| log_line_prefix | `%m [%p] user=%u db=%d app=%a client=%h ` | Recarga | Atribuir cada línea a un usuario, una base de datos, una aplicación y una IP |
| log_statement | ddl, y después mod | Recarga | `ddl` registra privilegios y estructura; `mod` agrega INSERT, UPDATE y DELETE |
| lc_messages | C | Recarga |  Mensajes en inglés para que los filtros de la guía coincidan |

Notas:
- `log_connections` se aplicó con `on`. En PostgreSQL 18 este parámetro admite una lista de valores, y una consulta hecha desde una sesión abierta antes de la recarga todavía mostraba el valor anterior; se verificó desde una sesión nueva.
- La vista `dba.bitacora` se recreó leyendo el archivo como bytes y convirtiéndolo con `convert_from(pg_read_binary_file(...), 'WIN1252')`, porque `pg_read_file` falló con "secuencia de bytes no válida para codificación UTF8". Para los archivos anteriores al reinicio se usó `LATIN1`, porque `WIN1252` falló con el byte `0x81`.

## 3. Eventos observados

Un ejemplo interpretado de cada tipo (horas en CST; `num` es la línea de `dba.bitacora`):

- **Acceso.** Línea 17, 2026-11-18 14:51:09.967 [15568]: `user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL: password authentication failed for user "app_ventas"`. Prueba que alguien, desde 127.0.0.1 y en ese momento, intentó autenticarse como `app_ventas` con una contraseña incorrecta. No prueba que fuera la aplicación de ventas, porque el nombre de usuario lo declara el cliente. El `app=[unknown]` se debe a que `application_name` se asigna después de autenticarse.
- **Privilegio.** Líneas 40 y 41, 2026-11-18 15:06:15 y 15:06:18: `user=postgres ... statement: REVOKE UPDATE ON clientes FROM soporte_ana;` y `GRANT UPDATE ON clientes TO app_ventas;`. Muestran quién cambió los privilegios, cuándo y desde dónde (pgAdmin 4, `client=::1`).
- **Estructura.** Línea 42, 2026-11-18 15:06:20.143: `statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);` por `postgres`.
- **Datos.** Línea 266, 2026-11-18 15:59:34.955 [22056]: `user=app_ventas app=appventas-web client=127.0.0.1 statement: UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3`. La tabla de auditoría lo complementa con el valor anterior: id_evento 1, `GAMA780912XYZ` → `GAMA780912ZZZ`, usuario de sesión `app_ventas`, IP 127.0.0.1.
- **Error.** Líneas 125 y 126, 2026-11-18 15:30:41.805 [20500]: `user=soporte_ana app=psql client=127.0.0.1 statement: DELETE FROM clientes WHERE id = 5` seguida de `ERROR: permission denied for table clientes`. Es un error de autorización (la identidad ya estaba autenticada); no hubo daño, pero es un intento de operación no permitida y por eso se audita.
- **Configuración.** Línea 80, 2026-11-18 15:18:14.683: `user=postgres ... statement: ALTER SYSTEM SET log_statement = 'mod';`. También quedó registrado, en el archivo anterior al reinicio (`postgresql-2026-11-17_000000.log`, línea 40), `ALTER SYSTEM SET log_connections = on;` a las 19:00:17.627.

## 4. Auditoría del dato

**Diseño.** La tabla `auditoria.cambios_clientes` está en un esquema sin acceso para PUBLIC. Guarda `momento` (TIMESTAMPTZ), `usuario_sesion` (`session_user`), `usuario_efectivo` (`current_user`), `aplicacion`, `ip_cliente`, `operacion`, `id_cliente`, y el registro completo antes y después en JSONB. Responde a las preguntas de Dirección: quién, cuándo, desde dónde y qué valor tenía antes.

**SECURITY DEFINER y session_user.** La función de disparador `auditoria.registrar_cambio_cliente()` es `SECURITY DEFINER` para que `app_ventas` provoque la escritura en la auditoría sin tener privilegios sobre ella: cuando `app_ventas` intentó leer o borrar la tabla, recibió `permission denied for schema auditoria` (líneas 271, 320, 340 y 373). Fija su `search_path` (`pg_catalog, public`) para que nadie pueda crear objetos con los mismos nombres en otro esquema y lograr que la función los use con privilegios de propietario. Dentro de una función `SECURITY DEFINER`, `current_user` devuelve el propietario de la función (`postgres`), y por eso la auditoría usa `session_user` para saber quién provocó el cambio.

**Resultado del incidente auditado.** id_evento 1, 2026-11-18 15:59:34.955-06: `app_ventas`, aplicación declarada `appventas-web`, IP 127.0.0.1, UPDATE sobre el cliente 3, `rfc` de `GAMA780912XYZ` a `GAMA780912ZZZ`. Con el valor anterior se puede restaurar con `UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;`. Altas y bajas: Pedro Ruiz quedó con su INSERT (valores_despues) y su DELETE (valores_antes) en la auditoría (id_evento 3 y 4, repetidos en 5 y 6 por una segunda ejecución).

## 5. Limitaciones

- **Lecturas.** Con `mod`, la lectura de `rfc` y `telefono` por `soporte_ana` no deja rastro, porque no existe disparador para SELECT y `mod` no registra consultas. Registrarlas exige `log_statement = 'all'` o pgaudit.
- **Volumen.** Un UPDATE masivo genera una línea en la bitácora y una fila de auditoría por cada registro afectado (el UPDATE de la Actividad 15 generó 5 filas por ejecución: id_evento 7 a 11 y 12 a 16). En una tabla de un millón de registros, la auditoría crecería un millón de filas con dos copias JSONB del registro. `log_statement = 'all'` convertiría la bitácora en un depósito de datos sensibles.
- **Administrador con control total.** `postgres` desactivó el disparador, cambió el RFC a `GAMA780912GHI` y lo reactivó (bitácora 379 a 381) sin dejar evento en la auditoría. Solo la bitácora conserva la constancia, y quien controle el servidor podría alterarla. La diferencia entre el último valor auditado (`ZZZ`, id_evento 2) y el `rfc_antes = GHI` del id_evento 11 delata que el valor cambió fuera de la auditoría.
- **Identidad.** La bitácora registra el rol con que se autenticó la sesión, no a la persona; si varias personas compartieran `app_ventas`, no podrían distinguirse. Por ejemplo, los 18 intentos fallidos de `postgres` desde `::1` (bitácora 424 a 478) fueron míos, por una contraseña olvidada y por la extensión SQLTools de VS Code con la contraseña anterior guardada. Además, `application_name` lo declara el cliente (aparece como `appventas-web` y como `app-ventas-web` según cómo lo escribí), por lo que no es evidencia fuerte de identidad.

## 6. Riesgos de la bitácora

- **Secretos expuestos.** La sentencia `CREATE ROLE rol_temporal LOGIN PASSWORD ...` queda en la bitácora con el texto exacto con que se ejecuta (líneas 43 y 98). En mi ejecución el texto fue `<REDACTED>`, por lo que no hay una contraseña real registrada; si se hubiera escrito una real, habría quedado en texto claro y eliminar el rol no la borraría.Las sentencias registradas también contienen datos personales (RFC y teléfonos, por ejemplo en las líneas 76, 266 y 360).
- **Pérdida.** La bitácora vive en el servidor y se divide en archivos (`postgresql-2026-11-17_000000.log`, `postgresql-2026-11-18_000000.log`). La vista `dba.bitacora` solo lee el archivo vigente, que inicia el 2026-11-18 a las 14:50:22 por el reinicio del equipo. Los eventos anteriores solo se pudieron consultar leyendo los archivos antiguos con `pg_ls_logdir()` y `pg_read_binary_file()`. Si el servidor se reinstala o rota sus archivos sin copia externa, la evidencia desaparece.
- **Acceso de terceros.** `pg_read_file` y `pg_read_binary_file` pueden leer cualquier archivo que el servidor lea, por lo que se restringen a superusuarios, y la vista está en el esquema `dba`, sin acceso para PUBLIC. La bitácora puede contener contraseñas, datos personales y direcciones internas.
- **Exportación.** El archivo vigente se exportó a `evidencias/bitacora-lab01.log` con `replace(...)`, que sustituye la contraseña del rol temporal por `<REDACTED>` antes de que el texto salga del servidor, y se guardó con codificación UTF-8. Su hash SHA-256 está en `evidencias/bitacora-lab01.sha256`: `01357458E401404DF00B6CBEEBF8D83F5D02EA4B7BFD20EEB2D88BC20D5ACB79`. El archivo exportado solo cubre desde el 2026-11-18 14:50:22 CST; los eventos anteriores se citan desde los archivos antiguos (ver sección 3).

**Preguntas de la Actividad 16:**

**1. Un resumen SHA-256, ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?**
No impide la modificación. Permite demostrar la integridad: si el archivo cambia aunque sea un carácter, el hash ya no coincide.

**2. ¿Dónde debería guardarse el hash para que sea útil como control de integridad?**
Fuera del servidor y fuera del alcance de quien podría modificar la bitácora (por ejemplo, el repositorio de evidencias con su commit o un sistema administrado por otra área). Si el hash está junto al archivo, quien altera uno puede alterar el otro.

**3. ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce? (NIST SP 800-92)**
Pérdida (reinstalación, rotación, falla de disco, borrado) y manipulación: quien compromete o controla el servidor puede borrar o alterar su propio rastro. Sin una copia externa no hay evidencia confiable.

**4. Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio.**
Propongo 12 meses en línea y 3 años archivada fuera del servidor. Cubre al menos un ciclo anual de facturación y auditoría, deja margen para detectar incidentes tardíos y limita el tiempo en que se conservan datos personales y posibles secretos. El criterio formal se completa en el LAB-03.

## 7. Cronología y conclusión

La cronología completa está en `evidencias/15-cronologia.md`.

Con esta configuración puede demostrarse quién (el rol de sesión), cuándo, desde qué IP y con qué aplicación declarada se cambió un dato sensible, y qué valor tenía antes, siempre que el disparador esté activo: el cambio de `app_ventas` del 2026-11-18 a las 15:59:34.955 (Actividad 12) pasó de `GAMA780912XYZ` a `GAMA780912ZZZ` desde 127.0.0.1.

No puede demostrarse:
- quién cambió el RFC a `GAMA780912XXX` (Actividad 3), porque no había bitácora;
- qué sentencia lo cambió a `GAMA780912XYZ` (Actividad 7), porque con `ddl` no se registran los UPDATE (solo quedó la conexión y desconexión de `app_ventas`);
- el valor anterior del teléfono antes del UPDATE de las 15:15:33.195, porque aún no existía el disparador;
- el valor anterior en el cambio hecho con el disparador desactivado (Actividad 14);
- las lecturas de datos sensibles;
- ni la persona detrás de cada rol.

Un administrador con control total puede desactivar el disparador, y en ese caso solo la bitácora deja constancia.

## Preguntas de reflexión

**1. ¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?**
Porque solo registra los eventos que ocurren mientras está activa: lo que no se registró en su momento no puede reconstruirse. En mi práctica, el cambio de la Actividad 3 quedó como hueco.

**2. ¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?**
Porque con `logging_collector` el destino y la lectura de la bitácora dependen de PostgreSQL y no de cómo se desplegó (servicio, Homebrew, contenedor). Funciona igual en cualquier plataforma, se lee con SQL y la evidencia queda bajo control del servidor.

**3. ¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?**
El nivel decide qué se registra, pero el prefijo decide si lo registrado se puede atribuir. Sin `%u`, `%d`, `%a` y `%h`, una línea dice qué ocurrió pero no quién ni desde dónde.

**4. ¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?**
La sentencia es el texto SQL ejecutado (un UPDATE sin WHERE es una sola línea y no muestra valores anteriores). El cambio en el dato guarda el valor anterior y el nuevo de cada registro, una fila por registro afectado, y permite restaurar.

**5. ¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?**
`pg_stat_activity` muestra lo que ocurre ahora (sesiones activas, estado, consulta en curso) pero no conserva historia. La bitácora conserva lo ocurrido después de que la sesión termina (la sesión `reporte-mensual` de `soporte_ana`, por ejemplo, quedó con su conexión y desconexión de 1 minuto 30 segundos), pero no muestra el estado actual.

**6. Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?**
Nadie dentro del propio servidor. Se necesita separación de funciones: bitácoras enviadas a un sistema externo custodiado por otra área, revisión independiente y controles administrativos.