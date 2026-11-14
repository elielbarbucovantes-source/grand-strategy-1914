# CHECKLIST D'INTÉGRATION FINALE DE L'ATLAS 1914 (90 RÉGIONS)

Ce document décrit la procédure séquentielle permettant de réunir les productions de la branche `agent_1` (50 régions, commit `286975a96fc2238040a9bf09163c664740ee3854`) et de la branche `agent-2` (40 régions, commit `baa0c90932c74a39ae8745add9a07a7686cd770e`) dans l'atlas canonique `data/world/map/`, tout en corrigeant les **3 erreurs bloquantes (`BLK-001` à `BLK-003`)** et les **7 erreurs importantes (`MAJ-001` à `MAJ-007`)** identifiées dans `docs/map/audit/GLOBAL_AUDIT.md` et `docs/map/audit/ISSUES.json`.

---

## ÉTAPE 1 — PRÉPARATION DE LA BRANCHE D'INTÉGRATION

- [ ] **1.1** Créer une branche d'intégration dédiée (par exemple `integrate/atlas-1914`) à partir de `main` (`4ffdb8a09981b8d51f103bd2c2088fed9506a71f`).
- [ ] **1.2** Importer sans écrasement les deux dossiers de build dans l'arbre de travail :
  - `git checkout agent_1 -- data/world/map/build/agent_1`
  - `git checkout agent-2 -- data/world/map/build/agent_2`
  - `git checkout audit/map-1914 -- docs/map/audit`

---

## ÉTAPE 2 — CORRECTIONS GÉOMÉTRIQUES ET HISTORIQUES SUR LES POLYGONES (`BLK-001`, `BLK-002`, `MAJ-003`, `MAJ-004`)

- [ ] **2.1 Corriger le district `"Saray"` dans `region_088` (*Çatalca et Tekirdağ*) — [`BLK-001`]** :
  - Dans la source `gb_tur_adm2.geojson`, sélectionner le district thrace de Saray (`shapeID == "54988432B91991689904144"`, centroïde `[27.9001, 41.4436]`, `684,40 km²`) ou filtrer les districts turcs par `shape(f["geometry"]).centroid.x < 30.0`.
  - Retirer de `region_088` le polygone parasite de Van (`shapeID == "54988432B48034047733274"`, centroïde `[44.1558, 38.5162]`, `938,36 km²`) et fusionner le district thrace de Saray dans `region_088`.
  - Vérifier que la bounding box de `region_088` est désormais contenue dans `[26.85, 40.73, 28.90, 41.62]` (aucun point avec `lon > 29.0`) et que le trou intérieur de `684,40 km²` entre `region_088` et `region_089` a totalement disparu.
