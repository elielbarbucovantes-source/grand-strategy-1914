# RAPPORT D'AUDIT QUALITÉ GLOBAL — ATLAS GRAND STRATEGY-1914 (1er JANVIER 1914)

- **Date de l'audit** : 2 novembre 2026
- **Branche d'audit** : `audit/map-1914` (créée depuis `main` `4ffdb8a09981b8d51f103bd2c2088fed9506a71f`)
- **Lot Agent 1 audité** : branche `agent_1` — commit `286975a96fc2238040a9bf09163c664740ee3854` (50 régions : `region_001` à `region_043`, `region_080` à `region_086`)
- **Lot Agent 2 audité** : branche `agent-2` — commit final `baa0c90932c74a39ae8745add9a07a7686cd770e` faisant suite au commit initial `494abe0c6c8641c02ea9fd613d9045c8eeb242e8` (40 régions : `region_044` à `region_079`, `region_087` à `region_090`)
- **Intégrité des branches** : Aucune modification n'a été apportée à `main`, `agent_1` ou `agent-2`, et aucune fusion n'a été effectuée.

---

## SYNTHÈSE EXÉCUTIVE ET MÉTRIQUES CLÉS DE LIVRAISON

| Indicateur d'audit | Résultat | Détail |
|---|---|---|
| **Nombre de régions validées (inventaire & attributs)** | **90 / 90** (`100 %`) | 50 régions (`agent_1`) + 40 régions (`agent-2`), correspondance 100 % avec `region_plan.csv` |
| **Nombre de régions conformes sans retouche géométrique/historique** | **88 / 90** (`97,8 %`) | Seules `region_088` (`BLK-001` : homonymie du district *Saray*) et `region_074`/`region_072` (`MAJ-003` : saillant de Strumica) présentent un défaut substantiel de tracé |
| **Nombre de géométries valides (OGC / Shapely / RFC 7946)** | **90 / 90** (`100 %`) | `is_valid == True` en `EPSG:4326` et `EPSG:3035`, anneaux orientés selon la règle de la main droite |
| **Nombre de chevauchements significatifs (`> 1e-6 deg²` / `> 120 m²`)** | **0** | 0 interne `agent_1`, 0 interne `agent-2`, 0 inter-lots `agent_1 <-> agent-2` |
| **Nombre de micro-chevauchements d'arrondi (`1e-10 < aire <= 1,13e-8 deg²`)** | **15** (tous dans `agent_1`) | Entre `1,94 m²` et `115,29 m²` (`375,18 m²` cumulés), provoquant l'échec du seuil strict `1e-10` de `tools/map/validate_atlas.py` (`BLK-002`) |
| **Nombre d'erreurs / écarts d'adjacence** | **5** | 1 interface inter-lots omise dans `agent_1` (`026<->056`, `368,87 km`, `BLK-003`), listes `adjacent_region_ids` non fusionnées entre lots (`BLK-003`), 1 arête interne omise dans `agent_1` (`033<->037`, `1,43 km`, `MAJ-007`), 3 détroits en auto-boucle dans `agent-2` (`MAJ-007`), 4 détroits ouest-européens omis dans `agent_1` (`MAJ-007`) |
| **Problèmes historiques 1914 détectés** | **2 significatifs + 2 mineurs** | **1.** Exclave de Van / trou de Saray dans `region_088` (`BLK-001`) ; **2.** Saillant de Strumica (post-1919) dans `region_074` au lieu de `region_072` (`MAJ-003`) ; **3.** Parenthèses/toponymes post-1914 (`Dniepropetrovsk`, `Oslofjord`, districts turcs modernes, `OPT-001`) ; **4.** Pointe portuaire de Taganrog (`OPT-004`) |
| **Incompatibilités entre les deux lots** | **5** | **1.** `maritime_zones.json` et `maritime_zone_ids` absents d'`agent_1` (`MAJ-001`) ; **2.** `0` axe ferroviaire inter-lots (`MAJ-002`) ; **3.** Clés transitoires `external_*` asymétriques et `island_class: null` non conforme à `map.schema.json` (`MAJ-005`) ; **4.** 6 fleuves et 2 massifs transfrontaliers scindés sous des IDs distincts (`MAJ-006`) ; **5.** Lacunes de couture inter-sources (`MAJ-004`) |

### Verdict global d'audit
Les productions de l'Agent 1 (50 régions) et de l'Agent 2 (40 régions) sont **d'une très grande qualité structurelle, géométrique et historique** et **peuvent être réunies dans un atlas européen 1914 cohérent et exploitable sans recommencer le travail des deux agents**, sous réserve d'appliquer lors de l'assemblage les **3 corrections bloquantes** (`BLK-001` à `BLK-003`) et les **7 harmonisations importantes** (`MAJ-001` à `MAJ-007`) détaillées dans ce rapport et dans `docs/map/audit/INTEGRATION_CHECKLIST.md`.

---

## 1. CONTRÔLE A — INVENTAIRE DES 90 RÉGIONS

