# Projet decisionnel e-commerce

## Probleme et objectif

La boutique dispose de donnees operationnelles dispersees entre utilisateurs, commandes, produits, paiements, livraisons, avis, retours et navigation web. Le projet construit un entrepot permettant de suivre les ventes, les stocks, la satisfaction, les retours, le trafic et les delais de livraison, puis de produire des analyses OLAP, du reporting et des previsions exploratoires.

## Sources et outils

- Base de production : MariaDB/XAMPP, base `bd_décision`.
- Entrepot : MariaDB/XAMPP, base `entrepot_etl`.
- ETL : procedure SQL `charger_entrepot()` dans `entrepot_etl.sql`, lancee par `run_etl.bat`.
- OLAP : cubes Mondrian decrits dans `Schema2.xml`.
- Reporting : Metabase, requetes SQL dans `metabase_dashboard.md`.
- Requetes OLAP : `requetes_mdx.md`.
- Previsions statistiques : requete de tendance lineaire dans `previsions_ventes.sql`.

Les anciens fichiers `.ktr` sont des prototypes incomplets et ne sont pas le chemin d'execution retenu. Le lanceur `.bat` utilise l'ETL SQL qui a ete teste sur MariaDB/XAMPP.

## Schema en etoile et granularite

| Table de faits | Grain exact | Mesures principales | Dimensions liees |
| --- | --- | --- | --- |
| `faits_ventes` | Une ligne par detail de commande (`id_detail`) | quantite, chiffre d'affaires de ligne, prix unitaire | date, client, produit, geographie, transport |
| `faits_stock` | Un produit et un instantane quotidien | quantite disponible, valeur du stock, indicateur rupture | date, produit |
| `faits_trafic_web` | Une ligne par page visitee (`id_log`) | pages vues, duree en secondes | date, client facultatif, geographie facultative |
| `faits_avis` | Un avis (`id_avis`) | note de 1 a 5 | date, client, produit, geographie |
| `faits_retours` | Une demande de retour (`id_retour`) | quantite retournee, nombre de retours | date du retour, client, produit, geographie |
| `faits_paiements` | Un paiement (`id_paiement`) | montant, nombre de paiements | date, client, geographie |
| `faits_livraisons` | Une livraison (`id_livraison`) | cout, delai en jours, retard | date d'expedition (ou date disponible), client, geographie, transport |
| `faits_connexions` | Une connexion (`id_connexion`) | nombre de connexions | date, client, geographie, appareil |

Dimensions conformes : `dim_date`, `dim_client`, `dim_geographie`, `dim_produit`, `dim_transport`, `dim_promotion` et `dim_appareil`. Le client est pseudonymise dans l'entrepot: le nom, l'email, le telephone et l'adresse exacte ne sont pas charges. L'age est calcule a partir de la date de naissance source et classe en tranches; seule la tranche et l'age sont dans l'entrepot.

## Flux ETL

1. Demarrer MySQL dans XAMPP.
2. Executer `run_etl.bat`.
3. Le script source cree ou complete les tables applicatives sans supprimer ni modifier les lignes deja presentes.
4. La procedure met a jour les dimensions et recharge les faits transactionnels. Le stock est sauvegarde chaque jour; relancer le chargement le meme jour remplace l'instantane de cette journee.
5. Actualiser les metadonnees de la base `entrepot_etl` dans Metabase.

Pour une base locale vide, utiliser `run_etl.bat demo` afin de charger le jeu fictif de `donnees_demo.sql`; ne jamais utiliser cette option sur une base de production. Le chargement ETL seul s'execute avec `run_etl.bat`.

Le chargement est teste localement sur le jeu fictif fourni. Avant un usage reel, verifier les comptes SQL, les conventions de statut et les donnees de production.

## Indicateurs et limites de mesure

- Chiffre d'affaires : somme de `quantite * prix_unitaire` au grain ligne.
- Nombre de commandes : nombre distinct de `id_commande`, jamais somme des identifiants.
- Panier moyen : somme du chiffre d'affaires divisee par le nombre distinct de commandes.
- Rupture : produit dont le stock courant est inferieur ou egal a zero. Le seuil d'alerte est une regle de gestion configurable en production.
- Taux de retour : quantites retournees / quantites vendues pour une cohorte de ventes et une periode comparables. Le script fournit la quantite retournee; les retours doivent etre associes aux ventes par commande et produit dans le reporting.
- Duree de navigation : duree enregistree pour une page, pas duree de session complete.
- Abandon de panier : non calculable avec les tables actuelles, car il manque des evenements de creation, modification, validation et expiration du panier ainsi qu'un identifiant de session. Ne pas presenter le taux comme une mesure observee.
- Stock : l'historique commence le jour du premier chargement. Les anciens niveaux de stock ne peuvent pas etre reconstruits a partir du stock courant.
- Region : utilise le champ source `utilisateurs.region`; si la production ne le renseigne pas, les analyses regionales seront incompletes.
- Prevision : la tendance lineaire est exploratoire. Pour une prevision exploitable, viser au moins 12 mois observes et confronter le resultat a une periode de validation.

## Data mining statistique

`previsions_ventes.sql` estime une tendance lineaire sur le chiffre d'affaires mensuel et projette les trois mois suivants. La requete renvoie une mention d'insuffisance tant que moins de six mois calendaires sont observes. Avec le petit jeu d'exemple, aucune conclusion de prevision n'est statistiquement defendable.
