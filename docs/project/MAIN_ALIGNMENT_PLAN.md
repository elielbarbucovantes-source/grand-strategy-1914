# Plan d'alignement de `main`

- **Date :** 14 novembre 2026 (phase 1)
- **Statut :** **PRÉPARÉ, NON EXÉCUTÉ.** `main` n'a pas été modifié. L'exécution exige la **validation explicite du directeur**.
- **Orientation du directeur (14/11/2026) :** relier les deux historiques par un commit de fusion à deux parents, sans réécriture. Les lignées du 31 octobre et du 1er novembre restent intégralement conservées.

## 1. Situation

| Référence | Commit | Lignée |
|---|---|---|
| `origin/main` | `1ec985f` | A, 31/10 (racine `459375a`) |
| `consolidate/map-1914-topology` | `40a3117` | B, 01/11 (racine `5d8579f`), cartographie validée |
| `consolidate/phase-1` | voir `PHASE_1_CONSOLIDATION_REPORT.md` | B + consolidation de la phase 1 |

`git merge-base 1ec985f 40a3117` ne renvoie rien : les deux historiques n'ont aucun ancêtre commun.

## 2. Inventaire des fichiers des deux arbres

Comparaison de `1ec985f` avec la pointe de `consolidate/phase-1` :

| Catégorie | Nombre | Traitement dans l'arbre fusionné |
|---|---|---|
| Chemins communs, contenu identique | 7 (ADR 0000 à 0004, document fondateur, revue de conception) | Inchangés |
| Chemins communs, contenu différent | 8 : `AGENTS.md`, `CHANGELOG.md`, `PROGRESS.md`, `PROJECT.md`, `README.md`, `.gitignore`, ADR-0005, `docs/decisions/README.md` | **Version de la lignée B retenue.** Version de A conservée octet pour octet dans `docs/legacy/oct31/` (README racine → `README-racine-oct31.md`, `.gitignore` → `dot-gitignore.txt`, ADR-0005 et index initiaux → `decisions-0005.1ec985f.md`, `decisions-README.1ec985f.md`) |
| Uniquement dans A | 31, dont `docs/nations/nations.md` (source de D-027 à D-029), `docs/ai/*`, `docs/diplomacy/*`, `docs/military/*`, `CLAUDE.md`, `.env.example`, `scripts/check-infrastructure.sh` | **Copiés octet pour octet** sous `docs/legacy/oct31/<chemin>` (`.env.example` → `dot-env.example.txt`) |
| Uniquement dans B | Tout le reste : cartographie, outils, CI, docs de B | Inchangés |

**Pourquoi la version de B pour les fichiers homonymes ?** B porte les règles en vigueur (`PROJECT.md` v1.1, gel du gameplay, 69 MAP-DEC). Les versions de A restent consultables et sont signalées comme historiques. Ce n'est **pas** un arbitrage de conception : les contradictions entre A et B sont listées (R-01 à R-12) et restent ouvertes.

## 3. Stratégie

1. **Préparation** (fait, sur la branche `integrate/main-alignment-preview`) : un commit copie dans `docs/legacy/oct31/` les fichiers de `1ec985f` absents de B ou en conflit.
2. **Commit de jonction**, construit par `git commit-tree` :
   - **arbre** : celui de la préparation (lignée B) ;
   - **parent 1** : `1ec985f`, pour que `git log --first-parent main` continue l'historique de `main` ;
   - **parent 2** : la préparation, qui apporte toute la lignée B (`4ffdb8a` → … → `40a3117` → phase 1).
3. **Publication, après validation :** `git push origin <jonction>:main`. C'est un **fast-forward** (`1ec985f` est ancêtre de la jonction) : ni `--force`, ni réécriture.
4. Les branches `archive/oct31-main-t029` (`2a341d1`) et `archive/oct31-mvp-playable` (`cdd3ab1`) **ne deviennent pas** des ancêtres de `main`. Elles restent intactes et publiées. Le contenu documentaire de `2a341d1` est déjà rapatrié ; le prototype `cdd3ab1` **n'est pas fusionné**, conformément à l'orientation sur le moteur.

`git merge -s ours` ne convient pas, car il garderait l'arbre de A. `-X theirs` ne retirerait pas les fichiers propres à A. D'où `commit-tree`, qui fixe l'arbre exactement.

## 4. Vérifications effectuées sur la prévisualisation

Commandes et résultats reportés dans `PHASE_1_CONSOLIDATION_REPORT.md`, partie III :

- [x] Parents du commit de jonction : `1ec985f` puis la préparation.
- [x] `1ec985f`, `4ffdb8a`, `a7983e7`, `03bce80`, `47bc6fe`, `6d30a51`, `40a3117` et l'audit `34e4a63` sont **ancêtres** de la jonction.
- [x] `origin/main` est ancêtre de la jonction : **fast-forward possible**.
- [x] Les **46/46** fichiers de `1ec985f` sont présents à l'identique (même blob) dans l'arbre fusionné.
- [x] Fichiers de `40a3117` : 105/109 inchangés. Les 4 modifiés (`.gitignore`, `AGENTS.md`, `README.md`, `DECISIONS_PENDING.md`) sont les mises à jour volontaires de la phase 1.
- [x] Les 5 empreintes de référence de la cartographie sont inchangées ; `validate_all.sh` est vert.

## 5. Risques

| Risque | Atténuation |
|---|---|
| Un lecteur de `main` confond les documents `legacy` avec la référence | `docs/legacy/oct31/README.md` et `AGENTS.md` §0 les déclarent historiques |
| Liens internes des documents de A cassés ou résolus vers les fichiers de B | Documenté dans `RAPATRIEMENT_LIGNEE_OCT31.md` §5 ; non corrigé, pour ne pas modifier les copies |
| Clones existants de `main` (lignée A) | Le fast-forward ne casse rien : `git pull` suffit |
| `main` avance entre la préparation et l'exécution | Revérifier `git ls-remote origin main` = `1ec985f` juste avant le push ; sinon, reconstruire la jonction |
| La branche par défaut GitHub affiche la nouvelle arborescence | C'est l'effet voulu ; à annoncer |

## 6. Procédure d'exécution (après validation explicite)

```bash
git fetch origin --prune
test "$(git rev-parse origin/main)" = 1ec985f1dcb060177d8ec9fe85955d6957a4537b   # main n'a pas bougé
git checkout integrate/main-alignment-preview && tools/map/validate_all.sh --full
J=$(git rev-parse integrate/main-alignment-preview)
git merge-base --is-ancestor origin/main "$J"          # fast-forward garanti
git push origin "$J":main                               # sans --force
git ls-remote origin main                               # = $J
```

Ensuite :
- mettre à jour `AGENTS.md` et `CONTRIBUTING.md` (`main` devient la base de référence) ;
- produire un nouveau bundle de sauvegarde ;
- vérifier la CI sur `main`.
