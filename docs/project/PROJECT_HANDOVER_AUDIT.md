# AUDIT DE REPRISE — GRAND STRATEGY-1914

- **Date :** 14 novembre 2026
- **Objet :** mission 23 du dossier de reprise. Audit intégral du dépôt, état réel du projet et plan de reprise.
- **Branche :** `docs/project-handover-audit`, créée depuis `40a3117` (`consolidate/map-1914-topology`).
- **Statut du document :** RAPPORT D'AUDIT ET PROPOSITIONS. Ce document **ne vaut décision sur aucun point de conception**. Les recommandations y sont marquées comme telles.
- **Périmètre respecté :**
  - aucune modification de fichier cartographique ;
  - aucune fusion ;
  - aucune suppression de branche ;
  - aucun push forcé ;
  - aucun code de gameplay.

---

## 1. Synthèse

1. **La cartographie validée est intacte et reproductible.**
   - Le commit `40a3117` est présent localement et sur GitHub.
   - Les 5 empreintes SHA-256 de référence correspondent exactement.
   - Les 4 validateurs passent : 93 contrôles et 95 contrôles avec rejeu, 0 échec.
2. **Le dépôt contient deux historiques Git sans ancêtre commun.**
   - `origin/main` (`1ec985f`) appartient à la lignée du 31 octobre.
   - Toute la cartographie validée appartient à la lignée du 1er novembre.
   - Un fast-forward de `main` vers `40a3117` est donc **impossible**.
3. **La conception est répartie sur ces deux lignées.**
   - Le dossier d'arbitrage T-029, le document fondateur (D-001 à D-026) et les ADR 0001 à 0006 n'existent que dans la lignée du 31 octobre.
   - Les 69 décisions cartographiques, `PROJECT.md` v1.1 (gel du gameplay) et l'architecture Godot n'existent que dans la lignée du 1er novembre.
   - Aucune branche ne réunit aujourd'hui l'ensemble de la conception.
4. **Il existe un prototype Python jouable, non mentionné dans le dossier de reprise.**
   - Il se trouve sur `archive/oct31-mvp-playable` (`cdd3ab1`) : environ 11 000 lignes, un moteur, une IA, l'économie, la diplomatie, une interface web et des tests.
   - L'ADR-0006 (pile Python) y est « accepté par délégation ». Cela contredit la proposition Godot 4.7.2 de la lignée validée.
   - Ce prototype est antérieur au gel du gameplay. Il **n'est pas** une implémentation validée.
5. **Dans la lignée validée, aucun système de jeu n'est implémenté.**
   - `src/` et `tests/` ne contiennent que des `.gitkeep`.
   - `project.godot` est une coquille sans scène.
   - Godot n'est pas installé sur le poste.
6. **Les données thématiques ne sont pas sur la lignée validée.** Les 175 villes et l'audit thématique reposent sur une géométrie antérieure à la consolidation.
7. **Décisions qui reviennent au directeur :**
   - l'alignement de `main` ;
   - l'arbitrage T-029 ;
   - le statut du prototype Python face à Godot ;
   - la visibilité du dépôt, qui est toujours **privé**.

---

## 2. Méthode et preuves

### 2.1 Emplacements

| Rôle | Chemin | État |
|---|---|---|
| Dépôt de travail principal (lignée nov.) | `~/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914` | Branche active `consolidate/map-1914-geometry` (`47bc6fe`), propre. Contient tous les objets de `origin`. |
| Worktree cartographique validé | `…/worktrees/consolidate-map-1914-topology` | `40a3117`, propre |
| Ancien dépôt (lignée oct.) | `~/Projets/GrandStrategy` (+ worktree `GrandStrategy-opencode`) | `main` = `2a341d1`, pas de fetch depuis le 1er nov. : **obsolète**, ne plus y travailler |
| Sauvegarde | `~/backups/gs1914-2026-11-13/` | 2 bundles, archive de l'arbre, sources GIS (373 Mo), notes de recherche, prototypes de scripts |
| Dépôt distant | `github.com/elielbarbucovantes-source/grand-strategy-1914` | **PRIVATE**, branche par défaut `main`, 30 branches |

### 2.2 Empreintes de référence (vérifiées le 14/11/2026)

Les empreintes ont été calculées sur l'arbre de travail et sur les blobs de `40a3117`. Elles sont identiques dans les deux cas.

| Fichier | SHA-256 | Conforme |
|---|---|---|
| `data/world/map/adjacency.json` | `4013f26e…a28bb8` | ✅ |
| `tools/map/rebuild_topology.py` | `15f7b9f9…f604a3` | ✅ |
| `tools/map/validate_topology.py` | `2ebb5123…f994` | ✅ |
| `data/world/map/regions.geojson` | `183e5e80…7ee3623` | ✅ |
| `data/world/map/regions.json` | `4b26f0bd…e771` | ✅ |

### 2.3 Validateurs

Les validateurs ont été exécutés avec le venv `/tmp/opencode/gs1914-gis-venv` (Python 3.12.3, shapely 2.2.0, pyproj 3.8.0, pyogrio 0.13.0) :

