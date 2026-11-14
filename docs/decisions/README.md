# Décisions — index

- **Statut :** index de navigation (14/11/2026). **Il ne crée, ne modifie et ne valide aucune décision.**
- **Règle :** le statut faisant foi est celui déclaré dans chaque document.
- **Format des ADR :** voir `0000-template.md`. Une ADR acceptée est immuable : on la remplace par une nouvelle ADR.

## 1. Registres de conception

| Document | Contenu | Statut |
|---|---|---|
| [`../../PROJECT.md`](../../PROJECT.md) (v1.1) | Document maître de la lignée de référence. Gel du gameplay (§18). | Référence en vigueur |
| [`DECISIONS_PENDING.md`](DECISIONS_PENDING.md) | MAP-DEC-01 à 69 **VALIDÉES** (2026-11-01) ; MAP-OPEN, NAT, TURN, ECO, MIL, DIP… ouvertes | Registre en vigueur |
| [`../map/TECHNICAL_SPEC.md`](../map/TECHNICAL_SPEC.md) | Texte individuel des 69 décisions cartographiques | Voir le registre |
| [`../founding-document-v0.1.md`](../founding-document-v0.1.md) | Document fondateur du propriétaire (source de D-001 à D-026) | Cadrage initial du propriétaire |
| [`../legacy/oct31/PROJECT.md`](../legacy/oct31/PROJECT.md) | `PROJECT.md` de la lignée du 31/10 : table **D-001 à D-030** (§20.1) | Historique, à concilier (voir `RAPATRIEMENT_LIGNEE_OCT31.md` §6) |
| [`../design-review-v0.1.md`](../design-review-v0.1.md) | Revue critique, questions C-01 à C-18 | Non validée, gelée |

## 2. ADR

| N° | Titre | Statut déclaré | Origine |
|---|---|---|---|
| [0000](0000-template.md) | Modèle | Modèle | `2a341d1` |
| [0001](0001-documentation-et-git-comme-socle.md) | Documentation et Git comme socle | Accepté | `2a341d1` |
| [0002](0002-interoperabilite-multi-agents.md) | Interopérabilité multi-agents | Accepté | `2a341d1` |
| [0003](0003-report-du-choix-de-pile-technique.md) | Report du choix de pile technique | Accepté (caduc de fait, non remplacé : voir R-02) | `2a341d1` |
| [0004](0004-adoption-du-document-fondateur.md) | Adoption du document fondateur | Accepté | `2a341d1` |
| [0005](0005-integration-strategique-tactique.md) | Intégration stratégique/tactique | **Proposé — ne vaut pas décision** | `2a341d1` |
| [0006](0006-pile-technique-mvp.md) | Pile technique du premier MVP jouable (Python) | Accepté (délégation, 2026-10-31). **Historique** : prototype gelé comme référence d'étude ; moteur définitif non décidé (orientation du 14/11/2026). | `cdd3ab1` |

Le prochain numéro libre est **0007**.

## 3. Dossiers d'arbitrage (non-ADR, ne valent jamais décision)

| Document | Objet | Statut |
|---|---|---|
| [arbitrage-t029-temps-strategique-tactique.md](arbitrage-t029-temps-strategique-tactique.md) | T-029 : articulation entre temps stratégique et tactique. Options D1 à D5 ; package recommandé « S1 ». | **Document de travail. Les cinq décisions restent OUVERTES. Le package S1 n'est PAS approuvé** (confirmé par le directeur le 14/11/2026). |

## 4. Provenance

Les documents des sections 1 à 3 qui viennent de la lignée du 31 octobre sont des copies **octet pour octet**. Leur provenance, leurs versions concurrentes, les liens non résolus et les contradictions avec la lignée de référence sont décrits dans [`RAPATRIEMENT_LIGNEE_OCT31.md`](RAPATRIEMENT_LIGNEE_OCT31.md).
