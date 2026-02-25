-- Copiar URL
WITH src AS (
  SELECT id, url_video,
         ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM clase
  WHERE grupo = 872 AND id >= 39 AND url_video IS NOT NULL
),
tgt AS (
  SELECT id, url_video,
         ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM clase
  WHERE grupo = 1008 AND id >= 39
)
SELECT
  src.rn,
  src.id   AS src_id,
  src.url_video AS src_url,
  tgt.id   AS tgt_id,
  tgt.url_video AS tgt_url
FROM src
JOIN tgt ON src.rn = tgt.rn
ORDER BY src.rn;

START TRANSACTION;

UPDATE clase AS tgt
JOIN (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM clase
  WHERE grupo = 1008 AND id >= 39
) AS t ON tgt.grupo = 1008 AND tgt.id = t.id
JOIN (
  SELECT url_video, ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM clase
  WHERE grupo = 872 AND id >= 39 AND url_video IS NOT NULL
) AS s ON s.rn = t.rn
SET tgt.url_video = s.url_video
-- opcional: evitar sobreescribir si ya coincide
-- WHERE tgt.url_video IS NULL OR tgt.url_video <> s.url_video
;

COMMIT;