- [ ] **2.2 Corriger le saillant de Strumica (1914 vs 1919) entre `region_074` et `region_072` — [`MAJ-003`]** :
  - Découper la poche de Strumica (`[22.6427, 41.4378]`, ~`950 km²` à l'est de `[22.50, 41.32..41.55]`) de `region_074` (Serbie) et l'unir à `region_072` (Bulgarie occidentale) afin de respecter le traité de Bucarest du 10 août 1913.
- [ ] **2.3 Combler les 4 lacunes de couture inter-sources — [`MAJ-004`]** :
  - Appliquer la fonction `fill_seam_slivers()` (en projection `EPSG:3035`) sur :
    1. `(region_052, region_064)` avec `max_sliver_m2 = 750e6` pour absorber la lacune de `662,47 km²` à `[32.3258, 62.6315]` (Suojärvi/Olonets) ;
    2. `(region_040, region_062, region_071)` avec `buffer_m = 10000` pour absorber la lacune de `225,88 km²` au tripoint de Khotin/Herța (`[26.1997, 48.3030]`) ;
    3. `(region_047, region_065)` pour absorber les deux lacunes de `117,05 km²` et `92,09 km²` le long de la rivière Pasvik (`[30.5256, 69.5879]` et `[29.7994, 69.4143]`).
  - Ne pas combler les plans d'eau réels (`APP-006` : lac Ladoga `8 566,74 km²`, lagune du Sivach `1 019,25 km²`, lac de Ratzebourg `17,75 km²`).
- [ ] **2.4 Purger les 15 micro-chevauchements d'arrondi de coordonnées — [`BLK-002`]** :
  - Après arrondi des coordonnées à 6 décimales et orientation RFC 7946 sur les 90 géométries (`region_001` à `region_090`), exécuter une passe déterministe d'élimination des micro-intersections :
    ```python
    for i, rid_a in enumerate(sorted_ids):
        for rid_b in sorted_ids[i + 1:]:
            if geoms[rid_a].intersects(geoms[rid_b]):
                inter = geoms[rid_a].intersection(geoms[rid_b])
                if inter.area > 0:
                    geoms[rid_b] = snap_and_orient_polygons_only(geoms[rid_b].difference(geoms[rid_a]))
    ```
  - Vérifier que **toutes les 4 005 paires** de régions ont désormais `inter.area <= 1e-10 deg²` (c'est-à-dire `0` chevauchement détecté par `tools/map/validate_atlas.py`).
- [ ] **2.5 Recalculer les métriques géométriques dérivées** :
  - Mettre à jour `centroid`, `representative_point` et `area_km2` (en `EPSG:3035`) pour les régions retouchées (`region_088`, `region_072`, `region_074`, `region_040`, `region_047`, `region_052`, `region_062`, `region_064`, `region_065`, `region_071`).

---

## ÉTAPE 3 — UNIFICATION DU GRAPHE D'ADJACENCE ET DES DÉTROITS (`BLK-003`, `MAJ-007`)

- [ ] **3.1 Promouvoir les 17 interfaces terrestres inter-lots en arêtes standard — [`BLK-003`]** :
  - Intégrer dans la liste unique `edges` de `data/world/map/adjacency.json` :
    - les `97` arêtes internes d'`agent_1` ;
    - l'arête interne `adj_region_033_region_037` (`shared_border_km: 1.43`, **[`MAJ-007`]**) ;
    - les `69` arêtes internes d'`agent-2` ;
    - les **`17` arêtes terrestres inter-lots** (`4 335,96 km` au total), y compris **`adj_region_026_region_056` (`368,87 km`)** qui manquait dans `agent_1/adjacency.json` :
      1. `region_029 <-> region_044` (`88.19 km`)
      2. `region_026 <-> region_054` (`181.59 km`)
      3. `region_026 <-> region_056` (`368.87 km`)
      4. `region_026 <-> region_055` (`55.79 km`)
      5. `region_027 <-> region_055` (`423.96 km`)
      6. `region_030 <-> region_055` (`168.51 km`)
      7. `region_040 <-> region_055` (`264.53 km`)
      8. `region_040 <-> region_056` (`263.41 km`)
      9. `region_040 <-> region_058` (`435.39 km`)
      10. `region_040 <-> region_062` (`36.02 km`)
      11. `region_040 <-> region_071` (`294.97 km`)
      12. `region_042 <-> region_071` (`267.72 km`)
      13. `region_042 <-> region_070` (`440.64 km`)
      14. `region_041 <-> region_070` (`86.44 km`)
      15. `region_041 <-> region_074` (`217.60 km`)
      16. `region_043 <-> region_074` (`451.83 km`)
      17. `region_043 <-> region_075` (`310.50 km`)
  - Total attendu dans `data/world/map/adjacency.json` : **`184` arêtes terrestres** (`97 + 1 + 69 + 17`), 100 % symétriques.
- [ ] **3.2 Mettre à jour `neighbors_by_region` et `adjacent_region_ids` sur les 90 régions — [`BLK-003`]** :
  - Recalculer `neighbors_by_region` et `adjacent_region_ids` (dans `regions.json` et `regions.geojson`) directement à partir des 184 arêtes terrestres.
  - Vérifier que `region_044` (Danemark) a bien `adjacent_region_ids: ["region_029"]` et que seules les 3 îles pures (`region_051`, `region_085`, `region_086`) ont `adjacent_region_ids: []`.
  - Supprimer les clés temporaires de chantier `external_adjacent_region_ids`, `external_neighbors_by_region`, `external_perimeter_interfaces` et `total_external_perimeter_interfaces`.
- [ ] **3.3 Harmoniser `strait_crossings` — [`MAJ-007`]** :
  - Conserver les 6 détroits inter-régionaux existants (`strait_messina_084_085`, `strait_oresund_044_050`, `strait_kattegat_044_049`, `strait_skagerrak_044_045`, `strait_aland_048_052`, `strait_kerch_063_069`).
  - Ajouter les 4 détroits stratégiques d'Europe de l'Ouest :
    - `strait_dover_001_007` (`region_001 <-> region_007`, Pas de Calais / Strait of Dover) ;
    - `strait_north_channel_003_005` (`region_003 <-> region_005`, Canal du Nord) ;
    - `strait_st_george_004_006` (`region_004 <-> region_006`, Canal Saint-Georges / Mer d'Irlande) ;
    - `strait_bonifacio_012_086` (`region_012 <-> region_086`, Bouches de Bonifacio).
  - Pour les 3 détroits intra-régionaux (`strait_danish_belts`, `strait_bosphorus`, `strait_dardanelles`), soit les relier à une région voisine le long du détroit (`region_044 <-> region_028` pour Fehmarn Belt, `region_087 <-> region_088` et `region_090 <-> region_088`), soit les déplacer dans une section dédiée `internal_straits` afin d'éviter toute auto-boucle `region_a_id == region_b_id`.

---

## ÉTAPE 4 — HARMONISATION DES FICHIERS THÉMATIQUES ET DES SCHÉMAS (`MAJ-001`, `MAJ-002`, `MAJ-005`, `MAJ-006`, `OPT-001`)

- [ ] **4.1 Unifier `cities.json` (175 villes) et nettoyer la toponymie 1914 — [`OPT-001`]** :
  - Concaténer les 103 villes d'`agent_1` et les 72 villes d'`agent-2` triées par `region_id`.
  - Remplacer `"Ekaterinoslav (Dniepropetrovsk)"` par `"Ekaterinoslav"` sur `city_ekaterinoslav`.
- [ ] **4.2 Unifier `infrastructure.json` et ajouter les 10 axes ferroviaires inter-lots — [`MAJ-002`]** :
  - Concaténer les `76 + 53 = 129` axes ferroviaires, `47 + 37 = 84` ports majeurs et `32 + 33 = 65` fortifications.
  - Ajouter les **10 axes ferroviaires internationaux 1914** reliant les deux lots :
    1. `rail_hamburg_aarhus` (`city_hamburg` -> `city_kiel` -> `city_aarhus`, `["region_029", "region_044"]`) ;
    2. `rail_konigsberg_kovno` (`city_konigsberg` -> `city_kaunas`, `["region_026", "region_054"]`) ;
    3. `rail_posen_warsaw` (`city_posen` -> `city_thorn` -> `city_warsaw`, `["region_027", "region_055"]`) ;
    4. `rail_kattowitz_warsaw` (`city_kattowitz` -> `city_lodz` -> `city_warsaw`, `["region_030", "region_055"]`) ;
    5. `rail_krakow_warsaw` (`city_krakow` -> `city_warsaw`, `["region_040", "region_055"]`) ;
    6. `rail_lemberg_kiev` (`city_lemberg` -> `city_zhytomyr` -> `city_kiev`, `["region_040", "region_058", "region_059"]`) ;
    7. `rail_czernowitz_iasi` (`city_czernowitz` -> `city_iasi`, `["region_040", "region_071"]`) ;
    8. `rail_brasso_bucharest` (`city_brasso` -> `city_ploiesti` -> `city_bucharest`, `["region_042", "region_070"]`) ;
    9. `rail_temesvar_bucharest` (`city_temesvar` -> `city_craiova` -> `city_bucharest`, `["region_041", "region_070"]`) ;
    10. `rail_budapest_belgrade` (`city_budapest` -> `city_ujvidek` -> `city_belgrade`, `["region_041", "region_074"]`).
- [ ] **4.3 Unifier `terrain.json` et fusionner les fleuves et massifs transfrontaliers — [`MAJ-005`, `MAJ-006`]** :
  - Supprimer la clé `"island_class": null` sur les 54 régions purement continentales pour respecter `data/schemas/map.schema.json`.
  - Fusionner les 6 fleuves transfrontaliers dans `major_river_courses` :
    - `river_danube` + `river_danube_lower` -> `river_danube` (`["region_033", "region_034", "region_036", "region_041", "region_043", "region_074", "region_070", "region_072", "region_073", "region_071", "region_062"]`) ;
    - `river_vistula` + `river_vistula_middle` -> `river_vistula` (`["region_030", "region_040", "region_055", "region_056", "region_027"]`) ;
    - `river_dniester` (Lot 1 + Lot 2) -> `river_dniester` (`["region_040", "region_058", "region_062", "region_060"]`) ;
    - `river_niemen` (Lot 1 + Lot 2) -> `river_niemen` (`["region_057", "region_054", "region_056", "region_026"]`) ;
    - `river_sava` (Lot 1 + Lot 2) -> `river_sava` (`["region_037", "region_043", "region_074"]`) ;
    - `river_drina` (Lot 1 + Lot 2) -> `river_drina` (`["region_075", "region_043", "region_074"]`).
  - Fusionner les 2 chaînes de montagnes transfrontalières dans `mountain_chains` :
    - `mtn_carpathians` + `mtn_carpathians_east_south` -> `mtn_carpathians` (`["region_039", "region_040", "region_041", "region_042", "region_058", "region_070", "region_071"]`) ;
    - `mtn_dinaric_alps` + `mtn_dinaric_prokletije_sar` -> `mtn_dinaric_alps` (`["region_037", "region_043", "region_074", "region_075", "region_076"]`).
- [ ] **4.4 Compléter `maritime_zones.json` et `maritime_zone_ids` — [`MAJ-001`]** :
  - Étendre `maritime_zones.json` avec les bassins maritimes d'Europe occidentale et de Méditerranée occidentale/centrale (Manche, mer d'Irlande, Atlantique Nord-Est, golfe de Gascogne, détroit de Gibraltar, Méditerranée occidentale, mer Tyrrhénienne, Adriatique septentrionale) et renseigner `maritime_zone_ids` sur les régions côtières d'`agent_1` (ou retirer `maritime_zone_ids` de `regions.json` si le schéma canonique `map.schema.json` ne le requiert pas).

---

## ÉTAPE 5 — VALIDATION FINALE ET MISE À JOUR DES TABLES DE SUIVI (`OPT-002`)

- [ ] **5.1** Écrire les fichiers finaux assemblés dans `data/world/map/` :
  - `data/world/map/regions.geojson`
  - `data/world/map/regions.json`
  - `data/world/map/adjacency.json`
  - `data/world/map/cities.json`
  - `data/world/map/infrastructure.json`
  - `data/world/map/terrain.json`
  - `data/world/map/maritime_zones.json`
- [ ] **5.2** Mettre à jour `data/world/map/tables/region_plan.csv` (`etat_geometrie = "construite"` sur les 90 lignes) et `docs/map/ATLAS_BUILD_STATUS.md` (`90 / 90 régions construites et validées`).
- [ ] **5.3** Exécuter les deux validateurs :
  - `python3 tools/map/validate_atlas.py` -> doit retourner `0` erreur et `exit code 0`.
  - `python3 docs/map/audit/validate_global_atlas.py` -> doit retourner `exit code 0` avec `0` erreur bloquante.
