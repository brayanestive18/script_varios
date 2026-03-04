-- ...existing code...
WITH
-- grupos que pertenecen a las materias DIR en lugar de listar los ids de grupo
grupos_dir AS (
  SELECT g.id AS grupo_id
  FROM grupo g
  WHERE g.materia IN (34, 48, 55, 65, 68, 69, 74)
    AND g.id NOT IN (1174,294,516,647)
),
tc AS (
  SELECT c.grupo, COUNT(*) AS total_clases
  FROM clase c
  JOIN grupos_dir gd ON gd.grupo_id = c.grupo
  WHERE c.est_clase = 2 AND c.url_video IS NOT NULL
  GROUP BY c.grupo
),
ac AS (
  -- contar solo asistencias que correspondan a clases válidas (mismas que usa tc)
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
per_alumno_grupo AS (
  SELECT
    m.id_alumno,
    TRIM(CONCAT(u.nombre1,' ',COALESCE(u.nombre2,''),' ',u.apellido1,' ',COALESCE(u.apellido2,''))) AS nombre,
    m.grupo AS grupo_id,
    CONCAT('Grupo ', m.grupo) AS grupo,
    COALESCE(tc.total_clases,0) AS clases_totales,
    COALESCE(ac.clases_con_asistencia,0) AS clases_con_asistencia,
    ROUND(
      CASE WHEN COALESCE(tc.total_clases,0) > 0
           THEN (COALESCE(ac.clases_con_asistencia,0) * 100.0) / tc.total_clases
           ELSE 0
      END, 2
    ) AS porcentaje
  FROM matricula_materia m
  JOIN grupos_dir gd ON gd.grupo_id = m.grupo
  JOIN grupo g ON m.grupo = g.id
  JOIN alumno al ON m.id_alumno = al.id AND m.dni_alumno = al.dni
  JOIN usuario u ON al.id = u.id AND al.dni = u.dni
  LEFT JOIN tc ON tc.grupo = m.grupo
  LEFT JOIN ac ON ac.grupo = m.grupo AND ac.id_alumno = m.id_alumno
  WHERE m.id_alumno IN ('32491705', '64920014', '1036613503', '43204964', '43189013', '43584700', '43606235', '43601444', '71775420', '43828775', '71317778', '98512668', '30294338', '43748145', '32533908', '15438991', '1039598031', '1152197989', '43677721', '43257971', '43101428', '43744709', '43096254', '39206187', '98589682', '1039447979', '43795925', '71084789', '39357458', '98626848', '42761474', '43023459', '1065578523', '43834760', '1128420262', '21404146', '32541619', '32322183', '98489727', '43633614', '71755043', '98470975', '43498900', '43640521', '43666614', '70508377', '39416448', '43988388', '71683459', '1128476920', '1128470467', '71782140', '1193051289', '71720463', '79495943', '70500814', '70518454', '1152684808', '71767127', '70812513', '8101474', '1020408285', '1037594035', '15446143', '71141563', '32109237', '1017250598', '43986957', '39427280', '43558188', '43455044', '21588415', '43157461', '44001531', '1072706184', '71695628', '1017229517', '1152192686', '32142769', '43250792', '1017123617', '1152213951', '32558238', '43425960', '24432501', '43221650', '42770116', '43033080', '42770116', '1000305538', '43579507', '43506130', '42976709', '43075274', '43081430', '43441805', '1128436984', '43684924', '44007776', '43524291', '15325354', '24706399', '71737479', '39178892', '43258396', '1001368954', '1128445068', '1037583180', '43278827', '43752316', '43104882', '43481700', '42899207', '1036636732', '70057232', '1152194431', '43200022', '93203838', '32220371', '1017141565')
  GROUP BY m.id_alumno, nombre, m.grupo, g.title, tc.total_clases, ac.clases_con_asistencia
)
SELECT id_alumno, nombre, grupo, porcentaje, clases_con_asistencia, clases_totales
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY id_alumno ORDER BY porcentaje DESC, clases_con_asistencia DESC) AS rn
  FROM per_alumno_grupo
) t
WHERE rn = 1
ORDER BY nombre;



