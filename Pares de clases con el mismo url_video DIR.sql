-- Pares de clases con el mismo url_video entre los grupos 872 y 723
WITH g872 AS (
  SELECT id AS clase_id_872, url_video FROM clase WHERE grupo = 872
),
g723 AS (
  SELECT id AS clase_id_723, url_video FROM clase WHERE grupo = 723
)
SELECT
  g872.clase_id_872,
  g872.url_video,
  g723.clase_id_723
FROM g872
JOIN g723 ON g872.url_video = g723.url_video
WHERE g872.url_video IS NOT NULL AND g872.url_video <> ''
ORDER BY g872.url_video, g872.clase_id_872, g723.clase_id_723;

-- Listado por clase indicando si hay iguales en el otro grupo
WITH g872 AS (
  SELECT id, url_video FROM clase WHERE grupo = 872
),
g723 AS (
  SELECT id, url_video FROM clase WHERE grupo = 723
),
matches_872 AS (
  SELECT url_video, GROUP_CONCAT(id ORDER BY id SEPARATOR ',') AS ids_723
  FROM g723
  WHERE url_video IS NOT NULL AND url_video <> ''
  GROUP BY url_video
),
matches_723 AS (
  SELECT url_video, GROUP_CONCAT(id ORDER BY id SEPARATOR ',') AS ids_872
  FROM g872
  WHERE url_video IS NOT NULL AND url_video <> ''
  GROUP BY url_video
)
SELECT
  872 AS grupo,
  g.id AS id_clase,
  g.url_video,
  CASE WHEN m.ids_723 IS NOT NULL THEN 'CON IGUAL' ELSE 'SIN IGUAL' END AS estado,
  COALESCE(m.ids_723, '') AS ids_en_otro_grupo
FROM g872 g
LEFT JOIN matches_872 m ON g.url_video = m.url_video

UNION ALL

SELECT
  723 AS grupo,
  g.id AS id_clase,
  g.url_video,
  CASE WHEN m.ids_872 IS NOT NULL THEN 'CON IGUAL' ELSE 'SIN IGUAL' END AS estado,
  COALESCE(m.ids_872, '') AS ids_en_otro_grupo
FROM g723 g
LEFT JOIN matches_723 m ON g.url_video = m.url_video

ORDER BY grupo, id_clase;