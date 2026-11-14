# HANDOFF — Agent 2 : Construction Cartographique Complète des 40 Régions (01/01/1914)

## 1. Résumé Exécutif

La mission cartographique de l'**Agent 2** sur la branche `agent-2` est **intégralement achevée et validée**.

Les **40 régions** du périmètre de l'Agent 2 (`Scandinavie` : 8, `Europe orientale` : 18, `Balkans` : 10, `Territoires ottomans européens` : 4) ont été construites sous forme de véritables géométries vectorielles historiques (`Polygon` / `MultiPolygon` en `EPSG:4326`), accompagnées de l'ensemble de leurs métadonnées, de leur graphe d'adjacence (interne, détroits et interfaces avec l'Agent 1), de leurs villes stratégiques, de leur géographie physique, de leurs infrastructures de 1914 et de leurs zones maritimes.

Aucun fichier en dehors de `data/world/map/build/agent_2/` n'a été modifié. Aucune branche n'a été fusionnée.

---

## 2. Livrables Produits dans `data/world/map/build/agent_2/`

1. **`regions.geojson`** : `FeatureCollection` GeoJSON (`EPSG:4326` / `CRS84`) des 40 régions construites (`etat_geometrie = "construite"`), 100 % valides selon les règles OGC, orientées RFC 7946, sans aucun chevauchement interne (`0.0 deg²`) et sans aucun chevauchement avec les 50 régions de l'Agent 1 (`0.0 deg²`).
2. **`regions.json`** : Métadonnées complètes des 40 régions selon les conventions exactes de l'Agent 1 (`id`, `name_fr`, `name_key`, `zone`, `sovereign_1914`, `initial_sovereign_id`, `etat_geometrie`, `relief_categories`, `importance_dimensions`, `has_coastline`, `area_km2`, `centroid_lon_lat`, `representative_point_lon_lat`, `city_ids`, `adjacent_region_ids`, `external_adjacent_region_ids`, `maritime_zone_ids`, `historical_admin_units`, `source_layer`, `source_refs`, `notes`, `bbox`, `polygon_parts_count`, `vertex_count`, `maritime_facades`, `major_rivers`, `mountain_ranges`, `approximations`).
3. **`adjacency.json`** :
   - **69 arêtes terrestres internes** (`edges`) symétriques avec longueur de frontière partagée en km (`shared_border_km`), obstacles naturels (`natural_obstacles`) et passages historiques documentés (`documented_passages`) ;
   - **8 passages de détroits stratégiques** (`strait_crossings` : Øresund, Belts danois, Mer d'Åland, Détroit d'Irbe / Moonsund, Détroit de Kertch, Rion-Antirion / Canal de Corinthe, Bosphore, Dardanelles) ;
   - **17 interfaces terrestres externes** (`external_perimeter_interfaces`) avec les régions frontalières de l'Agent 1.
4. **`cities.json`** : `FeatureCollection` GeoJSON et liste structurée de **72 villes et sites stratégiques** de 1914 (au moins 1 par région), incluant les **11 capitales d'État** du périmètre (`Copenhague`, `Christiania`, `Stockholm`, `Saint-Pétersbourg`, `Bucarest`, `Sofia`, `Belgrade`, `Cetinje`, `Durrës`, `Athènes`, `Constantinople`), toutes vérifiées géométriquement à l'intérieur strict de leur polygone régional.
5. **`terrain.json`** : Relief catégorisé des 40 régions (`plains`, `forests`, `mountains`, `hills`, `marshes`), façades maritimes, catalogue de **32 grands fleuves** et **11 chaînes de montagnes** avec cols stratégiques.
6. **`infrastructure.json`** : Réseau stratégique de 1914 comprenant **53 axes ferroviaires majeurs**, **37 grands ports** et **33 places fortes / systèmes fortifiés** historiques de 1914.
7. **`maritime_zones.json`** : `FeatureCollection` GeoJSON et catalogue de **16 zones maritimes intermédiaires** découpées sur le trait de côte réel des 90 régions européennes, avec leurs détroits contrôlés et leurs régions côtières adjacentes.
8. **`README.md`** & **`sources/README.md`** : Documentation complète de l'architecture des données, des sources, des périodes et des licences.
9. **`HANDOFF.md`** : Présent rapport de livraison et de passation.
10. **`validate_agent_2.py`** : Script de validation exécutable couvrant l'intégralité des contrôles géométriques, topologiques, inter-lots et historiques.

---

## 3. Interfaces Frontalières avec l'Agent 1 (17 connexions terrestres vérifiées)

