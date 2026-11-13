# AUDIT DE CENTRALISATION GITHUB ET ÉTAT DES BRANCHES — GRAND STRATEGY-1914

- **Date** : 13 novembre 2026
- **Dépôt local principal** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **Dépôt distant GitHub (`origin`)** : `https://github.com/elielbarbucovantes-source/grand-strategy-1914` (Privé)
- **Branche du présent rapport** : `docs/github-central-infrastructure`

---

## 1. Audit initial de l'état local et distant

### 1.1 Emplacements locaux identifiés sur la machine
L'inspection complète du poste a mis en évidence **deux dépôts locaux successifs** appartenant au projet :

1. **Dépôt principal actuel (lignée du 1er au 13 novembre 2026)** :
   - **Chemin** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
   - **Racine Git** : commit `5d8579f` (*« docs: prepare cartography data foundation »*, 2026-11-01).
   - **Contenu** : corpus maître restructuré (`PROJECT.md` v1.1, interdiction explicite du gameplay), architecture technique Godot 4.7.2 (`docs/architecture/TECHNICAL_ARCHITECTURE.md`), 69 décisions cartographiques validées (`docs/map/TECHNICAL_SPEC.md`), index des 90 régions (`data/world/map/tables/region_plan.csv`), lots cartographiques (`agent_1`, `agent-2`), audits, topologie, données thématiques, consolidation géométrique (`consolidate/map-1914-geometry` à `a7983e7`) et correction du saillant de Stroumitsa (`fix/map-strumica-final` à `03bce80`).
   - **Worktrees actifs rattachés** :
     - `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914` (`consolidate/map-1914-geometry`, `a7983e7`)
     - `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/worktrees/fix-map-strumica-final` (`fix/map-strumica-final`, `03bce80`)
     - `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/worktrees/docs-github-central-infrastructure` (`docs/github-central-infrastructure`)
     - `/home/cassiop-e/.gemini/antigravity-cli/brain/2e364ab6-b671-40b7-9658-41e3ad3fecb7/scratch/wt_fix_geometry` (`fix/map-geometry`, `b5a07ae`)

