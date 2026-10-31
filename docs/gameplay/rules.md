# Règles du jeu

> **Statut :** Cadrage antérieur — fiche maîtresse non intégrée, règles détaillées non conçues, non implémentées
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [map-system.md](map-system.md) · [military-system.md](military-system.md) · [economy-system.md](economy-system.md) · [diplomacy/treaties.md](../diplomacy/treaties.md) · [architecture/overview.md](../architecture/overview.md)

---

> **Note de cohérence (2026-10-31) —** Ce document a été rédigé avant la fiche maîtresse (PROJECT.md v0.2.0). La relation aux inspirations, le rythme (un tour = un mois, résolution simultanée), le cadre 1914 et les trois voies de victoire y sont désormais tranchés : voir [PROJECT.md](../../PROJECT.md) § 1.2, 3, 5, 13 et 20.3. Les hypothèses contraires ci-dessous sont historiques et ne font plus autorité. Révision suivie par la tâche **T-031**.

## 1. Objet

Poser le cadre des règles de base : boucle de jeu, phases, types d'ordres, résolution, conditions de fin. Ce document ne définit pas encore de règles définitives.

## 2. Base de référence

**[VALIDÉ]** Le jeu est inspiré de webDiplomacy / Diplomacy.

**[À DÉFINIR — Q-003]** La nature exacte de cette inspiration :

- reprise fidèle des mécaniques de Diplomacy (plateau classique, sept puissances, ordres simultanés) ?
- adaptation libre (carte différente, puissances différentes, mécaniques supplémentaires) ?
- inspiration thématique seulement (négociation et trahison), avec des règles originales ?

Cette question est **bloquante** : elle conditionne le système militaire, la carte, l'équilibrage et le risque juridique.

## 3. Boucle de jeu envisagée (hypothèse)

**[HYPOTHÈSE]** Une partie se déroulerait par cycles :

1. **Phase de négociation** : les acteurs échangent des messages, forment des alliances, prennent des engagements.
2. **Phase d'ordres** : chaque acteur soumet secrètement ses ordres.
3. **Résolution** : les ordres sont validés puis résolus simultanément.
4. **Phase de retraite / ajustement** : selon les résultats.
5. **Fin de tour** : mise à jour des perceptions, de la réputation et des objectifs.

**[À DÉFINIR]** L'ordre exact, la possibilité de négocier pendant la phase d'ordres, et l'existence de phases distinctes.

## 4. Types d'ordres (proposition inspirée de Diplomacy)

| Ordre | Description | Statut |
|---|---|---|
| Tenir | L'unité reste sur place. | **Proposition** |
| Se déplacer | Vers un territoire adjacent. | **Proposition** |
| Soutenir | Soutenir une unité qui tient ou se déplace. | **Proposition** |
| Convoyer | Transporter une unité par mer. | **Proposition** |
| Retraite | Repli après une défaite. | **Proposition** |
| Construction | Créer une unité dans un centre contrôlé. | **Proposition** |
| Démantèlement | Retirer une unité. | **Proposition** |

**[À DÉFINIR]** Faut-il des ordres conditionnels, des ordres différés, des ordres de renseignement, des ordres économiques ? La réponse dépend du périmètre (Q-002) et de l'économie (Q-015).

## 5. Résolution des ordres (hypothèse)

**[HYPOTHÈSE]** Une résolution simultanée, avec :

- priorité des soutiens ;
- résolution des conflits de mouvement ;
- effets des coupes de soutien ;
- gestion des chaînes de convoi ;
- règles de retraite et de construction.

**[VALIDÉ — contrainte de qualité]** La résolution doit être **déterministe** : à ordres, état et graine identiques, le résultat doit être identique. Tout aléatoire doit être explicite et enregistré.

**[À DÉFINIR]** Le détail des conflits, les égalités, les cycles de mouvement, les règles de bord. Ces points doivent être spécifiés et testés avant implémentation.

## 6. Phases et calendrier

**[À DÉFINIR — Q-005]**

- temps réel avec ticks ?
- tour par tour synchrone avec minuteur ?
- asynchrone (plusieurs heures/jours par tour) ?
- hybride avec négociation asynchrone et résolution programmée ?

Le choix influence l'architecture, le design des IA et l'expérience. Aucune option n'est retenue.

## 7. Conditions de victoire et de fin

**[À DÉFINIR — Q-014]** Options possibles :

- contrôle d'un nombre de centres ;
- élimination des adversaires ;
- score après un nombre de tours ;
- objectifs asymétriques ;
- victoire diplomatique / coalition ;
- condition de survie.

**[À DÉFINIR]** Que se passe-t-il en cas d'égalité, d'abandon, de joueur déconnecté, d'IA défaillante ?

## 8. Information et fog of war

**[À DÉFINIR — Q-013]** Diplomacy classique repose sur une information largement publique (positions des unités), avec secret des ordres et des négociations. Le projet peut conserver ce modèle ou introduire un brouillard plus fort.

Contrainte : toute règle de visibilité doit être compatible avec l'équité des IA (Q-012) et testable.

## 9. Rythme et durée

**[À DÉFINIR — Q-017]** Durée cible d'une partie, nombre de tours, temps de négociation, possibilité de sauvegarder/reprendre.

## 10. Règles et variantes

**[PROPOSITION]** Séparer :

- le **socle** de règles obligatoires ;
- les **variantes** optionnelles, déclarées dans la configuration de partie ;
- la **version des règles**, enregistrée avec chaque sauvegarde.

Cela faciliterait les tests, le replay et l'ajout de mécaniques.

## 11. Questions ouvertes

| ID | Question |
|---|---|
| G-001 | Reprise fidèle ou adaptation libre de Diplomacy (Q-003) ? |
| G-002 | Quels types d'ordres exactement ? |
| G-003 | Comment résoudre les conflits et les égalités ? |
| G-004 | Y a-t-il des ordres conditionnels ? |
| G-005 | Quel rythme de partie (Q-005) ? |
| G-006 | Quelles conditions de victoire (Q-014) ? |
| G-007 | Quel niveau de fog of war (Q-013) ? |
| G-008 | Les traités ont-ils un effet mécanique (Q-016) ? |
| G-009 | Les règles sont-elles moddables (Q-018) ? |
| G-010 | Comment gérer les abandons et déconnexions ? |

## 12. Dépendances

- La carte dépend des règles ([map-system.md](map-system.md)).
- Le militaire dépend des types d'ordres ([military-system.md](military-system.md)).
- L'économie n'est pertinente que si elle est confirmée ([economy-system.md](economy-system.md)).
- La diplomatie doit s'articuler avec les phases ([negotiations.md](../diplomacy/negotiations.md)).
- L'IA doit connaître les règles et les ordres légaux ([decision-making.md](../artificial-intelligence/decision-making.md)).

## 13. Critères de passage à « Spécifié »

- [ ] Q-003 et Q-002 tranchées.
- [ ] Types d'ordres listés et justifiés.
- [ ] Algorithme de résolution décrit, cas limites inclus.
- [ ] Conditions de victoire définies.
- [ ] Règles de visibilité définies.
- [ ] Jeux de tests de référence identifiés.
- [ ] Validation du propriétaire.
