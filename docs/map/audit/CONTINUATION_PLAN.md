# PLAN DE CONTINUATION — ATLAS GRAND STRATEGY-1914

> **HISTORIQUE (bandeau ajouté le 14/11/2026).** Rapport daté, exact à sa date (13/11/2026). Les opérations qu'il prévoit ont depuis été réalisées : géométrie consolidée, Strumica validée (`47bc6fe`), topologie reconstruite (`40a3117`). État courant : `docs/project/audit-2026-11/01_ETAT_GENERAL.md`. Texte conservé sans modification.

- **Date** : 13 novembre 2026
- **Objet** : feuille de route opérationnelle pour réunir les travaux fragmentés en un atlas canonique unique, sans recommencer le travail des agents.
- **Prérequis de lecture** : `docs/map/audit/PROJECT_STATUS.md` (état des lieux) et `docs/map/audit/INTEGRATION_CHECKLIST.md` (procédure d'origine).
- **Nature** : plan. Aucune donnée n'a été modifiée pour l'établir.

---

## 1. PRINCIPE DIRECTEUR

Le projet a produit beaucoup de bon travail **sur des lignes parallèles non fusionnées**. La continuation ne consiste donc **pas** à reconstruire, mais à **recoudre une chaîne linéaire** :

```
géométrie corrigée complète  ──►  topologie reconstruite  ──►  données thématiques unifiées  ──►  intégration main
        (M1, M2)                      (M3)                         (M4, M5, M6)                   (M7)
```

**Règle d'or** : la topologie se dérive **toujours** de la géométrie finale. Tant que la géométrie n'est pas figée, aucun graphe d'adjacence ne doit être considéré comme canonique.

**Règle de traçabilité** : chaque mission produit un artefact **versionné** (jamais uniquement dans `/tmp`) et un rapport. Toute donnée produite hors du dépôt est considérée comme perdue.

---

## 2. ÉTAT DE DÉPART ET DÉPENDANCES

| Mission | Entrées | Sortie | Dépend de |
|---|---|---|---|
| **M1** Assemblage géométrique canonique | `fix/map-geometry-v2` (`regions.geojson/json`), lots `agent_1`/`agent-2` | Géométrie 90 régions, `BLK-001`+`BLK-002` corrigées, sans `external_*` | — |
| **M2** Comblement `MAJ-004` + Strumica | Sortie M1, `close_geometry_gaps.py`, sources externes | Géométrie finale 90 régions, 0 lacune, 0 chevauchement | M1 ; arbitrage directeur pour Strumica |
| **M3** Reconstruction topologie | Sortie M2 | `adjacency.json` + `adjacent_region_ids` fusionnés | M2 |
| **M4** Données thématiques de base | Sortie M2, lots, `unify_thematic_data.py` | `terrain.json`, `infrastructure.json`, `maritime_zones.json` | M2 |
| **M5** Ressources naturelles | Sortie M2, notes de recherche, `map.schema.json` | `resources` renseigné ou décision de périmètre | M2 ; arbitrage directeur |
| **M6** Routes (MAP-DEC-08) | Sortie M2, sources historiques | Inventaire routier documenté | M2 ; arbitrage directeur |
| **M7** Intégration `main` | Sorties M2–M6 | `main` cohérente + `etat_geometrie=construite` | M2–M6 |

---

## 3. MISSIONS PRIORITAIRES (LES 3 À LANCER EN PREMIER)

### Mission 1 — Figer la géométrie canonique corrigée et complète

**Objectif** : produire **un seul** `regions.geojson` + `regions.json` contenant les 90 régions avec `BLK-001`, `BLK-002` **et** `MAJ-004` corrigées.

**Entrées** :
- `fix/map-geometry-v2` (corrections `BLK-001`/`BLK-002` déjà appliquées) ;
- `tools/map/close_geometry_gaps.py` + `docs/map/corrections/GEOMETRY_GAPS_RESOLUTION.md` (`fix/map-geometry-gaps`) ;
- sources externes à re-télécharger : Kavanagh `europe_1914.gpkg` (DOI `10.5281/zenodo.21341486`, CC BY 4.0) et RISTAT `ristat_1897_provinces.gpkg` (DOI `10.34894/NQOASN`, CC0).

**Étapes** :
1. Créer une branche dédiée `integrate/atlas-geometry` depuis `fix/map-geometry-v2`.
2. Re-télécharger et vérifier les sources externes (somme de contrôle + licence).
3. Re-exécuter `close_geometry_gaps.py` en écrivant dans un répertoire **versionné** du dépôt (jamais `/tmp`).
4. Fusionner les sorties dans `data/world/map/regions.geojson` et `regions.json`.
5. Recalculer `area_km2`, centroïdes, points représentatifs, bbox, `polygon_parts_count`, `vertex_count` pour les régions touchées.
6. Rejouer `validate_geometry.py` et `validate_atlas.py`.

**Critères d'acceptation** :
- 90/90 régions, 90/90 géométries OGC valides ;
- 0 paire avec chevauchement `> 1e-10 deg²` sur les 4 005 paires ;
- 0 lacune résiduelle sur les 4 sentinelles `MAJ-004` ;
- superficie totale ≈ `10 027 648,69 km²` (valeur de la résolution testée) ;
- **aucune valeur de `region_088` divergente** : une seule aire recalculée fait autorité (`7 933,51 km²`).

**Risques** : source Kavanagh indisponible ; conflit entre arrondi à 6 décimales et coutures natives (documenté dans le rapport `MAJ-004`). **Ne pas** réarrondir les nouvelles coutures.

---

### Mission 2 — Reconstruire la topologie sur la géométrie finale

**Objectif** : régénérer `adjacency.json` **à partir de la géométrie issue de M1** et propager `adjacent_region_ids` dans `regions.json`/`regions.geojson`.

**Entrées** : sortie M1 ; `tools/map/build_adjacency.py` + `validate_topology.py` (`fix/map-topology-v2`) ; `INTEGRATION_CHECKLIST.md` §3.

**Étapes** :
1. Rejouer `build_adjacency.py` sur les polygones corrigés (ne **pas** reprendre l'`adjacency.json` actuel : il est dérivé des lots non corrigés).
2. Vérifier le total d'arêtes **recalculé**, pas imposé : le rapport de topologie attend 184 (97 + 1 + 69 + 17) ; toute correction de couture peut le modifier.
3. Fusionner `neighbors_by_region` et `adjacent_region_ids` ; vérifier `region_044 = ["region_029"]` et que seules `region_051`, `region_085`, `region_086` sont isolées.
4. **Supprimer** les clés `external_adjacent_region_ids` (présentes sur 40 régions), `external_neighbors_by_region`, `external_perimeter_interfaces`, `total_external_perimeter_interfaces`.
5. Rejouer `validate_topology.py`.

**Critères d'acceptation** :
- 184+ arêtes, 100 % symétriques, aucune auto-boucle, aucun doublon ;
- 17/17 interfaces inter-lots, dont `region_026 <-> region_056` ;
- 3 régions isolées exactement ;
- `adjacent_region_ids` identiques entre `regions.json` et `regions.geojson`, et cohérents avec `neighbors_by_region` ;
- aucune clé `external_*` restante.

**Risques** : si M2 (Strumica) déplace une frontière, le nombre d'arêtes et les longueurs changent — d'où la dépendance stricte M1 → M2.

---

### Mission 3 — Unifier les données thématiques de base

**Objectif** : produire les fichiers thématiques canoniques absents et fusionner les catalogues.

**Entrées** : sortie M1 ; lots `agent_1`/`agent-2` ; `tools/map/unify_thematic_data.py` (`fix/map-thematic-data-v2`) ; `INTEGRATION_CHECKLIST.md` §4.

**Étapes** :
1. Conserver `cities.json` (175 villes, déjà unifié) ; corriger `OPT-001` (`Ekaterinoslav (Dniepropetrovsk)` → `Ekaterinoslav`).
2. Produire `terrain.json` unifié (5 catégories, profils des 90 régions).
3. Produire `infrastructure.json` : 129 axes + **10 axes ferroviaires inter-lots** (`MAJ-002`), en distinguant l'écartement russe 1524 mm du standard 1435 mm ; vérifier le tronçon grec « en travaux 1914–1916 » et le dater/scinder.
4. Produire `maritime_zones.json` unifié (`MAJ-001`) : intégrer les 16 zones du lot 2, unifier les identifiants.
5. Unifier les identifiants des **6 fleuves et 2 massifs transfrontaliers** (`MAJ-006`).
6. Rejouer le validateur thématique.

**Critères d'acceptation** : 90 profils de terrain ; catalogues sans doublon d'ID ni de nom ; chaque référence de site/ville/région résolue ; aucun segment ferroviaire non ouvert au 1er janvier 1914 présenté comme en service ; zones maritimes reliées à des régions existantes.

---

## 4. ORDONNANCEMENT : SÉQUENTIEL VS PARALLÉLISABLE

### Chaîne strictement séquentielle (à ne pas paralléliser)
```
M1 (géométrie corrigée)  →  M2 (MAJ-004 + Strumica)  →  M3 (topologie)  →  M7 (intégration)
```
Chaque maillon dépend du précédent : la topologie ne peut pas être figée avant la géométrie, et l'intégration pas avant les deux.

### Parallélisable (après M2)
- **M4** (thématique de base), **M5** (ressources), **M6** (routes) peuvent avancer **en parallèle** dès que la géométrie finale est figée, car elles ne se recouvrent pas fonctionnellement.
- À l'intérieur de M4, `terrain.json`, `infrastructure.json` et `maritime_zones.json` peuvent être traités par des agents distincts.

### Peut démarrer immédiatement, en parallèle de tout
- **Arbitrages historiques** auprès du directeur de conception : Strumica (M2), périmètre des ressources (M5), définition d'un « axe routier majeur » (M6).
- **Récupération des sources externes** (Kavanagh, RISTAT, geoBoundaries) : prérequis de M1/M2, indépendant.
- **Sécurisation** : ajouter un remote Git et committer les scripts de construction (`build_agent_1_atlas.py`, `build_agent_2_atlas.py`) actuellement uniquement dans le scratch Gemini.

---

## 5. AUDITS INDÉPENDANTS REQUIS

Principe : **aucune mission ne s'auto-valide**. Un artefact n'est réputé conforme que si un agent distinct le vérifie sur les données, pas sur le rapport.

| Audit | Portée | Indépendant de |
|---|---|---|
| **Audit géométrique indépendant** | Recalculer validité OGC, chevauchements, lacunes, aires, bbox, sur la géométrie M2 | M1, M2 |
| **Audit topologique indépendant** | Recalculer arêtes, symétrie, interfaces, détroits depuis la géométrie M2 | M3 |
| **Audit thématique indépendant** | Vérifier rattachements villes/terrain/infra aux régions corrigées | M4 |
| **Audit de fiabilité des ressources** | Vérifier les attributions régionales, les sources, la distinction avant/après 1914 | M5 |
| **Audit de conformité au schéma** | Valider `regions.json`, `cities.json`, etc. contre `data/schemas/map.schema.json` | M2–M6 |

**Point de vigilance** : le document `docs/map/audit/INDEPENDENT_GEOMETRY_AUDIT.md`, référencé par des consignes passées, **n'existe pas**. Il doit être produit par l'audit géométrique indépendant, ou la référence doit être supprimée des consignes.

---

## 6. PORTES D'INTÉGRATION VERS `main`

Aucune fusion dans `main` avant franchissement de **toutes** ces portes :

- [ ] **P1 — Géométrie** : 90 régions, 0 chevauchement `> 1e-10 deg²`, 0 lacune, métriques recalculées, Strumica arbitrée et appliquée.
- [ ] **P2 — Topologie** : arêtes recalculées depuis la géométrie finale, 100 % symétriques, `adjacent_region_ids` fusionnés, `external_*` purgés.
- [ ] **P3 — Thématique** : `cities.json`, `terrain.json`, `infrastructure.json`, `maritime_zones.json` présents et cohérents ; rails inter-lots ajoutés et datés.
- [ ] **P4 — Ressources** : décision de périmètre prise **et** soit `resources` renseigné conformément au schéma, soit absence explicitement assumée et documentée.
- [ ] **P5 — Schéma** : tous les fichiers canoniques valides contre `map.schema.json`.
- [ ] **P6 — Métadonnées** : `region_plan.csv` avec `etat_geometrie = construite` sur les 90 lignes (`OPT-002`) ; `ATLAS_BUILD_STATUS.md` mis à jour.
- [ ] **P7 — Audits** : les 5 audits indépendants (§5) passés et archivés.
- [ ] **P8 — Sauvegarde** : remote Git configuré, tout commité et poussé.

**Recommandation forte** : configurer un remote **avant** de commencer M1. Le dépôt n'en a aucun et plusieurs livraisons ont déjà été perdues.

---

## 7. ORGANISATION D'AGENTS RECOMMANDÉE

Pour éviter la fragmentation qui a causé l'état actuel, adopter une organisation **séquentielle avec barrières**, et non des lots parallèles indépendants.

| Rôle | Mission | Peut démarrer | Ne doit jamais |
|---|---|---|---|
| **Agent Géométrie** | M1 + M2 (géométrie corrigée complète) | Immédiatement | Toucher `adjacency.json` ou les fichiers thématiques |
| **Agent Topologie** | M3 (reconstruction) | Après P1 | Toucher les géométries |
| **Agent Thématique** | M4 (terrain, infra, maritimes) | Après P1 | Toucher les géométries ou la topologie |
| **Agent Ressources** | M5 | Après P1 | Inventer des gisements ou des volumes |
| **Agent Routes** | M6 | Après P1 | Fabriquer des routes pour relier des villes |
| **Agent Audit** (×2, distincts) | Audits §5 | Après chaque livraison | Produire ou corriger les données qu'il audite |
| **Directeur de conception** | Arbitrages : Strumica, périmètre ressources, définition « axe routier majeur » | Immédiatement | — |

**Règles d'organisation** :
1. **Un artefact = un propriétaire.** Personne d'autre ne modifie un fichier canonique qu'il ne produit pas.
2. **Barrières explicites** : M3, M4, M5, M6 ne démarrent qu'après validation (P1) de la géométrie.
3. **Tout livrable est versionné.** Interdiction de travailler dans `/tmp` sans copie versionnée.
4. **Aucune auto-validation.** Chaque livraison passe par un agent d'audit distinct.
5. **Aucune branche fantôme.** Ne pas créer de branches de correction avant d'avoir le contenu ; les trois coquilles vides existantes (`fix/map-geometry`, `fix/map-topology`, `fix/map-thematic-data`) doivent être documentées ou supprimées.
6. **Une seule branche d'intégration** (`integrate/atlas-1914`) qui agrège au fur et à mesure, plutôt que des branches parallèles.

---

## 8. PRÉREQUIS D'ENVIRONNEMENT

Avant de lancer M1, l'environnement d'exécution doit disposer de :

- `shapely>=2.0,<3` et `pyogrio>=0.11,<1` (déclarés dans `tools/map/requirements.txt`, actuellement **absents**) ;
- accès réseau aux sources externes (Kavanagh, RISTAT, geoBoundaries, REGIS) ;
- un remote Git pour la sauvegarde.

Sans `shapely`, aucun validateur du dépôt n'est exécutable, et **aucune des missions M1–M3 ne peut être validée**. C'est le prérequis le plus urgent.

---

## 9. RÉCAPITULATIF DES 3 MISSIONS PRIORITAIRES

1. **M1 — Figer la géométrie canonique corrigée et complète** (fusion `fix/map-geometry-v2` + `MAJ-004`, sources re-téléchargées, artefact versionné).
2. **M2 — Arbitrer et appliquer Strumica** (décision du directeur + correction de `region_074`/`region_072`).
3. **M3 — Reconstruire la topologie** depuis la géométrie finale (184+ arêtes, `adjacent_region_ids` fusionnés, `external_*` purgés).

Ces trois missions débloquent tout le reste. Les données thématiques (M4), les ressources (M5) et les routes (M6) peuvent ensuite avancer en parallèle, avant l'intégration finale (M7).
