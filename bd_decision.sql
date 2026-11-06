SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `bd_décision`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `bd_décision`;

CREATE TABLE IF NOT EXISTS utilisateurs (
  id_utilisateur INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL,
  mot_de_passe VARCHAR(255) NOT NULL,
  telephone VARCHAR(30),
  adresse VARCHAR(255),
  ville VARCHAR(100),
  region VARCHAR(100),
  code_postal VARCHAR(20),
  pays VARCHAR(100),
  date_naissance DATE,
  genre VARCHAR(30),
  type_utilisateur VARCHAR(30) NOT NULL DEFAULT 'client',
  date_inscription DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_utilisateur),
  UNIQUE KEY uq_utilisateurs_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS region VARCHAR(100) NULL,
  ADD COLUMN IF NOT EXISTS date_naissance DATE NULL,
  ADD COLUMN IF NOT EXISTS genre VARCHAR(30) NULL;

CREATE TABLE IF NOT EXISTS categories (
  id_categorie INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nom_categorie VARCHAR(100) NOT NULL,
  description TEXT,
  PRIMARY KEY (id_categorie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS produits (
  id_produit INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nom VARCHAR(150) NOT NULL,
  description TEXT,
  prix DECIMAL(12,2) NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  seuil_alerte INT UNSIGNED NOT NULL DEFAULT 5,
  couleur VARCHAR(50),
  taille VARCHAR(50),
  marque VARCHAR(100),
  id_categorie INT UNSIGNED NOT NULL,
  image_url VARCHAR(500),
  date_ajout DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_produit),
  KEY ix_produits_categorie (id_categorie),
  CONSTRAINT fk_produits_categories FOREIGN KEY (id_categorie)
    REFERENCES categories (id_categorie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE produits
  ADD COLUMN IF NOT EXISTS seuil_alerte INT UNSIGNED NOT NULL DEFAULT 5;

CREATE TABLE IF NOT EXISTS commandes (
  id_commande INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_promo INT UNSIGNED NULL,
  total DECIMAL(12,2) NOT NULL,
  statut VARCHAR(30) NOT NULL DEFAULT 'en attente',
  date_commande DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_commande),
  KEY ix_commandes_utilisateur (id_utilisateur),
  KEY ix_commandes_date (date_commande),
  CONSTRAINT fk_commandes_utilisateurs FOREIGN KEY (id_utilisateur)
    REFERENCES utilisateurs (id_utilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE commandes
  ADD COLUMN IF NOT EXISTS id_promo INT UNSIGNED NULL;

CREATE TABLE IF NOT EXISTS details_commande (
  id_detail INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_commande INT UNSIGNED NOT NULL,
  id_produit INT UNSIGNED NOT NULL,
  quantite INT UNSIGNED NOT NULL,
  prix_unitaire DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id_detail),
  KEY ix_details_commande (id_commande),
  KEY ix_details_produit (id_produit),
  CONSTRAINT fk_details_commandes FOREIGN KEY (id_commande)
    REFERENCES commandes (id_commande),
  CONSTRAINT fk_details_produits FOREIGN KEY (id_produit)
    REFERENCES produits (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS paiements (
  id_paiement INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_commande INT UNSIGNED NOT NULL,
  montant DECIMAL(12,2) NOT NULL,
  methode_paiement VARCHAR(40) NOT NULL,
  statut VARCHAR(30) NOT NULL DEFAULT 'en attente',
  date_paiement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_paiement),
  KEY ix_paiements_commande (id_commande),
  CONSTRAINT fk_paiements_commandes FOREIGN KEY (id_commande)
    REFERENCES commandes (id_commande)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS livraisons (
  id_livraison INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_commande INT UNSIGNED NOT NULL,
  transporteur VARCHAR(100),
  mode_livraison VARCHAR(100),
  cout_livraison DECIMAL(10,2) NOT NULL DEFAULT 0,
  date_expedition DATETIME NULL,
  date_livraison_estimee DATETIME NULL,
  date_livraison_reelle DATETIME NULL,
  statut VARCHAR(40) NOT NULL DEFAULT 'en préparation',
  PRIMARY KEY (id_livraison),
  KEY ix_livraisons_commande (id_commande),
  CONSTRAINT fk_livraisons_commandes FOREIGN KEY (id_commande)
    REFERENCES commandes (id_commande)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS avis (
  id_avis INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_utilisateur INT UNSIGNED NOT NULL,
  id_produit INT UNSIGNED NOT NULL,
  note TINYINT UNSIGNED NOT NULL,
  commentaire TEXT,
  date_avis DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_avis),
  KEY ix_avis_utilisateur (id_utilisateur),
  KEY ix_avis_produit (id_produit),
  CONSTRAINT ck_avis_note CHECK (note BETWEEN 1 AND 5),
  CONSTRAINT fk_avis_utilisateurs FOREIGN KEY (id_utilisateur)
    REFERENCES utilisateurs (id_utilisateur),
  CONSTRAINT fk_avis_produits FOREIGN KEY (id_produit)
    REFERENCES produits (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS retours (
  id_retour INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_commande INT UNSIGNED NOT NULL,
  id_produit INT UNSIGNED NOT NULL,
  quantite INT UNSIGNED NOT NULL DEFAULT 1,
  raison TEXT,
  statut VARCHAR(30) NOT NULL DEFAULT 'demandé',
  date_retour DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_retour),
  KEY ix_retours_commande (id_commande),
  KEY ix_retours_produit (id_produit),
  CONSTRAINT fk_retours_commandes FOREIGN KEY (id_commande)
    REFERENCES commandes (id_commande),
  CONSTRAINT fk_retours_produits FOREIGN KEY (id_produit)
    REFERENCES produits (id_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promotions (
  id_promo INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(30) NOT NULL,
  description TEXT,
  reduction DECIMAL(5,2) NOT NULL,
  date_debut DATETIME NOT NULL,
  date_fin DATETIME NOT NULL,
  actif TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_promo),
  UNIQUE KEY uq_promotions_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS historique_connexions (
  id_connexion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_utilisateur INT UNSIGNED NOT NULL,
  adresse_ip VARCHAR(45),
  navigateur VARCHAR(255),
  systeme_exploitation VARCHAR(100),
  date_connexion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_connexion),
  KEY ix_connexions_utilisateur_date (id_utilisateur, date_connexion),
  CONSTRAINT fk_connexions_utilisateurs FOREIGN KEY (id_utilisateur)
    REFERENCES utilisateurs (id_utilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS logs_navigation (
  id_log BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_utilisateur INT UNSIGNED NULL,
  page_visitee VARCHAR(255) NOT NULL,
  duree_seconde INT UNSIGNED NOT NULL DEFAULT 0,
  date_visite DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_log),
  KEY ix_navigation_date (date_visite),
  KEY ix_navigation_utilisateur_date (id_utilisateur, date_visite),
  CONSTRAINT fk_navigation_utilisateurs FOREIGN KEY (id_utilisateur)
    REFERENCES utilisateurs (id_utilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

