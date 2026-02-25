-- ...existing code...
WITH
tc AS (
  SELECT grupo, COUNT(*) AS total_clases
  FROM clase
  WHERE grupo IN (364,545,475,723) AND est_clase = 2 AND url_video IS NOT NULL
  GROUP BY grupo
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
  WHERE a.grupo IN (364,545,475,723)
  GROUP BY a.grupo, a.id_alumno
),
per_alumno_grupo AS (
  SELECT
    m.id_alumno,
    TRIM(CONCAT(u.nombre1,' ',COALESCE(u.nombre2,''),' ',u.apellido1,' ',COALESCE(u.apellido2,''))) AS nombre,
    m.grupo AS grupo_id,
    COALESCE(g.title, CONCAT('Grupo ', m.grupo)) AS grupo,
    COALESCE(tc.total_clases,0) AS clases_totales,
    COALESCE(ac.clases_con_asistencia,0) AS clases_con_asistencia,
    ROUND(
      CASE WHEN COALESCE(tc.total_clases,0) > 0
           THEN (COALESCE(ac.clases_con_asistencia,0) * 100.0) / tc.total_clases
           ELSE 0
      END, 2
    ) AS porcentaje
  FROM matricula_materia m
  JOIN grupo g ON m.grupo = g.id
  JOIN alumno al ON m.id_alumno = al.id AND m.dni_alumno = al.dni
  JOIN usuario u ON al.id = u.id AND al.dni = u.dni
  LEFT JOIN tc ON tc.grupo = m.grupo
  LEFT JOIN ac ON ac.grupo = m.grupo AND ac.id_alumno = m.id_alumno
  WHERE m.grupo IN (364,545,475,723)
    AND m.id_alumno IN ('71219122', '32491705', '1017221916', '71645221', '1007643081', '1039598031', '1152197989',
                      '1017221630', '1021803322', '1039447979', '1032361868', '1001618440', '70812395', '1027805968',
                      '8101474', '1036449886', '1000752602', '1141515186', '1152709989', '1017250598', '1116499961',
                      '1037624950', '1216725600', '1000538891', '1001618441', '71737479', '1004702414', '1037662167',
                      '1000764693', '1214726551', '98626031', '1004921413', '1017241783', '1036686611')
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