| Commande | Résultat |
|---|---|
| `validate_geometry.py` | 90/90 valides ; 0 doublon ; 0 chevauchement ; Saray dans 088 = vrai, Van = faux ; Strumica dans 072 = vrai, 074 = faux ; lacunes 0/4 ; total 10 027 649,63 km² |
| `validate_atlas.py` | Index de 90 lignes, 90/90 géométries. Avertissement : l'absence d'emprise de référence empêche de conclure à la couverture complète. Limite éditoriale connue. |
| `validate_topology.py` | **VALIDÉ — 93 contrôles, 0 échec** |
| `validate_topology.py --rebuild-check` | **VALIDÉ — 95 contrôles, 0 échec** (rejeu identique octet pour octet) |

`git status` est resté vide après exécution.

---

## 3. État Git

### 3.1 Les deux lignées

```
Lignée A (31 oct., racine 459375a)          Lignée B (1er nov., racine 5d8579f)
  1ec985f  origin/main                        4ffdb8a foundation/main-2026-11-01 (= main local Codex)
   ├─ 2a341d1 archive/oct31-main-t029          ├─ 286975a agent_1     ├─ baa0c90 agent-2
   ├─ cdd3ab1 archive/oct31-mvp-playable       └─ … b5a07ae audit/map-1914
   ├─ e20bf90 docs/fiche-maitresse-v0.2            ├─ 4dbf4f8 fix/map-thematic-data-v2
   └─ ca0d4e2 docs/fiche-maitresse-opencode        ├─ 8a5d2bf audit/map-thematic-data
                                                   └─ fc26c18 → 219373b → a7983e7
                                                        ├─ 2d7bb5c docs/github-central-infrastructure
                                                        └─ 03bce80 → 47bc6fe → 6d30a51 → 40a3117
```

`git merge-base` ne trouve aucun ancêtre commun entre `1ec985f` et `40a3117`, ni entre `1ec985f` et `4ffdb8a`.

### 3.2 Classement des 30 branches distantes

| Branche | Commit | Lignée | Classement proposé |
|---|---|---|---|
| `consolidate/map-1914-topology` | `40a3117` | B | **RÉFÉRENCE**. Point d'intégration de la nouvelle `main`. |
| `consolidate/map-1914-geometry` | `47bc6fe` | B | Ancêtre de la référence. Conserver comme jalon. |
| `audit/map-strumica-final` | `47bc6fe` | B | Identique à la précédente. Conserver comme trace d'audit. |
| `fix/map-strumica-final` | `03bce80` | B | Ancêtre de la référence. Jalon. |
| `docs/github-central-infrastructure` | `2d7bb5c` | B (depuis `a7983e7`) | **À INTÉGRER** : rejouer son commit sur la référence (tâche T3). |
| `test/github-infrastructure-check` | `2d7bb5c` | B | Alias de la précédente. Archiver. |
| `fix/map-thematic-data-v2` | `4dbf4f8` | B (depuis `b5a07ae`) | **À INTÉGRER après revalidation** (tâche T9). |
| `audit/map-thematic-data` | `8a5d2bf` | B (depuis `b5a07ae`) | À intégrer, en tant que documentation (tâche T9). |
| `audit/natural-resources-inventory` | `8a5d2bf` | B | Alias. Archiver. |
| `fix/map-topology-v2` | `76333e1` | B | **Remplacée** par la reconstruction `6d30a51`. Archiver, sans fusionner. |
| `fix/map-geometry-v2`, `fix/map-geometry-gaps`, `integrate/map-1914-final-audit` | `fc26c18`, `219373b`, `219373b` | B | Étapes intermédiaires, déjà incluses. Archiver. |
| `audit/map-1914` | `b5a07ae` | B | Audit initial, déjà inclus dans l'ancêtre. Archiver. |
| `fix/map-geometry`, `fix/map-topology`, `fix/map-thematic-data` | `b5a07ae` | B | Coquilles vides. Archiver. |
| `agent_1`, `agent-2` | `286975a`, `baa0c90` | B | Lots sources, déjà intégrés. Archiver. |
| `foundation/main-2026-11-01` | `4ffdb8a` | B | Socle documentaire, ancêtre de la référence. Conserver. |
| `main` | `1ec985f` | A | **À ALIGNER** : décision du directeur requise (tâche T1). |
| `archive/oct31-origin-main`, `docs/conception-suite`, `feat/mvp-playable` | `1ec985f` | A | Alias de `main`. Archiver. |
| `archive/oct31-main-t029` | `2a341d1` | A | Contient **T-029**. Reprendre ses documents dans la lignée B (tâche T2). |
| `archive/oct31-mvp-playable` | `cdd3ab1` | A | **Prototype Python et ADR-0006.** Statut à arbitrer (tâche T12). |
| `docs/fiche-maitresse-v0.2`, `docs/fiche-maitresse-opencode` | `e20bf90`, `ca0d4e2` | A | Versions de la fiche maîtresse. Archiver après la tâche T2. |

« Archiver » signifie renommer en `archive/*` ou laisser en place. Cela ne signifie **jamais** supprimer, et ne se fait qu'après vérification du contenu.

### 3.3 Écarts avec le dossier de reprise

