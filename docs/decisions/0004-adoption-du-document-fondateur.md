# ADR-0004 — Adoption du document fondateur v0.1 comme source de conception

> **Statut :** Accepté
> **Date :** 2026-10-31
> **Auteur :** OpenCode
> **Décideur :** Propriétaire du projet (document remis le 2026-10-31)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [PROJECT.md](../../PROJECT.md) · [founding-document-v0.1.md](../founding-document-v0.1.md) · [design-review-v0.1.md](../design-review-v0.1.md) · [PROGRESS.md](../../PROGRESS.md)

---

## 1. Contexte

Le brief initial décrivait un jeu de stratégie et de diplomatie inspiré de webDiplomacy, sans cadre historique ni systèmes détaillés. Le 2026-10-31, le propriétaire a remis un **document fondateur v0.1** qui fixe un cadre beaucoup plus précis : Europe de 1914, sept grandes puissances, tours mensuels à résolution simultanée, diplomatie, IA autonomes, économie, recherche, renseignement, batailles tactiques, régimes et victoire.

Ce document n'est pas un cahier des charges final : il contient des éléments « à définir » et plusieurs tensions internes. Il doit néanmoins devenir la référence de conception, sous peine que les documents antérieurs continuent de décrire un autre jeu.

## 2. Problème à résoudre

Comment intégrer le document fondateur sans :

- écraser les documents de cadrage existants ;
- présenter des éléments encore ouverts comme validés ;
- faire croire que le cahier des charges est terminé ;
- perdre la trace des contradictions à arbitrer ?

## 3. Solutions envisagées

### Option A — Remplacer tous les documents existants par le document fondateur

- **Avantages :** cohérence apparente immédiate.
- **Inconvénients :** perte de l'historique de cadrage, suppression de questions utiles, confusion entre décision et intention.
- **Verdict :** rejetée.

### Option B — Conserver le document fondateur comme fichier isolé, sans l'intégrer

- **Avantages :** aucun risque de contradiction.
- **Inconvénients :** les documents de référence continuent de décrire un jeu différent ; les agents travailleraient sur des hypothèses périmées.
- **Verdict :** rejetée.

### Option C — Intégrer le document fondateur comme source d'autorité, avec traçabilité et revue critique

- **Avantages :** référence unique, décisions tracées dans `PROJECT.md`, tensions rendues visibles, documents thématiques alignés progressivement.
- **Inconvénients :** travail de révision important, coexistence temporaire de documents anciens et nouveaux.
- **Verdict :** retenue.

## 4. Solution retenue

1. Le document fondateur v0.1 est conservé **intégralement** dans `docs/founding-document-v0.1.md`, avec une empreinte SHA-256.
2. Ses décisions de cadrage sont transposées dans `PROJECT.md` sous les identifiants **D-001 à D-026**, avec étiquettes **[VALIDÉ]**.
3. Une **revue de conception** (`docs/design-review-v0.1.md`) consigne les tensions C-01 à C-18 et les points de vigilance V-01 à V-08. Elle ne tranche rien.
4. Les documents thématiques signalent désormais les décisions validées et les tensions qui les concernent. Ils restent des documents de cadrage tant que leur spécification n'est pas validée.
5. Le **cahier des charges détaillé** reste **[À DÉFINIR]** : son absence interdit l'implémentation des mécaniques définitives.

## 5. Justification

- Respecte l'autorité du propriétaire : le document est sa décision, pas une proposition d'agent.
- Respecte la traçabilité : chaque reprise est identifiable.
- Respecte la distinction entre décision, proposition et question ouverte.
- Permet aux agents de travailler sur la bonne vision sans inventer de mécaniques.
- Rend les contradictions visibles au lieu de les masquer.

## 6. Conséquences

### Positives

- Une référence de conception unique et datée.
- Les documents antérieurs ne sont plus la source de vérité.
- Les tensions critiques sont identifiées avant toute implémentation.
- Les agents disposent d'un cadre pour proposer des options sans les imposer.

### Négatives / coûts

- Révision importante des documents thématiques.
- Coexistence temporaire de contenus anciens et nouveaux.
- Risque de confusion si les étiquettes ne sont pas maintenues.
- Le document fondateur reste incomplet ; il ne dispense pas d'un cahier des charges.

### Impacts sur les documents et le code

- `PROJECT.md` passe en version 0.2.0.
- `docs/founding-document-v0.1.md` est versionné.
- `docs/design-review-v0.1.md` est créé.
- Les documents thématiques sont réorganisés et révisés.
- Aucun code de jeu n'est créé.

## 7. État

**Accepté** pour l'adoption du document comme source de conception. **Non accepté** comme validation du cahier des charges détaillé ni des mécaniques qui y restent « à définir ».

## 8. Suivi

- [x] Document fondateur conservé et empreinté
- [x] Décisions transposées dans `PROJECT.md`
- [x] Revue de conception créée
- [x] Index des ADR mis à jour
- [ ] Documents thématiques entièrement alignés (tâche T-031)
- [ ] Cahier des charges détaillé validé par le propriétaire

## 9. Références

- [Document fondateur v0.1](../founding-document-v0.1.md)
- [Revue de conception v0.1](../design-review-v0.1.md)
- [PROJECT.md § 20](../../PROJECT.md#20-gouvernance-décisions-et-questions-ouvertes)
- [AGENTS.md § 1](../../AGENTS.md#1-objet-et-principe-dautorité)
