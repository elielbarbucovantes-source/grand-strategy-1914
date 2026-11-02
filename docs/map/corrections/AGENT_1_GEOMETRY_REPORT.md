# Rapport de correction géométrique — Atlas 1914

## État de la livraison

Le worktree dédié est `/tmp/opencode/gs1914-geometry-v2`, branche `fix/map-geometry-v2`, issu du commit `b5a07aee2d6d545ebf42ec682ec9d0dd25353387`. La branche `audit/map-1914` et `fix/map-topology-v2` n'ont pas été modifiées ni fusionnées. Les fichiers sources des deux lots sont conservés sans modification.

Les 90 géométries fournies par les lots ont été inspectées. Avant correction, l'audit indépendant confirme 90 géométries OGC valides, 15 micro-chevauchements au-dessus du seuil strict de `1e-10 deg²`, une composante incorrecte de Van dans `region_088`, et Strumica dans `region_074`.

## Corrections réalisables et limites

### Région 088 — Saray de Tekirdağ

La source officielle geoBoundaries TUR ADM2 a été téléchargée dans l'environnement temporaire, puis le `shapeID` `54988432B91991689904144` a été vérifié comme l'unique district Saray de Tekirdağ. La géométrie est valide, couvre le point représentatif `[27.9001, 41.4436]`, et mesure environ `684.55 km²` dans EPSG:3035. L'assemblage lui attribue cette géométrie dans `region_088`; la composante isolée à Van est retirée. Avant l'union, le recouvrement existant est retiré des régions 088 et 089 dans l'aire de Saray, ce qui évite un doublon de territoire.

Source : geoBoundaries v6, Turquie ADM2, jeu de données représenté en 2021, ODbL 1.0 d'après le catalogue officiel courant. Fichier `geoBoundaries-TUR-ADM2.geojson`, révision `9469f09` du dépôt geoBoundaries. La licence de la version actuelle diffère de la mention CC BY 4.0 figurant dans les anciens handoffs; le livrable doit être revu avant redistribution commerciale et l'attribution ODbL conservée.

### 15 micro-chevauchements

Le script de construction arrondit à six décimales avant la réparation et traite par différence déterministe `B := B - A`, dans l'ordre des IDs. Il refuse tout chevauchement dont l'aire dépasse `1e-6 deg²`; le seuil de validation officiel reste inchangé à `1e-10 deg²`. Les surfaces, centroïdes, points représentatifs, boîtes englobantes et nombres de parties/sommets sont recalculés après correction.

La soustraction déterministe conserve la géométrie A et ne retire de B que les intersections mesurées après arrondi. Comme plusieurs paires présentent des fragments distincts, une réparation peut générer plus d'une opération par paire; aucune autre limite n'est volontairement déplacée. Le contrôle strict examine ensuite toutes les 4 005 paires.

### Strumica

Le point `[22.6427, 41.4378]` est signalé par les sources historiques de l'audit comme bulgare après le traité de Bucarest (10 août 1913), avant la cession de 1919. Le GeoJSON national Kavanagh/UCD téléchargé ne permet pas de tracer le saillant : son polygone national « Serbia » recouvre le point et la couche est généralisée, tandis que la frontière demandée concerne les régions infra-nationales 072 et 074. La couche source REGIS Yougoslavie 1948–1954 employée pour `region_074` n'est pas incluse et ne peut pas être découpée de façon documentée sans une référence vectorielle régionale historique adaptée. Aucune géométrie ne doit donc être déplacée par approximation.

## Sources précises manquantes pour les quatre lacunes