| Dossier | Constat |
|---|---|
| 26 branches distantes | **30** |
| `consolidate/map-1914-geometry` = `a7983e7` | La branche a avancé à **`47bc6fe`** (Strumica et audit) |
| `AGENTS.md`/`CONTRIBUTING.md` « sur une branche dédiée » | Ils n'existent que sur `2d7bb5c`, basé sur `a7983e7` et donc **sans** Strumica ni topologie. Le `AGENTS.md` de `40a3117` est l'ancienne version. |
| Prototypes à rechercher | Un prototype **jouable** de grande taille existe dans la lignée A (`cdd3ab1`) |
| Dépôt « envisagé public » | `gh repo view` : **PRIVATE** |
| Manifeste de sauvegarde | Il indique « aucun remote configuré ». Ce n'est plus exact depuis la centralisation. |

### 3.4 Worktrees

- Six worktrees enregistrés pointent vers `/tmp/mammouth/*` et `/tmp/opencode/*`. Ils sont marqués *prunable*, car leurs répertoires ont disparu.
- Un autre se trouve dans `~/.gemini/antigravity-cli/…/wt_fix_geometry`.
- Tous référencent des commits présents sur `origin`.
- Un `git worktree prune` serait sans risque de perte de données (tâche T13).

---

## 4. Architecture existante (réelle)

Lignée B, état de `40a3117` : 109 fichiers suivis.

| Zone | Contenu réel |
|---|---|
| `PROJECT.md` v1.1, `PROGRESS.md`, `CHANGELOG.md`, `AGENTS.md`, `STRUCTURE.md`, `prompts/OPENCODE_PROMPT.md` | Corpus de conception et de gouvernance |
| `docs/{ai,diplomacy,economy,gameplay,intelligence,military,nations,technology}/OVERVIEW.md` | Cadrages par domaine. Aucune spécification calculable. |
| `docs/architecture/TECHNICAL_ARCHITECTURE.md`, `PRINCIPLES.md` | Architecture **proposée** : Godot 4.7.2 et GDScript typé, simulation pure, contrats `NationAgent` et `SaveRepository` |
| `docs/decisions/DECISIONS_PENDING.md` | Registre : MAP-DEC-01 à 69 VALIDÉES ; MAP-OPEN-01 à 19 ; NAT, TURN, ECO, MIL, DIP… |
| `docs/map/TECHNICAL_SPEC.md`, `ATLAS_BUILD_STATUS.md`, `audit/*` (11 fichiers), `corrections/*` (5 fichiers) | Spécification de la carte et rapports d'audit, dont `FINAL_GEOMETRY_AND_TOPOLOGY_AUDIT.md` |
| `data/world/map/` | `regions.geojson` (17,4 Mo), `regions.json`, `adjacency.json`, `tables/region_plan.csv`, lots `build/agent_1` et `build/agent_2`, extraits de sources dérivés (4 fichiers) |
| `data/schemas/map.schema.json` | Seul schéma présent |
| `tools/map/` | 11 scripts : construction, consolidation, comblement des lacunes, Strumica, topologie et 3 validateurs, avec `requirements.txt` et `requirements.lock` |
| `src/**`, `tests/**`, `data/rules`, `data/scenarios`, `assets/**` | **Uniquement des `.gitkeep`** |
| `project.godot` | Coquille, `config_version=5`. Aucune scène principale. |

**Lignée A :**
- Corpus documentaire : document fondateur v0.1, revue de conception v0.1, ADR 0001 à 0005, T-029, documents par domaine plus détaillés (IA : mémoire et personnalités ; diplomatie : traités et réputation ; militaire : batailles tactiques).
- Sur `cdd3ab1` s'ajoutent :
  - `game/*.py` : moteur, modèle, IA, économie, diplomatie, armée, recherche, événements, scénario, stockage et serveur HTTP ;
  - `game/web/` : interface SVG/JS ;
  - `game/data/*.json` : carte, nations et technologies propres au prototype, **sans lien avec les 90 régions validées** ;
  - `tests/test_engine.py` ;
  - `tools/generate_map.py`.

**Environnement du poste :**
- Python 3.12.3 et `gh` 2.86 sont installés.
- **Godot n'est pas installé.**
- Les seules dépendances GIS se trouvent dans un venv sous `/tmp`, donc volatil.

---

## 5. Matrice de classification

Légende :
- **VAL** : validée ;
- **IMP** : implémentée ;
- **TST** : testée ;
- **DOC** : documentée ;
- **PROP** : proposée ;
- **OUV** : ouverte ;
- **ABS** : absente ;
- **BLQ** : bloquée.

« Proto-A » désigne une implémentation **non validée** dans le prototype `cdd3ab1`.