L'alignement géométrique avec `data/world/map/build/agent_1/regions.geojson` a été réalisé en `EPSG:3035` puis vérifié en `EPSG:4326` : les micro-interstices de numérisation entre RISTAT 1897 et REGIS ont été comblés du côté de l'Agent 2, puis l'empreinte exacte des 50 polygones de l'Agent 1 a été soustraite pour garantir une couture parfaite (`0.0` chevauchement et contact topologique continu).

| ID Interface | Région Agent 2 | Région Agent 1 | Frontière partagée (km) | Statut dans `agent_1/adjacency.json` |
| :--- | :--- | :--- | :---: | :--- |
| `ext_adj_region_044_region_029` | `region_044` (Danemark) | `region_029` (Allemagne du Nord-Ouest) | **88,19 km** | Déclarée (1/16) |
| `ext_adj_region_054_region_026` | `region_054` (Pays baltes du Sud) | `region_026` (Prusse-Orientale) | **181,59 km** | Déclarée (2/16) |
| `ext_adj_region_056_region_026` | `region_056` (Pologne russe orientale) | `region_026` (Prusse-Orientale) | **368,87 km** | **Omise dans la liste déclarative de l'Agent 1** (voir section 5) |
| `ext_adj_region_055_region_026` | `region_055` (Pologne russe occidentale) | `region_026` (Prusse-Orientale) | **55,79 km** | Déclarée (3/16) |
| `ext_adj_region_055_region_027` | `region_055` (Pologne russe occidentale) | `region_027` (Prusse-Occidentale et Posnanie) | **423,96 km** | Déclarée (4/16) |
| `ext_adj_region_055_region_030` | `region_055` (Pologne russe occidentale) | `region_030` (Silésie) | **168,51 km** | Déclarée (5/16) |
| `ext_adj_region_055_region_040` | `region_055` (Pologne russe occidentale) | `region_040` (Galicie et Bucovine) | **264,53 km** | Déclarée (6/16) |
| `ext_adj_region_056_region_040` | `region_056` (Pologne russe orientale) | `region_040` (Galicie et Bucovine) | **263,41 km** | Déclarée (7/16) |
| `ext_adj_region_058_region_040` | `region_058` (Ukraine occidentale) | `region_040` (Galicie et Bucovine) | **435,39 km** | Déclarée (8/16) |
| `ext_adj_region_062_region_040` | `region_062` (Bessarabie) | `region_040` (Galicie et Bucovine) | **36,02 km** | Déclarée (9/16) |
| `ext_adj_region_071_region_040` | `region_071` (Roumanie septentrionale) | `region_040` (Galicie et Bucovine) | **294,97 km** | Déclarée (10/16) |
| `ext_adj_region_071_region_042` | `region_071` (Roumanie septentrionale) | `region_042` (Transylvanie) | **267,72 km** | Déclarée (11/16) |
| `ext_adj_region_070_region_042` | `region_070` (Roumanie méridionale) | `region_042` (Transylvanie) | **440,64 km** | Déclarée (12/16) |
| `ext_adj_region_070_region_041` | `region_070` (Roumanie méridionale) | `region_041` (Hongrie centrale et orientale) | **86,44 km** | Déclarée (13/16) |
| `ext_adj_region_074_region_041` | `region_074` (Serbie) | `region_041` (Hongrie centrale et orientale) | **217,60 km** | Déclarée (14/16) |
| `ext_adj_region_074_region_043` | `region_074` (Serbie) | `region_043` (Croatie-Slavonie, Bosnie-Herzégovine et Dalmatie) | **451,83 km** | Déclarée (15/16) |
| `ext_adj_region_075_region_043` | `region_075` (Monténégro) | `region_043` (Croatie-Slavonie, Bosnie-Herzégovine et Dalmatie) | **310,50 km** | Déclarée (16/16) |

---

## 4. Approximations Historiques et Cartographiques Documentées

Conformément aux consignes, chaque approximation méthodologique est explicitement documentée :

1. **Gouvernement de Kholm (1912) au sein de `region_056` (Pologne russe orientale)** :
   - Les couches vectorielles de l'Empire russe (`ristat_1897_provinces.gpkg`) reflètent l'état administratif de 1897 (gouvernements de Lublin, Siedlce, Łomża et Suwałki). En 1912, le gouvernement de Kholm (Chełm) a été créé à partir des districts orientaux de Siedlce et de Lublin, et le reste de Siedlce a été partagé entre Lublin et Łomża. Comme `region_056` regroupe simultanément Lublin, Siedlce/Kholm, Łomża et Suwałki, l'enveloppe extérieure de `region_056` est mathématiquement identique entre 1897 et 1914.