1. **Finlande / Olonets, `region_052` / `region_064`**, secteur Suojärvi, point d'audit `[32.3258, 62.6315]`, lacune annoncée `662.47 km²` : couche `REGIS_Finland.gpkg`, couche interne `REGIS_Finland_L1_1870-1918`, plus `Russian Empire 1897 - Provinces` (GeoPackage RISTAT, couche `provinces_1897`, gouvernements de Saint-Pétersbourg et Olonets). Sources/catalogues : REGIS, DOI `10.1007/978-3-032-14932-9_3`; RISTAT, DOI `10.34894/NQOASN`, DataverseNL. Format attendu : GeoPackage, géométries polygonales, CRS source conservé (la documentation indique EPSG:3035 pour REGIS et EPSG:4326 pour RISTAT). Les deux géométries sources exactes de la frontière et un éventuel masque d'eau de référence sont requis.
2. **Tripoint Bucovine / Bessarabie / Moldavie, `region_040` / `region_062` / `region_071`**, secteur Khotin/Herța, point `[26.1997, 48.3030]`, lacune annoncée `225.88 km²` : `REGIS_Austria_Hungary.gpkg`, couche `REGIS_Austria_Hungary_L3_1908-1914` (Bucovine), RISTAT `Russian Empire 1897 - Provinces`, couche `provinces_1897` (Bessarabie), et `REGIS_Romania.gpkg`, couches `REGIS_Romania_L1_1879-1913` et `REGIS_Romania_L2_1879-1913` (Moldavie/Herța). Sources/catalogues : REGIS, DOI `10.1007/978-3-032-14932-9_3`; RISTAT, DOI `10.34894/NQOASN`. Formats attendus : GeoPackages; CRS REGIS EPSG:3035 et RISTAT EPSG:4326. Les polygones sources d'origine, avant alignement inter-lots, sont requis pour identifier les unités responsables du vide.
3. **Pasvik nord, `region_047` / `region_065`**, point `[30.5256, 69.5879]`, lacune annoncée `117.05 km²` : couche norvégienne d'origine geoBoundaries `gb_nor_adm1.geojson` / « Norway ADM1 », ou sa source officielle Kartverket « Administrative units — counties/fylker » (métadonnées Geonorge); RISTAT `Russian Empire 1897 - Provinces`, couche `provinces_1897` (gouvernement d'Arkhangelsk/Petsamo). Catalogue geoBoundaries courant : API `gbOpen/NOR/ADM1`, GeoJSON WGS84; source officielle Kartverket liée par ses métadonnées. Format attendu : GeoJSON WGS84 pour la couche geoBoundaries/Kartverket et GeoPackage EPSG:4326 pour RISTAT. Les fichiers utilisés lors de la construction, incluant la version originale geoBoundaries et son identification de couche, restent requis.
4. **Pasvik sud, `region_047` / `region_065`**, point `[29.7994, 69.4143]`, lacune annoncée `92.09 km²` : mêmes couches et formats que pour Pasvik nord.

Le dépôt ne documente pas de millésime précis pour le geoBoundaries NOR consommé dans le build; l'API actuelle renvoie des limites représentées en 2022. Cette version actuelle ne peut pas se substituer sans contrôle à la géométrie exacte présente avant alignement. DataverseNL/RISTAT a été consulté; le téléchargement binaire a échoué dans cet environnement. REGIS est identifié par DOI et noms de couches, mais le jeu vectoriel n'a pas été récupéré.

## Résultats de validation et anomalies restantes

- Inventaire assemblé : `90/90`; IDs dupliqués : `0`.
- Géométries OGC valides : `90/90`.
- Intersections strictes supérieures à `1e-10 deg²` : `0` sur les 4 005 paires. Le seuil officiel n'a pas été modifié.
- Superficie recalculée après traitements : `10 026 551,20 km²`.
- Région 088 : bounding box `(26.693293, 40.723000, 28.701899, 41.609741)`, une composante; aire recalculée `7 933,51 km²`; le point Saray est inclus et le point Van est exclu.
- Points représentatifs : validés par le validateur de construction sur les 90 régions.
- `tools/map/validate_atlas.py` : succès, 90/90 géométries valides; affiche l'avertissement de couverture en l'absence d'une emprise de référence.
- `tools/map/validate_geometry.py` : inventaire, géométries, superficies, points représentatifs et chevauchements passent; il échoue explicitement sur Strumica, qui reste dans 074. Ses tests ponctuels détectent 2/4 sentinelles de coutures non couvertes, mais ceci ne constitue pas une validation aréale des lacunes.
- `docs/map/audit/validate_global_atlas.py --strict` : échoue sur les lots d'origine (3 erreurs bloquantes et 2 importantes). Ce script relit les fichiers des lots via Git et ne teste pas les fichiers assemblés; ses résultats d'avant intégration sont donc attendus et rapportés sans les masquer.

**Restent non corrigés faute de géométries historiques suffisantes :** l'attribution de Strumica et les quatre surfaces de lacune répertoriées dans MAJ-004 (662.47, 225.88, 117.05 et 92.09 km²). Les emplacements précis, couches, formats et catalogues sont indiqués plus haut. En particulier, les seules références disponibles pour Strumica établissent la situation diplomatique 1913–1919, mais le contrôle de Kavanagh/UCD à l'échelle nationale classe le point dans son polygone Serbie; aucune limite interne régionale fiable n'est ainsi dérivable.

Le rapport d'audit donne deux séries incompatibles de valeurs pour la région 088 (6 704.61 km² et 6 450.65 km²), tandis que le GeoJSON livré contient une aire initiale de 8 188.30 km². L'aire présentée ici est recalculée directement de la géométrie assemblée et reprojetée en EPSG:3035; les valeurs d'audit ne sont pas reprises comme métriques finales.

## Commandes reproductibles

Après avoir obtenu le GeoJSON officiel geoBoundaries TUR ADM2 :

`python3 tools/map/build_geometry.py --saray-source /chemin/geoBoundaries-TUR-ADM2.geojson`

Puis exécuter :

`python3 tools/map/validate_geometry.py`

`python3 tools/map/validate_atlas.py`

Le validateur global `docs/map/audit/validate_global_atlas.py` est un audit des deux lots via des refs Git, non un validateur des fichiers canoniques assemblés. Ses résultats antérieurs doivent rester distincts des validations des livrables intégrés.