### 1.1 Vérification des identifiants et de la partition entre lots
- **Total des identifiants attendus** : 90 (`region_001` à `region_090`).
- **Lot Agent 1 (`data/world/map/build/agent_1/`)** : **50 régions** exactement (`region_001` à `region_043` et `region_080` à `region_086`).
- **Lot Agent 2 (`data/world/map/build/agent_2/`)** : **40 régions** exactement (`region_044` à `region_079` et `region_087` à `region_090`).
- **Régions manquantes** : **0**.
- **Identifiants dupliqués (internes ou inter-lots)** : **0** (`50 + 40 = 90`, intersection vide).
- **Cohérence interne des fichiers par lot** : dans chacun des deux lots, les mêmes identifiants apparaissent exactement dans le même ordre dans `regions.geojson`, `regions.json` et `terrain.json`.

### 1.2 Concordance avec `data/world/map/tables/region_plan.csv`
La comparaison automatisée des 90 régions avec `data/world/map/tables/region_plan.csv` confirme une **concordance de 90 / 90 (`100 %`)** sur :
- l'identifiant (`id` : `region_001`..`region_090`) ;
- le nom français (`nom_fr` / `name_fr`) ;
- la macro-zone géographique (`zone`) ;
- la souveraineté au 1er janvier 1914 (`souverainete_1914` / `sovereign_1914`).

| Macro-zone (`region_plan.csv`) | Attendu | Lot Agent 1 | Lot Agent 2 | Total validé |
|---|---:|---:|---:|---:|
| Îles Britanniques | 6 | 6 (`001`–`006`) | 0 | **6 / 6** |
| Europe occidentale | 13 | 13 (`007`–`019`) | 0 | **13 / 13** |
| Péninsule ibérique | 6 | 6 (`020`–`025`) | 0 | **6 / 6** |
| Europe centrale | 18 | 18 (`026`–`043`) | 0 | **18 / 18** |
| Scandinavie | 8 | 0 | 8 (`044`–`051`) | **8 / 8** |
| Europe orientale | 18 | 0 | 18 (`052`–`069`) | **18 / 18** |
| Balkans | 10 | 0 | 10 (`070`–`079`) | **10 / 10** |
| Italie | 7 | 7 (`080`–`086`) | 0 | **7 / 7** |
| Territoires ottomans européens | 4 | 0 | 4 (`087`–`090`) | **4 / 4** |
| **Total Atlas 1914** | **90** | **50** | **40** | **90 / 90** |

> **Remarque de suivi (`OPT-002`)** : dans `data/world/map/tables/region_plan.csv`, la colonne `etat_geometrie` a conservé sa valeur initiale `"non_construite"` sur les 90 lignes (les agents ayant interdiction de modifier les fichiers hors de leur dossier `build/`). Elle devra être passée à `"construite"` lors de l'intégration finale.

---

## 2. CONTRÔLE B — GÉOMÉTRIE ET TOPOLOGIE DES 90 POLYGONES

### 2.1 Validité OGC, projection et orientation RFC 7946
- **Validité OGC (`shapely.is_valid`) en WGS84 (`EPSG:4326`)** : **90 / 90 valides** (`0` auto-intersection, `0` géométrie vide, `0` `GeometryCollection`).
- **Validité OGC en projection équivalente européenne (`EPSG:3035` LAEA Europe)** : **90 / 90 valides**.
- **Orientation des anneaux (RFC 7946 right-hand rule)** : **90 / 90 conformes** (anneaux extérieurs dans le sens anti-horaire, anneaux intérieurs dans le sens horaire).
- **Types géométriques** : 26 `Polygon` (17 dans `agent_1`, 9 dans `agent-2`) et 64 `MultiPolygon` (33 dans `agent_1`, 31 dans `agent-2`).
- **Superficie totale calculée en `EPSG:3035`** : **`10 026 806,13 km²`** (`3 053 472,80 km²` pour `agent_1` + `6 973 333,33 km²` pour `agent-2`).
- **Centroïdes et points d'ancrage (`representative_point`)** : **90 / 90** points `representative_point` sont strictement contenus à l'intérieur de leur polygone régional.

### 2.2 Analyse des chevauchements (Overlaps)
L'audit a testé les **4 005 paires** de régions possibles (`(90 × 89) / 2`) en `EPSG:4326` et en `EPSG:3035` :
1. **Chevauchements significatifs (`> 1e-6 deg²` ou `> 120 m²`)** : **`0`**.
   - `0` chevauchement interne à `agent_1` ;
   - `0` chevauchement interne à `agent-2` ;
   - `0` chevauchement le long de la frontière entre `agent_1` et `agent-2` (`4 335,96 km` de couture inter-lots parfaitement jointive, sans aucun recouvrement `> 1e-10 deg²`).
2. **Micro-chevauchements d'arrondi de coordonnées (`1e-10 < aire <= 1,132e-08 deg²`) — `BLK-002`** : **`15` paires**, toutes internes au lot `agent_1`, résultant de l'arrondi des coordonnées à 6 décimales sans passe finale de soustraction topologique après arrondi :

