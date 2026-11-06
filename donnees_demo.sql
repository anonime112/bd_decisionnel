-- Jeu de demonstration uniquement: les donnees sont fictives.
-- Ne pas executer sur une base de production.
SET NAMES utf8mb4;
USE `bd_décision`;

INSERT INTO utilisateurs
  (id_utilisateur, nom, prenom, email, mot_de_passe, telephone, adresse,
   ville, region, code_postal, pays, date_naissance, genre, type_utilisateur,
   date_inscription)
VALUES
  (1, 'Martin', 'Lea', 'lea.martin@example.invalid', 'demo-not-a-real-password',
   '0100000001', '1 rue des Fleurs', 'Lyon', 'Auvergne-Rhone-Alpes', '69001',
   'France', '1995-04-10', 'femme', 'client', '2024-01-15 10:00:00'),
  (2, 'Bernard', 'Noah', 'noah.bernard@example.invalid', 'demo-not-a-real-password',
   '0100000002', '2 avenue du Parc', 'Lille', 'Hauts-de-France', '59000',
   'France', '1988-09-22', 'homme', 'client', '2024-03-20 14:30:00')
ON DUPLICATE KEY UPDATE
  nom=VALUES(nom), prenom=VALUES(prenom), email=VALUES(email),
  mot_de_passe=VALUES(mot_de_passe), telephone=VALUES(telephone),
  adresse=VALUES(adresse), ville=VALUES(ville), region=VALUES(region),
  code_postal=VALUES(code_postal), pays=VALUES(pays),
  date_naissance=VALUES(date_naissance), genre=VALUES(genre),
  type_utilisateur=VALUES(type_utilisateur),
  date_inscription=VALUES(date_inscription);

INSERT INTO categories (id_categorie, nom_categorie, description)
VALUES
  (1, 'Vetements', 'Produits de demonstration.'),
  (2, 'Accessoires', 'Produits de demonstration.')
ON DUPLICATE KEY UPDATE nom_categorie=VALUES(nom_categorie),
  description=VALUES(description);

INSERT INTO produits
  (id_produit, nom, description, prix, stock, seuil_alerte, couleur, taille,
   marque, id_categorie, image_url, date_ajout)
VALUES
  (1, 'T-shirt demo', 'Produit fictif pour valider les analyses.',
   19.90, 2, 5, 'bleu', 'M', 'Demo', 1, NULL, '2024-01-10 09:00:00'),
  (2, 'Sac demo', 'Produit fictif pour valider les analyses.',
   34.50, 12, 5, 'noir', 'Unique', 'Demo', 2, NULL, '2024-02-05 09:00:00')
ON DUPLICATE KEY UPDATE nom=VALUES(nom), description=VALUES(description),
  prix=VALUES(prix), stock=VALUES(stock), seuil_alerte=VALUES(seuil_alerte),
  couleur=VALUES(couleur), taille=VALUES(taille), marque=VALUES(marque),
  id_categorie=VALUES(id_categorie), image_url=VALUES(image_url),
  date_ajout=VALUES(date_ajout);

INSERT INTO commandes
  (id_commande, id_utilisateur, id_promo, total, statut, date_commande)
VALUES
  (1001, 1, NULL, 39.80, 'livree', '2024-04-02 11:15:00'),
  (1002, 2, 1, 34.50, 'expediee', '2024-05-18 16:45:00')
ON DUPLICATE KEY UPDATE id_utilisateur=VALUES(id_utilisateur),
  id_promo=VALUES(id_promo), total=VALUES(total), statut=VALUES(statut),
  date_commande=VALUES(date_commande);

INSERT INTO details_commande
  (id_detail, id_commande, id_produit, quantite, prix_unitaire)
VALUES (1, 1001, 1, 2, 19.90), (2, 1002, 2, 1, 34.50)
ON DUPLICATE KEY UPDATE id_commande=VALUES(id_commande),
  id_produit=VALUES(id_produit), quantite=VALUES(quantite),
  prix_unitaire=VALUES(prix_unitaire);

INSERT INTO paiements
  (id_paiement, id_commande, montant, methode_paiement, statut, date_paiement)
VALUES
  (1, 1001, 39.80, 'carte', 'reussi', '2024-04-02 11:20:00'),
  (2, 1002, 34.50, 'paypal', 'reussi', '2024-05-18 16:50:00')
