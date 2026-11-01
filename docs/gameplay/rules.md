# Règles du jeu

> **Statut :** MVP jouable livré (boucle mensuelle) ; règles détaillées non validées
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 5, § 13, § 20.1 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 5, § 13
> **Documents liés :** [map-system.md](map-system.md) · [military/strategic-warfare.md](../military/strategic-warfare.md) · [military/tactical-battles.md](../military/tactical-battles.md) · [economy/economy-system.md](../economy/economy-system.md) · [technology/research-system.md](../technology/research-system.md) · [diplomacy/treaties.md](../diplomacy/treaties.md) · [architecture/overview.md](../architecture/overview.md) · [design-review-v0.1.md](../design-review-v0.1.md)

---

## 1. Objet

Poser le cadre des règles de base : boucle de jeu, phases, types d'ordres, résolution, conditions de fin.

Ce document **reprend le cadre validé par la fiche maîtresse** et signale ce qui reste à définir. Il ne remplace ni PROJECT.md ni le futur cahier des charges détaillé.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Cadre historique | Europe de 1914 ; histoire alternative crédible. | D-004, PROJECT.md § 3 et § 14 |
| Puissances jouables | Sept grandes puissances ; les autres pays sont des entités indépendantes non jouables en v1. | D-005, § 3.2 |
| Unité de temps | **Un tour = un mois**. | D-006, § 5.1 |
| Résolution | Les ordres sont préparés pendant une phase commune puis **résolus simultanément pour le monde entier**. | D-006, § 5.2 |
| Piliers | Diplomatie et stratégie militaire. | D-007, § 2 |
| Information | Les nations ne sont pas omniscientes ; communications confidentielles par défaut ; interception possible. | D-008, D-011, D-023 |
| Victoire | Trois voies : territoriale, diplomatique, économique et sociale. | D-025, § 13 |
| Élimination | Un pays entièrement conquis élimine son joueur. | § 13.1 |

**Conséquence :** les hypothèses antérieures de ce document (temps réel global, rythme non défini, reprise fidèle de Diplomacy, victoire unique par conquête) sont **historiques** et ne font plus autorité.

## 3. Boucle de jeu proposée

**[PROPOSITION — non validée]** La séquence suivante traduit le cadre validé sans trancher les tensions C-01, C-04 et C-16 :

1. **Ouverture du tour** : le monde entre dans le mois `M`.
2. **Phase de préparation** : chaque nation consulte ses rapports, négocie, planifie et saisit ses ordres.
3. **Verrouillage** : les ordres sont figés à une échéance définie par le mode de partie.
4. **Résolution simultanée** : le noyau résout l'ensemble des ordres du monde avec une graine et une version de règles identiques.
5. **Batailles tactiques** : les offensives qui rencontrent des armées ouvrent des batailles indépendantes (voir [tactical-battles.md](../military/tactical-battles.md)).
6. **Application des résultats** : conquêtes, pertes, production, recherche, effets diplomatiques.
7. **Rapports** : chaque nation reçoit son état mis à jour et ses rapports de renseignement.
8. **Tour suivant** : le mois `M+1`.

**[À DÉFINIR — C-01, C-16]** La position exacte des batailles tactiques dans cette séquence, le sort des ordres passés après le verrouillage et l'effet d'un traité signé pendant la résolution ne sont pas tranchés. Voir [ADR-0005](../decisions/0005-integration-strategique-tactique.md), à l'état `proposé`.

## 4. Types d'ordres envisagés

**[PROPOSITION]** Les ordres devraient couvrir au moins :

| Domaine | Exemples d'ordres | Statut |
|---|---|---|
| Militaire | déplacer une formation, tenir un front, lancer une offensive, construire une fortification. | À définir |
| Économie | affecter un budget, construire une usine, mobiliser l'industrie, commercer. | À définir |
| Recherche | choisir une technologie, financer une branche, tenter une recherche en avance. | À définir |
| Renseignement | financer une interception, orienter une mission, demander un rapport. | À définir |
| Diplomatie | envoyer un message, proposer un accord, rompre un accord, déclarer un état relationnel. | À définir |
| Politique intérieure | réforme, changement de régime (si conditions réunies). | À définir |