| Paire de régions (`agent_1`) | Aire d'intersection (`deg²`) | Aire réelle (`EPSG:3035`, `m²`) |
|---|---:|---:|
| `region_018` (Belgique) / `region_080` (Piémont — artefact d'arrondi en fait `018`/`080` non, `018` Pays-Bas ? Non : `018` = Suisse, `080` = Piémont-Ligurie) | `1.132e-08` | `115,29 m²` |
| `region_012` (Provence-Corse) / `region_080` (Piémont et Ligurie) | `5.149e-09` | `55,91 m²` |
| `region_034` (Bavière) / `region_037` (Alpes autrichiennes) | `4.941e-09` | `48,81 m²` |
| `region_037` (Alpes autrichiennes) / `region_081` (Lombardie et Vénétie) | `8.468e-09` | `40,85 m²` |
| `region_014` (Bassin parisien) / `region_032` (Rhénanie — tripoint/frontière) | `3.356e-09` | `26,63 m²` |
| `region_017` (Bourgogne — Franche-Comté / Alpes) / `region_080` (Piémont) | `2.353e-09` | `20,69 m²` |
| `region_013` (Nord et Pas-de-Calais) / `region_016` (Champagne-Ardenne-Picardie) | `1.805e-09` | `15,31 m²` |
| `region_031` (Saxe et Thuringe) / `region_038` (Bohême et Moravie) | `1.564e-09` | `11,73 m²` |
| `region_030` (Silésie) / `region_040` (Galicie et Bucovine) | `1.547e-09` | `9,40 m²` |
| `region_030` (Silésie) / `region_039` (Autriche-Silésie / Moravie) | `9.800e-10` | `7,81 m²` |
| `region_013` / `region_015` | `9.940e-10` | `7,75 m²` |
| `region_030` / `region_038` | `7.830e-10` | `6,22 m²` |
| `region_011` / `region_035` | `4.040e-10` | `3,42 m²` |
| `region_014` / `region_019` | `4.170e-10` | `3,35 m²` |
| `region_014` / `region_016` | `2.470e-10` | `1,94 m²` |
| **Total cumulé sur les 15 paires** | **`4.433e-08 deg²`** | **`375,18 m²` (`0,000375 km²`)** |

Bien que ces 15 micro-intersections soient imperceptibles visuellement (`375 m²` au total sur `10 millions de km²`), **le script officiel `tools/map/validate_atlas.py` (ligne 80) applique un seuil strict `inter.area > 1e-10` et échoue sur ces 15 paires**. Elles sont donc classées en **`BLK-002`** et doivent être purgées par une simple passe `difference` post-arrondi lors de la fusion.

### 2.3 Détection des trous, lacunes de couture et géométries suspectes

L'analyse des anneaux intérieurs de l'union globale des 90 régions (`EPSG:3035`) a permis d'identifier :

1. **Erreur bloquante `BLK-001` — Trou de `684,40 km²` en Thrace orientale et exclave parasite de `938,36 km²` à Van (`region_088` *Çatalca et Tekirdağ*)** :
   - **Cause racine identifiée** : dans le fichier source `gb_tur_adm2.geojson`, deux districts distincts portent le même nom `shapeName == "Saray"` :
     - le district thrace de **Saray** (province de Tekirdağ, `shapeID: 54988432B91991689904144`, centroïde `[27.9001, 41.4436]`, `684,40 km²`) ;
     - le district est-anatolien de **Saray** (province de Van, frontière iranienne, `shapeID: 54988432B48034047733274`, centroïde `[44.1558, 38.5162]`, `938,36 km²`).
   - Dans `build_agent_2.py` (ligne 153), le dictionnaire `tur = {f["properties"]["shapeName"]: shape(f["geometry"]) for f in load_geojson("gb_tur_adm2.geojson")}` a écrasé le district thrace par le district de Van.
   - **Conséquence double** : `region_088` comporte un **trou béant de `684,40 km²`** au milieu de la Thrace orientale (entre `region_088` et `region_089`) et possède un **polygone détaché de `938,36 km²` à `1 326,4 km` à l'est** près du lac de Van (`lon = 44,16°E`).
   - **Correction** : filtrer `gb_tur_adm2.geojson` avec `centroid.x < 30.0` (ou par `shapeID == "54988432B91991689904144"`).

2. **Erreur importante `MAJ-004` — 4 lacunes de couture inter-sources (`92` à `662 km²`)** :
   - **`662,47 km²` à `[32.3258, 62.6315]`** entre `region_052` (Finlande, source `REGIS_Finland`) et `region_064` (Russie du Nord-Ouest, source `ristat_1897_provinces`, secteur de Suojärvi / Olonets) : non comblé car supérieur au plafond `max_sliver_m2 = 500 km²` de `fill_seam_slivers()`.
   - **`225,88 km²` à `[26.1997, 48.3030]`** au tripoint inter-lots entre `region_040` (Galicie et Bucovine), `region_062` (Bessarabie) et `region_071` (Roumanie septentrionale, secteur de Khotin / Herța).
   - **`117,05 km²` à `[30.5256, 69.5879]`** et **`92,09 km²` à `[29.7994, 69.4143]`** entre `region_047` (Norvège — Nord, source `geoBoundaries NOR`) et `region_065` (Russie septentrionale, source `ristat_1897_provinces`, vallée de la Pasvik).

3. **Plans d'eau intérieurs légitimes (`APP-006`)** :
   - **Lac Ladoga** (`8 566,74 km²` à `[30.9321, 61.1538]` entre `region_052` et `region_064`) ;
   - **Lagune du Sivach / Mer Putride** (`1 019,25 km²` à `[34.2095, 46.1241]` entre `region_060` et `region_063`) ;
   - **Lac de Ratzebourg / Schaalsee** (`17,75 km²` à `[10.8867, 53.9257]` entre `region_028` et `region_029`).

### 2.4 Limites géographiques de l'Europe
Après prise en compte du correctif de `region_088` (`BLK-001`), l'emprise globale de l'atlas est **`[-24.6044, 34.7925, 66.2664, 71.1905]`** :
- **Ouest** : `-24,60°` (Islande — Bjargtangar, `region_051`) ;
- **Sud** : `34,79°` (Crète — île de Gavdos / cap Lithinon, `region_079`) ;
- **Est** : `66,27°` (Oural oriental, `region_065` / `region_068`) ;
- **Nord** : `71,19°` (Cap Nord / Knivskjellodden en Norvège, `region_047`).
Les territoires extra-européens ou hors cadre (Canaries, Açores, Madère, Svalbard, Anatolie asiatique, Chypre, Dodécanèse) sont correctement exclus (`APP-008`).

---

## 3. CONTRÔLE C — ADJACENCES, INTERFACES INTER-LOTS ET DÉTROITS

### 3.1 Connexions internes et symétrie
- **Lot Agent 1** : `97` arêtes terrestres internes dans `agent_1/adjacency.json`, **100 % symétriques** et cohérentes avec `adjacent_region_ids` dans `regions.json` et `regions.geojson`.
- **Lot Agent 2** : `69` arêtes terrestres internes dans `agent-2/adjacency.json`, **100 % symétriques** et cohérentes avec `adjacent_region_ids` dans `regions.json` et `regions.geojson`.
- **Arête interne manquante (`MAJ-007`)** : `region_033` (Allemagne du Sud-Ouest) et `region_037` (Alpes autrichiennes — Vorarlberg) partagent **`1,43 km`** de frontière terrestre géométrique réelle à Bregenz/Lindau (rive orientale du lac de Constance), mais ne sont pas reliées dans `agent_1/adjacency.json`.

### 3.2 Interfaces terrestres entre les deux lots (`agent_1 <-> agent-2`) — `BLK-003`
L'analyse géométrique exacte en `EPSG:3035` identifie **17 frontières terrestres inter-lots** totalisant **`4 335,96 km`** du Jutland à l'Adriatique :

| # | Région Lot 1 (`agent_1`) | Région Lot 2 (`agent-2`) | Longueur géométrique (`km`) | Déclarée dans `agent_1` ? | Déclarée dans `agent-2` ? |
|---:|---|---|---:|:---:|:---:|
| 1 | `region_029` (Schleswig-Holstein et Hanovre) | `region_044` (Danemark) | `88,19 km` | Oui | Oui |
| 2 | `region_026` (Prusse-Orientale) | `region_054` (Courlande et Lituanie) | `181,59 km` | Oui | Oui |
| 3 | **`region_026` (Prusse-Orientale)** | **`region_056` (Pologne russe orientale — Suwałki)** | **`368,87 km`** | **NON (`BLK-003`)** | **Oui** |
| 4 | `region_026` (Prusse-Orientale) | `region_055` (Pologne russe occidentale) | `55,79 km` | Oui | Oui |
| 5 | `region_027` (Prusse-Occidentale et Posnanie) | `region_055` (Pologne russe occidentale) | `423,96 km` | Oui | Oui |
| 6 | `region_030` (Silésie) | `region_055` (Pologne russe occidentale) | `168,51 km` | Oui | Oui |
| 7 | `region_040` (Galicie et Bucovine) | `region_055` (Pologne russe occidentale) | `264,53 km` | Oui | Oui |
| 8 | `region_040` (Galicie et Bucovine) | `region_056` (Pologne russe orientale) | `263,41 km` | Oui | Oui |
| 9 | `region_040` (Galicie et Bucovine) | `region_058` (Ukraine occidentale) | `435,39 km` | Oui | Oui |
| 10 | `region_040` (Galicie et Bucovine) | `region_062` (Bessarabie) | `36,02 km` | Oui | Oui |
| 11 | `region_040` (Galicie et Bucovine) | `region_071` (Roumanie septentrionale — Moldavie) | `294,97 km` | Oui | Oui |
| 12 | `region_042` (Transylvanie) | `region_071` (Roumanie septentrionale — Moldavie) | `267,72 km` | Oui | Oui |
| 13 | `region_042` (Transylvanie) | `region_070` (Roumanie méridionale — Valachie) | `440,64 km` | Oui | Oui |
| 14 | `region_041` (Hongrie centrale et orientale) | `region_070` (Roumanie méridionale — Portes de Fer) | `86,44 km` | Oui | Oui |
| 15 | `region_041` (Hongrie centrale et orientale) | `region_074` (Serbie) | `217,60 km` | Oui | Oui |
| 16 | `region_043` (Croatie-Slavonie, Bosnie et Dalmatie) | `region_074` (Serbie) | `451,83 km` | Oui | Oui |
| 17 | `region_043` (Croatie-Slavonie, Bosnie et Dalmatie) | `region_075` (Monténégro) | `310,50 km` | Oui | Oui |
| **Total** | **8 régions frontalières (`agent_1`)** | **10 régions frontalières (`agent-2`)** | **`4 335,96 km`** | **16 / 17** | **17 / 17** |

Deux problèmes bloquants (`BLK-003`) affectent ces interfaces :
1. **`agent_1/adjacency.json` omet la frontière `region_026 <-> region_056` (`368,87 km`)** entre la Prusse-Orientale et le gouvernement de Suwałki/Łomża (`region_056`), alors qu'`agent-2/adjacency.json` la déclare correctement (`ext_adj_region_056_region_026`).
2. **Les voisins inter-lots ne sont pas injectés dans `adjacent_region_ids` (`regions.json` / `regions.geojson`) ni dans `neighbors_by_region` (`adjacency.json`)**. En conséquence, `region_044` (Danemark) a `adjacent_region_ids = []` dans `agent-2` car son unique voisin terrestre (`region_029`) est stocké séparément dans `external_adjacent_region_ids`.

### 3.3 Détection des régions isolées
Une fois les 17 interfaces inter-lots fusionnées, **87 des 90 régions forment un graphe terrestre connexe** (composante continentale unique de 81 régions + Grande-Bretagne 4 régions + Irlande 2 régions). Les **3 seules régions sans voisin terrestre (`adjacent_region_ids == []`)** sont les 3 régions purement insulaires prévues par le plan :
- `region_051` (Islande) ;
- `region_085` (Sicile — reliée à `region_084` par le détroit de Messine) ;
- `region_086` (Sardaigne).

### 3.4 Passages maritimes et détroits (`strait_crossings`) — `MAJ-007`
- **Lot Agent 1** : 1 seul détroit déclaré (`strait_messina_084_085` entre `region_084` et `region_085`). Les passages stratégiques de l'Europe de l'Ouest (**Pas de Calais** `001<->007`, **Canal du Nord** `003<->005`, **Canal Saint-Georges** `004<->006`, **Bouches de Bonifacio** `012<->086`) sont absents de `strait_crossings`.
- **Lot Agent 2** : 8 détroits déclarés, dont 5 connexions inter-régionales valides (`strait_oresund_044_050`, `strait_kattegat_044_049`, `strait_skagerrak_044_045`, `strait_aland_048_052`, `strait_kerch_063_069`) et **3 auto-boucles (`region_a_id == region_b_id`)** :
  - `strait_danish_belts_044_044` (`region_044 <-> region_044`) ;
  - `strait_bosphorus_087` (`region_087 <-> region_087`) ;
  - `strait_dardanelles_090` (`region_090 <-> region_090`).

---

## 4. CONTRÔLE D — DONNÉES HISTORIQUES AU 1er JANVIER 1914

L'audit a vérifié **103 points de contrôle géopolitiques et territoriaux** au 1er janvier 1914 (tests automatisés d'inclusion de coordonnées historiques et contrôle des unités administratives). **101 points sur 103 sont strictement conformes**.