| Système | Statut(s) | Source / remarque |
|---|---|---|
| Identité, devise, trois piliers | VAL, DOC | `PROJECT.md` §1–2, D-001 et suivantes (lignée A) |
| 7 puissances jouables, autres États IA | VAL (principe), DOC | `PROJECT.md` §4 |
| 12 statistiques nationales | VAL (liste), OUV (formules) | NAT-01 |
| Atlas de 90 régions (géométrie) | VAL, IMP, TST | `regions.geojson`, `validate_geometry.py` |
| Topologie terrestre (184 arêtes), 10 + 3 détroits | IMP, TST | `adjacency.json`, `validate_topology.py` |
| Zones maritimes (16) et liaisons | IMP (partiel), TST, BLQ (catalogue incomplet) | 53 liens déclarés contre 66 géométriques ; 26 façades orphelines |
| 69 décisions cartographiques | VAL, DOC | `TECHNICAL_SPEC.md`, `DECISIONS_PENDING.md` §A |
| Villes stratégiques (175) | IMP (hors lignée validée), OUV (MAP-OPEN-05) | `4dbf4f8:data/world/map/cities.json` |
| Relief, fleuves, infrastructures, fortifications | VAL (principes), ABS (données) | MAP-OPEN-04, 06 et 07 |
| Ressources naturelles | VAL (principe à 3 niveaux), ABS (données canoniques) | Notes hors Git dans `backups/…/research_notes/` |
| Démographie, économie et données militaires historiques | ABS | NAT-02, NAT-03 |
| Tour mensuel, ordres simultanés secrets | VAL (principe), OUV (TURN-01 à 05), Proto-A | |
| Articulation stratégique / tactique (T-029) | OUV, PROP (package A / E+F / I / journal / contrat de session) | `2a341d1:docs/decisions/arbitrage-t029-…`, ADR-0005 « proposé » |
| Économie, budget, marché, commerce | VAL (principes), OUV (ECO-01 à 07), Proto-A | |
| Industrie (5 catégories) | VAL (catégories), OUV (formules) | `PROJECT.md` §11 : terrestre, aéronautique, navale, civile, munitions |
| Logistique et ravitaillement | VAL (principe), OUV (MIL-03, MIL-04), ABS | |
| Mobilisation, ordre de bataille | OUV (MIL-01, MIL-02), Proto-A | |
| Batailles tactiques | VAL (principes : 30 min, pertes définitives), OUV (MIL-06), ABS | |
| Diplomatie, traités, mémoire | VAL (principes), OUV (DIP-*), Proto-A | |
| IA autonome | VAL (vision), PROP (architecture `NationAgent`), Proto-A | |
| Renseignement et espionnage | VAL (périmètre), OUV, ABS | |
| Recherche (1914 à 1945) | VAL (principe), OUV, Proto-A | |
| Victoire territoriale à 90 % | VAL (seuil), OUV (calcul : MAP-OPEN-16) | |
| Victoire socio-économique et collective | VAL (principe), OUV | |
| Sauvegarde et replay | PROP, OUV (D4 de T-029), Proto-A (JSON) | |
| Interface et carte jouable | VAL (principes, MAP-DEC 27 à 69), ABS (lignée B), Proto-A (SVG web) | |
| Multijoueur | VAL (orientation : après le solo), ABS | |
| Moteur | PROP (Godot 4.7.2, lignée B) **contre** ADR-0006 accepté par délégation (Python, lignée A) : **OUV** | Conflit à arbitrer (T12) |
| Code de gameplay | **Interdit** sans autorisation explicite | `PROJECT.md` §18 |

---

## 6. Travaux terminés et incomplets

**Terminés et vérifiés :**
- Géométrie des 90 régions, avec BLK-001 (Saray), BLK-002 (chevauchements), MAJ-004 (lacunes) et MAJ-003 (Strumica, audit indépendant validé).
- Topologie déterministe reconstruite ; validateurs reproductibles.
- Registre des 69 décisions cartographiques.
- Architecture technique proposée et documentée.
- Centralisation GitHub sans perte (30 branches) et sauvegardes par bundle.

**Incomplets :**
- Catalogue maritime, `mz_norwegian_sea`, canal de Corfou et proximités, région 051 isolée, `regions.json` hérité.
- Villes et audit thématique à réintégrer.
- Réconciliation documentaire entre les lignées A et B.
- Alignement de `main` ; `AGENTS.md` et `CONTRIBUTING.md` à jour sur la lignée validée.
- Aucune intégration continue.
- Environnement GIS non durable.
- Ensemble des données historiques nationales et régionales.
- Toutes les spécifications calculables (NAT, TURN, ECO, MIL, DIP…).

---

## 7. Anomalies

### 7.1 Cartographie

Ces anomalies sont reprises du rapport final, §9, et sont toujours d'actualité.

| # | Anomalie | Gravité | Tâche |
|---|---|---|---|
| C1 | `mz_norwegian_sea` présente une auto-intersection (`buffer(0)` utilisé pour la mesure uniquement) | Mineure | T7 |
| C2 | Catalogue maritime : 53 liens déclarés contre 66 géométriques ; 14 liens géométriques non catalogués ; 26 façades orphelines | Majeure pour la navigation | T5 |
| C3 | Paire 026/056 : 365,47 km mesurés contre 369,18 km curatés (la mesure géométrique fait autorité) | Information | — |
| C4 | `regions.json` hérité : 166 couples sur 184 | Mineure (`adjacency.json` fait référence) | T8 |
| C5 | 8 proximités de moins de 20 km non converties en adjacences | Information, à arbitrer | T6 |
| C6 | Région 051 (Islande) isolée ; lien `catalogue_only`, à 170,22 km de la zone | Majeure pour le jeu | T6, T7 |
| C7 | Canal de Corfou 076/077 non arbitré | Mineure | T6 |
| C8 | Pas d'emprise de référence ; source Kavanagh `europe_1914.gpkg` introuvable (substitut basse résolution) | Limite éditoriale | — |

