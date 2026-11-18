# Evidencia 10 — Diseño de la auditoría

**Estudiante:** Luis Alejandro Navarrete Diaz

**Actividad:** 10

## Comando ejecutado

Ver `sql/04-esquema-auditoria.sql`:

```sql
CREATE SCHEMA auditoria;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

CREATE TABLE auditoria.cambios_clientes ( id_evento BIGSERIAL PRIMARY KEY,
 momento TIMESTAMPTZ NOT NULL DEFAULT now(),
 usuario_sesion TEXT NOT NULL DEFAULT session_user,
 usuario_efectivo TEXT NOT NULL DEFAULT current_user,
 aplicacion TEXT DEFAULT current_setting('application_name'),
 ip_cliente INET DEFAULT inet_client_addr(),
 operacion TEXT NOT NULL,
 id_cliente BIGINT,
 valores_antes JSONB,
 valores_despues JSONB
);
```

## Resultado obtenido

| nspname | nspacl |
| :--- | :--- |
| `auditoria` | `["postgres=UC/postgres"]` |

| column_name | data_type | is_nullable | column_default |
| :--- | :--- | :--- | :--- |
| `id_evento` | `bigint` | `NO` | `nextval('auditoria.cambios_clientes_id_evento_seq'::regclass)` |
| `momento` | `timestamp with time zone` | `NO` | `now()` |
| `usuario_sesion` | `text` | `NO` | `SESSION_USER` |
| `usuario_efectivo` | `text` | `NO` | `CURRENT_USER` |
| `aplicacion` | `text` | `YES` | `current_setting('application_name'::text)` |
| `ip_cliente` | `inet` | `YES` | `inet_client_addr()` |
| `operacion` | `text` | `NO` | |
| `id_cliente` | `bigint` | `YES` | |
| `valores_antes` | `jsonb` | `YES` | |
| `valores_despues` | `jsonb` | `YES` | |

**Diseño de los campos** (preguntas de Dirección: 1 ¿Quién? · 2 ¿Cuándo? · 3 ¿Desde qué aplicación o equipo? · 4 ¿Intentos fallidos previos? · 5 ¿Qué valor tenía antes?):

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| id_evento | BIGSERIAL | Ninguna directamente: identifica y ordena cada evento (apoya a todas) | No: es la clave primaria |
| momento | TIMESTAMPTZ | 2. ¿Cuándo? | No: todo evento ocurre en un momento |
| usuario_sesion | TEXT | 1. ¿Quién? (rol con que se autenticó la sesión) | No: siempre hay una sesión |
| usuario_efectivo | TEXT | 1. ¿Quién? (rol con privilegios vigentes; permite contrastar con el de sesión) | No: siempre hay un rol vigente |
| aplicacion | TEXT | 3. ¿Desde qué aplicación? | Sí: el cliente puede no declarar application_name |
| ip_cliente | INET | 3. ¿Desde qué equipo? | Sí: es nulo en conexiones por socket local |
| operacion | TEXT | 1 y 5. ¿Qué se hizo? (INSERT, UPDATE, DELETE) | No: siempre hay una operación |
| id_cliente | BIGINT | 5. ¿Sobre qué registro? | Sí: la columna lo admite; el disparador lo llena en las operaciones por fila |
| valores_antes | JSONB | 5. ¿Qué valor tenía antes? | Sí: es nulo en INSERT (no había valor anterior) |
| valores_despues | JSONB | 5. ¿Qué valor quedó? | Sí: es nulo en DELETE (ya no existe) |

## Interpretación

**1. ¿Por qué `momento` usa TIMESTAMPTZ y no TIMESTAMP?**
`TIMESTAMPTZ` guarda un instante absoluto, independiente de la zona horaria de la sesión o del servidor. Un `TIMESTAMP` sin zona es ambiguo y dificulta correlacionar la auditoría con la bitácora y con otras fuentes.

**2. ¿Por qué se guarda el registro completo en JSONB y no solo la columna que cambió?**
Porque conserva el estado completo del registro, permite reconstruirlo o restaurarlo y no depende de saber de antemano qué columna va a cambiar. También sigue siendo válido aunque `clientes` cambie de estructura después.

**3. La tabla de auditoría también contendrá RFC. ¿Qué implica para su clasificación y control de acceso?**
Que debe clasificarse al menos al mismo nivel de sensibilidad que `clientes` (dato personal). Requiere acceso restringido (esquema sin acceso para PUBLIC, solo DBA o auditor), cuidado en respaldos y exportaciones, y que su retención y depuración las defina una política y no el DBA por su cuenta.