### 4.1 Empire austro-hongrois (`region_036` à `region_043`) — **100 % conforme**
- **Trentin, Tyrol du Sud et Littoral autrichien (`region_037`)** : Trente (`[11.1211, 46.0748]`), Bolzano/Bozen (`[11.3548, 46.4983]`), Gorizia (`[13.6222, 45.9414]`), Trieste (`[13.7768, 45.6495]`) et Pola/Istrie (`[13.8496, 44.8666]`) appartiennent bien à l'Autriche-Hongrie (`region_037`) et non à l'Italie (`region_081`).
- **Galicie et Bucovine (`region_040`)** : Cracovie (`[19.9450, 50.0647]`), Lemberg/Lwów (`[24.0316, 49.8429]`) et Czernowitz (`[25.9358, 48.2917]`) sont bien dans `region_040`.
- **Couronne de Saint-Étienne (`region_041`, `region_042`)** : Presbourg/Pozsony (`[17.1077, 48.1486]`), Košice/Kassa (`[21.2611, 48.7164]`), Temesvár/Timișoara (`[21.2272, 45.7489]`), Újvidék/Novi Sad (`[19.8335, 45.2671]`) sont dans `region_041` ; Kolozsvár/Cluj (`[23.6236, 46.7712]`) et Brassó/Brașov (`[25.5887, 45.6427]`) sont dans `region_042` (Transylvanie).
- **Croatie-Slavonie, Dalmatie et Bosnie-Herzégovine (`region_043`)** : Zagreb/Agram, Fiume/Rijeka (`[14.4422, 45.3271]`), Zara/Zadar, Raguse/Dubrovnik, les Bouches de Cattaro/Kotor (`[18.7712, 42.4247]`), Sarajevo (`[18.4131, 43.8563]`) et Mostar sont intégralement dans `region_043`.

