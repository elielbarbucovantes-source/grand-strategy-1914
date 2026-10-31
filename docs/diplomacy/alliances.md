# Alliances

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [treaties.md](treaties.md) · [negotiations.md](negotiations.md) · [reputation.md](reputation.md) · [gameplay/rules.md](../gameplay/rules.md)

---

## 1. Objet

Définir les alliances : formation, fonctionnement, coordination, dissolution, trahison et victoire partagée. Aucune mécanique n'est validée.

## 2. Définition proposée

**[PROPOSITION]** Une alliance est un groupe de puissances qui coordonnent leurs actions, partagent éventuellement des informations et s'engagent mutuellement. Elle peut être :

- formalisée par un traité ;
- informelle (coalition de circonstance) ;
- secrète ou publique ;
- temporaire ou durable.

## 3. Formation

**[À DÉFINIR]**

- combien de membres minimum ?
- faut-il un traité formel ?
- qui dirige ? rotation, unanimité, leader élu ?
- peut-on rejoindre ou quitter librement ?
- existe-t-il des alliances imposées par les règles (ex. camps) ?

## 4. Coordination

Mécanismes possibles :

| Mécanisme | Description | Statut |
|---|---|---|
| Canal de coalition | Discussion réservée aux membres | Proposition |
| Partage de plans | Les membres déclarent leurs intentions | Proposition |
| Ordres coordonnés | Le moteur facilite la coordination | À définir |
| Objectif commun | Condition de victoire partagée | À définir |
| Commandement | Un membre décide pour le groupe | À définir |

**[À DÉFINIR]** Le jeu doit-il aider mécaniquement la coordination, ou la laisser entièrement à la négociation ?

## 5. Secret et information

**[À DÉFINIR]**

- une alliance peut-elle être secrète ?
- les autres acteurs peuvent-ils la détecter ?
- que voit un membre des ordres des autres ?
- que se passe-t-il si un membre fuit des informations ?

**Contrainte proposée :** les canaux de coalition ne doivent pas être accessibles aux non-membres, ni aux IA non membres.

## 6. Trahison et dissolution

**[VALIDÉ]** La trahison doit être possible et intelligente.

**[À DÉFINIR]**

- peut-on quitter une alliance sans conséquence ?
- une trahison doit-elle être annoncée ?
- quelles conséquences sur la réputation ?
- l'alliance peut-elle exclure un membre ?
- que se passe-t-il si un membre est éliminé ?
- une alliance peut-elle survivre à la fin de son objectif ?

## 7. Victoire partagée

**[À DÉFINIR — Q-014]**

- une alliance peut-elle gagner collectivement ?
- tous les membres gagnent-ils, ou seulement certains ?
- comment départager les contributions ?
- la victoire partagée encourage-t-elle la coopération ou la passivité ?
- peut-on trahir au dernier tour pour gagner seul ?

C'est un point de design majeur : il détermine si les alliances sont réellement attractives.

## 8. Dynamique entre IA

**[PROPOSITION]** Les alliances entre IA devraient produire :

- des coalitions contre un leader trop puissant ;
- des négociations de partage de territoire ;
- des tensions entre engagement et intérêt ;
- des retournements crédibles, pas aléatoires ;
- des différences de style selon les personnalités.

**[À DÉFINIR]** Comment éviter :

- les alliances figées du début à la fin ;
- les trahisons gratuites et inexplicables ;
- le « tous contre le joueur humain » ;
- les coalitions absurdes entre ennemis historiques.

## 9. Équilibrage

- Les alliances doivent-elles être limitées en nombre ou en taille ?
- Faut-il des mécanismes anti-hégémonie ?
- Comment mesurer l'équilibre par simulation ?
- Les IA doivent-elles craindre les représailles ?

## 10. Questions ouvertes

| ID | Question |
|---|---|
| A-001 | Qu'est-ce qu'une alliance officielle ? |
| A-002 | Comment se forme-t-elle ? |
| A-003 | Comment se coordonne-t-elle ? |
| A-004 | Peut-elle être secrète ? |
| A-005 | Comment la quitter ou en être exclu ? |
| A-006 | Quelles conséquences à la trahison ? |
| A-007 | La victoire peut-elle être partagée (Q-014) ? |
| A-008 | Comment éviter les coalitions absurdes ? |
| A-009 | Faut-il des limites de taille ? |
| A-010 | Comment tester les dynamiques d'alliance ? |

## 11. Dépendances

- [treaties.md](treaties.md) : socle formel.
- [negotiations.md](negotiations.md) : canaux et propositions.
- [reputation.md](reputation.md) : confiance et conséquences.
- [gameplay/rules.md](../gameplay/rules.md) : victoire et phases.
- [artificial-intelligence/multi-agent-interactions.md](../artificial-intelligence/multi-agent-interactions.md) : dynamiques entre agents.

## 12. Critères de passage à « Spécifié »

- [ ] Définition d'une alliance validée.
- [ ] Mécanisme de formation et de coordination défini.
- [ ] Règles de secret et de visibilité définies.
- [ ] Conditions de dissolution et de trahison définies.
- [ ] Victoire partagée tranchée.
- [ ] Limites d'équilibrage définies.
- [ ] Scénarios de test multi-agents définis.
- [ ] Validation du propriétaire.
