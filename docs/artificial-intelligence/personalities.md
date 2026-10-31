# Personnalités des IA

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [ai-architecture.md](ai-architecture.md) · [memory-system.md](memory-system.md) · [decision-making.md](decision-making.md) · [diplomacy/reputation.md](../diplomacy/reputation.md)

---

## 1. Objet

Définir comment donner aux agents IA des personnalités distinctes, cohérentes et crédibles, sans tomber dans la caricature ni dans l'aléatoire.

**Aucun modèle de personnalité n'est validé.**

## 2. Pourquoi des personnalités

**[PROPOSITION]** Sans personnalité :

- tous les agents jouent de la même façon ;
- les négociations deviennent prévisibles ;
- la trahison est uniforme ;
- le joueur ne distingue pas ses adversaires.

Avec des personnalités :

- chaque agent a un style identifiable ;
- les alliances et les rivalités ont une histoire ;
- les décisions deviennent plus lisibles et plus intéressantes ;
- le replay et les analyses gagnent en valeur.

## 3. Modèle de traits proposé

Chaque trait serait une valeur normalisée (par exemple 0–100) ou une catégorie.

| Trait | Description | Effet possible |
|---|---|---|
| Agressivité | Tendance à attaquer | Fréquence des guerres |
| Prudence | Tolérance au risque | Acceptation des paris |
| Loyauté | Respect des engagements | Trahisons |
| Opportunisme | Réactivité aux gains rapides | Retournements |
| Patience | Horizon de planification | Investissement long terme |
| Sociabilité | Propension à négocier | Nombre de messages |
| Manipulation | Usage du mensonge | Bluffs, fausses promesses |
| Vindicativité | Réponse aux offenses | Représailles |
| Générosité | Propension à aider | Aides, concessions |
| Ambition | Priorité à la victoire | Risques acceptés |
| Adaptabilité | Changement de stratégie | Réactivité |
| Méfiance | Interprétation des intentions | Coût de la coopération |

**[À DÉFINIR]** Faut-il 3–4 traits simples ou une douzaine ? Trop de traits rendent le comportement difficile à comprendre et à équilibrer.

## 4. Valeurs, objectifs et style

Une personnalité ne se réduit pas à des traits. Il faut aussi définir :

- **Objectifs** : victoire, survie, domination régionale, revanche, prospérité.
- **Valeurs** : honneur, pragmatisme, loyauté, revanche, équilibre.
- **Style de communication** : direct, froid, chaleureux, théâtral, méfiant.
- **Style de jeu** : expansionniste, défensif, opportuniste, bâtisseur.
- **Cohérence** : ce que l'agent dit doit correspondre à ce qu'il fait, sauf mensonge assumé.

## 5. Génération et configuration

**[À DÉFINIR]**

- personnalités écrites à la main ?
- générées aléatoirement à partir d'une graine ?
- dérivées d'archétypes ?
- configurables par le joueur ?
- persistantes entre parties ?

**Contrainte proposée :** une personnalité doit être reproductible à partir d'une configuration enregistrée (graine incluse). Sinon les tests et le replay sont impossibles.

## 6. Archétypes possibles (exemples, non validés)

| Archétype | Traits dominants | Risque |
|---|---|---|
| Le loyal | Loyauté élevée, agressivité modérée | Prévisible, peut être exploité |
| L'opportuniste | Opportunisme, adaptabilité | Peu fiable, isolement |
| Le conquérant | Agressivité, ambition | Coalitions contre lui |
| Le stratège patient | Patience, prudence | Lenteur, passivité |
| Le manipulateur | Manipulation, sociabilité | Réputation détruite |
| Le vengeur | Vindicativité, méfiance | Escalade |
| Le conciliateur | Générosité, sociabilité | Faiblesse perçue |
| L'imprévisible | Adaptabilité, faible loyauté | Incohérence perçue |

Ces archétypes sont des **exemples de conception**, pas des personnages validés.

## 7. Cohérence et évolution

**[À DÉFINIR]**

- une personnalité peut-elle évoluer au cours de la partie ?
- peut-elle apprendre de ses erreurs ?
- peut-elle simuler un changement de style pour tromper ?
- comment éviter les retournements gratuits ?

**[PROPOSITION]** La personnalité définit des **tendances**, pas des règles absolues. Un agent loyal peut trahir si les circonstances l'exigent, mais rarement et avec un coût.

## 8. Personnalité et réputation

- La réputation perçue doit refléter les actes, pas seulement les traits déclarés.
- Un agent peut mentir sur sa personnalité.
- Les autres agents doivent pouvoir se tromper sur ses intentions.
- Le joueur ne doit pas voir les traits exacts, seulement des indices.

## 9. Personnalité et LLM

**[PROPOSITION]** La personnalité peut être injectée de plusieurs façons :

- instructions système (rôle, valeurs, style) ;
- paramètres de décision (seuils, poids) ;
- exemples de comportement ;
- mémoire des actes passés.

**Risque :** un prompt de personnalité trop rigide produit des comportements caricaturaux ; trop souple, il ne produit aucune identité.

## 10. Évaluation

Comment vérifier qu'une personnalité est réussie :

- un observateur peut-il l'identifier à partir d'un journal de partie ?
- ses décisions sont-elles cohérentes avec ses traits ?
- produit-elle des comportements variés ?
- est-elle équilibrée par rapport aux autres ?
- est-elle intéressante à jouer contre ?

**[PROPOSITION]** Utiliser des tests de scénarios et des évaluations par des juges (humains ou IA) avec des critères explicites.

## 11. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Caricature | Comportement en boucle | Traits multiples, contexte |
| Incohérence | Actes contraires au profil | Mémoire, garde-fous |
| Exploit | Personnalité trop prévisible | Variabilité contrôlée |
| Biais | Toutes les IA agressives | Diversité et équilibrage |
| Anthropomorphisme | Fausse profondeur | Évaluation rigoureuse |
| Coût | Prompts longs | Résumés de personnalité |

## 12. Questions ouvertes

| ID | Question |
|---|---|
| P-001 | Combien de traits ? |
| P-002 | Traits numériques ou catégories ? |
| P-003 | Personnalités écrites ou générées ? |
| P-004 | Sont-elles persistantes entre parties ? |
| P-005 | Peuvent-elles évoluer ? |
| P-006 | Le joueur peut-il les configurer ? |
| P-007 | Comment éviter la caricature ? |
| P-008 | Comment évaluer une personnalité ? |
| P-009 | Les traits sont-ils visibles ? |
| P-010 | Comment équilibrer des personnalités différentes ? |
| P-011 | Une IA peut-elle simuler une fausse personnalité ? |
| P-012 | Quel impact sur le coût des prompts ? |

## 13. Dépendances

- [ai-architecture.md](ai-architecture.md) : pipeline.
- [decision-making.md](decision-making.md) : usage des traits.
- [memory-system.md](memory-system.md) : continuité.
- [diplomacy/reputation.md](../diplomacy/reputation.md) : réputation perçue.
- [development/testing-strategy.md](../development/testing-strategy.md) : évaluation.

## 14. Critères de passage à « Spécifié »

- [ ] Modèle de traits validé.
- [ ] Archétypes du MVP choisis.
- [ ] Mécanisme de génération reproductible défini.
- [ ] Règles de cohérence et d'évolution définies.
- [ ] Visibilité pour le joueur définie.
- [ ] Critères d'évaluation définis.
- [ ] Validation du propriétaire.