### 4.2 Frontières de l'Empire allemand (`region_026` à `region_035`) — **100 % conforme**
- **Alsace-Lorraine (`region_035`)** : Strasbourg, Metz et Mulhouse sont dans `region_035` (`Empire allemand`), tandis que **Belfort** (`[6.8628, 47.6380]`) est bien en France (`region_011`).
- **Eupen-Malmedy (`region_032`)** : Eupen (`[6.0365, 50.6292]`) et Malmedy (`[6.0279, 50.4268]`) sont bien rattachés à la Prusse rhénane (`region_032`) et soustraits de la Belgique (`region_019`).
- **Schleswig du Nord (`region_029`)** : Haderslev (`[9.4898, 55.2530]`) et Aabenraa (`[9.4174, 55.0444]`), au sud de la rivière Kongeå (frontière de 1864–1920), sont bien dans `region_029` (`Empire allemand`), tandis qu'Esbjerg et Kolding sont au Danemark (`region_044`).
- **Marches orientales prussiennes (`region_026`, `region_027`, `region_030`)** : Königsberg, Memel (`[21.1322, 55.7033]`) et Allenstein dans `region_026` ; Dantzig, Posen et Thorn (`[18.5984, 53.0138]`) dans `region_027` ; Breslau et Kattowitz (`[19.0238, 50.2649]`) dans `region_030`.