### 7.2 Dépôt et projet

| # | Anomalie | Gravité |
|---|---|---|
| G1 | Deux historiques sans ancêtre commun ; `origin/main` sur la lignée A | **Bloquante pour l'intégration** |
| G2 | Conception répartie entre les lignées (T-029, D-001 à 026 et ADR uniquement en A) | Majeure |
| G3 | ADR-0006 « accepté » (Python) contre la proposition Godot (B) | Majeure, à arbitrer |
| G4 | `AGENTS.md` et `CONTRIBUTING.md` à jour seulement sur `2d7bb5c`, en dehors de la référence | Moyenne |
| G5 | Données thématiques (villes) construites sur une géométrie antérieure à la consolidation | Moyenne |
| G6 | Venv GIS sous `/tmp` ; Godot absent ; aucune intégration continue | Moyenne |
| G7 | Six worktrees *prunables* ; ancien dépôt `~/Projets/GrandStrategy` non synchronisé | Faible |
| G8 | Manifeste de sauvegarde obsolète (remote) ; sauvegarde sur le même disque | Faible à moyenne |

---

## 8. Risques

| Risque | Effet | Atténuation |
|---|---|---|
| Fusion naïve des lignées A et B | Conflits massifs, régression de la carte | Commit de jonction contrôlé (T1). Contrôle des empreintes avant et après. |
| Un agent travaille dans `~/Projets/GrandStrategy` | Travail sur une base obsolète | Le signaler dans `AGENTS.md` (T3). Archiver ce dossier local. |
| Perte du venv `/tmp` au redémarrage | Validateurs inexécutables | T4 : venv durable et CI |
| Prototype Python pris pour le jeu | Confusion de statut, dette technique | T12 : statut explicite (référence d'étude, jetable ou base) |
| Données historiques inventées pour combler les tableaux | Perte de crédibilité (pilier C) | T10 : schéma de provenance obligatoire, valeurs `null` plutôt qu'inventées |
| Modification accidentelle des fichiers de carte | Invalidation de l'audit | Empreintes vérifiées en CI (T4). Branches dédiées. |
| Plusieurs agents sur le même répertoire de travail | Écrasements | Un worktree par branche, règle inscrite dans `AGENTS.md` |
| Disque unique | Perte totale | GitHub sert de copie distante. Recommandé : bundle périodique sur un support externe. |

---

## 9. Décisions ouvertes

**Décisions qui reviennent au directeur :**

1. **Alignement de `main`** (T1). La décision est déjà soumise dans `GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md` §3.
2. **T-029, questions D1 à D5.** Le package recommandé (D1 = A, D2 = E+F, D3 = I, D4 = journal et pas fixes, D5 = moteur isolé et contrat de session) reste **non approuvé**.
3. **Moteur et prototype** : confirmer Godot et le statut de `cdd3ab1` ou de l'ADR-0006 (T12).
4. **Visibilité du dépôt** : public ou privé.
5. **Arbitrages cartographiques ayant un effet sur le jeu :**
   - traversées de l'Islande (051) ;
   - canal de Corfou ;
   - proximités ;
   - éventuelles liaisons maritimes nouvelles ayant un effet de jeu.
6. **Spécifications de conception :**
   - MAP-OPEN-02 à 19 ;
   - NAT-01 à 05 ;
   - TURN-01 à 05 ;
   - ECO-01 à 07 ;
   - MIL-01 à 09 ;
   - DIP-* ;
   - IA, recherche, renseignement, victoire, élimination.

**Décisions techniques ordinaires** (prises par le responsable technique, sans arbitrage) :
- outillage ;
- CI ;
- environnements ;
- format des schémas ;
- organisation des branches ;
- curation purement factuelle des catalogues.

---

## 10. Propositions techniques

Ces éléments sont des **propositions**.

1. **Branche d'intégration unique**, `integration/main-2026-11`.
   - Elle part de `40a3117`.
   - Elle reçoit par commits distincts : l'infrastructure documentaire (T3), les documents de la lignée A (T2), puis l'outillage (T4).
   - `main` la rejoint ensuite par un commit de jonction (T1).
2. **Commit de jonction recommandé pour `main`** (option 1 de l'audit de centralisation).
   - Un commit de fusion `--no-ff` avec la stratégie `-s ours` inversée : arbre = celui de la lignée B intégrée ; parents = `1ec985f` et la pointe d'intégration.
   - Avantages : pas de push forcé, l'historique A reste accessible dans `main`, et la mise à jour de `origin/main` se fait par fast-forward.
   - Les documents utiles de la lignée A sont repris explicitement (T2), et non par la fusion.
3. **Outillage :**
   - `tools/map/validate_all.sh` : un point d'entrée unique pour les 4 validateurs et la vérification des empreintes ;
   - venv dans `~/.venvs/gs1914-gis` installé depuis `requirements.lock` ;
   - workflow GitHub Actions `map-validation.yml`, déclenché sur les PR touchant `data/world/map/**` ou `tools/map/**`.
4. **Données historiques.**
   - Un schéma `data/schemas/provenance.schema.json` : valeur, unité, date de référence, source, niveau de confiance, méthode.
   - Une donnée sans source porte `confidence: "unknown"` ; elle n'est jamais inventée.
5. **Architecture du jeu.**
   - On conserve la proposition existante (`TECHNICAL_ARCHITECTURE.md`) : simulation pure découplée de Godot, ordres sérialisables, `NationAgent` à vue filtrée, `SaveRepository`.
   - Aucun code avant le feu vert.
   - Un prototype technique neutre (chargement de `regions.geojson` dans Godot, sans règle de jeu) est envisageable sur autorisation explicite, une fois Godot installé.
6. **Prototype Python.** Recommandation : le conserver comme **référence d'étude archivée**. On peut y relire l'IA, les ordres et les sauvegardes, mais il ne sert pas de base de code. Son ADR-0006 serait marqué « remplacé » si le directeur confirme Godot.

---

## 11. Ordre de priorité

1. **Phase 1, stabilisation du dépôt :** T13, T4, T3, T2, puis T1 (sur décision).
2. **Phase 2, finalisation de la carte :** T5, T7, T6 (arbitrages), T8.
3. **Phase 3, données :** T9, T10, puis les données démographiques, économiques et militaires région par région.
4. **Phase 4, conception :** T11 (T-029), puis les spécifications NAT, TURN, ECO, MIL, DIP et IA. T12 (moteur) peut se décider en parallèle.
5. **Phase 5, architecture :** contrats de données et d'ordres, schémas, plan de tests, prototype technique neutre (sur autorisation).
6. **Phase 6, développement :** après autorisation explicite du directeur uniquement.

---

## 12. Plan détaillé par phase

| Phase | Livrables | Critère de sortie |
|---|---|---|
| 1 | `main` aligné ; `AGENTS.md` et `CONTRIBUTING.md` à jour ; documents A repris ; CI de la carte ; worktrees nettoyés | `main` contient la carte validée, toute la conception et une CI verte |
| 2 | Catalogue maritime complet ; `mz_norwegian_sea` valide ; arbitrages 051, Corfou et proximités consignés ; `regions.json` aligné ou déclaré obsolète | 0 façade orpheline non justifiée ; validateurs à jour, nouvelles empreintes documentées |
| 3 | `cities.json` revalidé ; schéma de provenance ; population 1914 des 90 régions (sourcée) | Chaque valeur porte une source ou une incertitude |
| 4 | T-029 tranché ; spécifications calculables par système | Registre sans « À DÉFINIR » bloquant pour le premier système à développer |
| 5 | Modèle de données du monde, contrat d'ordres, format de sauvegarde, stratégie de tests, choix du moteur confirmé | ADR acceptées |
| 6 | Systèmes livrés un par un, avec tests | Sur autorisation |

---

## 13. Fiches de tâches

### T1 — Aligner `main` sans perte d'historique
- **Objectif :** que `main` contienne la lignée validée tout en conservant l'historique A.
- **Fichiers :** aucun fichier de contenu. Seules les références `main` et `integration/main-2026-11` changent.
- **Dépendances :** T2 et T3 terminées ; **décision du directeur**.
- **Risques :** confusion d'historique ; écrasement accidentel de la carte.
- **Méthode :**
  1. `git checkout -b integration/main-2026-11 40a3117`, puis appliquer T2, T3 et T4.
  2. Créer un commit de jonction de parents `1ec985f` et `integration`, avec l'arbre `integration` (`git merge -s ours` depuis la branche d'intégration vers une copie de `main`, ou `git commit-tree`).
  3. PR vers `main`, puis fast-forward.
- **Tests :** empreintes des 5 fichiers ; `validate_all.sh` ; `git merge-base --is-ancestor 1ec985f main` et `40a3117 main`.
- **Résultat attendu :** `origin/main` mis à jour sans `--force`, avec les deux lignées comme ancêtres.

### T2 — Reprendre la conception de la lignée A
- **Objectif :** réunir la conception sur une seule branche.
- **Fichiers :**
  - `docs/decisions/arbitrage-t029-temps-strategique-tactique.md` ;
  - `docs/decisions/0001` à `0006` et `README.md` ;
  - `docs/founding-document-v0.1.md`, `docs/design-review-v0.1.md` ;
  - documents de domaine détaillés de A sous `docs/legacy-oct31/` ;
  - index dans `docs/decisions/DECISIONS_PENDING.md`.
- **Dépendances :** aucune.
- **Risques :** modifier un statut en le copiant ; doublons ou contradictions avec `PROJECT.md` v1.1.
- **Méthode :** `git show 2a341d1:<chemin>` et `git show cdd3ab1:docs/decisions/0006…`, copie à l'identique avec un en-tête de provenance (commit d'origine). Table de concordance D-001 à 026 / `PROJECT.md` v1.1 ; les contradictions sont **signalées**, pas résolues.
- **Tests :** `diff` octet pour octet entre la copie et l'original (hors en-tête) ; vérification que T-029 et ADR-0005 restent « proposé » ou « document de travail ».
- **Résultat attendu :** T-029 et les ADR accessibles depuis la lignée de référence, avec leurs statuts intacts.

