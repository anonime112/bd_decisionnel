SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS entrepot_etl
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE entrepot_etl;

CREATE TABLE IF NOT EXISTS dim_date (
  id_date INT UNSIGNED NOT NULL,
  date_complete DATE NOT NULL,
  jour TINYINT UNSIGNED NOT NULL,
  jour_semaine TINYINT UNSIGNED NOT NULL,
  mois TINYINT UNSIGNED NOT NULL,
  nom_mois VARCHAR(12) NOT NULL,
  trimestre TINYINT UNSIGNED NOT NULL,
  annees SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (id_date),
  UNIQUE KEY uq_dim_date_complete (date_complete)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE dim_date
  ADD COLUMN IF NOT EXISTS jour_semaine TINYINT UNSIGNED NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS nom_mois VARCHAR(12) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS dim_geographie (
  id_geographie INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pays VARCHAR(100) NOT NULL,
  region VARCHAR(100) NOT NULL,
  ville VARCHAR(100) NOT NULL,
  code_postal VARCHAR(20) NOT NULL,
  PRIMARY KEY (id_geographie),
  UNIQUE KEY uq_dim_geographie (pays, region, ville, code_postal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dim_client (
  id_utilisateur INT UNSIGNED NOT NULL,
  age SMALLINT UNSIGNED NULL,
  tranche_age VARCHAR(20) NOT NULL,
  genre VARCHAR(30) NOT NULL,
  type_utilisateur VARCHAR(30) NOT NULL,
  date_inscription DATE NULL,
  id_geographie INT UNSIGNED NULL,
  PRIMARY KEY (id_utilisateur),
  KEY ix_dim_client_geographie (id_geographie),
  KEY ix_dim_client_segment (genre, tranche_age),
  CONSTRAINT fk_dim_client_geographie FOREIGN KEY (id_geographie)
    REFERENCES dim_geographie (id_geographie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE dim_client
  ADD COLUMN IF NOT EXISTS age SMALLINT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS tranche_age VARCHAR(20) NOT NULL DEFAULT 'Inconnue',
  ADD COLUMN IF NOT EXISTS genre VARCHAR(30) NOT NULL DEFAULT 'Non renseigne',
  ADD COLUMN IF NOT EXISTS id_geographie INT UNSIGNED NULL;

CREATE TABLE IF NOT EXISTS dim_produit (
  id_produit INT UNSIGNED NOT NULL,
  id_categorie INT UNSIGNED NOT NULL,
  nom_categorie VARCHAR(100) NOT NULL,
  nom VARCHAR(150) NOT NULL,
  marque VARCHAR(100) NOT NULL,
  prix DECIMAL(12,2) NOT NULL,
  taille VARCHAR(50) NOT NULL,
  couleur VARCHAR(50) NOT NULL,
  date_ajout DATE NULL,
  PRIMARY KEY (id_produit),
  KEY ix_dim_produit_categorie (id_categorie),
  KEY ix_dim_produit_marque (marque)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE dim_produit
  ADD COLUMN IF NOT EXISTS couleur VARCHAR(50) NOT NULL DEFAULT 'Non renseignee',
  ADD COLUMN IF NOT EXISTS date_ajout DATE NULL;

CREATE TABLE IF NOT EXISTS dim_transport (
  id_transport INT UNSIGNED NOT NULL AUTO_INCREMENT,
  transporteur VARCHAR(100) NOT NULL,
  mode_livraison VARCHAR(100) NOT NULL,
  PRIMARY KEY (id_transport),
  UNIQUE KEY uq_dim_transport (transporteur, mode_livraison)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dim_promotion (
  id_promo INT UNSIGNED NOT NULL,
  code VARCHAR(30) NOT NULL,
  description TEXT,
  reduction_pct DECIMAL(5,2) NOT NULL,
  actif TINYINT(1) NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  PRIMARY KEY (id_promo),
  UNIQUE KEY uq_dim_promotion_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dim_appareil (
  id_appareil INT UNSIGNED NOT NULL AUTO_INCREMENT,
  navigateur VARCHAR(255) NOT NULL,
  systeme_exploitation VARCHAR(100) NOT NULL,
  PRIMARY KEY (id_appareil),
  UNIQUE KEY uq_dim_appareil (navigateur, systeme_exploitation)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_ventes (
  id_fait BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_detail INT UNSIGNED NOT NULL,
  id_temps INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_produit INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_transport INT UNSIGNED NULL,
  id_promo INT UNSIGNED NULL,
  reduction_promo_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  id_commande INT UNSIGNED NOT NULL,
  statut VARCHAR(40) NOT NULL,
  quantite INT UNSIGNED NOT NULL,
  prix_unitaire DECIMAL(12,2) NOT NULL,
  total1 DECIMAL(14,2) NOT NULL,
  age_au_achat SMALLINT UNSIGNED NULL,
  PRIMARY KEY (id_fait),
  UNIQUE KEY uq_faits_ventes_detail (id_detail),
  KEY ix_faits_ventes_date (id_temps),
  KEY ix_faits_ventes_client (id_utilisateur),
  KEY ix_faits_ventes_produit (id_produit),
  KEY ix_faits_ventes_geo (id_geographie),
  KEY ix_faits_ventes_transport (id_transport),
  KEY ix_faits_ventes_promo (id_promo),
  KEY ix_faits_ventes_commande (id_commande),
  CONSTRAINT fk_fv_date FOREIGN KEY (id_temps) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fv_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fv_produit FOREIGN KEY (id_produit) REFERENCES dim_produit (id_produit),
  CONSTRAINT fk_fv_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie),
  CONSTRAINT fk_fv_transport FOREIGN KEY (id_transport) REFERENCES dim_transport (id_transport)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE faits_ventes
  ADD COLUMN IF NOT EXISTS id_geographie INT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS id_transport INT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS id_promo INT UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS reduction_promo_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS age_au_achat SMALLINT UNSIGNED NULL;

CREATE TABLE IF NOT EXISTS faits_stock (
  id_stock BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_date INT UNSIGNED NOT NULL,
  id_produit INT UNSIGNED NOT NULL,
  quantite_stock INT UNSIGNED NOT NULL,
  seuil_alerte INT UNSIGNED NOT NULL,
  valeur_stock DECIMAL(14,2) NOT NULL,
  en_rupture TINYINT(1) NOT NULL,
  PRIMARY KEY (id_stock),
  UNIQUE KEY uq_faits_stock_jour_produit (id_date, id_produit),
  CONSTRAINT fk_fs_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fs_produit FOREIGN KEY (id_produit) REFERENCES dim_produit (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_trafic_web (
  id_fait_trafic BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_log BIGINT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NULL,
  id_geographie INT UNSIGNED NULL,
  page_visitee VARCHAR(255) NOT NULL,
  duree_seconde INT UNSIGNED NOT NULL,
  nombre_vues TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (id_fait_trafic),
  UNIQUE KEY uq_faits_trafic_log (id_log),
  KEY ix_ft_date (id_date),
  KEY ix_ft_client (id_utilisateur),
  KEY ix_ft_geo (id_geographie),
  CONSTRAINT fk_ft_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_ft_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_ft_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_connexions (
  id_fait_connexion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_connexion BIGINT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_appareil INT UNSIGNED NOT NULL,
  nombre_connexions TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (id_fait_connexion),
  UNIQUE KEY uq_faits_connexions_source (id_connexion),
  CONSTRAINT fk_fc_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fc_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fc_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie),
  CONSTRAINT fk_fc_appareil FOREIGN KEY (id_appareil) REFERENCES dim_appareil (id_appareil)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_avis (
  id_fait_avis BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_avis INT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_produit INT UNSIGNED NOT NULL,
  note TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (id_fait_avis),
  UNIQUE KEY uq_faits_avis_source (id_avis),
  CONSTRAINT fk_fa_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fa_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fa_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie),
  CONSTRAINT fk_fa_produit FOREIGN KEY (id_produit) REFERENCES dim_produit (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_retours (
  id_fait_retour BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_retour INT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_produit INT UNSIGNED NOT NULL,
  id_commande INT UNSIGNED NOT NULL,
  quantite_retour INT UNSIGNED NOT NULL,
  statut_retour VARCHAR(30) NOT NULL,
  PRIMARY KEY (id_fait_retour),
  UNIQUE KEY uq_faits_retours_source (id_retour),
  CONSTRAINT fk_fr_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fr_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fr_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie),
  CONSTRAINT fk_fr_produit FOREIGN KEY (id_produit) REFERENCES dim_produit (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_paiements (
  id_fait_paiement BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_paiement INT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_commande INT UNSIGNED NOT NULL,
  methode_paiement VARCHAR(40) NOT NULL,
  statut_paiement VARCHAR(30) NOT NULL,
  montant DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (id_fait_paiement),
  UNIQUE KEY uq_faits_paiements_source (id_paiement),
  CONSTRAINT fk_fp_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fp_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fp_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS faits_livraisons (
  id_fait_livraison BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_livraison INT UNSIGNED NOT NULL,
  id_date INT UNSIGNED NOT NULL,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_geographie INT UNSIGNED NULL,
  id_transport INT UNSIGNED NOT NULL,
  id_commande INT UNSIGNED NOT NULL,
  cout_livraison DECIMAL(12,2) NOT NULL,
  delai_jours INT UNSIGNED NULL,
  en_retard TINYINT(1) NOT NULL,
  statut_livraison VARCHAR(40) NOT NULL,
  PRIMARY KEY (id_fait_livraison),
  UNIQUE KEY uq_faits_livraisons_source (id_livraison),
  CONSTRAINT fk_fl_date FOREIGN KEY (id_date) REFERENCES dim_date (id_date),
  CONSTRAINT fk_fl_client FOREIGN KEY (id_utilisateur) REFERENCES dim_client (id_utilisateur),
  CONSTRAINT fk_fl_geo FOREIGN KEY (id_geographie) REFERENCES dim_geographie (id_geographie),
  CONSTRAINT fk_fl_transport FOREIGN KEY (id_transport) REFERENCES dim_transport (id_transport)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS charger_entrepot;
DELIMITER //
CREATE PROCEDURE charger_entrepot()
BEGIN
  DECLARE v_date_stock INT UNSIGNED;
  SET v_date_stock = CAST(DATE_FORMAT(CURDATE(), '%Y%m%d') AS UNSIGNED);
  START TRANSACTION;

  DELETE FROM faits_ventes;
  DELETE FROM faits_trafic_web;
  DELETE FROM faits_connexions;
  DELETE FROM faits_avis;
  DELETE FROM faits_retours;
  DELETE FROM faits_paiements;
  DELETE FROM faits_livraisons;
  DELETE FROM faits_stock WHERE id_date = v_date_stock;

  INSERT INTO dim_geographie (pays, region, ville, code_postal)
  SELECT DISTINCT
    COALESCE(NULLIF(u.pays, ''), 'Inconnu'),
    COALESCE(NULLIF(u.region, ''), 'Inconnue'),
    COALESCE(NULLIF(u.ville, ''), 'Inconnue'),
    COALESCE(NULLIF(u.code_postal, ''), 'Inconnu')
  FROM `bd_décision`.utilisateurs AS u
  ON DUPLICATE KEY UPDATE id_geographie = id_geographie;

  INSERT INTO dim_date
    (id_date, date_complete, jour, jour_semaine, mois, nom_mois, trimestre, annees)
  SELECT DISTINCT
    CAST(DATE_FORMAT(x.date_evenement, '%Y%m%d') AS UNSIGNED),
    x.date_evenement,
    DAY(x.date_evenement),
    DAYOFWEEK(x.date_evenement),
    MONTH(x.date_evenement),
    MONTHNAME(x.date_evenement),
    QUARTER(x.date_evenement),
    YEAR(x.date_evenement)
  FROM (
    SELECT DATE(date_commande) AS date_evenement FROM `bd_décision`.commandes
    UNION SELECT DATE(date_ajout) FROM `bd_décision`.produits
    UNION SELECT DATE(date_visite) FROM `bd_décision`.logs_navigation
    UNION SELECT DATE(date_avis) FROM `bd_décision`.avis
    UNION SELECT DATE(date_retour) FROM `bd_décision`.retours
    UNION SELECT DATE(date_paiement) FROM `bd_décision`.paiements
    UNION SELECT DATE(COALESCE(date_expedition, date_livraison_reelle, date_livraison_estimee))
      FROM `bd_décision`.livraisons
    UNION SELECT DATE(date_inscription) FROM `bd_décision`.utilisateurs
    UNION SELECT CURDATE()
  ) AS x
  WHERE x.date_evenement IS NOT NULL
  ON DUPLICATE KEY UPDATE
    date_complete = VALUES(date_complete), jour = VALUES(jour),
    jour_semaine = VALUES(jour_semaine), mois = VALUES(mois),
    nom_mois = VALUES(nom_mois), trimestre = VALUES(trimestre),
    annees = VALUES(annees);

  INSERT INTO dim_client
    (id_utilisateur, age, tranche_age, genre, type_utilisateur,
     date_inscription, id_geographie)
  SELECT
    u.id_utilisateur,
    CASE WHEN u.date_naissance IS NULL THEN NULL
      ELSE TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) END,
    CASE
      WHEN u.date_naissance IS NULL THEN 'Inconnue'
      WHEN TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) < 18 THEN 'Moins de 18'
      WHEN TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) < 26 THEN '18-25'
      WHEN TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) < 36 THEN '26-35'
      WHEN TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) < 51 THEN '36-50'
      ELSE '51 et plus'
    END,
    COALESCE(NULLIF(u.genre, ''), 'Non renseigne'),
    COALESCE(NULLIF(u.type_utilisateur, ''), 'client'),
    DATE(u.date_inscription),
    g.id_geographie
  FROM `bd_décision`.utilisateurs AS u
  LEFT JOIN dim_geographie AS g
    ON g.pays = COALESCE(NULLIF(u.pays, ''), 'Inconnu')
   AND g.region = COALESCE(NULLIF(u.region, ''), 'Inconnue')
   AND g.ville = COALESCE(NULLIF(u.ville, ''), 'Inconnue')
   AND g.code_postal = COALESCE(NULLIF(u.code_postal, ''), 'Inconnu')
  ON DUPLICATE KEY UPDATE
    age=VALUES(age), tranche_age=VALUES(tranche_age), genre=VALUES(genre),
    type_utilisateur=VALUES(type_utilisateur),
    date_inscription=VALUES(date_inscription), id_geographie=VALUES(id_geographie);

  INSERT INTO dim_produit
    (id_produit, id_categorie, nom_categorie, nom, marque, prix, taille,
     couleur, date_ajout)
  SELECT p.id_produit, p.id_categorie, c.nom_categorie, p.nom,
    COALESCE(NULLIF(p.marque, ''), 'Sans marque'), p.prix,
    COALESCE(NULLIF(p.taille, ''), 'Non renseignee'),
    COALESCE(NULLIF(p.couleur, ''), 'Non renseignee'), DATE(p.date_ajout)
  FROM `bd_décision`.produits AS p
  INNER JOIN `bd_décision`.categories AS c ON c.id_categorie=p.id_categorie
  ON DUPLICATE KEY UPDATE
    id_categorie=VALUES(id_categorie), nom_categorie=VALUES(nom_categorie),
    nom=VALUES(nom), marque=VALUES(marque), prix=VALUES(prix),
    taille=VALUES(taille), couleur=VALUES(couleur), date_ajout=VALUES(date_ajout);

  INSERT INTO dim_transport (transporteur, mode_livraison)
  SELECT DISTINCT COALESCE(NULLIF(transporteur, ''), 'Inconnu'),
    COALESCE(NULLIF(mode_livraison, ''), 'Non renseigne')
  FROM `bd_décision`.livraisons
  ON DUPLICATE KEY UPDATE id_transport=id_transport;

  INSERT INTO dim_promotion
    (id_promo, code, description, reduction_pct, actif, date_debut, date_fin)
  SELECT id_promo, code, description, reduction, actif,
    DATE(date_debut), DATE(date_fin)
  FROM `bd_décision`.promotions
  ON DUPLICATE KEY UPDATE code=VALUES(code), description=VALUES(description),
    reduction_pct=VALUES(reduction_pct), actif=VALUES(actif),
    date_debut=VALUES(date_debut), date_fin=VALUES(date_fin);

  INSERT INTO dim_appareil (navigateur, systeme_exploitation)
  SELECT DISTINCT COALESCE(NULLIF(navigateur, ''), 'Inconnu'),
    COALESCE(NULLIF(systeme_exploitation, ''), 'Inconnu')
  FROM `bd_décision`.historique_connexions
  ON DUPLICATE KEY UPDATE id_appareil=id_appareil;

  INSERT INTO faits_ventes
    (id_detail, id_temps, id_utilisateur, id_produit, id_geographie,
     id_transport, id_promo, reduction_promo_pct, id_commande, statut, quantite, prix_unitaire,
     total1, age_au_achat)
  SELECT d.id_detail,
    CAST(DATE_FORMAT(DATE(c.date_commande), '%Y%m%d') AS UNSIGNED),
    c.id_utilisateur, d.id_produit, cl.id_geographie, tr.id_transport,
    c.id_promo, COALESCE(pr.reduction_pct, 0),
    c.id_commande, c.statut, d.quantite, d.prix_unitaire,
    d.quantite*d.prix_unitaire,
    CASE WHEN u.date_naissance IS NULL THEN NULL
      ELSE TIMESTAMPDIFF(YEAR, u.date_naissance, c.date_commande) END
  FROM `bd_décision`.details_commande AS d
  JOIN `bd_décision`.commandes AS c ON c.id_commande=d.id_commande
  JOIN `bd_décision`.utilisateurs AS u ON u.id_utilisateur=c.id_utilisateur
  JOIN dim_client AS cl ON cl.id_utilisateur=u.id_utilisateur
  JOIN dim_produit AS p ON p.id_produit=d.id_produit
  LEFT JOIN `bd_décision`.livraisons AS l
    ON l.id_livraison=(SELECT MIN(l2.id_livraison)
      FROM `bd_décision`.livraisons AS l2 WHERE l2.id_commande=c.id_commande)
  LEFT JOIN dim_transport AS tr
    ON tr.transporteur=COALESCE(NULLIF(l.transporteur, ''), 'Inconnu')
   AND tr.mode_livraison=COALESCE(NULLIF(l.mode_livraison, ''), 'Non renseigne')
  LEFT JOIN dim_promotion AS pr ON pr.id_promo=c.id_promo;

  INSERT INTO faits_stock
    (id_date, id_produit, quantite_stock, seuil_alerte, valeur_stock, en_rupture)
  SELECT v_date_stock, p.id_produit, p.stock, p.seuil_alerte,
    p.stock*p.prix, (p.stock=0)
  FROM `bd_décision`.produits AS p;

  INSERT INTO faits_trafic_web
    (id_log, id_date, id_utilisateur, id_geographie,
     page_visitee, duree_seconde, nombre_vues)
  SELECT n.id_log,
    CAST(DATE_FORMAT(DATE(n.date_visite), '%Y%m%d') AS UNSIGNED),
    n.id_utilisateur, cl.id_geographie, n.page_visitee, n.duree_seconde, 1
  FROM `bd_décision`.logs_navigation AS n
  LEFT JOIN dim_client AS cl ON cl.id_utilisateur=n.id_utilisateur;

  INSERT INTO faits_connexions
    (id_connexion, id_date, id_utilisateur, id_geographie,
     id_appareil, nombre_connexions)
  SELECT h.id_connexion,
    CAST(DATE_FORMAT(DATE(h.date_connexion), '%Y%m%d') AS UNSIGNED),
    h.id_utilisateur, cl.id_geographie, a.id_appareil, 1
  FROM `bd_décision`.historique_connexions AS h
  JOIN dim_client AS cl ON cl.id_utilisateur=h.id_utilisateur
  JOIN dim_appareil AS a
    ON a.navigateur=COALESCE(NULLIF(h.navigateur, ''), 'Inconnu')
   AND a.systeme_exploitation=COALESCE(NULLIF(h.systeme_exploitation, ''), 'Inconnu');

  INSERT INTO faits_avis
    (id_avis, id_date, id_utilisateur, id_geographie, id_produit, note)
  SELECT a.id_avis,
    CAST(DATE_FORMAT(DATE(a.date_avis), '%Y%m%d') AS UNSIGNED),
    a.id_utilisateur, cl.id_geographie, a.id_produit, a.note
  FROM `bd_décision`.avis AS a
  JOIN dim_client AS cl ON cl.id_utilisateur=a.id_utilisateur;

  INSERT INTO faits_retours
    (id_retour, id_date, id_utilisateur, id_geographie, id_produit,
     id_commande, quantite_retour, statut_retour)
  SELECT r.id_retour,
    CAST(DATE_FORMAT(DATE(r.date_retour), '%Y%m%d') AS UNSIGNED),
    c.id_utilisateur, cl.id_geographie, r.id_produit, r.id_commande,
    r.quantite, r.statut
  FROM `bd_décision`.retours AS r
  JOIN `bd_décision`.commandes AS c ON c.id_commande=r.id_commande
  JOIN dim_client AS cl ON cl.id_utilisateur=c.id_utilisateur;

  INSERT INTO faits_paiements
    (id_paiement, id_date, id_utilisateur, id_geographie, id_commande,
     methode_paiement, statut_paiement, montant)
  SELECT p.id_paiement,
    CAST(DATE_FORMAT(DATE(p.date_paiement), '%Y%m%d') AS UNSIGNED),
    c.id_utilisateur, cl.id_geographie, p.id_commande,
    p.methode_paiement, p.statut, p.montant
  FROM `bd_décision`.paiements AS p
  JOIN `bd_décision`.commandes AS c ON c.id_commande=p.id_commande
  JOIN dim_client AS cl ON cl.id_utilisateur=c.id_utilisateur;

  INSERT INTO faits_livraisons
    (id_livraison, id_date, id_utilisateur, id_geographie, id_transport,
     id_commande, cout_livraison, delai_jours, en_retard, statut_livraison)
  SELECT l.id_livraison,
    CAST(DATE_FORMAT(DATE(COALESCE(l.date_expedition, l.date_livraison_reelle,
      l.date_livraison_estimee, c.date_commande)), '%Y%m%d') AS UNSIGNED),
    c.id_utilisateur, cl.id_geographie, tr.id_transport, l.id_commande,
    l.cout_livraison,
    CASE WHEN l.date_expedition IS NOT NULL AND l.date_livraison_reelle IS NOT NULL
      THEN GREATEST(DATEDIFF(l.date_livraison_reelle, l.date_expedition), 0)
      ELSE NULL END,
    (l.date_livraison_reelle IS NOT NULL
      AND l.date_livraison_estimee IS NOT NULL
      AND l.date_livraison_reelle > l.date_livraison_estimee),
    l.statut
  FROM `bd_décision`.livraisons AS l
  JOIN `bd_décision`.commandes AS c ON c.id_commande=l.id_commande
  JOIN dim_client AS cl ON cl.id_utilisateur=c.id_utilisateur
  JOIN dim_transport AS tr
    ON tr.transporteur=COALESCE(NULLIF(l.transporteur, ''), 'Inconnu')
   AND tr.mode_livraison=COALESCE(NULLIF(l.mode_livraison, ''), 'Non renseigne');

  COMMIT;
END//
DELIMITER ;

CALL charger_entrepot();
