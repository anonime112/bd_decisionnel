# Reconstitution du dashboard Metabase

Le projet ne contient pas d'export Metabase (`.mbz`) ni de sauvegarde de sa base applicative. Le dashboard d'origine ne peut donc pas etre restaure a l'identique. Les questions ci-dessous reconstituent un tableau de bord de ventes coherent avec la base e-commerce et l'entrepot actuellement disponibles.

## Connexion a la base

Dans Metabase, ajouter une base de donnees de type **MariaDB** (ou **MySQL** si MariaDB n'est pas propose) :

- Hote : `127.0.0.1`
- Port : `3306`
- Base : `entrepot_etl`
- Utilisateur : `root`
- Mot de passe : celui configure dans XAMPP; souvent vide sur une installation locale neuve

Ne pas exposer cette connexion sur Internet. Pour un usage autre que local, creer un compte SQL dedie, avec acces en lecture seule a `entrepot_etl`.

Dans chaque question, choisir **SQL natif**, coller une seule requete, l'executer, puis enregistrer la question. Ajouter ensuite les questions a un nouveau dashboard nomme **Analyse des ventes**.

## Cartes KPI

### Chiffre d'affaires
Visualisation : nombre / devise.

```sql
SELECT ROUND(COALESCE(SUM(total1), 0), 2) AS chiffre_affaires
FROM faits_ventes;
```

### Commandes
Visualisation : nombre.

```sql
SELECT COUNT(DISTINCT id_commande) AS commandes
FROM faits_ventes;
```

### Articles vendus
Visualisation : nombre.

```sql
SELECT COALESCE(SUM(quantite), 0) AS articles_vendus
FROM faits_ventes;
```

### Panier moyen
Le panier moyen est calcule sur le total de chaque commande, et non sur la moyenne des lignes de detail.

```sql
SELECT ROUND(AVG(total_commande), 2) AS panier_moyen
FROM (
  SELECT id_commande, SUM(total1) AS total_commande
  FROM faits_ventes
  GROUP BY id_commande
) AS commandes;
```

## Graphiques

### Chiffre d'affaires par mois
Visualisation : courbe; axe X `mois`, axe Y `chiffre_affaires`.

```sql
SELECT
  DATE_FORMAT(d.date_complete, '%Y-%m') AS mois,
  ROUND(SUM(f.total1), 2) AS chiffre_affaires,
  COUNT(DISTINCT f.id_commande) AS commandes
FROM faits_ventes AS f
JOIN dim_date AS d ON d.id_date = f.id_temps
GROUP BY DATE_FORMAT(d.date_complete, '%Y-%m')
ORDER BY mois;
```

### Ventes par categorie
Visualisation : barres; axe X `categorie`, axe Y `chiffre_affaires`.

```sql
SELECT
  COALESCE(p.nom_categorie, 'Sans categorie') AS categorie,
  ROUND(SUM(f.total1), 2) AS chiffre_affaires,
  SUM(f.quantite) AS quantite
FROM faits_ventes AS f
JOIN dim_produit AS p ON p.id_produit = f.id_produit
GROUP BY COALESCE(p.nom_categorie, 'Sans categorie')
ORDER BY chiffre_affaires DESC;
```

### Ventes par région et ville
Visualisation : barres horizontales; axe Y `region` puis `ville`, valeur `chiffre_affaires`.

```sql
SELECT
  COALESCE(g.pays, 'Inconnu') AS pays,
  COALESCE(g.region, 'Inconnue') AS region,
  COALESCE(g.ville, 'Inconnue') AS ville,
  ROUND(SUM(f.total1), 2) AS chiffre_affaires,
  COUNT(DISTINCT f.id_commande) AS commandes
FROM faits_ventes AS f
JOIN dim_geographie AS g ON g.id_geographie = f.id_geographie
GROUP BY g.pays, g.region, g.ville
ORDER BY chiffre_affaires DESC;
```

### Meilleurs produits
Visualisation : tableau ou barres; limiter a 10 produits dans Metabase.

```sql
SELECT
  p.nom AS produit,
  COALESCE(p.marque, 'Sans marque') AS marque,
  SUM(f.quantite) AS quantite_vendue,
  ROUND(SUM(f.total1), 2) AS chiffre_affaires
FROM faits_ventes AS f
JOIN dim_produit AS p ON p.id_produit = f.id_produit
GROUP BY p.id_produit, p.nom, p.marque
ORDER BY chiffre_affaires DESC;
```

### Evolution des inscriptions
Visualisation : courbe; axe X `mois_inscription`, axe Y `nouveaux_clients`.

```sql
SELECT
  DATE_FORMAT(date_inscription, '%Y-%m') AS mois_inscription,
  COUNT(*) AS nouveaux_clients
FROM dim_client
WHERE date_inscription IS NOT NULL
GROUP BY DATE_FORMAT(date_inscription, '%Y-%m')
ORDER BY mois_inscription;
```

## Analyses complementaires

### Croissance mensuelle des commandes
Visualisation : courbe; compare `commandes` et `croissance_pct`.

```sql
WITH mensuel AS (
  SELECT DATE_FORMAT(d.date_complete, '%Y-%m-01') AS mois,
         COUNT(DISTINCT f.id_commande) AS commandes
  FROM faits_ventes AS f
  JOIN dim_date AS d ON d.id_date = f.id_temps
  GROUP BY DATE_FORMAT(d.date_complete, '%Y-%m-01')
), evolution AS (
  SELECT mois, commandes,
         LAG(commandes) OVER (ORDER BY mois) AS commandes_mois_precedent
  FROM mensuel
)
SELECT mois, commandes,
       ROUND(100.0 * (commandes-commandes_mois_precedent)
         / NULLIF(commandes_mois_precedent, 0), 2) AS croissance_pct
FROM evolution
ORDER BY mois;
```

### Ventes par tranche d'age et genre
Visualisation : barres empilees; axe X `tranche_age`, serie `genre`.

```sql
SELECT
  CASE
    WHEN f.age_au_achat IS NULL THEN 'Inconnue'
    WHEN f.age_au_achat < 18 THEN 'Moins de 18'
    WHEN f.age_au_achat < 26 THEN '18-25'
    WHEN f.age_au_achat < 36 THEN '26-35'
    WHEN f.age_au_achat < 51 THEN '36-50'
    ELSE '51 et plus'
  END AS tranche_age,
  c.genre,
  COUNT(DISTINCT f.id_commande) AS commandes,
  ROUND(SUM(f.total1), 2) AS chiffre_affaires
FROM faits_ventes AS f
JOIN dim_client AS c ON c.id_utilisateur=f.id_utilisateur
GROUP BY tranche_age, c.genre
ORDER BY tranche_age, c.genre;
```

### Produits en rupture ou sous le seuil
Visualisation : tableau; filtrer `niveau_stock` egal a `Rupture` ou `Alerte`.

```sql
SELECT p.nom, p.nom_categorie, s.quantite_stock, s.seuil_alerte,
       s.valeur_stock,
       CASE WHEN s.quantite_stock=0 THEN 'Rupture'
            WHEN s.quantite_stock<=s.seuil_alerte THEN 'Alerte'
            ELSE 'Disponible' END AS niveau_stock
FROM faits_stock AS s
JOIN dim_produit AS p ON p.id_produit=s.id_produit
JOIN dim_date AS d ON d.id_date=s.id_date
WHERE d.date_complete=CURRENT_DATE()
ORDER BY s.quantite_stock, p.nom;
```

### Couverture du stock par les ventes recentes
La couverture estime le nombre de jours de stock au rythme moyen des 30 derniers jours. Elle n'integre pas de delai de reapprovisionnement.

```sql
WITH ventes_30j AS (
  SELECT f.id_produit, SUM(f.quantite) AS quantite_vendue_30j
  FROM faits_ventes AS f
  JOIN dim_date AS d ON d.id_date=f.id_temps
  WHERE d.date_complete >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND d.date_complete < DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY f.id_produit
)
SELECT p.nom, s.quantite_stock,
       COALESCE(v.quantite_vendue_30j, 0) AS quantite_vendue_30j,
       ROUND(COALESCE(v.quantite_vendue_30j, 0)/30.0, 2) AS ventes_moyennes_jour,
       CASE WHEN COALESCE(v.quantite_vendue_30j, 0)=0 THEN NULL
         ELSE ROUND(s.quantite_stock/(v.quantite_vendue_30j/30.0), 1)
       END AS jours_de_couverture
FROM faits_stock AS s
JOIN dim_date AS d ON d.id_date=s.id_date AND d.date_complete=CURRENT_DATE()
JOIN dim_produit AS p ON p.id_produit=s.id_produit
LEFT JOIN ventes_30j AS v ON v.id_produit=s.id_produit
ORDER BY jours_de_couverture, p.nom;
```

### Taux de retour par produit
La mesure inclut les retours demandes/acceptes/rembourses et exclut les demandes refusees.

```sql
SELECT p.nom AS produit,
       SUM(v.quantite) AS quantite_vendue,
       COALESCE(r.quantite_retournee, 0) AS quantite_retournee,
       ROUND(100.0*COALESCE(r.quantite_retournee, 0)
         / NULLIF(SUM(v.quantite), 0), 2) AS taux_retour_pct
FROM faits_ventes AS v
JOIN dim_produit AS p ON p.id_produit=v.id_produit
LEFT JOIN (
  SELECT id_produit, SUM(quantite_retour) AS quantite_retournee
  FROM faits_retours
  WHERE LOWER(statut_retour) NOT IN ('refuse', 'refusee', 'refusé', 'refusée')
  GROUP BY id_produit
) AS r ON r.id_produit=v.id_produit
GROUP BY p.id_produit, p.nom, r.quantite_retournee
ORDER BY taux_retour_pct DESC;
```

### Notes moyennes et satisfaction

```sql
SELECT p.nom AS produit, p.nom_categorie,
       ROUND(AVG(a.note), 2) AS note_moyenne,
       COUNT(*) AS nombre_avis
FROM faits_avis AS a
JOIN dim_produit AS p ON p.id_produit=a.id_produit
GROUP BY p.id_produit, p.nom, p.nom_categorie
ORDER BY note_moyenne DESC, nombre_avis DESC;
```

### Duree moyenne de navigation par page
Les durees representent des evenements/page vues, pas une duree de session.

```sql
SELECT page_visitee, COUNT(*) AS pages_vues,
       ROUND(AVG(duree_seconde), 1) AS duree_moyenne_secondes
FROM faits_trafic_web
GROUP BY page_visitee
ORDER BY pages_vues DESC;
```

### Paiements reussis

```sql
SELECT methode_paiement,
       COUNT(*) AS nombre_paiements,
       ROUND(SUM(CASE WHEN LOWER(statut_paiement) IN ('reussi', 'réussi')
                      THEN montant ELSE 0 END), 2) AS montant_reussi,
       ROUND(100.0*SUM(CASE WHEN LOWER(statut_paiement) IN ('reussi', 'réussi')
                            THEN 1 ELSE 0 END)/NULLIF(COUNT(*), 0), 2) AS taux_reussite_pct
FROM faits_paiements
GROUP BY methode_paiement
ORDER BY montant_reussi DESC;
```

### Performance des promotions

```sql
SELECT COALESCE(p.code, 'Sans promotion') AS promotion,
       MAX(p.reduction_pct) AS reduction_pct,
       COUNT(DISTINCT f.id_commande) AS commandes,
       ROUND(SUM(f.total1), 2) AS chiffre_affaires
FROM faits_ventes AS f
LEFT JOIN dim_promotion AS p ON p.id_promo=f.id_promo
GROUP BY COALESCE(p.code, 'Sans promotion')
ORDER BY chiffre_affaires DESC;
```

### Connexions par navigateur et systeme

```sql
SELECT a.navigateur, a.systeme_exploitation,
       COUNT(*) AS connexions,
       COUNT(DISTINCT c.id_utilisateur) AS clients_connectes
FROM faits_connexions AS f
JOIN dim_appareil AS a ON a.id_appareil=f.id_appareil
JOIN dim_client AS c ON c.id_utilisateur=f.id_utilisateur
GROUP BY a.navigateur, a.systeme_exploitation
ORDER BY connexions DESC;
```

### Delai et ponctualite des livraisons

```sql
SELECT t.transporteur, t.mode_livraison,
       ROUND(AVG(l.delai_jours), 1) AS delai_moyen_jours,
       ROUND(100.0*AVG(l.en_retard), 2) AS taux_retard_pct,
       ROUND(AVG(l.cout_livraison), 2) AS cout_moyen
FROM faits_livraisons AS l
JOIN dim_transport AS t ON t.id_transport=l.id_transport
GROUP BY t.transporteur, t.mode_livraison
ORDER BY taux_retard_pct DESC;
```

### Prevision exploratoire
La requete de tendance lineaire est dans `previsions_ventes.sql`. Elle necessite au moins six mois calendaires de ventes et reste exploratoire; viser 12 mois ou plus et valider sur une periode tenue a l'ecart.

### Abandon de panier
Le taux d'abandon n'est pas calculable avec les tables disponibles: il faut enregistrer les evenements de creation/ajout panier, validation/commande, expiration et un identifiant de session. Les pages visitees ne permettent pas de deduire de maniere fiable qu'un panier a ete abandonne.

## Actualiser les donnees

Apres ajout ou modification des donnees source, demarrer MySQL dans XAMPP puis executer `run_etl.bat`. Le script met a niveau le schema sans modifier les lignes source, puis appelle `charger_entrepot()` pour recharger les faits. Pour initialiser une base locale vide avec des exemples fictifs, executer `run_etl.bat demo`; cette option ne doit jamais etre lancee sur une base de production.
