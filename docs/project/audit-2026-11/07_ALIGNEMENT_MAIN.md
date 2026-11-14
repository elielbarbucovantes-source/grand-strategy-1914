# Audit de la prévisualisation de l'alignement de `main` (partie 6)

- **Objet :** `integrate/main-alignment-preview` (`c99051b`). Plan de référence : `docs/project/MAIN_ALIGNMENT_PLAN.md`.
- **Statut :** audit et procédure. **Aucune fusion n'est réalisée.**

## 1. Vérifications effectuées sur `c99051b`

| Contrôle | Résultat |
|---|---|
| Parents | `1ec985f` (`origin/main`), puis `3a27371` (préparation des copies `legacy`, construite sur `f81c3d9`) |
| Arbre | Identique à l'arbre de la préparation (lignée de référence) |
| Ascendance | `1ec985f`, `4ffdb8a`, `a7983e7`, `03bce80`, `47bc6fe`, `6d30a51`, `40a3117`, `34e4a63` et `f81c3d9` sont tous ancêtres |
| Fast-forward depuis `origin/main` | Possible |
| Fichiers de `1ec985f` | **46/46** présents à l'identique (même blob) : au même chemin, dans `docs/legacy/oct31/`, ou rapatriés (ADR, T-029, fondateur, revue) |
| Fichiers de `40a3117` | 105/109 inchangés ; les 4 modifiés sont les mises à jour volontaires de la phase 1 |
| Empreintes cartographiques | 5/5 identiques |
| CI | Verte (run `43603309751`) |

## 2. Documents de la lignée du 31/10 et leur sort

- **Rapatriés au chemin canonique** (phase 1) : ADR 0000 à 0006, T-029, `founding-document-v0.1.md`, `design-review-v0.1.md`.
- **Conservés dans `docs/legacy/oct31/`** sur la prévisualisation :
  - les 31 fichiers absents de la lignée de référence, dont `docs/nations/nations.md` (source de D-027 à D-029), `docs/nations/regimes.md`, `docs/ai/*` (5), `docs/diplomacy/*` (4), `docs/military/*` (2), `docs/economy/economy-system.md`, `docs/gameplay/*` (2), `docs/technology/research-system.md`, `docs/intelligence/intelligence-system.md`, `docs/architecture/*` (3), `docs/development/*` (3), `CLAUDE.md`, `.env.example`, `scripts/check-infrastructure.sh`, `src/README.md`, `tests/README.md`, `assets/README.md`, `docs/README.md` ;
  - les versions de A des fichiers homonymes (`AGENTS.md`, `CHANGELOG.md`, `PROGRESS.md`, `README.md`, `.gitignore`, ADR-0005 initiale, index initial).
- **Non intégrés dans l'arbre, mais conservés sur leurs branches :** le prototype `cdd3ab1` (`archive/oct31-mvp-playable`), conformément à l'orientation du 14/11, et l'historique complet des deux lignées.

**Perte de contexte :** aucune perte de contenu. Il reste deux pertes de **navigation** :
- les liens internes des copies historiques visent leur emplacement d'origine. Correspondance : `docs/legacy/oct31/LINK_MAP.md` (lot 1), à étendre aux 31 copies lors de la reconstruction de la prévisualisation ;
- **aucun index** ne présentait l'ensemble. `docs/README.md` (lot 1) remplit ce rôle.

## 3. Corrections nécessaires avant exécution

1. **Reconstruire la prévisualisation** à partir de la pointe à jour : `c99051b` est construite sur `f81c3d9` et ne contient pas le lot 1. Méthode : script `tools/git/build_main_alignment.sh`, déterministe. Il copie les fichiers de `1ec985f` absents ou en conflit vers `docs/legacy/oct31/` selon la table de renommage, puis crée la jonction avec `git commit-tree`.
2. Étendre `LINK_MAP.md` aux 31 copies ajoutées.
3. Relancer tous les contrôles du §1.

## 4. Procédure sûre (après U2)

```bash
git fetch origin --prune
test "$(git rev-parse origin/main)" = 1ec985f1dcb060177d8ec9fe85955d6957a4537b
tools/git/build_main_alignment.sh <pointe-de-référence>      # reconstruit integrate/main-alignment-preview
tools/map/validate_all.sh --full && python3 tools/audit/link_check.py
J=$(git rev-parse integrate/main-alignment-preview)
git merge-base --is-ancestor origin/main "$J"
git push origin "$J":main                                     # fast-forward, jamais --force
```

## 5. Contrôles après la fusion

- `git ls-remote origin main` = `$J` ; toutes les autres références sont inchangées.
- CI verte sur `main` (workflow déclenché manuellement).
- `tools/map/validate_all.sh --full` et `tools/audit/link_check.py` sur un clone neuf.
- 46/46 fichiers de `1ec985f` retrouvés ; empreintes 5/5.
- Mise à jour d'`AGENTS.md` et de `CONTRIBUTING.md` (`main` devient la base) ; nouveau bundle de sauvegarde.