### 4.3 Royaume-Uni et Irlande (`region_001` à `region_006`) — **100 % conforme**
- **Pays de Galles distinct (`region_004`)** : Cardiff et Swansea forment une région distincte de l'Angleterre (`region_001`–`002`).
- **Irlande entière sous souveraineté britannique (`region_005`, `region_006`)** : aucune partition de 1921 n'est présente. `region_005` (*Irlande du Nord — Ulster*) regroupe les **9 comtés historiques de la province d'Ulster** (incluant Donegal `[8.1100, 54.6542]`, Cavan `[7.3606, 53.9908]` et Monaghan `[6.9683, 54.2492]` en plus d'Antrim, Armagh, Down, Fermanagh, Londonderry et Tyrone), tandis que `region_006` regroupe les 23 comtés de Leinster, Munster et Connacht, tous deux sous `sovereign_1914 = "Royaume-Uni"`.

### 4.4 Pays scandinaves (`region_044` à `region_051`) — **100 % conforme**
- **Danemark (`region_044`)** : frontière sud sur la Kongeå (1864–1920) ; souverain sur l'**Islande (`region_051`)** (`sovereign_1914 = "Danemark"`).
- **Norvège (`region_045`–`047`)** : indépendante (dissolution de l'union avec la Suède en 1905), capitale nommée **Christiania** (`region_045`), frontière arctique de 1826 avec la Russie (Petsamo restant russe dans `region_065`).
- **Suède (`region_048`–`050`)** : 3 régions complètes (Nord, Centrale, Sud).

### 4.5 Territoires de l'Empire russe (`region_052` à `region_069`) — **Conforme**
- **Grand-Duché de Finlande (`region_052`)** : sous souveraineté `Empire russe`, incluant Viipuri/Vyborg (`[28.7497, 60.7107]`) et l'isthme de Carélie, mais excluant Petsamo/Pechenga (`[31.2167, 69.5500]`, qui est bien dans `region_065` *Russie septentrionale*, la cession à la Finlande datant du traité de Tartu de 1920).
- **Gouvernements baltes et Lituanie (`region_053`, `region_054`)** : Estonie et Livonie (`region_053` : Reval, Riga, Dorpat), Courlande et Kovno (`region_054` : Libau, Mitau, Kovno).
- **Pologne du Congrès (`region_055`, `region_056`)** : Varsovie, Łódź, Kalisz dans `region_055` ; Lublin, Siedlce, Kholm (`APP-001`), Białystok et Suwałki dans `region_056`.
- **Biélorussie, Ukraine et Bessarabie (`region_057`–`063`)** : Vilna (`[25.2797, 54.6872]`), Grodno, Brest-Litovsk, Minsk, Mohilev et Vitebsk dans `region_057` ; Volhynie et Podolie dans `region_058` ; Ukraine centrale (`059`), méridionale (`060`, incluant la Tauride continentale au nord de Perekop), Donbass (`061`), **Bessarabie (`region_062` : Kichinev, Izmaïl, Akkerman)** et **Crimée (`region_063` : Sébastopol, Simferopol, Kertch)** sous souveraineté `Empire russe`.

### 4.6 Balkans après les traités de Londres, Bucarest et Constantinople (1913) (`region_070` à `region_079`)
- **Roumanie (`region_070`, `region_071`)** : inclut la **Dobroudja du Sud / Quadrilatère** acquise au traité de Bucarest d'août 1913 (**Silistra** `[27.2606, 44.1171]` et **Dobritch/Bazargic** `[27.8273, 43.5670]` sont bien dans `region_070`).
- **Bulgarie (`region_072`, `region_073`)** : inclut la **Thrace occidentale** donnant accès à la mer Égée (**Gümülcine/Komotini** `[25.4066, 41.1225]` et **Dedeağaç/Alexandroupoli** `[25.8740, 40.8476]` sont bien dans `region_073`).
- **Anomalie historique détectée (`MAJ-003`) — Saillant de Strumica** : la ville de **Strumica** (`[22.6427, 41.4378]`), attribuée à la Bulgarie en août 1913 et cédée au Royaume des Serbes, Croates et Slovènes seulement en novembre 1919 (traité de Neuilly), se trouve dans `region_074` (Serbie) au lieu de `region_072` (Bulgarie occidentale) en raison de l'emploi de `REGIS_Yugoslavia_L2_1948-1954` pour la Macédoine du Vardar.
- **Serbie (`region_074`) et Monténégro (`region_075`)** : la Serbie inclut le Kosovo (Pristina, Prizren) et la Macédoine du Vardar (Skopje/Üsküb, Bitola/Monastir) ; le Monténégro inclut Cetinje, Podgorica, Nikšić et la part occidentale du Sandjak (**Pljevlja** `[19.3584, 43.3567]`), sans Cattaro (austro-hongrois dans `region_043`).
- **Principauté d'Albanie (`region_076`)** : indépendante dans ses frontières de 1913 (Scutari/Shkodër, Durazzo/Durrës, Valona/Vlorë, Koritza/Korçë).
- **Grèce (`region_077`–`079`)** : inclut l'Épire du Sud (**Ioannina** `[20.8537, 39.6650]`), la Macédoine égéenne (**Salonique** `[22.9444, 40.6401]`, **Kavala** `[24.4129, 40.9396]`), la Crète et les îles de l'Égée orientale acquises en 1912–1913 (Lesbos, Chios, Samos, Lemnos), tout en excluant le Dodécanèse occupé par l'Italie (`APP-008`).

### 4.7 Thrace ottomane (`region_087` à `region_090`)
- **`region_087` (*Constantinople et Bosphore*)** : rive européenne de Constantinople et du Bosphore.
- **`region_088` (*Çatalca et Tekirdağ*)** : Tekirdağ/Rodosto, Çorlu et Silivri, mais affectée par **le bug d'homonymie du district de Saray (`BLK-001`)** qui crée un trou de `684,40 km²` en Thrace et une exclave de `938,36 km²` à Van.
- **`region_089` (*Andrinople et Kirklareli*)** : **Edirne/Andrinople** (`[26.5557, 41.6771]`, y compris Karaağaç), **Kırklareli** (`[27.2252, 41.7351]`), Lüleburgaz et Uzunköprü, reconquis par l'Empire ottoman lors de la Deuxième Guerre balkanique et confirmés par le traité de Constantinople du 29 septembre 1913.
- **`region_090` (*Gallipoli et Dardanelles*)** : péninsule de Gallipoli (Gelibolu, Eceabat) et îles ottomanes d'**Imbros (Gökçeada)** et **Ténédos (Bozcaada)** confirmées à l'Empire ottoman en 1913–1914.

---

## 5. CONTRÔLE E — COMPATIBILITÉ DES DONNÉES ENTRE LES DEUX LOTS

### 5.1 Comparaison structurelle des fichiers JSON
| Fichier | Lot Agent 1 | Lot Agent 2 | Statut de compatibilité |
|---|---|---|---|
| `regions.geojson` | 50 features (23 propriétés/feature) | 40 features (25 propriétés/feature) | Compatible après suppression de `external_adjacent_region_ids` et harmonisation de `maritime_zone_ids` (`MAJ-005`) |
| `regions.json` | 50 régions (23 clés/région) | 40 régions (25 clés/région) | Même harmonisation que `regions.geojson` (`MAJ-005`) |
| `adjacency.json` | 97 arêtes, 16 interfaces externes, 1 détroit | 69 arêtes, 17 interfaces externes, 8 détroits | Requiert fusion des 17 interfaces en arêtes, correction de `026<->056` (`BLK-003`) et nettoyage des détroits (`MAJ-007`) |
| `cities.json` | 103 villes (10 capitales, 12 clés/ville) | 72 villes (12 capitales, 12 clés/ville) | **100 % compatible** (schéma identique, `0` doublon, `175` villes dont `22` capitales) |
| `infrastructure.json` | 76 voies ferrées, 47 ports, 32 forts | 53 voies ferrées, 37 ports, 33 forts | Schéma **100 % identique**, `0` doublon d'ID, mais requiert l'ajout des voies ferrées inter-lots (`MAJ-002`) |
| `terrain.json` | 50 profils, 23 fleuves, 14 massifs | 40 profils, 22 fleuves, 10 massifs | Requiert omission de `island_class: null` (`MAJ-005`) et fusion des 6 fleuves et 2 massifs transfrontaliers (`MAJ-006`) |
| `maritime_zones.json` | **Absent** | 16 zones maritimes | À étendre à l'Europe de l'Ouest/Méditerranée ou harmoniser (`MAJ-001`) |

### 5.2 Contrôle des villes (`175` villes) et des infrastructures (`129` voies ferrées, `84` ports, `65` forteresses)
- **Doublons de villes** : **`0`** doublon d'`id`, **`0`** doublon de `name_fr`, **`0`** doublon de coordonnées parmi les 175 villes (`103 + 72`).
- **Inclusion géométrique des villes** : **`175 / 175` villes (`100 %`)** ont leurs coordonnées situées strictement à l'intérieur du polygone de leur région de rattachement (`0` ville en mer ou hors polygone).
- **Cohérence `major_city_ids` / `capital_city_id`** : **`90 / 90` régions** ont un `capital_city_id` valide présent dans `cities.json` et dans leur liste `major_city_ids`.
- **Inclusion géométrique des forteresses** : **`65 / 65` fortifications (`100 %`)** sont strictement situées à l'intérieur de leur polygone régional.
- **Références des ports et voies ferrées** : toutes les références `city_id` et `region_id` sont valides dans les deux lots.

---

## 6. CLASSIFICATION DES PROBLÈMES PAR NIVEAU DE CRITICITÉ

La liste exhaustive et structurée des 23 anomalies est disponible dans `docs/map/audit/ISSUES.json`.

### 6.1 Erreurs bloquantes (`3` — à corriger impérativement lors de l'intégration)
1. **`BLK-001` — Homonymie du district `"Saray"` dans `region_088` (*Çatalca et Tekirdağ*)** : trou intérieur de `684,40 km²` en Thrace orientale (`[27.9001, 41.4436]`) et exclave parasite de `938,36 km²` dans la province de Van (`[44.1558, 38.5162]`, à `1 326,4 km` à l'est).
2. **`BLK-002` — 15 micro-chevauchements d'arrondi de coordonnées dans `agent_1` (`2,47e-10` à `1,132e-08 deg²`, total `375,18 m²`)** : font échouer le test strict `inter.area > 1e-10` de `tools/map/validate_atlas.py`.
3. **`BLK-003` — Asymétrie de l'interface inter-lots `region_026 <-> region_056` (`368,87 km` omis dans `agent_1/adjacency.json`) et listes `adjacent_region_ids` / `neighbors_by_region` non fusionnées entre les deux lots**.

### 6.2 Erreurs importantes (`7` — à corriger ou harmoniser lors de l'intégration)
1. **`MAJ-001` — Fichier `maritime_zones.json` et champ `maritime_zone_ids` présents dans `agent-2` mais absents dans `agent_1`**.
2. **`MAJ-002` — Absence d'axes ferroviaires inter-lots (`0` voie ferrée reliant `agent_1` et `agent-2`)**.
3. **`MAJ-003` — Saillant de Strumica (`[22.6427, 41.4378]`) inclus dans `region_074` (Serbie) au lieu de `region_072` (Bulgarie occidentale)**.
4. **`MAJ-004` — 4 lacunes de couture inter-sources (`92` à `662 km²`)** entre `(052, 064)`, `(040, 062, 071)` et `(047, 065)`.
5. **`MAJ-005` — Divergences de schéma JSON (`external_*`, `maritime_zone_ids`) et présence de `"island_class": null` sur 54 régions continentales (contraire à `data/schemas/map.schema.json`)**.
6. **`MAJ-006` — Doublons d'identifiants pour 6 fleuves (`Danube`, `Vistule`, `Dniestr`, `Niémen`, `Save`, `Drina`) et 2 chaînes de montagnes (`Carpates`, `Alpes dinariques`) entre `agent_1/terrain.json` et `agent_2/terrain.json`**.
7. **`MAJ-007` — Arête terrestre interne `region_033 <-> region_037` (`1,43 km`) omise dans `agent_1`, 3 détroits en auto-boucle dans `agent-2` et 4 détroits ouest-européens omis dans `agent_1`**.

### 6.3 Approximations acceptables (`8` — documentées, aucune modification requise)
- **`APP-001`** : Gouvernement de Kholm (1912) représenté via l'enveloppe des gouvernements de Lublin et Siedlce au sein de `region_056`.
- **`APP-002`** : Limite orientale de l'Europe (Oural et Caucase) suivie sur les subdivisions RISTAT 1897 avec coupure à `66,5°E`.
- **`APP-003`** : Reconstruction d'Eupen-Malmedy (`region_032`) via les 9 communes belges des Cantons de l'Est.
- **`APP-004`** : Monmouthshire rattaché à `region_001` selon le recensement britannique de 1911.
- **`APP-005`** : Frontière bulgaro-ottomane de Thrace (`region_073` / `region_089`) le long de la Maritsa et de l'Istranca.
- **`APP-006`** : Plans d'eau intérieurs représentés comme vides non terrestres (lac Ladoga `8 566,74 km²`, Sivach `1 019,25 km²`, lac de Ratzebourg `17,75 km²`).
- **`APP-007`** : Îles côtières et micro-enclaves historiques en Europe occidentale et centrale.
- **`APP-008`** : Exclusion des territoires extra-européens et arctiques hors cadre (Canaries, Açores, Madère, Svalbard, Dodécanèse, Chypre, Anatolie).

### 6.4 Améliorations facultatives (`5` — cosmétiques ou documentaires)
- **`OPT-001`** : Nettoyage des parenthèses/toponymes post-1914 (`"Ekaterinoslav (Dniepropetrovsk)"`, `"Oslofjord"`, noms de districts turcs modernes dans `historical_admin_units` de `region_087`–`090`).
- **`OPT-002`** : Passage de `etat_geometrie` à `"construite"` dans `data/world/map/tables/region_plan.csv` et mise à jour de `docs/map/ATLAS_BUILD_STATUS.md`.
- **`OPT-003`** : Correction documentaire de `validate_agent_1.py` / `agent_1/HANDOFF.md` (remplacés après fusion par `tools/map/validate_atlas.py` et `docs/map/audit/validate_global_atlas.py`).
- **`OPT-004`** : Ajustement optionnel de la pointe du cap de Taganrog entre `region_061` et `region_069`.
- **`OPT-005`** : Lissage optionnel du nombre de sommets de `region_052` (`4 798` sommets).

---

## 7. OUTIL DE VALIDATION SUPPLÉMENTAIRE LIVRÉ

Le script autonome `docs/map/audit/validate_global_atlas.py` a été créé pour auditer simultanément les deux lots sans modifier leurs fichiers. Il vérifie l'inventaire des 90 régions, la concordance avec `region_plan.csv`, la validité OGC, les chevauchements, le trou et l'exclave de `region_088`, les 17 interfaces inter-lots, l'inclusion géométrique des 175 villes et 65 fortifications, ainsi que la compatibilité des schémas JSON.
