# Evidencia 03 — Incidente sin bitácora

**Estudiante:** Luis Alejandro Navarrete Diaz
**Actividad:** 3

## Comando ejecutado

Terminal (como aplicación de ventas):

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
```

Sesión de administrador:

```sql
SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';
```

## Resultado obtenido
```powershell
PS C:\Users\alexd> $env:Path += ";C:\Program Files\PostgreSQL\18\bin"
PS C:\Users\alexd> psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
UPDATE 1
```log
2026-11-17 18:05:28 CST SENTENCIA:  \password app_ventas
2026-11-17 18:05:30 CST SENTENCIA:  \password app_ventas
```





## Interpretación

**1. ¿Puedes demostrar quién modificó el RFC?** No. No existe ninguna línea de la conexión ni del UPDATE, porque con la configuración por defecto no se registran conexiones ni sentencias.

**2. ¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?** No hay evidencia. Los privilegios indican lo que cada rol podía hacer, no lo que hizo. Sin bitácora no hay forma de descartarla ni de señalarla.

**3. Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?** No lo impidieron y no debían: `app_ventas` tiene UPDATE legítimo sobre `clientes`. El control de acceso dice quién puede hacer algo, pero no distingue entre un cambio legítimo, un error o un abuso, ni deja evidencia de lo ocurrido.

**4. ¿Qué tendría que haber estado configurado antes del incidente?** `logging_collector = on`, `log_connections = on`, `log_disconnections = on`, un `log_line_prefix` con `%u`, `%d`, `%a` y `%h`, y `log_statement` en al menos `mod`. Además, una auditoría a nivel de dato (tabla de auditoría con disparador) para conservar el valor anterior.

Idea central: la auditoría no puede configurarse "después" para eventos que ya ocurrieron. Lo que no se registró en su momento no puede reconstruirse.