### T3 — Infrastructure documentaire sur la référence
- **Objectif :** `AGENTS.md`, `CONTRIBUTING.md` et l'audit de centralisation à jour sur `40a3117`.
- **Fichiers :** `AGENTS.md`, `CONTRIBUTING.md`, `.gitignore`, `README.md`, `docs/map/audit/GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md`.
- **Dépendances :** aucune.
- **Risques :** conflits sur `AGENTS.md`.
- **Méthode :**
  1. `git cherry-pick 2d7bb5c` sur la branche d'intégration et résoudre les conflits à la main.
  2. Ajouter : le chemin canonique du dépôt de travail, l'interdiction de `~/Projets/GrandStrategy`, un worktree par agent et la commande `validate_all.sh`.
- **Tests :** relecture ; les fichiers de carte restent inchangés (empreintes).
- **Résultat attendu :** les règles multi-agents sont applicables sur la référence.

### T4 — Environnement GIS durable, validation unifiée et CI
- **Objectif :** des validateurs exécutables partout, et automatiquement.
- **Fichiers :** `tools/map/validate_all.sh` (nouveau), `tools/map/README.md` (nouveau), `.github/workflows/map-validation.yml` (nouveau), `tools/map/SHA256SUMS` (nouveau, empreintes de référence).
- **Dépendances :** aucune.
- **Risques :**
  - `validate_topology.py` vérifie sa propre empreinte : ne pas toucher aux scripts existants ;
  - temps de CI dû à la géométrie de 17 Mo.