2. **Limite interne serbo-monténégrine dans le Sandjak et en Métochie (`region_074` / `region_075`)** :
   - La frontière internationale extérieure de 1914 avec l'Autriche-Hongrie (`region_041`, `region_043`, excluant les Bouches de Cattaro) et l'Albanie (`region_076`) est restituée avec exactitude. Pour le partage interne de 1913 entre la Serbie (`region_074`) et le Monténégro (`region_075`), le Monténégro intègre le Sandjak occidental (Pljevlja, Bijelo Polje, Berane) ainsi que Plav et Gusinje selon le tracé administratif vérifiable de REGIS (`Crna gora`), tandis que l'ensemble de l'unité `Kosovo i Metohija` (incluant Peć/Đakovica) est conservé dans `region_074` afin de ne pas tracer de coupure arbitraire non sourcée.
3. **Basse Maritsa entre la Bulgarie orientale (`region_073`) et les régions ottomanes d'Edirne (`region_089`) et Gallipoli (`region_090`)** :
   - Entre le traité de Constantinople (29 septembre 1913) et la convention de Sofia (septembre 1915), l'Empire ottoman détenait sur la rive droite de la Maritsa le faubourg de Karaağaç et une bande autour de Dimetoka (Didymoteicho). Les couches vectorielles disponibles (`REGIS_Greece_L0_1928-1940` et `gb_tur_adm2.geojson`) suivent le talweg de la basse Maritsa ; ce tracé fluvial continu a été retenu pour éviter tout découpage manuel artificiel.
4. **Versant oriental de l'Oural dans les gouvernements de Perm (`region_067`) et d'Orenbourg (`region_068`)** :
   - En 1914, les gouvernements de Perm et d'Orenbourg s'étendaient administrativement au-delà de la ligne de partage des eaux de l'Oural (incluant Ekaterinbourg et Tcheliabinsk). Conformément à `region_plan.csv` qui définit `region_067` et `region_068` par ces gouvernements historiques, leurs limites intégrales issues de RISTAT 1897 ont été conservées.

---

## 5. Incompatibilités ou Points d'Attention lors de la Fusion Future avec l'Agent 1

Aucune incompatibilité géométrique n'existe entre les polygones de l'Agent 1 et ceux de l'Agent 2 (`0.0` chevauchement, frontières communes parfaitement jointives). Deux points documentaires sont signalés pour l'étape ultérieure d'assemblage des 90 régions :

1. **Connexité terrestre `region_026` (Prusse-Orientale) <-> `region_056` (Pologne russe orientale)** :
   - Dans `data/world/map/build/agent_1/adjacency.json`, la table `external_perimeter_interfaces` mentionne `region_026 <-> region_054` (Courlande/Kovno) et `region_026 <-> region_055` (Płock), mais omet `region_026 <-> region_056` (gouvernements de Suwałki et de Łomża). Or, historiquement et géométriquement, la Prusse-Orientale partageait une frontière terrestre majeure de **368,87 km** avec Suwałki et Łomża (Augustów, Lyck, Grajewo, théâtre des batailles des lacs de Mazurie en 1914). Cette 17e interface a été intégrée et documentée dans `data/world/map/build/agent_2/adjacency.json` (`ext_adj_region_056_region_026`).
2. **Harmonisation des champs additionnels lors de la fusion finale** :
   - Le lot de l'Agent 2 respecte 100 % des champs produits par l'Agent 1 et y ajoute, conformément aux instructions de la mission Agent 2, le fichier `maritime_zones.json` ainsi que les clés de liaison `external_adjacent_region_ids` et `maritime_zone_ids` dans `regions.geojson` / `regions.json`. Lors de l'intégration finale des 90 régions sur `main`, ces clés pourront être étendues aux 50 régions de l'Agent 1.

---

## 6. Résultats des Validations

L'exécution de `validate_agent_2.py` confirme :
- **10 / 10 livrables présents et valides** (plus `sources/README.md`) ;
- **40 / 40 régions construites** (`Scandinavie`: 8, `Europe orientale`: 18, `Balkans`: 10, `Territoires ottomans européens`: 4) ;
- **40 / 40 géométries OGC valides** en `EPSG:4326`, **0 chevauchement interne**, **0 chevauchement avec les 50 régions de l'Agent 1** ;
- **69 arêtes terrestres internes**, **8 passages de détroits**, **17 interfaces terrestres externes avec l'Agent 1** ;
- **72 villes stratégiques** (dont **11 capitales d'État 1914**) et **33 places fortes** toutes strictement incluses dans leur polygone régional ;
- **0 erreur détectée**.
