# Correspondance des liens des documents historiques (lignée du 31/10)

Les documents copiés octet pour octet depuis la lignée du 31/10 conservent leurs liens relatifs d'origine. Pour respecter la copie à l'identique, ces liens **ne sont pas corrigés**. Utilisez cette table pour retrouver la cible. Liste complète et à jour des liens cassés : `python3 tools/audit/link_check.py --include-legacy`.

## Règle générale

Un lien d'un document historique vise un fichier de l'arborescence de `2a341d1` (ou de `cdd3ab1` pour l'ADR-0006). Le contenu visé est toujours consultable par :

```bash
git show 2a341d1:<chemin-d-origine>
```

Après l'alignement de `main` (`docs/project/MAIN_ALIGNMENT_PLAN.md`), ces fichiers seront aussi présents sous `docs/legacy/oct31/<chemin-d-origine>`.

## Cibles fréquentes

| Cible du lien (chemin d'origine) | Où la trouver aujourd'hui | Après l'alignement de `main` |
|---|---|---|
| `PROJECT.md` (lignée A) | `docs/legacy/oct31/PROJECT.md`. Attention : `PROJECT.md` à la racine est la v1.1, différente | idem |
| `PROGRESS.md`, `AGENTS.md`, `CHANGELOG.md`, `README.md` (lignée A) | `git show 2a341d1:<fichier>` ; les fichiers homonymes à la racine sont ceux de la lignée de référence | `docs/legacy/oct31/<fichier>` (`README-racine-oct31.md` pour le README) |
| `CLAUDE.md` | `git show 2a341d1:CLAUDE.md` | `docs/legacy/oct31/CLAUDE.md` |
| `DECISIONS_PENDING.md` (racine, cité par l'ADR-0006) | `git show cdd3ab1:DECISIONS_PENDING.md` (registre du MVP) ; à ne pas confondre avec `docs/decisions/DECISIONS_PENDING.md` | inchangé (fichier du prototype, non intégré) |
| `docs/architecture/overview.md`, `technical-decisions.md`, `data-model.md` | `git show 2a341d1:docs/architecture/<fichier>` | `docs/legacy/oct31/docs/architecture/` |
| `docs/gameplay/rules.md`, `map-system.md` | `git show 2a341d1:docs/gameplay/<fichier>` | `docs/legacy/oct31/docs/gameplay/` |
| `docs/military/strategic-warfare.md`, `tactical-battles.md` | `git show 2a341d1:docs/military/<fichier>` | `docs/legacy/oct31/docs/military/` |
| `docs/ai/*`, `docs/diplomacy/*`, `docs/economy/economy-system.md`, `docs/intelligence/intelligence-system.md`, `docs/technology/research-system.md`, `docs/nations/nations.md`, `docs/nations/regimes.md` | `git show 2a341d1:<chemin>` | `docs/legacy/oct31/<chemin>` |
| `docs/development/contribution-guide.md`, `coding-standards.md`, `testing-strategy.md` | `git show 2a341d1:docs/development/<fichier>` | `docs/legacy/oct31/docs/development/` |
| Liens internes des index ADR historiques (`decisions-README.*.md`) vers `000x-*.md`, `../founding-document-v0.1.md`… | `docs/decisions/000x-*.md`, `docs/founding-document-v0.1.md`, `docs/design-review-v0.1.md` (rapatriés) | idem |

## Documents concernés (état au 14/11/2026)

`docs/decisions/0002`, `0003`, `0005`, `0006`, `arbitrage-t029-temps-strategique-tactique.md`, `docs/design-review-v0.1.md`, `docs/legacy/oct31/PROJECT.md`, `docs/legacy/oct31/decisions-README.2a341d1.md`, `docs/legacy/oct31/decisions-README.cdd3ab1.md` : 9 fichiers, 84 liens.
