# Evidencia 12 — Altas y bajas

**Estudiante:** Luis Alejandro Navarrete Diaz

**Actividad:** 13

## Comando ejecutado

```sql
INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');
DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';

SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
 valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
```

## Resultado obtenido

| id_evento | usuario_sesion | aplicacion | ip_cliente | operacion | id_cliente | rfc_antes | rfc_despues |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `app_ventas` | `appventas-web` | `127.0.0.1` | `UPDATE` | 3 | `GAMA780912XYZ` | `GAMA780912ZZZ` |
| 2 | `app_ventas` | `app-ventas-web` | `127.0.0.1` | `UPDATE` | 3 | `GAMA780912ZZZ` | `GAMA780912ZZZ` |
| 3 | `postgres` | `pgAdmin 4 - CONN:5123666` | `::1` | `INSERT` | 6 | | `RUPE950101AAA` |
| 4 | `postgres` | `pgAdmin 4 - CONN:5123666` | `::1` | `DELETE` | 6 | `RUPE950101AAA` | |

## Interpretación

**1. El cliente Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?**
En `auditoria.cambios_clientes`: el INSERT conserva sus datos en `valores_despues` y el DELETE conserva el registro completo en `valores_antes`. Las sentencias también quedan en la bitácora con `log_statement = 'mod'`.

**2. ¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?**
Porque el administrador se conectó por socket Unix local, no por TCP, y `inet_client_addr()` devuelve NULL en ese caso.

**3. La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**
La tabla de auditoría conserva los datos personales (por ejemplo el RFC) de un cliente que ya fue eliminado de `clientes`. Eso choca con la política de eliminar datos que ya no son necesarios. Debe resolverlo quien define la política de retención y gobierno del dato (responsable del dato junto con seguridad y cumplimiento), no el DBA por su cuenta. El criterio formal se completa en el LAB-03.