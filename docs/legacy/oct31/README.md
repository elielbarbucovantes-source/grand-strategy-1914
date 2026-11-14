# Archives documentaires de la lignée du 31 octobre 2026

Ce dossier contient des copies **octet pour octet** de documents de la lignée Git A (racine `459375a`). Leur nom entre en collision avec des documents de la lignée de référence, ou il en existe plusieurs versions concurrentes.

Ces fichiers sont **historiques** : ils ne sont ni à modifier ni à suivre comme référence courante. Le document maître en vigueur est `PROJECT.md` (v1.1) à la racine.

| Fichier | Source |
|---|---|
| `PROJECT.md` | `2a341d1:PROJECT.md` (table D-001 à D-030, §20.1) |
| `decisions-README.2a341d1.md` | `2a341d1:docs/decisions/README.md` (variante T-029) |
| `decisions-README.cdd3ab1.md` | `cdd3ab1:docs/decisions/README.md` (variante MVP / ADR-0006) |

Provenance complète et contradictions : `docs/decisions/RAPATRIEMENT_LIGNEE_OCT31.md`.

## Copies ajoutées pour l'alignement de `main` (branche `integrate/main-alignment-preview`)

Les fichiers suivants de `origin/main` (`1ec985f`) sont copiés octet pour octet, sous leur chemin d'origine relatif à ce dossier :
- tous les fichiers **absents** de l'arbre de la lignée de référence (31 fichiers, dont `docs/nations/nations.md`, `docs/ai/*`, `docs/diplomacy/*`, `docs/military/*`) ;
- les versions de A des fichiers homonymes (`AGENTS.md`, `CHANGELOG.md`, `PROGRESS.md`).

Après la jonction, **aucun fichier de `1ec985f` ne disparaît** de l'arbre visible de `main`.

Renommages, nécessaires pour éviter une collision ou garder les copies inertes :

| Original (`1ec985f`) | Copie |
|---|---|
| `README.md` (racine) | `README-racine-oct31.md` |
| `.gitignore` | `dot-gitignore.txt` |
| `.env.example` | `dot-env.example.txt` |
| `docs/decisions/0005-integration-strategique-tactique.md` (version initiale `4f820c5`) | `decisions-0005.1ec985f.md` |
| `docs/decisions/README.md` (version initiale `1429119`) | `decisions-README.1ec985f.md` |
| `scripts/check-infrastructure.sh` | même chemin, sans bit exécutable (contenu inchangé) |

Vérification : `git show 1ec985f:<chemin> | cmp - docs/legacy/oct31/<copie>`.