**[À DÉFINIR]** Le format exact, la validation, les ordres conditionnels et les ordres par défaut en cas d'absence du joueur.

## 5. Résolution simultanée

**[VALIDÉ — contrainte]** La résolution doit être déterministe et reproductible : mêmes ordres + même graine + même version de règles ⇒ même résultat.

**[VALIDÉ — intention]** Le système doit éviter qu'une nation puisse systématiquement agir après avoir observé les décisions des autres pendant le même tour.

**[À DÉFINIR]** Les modalités exactes de résolution des conflits entre ordres simultanés : priorités, égalités, ordre interne, effets des annulations, cas des mouvements contradictoires.

**[PROPOSITION]** Un journal d'événements append-only enregistre les ordres et les résultats ; il sert aux tests, au replay et à l'audit des décisions des IA.

## 6. Conditions de fin de partie

### 6.1 Élimination

**[VALIDÉ]** Lorsqu'un pays est entièrement conquis, son joueur est éliminé.

**[À DÉFINIR — C-08]** Sort des joueurs éliminés : spectateur, retour possible, fin de partie anticipée.

### 6.2 Victoires

**[VALIDÉ]** Trois voies coexistent :

1. **Victoire territoriale** : conquérir l'Europe.
2. **Victoire diplomatique** : dominer politiquement le continent par les alliances, l'influence et les relations internationales.
3. **Victoire économique et sociale** : atteindre un niveau de vie exceptionnellement élevé par rapport aux autres nations.

**[À DÉFINIR — C-07, C-08]** Seuils, durée, indicateurs, victoire partagée, match nul, date de fin et retournement d'alliance. Aucun agent ne doit inventer ces seuils. Voir [design-review-v0.1.md § C-07 et C-08](../design-review-v0.1.md).

## 7. Visibilité et information

**[VALIDÉ]** Les nations ne sont pas omniscientes. Les intentions secrètes ne sont pas connues automatiquement.

**[À DÉFINIR — C-06]** Niveau de fog of war : positions des armées visibles ou non, effectifs visibles ou non, informations obtenues par le renseignement, informations publiques (fronts, conquêtes, déclarations).

**[VALIDÉ — exigence d'équité]** Toute asymétrie d'information doit s'appliquer de la même façon aux joueurs humains et aux IA.

## 8. Tensions de conception applicables

| ID | Tension | Traitement |
|---|---|---|
| C-01 | Tour mensuel vs bataille tactique de 30 minutes. | Non tranchée ; ADR-0005 `proposé`. |
| C-04 | « Nouvelle offensive immédiate » vs calendrier mensuel. | Non tranchée. |
| C-08 | Seuils et fin de partie. | Non tranchés. |
| C-16 | Diplomatie pendant le mois vs verrouillage des ordres. | Non tranchée. |

Aucune de ces tensions ne peut être résolue par un agent seul ([AGENTS.md](../../AGENTS.md) § 14).

## 9. Questions ouvertes

| ID | Question | Référence |
|---|---|---|
| R-001 | Quelles phases exactes et quel moment de verrouillage ? | C-01, C-16 |
| R-002 | Quels ordres sont disponibles au lancement ? | T-026 |
| R-003 | Comment résoudre les conflits d'ordres simultanés ? | § 5 |
| R-004 | Quels seuils de victoire et quelle durée maximale ? | C-08 |
| R-005 | Quel niveau de fog of war ? | C-06 |
| R-006 | Que se passe-t-il pour un joueur absent ou éliminé ? | C-08, C-14 |

## 10. Critères de passage à « Spécifié »

- [ ] Phases et verrouillage définis et validés.
- [ ] Types d'ordres et validation spécifiés.
- [ ] Résolution des conflits simultanés décrite, cas limites inclus.
- [ ] Seuils et conditions de fin validés par le propriétaire.
- [ ] Niveau de visibilité validé.
- [ ] Jeux de tests de référence identifiés.
- [ ] Validation du propriétaire.
