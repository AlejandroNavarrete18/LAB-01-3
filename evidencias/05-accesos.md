# Evidencia 05 — Accesos exitosos y fallidos

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 5

## Comando ejecutado

Terminal:

```bash
psql "postgresql://app_ventas:incorrecta@127.0.0.1/comercial" -c "SELECT 1"
psql "postgresql://usuario_inexistente:x@127.0.0.1/comercial" -c "SELECT 1"
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
```

Sesión de administrador:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;
```

Consulta de la pregunta 4 (intentos fallidos por usuario):

```sql
SELECT substring(linea FROM 'password authentication failed for user "([^"]+)"') AS usuario,
       count(*) AS intentos_fallidos
FROM dba.bitacora
WHERE linea LIKE '%FATAL:%password authentication failed%'
GROUP BY 1
ORDER BY 2 DESC;
```

## Resultado obtenido

**Salida de los tres psql:**

PS C:\Users\alexd> $env:Path += ";C:\Program Files\PostgreSQL\18\bin"
PS C:\Users\alexd> psql "postgresql://app_ventas:incorrecta@127.0.0.1/comercial" -c "SELECT 1"
psql: error: falló la conexión al servidor en «127.0.0.1», puerto 5432: FATAL:  password authentication failed for user "app_ventas"
falló la conexión al servidor en «127.0.0.1», puerto 5432: FATAL:  password authentication failed for user "app_ventas"
PS C:\Users\alexd> psql "postgresql://usuario_inexistente:x@127.0.0.1/comercial" -c "SELECT 1"
psql: error: falló la conexión al servidor en «127.0.0.1», puerto 5432: FATAL:  password authentication failed for user "usuario_inexistente"
falló la conexión al servidor en «127.0.0.1», puerto 5432: FATAL:  password authentication failed for user "usuario_inexistente"
PS C:\Users\alexd> psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
 count
-------
     5
(1 fila)

**Líneas de la bitácora con tu client**
```log
2026-11-18 14:51:09.947 CST [15568] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=64552
2026-11-18 14:51:09.967 CST [15568] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
2026-11-18 14:51:09.967 CST [15568] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "C:/Program Files/PostgreSQL/18/data/pg_hba.conf" line 115: "host    all             all             127.0.0.1/32            scram-sha-256"
2026-11-18 14:51:09.986 CST [35612] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=64553
2026-11-18 14:51:09.994 CST [35612] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
2026-11-18 14:51:09.994 CST [35612] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "C:/Program Files/PostgreSQL/18/data/pg_hba.conf" line 115: "host    all             all             127.0.0.1/32            scram-sha-256"
2026-11-18 14:51:16.106 CST [34684] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=64558
2026-11-18 14:51:16.125 CST [34684] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
2026-11-18 14:51:16.125 CST [34684] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
2026-11-18 14:51:16.145 CST [34652] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=64559
2026-11-18 14:51:16.153 CST [34652] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
2026-11-18 14:51:16.153 CST [34652] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
2026-11-18 14:51:20.690 CST [14832] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=64562
2026-11-18 14:51:20.709 CST [14832] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="app_ventas" method=scram-sha-256 (C:/Program Files/PostgreSQL/18/data/pg_hba.conf:115)
2026-11-18 14:51:20.709 CST [14832] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
2026-11-18 14:51:20.752 CST [14832] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.067 user=app_ventas database=comercial host=127.0.0.1 port=64562
```
**Resultado de la consulta de intentos fallidos por usuario:**

| usuario | intentos_fallidos |
| :--- | :--- |
| `app_ventas` | 2 |
| `usuario_inexistente` | 2 |

**Lectura de una línea campo por campo (una de tus líneas FATAL):**

| Campo | Valor | Significado |
|---|---|---|
| Fecha y hora | 2026-11-18 14:51:09.967 CST | Momento del evento (en la zona de log_timezone) |
| PID | 15568 | Proceso del servidor; agrupa las líneas de una misma sesión |
| Usuario | app_ventas | Usuario declarado por el cliente en la conexión |
| Base de datos | comercial | Base a la que se intentó entrar |
| Aplicación | [unknown] | application_name; [unknown] porque aún no se asignó (y en este intento no se indicó) |
| Cliente | 127.0.0.1 | Dirección IP desde la que llegó la conexión |
| Severidad | FATAL | Nivel del mensaje (FATAL: la conexión se terminó) |
| Mensaje | password authentication failed for user "app_ventas" | Qué ocurrió |
| Regla aplicada | pg_hba.conf línea 115 (C:/Program Files/PostgreSQL/18/data/pg_hba.conf) | Línea de pg_hba.conf que correspondió a la conexión |

## Interpretación

**1. La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?**
No lo prueba. El nombre de usuario lo declara el cliente. Lo que prueba es que alguien, desde esa dirección IP y en ese momento, intentó autenticarse como `app_ventas` con una contraseña incorrecta.

**2. ¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje al cliente?**
Registra `DETAIL: Role "usuario_inexistente" does not exist`. El cliente recibe el mismo mensaje genérico en ambos casos para no revelarle a un atacante si un usuario existe (enumeración de usuarios). El detalle queda solo para el administrador, en la bitácora.

**3. ¿Por qué `app=[unknown]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?**
Porque en los intentos fallidos no se indicó `application_name`, y porque aun cuando se indica, la sesión lo recibe después de autenticarse. Las líneas anteriores a ese momento muestran `[unknown]`, y la desconexión, ya con la sesión establecida, muestra el nombre.

**4. ¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta?**
Muchas líneas `FATAL: password authentication failed` para el mismo usuario, o para muchos usuarios distintos, desde la misma IP en un lapso corto, especialmente si terminan en una conexión exitosa. La consulta que cuenta los intentos fallidos por usuario está en la sección "Comando ejecutado".