- **Méthode :**
  1. `python3 -m venv ~/.venvs/gs1914-gis && pip install -r tools/map/requirements.lock`.
  2. Le script enchaîne `sha256sum -c`, puis les 4 validateurs, et sort avec un code non nul au premier échec.
  3. Le workflow Ubuntu reprend les mêmes étapes.
- **Tests :** exécution locale (93/0 et 95/0), puis exécution CI sur une PR.
- **Résultat attendu :** une CI verte sur la référence et le venv hors de `/tmp`.

### T5 — Curation du catalogue maritime
- **Objectif :** rattacher les 26 façades orphelines et cataloguer les 14 liens uniquement géométriques.
- **Fichiers :** `data/world/map/build/agent_2/maritime_zones.json`, ou un nouveau catalogue consolidé. `adjacency.json` est régénéré par `rebuild_topology.py`.
- **Dépendances :** T4. Une **validation du directeur** est requise si de nouvelles zones sont découpées (Manche, Atlantique, Méditerranée occidentale, Tyrrhénienne, Adriatique nord), car cela touche à MAP-DEC-11.
- **Risques :** l'empreinte de `maritime_zones.json` est figée dans `validate_topology.py`, donc le validateur devra être mis à jour (nouvelle référence documentée).
- **Méthode :**
  1. Lister les 26 régions.
  2. Pour chacune, déterminer la zone par contact géométrique, ou consigner « aucune zone adaptée » avec sa justification.
  3. Rebâtir, puis comparer.
- **Tests :** `--rebuild-check` ; nouveau contrôle « toute région côtière a un lien ou une justification ».
- **Résultat attendu :** catalogue de 66 liens ou plus, cohérent avec la géométrie, dans une PR auditable.

### T6 — Arbitrages : Corfou, proximités, région 051
- **Objectif :** décider (ou faire décider) des traversées hors adjacence terrestre.
- **Fichiers :** nouveau `docs/map/decisions/MARITIME_CROSSINGS.md` ; ensuite, éventuellement, la liste des détroits dans `rebuild_topology.py`.
- **Dépendances :** T5. **Décision du directeur** sur les effets de jeu.
- **Risques :** connexions sans source historique.
- **Méthode :** une fiche par cas (distance, sources de 1914, options, recommandation), soumise en un seul lot.
- **Tests :** validateur mis à jour ; la région 051 n'est plus isolée, ou son isolement est justifié.
- **Résultat attendu :** un registre d'arbitrages signé.

### T7 — Réparation de `mz_norwegian_sea`
- **Objectif :** une géométrie valide, qui touche si possible la côte islandaise.
- **Fichiers :** géométrie des zones maritimes (lot `agent_2`) et nouveau script `tools/map/repair_maritime_zone.py`.
- **Dépendances :** T4.
- **Risques :** modification d'autres liens maritimes.
- **Méthode :** `shapely.make_valid` ; comparaison des surfaces avant et après ; extension de l'emprise vers l'Islande seulement si T6 l'approuve.
- **Tests :** `is_valid` ; rebuild ; différences d'arêtes maritimes listées.
- **Résultat attendu :** `geometry_valid: true` et le `buffer(0)` supprimé.

