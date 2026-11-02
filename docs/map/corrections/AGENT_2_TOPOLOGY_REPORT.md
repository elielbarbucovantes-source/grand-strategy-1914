# RAPPORT — AGENT 2 TOPOLOGIE

## Livraison `fix/map-topology-v2` — Grand Strategy-1914

- **Date** : 2 novembre 2026
- **Branche de travail** : `fix/map-topology-v2`
- **Worktree** : `/tmp/opencode/gs1914-topology-v2`
- **Commit de départ vérifié** : `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` (`audit/map-1914`)
- **Commit de livraison (données + scripts)** : `879fc4ea78482932bea322378e66db0fd807cc51`
- **Commit d'import des sources** : `1497f91` (lots `agent_1` et `agent-2` importés sans modification)
- **Sources** : `agent_1` = `286975a96fc2238040a9bf09163c664740ee3854` (50 régions) ; `agent-2` = `baa0c90932c74a39ae8745add9a07a7686cd770e` (40 régions).
- **Aucune fusion effectuée.** Aucune branche existante déplacée. Aucun fichier géométrique ou thématique source modifié.

---

## 1. Synthèse exécutive

| Indicateur | Résultat |
|---|---:|
| Régions référencées | **90 / 90** |
| Arêtes terrestres | **184** |
| Relations terrestres réciproques | **184 / 184** |
| Interfaces inter-lots | **17 / 17** |
| Dont `region_026 <-> region_056` | **présente** |
| Arête manquante `region_033 <-> region_037` | **présente** |
| Détroits inter-régionaux | **10** |
| Détroits strictement internes | **3** |
| Passages maritimes totaux | **13** |
| Connexions entre zones maritimes | **14** |
| Relations maritimes réciproques | **14 / 14** |
| Régions terrestres isolées | **3** (`051`, `085`, `086`) |
| Contrôles du validateur | **55 / 55 réussis** |

**Verdict : livraison complète et validée sur le périmètre topologique.**

Le graphe terrestre n'est pas construit à partir d'un total imposé : les 184 arêtes sont dérivées des frontières réellement partagées par les 90 polygones. Le total de 184 correspond exactement aux 166 arêtes internes des deux lots, aux 17 interfaces inter-lots et à l'arête manquante `033/037`.

---

## 2. Livrables

| Fichier | Rôle |
|---|---|
| `data/world/map/adjacency.json` | Graphe canonique des 90 régions : arêtes terrestres, détroits, détroits internes et connexions entre zones maritimes |
| `tools/map/build_adjacency.py` | Construction reproductible du fichier depuis les deux lots |
| `tools/map/validate_topology.py` | Validation reproductible en lecture seule |
| `docs/map/corrections/AGENT_2_TOPOLOGY_REPORT.md` | Présent rapport |

Empreinte SHA-256 de `data/world/map/adjacency.json` :

```text
6ad5f8da0195da74be9c2530bea3d5ecbb63adde6664b0d22f65054e3c73d6f2
```

Deux exécutions consécutives du constructeur produisent la même empreinte.

---

## 3. Méthode de construction

1. Import des deux lots dans un worktree indépendant, sans modification de leurs fichiers.
2. Lecture des 90 géométries (`regions.geojson`) et des métadonnées (`regions.json`).
3. Projection en **EPSG:3035** pour mesurer les frontières.
4. Calcul exhaustif des 4 005 paires de régions.
5. Conservation d'une arête terrestre uniquement si les deux polygones partagent une frontière mesurable de plus de **10 m**.
6. Récupération des 166 arêtes déjà déclarées, puis ajout des 18 interfaces géométriques non déclarées : 17 inter-lots + `033/037`.
7. Recalcul complet de `neighbors_by_region` et de `adjacent_region_ids` à partir des 184 arêtes.
8. Traitement séparé des détroits inter-régionaux, des détroits internes et des connexions entre zones maritimes.

Aucune arête terrestre n'est créée sans support géométrique : le validateur recalcule les 184 interfaces et vérifie l'égalité stricte avec le fichier livré.

---

## 4. BLK-003 — Interfaces inter-lots

Les 17 interfaces terrestres de l'audit sont intégrées. Chacune est marquée `interlot_interface: true`.

| Région A | Région B | Longueur déclarée (km) | Contact géométrique exact (km) |
|---|---|---:|---:|
| `region_026` | `region_054` | 181,65 | 180,54 |
| `region_026` | `region_055` | 55,79 | 54,68 |
| **`region_026`** | **`region_056`** | **368,87** | **365,47** |
| `region_027` | `region_055` | 423,93 | 423,69 |
| `region_029` | `region_044` | 88,26 | 79,80 |
| `region_030` | `region_055` | 168,51 | 168,27 |
| `region_040` | `region_055` | 264,53 | 264,00 |
| `region_040` | `region_056` | 263,62 | 261,67 |
| `region_040` | `region_058` | 435,40 | 429,54 |
| `region_040` | `region_062` | 36,02 | 33,22 |
| `region_040` | `region_071` | 294,97 | 268,20 |
| `region_041` | `region_070` | 86,44 | 70,52 |
| `region_041` | `region_074` | 217,60 | 202,00 |
| `region_042` | `region_070` | 440,65 | 388,58 |
| `region_042` | `region_071` | 267,73 | 206,93 |
| `region_043` | `region_074` | 451,87 | 380,06 |
| `region_043` | `region_075` | 310,50 | 267,63 |

