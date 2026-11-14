# Audit de la documentation et organisation cible (partie 8)

- **Méthode :** inventaire des 98 fichiers Markdown de la prévisualisation et des 63 de la lignée de référence (`f81c3d9`) ; `tools/audit/link_check.py` ; lecture des documents d'état.
- **Aucun document supprimé.**

## 1. Constats

| Type | Documents | Traitement (lot 1) |
|---|---|---|
| **État périmé** | `docs/map/ATLAS_BUILD_STATUS.md` (« atlas non construit »), `data/world/map/README.md`, `docs/map/TECHNICAL_SPEC.md` §10 (« REGIS non importé »), `PROGRESS.md` (« hors Strumica »), `CHANGELOG.md` (sans la phase 1) | En-tête « obsolète » ou erratum ; `PROGRESS.md` et `CHANGELOG.md` mis à jour |
| **Rapports datés** (historiques, exacts à leur date) | `docs/map/audit/PROJECT_STATUS.md`, `CONTINUATION_PLAN.md`, `GLOBAL_AUDIT.md`, `INTEGRATION_CHECKLIST.md`, `GIT_RECOVERY_REPORT.md`, `GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md` | Bandeau « historique » sur les deux premiers ; les autres restent intacts |
| **Statut ambigu** | `docs/map/audit/ISSUES.json` (aucun champ de statut) | `docs/map/audit/ISSUES_STATUS.md` |
| **Liens non portables** | `docs/map/corrections/STRUMICA_FINAL_RESOLUTION.md` (6 liens `file://` et `conversation://`) | Note d'erratum en tête ; le rapport validé n'est pas réécrit |
| **Liens historiques** | 9 copies rapatriées (84 liens ; 129 avec les copies de la prévisualisation) | `docs/legacy/oct31/LINK_MAP.md` |
| **Redondances** | Domaines décrits deux fois : vues d'ensemble de B (`docs/*/OVERVIEW.md`) et documents de A (`docs/legacy/oct31/docs/*`, après l'alignement) | Ordre d'autorité indiqué dans `docs/README.md` : B fait référence, A est historique |
| **Informations présentes seulement dans d'anciennes branches** | Prototype (`cdd3ab1`), villes (`4dbf4f8`), audit thématique (`8a5d2bf`), notes sur les ressources (hors Git) | Recensées ; leur réintégration fait l'objet des tâches C6, C7 et C10 |
| **Décisions sans source ou ambiguës** | D-001 à D-030 (sans validation dans B) ; R-01 à R-14 | `03_REGISTRE_CONTRADICTIONS.md` |
| **Absentes du dossier de reprise** | Prototype jouable ; conditions de réutilisation des données sources (audit des licences remis au directeur) ; mois de départ non décidé ; réseau naval occidental absent | Livrables 1 à 4 |

## 2. Organisation documentaire cible

```text
README.md                  présentation, liens vers docs/README.md
AGENTS.md, CONTRIBUTING.md règles (à jour)
PROJECT.md                 document maître (v1.1)
PROGRESS.md, CHANGELOG.md  état et journal
docs/README.md             COMMENCER ICI : ordre de lecture, carte des documents, statuts
docs/decisions/            registre, ADR, dossiers d'arbitrage, rapatriement
docs/project/              audits, rapports de phase, plans (audit-2026-11/ = audit approfondi)
docs/map/                  spécification, audits (datés), corrections, décisions cartographiques à venir
docs/<domaine>/            vues d'ensemble de B (référence)
docs/legacy/oct31/         copies historiques de la lignée du 31/10 (non normatives)
tools/map/, tools/audit/   outils reproductibles, avec un README
```

**Règles proposées :**
- tout rapport porte une date et un statut (« en vigueur », « historique », « obsolète ») ;
- un document d'état ne se réécrit pas : on ajoute un bandeau ou un erratum daté ;
- `docs/README.md` est mis à jour à chaque lot.