### T8 — Statut de `regions.json`
- **Objectif :** éliminer la double source d'adjacence.
- **Fichiers :** `data/world/map/regions.json` et les validateurs qui contrôlent son empreinte.
- **Dépendances :** T4.
- **Risques :** l'empreinte de référence change.
- **Méthode :** recommandation : retirer `adjacent_region_ids` de `regions.json` (index éditorial seul), ou générer ce champ depuis `adjacency.json`. Choix technique documenté par une ADR.
- **Tests :** validateurs ; aucun consommateur ne lit l'ancien champ.
- **Résultat attendu :** une seule source d'adjacence.

### T9 — Réintégrer les villes et l'audit thématique
- **Objectif :** amener `cities.json` (175 entrées) sur la géométrie validée.
- **Fichiers :** `data/world/map/cities.json`, `tools/map/unify_thematic_data.py`, `docs/map/corrections/THEMATIC_DATA_AUDIT.md` (depuis `4dbf4f8` et `8a5d2bf`) ; nouveau `tools/map/validate_cities.py`.
- **Dépendances :** T4.
- **Risques :** villes rattachées à une mauvaise région après Saray et Strumica.
- **Méthode :** `git checkout 4dbf4f8 -- <fichiers>` sur une branche dédiée ; test point-dans-polygone de chaque ville contre `regions.geojson` ; liste des écarts.
- **Tests :** `validate_cities.py` (id unique, coordonnées, région ou zone cohérente, capitales présentes).
- **Résultat attendu :** une couche de villes valide sur la référence.

### T10 — Provenance des données historiques et démographie de 1914
- **Objectif :** amorcer la phase 3 sans données inventées.
- **Fichiers :** `data/schemas/provenance.schema.json`, `data/world/demography/regions_1914.json`, `docs/data/SOURCES.md`.
- **Dépendances :** T9 souhaitable.
- **Risques :** sources hétérogènes (recensements de 1910 à 1913) ; découpages non concordants.
- **Méthode :** une valeur par région, avec source, date, méthode d'agrégation et confiance. Les notes de recherche de la sauvegarde servent de point de départ.
- **Tests :** validation par schéma ; somme par État comparée aux totaux nationaux publiés (écart documenté).
- **Résultat attendu :** une population sourcée pour les 90 régions.

### T11 — Arbitrage T-029 *(décision du directeur)*
- **Objectif :** trancher D1 à D5.
- **Fichiers :** T-029, ADR-0005 (passage en « accepté » ou « rejeté »), `PROJECT.md`, `DECISIONS_PENDING.md`.
- **Dépendances :** T2.
- **Risques :** choix incompatible avec le multijoueur futur.
- **Méthode :** présenter la fiche de décision existante, recueillir la décision, l'enregistrer en ADR.
- **Tests :** cohérence documentaire (aucun document ne contredit la décision).
- **Résultat attendu :** le temps stratégique et tactique est spécifié.

### T12 — Moteur et statut du prototype Python *(décision du directeur)*
- **Objectif :** lever le conflit entre l'ADR-0006 (Python) et la proposition Godot.
- **Fichiers :** nouvelle ADR comparative ; ADR-0006 marquée « remplacé » le cas échéant ; `TECHNICAL_ARCHITECTURE.md`.
- **Dépendances :** T2.
- **Risques :** coût de bascule ; dette technique.
- **Méthode :** relecture de `cdd3ab1` (architecture, tests, éléments réutilisables) ; installation de Godot 4.7.2 stable ; ADR comparative.
- **Tests :** `python -m unittest` du prototype sur une extraction temporaire, pour constater son état réel ; ouverture de `project.godot`.
- **Résultat attendu :** un moteur confirmé et un statut explicite du prototype.

### T13 — Hygiène du poste et des sauvegardes
- **Objectif :** supprimer les ambiguïtés de travail.
- **Fichiers :** `~/backups/gs1914-2026-11-13/MANIFEST.md` (hors dépôt) ; métadonnées des worktrees.
- **Dépendances :** aucune.
- **Risques :** quasi nuls, car les commits sont tous sur `origin`.
- **Méthode :** `git worktree prune` ; note `OBSOLETE.md` dans `~/Projets/GrandStrategy` (ou archivage du dossier) ; mise à jour du manifeste ; nouveau bundle après T1.
- **Tests :** `git worktree list` ; `git bundle verify`.
- **Résultat attendu :** un seul dépôt de travail identifié et des sauvegardes à jour.

---

## Annexe — Commandes de reproduction de l'audit

```bash
REPO=~/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914
git -C $REPO ls-remote origin                     # 30 branches
git -C $REPO merge-base 40a3117 1ec985f           # vide : lignées disjointes
for f in data/world/map/adjacency.json tools/map/rebuild_topology.py \
         tools/map/validate_topology.py data/world/map/regions.geojson \
         data/world/map/regions.json; do git -C $REPO show 40a3117:$f | sha256sum; done
PY=/tmp/opencode/gs1914-gis-venv/bin/python       # à remplacer par un venv durable (T4)
$PY tools/map/validate_geometry.py && $PY tools/map/validate_atlas.py
$PY tools/map/validate_topology.py && $PY tools/map/validate_topology.py --rebuild-check
gh repo view elielbarbucovantes-source/grand-strategy-1914 --json visibility
```
