# Atlas Stratégique 1914 — Lot Cartographique Agent 2 (40 régions)

Ce répertoire contient les données géographiques, topologiques, physiques et d'infrastructures construites pour les **40 régions** du périmètre de l'**Agent 2** au **1er janvier 1914**, en conformité avec `data/world/map/tables/region_plan.csv`, `docs/map/TECHNICAL_SPEC.md` et les conventions établies par le lot de l'Agent 1 (`data/world/map/build/agent_1/`).

---

## 1. Périmètre couvert (40 régions)

| Zone géographique | Nombre de régions | Identifiants | Souverainetés au 1er janvier 1914 |
| :--- | :---: | :--- | :--- |
| **Scandinavie** | **8** | `region_044` à `region_051` | Danemark (`region_044`, `region_051`), Norvège (`region_045`–`047`), Suède (`region_048`–`050`) |
| **Europe orientale** | **18** | `region_052` à `region_069` | Empire russe (`region_052`–`069`, incluant le Grand-Duché de Finlande, le Royaume du Congrès, les gouvernements baltes, biélorusses, ukrainiens, la Bessarabie, la Crimée, la Russie d'Europe jusqu'à l'Oural et la Ciscaucasie) |
| **Balkans** | **10** | `region_070` à `region_079` | Roumanie (`region_070`–`071`), Bulgarie (`region_072`–`073`), Serbie (`region_074`), Monténégro (`region_075`), Albanie (`region_076`), Grèce (`region_077`–`079`) |
| **Territoires ottomans européens** | **4** | `region_087` à `region_090` | Empire ottoman (`region_087`–`090` : Constantinople, Çatalca-Tekirdağ, Edirne/Kırklareli, Gallipoli/Dardanelles) |
| **Total Agent 2** | **40** | `40 / 90` | **11 États souverains représentés** |

---

## 2. Inventaire des fichiers produits

| Fichier | Rôle et contenu |
| :--- | :--- |
| `regions.geojson` | `FeatureCollection` GeoJSON RFC 7946 (`EPSG:4326` / `CRS84`) contenant les 40 polygones et multipolygones réels validés, orientés selon la règle de la main droite et alignés sans chevauchement ni interstice avec les 50 régions de l'Agent 1. |
| `regions.json` | Table complète des métadonnées des 40 régions (`id`, `name_fr`, `name_key`, `zone`, `sovereign_1914`, `initial_sovereign_id`, `etat_geometrie: "construite"`, `relief_categories`, `importance_dimensions`, `has_coastline`, `area_km2`, `centroid_lon_lat`, `representative_point_lon_lat`, `city_ids`, `adjacent_region_ids`, `external_adjacent_region_ids`, `maritime_zone_ids`, `historical_admin_units`, `source_layer`, `source_refs`, `approximations`). |
| `adjacency.json` | Graphe d'adjacence topologique comprenant **69 arêtes terrestres internes**, **8 passages de détroits stratégiques** (Øresund, Belts danois, Mer d'Åland, Irbe/Moonsund, Kertch, Rion-Antirion/Corinthe, Bosphore, Dardanelles) et **17 interfaces terrestres externes** avec le périmètre de l'Agent 1. |
| `cities.json` | `FeatureCollection` GeoJSON et catalogue tabulaire de **72 villes et sites stratégiques** de 1914 (dont les **11 capitales d'État** du périmètre : Copenhague, Christiania, Stockholm, Saint-Pétersbourg, Bucarest, Sofia, Belgrade, Cetinje, Durrës, Athènes, Constantinople), tous vérifiés géométriquement à l'intérieur strict de leur région. |
| `terrain.json` | Synthèse physique par région (`plains`, `forests`, `mountains`, `hills`, `marshes`), façades maritimes, catalogue de **32 grands fleuves** et **11 chaînes de montagnes** avec leurs cols et passages stratégiques. |
| `infrastructure.json` | Réseau stratégique de 1914 comprenant **53 grands axes ferroviaires**, **37 grands ports** et **33 places fortes / systèmes fortifiés** historiques de 1914 (Copenhague, Oscarsborg, Boden, Sveaborg, Kronstadt, Kovno, Varsovie/Modlin, Ivangorod/Ossovets, Brest-Litovsk/Grodno, triangle de Volhynie, Sébastopol, Bucarest, Focșani-Nămoloasa-Galați, Choumen, Belgrade, Salonique, Lignes de Çatalca, Edirne, Dardanelles, Bosphore). |
| `maritime_zones.json` | `FeatureCollection` GeoJSON et table de **16 zones maritimes intermédiaires** couvrant l'Atlantique Nord/Islande, la mer de Norvège, la mer de Barents/mer Blanche, la mer du Nord orientale, le Skagerrak/Kattegat, la Baltique, le golfe de Botnie, le golfe de Finlande/Riga, l'Adriatique méridionale/Otrante, la mer Ionienne, la mer Égée, la mer de Marmara et les Détroits, la mer Noire (ouest et est), la mer d'Azov et la mer Caspienne. |
| `sources/README.md` | Documentation exhaustive des sources géographiques et historiques utilisées, de leurs périodes de référence, de leurs licences ouvertes et de leurs limites. |
| `HANDOFF.md` | Document de passation détaillant la méthodologie, les interfaces inter-lots avec l'Agent 1, les approximations documentées et les résultats des contrôles. |
| `validate_agent_2.py` | Script de validation automatisé vérifiant la conformité géométrique, topologique, inter-lots et historique des 40 régions. |

---

## 3. Sources géographiques et licences (Synthèse)

L'intégralité des géométries repose sur des jeux de données vectoriels historiques vérifiés et placés sous licences ouvertes compatibles (`CC BY 4.0`, `CC0 1.0`, `ODbL`) :

1. **`regis_2026_v1` — REGIS Historical GIS of Europe (Schweikart et al., 2026)**
   - **Origine** : *Data Tracking of Centuries (DATA-TOC)*, Springer / Figshare (`DOI: 10.1007/978-3-032-14932-9_3`).
   - **Période** : Couches historiques par décennie/période (1870–1919 pour le Danemark, la Norvège, la Suède, l'Islande et la Finlande ; 1879–1925 pour la Roumanie, la Bulgarie, la Serbie, le Monténégro, l'Albanie et la Grèce `1914-1919`).
   - **Licence** : **CC BY 4.0**.
   - **Utilisation** : Scandinavie (`region_044` à `051`), Grand-Duché de Finlande (`region_052`) et Balkans (`region_070` à `079`).

2. **`ristat_1897_v1` — RISTAT Historical GIS of the Russian Empire (Kessler & Markevich)**
   - **Origine** : International Institute of Social History (IISH) / DataverseNL (`DOI: 10.34894/NQOASN`).
   - **Période** : Recensement impérial de 1897 (stable jusqu'au 1er janvier 1914 pour les gouvernements et ouïezds d'Europe orientale).
   - **Licence** : **CC0 1.0 Universal (Domaine public)**.
   - **Utilisation** : Gouvernements (`provinces_1897`) et ouïezds/okrougs (`ristat_1897_districts.gpkg`) des 17 régions de l'Empire russe hors Finlande (`region_053` à `region_069`).

3. **`geoboundaries_tur_v6` — geoBoundaries Turkey ADM1/ADM2 (Runfola et al., WMgeolab)**
   - **Origine** : geoBoundaries v6.0 (`gb_tur_adm1.geojson`, `gb_tur_adm2.geojson`).
   - **Période** : Limites administratives de provinces (*iller*) et districts (*ilçeler*) de Thrace orientale correspondant aux anciens sandjaks d'Istanbul, Çatalca, Tekirdağ, Kırklareli, Edirne et Gelibolu.
   - **Licence** : **CC BY 4.0**.
   - **Utilisation** : Découpage interne des 4 régions ottomanes d'Europe (`region_087`, `region_088`, `region_089`, `region_090`).

4. **`kavanagh_1914_v1` — Europe 1914 Borders (Aoife Kavanagh, 2023)**
   - **Origine** : GitHub `aoifekavanagh/europe-1914` (dérivé de CShapes 2.0, Schvitz et al. 2022).
   - **Période** : Frontières internationales d'Europe en 1914.
   - **Licence** : **CC BY 4.0**.
   - **Utilisation** : Contrôle de cohérence des frontières internationales de 1914 dans les Balkans et en Thrace après les traités de Londres, de Bucarest (10 août 1913) et de Constantinople (29 septembre 1913).

5. **`natural_earth_10m_v5` & `baedeker_bradshaw_1914`**
   - **Origine** : Natural Earth 1:10m Physical Vectors (**Domaine public / CC0**) ; guides historiques *Bradshaw's Continental Guide* (1913–1914) et *Baedeker Russia / Konstantinopel und Kleinasien / Österreich-Ungarn und Balkan* (1912–1914, **Domaine public**).
   - **Utilisation** : Bassins maritimes, fleuves majeurs, reliefs, noeuds ferroviaires et places fortes de 1914.

Voir `sources/README.md` pour le détail complet des couches et des limites méthodologiques.

---

## 4. Exécution du validateur

Depuis la racine du dépôt :

```bash
PYTHONPATH=/tmp/gs1914-gis-packages python3 data/world/map/build/agent_2/validate_agent_2.py
```