ON DUPLICATE KEY UPDATE id_commande=VALUES(id_commande),
  montant=VALUES(montant), methode_paiement=VALUES(methode_paiement),
  statut=VALUES(statut), date_paiement=VALUES(date_paiement);

INSERT INTO livraisons
  (id_livraison, id_commande, transporteur, mode_livraison, cout_livraison,
   date_expedition, date_livraison_estimee, date_livraison_reelle, statut)
VALUES
  (1, 1001, 'Demo Express', 'standard', 4.90,
   '2024-04-03 08:00:00', '2024-04-06 18:00:00', '2024-04-05 15:00:00', 'livre'),
  (2, 1002, 'Demo Relais', 'point relais', 3.50,
   '2024-05-19 08:00:00', '2024-05-24 18:00:00', NULL, 'expedie')
ON DUPLICATE KEY UPDATE id_commande=VALUES(id_commande),
  transporteur=VALUES(transporteur), mode_livraison=VALUES(mode_livraison),
  cout_livraison=VALUES(cout_livraison), date_expedition=VALUES(date_expedition),
  date_livraison_estimee=VALUES(date_livraison_estimee),
  date_livraison_reelle=VALUES(date_livraison_reelle), statut=VALUES(statut);

INSERT INTO avis
  (id_avis, id_utilisateur, id_produit, note, commentaire, date_avis)
VALUES
  (1, 1, 1, 5, 'Avis fictif de demonstration.', '2024-04-08 12:00:00'),
  (2, 2, 2, 4, 'Avis fictif de demonstration.', '2024-05-28 12:00:00')
ON DUPLICATE KEY UPDATE id_utilisateur=VALUES(id_utilisateur),
  id_produit=VALUES(id_produit), note=VALUES(note),
  commentaire=VALUES(commentaire), date_avis=VALUES(date_avis);

INSERT INTO retours
  (id_retour, id_commande, id_produit, quantite, raison, statut, date_retour)
VALUES
  (1, 1002, 2, 1, 'Exemple fictif de retour.', 'demande', '2024-05-25 10:00:00')
ON DUPLICATE KEY UPDATE id_commande=VALUES(id_commande),
  id_produit=VALUES(id_produit), quantite=VALUES(quantite),
  raison=VALUES(raison), statut=VALUES(statut), date_retour=VALUES(date_retour);

INSERT INTO promotions
  (id_promo, code, description, reduction, date_debut, date_fin, actif)
VALUES
  (1, 'DEMO10', 'Promotion fictive de demonstration.', 10.00,
   '2024-01-01 00:00:00', '2025-01-01 00:00:00', 1)
ON DUPLICATE KEY UPDATE description=VALUES(description),
  reduction=VALUES(reduction), date_debut=VALUES(date_debut),
  date_fin=VALUES(date_fin), actif=VALUES(actif);

INSERT INTO historique_connexions
  (id_connexion, id_utilisateur, adresse_ip, navigateur,
   systeme_exploitation, date_connexion)
VALUES
  (1, 1, '192.0.2.10', 'Demo Browser', 'Demo OS', '2024-04-02 10:50:00'),
  (2, 2, '192.0.2.20', 'Demo Browser', 'Demo OS', '2024-05-18 16:20:00')
ON DUPLICATE KEY UPDATE id_utilisateur=VALUES(id_utilisateur),
  adresse_ip=VALUES(adresse_ip), navigateur=VALUES(navigateur),
  systeme_exploitation=VALUES(systeme_exploitation),
  date_connexion=VALUES(date_connexion);

INSERT INTO logs_navigation
  (id_log, id_utilisateur, page_visitee, duree_seconde, date_visite)
VALUES
  (1, 1, '/produits/t-shirt-demo', 95, '2024-04-02 10:52:00'),
  (2, 1, '/panier', 42, '2024-04-02 10:54:00'),
  (3, 2, '/produits/sac-demo', 130, '2024-05-18 16:22:00'),
  (4, 2, '/commande/confirmation', 35, '2024-05-18 16:30:00'),
  (5, NULL, '/accueil', 20, '2024-05-20 09:00:00')
ON DUPLICATE KEY UPDATE id_utilisateur=VALUES(id_utilisateur),
  page_visitee=VALUES(page_visitee), duree_seconde=VALUES(duree_seconde),
  date_visite=VALUES(date_visite);
