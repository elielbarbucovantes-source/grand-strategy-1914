# Répertoires de travail : référence, copies obsolètes et archivage

- **Date :** 14 novembre 2026 (phase 1, tâche 4)
- **Règle appliquée :** aucun répertoire, fichier ou historique n'a été supprimé. L'archivage a été préféré à la suppression. Les seules métadonnées retirées sont celles de six worktrees Git dont le répertoire n'existait plus.

## 1. Répertoire de référence

`~/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`

Ce répertoire contient tous les objets de `origin`. Ses worktrees se trouvent dans `../worktrees/` :

| Worktree | Branche | Usage |
|---|---|---|
| `grand-strategy-1914/` (principal) | `consolidate/map-1914-geometry` | Historique ; `.venv/` local (shapely 2.2.0) également utilisable |
| `worktrees/consolidate-map-1914-topology` | `consolidate/map-1914-topology` | Référence cartographique `40a3117` |
| `worktrees/phase-1-consolidation` | `consolidate/phase-1` | Consolidation de la phase 1 |
| `worktrees/docs-project-handover-audit` | `docs/project-handover-audit` | Audit de reprise |
| `worktrees/audit-map-strumica-final`, `fix-map-strumica-final`, `docs-github-central-infrastructure` | branches homonymes | Travaux terminés, conservés |

## 2. Inventaire des copies et répertoires annexes

| Emplacement | Nature | Données uniques ? | Traitement |
|---|---|---|---|
| `~/Projets/GrandStrategy` | Dépôt de la lignée du 31/10 (`main` = `2a341d1`), pas de fetch depuis le 01/11 | **Non** : 0 commit absent du dépôt de référence, 0 modification non commitée, 0 stash | **Obsolète.** Archivé, note `OBSOLETE_NE_PAS_UTILISER.md` ajoutée (non versionnée) |
| `~/Projets/GrandStrategy-opencode` | Worktree du précédent (`feat/mvp-playable` = `cdd3ab1`, prototype Python) | Seulement `saves/` (3 sauvegardes de test du prototype, 428 Ko, ignorées par Git) | **Obsolète.** Archivé avec `saves/`, note ajoutée |
| `~/backups/gs1914-2026-11-13/` | Bundles, archive d'arbre, sources REGIS (373 Mo), notes de recherche, prototypes de scripts | **Oui** : sources externes et notes de recherche, hors Git | **À conserver.** Addendum ajouté au `MANIFEST.md` (le remote existe désormais) |
| `~/backups/gs1914-2026-11-13/independent-clone-test` | Clone de test de restauration (13/11) | Non | Conservé ; supprimable sur décision |
| `grand-strategy-1914/.consolidation-stage/` | Résidu de construction (ignoré par Git) | **Non** : identique octet pour octet à `a7983e7:data/world/map/regions.{geojson,json}` | Conservé ; supprimable sans perte |
| `tu-es-responsable-du-d-veloppement/outputs/plan-technique-grand-strategy-1914.md` | Liste de liens du 01/11 | Non (simples liens vers des fichiers versionnés) | Conservé |
| `tu-es-responsable-du-d-veloppement/{.agents,.aws,.codex,.git,work}` | Répertoires vides créés par un outil | Non | Conservés |
| `~/.gemini/antigravity-cli/…/scratch/wt_fix_geometry` | Worktree enregistré (`fix/map-geometry` = `b5a07ae`), propre | Non (branche coquille sur `origin`) | Conservé ; détachable par `git worktree remove` sur décision |
| `/tmp/opencode/gs1914-gis-venv` | Ancien venv GIS volatil | Non | Remplacé par `~/.venvs/gs1914-gis` (`tools/map/README.md`) |
| `~/Téléchargements/testGit` | Dépôt sans rapport (scripts R) | — | Hors projet |

## 3. Opérations effectuées

1. **Archive** `~/backups/gs1914-2026-11-14-obsolete-workspaces/projets-GrandStrategy-lineage-oct31.tar.gz` (1,1 Mo, 605 entrées, `.git` et `saves/` inclus, `__pycache__` exclus).
   - SHA-256 : `2e80a623ac1ee019c484b6562ad6e9243c267e422985f6683fb5e1ee62cc2fff` (fichier `SHA256SUMS` à côté).
2. **Notes d'avertissement** `OBSOLETE_NE_PAS_UTILISER.md` dans les deux répertoires obsolètes.
3. **`git worktree prune`** (après simulation avec `--dry-run`).
   - Six enregistrements retirés : `/tmp/mammouth/gs1914-{geometry-audit,natural-resources,thematic-data-audit}` et `/tmp/opencode/gs1914-{final-audit,geometry-gaps,geometry-v2}`.
   - Leurs répertoires n'existaient plus, et leurs commits (`fc26c18`, `8a5d2bf`, `219373b`) sont sur `origin`.
4. **Addendum** au manifeste de sauvegarde du 13/11.

## 4. Propositions (non exécutées)

- Supprimer `~/Projets/GrandStrategy*` **après** accord du directeur. L'archive vérifiée et GitHub en contiennent tout l'historique.
- Faire une copie des sauvegardes (`~/backups/`) sur un **support distinct**. Elles sont aujourd'hui sur le même disque que le dépôt.
- Produire un nouveau bundle Git complet après l'alignement de `main`.
