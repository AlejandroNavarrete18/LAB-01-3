# Evidencia 14 — Límites: lecturas y volumen

**Estudiante:** Luis Alejandro Navarrete Diaz

**Actividad:** 15

## Comando ejecutado

Terminal:

```bash
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
```

Administrador:

```sql
UPDATE clientes SET segmento = 'regular';

SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%statement: UPDATE clientes SET segmento%';

SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;

SELECT count(*) AS lecturas_soporte FROM dba.bitacora
WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
```

## Resultado obtenido

| lineas_bitacora |
| :--- |
| 2 |

| operacion | count |
| :--- | :--- |
| `DELETE` | 2 |
| `INSERT` | 2 |
| `UPDATE` | 12 |

| lecturas_soporte |
| :--- |
| 0 |

## Interpretación

El UPDATE masivo produjo una línea en la bitácora y una fila nueva en la auditoría por cada registro afectado. La lectura del RFC por `soporte_ana` no dejó rastro: no existe disparador para SELECT y `mod` no registra consultas.

**1. Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un UPDATE sin WHERE?**
La bitácora seguiría teniendo una sola línea, pero la tabla de auditoría recibiría un millón de filas (cada una con el registro completo antes y después en JSONB). Crecería muy rápido en almacenamiento, la operación se volvería mucho más lenta y la tabla se volvería difícil de consultar.

**2. Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`.**
El responsable del dato junto con el área de seguridad y cumplimiento (con conocimiento de auditoría interna), según la política de retención. No debe autorizarla ni ejecutarla por sí solo el DBA que opera la base.

**3. ¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?**
Porque registra el texto de todas las sentencias, con los valores literales (RFC, teléfonos, correos, contraseñas en sentencias) en archivos de texto con menos controles que la base, lo que duplica los datos sensibles fuera de ella.