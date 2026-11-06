-- Prevision exploratoire par tendance lineaire sur le chiffre d'affaires mensuel.
-- Une prevision est publiee seulement avec au moins six mois calendaires observes.
WITH RECURSIVE
mensuel AS (
  SELECT CAST(DATE_FORMAT(d.date_complete, '%Y-%m-01') AS DATE) AS mois,
         SUM(f.total1) AS chiffre_affaires
  FROM entrepot_etl.faits_ventes AS f
  JOIN entrepot_etl.dim_date AS d ON d.id_date=f.id_temps
  GROUP BY CAST(DATE_FORMAT(d.date_complete, '%Y-%m-01') AS DATE)
),
bornes AS (
  SELECT MIN(mois) AS premier_mois, MAX(mois) AS dernier_mois
  FROM mensuel
),
calendrier(mois) AS (
  SELECT premier_mois FROM bornes WHERE premier_mois IS NOT NULL
  UNION ALL
  SELECT DATE_ADD(calendrier.mois, INTERVAL 1 MONTH)
  FROM calendrier CROSS JOIN bornes
  WHERE calendrier.mois < bornes.dernier_mois
),
serie AS (
  SELECT calendrier.mois,
         COALESCE(mensuel.chiffre_affaires, 0) AS chiffre_affaires,
         TIMESTAMPDIFF(MONTH, bornes.premier_mois, calendrier.mois) + 1 AS x
  FROM calendrier
  CROSS JOIN bornes
  LEFT JOIN mensuel ON mensuel.mois=calendrier.mois
),
stats AS (
  SELECT COUNT(*) AS n,
         SUM(x) AS somme_x,
         SUM(chiffre_affaires) AS somme_y,
         SUM(x * chiffre_affaires) AS somme_xy,
         SUM(x * x) AS somme_x2,
         MIN(mois) AS premier_mois,
         MAX(mois) AS dernier_mois
  FROM serie
),
modele AS (
  SELECT stats.*,
    CASE WHEN (n * somme_x2 - somme_x * somme_x) = 0 THEN 0
      ELSE (n * somme_xy - somme_x * somme_y)
        / (n * somme_x2 - somme_x * somme_x) END AS pente,
    (somme_y / n) -
      (CASE WHEN (n * somme_x2 - somme_x * somme_x) = 0 THEN 0
        ELSE (n * somme_xy - somme_x * somme_y)
          / (n * somme_x2 - somme_x * somme_x) END) * (somme_x / n) AS constante
  FROM stats
)
SELECT DATE_FORMAT(DATE_ADD(modele.dernier_mois, INTERVAL projection.mois_a_prevoir MONTH), '%Y-%m')
         AS mois_prevu,
       CASE WHEN modele.n < 6 THEN NULL
         ELSE ROUND(GREATEST(modele.constante + modele.pente *
           (modele.n + projection.mois_a_prevoir), 0), 2)
       END AS chiffre_affaires_prevu,
       modele.n AS mois_observes,
       CASE WHEN modele.n < 6 THEN 'Donnees insuffisantes: minimum 6 mois'
         ELSE 'Tendance lineaire exploratoire' END AS methode
FROM modele
CROSS JOIN (
  SELECT 1 AS mois_a_prevoir
  UNION ALL SELECT 2
  UNION ALL SELECT 3
) AS projection
ORDER BY projection.mois_a_prevoir;
