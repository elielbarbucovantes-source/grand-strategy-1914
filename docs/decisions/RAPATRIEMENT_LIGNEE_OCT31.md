# Rapatriement des documents de conception de la lignée du 31 octobre 2026

- **Date :** 14 novembre 2026 (phase 1, tâche 3)
- **Branche :** `consolidate/phase-1`
- **Nature :** copie **octet pour octet** de documents de la lignée Git A (racine `459375a`, dépôt d'origine `~/Projets/GrandStrategy`) vers la lignée B (cartographie validée).
- **Statut de ce rapport :** documentation de provenance. **Ne vaut décision sur aucun point.** Les contradictions sont signalées, pas résolues.

## 1. Règles appliquées

1. Aucun document rapatrié n'a été modifié : pas d'en-tête ajouté, pas de lien corrigé, pas de statut mis à jour. Leur provenance est consignée **ici**.
2. Le statut de chaque document est celui qu'il déclare lui-même. Rien n'a été promu : une proposition reste une proposition.
3. Quand deux versions concurrentes existent, la plus récente qui ne change pas le statut est copiée au chemin canonique. Les autres sont conservées dans `docs/legacy/oct31/`.

## 2. Topologie de la lignée A

```
459375a … ca0d4e2 (fiche maîtresse v0.1) … a2e0940 (document fondateur) … e20bf90
   └─ 1ec985f  origin/main — « entériner le nom Grand Strategy-1914 » (31/10 23:59)
        ├─ 2a341d1  archive/oct31-main-t029 — dossier T-029 (01/11 00:26)
        └─ 88e3b45 → cdd3ab1  archive/oct31-mvp-playable — MVP Python + ADR-0006 (01/11 01:14)
```

`2a341d1` et `cdd3ab1` sont deux branches sœurs : aucune ne contient l'autre.

## 3. Inventaire des documents rapatriés

Le SHA-256 indiqué est celui du fichier copié, identique à celui du blob d'origine.

| Chemin dans la lignée B | Commit source | Blob | SHA-256 (16 premiers) | Statut déclaré par le document |
|---|---|---|---|---|
| `docs/decisions/0000-template.md` | `2a341d1` | `96fd2bb` | `3a28e6f451f0ae5b` | Modèle (ne vaut pas décision) |
| `docs/decisions/0001-documentation-et-git-comme-socle.md` | `2a341d1` | `0eb97dd` | `175f676e0f0e6738` | Accepté |
| `docs/decisions/0002-interoperabilite-multi-agents.md` | `2a341d1` | `4c105a2` | `8816724900084eae` | Accepté |
| `docs/decisions/0003-report-du-choix-de-pile-technique.md` | `2a341d1` | `b1fa453` | `cf2eefb5dc0ab6f4` | Accepté |
| `docs/decisions/0004-adoption-du-document-fondateur.md` | `2a341d1` | `06a57aa` | `13ac05f9204c6c16` | Accepté |
| `docs/decisions/0005-integration-strategique-tactique.md` | `2a341d1` | `5556e53` | `1894de14c90e8a4d` | **Proposé — ne vaut pas décision** |
| `docs/decisions/0006-pile-technique-mvp.md` | `cdd3ab1` | `7e226d6` | `decdc8639e084da7` | accepté (délégation technique du propriétaire, 2026-10-31) |
| `docs/decisions/arbitrage-t029-temps-strategique-tactique.md` | `2a341d1` | `ace7f72` | `d410cdb6fbcb550c` | **Document de travail — ne vaut pas décision** |
| `docs/founding-document-v0.1.md` | `2a341d1` | `c5f6070` | `6de617ca12d9b902` | Document de cadrage initial du propriétaire, qui fait autorité sur les intentions |
| `docs/design-review-v0.1.md` | `2a341d1` | `14618ca` | `31cdeae4c4358e0e` | Cadrage, revue critique **non validée** ; gelée |
| `docs/legacy/oct31/PROJECT.md` | `2a341d1` | `4a3332e` | `ed3c8b5b7551abc0` | `PROJECT.md` de la lignée A, qui contient la **table D-001 à D-030** (§20.1) |
| `docs/legacy/oct31/decisions-README.2a341d1.md` | `2a341d1` | `4bfddc8` | `557394428c6cdd62` | Index ADR, version T-029 |
| `docs/legacy/oct31/decisions-README.cdd3ab1.md` | `cdd3ab1` | `86b2d01` | `c9f7264f89249f9d` | Index ADR, version MVP |

Vérification reproductible :

```bash
git show 2a341d1:docs/decisions/0005-integration-strategique-tactique.md | cmp - docs/decisions/0005-integration-strategique-tactique.md
```

La même commande s'applique à chaque ligne du tableau.

**Le document fondateur et la table D-xxx.** Le dossier de reprise parle du « document fondateur D-001 à D-026 ». Les décisions D-001 à D-026 sont issues de `docs/founding-document-v0.1.md`. L'ADR-0004 les a transposées dans le `PROJECT.md` de la lignée A, dont la table s'étend en réalité jusqu'à **D-030** :
- D-027 : douze caractéristiques notées de 1 à 10 ;
- D-028 : colonies simplifiées ;
- D-029 : ambitions initiales ;
- D-030 : nom du jeu.

Ce `PROJECT.md` est conservé dans `docs/legacy/oct31/`, car son nom entre en collision avec le `PROJECT.md` v1.1 de la lignée B, qui reste le document maître.

## 4. Versions concurrentes

| Document | Versions | Différence | Traitement |
|---|---|---|---|
| ADR-0005 | `4f820c5` (`1ec985f`, `cdd3ab1`) / `5556e53` (`2a341d1`) | `2a341d1` ajoute seulement des liens vers le dossier T-029. Statut identique : « Proposé ». | `5556e53` copiée au chemin canonique |
| `docs/decisions/README.md` | `1429119` (`1ec985f`) / `4bfddc8` (`2a341d1`) / `86b2d01` (`cdd3ab1`) / `9a441f0` (`ca0d4e2`) | Les ajouts sont **compatibles** : `2a341d1` ajoute une section « dossiers d'arbitrage » (T-029), `cdd3ab1` ajoute la ligne ADR-0006 et passe l'index à « 6 ADR (5 acceptés) ». Aucune version ne contient les deux. | Les deux versions récentes sont conservées dans `docs/legacy/oct31/`. Le nouvel index `docs/decisions/README.md` est un document **nouveau**, qui recense les statuts déclarés. |
| Autres documents | Une seule version par blob dans toute la lignée A | — | Copie directe |

## 5. Liens internes non résolus

Les documents rapatriés contiennent des liens relatifs vers des documents de la lignée A qui n'ont **pas** été rapatriés (hors périmètre de la tâche 3) :

- `docs/gameplay/rules.md`
- `docs/architecture/overview.md`
- `docs/architecture/technical-decisions.md`
- `docs/military/tactical-battles.md`
- `docs/military/strategic-warfare.md`
- `docs/development/contribution-guide.md`

Ils restent consultables avec `git show 2a341d1:<chemin>`.

Les liens vers `PROJECT.md`, `PROGRESS.md`, `AGENTS.md` et `CLAUDE.md` se résolvent désormais vers les fichiers **de la lignée B**, dont le contenu diffère de celui que l'auteur visait. La version visée est `docs/legacy/oct31/PROJECT.md` ou `git show 2a341d1:<fichier>`. Les liens n'ont pas été corrigés, car cela reviendrait à modifier les documents.

## 6. Contradictions et tensions documentaires (à arbitrer, NON résolues)

| # | Lignée A | Lignée B (`PROJECT.md` v1.1, registre) | Nature |
|---|---|---|---|
| R-01 | **ADR-0006 « accepté »** : pile Python 3.12 (bibliothèque standard) avec interface web pour le MVP jouable | `PROJECT.md` §18–19 : gel du gameplay ; les consignes demandant une partie jouable sont remplacées. `TECHNICAL_ARCHITECTURE.md` : Godot 4.7.2 en **proposition**. | Conflit de pile technique et de gouvernance. Orientation du directeur (14/11) : Godot reste le candidat privilégié, la décision est différée et le prototype est une référence d'étude. L'ADR-0006 garde son statut historique. |
| R-02 | **ADR-0003 « accepté »** : report du choix de pile | Rendue caduque de fait par l'ADR-0006 (A) puis par la proposition Godot (B), mais jamais marquée « remplacé » | Statut à mettre à jour lors de la décision sur le moteur, par une nouvelle ADR (une ADR acceptée est immuable). |
| R-03 | D-018 : chaque territoire produit **trois ressources** en quantités faible, moyenne ou forte (principe inspiré de Catan), liste à définir | §10 : trois ressources **nationales** (nourriture, matières premières, richesse) et stock centralisé ; dossier §6.3 : potentiel exploitable sur trois niveaux | Les deux sont peut-être compatibles, mais la sémantique de « trois ressources » diffère. À clarifier (ECO-01). |
| R-04 | D-025 : trois voies de victoire, **territoriale, diplomatique, économique et sociale** | §17 : territoriale (90 %), **socio-économique**, **collective** (traité de paix et d'unité) | La voie « diplomatique » de A correspond-elle à la voie « collective » de B ? Rien ne le précise. |
| R-05 | D-027 (marquée décision du propriétaire) : douze caractéristiques **notées de 1 à 10**, relatives aux sept puissances | NAT-01 : formules et **échelles À DÉFINIR** ; NAT-04 : notes d'équilibre provisoires, non officielles | Conflit de statut sur l'échelle de 1 à 10. |
| R-06 | D-028 : l'Empire allemand est considéré **sans empire colonial exploitable** (simplification volontaire) | B n'en dit rien. Historiquement, l'Allemagne possédait des colonies en 1914. | Absent de B. Simplification délibérée à reconfirmer face au pilier de réalisme. |
| R-07 | D-010 : relations limitées à **amitié / neutralité / hostilité** | DIP-01 : échelles À DÉFINIR | Décision de A absente de B. |
| R-08 | D-014 : 30 minutes **maximum** (décision) | MIL-06 : « 30 min maximum **envisagées** », À DÉFINIR | Le statut est plus faible dans B. |
| R-09 | D-023 : une interception donne une information exacte ; pas de faux messages | Non repris explicitement dans B | Décision de A absente de B. |
| R-10 | Terminologie « **province** » (A et parties de B) | Atlas B : « **région** » (MAP-OPEN-14) | Déjà ouvert dans B. |
| R-11 | D-030 : le répertoire Git reste `GrandStrategy` | Le répertoire de travail de référence est désormais `…/grand-strategy-1914` (dossier Codex) | Information obsolète, sans effet de conception. |
| R-12 | Design review v0.1 : questions C-01 à C-18 | Registre B : identifiants MAP-OPEN, NAT, TURN, ECO, MIL, DIP | Deux systèmes d'identifiants, sans table de concordance. |

**Erratum du 14/11/2026 (audit approfondi) :**
- **R-06 est une contradiction apparente.** `docs/nations/PLAYABLE_POWERS.md:44` (lignée de référence) reprend expressément D-028 : « Simplification de conception validée : l'Allemagne est traitée comme ne disposant pas d'un empire colonial exploitable… ». Le classement « absent de B » ci-dessus est erroné.
- **R-07 et R-09 sont des lacunes** de la lignée de référence (règles « À DÉFINIR »), non des contradictions frontales.
- **Deux contradictions nouvelles :** **R-13**, mois de départ de la campagne (fondateur « 1914 », atlas au 1/1/1914, prototype en juin) ; **R-14**, piliers (fondateur §2 : diplomatie et militaire ; lignée de référence : trois piliers).
- Les fiches complètes et le tableau D-001 à D-030 sont dans `docs/project/audit-2026-11/03_REGISTRE_CONTRADICTIONS.md`.

**Proposition, sans décision :** le directeur pourrait indiquer pour chaque D-001 à D-030 si elle est « reprise telle quelle », « remplacée par… » ou « à rediscuter ». Une table de concordance C-xx ↔ identifiants du registre B serait ensuite établie (travail technique).

## 7. Ce qui n'a pas été fait volontairement

- Aucun statut modifié : T-029 reste un document de travail, ADR-0005 reste proposée, ADR-0006 reste « acceptée (délégation) ».
- Aucune intégration du contenu de A dans le `PROJECT.md` de B.
- Aucun rapatriement des documents de domaine de A (IA, diplomatie, militaire…). Ils restent accessibles dans `2a341d1`, et leur rapatriement peut faire l'objet d'une tâche distincte.
- Aucun code du prototype n'a été copié.
