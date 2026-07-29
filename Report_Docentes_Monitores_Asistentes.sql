-- Profesores, monitores y asistentes de los grupos activos (est_grupo = 1)
WITH profesores AS (
  SELECT g.id AS grupo, 'Profesor' AS rol, g.id_maestro AS id_persona, g.dni_maestro AS dni_persona
  FROM grupo g
  WHERE g.est_grupo = 1
    AND g.id_maestro IS NOT NULL
),
monitores AS (
  SELECT gm.grupo, 'Monitor' AS rol, gm.id_monitor AS id_persona, gm.dni_monitor AS dni_persona
  FROM grupo_x_monitor gm
  JOIN grupo g ON g.id = gm.grupo
  WHERE g.est_grupo = 1
),
asistentes AS (
  SELECT gx.grupo, 'Asistente' AS rol, gx.id_asistente AS id_persona, gx.dni_asistente AS dni_persona
  FROM grupo_x_asistente gx
  JOIN grupo g ON g.id = gx.grupo
  WHERE g.est_grupo = 1
),
todos AS (
  SELECT * FROM profesores
  UNION ALL
  SELECT * FROM monitores
  UNION ALL
  SELECT * FROM asistentes
)
SELECT
  t.grupo,
  CONCAT('Grupo ', t.grupo) AS grupo_nombre,
  mat.nombre AS materia,
  s.nombre AS sede,
  t.rol,
  TRIM(CONCAT(u.nombre1, ' ', COALESCE(u.nombre2, ''), ' ', u.apellido1, ' ', COALESCE(u.apellido2, ''))) AS nombre_completo,
  u.id AS documento,
  td.abreviacion AS tipo_documento,
  u.celular,
  u.email
FROM todos t
JOIN grupo g ON g.id = t.grupo
JOIN materia mat ON mat.id = g.materia
JOIN sede s ON s.id = g.sede
JOIN usuario u ON u.id = t.id_persona AND u.dni = t.dni_persona
JOIN t_dni td ON td.id = u.dni
ORDER BY t.grupo, FIELD(t.rol, 'Profesor', 'Monitor', 'Asistente'), nombre_completo;
