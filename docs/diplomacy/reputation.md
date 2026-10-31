# Réputation

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [treaties.md](treaties.md) · [alliances.md](alliances.md) · [negotiations.md](negotiations.md) · [artificial-intelligence/memory-system.md](../artificial-intelligence/memory-system.md)

---

## 1. Objet

Définir comment la confiance, la fiabilité et l'historique des engagements sont représentés et utilisés. La réputation est le mécanisme qui donne un coût à la trahison et de la valeur aux promesses.

**Aucun modèle n'est validé.**

## 2. Pourquoi une réputation

**[PROPOSITION]** Sans réputation :

- trahir n'a aucun coût ;
- les promesses ne valent rien ;
- les IA n'ont aucune raison de coopérer durablement ;
- la diplomatie se réduit à un jeu de dupes à court terme.

Avec une réputation :

- les engagements passés influencent les décisions futures ;
- la coopération devient possible ;
- la trahison devient un calcul, pas une impulsion ;
- les personnalités peuvent se distinguer (fidèle, opportuniste, imprévisible).

## 3. Dimensions proposées

| Dimension | Signification | Exemple |
|---|---|---|
| Fiabilité | Tient ses engagements | Traités respectés |
| Honnêteté | Dit la vérité | Informations vérifiées |
| Loyauté | Soutient ses alliés | Aide effective |
| Agressivité | Attaque fréquemment | Guerres déclarées |
| Prévisibilité | Comportement stable | Écarts aux habitudes |
| Réciprocité | Rend les services | Aide retournée |

**[À DÉFINIR]** Faut-il une valeur unique de « confiance » ou plusieurs dimensions ? Trop de dimensions rend le modèle opaque et difficile à équilibrer.

## 4. Sources de réputation

- traités signés et respectés ;
- traités rompus ;
- promesses tenues ou non ;
- alliances honorées ou trahies ;
- aide apportée ou refusée ;
- mensonges découverts ;
- attaques non provoquées ;
- comportement envers les plus faibles ;
- cohérence entre discours et actes.

**[À DÉFINIR]** Comment distinguer une trahison justifiée d'une trahison gratuite ? Faut-il une notion de légitimité ?

## 5. Calcul et mise à jour

**[À DÉFINIR]**

- événementiel (chaque acte modifie un score) ou évalué périodiquement ?
- pondération par gravité ?
- décroissance dans le temps ?
- réputation par paire (A envers B) ou globale ?
- réputation connue de tous ou privée ?
- comment éviter les oscillations et les effets de bord ?

**[HYPOTHÈSE]** Une réputation par paire, complétée d'une réputation publique agrégée, serait plus réaliste. À valider.

## 6. Visibilité

**[À DÉFINIR]** Qui voit quoi :

- chaque acteur voit-il sa réputation vue par les autres ?
- les scores sont-ils publics ?
- les causes sont-elles visibles ?
- les IA peuvent-elles cacher leurs intentions ?
- le joueur humain doit-il voir pourquoi une IA ne lui fait plus confiance ?

**[PROPOSITION]** Une interface lisible mais imparfaite : le joueur voit des signaux, pas les calculs exacts.

## 7. Effets sur le jeu

Options :

- les IA modifient leurs décisions selon la réputation ;
- les traités futurs sont plus difficiles à conclure ;
- les coalitions se forment contre les traîtres ;
- les échanges économiques sont refusés ;
- les représailles sont plus probables ;
- aucun effet mécanique, seulement social.

**[À DÉFINIR]** La réputation doit-elle avoir un effet mécanique dur (interdiction de traité) ou rester une incitation ?

## 8. Réputation et IA

Une IA doit pouvoir :

- estimer la fiabilité d'un autre acteur ;
- mettre à jour cette estimation après un événement ;
- décider de coopérer ou non ;
- décider de trahir en tenant compte du coût réputationnel ;
- se souvenir des engagements ;
- éventuellement mentir sur sa propre réputation.

**[VALIDÉ]** Les IA doivent pouvoir manipuler. La réputation ne doit donc pas être une vérité parfaite et incontestable.

## 9. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Modèle opaque | Le joueur ne comprend pas | Signaux et explications |
| Réputation figée | Un traître ne peut jamais se racheter | Décroissance, rédemption |
| Réputation trop punitive | Personne n'ose trahir | Pondération, contexte |
| Réputation trop faible | Trahison sans conséquence | Événements visibles, coalitions |
| Exploit | Collusion pour manipuler les scores | Détection, règles anti-collusion |
| Biais anti-IA | Les IA se coalisent contre l'humain | Symétrie des règles |
| Données excessives | Trop d'historique | Résumés, oubli |

## 10. Questions ouvertes

| ID | Question |
|---|---|
| R-001 | Une ou plusieurs dimensions ? |
| R-002 | Réputation par paire ou globale ? |
| R-003 | Comment est-elle calculée ? |
| R-004 | Décroît-elle avec le temps ? |
| R-005 | Est-elle visible ? Par qui ? |
| R-006 | A-t-elle un effet mécanique ? |
| R-007 | Comment permettre la rédemption ? |
| R-008 | Comment éviter les abus de collusion ? |
| R-009 | Comment les IA l'utilisent-elles ? |
| R-010 | Comment la tester et l'équilibrer ? |
| R-011 | La réputation est-elle persistante entre parties ? |
| R-012 | Que se passe-t-il si un acteur est éliminé ? |

## 11. Dépendances

- [treaties.md](treaties.md) : engagements et ruptures.
- [alliances.md](alliances.md) : loyauté et trahison.
- [negotiations.md](negotiations.md) : promesses et mensonges.
- [artificial-intelligence/memory-system.md](../artificial-intelligence/memory-system.md) : mémoire des événements.
- [artificial-intelligence/decision-making.md](../artificial-intelligence/decision-making.md) : usage dans les décisions.
- [architecture/data-model.md](../architecture/data-model.md) : entité `Reputation`.

## 12. Critères de passage à « Spécifié »

- [ ] Dimensions et granularité validées.
- [ ] Règles de calcul et de décroissance définies.
- [ ] Visibilité définie.
- [ ] Effets sur le jeu définis.
- [ ] Utilisation par les IA spécifiée.
- [ ] Stratégie de test et d'équilibrage définie.
- [ ] Validation du propriétaire.
