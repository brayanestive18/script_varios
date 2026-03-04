WITH
-- Grupos DIR: pertenecen a las materias específicas
grupos_dir AS (
  SELECT g.id AS grupo_id
  FROM grupo g
  WHERE g.materia IN (34, 48, 55, 65, 68, 69, 74)
  AND g.id NOT IN (1174,294,516,519) 
  -- excluir grupos específicos 1174 (11) Remendado Redes
  -- 294 (OLD), 516 (12), 647 (48) que no corresponden a DIR 
),
-- Total clases válidas por grupo DIR
tc AS (
  SELECT c.grupo, COUNT(*) AS total_clases
  FROM clase c
  JOIN grupos_dir gd ON gd.grupo_id = c.grupo
  WHERE c.est_clase = 2 AND c.url_video IS NOT NULL
  GROUP BY c.grupo
),
-- Asistencias por alumno en grupos DIR
ac AS (
  SELECT a.grupo, a.id_alumno, COUNT(DISTINCT a.clase) AS clases_con_asistencia
  FROM asistencia_clase a
  JOIN clase c
    ON c.grupo = a.grupo
   AND c.id = a.clase
   AND c.est_clase = 2
   AND c.url_video IS NOT NULL
  JOIN grupos_dir gd ON gd.grupo_id = a.grupo
  GROUP BY a.grupo, a.id_alumno
),
-- Grupo ILC de cada alumno (grupo activo que NO es de materias DIR)
ilc AS (
  SELECT
    m.id_alumno,
    m.dni_alumno,
    CONCAT('Grupo ', m.grupo) AS grupo_ILC,
    mat.nombre AS materia_ILC,
    ROW_NUMBER() OVER (PARTITION BY m.id_alumno ORDER BY m.grupo DESC) AS rn
  FROM matricula_materia m
  JOIN grupo g ON m.grupo = g.id
  JOIN materia mat ON g.materia = mat.id
  WHERE g.est_grupo = 1
    AND g.materia NOT IN (34,48,51,53,54,55,65,68,69,71,73,74)
),
-- Matriculaciones en grupos DIR por alumno
dir_mat AS (
  SELECT m.id_alumno, m.grupo, mat.nombre AS materia_DIR
  FROM matricula_materia m
  JOIN grupos_dir gd ON gd.grupo_id = m.grupo
  JOIN grupo g ON m.grupo = g.id
  JOIN materia mat ON g.materia = mat.id
),
-- Cruce: alumno ILC con su asistencia en grupo DIR
per_alumno_grupo AS (
  SELECT
    ilc.id_alumno,
    TRIM(CONCAT(u.nombre1,' ',COALESCE(u.nombre2,''),' ',u.apellido1,' ',COALESCE(u.apellido2,''))) AS nombre,
    ilc.grupo_ILC,
    ilc.materia_ILC,
    COALESCE(CONCAT('Grupo ', dm.grupo), 'No matriculado en DIR') AS grupo_DIR,
    COALESCE(dm.materia_DIR, 'No matriculado en DIR') AS materia_DIR,
    COALESCE(tc.total_clases,0) AS clases_totales,
    COALESCE(ac.clases_con_asistencia,0) AS clases_con_asistencia,
    ROUND(
      CASE WHEN COALESCE(tc.total_clases,0) > 0
           THEN (COALESCE(ac.clases_con_asistencia,0) * 100.0) / tc.total_clases
           ELSE 0
      END, 2
    ) AS porcentaje
  FROM ilc
  JOIN alumno al ON ilc.id_alumno = al.id AND ilc.dni_alumno = al.dni
  JOIN usuario u ON al.id = u.id AND al.dni = u.dni
  LEFT JOIN dir_mat dm ON dm.id_alumno = ilc.id_alumno
  LEFT JOIN tc ON tc.grupo = dm.grupo
  LEFT JOIN ac ON ac.grupo = dm.grupo AND ac.id_alumno = ilc.id_alumno
  WHERE ilc.rn = 1
  GROUP BY ilc.id_alumno, nombre, ilc.grupo_ILC, ilc.materia_ILC, dm.grupo, dm.materia_DIR, tc.total_clases, ac.clases_con_asistencia
)
SELECT id_alumno, nombre, grupo_ILC, materia_ILC, grupo_DIR, materia_DIR, porcentaje, clases_con_asistencia, clases_totales
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY id_alumno ORDER BY porcentaje DESC, clases_con_asistencia DESC) AS rn
  FROM per_alumno_grupo
) t
WHERE rn = 1
ORDER BY nombre;