# Documentation — COMMENCER ICI

Index de navigation de Grand Strategy-1914 (mis à jour le 14/11/2026). Il ne crée aucune décision. Le statut qui fait foi est celui de chaque document.

## 1. Ordre de lecture pour un nouvel agent

1. [`../AGENTS.md`](../AGENTS.md) : règles impératives (gel du gameplay, statuts, Git, validation).
2. [`../PROJECT.md`](../PROJECT.md) : document maître v1.1 (référence de conception).
3. [`../PROGRESS.md`](../PROGRESS.md) : état courant.
4. [`decisions/README.md`](decisions/README.md) et [`decisions/DECISIONS_PENDING.md`](decisions/DECISIONS_PENDING.md) : décisions validées, ouvertes, ADR, T-029.
5. [`project/audit-2026-11/01_ETAT_GENERAL.md`](project/audit-2026-11/01_ETAT_GENERAL.md) : état vérifié du projet.
6. [`project/audit-2026-11/QUESTIONS_DIRECTEUR.md`](project/audit-2026-11/QUESTIONS_DIRECTEUR.md) : décisions en attente.
7. [`../CONTRIBUTING.md`](../CONTRIBUTING.md) et [`../tools/map/README.md`](../tools/map/README.md) : procédures et validation.

## 2. Carte des documents

| Domaine | Documents en vigueur | Historiques ou obsolètes (non normatifs) |
|---|---|---|
| Conception générale | `../PROJECT.md` (v1.1), `founding-document-v0.1.md` (source de D-001 à D-026) | `legacy/oct31/PROJECT.md` (table D-001 à D-030), `design-review-v0.1.md` (non validée) |
| Décisions | `decisions/DECISIONS_PENDING.md`, `decisions/0000…0006`, `decisions/arbitrage-t029-…` (document de travail) | `legacy/oct31/decisions-README.*.md` |
| Contradictions entre lignées | `project/audit-2026-11/03_REGISTRE_CONTRADICTIONS.md`, `decisions/RAPATRIEMENT_LIGNEE_OCT31.md` | — |
| Carte | `map/TECHNICAL_SPEC.md` (69 MAP-DEC), `map/audit/FINAL_GEOMETRY_AND_TOPOLOGY_AUDIT.md` (référence), `map/audit/ISSUES_STATUS.md`, `project/audit-2026-11/04_PLAN_CARTOGRAPHIQUE.md` | `map/ATLAS_BUILD_STATUS.md` (obsolète), `map/audit/PROJECT_STATUS.md`, `CONTINUATION_PLAN.md`, `GLOBAL_AUDIT.md`, `INTEGRATION_CHECKLIST.md`, `GIT_RECOVERY_REPORT.md`, `GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md` (datés) |
| Domaines de jeu | `ai/`, `diplomacy/`, `economy/`, `gameplay/`, `intelligence/`, `military/`, `nations/`, `technology/` (vues d'ensemble de la lignée de référence) | Documents détaillés de la lignée du 31/10 : `git show 2a341d1:docs/<domaine>/…` (copiés dans `legacy/oct31/` après l'alignement de `main`) |
| Architecture et moteur | `architecture/TECHNICAL_ARCHITECTURE.md` (proposition), `project/audit-2026-11/05_COMPARAISON_TECHNOLOGIQUE.md`, `project/PYTHON_PROTOTYPE_INVENTORY.md` | ADR-0006 (historique) |
| Projet et Git | `project/PROJECT_HANDOVER_AUDIT.md`, `project/PHASE_1_CONSOLIDATION_REPORT.md`, `project/MAIN_ALIGNMENT_PLAN.md`, `project/audit-2026-11/` (audit approfondi), `project/OBSOLETE_WORKSPACES.md` | — |

## 3. Règles documentaires

- Un document d'état ou un rapport daté **ne se réécrit pas**. On ajoute un bandeau « obsolète » ou « historique », ou un erratum daté.
- Les copies de la lignée du 31/10 sont **octet pour octet**. Leurs liens visent l'arborescence d'origine : voir [`legacy/oct31/LINK_MAP.md`](legacy/oct31/LINK_MAP.md).
- Une proposition reste une proposition tant que le directeur ne l'a pas validée.
- Vérifier les liens : `python3 tools/audit/link_check.py`.