### Cas `region_026 <-> region_056`

L'interface est présente avec :

- `shared_border_km: 368.87` (valeur de référence de l'audit) ;
- `agent_2_shared_border_km: 369.18` (valeur du fichier source `agent-2`) ;
- `geometry_shared_border_km: 365.47` (contact exact mesuré en EPSG:3035) ;
- `topology_action: "BLK-003"` ;
- `interlot_interface: true`.

Les trois valeurs sont conservées pour que l'écart documentaire soit traçable. Le graphe utilise la valeur de référence de l'audit.

### Voisins inter-lots ajoutés

`neighbors_by_region` et `adjacent_region_ids` contiennent les 90 listes recalculées. Exemples vérifiés :

- `region_044` (Danemark) : `["region_029"]` ;
- `region_026` : `["region_027", "region_054", "region_055", "region_056"]` ;
- `region_056` : `["region_026", "region_040", "region_054", "region_055", "region_057", "region_058"]` ;
- `region_040` inclut `region_055`, `region_056`, `region_058`, `region_062` et `region_071`.

Les fichiers sources `build/agent_1/regions.json` et `build/agent_2/regions.json` n'ont pas été modifiés. La table `adjacent_region_ids` du fichier d'adjacence est la version recalculée à injecter dans l'atlas canonique lors de l'assemblage.

---

## 5. MAJ-007 — Arêtes terrestres

- **Arête `region_033 <-> region_037` ajoutée** : `shared_border_km: 1.43` (audit), `geometry_shared_border_km: 1.13`, `missing_land_edge: true`, `topology_action: "MAJ-007"`.
- Les deux régions se listent mutuellement dans `neighbors_by_region`.
- **184 arêtes terrestres** au total : 97 internes à `agent_1` + 69 internes à `agent_2` + 17 inter-lots + 1 arête manquante.
- Le validateur recalcule les interfaces géométriques et confirme qu'il n'existe ni arête artificielle ni interface oubliée.

---

## 6. Détroits

### 6.1 Auto-boucles corrigées

Les trois entrées qui avaient `region_a_id == region_b_id` sont déplacées dans la section `internal_straits`, avec un seul `region_id` :

| Identifiant | Région |
|---|---|
| `strait_danish_belts_044_044` | `region_044` |
| `strait_bosphorus_087` | `region_087` |
| `strait_dardanelles_090` | `region_090` |

Elles ne sont plus des auto-boucles et ne sont pas transformées en frontières terrestres.

### 6.2 Passages ajoutés

| Identifiant | Régions | Détroit |
|---|---|---|
| `strait_dover_001_007` | `region_001` / `region_007` | Pas de Calais / Douvres |
| `strait_north_channel_003_005` | `region_003` / `region_005` | Canal du Nord |
| `strait_st_george_004_006` | `region_004` / `region_006` | Canal Saint-Georges |
| `strait_bonifacio_012_086` | `region_012` / `region_086` | Bouches de Bonifacio |

### 6.3 Bilan des passages

- **6 détroits inter-régionaux conservés** : Messine, Øresund, Åland, Moonsund/Irbe, Kertch, Rion-Antirion.
- **10 détroits inter-régionaux** au total avec les 4 ajouts.
- **3 détroits internes**.
- **13 passages maritimes** au total.

Deux couples cumulent légitimement une frontière terrestre et une liaison maritime :

- `region_053 <-> region_054` (Moonsund/Irbe + frontière de Courlande) ;
- `region_077 <-> region_079` (Rion-Antirion/Corinthe + isthme).

Ils sont marqués `also_land_adjacent: true` et restent dans deux sections distinctes. Aucun détroit n'est compté comme arête terrestre.

---

## 7. Connexions entre zones maritimes

Le fichier reprend les **16 zones maritimes** du catalogue `agent_2/maritime_zones.json` et construit **14 connexions réciproques** à partir de `adjacent_maritime_zone_ids`.

- 14 / 14 connexions sont réciproques.
- Aucune auto-boucle.
- La mer Caspienne est la seule zone isolée (`mz_caspian_sea`), ce qui est cohérent avec une mer fermée sans connexion au catalogue.

Les relations sont dans une section distincte `maritime_zone_connections`, avec `connection_type: "maritime_zone"` et `boundary_kind: "sea"`.

---

## 8. Régions isolées

Le graphe terrestre ne contient que trois régions sans voisin terrestre, conformément à l'audit :

| Région | Justification |
|---|---|
| `region_051` | Islande : île sans frontière terrestre, aucun détroit inter-régional |
| `region_085` | Sicile : île, reliée à `region_084` par le détroit de Messine |
| `region_086` | Sardaigne : île, reliée à `region_012` par les Bouches de Bonifacio |

Chaque justification est enregistrée dans `isolated_regions` avec le nom français de la région.

---

## 9. Validation

Commande exécutée :

```bash
PYTHONPATH=/tmp/gs1914-gis-packages python3 tools/map/validate_topology.py
```

Résultat :

```text
RÉSULTAT : VALIDÉ — 55 contrôles, 0 échec
```

Les contrôles couvrent notamment :

- 90 identifiants `region_001`..`region_090` et couverture des 90 régions ;
- 184 arêtes, identifiants uniques, aucun doublon, aucune auto-boucle ;
- 184 / 184 relations terrestres réciproques ;
- égalité stricte entre les arêtes livrées et les interfaces géométriques mesurées ;
- 17 interfaces inter-lots, dont `026/056` ;
- présence de `033/037` et réciprocité des voisins ;
- 10 détroits inter-régionaux sans auto-boucle ;
- 3 détroits internes correctement séparés ;
- 4 détroits requis et distance entre rives < 100 km ;
- 14 connexions maritimes réciproques ;
- 3 régions isolées et leurs justifications.

Le script de construction et le validateur compilent sans erreur (`python3 -m py_compile`).

---

## 10. Problèmes non résolus et points d'attention

1. **Défauts géométriques hors périmètre topologique** : `BLK-001` (trou de Saray de 684,40 km² et exclave de Van de 938,36 km² dans `region_088`), `BLK-002` (15 micro-chevauchements d'arrondi) et `MAJ-004` (4 lacunes de couture) restent présents dans les géométries sources. Ils n'empêchent pas le graphe terrestre actuel, mais toute correction géométrique devra être suivie d'une ré-exécution de `build_adjacency.py` et `validate_topology.py`.
2. **Écart arithmétique dans l'audit** : le total inter-lots annoncé est `4 335,96 km`, alors que la somme de ses 17 lignes donne `4 355,96 km`. La somme des valeurs livrées est `4 356,34 km`. L'écart est documentaire ; les 17 relations et la relation `026/056` sont bien présentes.
3. **Identifiants de détroits divergents entre l'audit et le lot réel** : l'audit cite notamment `strait_oresund_044_050`, `strait_kattegat_044_049` et `strait_skagerrak_044_045`, alors que `agent-2/adjacency.json` contient `strait_oresund_044_048`, `strait_aland_049_052`, `strait_moonsund_irbe_053_054`, etc. La livraison conserve les relations réellement présentes et valides ; les trois auto-boucles citées par l'audit sont bien corrigées.
4. **Longueurs `026/056` et `033/037`** : trois mesures coexistent (`368,87` audit, `369,18` source agent-2, `365,47` géométrie exacte pour `026/056` ; `1,43` audit et `1,13` géométrie pour `033/037`). Elles sont conservées séparément pour éviter toute perte d'information.
5. **Métadonnées de région non modifiées** : `regions.json` et `regions.geojson` des lots restent intacts. La table `adjacent_region_ids` est fournie dans `adjacency.json` ; l'étape d'assemblage canonique devra l'injecter dans les enregistrements de région si le format final l'exige.
6. **Validateur global non exécutable** : `tools/map/validate_atlas.py` attend `data/world/map/regions.geojson`, absent de cette branche. La validation livrée porte donc sur l'adjacence, pas sur l'atlas fusionné complet.

---

## 11. Reproduction

```bash
cd /tmp/opencode/gs1914-topology-v2
PYTHONPATH=/tmp/gs1914-gis-packages python3 tools/map/build_adjacency.py
PYTHONPATH=/tmp/gs1914-gis-packages python3 tools/map/validate_topology.py
```

Le constructeur réécrit uniquement `data/world/map/adjacency.json`. Le validateur ne modifie aucun fichier.

---

## 12. Hashes

| Référence | Hash |
|---|---|
| Commit de départ | `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` |
| Import des lots | `1497f91` |
| **Commit de livraison données + scripts** | **`879fc4ea78482932bea322378e66db0fd807cc51`** |
| `agent_1` source | `286975a96fc2238040a9bf09163c664740ee3854` |
| `agent-2` source | `baa0c90932c74a39ae8745add9a07a7686cd770e` |
| SHA-256 `adjacency.json` | `6ad5f8da0195da74be9c2530bea3d5ecbb63adde6664b0d22f65054e3c73d6f2` |
