# ADR-0003 — Report du choix de pile technique

> **Statut :** Accepté
> **Date :** 2026-10-31
> **Auteur :** OpenCode
> **Décideur :** Propriétaire du projet (contrainte explicite du brief)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [technical-decisions.md](../architecture/technical-decisions.md) · [PROJECT.md](../../PROJECT.md) · [docs/gameplay/rules.md](../gameplay/rules.md)

---

## 1. Contexte

Le projet est au stade du cadrage. Le game design n'est pas défini : ni le périmètre du MVP, ni le rythme de partie, ni le niveau de simulation militaire, ni l'existence d'une économie, ni la relation exacte avec Diplomacy.

Le brief impose explicitement de ne pas choisir de framework ou de moteur graphique sans étude préalable.

Un choix prématuré de langage, de moteur ou de base de données créerait un engagement coûteux avant même de savoir ce que le jeu doit faire.

## 2. Problème à résoudre

Quand et comment choisir la pile technique, sans bloquer inutilement le projet et sans engager une décision irréversible sur la base d'hypothèses non validées ?

## 3. Solutions envisagées

### Option A — Choisir immédiatement une pile connue

- **Avantages :** démarrage rapide, moins d'incertitude.
- **Inconvénients :** risque d'inadéquation avec le game design, coût de changement élevé, décision non justifiée, contraire au brief.
- **Verdict :** rejetée.

### Option B — Repousser tout choix jusqu'à ce que le game design soit totalement défini

- **Avantages :** décision parfaitement informée.
- **Inconvénients :** risque de blocage prolongé, impossibilité de prototyper, retard excessif.
- **Verdict :** excessive.

### Option C — Repousser le choix structurant, mais autoriser des prototypes limités et documentés

- **Avantages :** décisions informées par l'expérimentation, sans engagement prématuré ; permet de tester des hypothèses (résolution, carte, IA).
- **Inconvénients :** nécessite de cadrer les prototypes et d'accepter du code jetable.
- **Verdict :** retenue, avec conditions.

## 4. Solution retenue

1. **Aucun choix définitif** de langage, moteur, framework, base de données ou hébergement avant :
   - validation du périmètre du MVP (Q-002) ;
   - décision sur la nature du jeu (Q-003) et le rythme (Q-005) ;
   - étude comparative documentée.
2. Toute sélection fait l'objet d'un **ADR** avec options, critères, coûts, risques et conséquences.
3. Des **spikes** (prototypes jetables) sont autorisés, à condition :
   - d'être isolés dans une branche `spike/` ;
   - d'être documentés (objectif, résultats, limites) ;
   - de ne pas être fusionnés dans la branche principale sans décision ;
   - de ne pas imposer de dépendance au projet.
4. Le registre [technical-decisions.md](../architecture/technical-decisions.md) suit l'état des choix.

## 5. Justification

- Respecte la contrainte du propriétaire (D-005).
- Évite un engagement coûteux sur des hypothèses.
- Permet néanmoins d'avancer par l'expérimentation.
- Chaque décision future sera traçable et argumentée.

## 6. Conséquences

### Positives

- Pas de dette technique imposée par un choix prématuré.
- Les décisions seront mieux informées.
- Les prototypes restent exploratoires.

### Négatives / coûts

- Le projet ne produit pas encore de code exécutable.
- Le démarrage effectif est retardé jusqu'à la validation du périmètre.
- Les agents doivent résister à la tentation de coder.

### Risques

| Risque | Mitigation |
|---|---|
| Le cadrage s'éternise | Fixer une échéance de décision pour Q-002/Q-003/Q-005 |
| Les prototypes deviennent du code de production | Branche `spike/`, revue, non-fusion |
| Le choix est fait implicitement par une dépendance | Revue des dépendances, ADR obligatoire |
| Le propriétaire attend un choix que les agents ne peuvent pas faire | Escalade explicite |

### Impacts

- Aucun code de jeu tant que les décisions préalables ne sont pas prises.
- `docs/architecture/technical-decisions.md` est le point de suivi.
- Les documents de gameplay doivent être suffisamment précis avant l'étude de pile.

## 7. État

**Accepté.** Contrainte du propriétaire, formalisée par OpenCode.

## 8. Suivi

- [x] Registre créé
- [x] Documents liés mis à jour
- [x] PROGRESS.md mis à jour
- [ ] Échéance de décision fixée par le propriétaire (recommandé)
- [ ] ADR de pile technique créé lorsque les prérequis seront remplis

## 9. Références

- Brief du propriétaire, section 9.
- [technical-decisions.md](../architecture/technical-decisions.md)
- [PROJECT.md § 12](../../PROJECT.md#12-questions-encore-ouvertes)
