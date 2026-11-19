# LAB-01 — Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** Luis Alejandro Navarrete Diaz
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos

## Despliegue del servidor (Anexo A)

- **Forma de despliegue:** instalación nativa en Windows con el instalador de EDB.
- **Versión:** "PostgreSQL 18.0 on x86_64-windows, compiled by msvc-19.44.35217, 64-bit"
- **Directorio de datos:** `C:/Program Files/PostgreSQL/18/data` (`pg_hba.conf` y `postgresql.auto.conf` están en ese directorio).
- **Sesión de administrador:** pgAdmin 4 (Query Tool y PSQL Tool) conectado como `postgres` a la base `comercial`.
- **Sesiones por red (app_ventas y soporte_ana):** `psql` desde PowerShell, hacia `127.0.0.1`.
- **Reinicio del servicio:** `Restart-Service postgresql-x64-18`.