2. **Dépôt initial de cadrage (lignée du 31 octobre 2026)** :
   - **Chemin** : `/home/cassiop-e/Projets/GrandStrategy` (et son worktree `/home/cassiop-e/Projets/GrandStrategy-opencode`)
   - **Racine Git** : commit `459375a` (*« docs: initialiser l'infrastructure documentaire du projet »*, 2026-10-31).
   - **Lien avec GitHub** : ce dépôt avait déjà créé et alimenté le dépôt privé `https://github.com/elielbarbucovantes-source/grand-strategy-1914.git` le 31 octobre 2026 (`origin/main` à `1ec985f`), et comportait en outre deux avancées locales non poussées (`main` à `2a341d1` et `feat/mvp-playable` à `cdd3ab1`).

### 1.2 État exact de la correction de Stroumitsa (`MAJ-003`)
- **Branche** : `fix/map-strumica-final`
- **Worktree** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/worktrees/fix-map-strumica-final`
- **Commit** : `03bce804d3da26783b444eb50e8979a58c325738` (`03bce80`), parent `a7983e72730f0a80d6e00ca2add74f94b717ff5d`.
- **Contenu de la correction** :
  - Extraction reproductible dans `data/world/map/sources/derived/gs1914_strumica_1913_salient.geojson` de la limite nord/nord-ouest de 1913 entre la Cote 1445 `(22.968377, 41.579668)` et le tripoint du mont Plavuš `(22.502811, 41.458667)` (préservée dans `REGIS_Yugoslavia.gpkg:REGIS_Yugoslavia_L1_1920-1923` entre `Bregalnitsa` `640-1.290` et `Bitoly` `640-1.300`) et de la ligne de partage des eaux Vardar-Strouma par le col de Kosturino jusqu'au tripoint bulgaro-gréco-serbe de 1913 à la Cote 1494 sur la Belasica `(22.811499, 41.328567)` (traité de Bucarest du 10 août 1913, art. III et V, protocole n° 9 ; accord gréco-serbe du 3/16 août 1913).
  - Rétrocession de `1 151,51 km²` (EPSG:3035) de `region_074` (*Serbie*, `89 797,38` → `88 645,87 km²`) à `region_072` (*Bulgarie occidentale*, `40 498,91` → `41 650,42 km²`), avec conservation exacte de la superficie cumulée (`130 296,283421 km²`) et des 88 autres régions.
- **État des tests et audits sur `fix/map-strumica-final`** :
  - **Validateurs géométriques (`validate_geometry.py`, `validate_atlas.py`)** : **TERMINÉS ET RÉUSSIS** (code de sortie `0` ; `Strumica: dans 072=True, dans 074=False` ; `90/90` géométries valides ; `0` chevauchement `> 1e-10 deg²` ; `0/4` lacune sentinelle ; `Saray: point dans 088=True, Van dans 088=False`).
  - **Test de reproductibilité bit-à-bit (`consolidate_geometry.sh`)** : **TERMINÉ ET RÉUSSI** (vérification `sha256sum -c` confirmant `data/world/map/regions.geojson: Réussi` et `data/world/map/regions.json: Réussi` dans le journal `task-367.log`).
  - **Audit indépendant et rapport final `STRUMICA_FINAL_RESOLUTION.md`** : **NON LANCÉS / EN ATTENTE**. Conformément aux règles du projet, la correction de Stroumitsa est **conservée et publiée sur `origin/fix/map-strumica-final`**, mais **n'est pas déclarée définitivement auditée** tant que le processus d'audit indépendant n'a pas été exécuté.

### 1.3 Contrôle de sécurité et des fichiers volumineux
- **Secrets / tokens / clés privées** : aucun secret ni jeton trouvé dans l'historique Git de l'ensemble des branches (`git grep` négatif sur tous les commits).
- **Fichiers volumineux suivis** : le plus gros fichier suivi est `data/world/map/regions.geojson` (`17,38 Mo`), largement inférieur à la limite GitHub de `100 Mo` par fichier. Aucune migration vers Git LFS n'est requise ni effectuée.
- **Sources externes brutes (≈ 373 Mo)** : conservées hors Git dans `/home/cassiop-e/backups/gs1914-2026-11-13/sources/external/regis/` ; seuls les 4 extraits minimaux dérivés (`data/world/map/sources/derived/`, `≈ 4,1 Mo` au total) sont versionnés pour garantir la reproductibilité autonome.

---

## 2. Classification de l'ensemble des branches conservées sur GitHub (`origin`)

Aucune branche n'a été supprimée ni fusionnée automatiquement. Les deux dépôts locaux ont été réunis dans la même base d'objets Git et toutes les branches ont été publiées sur `origin`.

### A. Travaux terminés et validés (dans leur périmètre respectif)
| Branche | Commit | Description et statut |
|---|---|---|
| `foundation/main-2026-11-01` (et `main` local) | `4ffdb8a09981b8d51f103bd2c2088fed9506a71f` | Socle documentaire v1.1 du 1er novembre 2026 : interdiction du gameplay, architecture Godot 4.7.2 proposée, 69 décisions cartographiques validées (`MAP-DEC-01` à `69`), plan éditorial des 90 régions (`region_plan.csv`) et validateur `validate_atlas.py`. |
| `agent_1` | `286975a96fc2238040a9bf09163c664740ee3854` | Lot cartographique 1 (50 régions d'Europe occidentale, centrale, ibérique, britannique et italienne) sous `data/world/map/build/agent_1/`. |
| `agent-2` | `baa0c90932c74a39ae8745add9a07a7686cd770e` | Lot cartographique 2 (40 régions de Scandinavie, Europe orientale, Balkans et Empire ottoman européen + 16 zones maritimes) sous `data/world/map/build/agent_2/`. |
| `audit/map-1914` | `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` | Audit global initial des 90 régions (`GLOBAL_AUDIT.md`, `ISSUES.json`, `INTEGRATION_CHECKLIST.md`, `validate_global_atlas.py`). |
| `consolidate/map-1914-geometry` | `a7983e72730f0a80d6e00ca2add74f94b717ff5d` | **Jalon de consolidation géométrique 1914** : résout `BLK-001` (Saray/Van), `BLK-002` (micro-chevauchements) et `MAJ-004` (4 lacunes de couture) avec extraits sources versionnés et reproductibilité bit-à-bit vérifiée (hors Stroumitsa `MAJ-003`). |
| `docs/github-central-infrastructure` | *(présente branche)* | Documentation commune multi-IA et multi-ordinateurs (`AGENTS.md`, `CONTRIBUTING.md`, `.gitignore` renforcé et présent rapport d'audit). |

### B. Travaux terminés techniquement mais en attente d'audit indépendant ou de reconstruction aval
| Branche | Commit | Description et statut |
|---|---|---|
| `fix/map-strumica-final` | `03bce804d3da26783b444eb50e8979a58c325738` | **Correction du saillant de Stroumitsa (`MAJ-003`)** construite sur `a7983e7`. Tous les validateurs géométriques (`validate_geometry.py`, `validate_atlas.py`) et le test de reproductibilité bit-à-bit (`consolidate_geometry.sh`) passent à `0`. **En attente de l'audit indépendant et du rapport `STRUMICA_FINAL_RESOLUTION.md`.** |
| `fix/map-topology-v2` | `76333e17a15725ef2dfdbbfa5ea05847820ccf65` | Graphe d'adjacence unifié (`adjacency.json`, 184 arêtes terrestres, 10 détroits) et script `build_adjacency.py`. Construit sur les géométries pré-consolidation (`b5a07ae`) : devra être rejoué sur la géométrie finale après audit de `fix/map-strumica-final`. |
| `fix/map-thematic-data-v2` | `4dbf4f843f92f6b492930995e35194f586e0f076` | Unification du catalogue des 175 villes stratégiques (`data/world/map/cities.json`) et script `tools/map/unify_thematic_data.py`. |
| `audit/map-thematic-data` | `8a5d2bfb47fa26035061dc7f6cc211455958a89f` | Rapport d'audit des données thématiques (`docs/map/audit/THEMATIC_DATA_AUDIT.md`). |

### C. Étapes intermédiaires de la chaîne géométrique (intégrées dans `consolidate/map-1914-geometry`)
| Branche | Commit | Description et statut |
|---|---|---|
| `fix/map-geometry-v2` | `fc26c18da7d85055158048af73be9cd0d97` | Première assemblée géométrique 90 régions (`BLK-001` + `BLK-002`, avant comblement `MAJ-004`). |
| `fix/map-geometry-gaps` | `219373bc33842566ca904a564e5c07de770164bf` | Script `close_geometry_gaps.py` et rapport `GEOMETRY_GAPS_RESOLUTION.md` (`MAJ-004`). |
| `integrate/map-1914-final-audit` | `219373bc33842566ca904a564e5c07de770164bf` | Pointe sur le même commit `219373b` que `fix/map-geometry-gaps`. |

### D. Branches coquilles / alias historiques (conservées sans suppression)
| Branche | Commit | Observation |
|---|---|---|
| `fix/map-geometry` | `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` | Coquille vide pointant sur `audit/map-1914` (remplacée par `fix/map-geometry-v2`). |
| `fix/map-topology` | `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` | Coquille vide pointant sur `audit/map-1914` (remplacée par `fix/map-topology-v2`). |
| `fix/map-thematic-data` | `b5a07aee2d6d545ebf42ec682ec9d0dd25353387` | Coquille vide pointant sur `audit/map-1914` (remplacée par `fix/map-thematic-data-v2`). |
| `audit/natural-resources-inventory` | `8a5d2bfb47fa26035061dc7f6cc211455958a89f` | Alias pointant sur `audit/map-thematic-data` (les notes de recherche sur les ressources naturelles figurent hors Git dans `/home/cassiop-e/research_notes/Ressources naturelles 1914/`). |

### E. Branches historiques de la première lignée (31 octobre 2026 — `/home/cassiop-e/Projets/GrandStrategy`)
| Branche | Commit | Observation |
|---|---|---|
| `main` (sur `origin`) / `archive/oct31-origin-main` | `1ec985f1dcb060177d8ec9fe85955d6957a4537b` | État initial de `origin/main` poussé le 31 octobre 2026 (fiche maîtresse v0.1/v0.2, ADR 0001–0005). Conservé intact sans push forcé. |
| `archive/oct31-main-t029` | `2a341d12989e865e81f4978177610572c6931f58` | Commit local du 1er novembre 2026 (`docs(decisions): dossier d'arbitrage T-029 temps stratégique/tactique`) issu de `/home/cassiop-e/Projets/GrandStrategy`. |
| `docs/conception-suite` | `1ec985f1dcb060177d8ec9fe85955d6957a4537b` | Branche documentaire du 31 octobre 2026 déjà présente sur `origin`. |
| `docs/fiche-maitresse-v0.2` | `e20bf90bbb94a75c8af810e35af3162269058dbd` | Branche documentaire du 31 octobre 2026 déjà présente sur `origin`. |
| `docs/fiche-maitresse-opencode` | `ca0d4e22e0b910135a0e7578f712bc4d58f4330e` | Branche documentaire du 31 octobre 2026 déjà présente sur `origin`. |
| `feat/mvp-playable` / `archive/oct31-mvp-playable` | `cdd3ab16807780916d3072c5fa44ccbc19200e7e` | Prototype expérimental du 31 octobre 2026 antérieur à la règle de gel du gameplay (`GATE-01`). Conservé pour archive historique ; **ne doit pas être repris ni fusionné**. |

---

## 3. Conflit structurel identifié sur `main` et demande d'arbitrage

### Nature de la divergence
1. Le **31 octobre 2026**, le dépôt `https://github.com/elielbarbucovantes-source/grand-strategy-1914.git` a été initialisé depuis `/home/cassiop-e/Projets/GrandStrategy` avec une première arborescence (`CLAUDE.md`, `docs/founding-document-v0.1.md`, `docs/decisions/0001-*.md` à `0005-*.md`) et son `origin/main` pointe sur `1ec985f1dcb060177d8ec9fe85955d6957a4537b` (suivi localement par `2a341d1`).
2. Le **1er novembre 2026**, le dépôt `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914` a été initialisé par un nouveau `git init` indépendant (racine `5d8579f` → `main` à `4ffdb8a09981b8d51f103bd2c2088fed9506a71f`), dont dérivent toutes les branches de l'atlas de 1914 (`consolidate/map-1914-geometry` à `a7983e7`, `fix/map-strumica-final` à `03bce80`, etc.).
3. Les deux branches `main` (`1ec985f` sur `origin` et `4ffdb8a` en local) n'ont **aucun ancêtre Git commun**.

### Respect des contraintes de sécurité
Conformément aux règles strictes de la mission :
- **Aucun push forcé (`git push --force`) n'a été exécuté sur `main`.**
- **Aucun contenu existant sur GitHub n'a été écrasé ni supprimé.**
- La branche `main` du 1er novembre 2026 (`4ffdb8a`) a été publiée sur GitHub sous le nom explicite **`foundation/main-2026-11-01`**, et toutes les branches de travail (`consolidate/map-1914-geometry`, `fix/map-strumica-final`, `docs/github-central-infrastructure`, etc.) sont publiées sur `origin`.

### Options soumises à l'arbitrage du directeur de conception
Pour aligner définitivement `origin/main` sans perte d'historique, deux options s'offrent à votre décision :
- **Option 1 (Recommandée — Fusion d'ancrage à deux parents sans perte ni push forcé)** : créer un commit de jonction sur `main` ayant pour parents `2a341d1` (lignée du 31 octobre 2026) et `4ffdb8a` (ou `docs/github-central-infrastructure`, lignée du 1er–13 novembre 2026), en conservant l'arborescence validée de novembre 2026 tout en archivant les ADR d'octobre 2026 dans `docs/decisions/archive-v0.1/`. Cela permet d'avancer `origin/main` en **fast-forward** pur (sans `--force`) tout en conservant les deux historiques dans le graphe de `main`.
- **Option 2 (Bascule directe après archivage)** : conserver la lignée du 31 octobre 2026 sur les branches `archive/oct31-*` et faire pointer `origin/main` directement sur la lignée de novembre 2026 (`4ffdb8a` ou `docs/github-central-infrastructure`).
