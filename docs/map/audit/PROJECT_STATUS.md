# TABLEAU DE BORD — ÉTAT RÉEL DE L'ATLAS GRAND STRATEGY-1914

> **HISTORIQUE (bandeau ajouté le 14/11/2026).** Rapport daté, exact à sa date (13/11/2026). Les opérations qu'il prévoit ont depuis été réalisées : géométrie consolidée, Strumica validée (`47bc6fe`), topologie reconstruite (`40a3117`). État courant : `docs/project/audit-2026-11/01_ETAT_GENERAL.md`. Texte conservé sans modification.

- **Date du diagnostic** : 13 novembre 2026
- **Dépôt audité** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **HEAD au moment du diagnostic** : branche `fix/map-thematic-data`, commit `b5a07ae` (commit d'audit global)
- **Nature du présent document** : diagnostic en lecture seule. Aucune donnée, branche, géométrie ou fichier canonique n'a été modifié pour l'établir.
- **Remote Git** : **aucun**. Toutes les branches sont locales et ne sont poussées nulle part.

> Ce tableau de bord décrit l'état **constaté**, pas l'état annoncé. Une anomalie n'est comptée comme résolue que si l'artefact corrigé existe réellement sur une branche ou dans l'arbre de travail. Plusieurs rapports de mission annoncent des livraisons complètes dont les données n'existent plus.

---

## 1. RÉSUMÉ EXÉCUTIF

L'atlas 1914 a été construit en deux lots indépendants (`agent_1` = 50 régions, `agent-2` = 40 régions), audité, puis corrigé sur **des branches séparées qui n'ont jamais été réunies**. Il n'existe aujourd'hui **aucun fichier canonique unique** contenant à la fois les géométries corrigées, la topologie unifiée et les données thématiques.

Concrètement :

- **Ce qui existe et est solide** : deux lots de géométries de très bonne qualité structurelle et historique (90/90 régions), un audit global complet (23 anomalies classées), un assemblage géométrique corrigé des erreurs bloquantes `BLK-001` et `BLK-002`, un graphe d'adjacence unifié à 184 arêtes, et un catalogue de 175 villes.
- **Ce qui manque ou a été perdu** : les géométries corrigées des 4 lacunes `MAJ-004` (elles n'existaient que dans un répertoire `/tmp` supprimé), l'attribution de Strumica (`MAJ-003`, toujours non résolue), les données thématiques unifiées (terrain, infrastructures, zones maritimes), et **l'intégralité de l'inventaire des ressources naturelles** (le document annoncé n'existe nulle part).
- **Ce qui bloque l'intégration** : aucune branche n'est fusionnée dans `main`; les artefacts vivent sur des branches mutuellement incompatibles (la géométrie corrigée ignore la topologie unifiée, et réciproquement).
- **Environnement** : aucun validateur GIS (`shapely`, `geopandas`, `fiona`, `pyproj`, `pyogrio`) n'est installé. Seuls les contrôles JSON et Git ont pu être rejoués.

**Verdict** : le projet est récupérable sans recommencer le travail des agents. Mais l'intégration suppose de **reconstruire une chaîne linéaire** géométrie → topologie → thématique, sur une branche d'intégration dédiée, avec les sources externes re-téléchargées.

---

## 2. CARTE DES BRANCHES ET DES COMMITS

| Branche | Commit | Rôle réel | État constaté |
|---|---|---|---|
| `main` | `4ffdb8a` | Socle documentaire | Docs + schéma + `region_plan.csv` ; **aucune donnée cartographique** |
| `agent_1` | `286975a` | Lot 1 (50 régions) | Livré (géométries, villes, terrain, infra, adjacence interne) |
| `agent-2` | `baa0c90` | Lot 2 (40 régions) | Livré (idem + `maritime_zones.json`) |
| `audit/map-1914` | `b5a07ae` | Audit global | Livré (`GLOBAL_AUDIT.md`, `ISSUES.json`, `INTEGRATION_CHECKLIST.md`, validateur) |
| `fix/map-geometry` | `b5a07ae` | — | **Branche vide** (aucun travail propre, pointe sur le commit d'audit) |
| `fix/map-geometry-v2` | `fc26c18` | Géométrie assemblée + `BLK-001`/`BLK-002` | Livrée, **non fusionnée**. Contient `regions.geojson`/`regions.json` canoniques |
| `fix/map-geometry-gaps` | `219373b` | Lacunes `MAJ-004` | **Partielle** : script + rapport commités, **données corrigées perdues** |
| `fix/map-topology` | `b5a07ae` | — | **Branche vide** |
| `fix/map-topology-v2` | `76333e1` | Adjacence unifiée | Livrée, **non fusionnée**. `adjacency.json` à 184 arêtes |
| `fix/map-thematic-data` | `b5a07ae` | — | **Branche vide** |
| `fix/map-thematic-data-v2` | `4dbf4f8` | Villes unifiées | **Partielle** : `cities.json` (175) seulement |
| `audit/map-thematic-data` | `8a5d2bf` | Audit thématique | Livré (rapport) |
| `audit/natural-resources-inventory` | `8a5d2bf` | Ressources naturelles | **Mal nommée** : identique à `audit/map-thematic-data`, **ne contient aucune ressource** |
| `integrate/map-1914-final-audit` | `219373b` | « Intégration finale » | **Trompeuse** : identique à `fix/map-geometry-gaps`, **aucune intégration** |

**Constats structurels :**

1. Les branches `fix/map-geometry`, `fix/map-topology` et `fix/map-thematic-data` sont des **coquilles vides** au commit d'audit. Le travail réel est sur les branches `-v2` correspondantes. Toute personne qui se fierait aux noms de branches non-`v2` ne trouverait rien.
2. `audit/natural-resources-inventory` et `integrate/map-1914-final-audit` portent des noms qui **ne correspondent pas à leur contenu**.
3. Aucune de ces branches n'est fusionnée dans `main`. `main` reste au stade « inventaire documentaire ».

---

## 3. OÙ VIVENT RÉELLEMENT LES ARTEFACTS CANONIQUES

| Artefact canonique | Branche porteuse | État |
|---|---|---|
| `data/world/map/regions.geojson` | `fix/map-geometry-v2` | 90 régions, corrections `BLK-001` + `BLK-002` ; lacunes `MAJ-004` **non** comblées ; Strumica **non** corrigée |
| `data/world/map/regions.json` | `fix/map-geometry-v2` | 90 régions ; `adjacent_region_ids` **non fusionnés** avec la topologie |
| `data/world/map/adjacency.json` | `fix/map-topology-v2` | 184 arêtes, 10 détroits, 3 détroits internes ; **construit depuis les lots NON corrigés** |
| `data/world/map/cities.json` | `fix/map-thematic-data-v2` | 175 villes ; **aucun champ `resources`** |
| `data/world/map/terrain.json` | — | **N'existe pas** au niveau canonique |
| `data/world/map/infrastructure.json` | — | **N'existe pas** au niveau canonique |
| `data/world/map/maritime_zones.json` | — | **N'existe pas** au niveau canonique |
| `data/world/map/tables/region_plan.csv` | `main` (et toutes) | 90 lignes ; `etat_geometrie = non_construite` sur **les 90** (option `OPT-002` jamais appliquée) |

**Point critique** : aucun artefact canonique n'est le résultat d'une fusion réelle. La géométrie corrigée (`fc26c18`) et la topologie unifiée (`76333e1`) sont issues de deux lignes parallèles : la seconde a été construite depuis les **lots d'origine** (`b5a07ae`), donc **toute correction de géométrie invalide la topologie existante** et impose de la reconstruire.

---

## 4. BILAN A–E (reprenant la grille d'audit de la mission)

### A. Inventaire des 90 régions — ✅ ACQUIS
- 90 identifiants (`region_001`…`region_090`), 50 + 40, aucun doublon, correspondance 100 % avec `region_plan.csv` sur l'ID, le nom, la zone et la souveraineté.
- 9 macro-zones conformes (Îles Britanniques 6, Europe occidentale 13, Péninsule ibérique 6, Europe centrale 18, Scandinavie 8, Europe orientale 18, Balkans 10, Italie 7, Ottomans européens 4).
- **Validé par inspection JSON** dans cet environnement.

### B. Géométrie — ⚠️ PARTIELLE
- Validité OGC 90/90 et orientation RFC 7946 : annoncées par l'audit et le rapport de correction (non rejouables ici, faute de `shapely`).
- `BLK-001` (Saray / exclave de Van) : **corrigée** sur `fix/map-geometry-v2`. `region_088` bbox `[26.693293, 40.723, 28.701899, 41.609741]`, aire recalculée `7 933,51 km²`.
- `BLK-002` (15 micro-chevauchements, `375,18 m²` cumulés) : **corrigée** sur `fix/map-geometry-v2`.
- `MAJ-003` (Strumica, ~`950 km²` dans `region_074` au lieu de `region_072`) : **NON CORRIGÉE**. Blocage documentaire : aucune couche historique ne permet de tracer la frontière interne 1913 sans approximation.
- `MAJ-004` (4 lacunes de couture, `1 097,49 km²`) : **NON CORRIGÉES dans un artefact persistant**. La résolution existe dans un rapport (`GEOMETRY_GAPS_RESOLUTION.md`) mais les géométries ne vivaient que dans `/tmp/opencode/...`, **supprimé**.
- **Métrique `region_088` non fiable** : l'audit donne deux valeurs contradictoires (`6 704,61` et `6 450,65 km²`), le GeoJSON d'origine `8 188,30 km²`, la correction `7 933,51 km²`. Aucune valeur unique ne fait autorité.

### C. Adjacence / topologie — ⚠️ PARTIELLE
- `adjacency.json` (`fix/map-topology-v2`) : **184 arêtes terrestres** (97 + 1 + 69 + 17), **17 interfaces inter-lots**, **10 détroits inter-régionaux**, **3 détroits internes**, 14 connexions maritimes, 55/55 contrôles du validateur — selon le rapport de l'agent.
- **Mais** : construit depuis les lots **non corrigés** (`b5a07ae`). Toute géométrie corrigée l'invalide.
- **Résidus `BLK-003` dans `regions.json`/`regions.geojson` de `fix/map-geometry-v2`** : 4 régions ont `adjacent_region_ids = []` (`region_044`, `region_051`, `region_085`, `region_086`) alors que seules 3 îles pures devraient l'être ; `region_044` (Danemark) doit avoir `["region_029"]` (ce que confirme `neighbors_by_region` de la topologie).
- **40 régions portent encore la clé de chantier `external_adjacent_region_ids`** dans `regions.json` et `regions.geojson` (les clés `external_*` devaient être supprimées à l'intégration — `MAJ-005`).

### D. Données historiques — ⚠️ PARTIELLE
- Corrections majeures 1914 conformes (Alsace-Lorraine allemande, Trentin/Tyrol du Sud/Trieste/Istrie austro-hongrois, Irlande entière britannique, Islande danoise, Bosnie-Herzégovine austro-hongroise, Albanie indépendante).
- **2 anomalies historiques subsistent** : Strumica (`MAJ-003`) et Saray (`BLK-001`, corrigé mais non intégré).
- **Toponymes post-1914** dans quelques métadonnées (`OPT-001`, ex. `Dniepropetrovsk`).
- **Ressources naturelles** : travail **absent** du dépôt (voir §6).

### E. Compatibilité des données — ⚠️ PARTIELLE
- Clés JSON hétérogènes entre lots (`MAJ-005`), `island_class: null` non conforme au schéma.
- **6 fleuves et 2 massifs transfrontaliers scindés** sous des identifiants distincts (`MAJ-006`).
- `maritime_zones.json` présent dans le lot 2, absent du lot 1 (`MAJ-001`).
- **0 axe ferroviaire inter-lots** (`MAJ-002`) ; réseau fragmenté au raccord des deux lots.
- Routes : **absentes** (MAP-DEC-08 non honorée).

---

## 5. CE QUI EST FAIT ET VALIDÉ

1. **Inventaire 90 régions** conforme à `region_plan.csv` (vérifié).
2. **Deux lots de géométries** complets et de haute qualité (50 + 40), conservés intacts sur `agent_1` et `agent-2`.
3. **Audit global** exhaustif : 23 anomalies (3 `BLK`, 7 `MAJ`, 8 `APP`, 5 `OPT`), avec métriques et localisation.
4. **Correction `BLK-001`** (Saray, exclave de Van) : présente dans l'artefact `fix/map-geometry-v2`.
5. **Correction `BLK-002`** (15 micro-chevauchements) : présente dans l'artefact `fix/map-geometry-v2`.
6. **Topologie unifiée** à 184 arêtes : présente dans l'artefact `fix/map-topology-v2` (à reconstruire après géométrie finale).
7. **Catalogue de 175 villes** unifié : présent dans l'artefact `fix/map-thematic-data-v2`.
8. **Méthode de comblement des lacunes `MAJ-004`** documentée et reproductible (`close_geometry_gaps.py` + rapport détaillé), même si les données sont perdues.

---

## 6. CE QUI RESTE À FAIRE

| Chantier | Nature | Statut |
|---|---|---|
| `MAJ-003` Strumica | Correction géométrique + arbitrage historique | **Ouvert** — nécessite une décision du directeur de conception |
| `MAJ-004` 4 lacunes | Re-exécution de `close_geometry_gaps.py` | **Ouvert** — données perdues, sources externes à re-télécharger |
| Fusion géométrie + lacunes | Assemblage canonique unique | **Ouvert** |
| Reconstruction de la topologie | `build_adjacency.py` depuis la géométrie finale | **Ouvert** |
| Fusion `adjacent_region_ids` + purge `external_*` | `MAJ-005`/`BLK-003` | **Ouvert** |
| `MAJ-002` rails inter-lots + écartements | Données thématiques | **Ouvert** |
| `MAJ-001` zones maritimes | Données thématiques | **Ouvert** |
| `MAJ-006` fleuves/massifs transfrontaliers | Données thématiques | **Ouvert** |
| Routes (MAP-DEC-08) | Donnée absente | **Ouvert** |
| **Ressources naturelles** | Donnée absente | **Ouvert — priorité haute** |
| `OPT-002` `etat_geometrie` + `ATLAS_BUILD_STATUS.md` | Métadonnées | **Ouvert** |
| `OPT-003`/`OPT-004`/`OPT-005` | Corrections mineures | **Ouvert** |
| Fusion de tout dans `main` | Intégration | **Ouvert** |

---

## 7. RESSOURCES NATURELLES — LE POINT LE PLUS GRAVE

Le travail sur les ressources naturelles est **effectivement absent du dépôt** :

- Le document annoncé `docs/map/corrections/NATURAL_RESOURCES_INVENTORY.md` **n'existe nulle part** (vérifié sur disque et dans tous les objets Git).
- La branche `audit/natural-resources-inventory` **ne contient pas** de ressources : elle est identique à `audit/map-thematic-data` (rapport d'audit thématique).
- Le document `docs/map/audit/INDEPENDENT_GEOMETRY_AUDIT.md`, cité par plusieurs consignes, **n'existe pas** non plus.
- Une mission de vérification référençant ces deux documents et devant produire `docs/map/corrections/RESOURCES_REGIONAL_VALIDATION.md` a été lancée (`brain/111cfd57…`) mais **n'a produit aucune réponse** (transcript de 2 298 octets = la seule requête). Le livrable n'existe pas.
- Ce qui existe réellement : **4 notes de recherche non versionnées** dans `/home/cassiop-e/research_notes/Ressources naturelles 1914/` (≈ 271 Ko, 9 catégories : charbon, fer, pétrole, gaz, bauxite, cuivre, autres minerais stratégiques, forêts, agriculture).
- **Problème de fiabilité** : ces notes utilisent une correspondance provisoire des IDs (ex. « 001 Scotland ») qui **contredit `region_plan.csv`** (où `region_001` = « Angleterre du Sud »). Elles ne sont pas exploitables telles quelles comme données de jeu.

Le schéma `data/schemas/map.schema.json` prévoit bien un tableau `resources` (objet `resourceRecord` avec `resource_code` requis, `quantity`/`production` optionnels, `source_refs`), mais **aucune fiche régionale ne le renseigne**.

---

## 8. BLOCAGES CLASSÉS

### Bloquants pour une intégration canonique
1. **Aucune branche n'est fusionnée** ; il n'existe pas de jeu de fichiers canoniques cohérent (géométrie + topologie + thématique).
2. **`MAJ-004`** : 4 lacunes (`1 097,49 km²`) non comblées dans un artefact persistant.
3. **`MAJ-003`** : Strumica mal attribuée — bloque aussi les rattachements thématiques qui en dépendent.
4. **Géométrie et topologie divergentes** : la topologie doit être reconstruite après toute correction géométrique.

### Importants
5. **Ressources naturelles absentes** (et notes de recherche non fiables).
6. **Routes absentes**, **rails inter-lots absents** (`MAJ-002`), **zones maritimes non unifiées** (`MAJ-001`).
7. **Clés de chantier `external_*`** (40 régions) et **`adjacent_region_ids` non fusionnés**.
8. **Métrique `region_088`** sans valeur unique fiable.

### Acceptables / facultatifs
9. `APP-001` à `APP-008` (approximations documentées et assumées).
10. `OPT-001` à `OPT-005` (toponymes, métadonnées, hétérogénéité de densité de sommets).

---

## 9. RISQUES DE PERTE ET DE DUPLICATION

| Risque | Preuve | Gravité |
|---|---|---|
| **Perte de données** : les géométries corrigées `MAJ-004` n'existaient que dans `/tmp/opencode/...`, supprimé | `GEOMETRY_GAPS_RESOLUTION.md` le confirme ; aucun artefact persistant | Élevée |
| **Branches fantômes** : `fix/map-geometry`, `fix/map-topology`, `fix/map-thematic-data` sont vides | Toutes à `b5a07ae` | Moyenne |
| **Branches mal nommées** : `audit/natural-resources-inventory`, `integrate/map-1914-final-audit` | Contenu ≠ nom | Moyenne |
| **Aucun remote** : aucune sauvegarde hors machine | `git remote -v` vide | Élevée |
| **Worktrees prunables** : 7 worktrees listés, dont 6 en `/tmp` ou marqués `prunable` | `git worktree list` | Moyenne |
| **Scripts de construction non versionnés** : `build_agent_1_atlas.py`, `build_agent_2_atlas.py` n'existent que dans le scratch Gemini | `git log --all --name-only` ne les trouve pas | Élevée |
| **Duplication** : trois « -v2 » et trois coquilles vides pour les mêmes chantiers | Cartographie des branches | Moyenne |
| **Traçabilité** : le rapport de topologie cite un commit de livraison (`879fc4e`) différent du HEAD de branche (`76333e1`) | Rapport vs `git log` | Faible |

---

## 10. OUTILS ET TESTS NON EXÉCUTABLES DANS CET ENVIRONNEMENT

| Outil / test | Raison | Conséquence |
|---|---|---|
| `tools/map/validate_atlas.py` | Dépend de `shapely` (absent) | Non rejoué ici |
| `tools/map/validate_geometry.py` | Dépend de `shapely` | Non rejoué |
| `tools/map/validate_topology.py` | Dépend de `shapely` | Non rejoué |
| `docs/map/audit/validate_global_atlas.py` | Dépend de `shapely` | Non rejoué |
| `tools/map/build_geometry.py` | Dépend de `shapely` + source geoBoundaries TUR ADM2 | Non rejouable sans source |
| `tools/map/close_geometry_gaps.py` | Dépend de `shapely` + `europe_1914.gpkg` (Kavanagh) | **Source absente du disque** |
| `tools/map/build_adjacency.py` | Dépend de `shapely` | Non rejouable |
| `tools/map/unify_thematic_data.py` | Dépend de `shapely` | Non rejouable |

**Bibliothèques GIS vérifiées absentes** : `shapely`, `geopandas`, `fiona`, `pyproj`, `pyogrio` (`ModuleNotFoundError` sur les cinq). `tools/map/requirements.txt` déclare pourtant `pyogrio>=0.11,<1` et `shapely>=2.0,<3`.

**Contrôles réellement exécutés** : inspection JSON (comptages, clés, cohérence d'identifiants), lecture des rapports, et commandes Git en lecture seule (`branch`, `log`, `show`, `ls-tree`, `worktree list`). Ces contrôles suffisent à établir l'état des artefacts, **pas** à valider la géométrie.

---

## 11. CONCLUSION

Le socle est bon : 90 régions construites, auditées et partiellement corrigées. Le problème n'est pas la qualité du travail produit, mais **la fragmentation de sa livraison** : des correctifs répartis sur des branches non fusionnées, une correction de lacunes perdue dans `/tmp`, une topologie construite sur des données périmées, et un chantier « ressources naturelles » annoncé mais inexistant.

La suite est décrite dans `docs/map/audit/CONTINUATION_PLAN.md`.
