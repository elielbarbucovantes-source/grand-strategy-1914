# Système militaire

> **Statut :** Cadrage antérieur — fiche maîtresse non intégrée, non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [rules.md](rules.md) · [map-system.md](map-system.md) · [economy-system.md](economy-system.md) · [diplomacy/alliances.md](../diplomacy/alliances.md)

---

> **Note de cohérence (2026-10-31) —** Ce document a été rédigé avant la fiche maîtresse (PROJECT.md v0.2.0). Sont désormais tranchés : les fronts statiques se résolvent sur la carte stratégique, une offensive qui rencontre des armées déclenche une bataille tactique indépendante (30 minutes maximum, effectifs proportionnels), l'occupation automatique de la province par le vainqueur, les pertes définitives, et l'exclusion du moral et des généraux. Voir [PROJECT.md](../../PROJECT.md) § 8. Révision suivie par la tâche **T-031**.

## 1. Objet

Décrire les questions à résoudre pour le système militaire : unités, mouvements, combats, soutien, attrition, supply et interactions avec la diplomatie.

**Aucune mécanique n'est validée.** Les éléments ci-dessous sont des options ou des propositions.

## 2. Périmètre à définir

Le système militaire peut aller de la reprise fidèle des règles de Diplomacy (unités simples, pas de combat probabiliste) à un système de guerre beaucoup plus riche (effectifs, fronts, attrition, logistique). Le choix dépend de Q-002 (MVP) et Q-003 (fidélité à Diplomacy).

**[À DÉFINIR]** Le niveau de simulation visé :

- **Option A** — Armées abstraites, une unité par territoire, résolution déterministe (proche de Diplomacy).
- **Option B** — Unités avec effectifs et combat résolu par règles ou probabilités.
- **Option C** — Simulation détaillée avec ravitaillement, moral, terrain, saisons.

Chaque option a un coût de conception et de test très différent.

## 3. Unités (proposition)

| Attribut | Description | Statut |
|---|---|---|
| Type | Armée terrestre, flotte, autre | Proposition |
| Propriétaire | Puissance | Proposition |
| Position | Territoire | Proposition |
| Effectif | Nombre d'hommes ou puissance | À définir |
| État | Active, défaite, en retraite | Proposition |
| Moral / expérience | Bonus ou malus | À définir |

**[À DÉFINIR]** Une unité par territoire ou plusieurs ? Peut-on empiler ? Comment représenter une flotte côtière ?

## 4. Mouvement

**[À DÉFINIR]**

- mouvement simultané ou séquentiel ?
- vitesse, distance, terrain ?
- zones de contrôle ?
- interception ?
- mouvement naval et transports ?

**[VALIDÉ — contrainte]** Toute résolution doit être déterministe et reproductible.

## 5. Combat

**[À DÉFINIR]** Options :

- résolution déterministe par comparaison de force et de soutien ;
- combat probabiliste avec graine enregistrée ;
- combat en plusieurs rounds ;
- usure / attrition automatique.

Questions : que se passe-t-il en cas d'égalité ? Les unités peuvent-elles être détruites sans combat ? Comment éviter les boucles infinies ?

## 6. Soutien

**[PROPOSITION]** Le soutien permet à une unité d'en renforcer une autre. Il faut définir :

- qui peut soutenir qui ;
- soutien défensif / offensif ;
- coupe du soutien ;
- soutien de soutien ;
- visibilité du soutien.

## 7. Retraite, défaite et reconstruction

**[À DÉFINIR]**

- quand une unité doit-elle retraiter ?
- que se passe-t-il si aucun territoire de retraite n'est disponible ?
- peut-on reconstruire une unité détruite ?
- où et à quel coût ?
- que deviennent les unités d'une puissance éliminée ?

## 8. Ravitaillement et attrition

**[À DÉFINIR — optionnel]** Le ravitaillement n'est peut-être pas nécessaire si le jeu reste proche de Diplomacy. S'il existe, il faut définir :

- sources de ravitaillement ;
- portée ;
- effets du manque ;
- interaction avec la carte et l'économie.

## 9. Renseignement et fog of war

**[À DÉFINIR — Q-013]** Quelles informations militaires sont visibles ?

- positions de toutes les unités ?
- effectifs ?
- intentions ?
- mouvements en cours ?
- résultats des combats ?

Toute asymétrie d'information doit être appliquée de façon identique aux humains et aux IA.

## 10. Interaction avec la diplomatie

**[À DÉFINIR]** Les traités peuvent-ils :

- interdire un mouvement dans une zone ?
- créer une zone démilitarisée ?
- imposer un cessez-le-feu ?
- déclencher une intervention automatique ?

**[À DÉFINIR — Q-016]** Un traité est-il appliqué par le moteur ou seulement par la confiance et la réputation ?

## 11. Équilibrage

**[À DÉFINIR]**

- les puissances doivent-elles être symétriques ?
- comment corriger un déséquilibre sans mécaniques arbitraires ?
- comment tester l'équilibre ? (simulations, statistiques)
- les IA doivent-elles être équilibrées entre elles, ou peut-on avoir des niveaux de difficulté ?

## 12. Questions ouvertes

| ID | Question |
|---|---|
| M-001 | Quel niveau de simulation (A, B ou C) ? |
| M-002 | Une ou plusieurs unités par territoire ? |
| M-003 | Combat déterministe ou probabiliste ? |
| M-004 | Le soutien existe-t-il ? Sous quelle forme ? |
| M-005 | Y a-t-il du ravitaillement ? |
| M-006 | Comment gérer les retraites ? |
| M-007 | Quelles informations sont cachées ? |
| M-008 | Les traités ont-ils un effet mécanique ? |
| M-009 | Comment équilibrer les puissances ? |
| M-010 | Comment tester le système militaire ? |

## 13. Dépendances

- [rules.md](rules.md) : socle des ordres et de la résolution.
- [map-system.md](map-system.md) : territoires et adjacences.
- [economy-system.md](economy-system.md) : coûts et production, si économie.
- [diplomacy/treaties.md](../diplomacy/treaties.md) : engagements militaires.
- [development/testing-strategy.md](../development/testing-strategy.md) : tests de résolution.

## 14. Critères de passage à « Spécifié »

- [ ] Niveau de simulation choisi et validé.
- [ ] Types d'unités et attributs définis.
- [ ] Règles de mouvement et de combat décrites, cas limites inclus.
- [ ] Règles de retraite et de reconstruction définies.
- [ ] Interactions avec la diplomatie définies.
- [ ] Jeux de tests de référence identifiés.
- [ ] Validation du propriétaire.
