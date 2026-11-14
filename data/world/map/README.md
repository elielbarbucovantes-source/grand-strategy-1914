# Atlas historique — données cartographiques

## État

La répartition éditoriale cible de **90 régions terrestres** est enregistrée dans [`tables/region_plan.csv`](tables/region_plan.csv), avec IDs stables provisoires `region_001` à `region_090`, zone, nom français et souveraineté de 1914. Cette table n’est pas une carte : aucune géométrie n’y est jointe et les régions ne sont pas encore cartographiquement construites. L’atlas n’est donc pas validé ni utilisable comme carte jouable.

Le plafond validé est de 100 régions terrestres. Les 90 identifiants sont réservés par le plan; leur géométrie doit provenir de données historiques vérifiables et partager une topologie cohérente. Ne pas attribuer à la table d’inventaire une précision qui n’existe pas encore.

## Fichiers et formats prévus

- `tables/region_plan.csv` : registre éditorial des 90 régions et souverainetés prévues, sans polygones.
- `regions.geojson` : à créer après dérivation documentée des géométries (RFC 7946, WGS 84).
- `adjacency.json`, `cities.json`, `terrain.json`, `infrastructure.json`, `maritime_zones.geojson` : à créer depuis des sources identifiées et validées.
- `sources/README.md` : registre des sources, licences, périodes, limites et transformations.

Les propositions de nom et d’affectation de souveraineté reproduisent la mission de construction et les décisions déjà validées. Les conventions plus précises de frontière, villes, relief et infrastructures restent en attente. Le manifeste doit distinguer géométrie dérivée, arbitrage historique et simplification de jeu.

## Import et édition

Les sources originales ne doivent pas être écrasées. Conserver une copie ou une référence versionnée sous `sources/`, avec licence/attribution et somme de contrôle si la redistribution est autorisée. Importer vers une couche de travail, reprojeter vers EPSG:4326 uniquement à l’export GeoJSON, normaliser les noms et IDs, puis faire valider la topologie avant publication. Les traitements doivent pouvoir être relancés et documenter chaque fusion/découpe. Ne jamais créer de limites rectangulaires ou interpolées pour remplir une lacune de source.

Le schéma structurel est [`data/schemas/map.schema.json`](../../schemas/map.schema.json). Les contrôles géométriques et de couverture ne sont pas encore exécutés sur des données, car aucune géométrie de région n’est présente.

Voir [`docs/map/ATLAS_BUILD_STATUS.md`](../../../docs/map/ATLAS_BUILD_STATUS.md) pour l’état, les sources candidates et les livrables encore bloqués.
