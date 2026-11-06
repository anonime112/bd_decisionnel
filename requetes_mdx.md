# Sept requetes MDX

Schema Mondrian utilise : `Schema2.xml`. Charger ce schema dans Mondrian/Schema Workbench avec la source SQL `entrepot_etl`. Les requetes supposent que le cube et ses noms de mesures sont charges tels quels. Pour analyser une periode, filtrer les membres de la dimension `date` dans l'outil OLAP.

## 1. Chiffre d'affaires et commandes par annee

```mdx
SELECT
  {[Measures].[ChiffreAffaires], [Measures].[Commandes]} ON COLUMNS,
  [date].[Calendrier].[Annee].Members ON ROWS
FROM [Ventes]
```

## 2. Chiffre d'affaires et quantites par categorie et produit

```mdx
SELECT
  {[Measures].[ChiffreAffaires], [Measures].[QuantitesVendues]} ON COLUMNS,
  NON EMPTY [produit].[Catalogue].[Produit].Members ON ROWS
FROM [Ventes]
```

## 3. Commandes et chiffre d'affaires par region et ville

```mdx
SELECT
  {[Measures].[Commandes], [Measures].[ChiffreAffaires]} ON COLUMNS,
  NON EMPTY [client].[GeographieClient].[Ville].Members ON ROWS
FROM [Ventes]
```

## 4. Panier moyen par mois

```mdx
SELECT
  {[Measures].[PanierMoyen], [Measures].[Commandes]} ON COLUMNS,
  NON EMPTY [date].[Calendrier].[Mois].Members ON ROWS
FROM [Ventes]
```

## 5. Quantites en stock et ruptures par produit

```mdx
SELECT
  {[Measures].[UnitesEnStock], [Measures].[ValeurDuStock],
   [Measures].[ProduitsEnRupture]} ON COLUMNS,
  NON EMPTY [produit].[Catalogue].[Produit].Members ON ROWS
FROM [Stocks]
```

Pour le stock courant, limiter la dimension date au dernier jour charge dans Schema Workbench ou l'interface OLAP; le cube conserve un instantane par jour.

## 6. Pages vues et duree moyenne par mois

```mdx
SELECT
  {[Measures].[PagesVues], [Measures].[DureeMoyenneSecondes]} ON COLUMNS,
  NON EMPTY [date].[Calendrier].[Mois].Members ON ROWS
FROM [TraficWeb]
```

## 7. Note moyenne et nombre d'avis par produit

```mdx
SELECT
  {[Measures].[NoteMoyenne], [Measures].[NombreAvis]} ON COLUMNS,
  NON EMPTY [produit].[Catalogue].[Produit].Members ON ROWS
FROM [Satisfaction]
```
