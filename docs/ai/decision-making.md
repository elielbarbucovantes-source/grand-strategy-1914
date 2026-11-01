# Prise de décision des IA

> **Statut :** MVP : heuristiques déterministes ; méthode cible non validée
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Documents liés :** [ai-architecture.md](ai-architecture.md) · [personalities.md](personalities.md) · [memory-system.md](memory-system.md) · [multi-agent-interactions.md](multi-agent-interactions.md) · [gameplay/rules.md](../gameplay/rules.md)

---

## 0. Cadre validé par la fiche maîtresse

**[VALIDÉ]** La décision d'un agent IA doit respecter :

- l'autonomie et l'initiative (D-011) ;
- la non-omniscience : la décision repose sur une **perception filtrée**, jamais sur l'état complet du jeu (§ 7.4, Q-012) ;
- les objectifs combinés (ambitions, intérêts nationaux, survie, adaptation, victoire) (§ 7.2) ;
- la mémoire longue des engagements et des trahisons (§ 7.3) ;
- l'interdiction d'ajouter des mécaniques non validées (§ 17).

**[À DÉFINIR — T-023]** La méthode : heuristiques, LLM, planificateur, combinaison ? Aucune architecture n'est validée. Les niveaux de décision ci-dessous restent des propositions.

## 1. Objet

Décrire comment un agent passe de la perception à une décision : analyse, planification, négociation, génération d'ordres, validation et apprentissage.

**Aucune méthode n'est validée.**

## 2. Niveaux de décision proposés

| Niveau | Horizon | Exemple |
|---|---|---|
| Stratégique | Partie entière | « Domination de l'ouest » |
| Opérationnel | Quelques tours | « Aller contre B avec C » |
| Tactique | Tour courant | « Soutenir cette unité » |
| Communication | Immédiat | « Proposer un cessez-le-feu » |

Un agent doit maintenir une cohérence entre ces niveaux. Un plan stratégique sans traduction tactique est inutile ; une tactique sans stratégie est erratique.

## 3. Pipeline de décision proposé

```
1. Percevoir       → état filtré, messages, mémoire
2. Interpréter     → menaces, opportunités, intentions probables
3. Évaluer         → options, risques, coûts, bénéfices
4. Planifier       → stratégie et objectifs
5. Négocier        → messages, propositions, engagements
6. Décider         → plan d'action pour la phase
7. Générer         → ordres dans un format strict
8. Valider         → règles, cohérence, budget
9. Journaliser     → décision, rationale, confiance
10. Apprendre      → comparer résultat et attente
```

## 4. Évaluation des options

**[PROPOSITION]** Une combinaison de :

- **heuristiques** : règles simples et robustes (défendre la capitale, respecter un allié fiable) ;
- **utility / score** : pondération des gains, pertes, risques, réputation ;
- **LLM** : analyse contextuelle, créativité, négociation, explication ;
- **recherche** : simulation de coups à court terme, si le moteur le permet.

**[À DÉFINIR]** Quelle part pour chaque méthode ? Un agent entièrement LLM est flexible mais coûteux et imprévisible ; un agent entièrement heuristique est fiable mais rigide.

## 5. Rôle du LLM

Le LLM est particulièrement adapté à :

- comprendre des messages ambigus ;
- formuler des réponses diplomatiques ;
- évaluer des intentions ;
- proposer des plans originaux ;
- expliquer une décision ;
- simuler une personnalité.

Il est moins adapté à :

- garantir la légalité d'un ordre ;
- calculer une résolution exacte ;
- tenir un budget strict ;
- être reproductible.

**[PROPOSITION]** Le LLM propose, le validateur dispose.

## 6. Génération d'ordres

Contraintes proposées :

- format strict et documenté ;
- ordres référençant des identifiants existants ;
- validation contre l'état courant ;
- rejet explicite si invalide ;
- tentative de correction limitée ;
- fallback déterministe ;
- journalisation de l'ordre brut et de l'ordre corrigé.

**[À DÉFINIR]** Combien de tentatives de correction ? Que faire si le modèle échoue systématiquement ?

## 7. Négociation et engagements

Un agent doit :

- décider quand négocier et avec qui ;
- formuler des propositions claires ;
- suivre ses engagements ;
- décider de mentir ou non ;
- estimer le coût réputationnel d'une trahison ;
- répondre dans les délais ;
- gérer les ultimatums.

**[PROPOSITION]** Les engagements sont enregistrés au moment où ils sont pris, avec leur portée exacte. Sinon un agent peut « oublier » ce qu'il a promis.

## 8. Incertitude et croyances

- L'agent ne connaît pas les intentions des autres.
- Il doit maintenir des croyances, pas des certitudes.
- Il doit pouvoir se tromper.
- Il doit réviser ses croyances face aux preuves.
- Il doit distinguer ce qu'il sait, ce qu'il suppose et ce qu'il ignore.

**[À DÉFINIR]** Comment représenter et mettre à jour ces croyances ? Un simple score de confiance par acteur ? Un modèle bayésien ? Une mémoire narrative ?

## 9. Planification à long terme

**[À DÉFINIR]**

- horizon de planification ;
- re-planification à chaque tour ou seulement en cas d'événement ;
- plans de repli ;
- objectifs intermédiaires ;
- gestion des retournements.

**[HYPOTHÈSE]** Un plan stratégique révisé périodiquement, avec des objectifs à court terme recalculés chaque tour, offre un bon compromis.

## 10. Fallback et robustesse

**[PROPOSITION]** Si le LLM échoue ou dépasse le budget :

1. utiliser une heuristique de secours ;
2. conserver les engagements existants ;
3. produire des ordres valides ;
4. journaliser l'incident ;
5. ne jamais bloquer la partie.

Le fallback doit être testé comme un mode normal.

## 11. Explicabilité

**[À DÉFINIR]** Ce que l'agent doit pouvoir expliquer :

- pourquoi il a choisi une stratégie ;
- pourquoi il a accepté ou refusé ;
- pourquoi il a trahi ;
- pourquoi il a attaqué.

L'explication peut être destinée :

- au joueur (partielle, pour la lisibilité) ;
- à l'administrateur (complète, pour l'audit) ;
- à l'agent lui-même (mémoire).

**[PROPOSITION]** Une explication n'est pas nécessairement la vérité interne du modèle ; elle doit être cohérente avec les actes.

## 12. Évaluation des décisions

- taux de victoire ;
- survie ;
- respect des engagements ;
- qualité des alliances ;
- coût et latence ;
- cohérence avec la personnalité ;
- capacité à récupérer après une perte ;
- résistance à la manipulation.

**[PROPOSITION]** Comparer plusieurs versions sur des scénarios identiques, avec graine fixe.

## 13. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Ordres invalides | Le LLM produit du hors-format | Validation stricte |
| Incohérence | Plan et actes divergents | Journal, garde-fous |
| Passivité | L'agent ne fait rien | Heuristiques, objectifs |
| Agressivité absurde | Guerre permanente | Pondération, contexte |
| Coût | Trop d'appels | Budget, cache |
| Blocage | Timeout non géré | Fallback |
| Exploit | L'agent exploite un bug | Validation, tests |
| Anthropomorphisme | Surestimation de la qualité | Métriques |

## 14. Questions ouvertes

| ID | Question |
|---|---|
| DM-001 | Quelle part de LLM vs heuristiques ? |
| DM-002 | Quel horizon de planification ? |
| DM-003 | Comment représenter les croyances ? |
| DM-004 | Combien de tentatives de correction ? |
| DM-005 | Quel fallback ? |
| DM-006 | Comment décider de trahir ? |
| DM-007 | Comment gérer les engagements ? |
| DM-008 | Que doit expliquer l'agent ? |
| DM-009 | Comment évaluer les décisions ? |
| DM-010 | Les agents peuvent-ils apprendre entre parties ? |
| DM-011 | Comment garantir la cohérence stratégique ? |
| DM-012 | Comment éviter les comportements dégénérés ? |

## 15. Dépendances

- [gameplay/rules.md](../gameplay/rules.md) : ordres et contraintes.
- [ai-architecture.md](ai-architecture.md) : pipeline.
- [memory-system.md](memory-system.md) : contexte.
- [personalities.md](personalities.md) : style.
- [diplomacy/treaties.md](../diplomacy/treaties.md) : engagements.
- [development/testing-strategy.md](../development/testing-strategy.md) : évaluation.

## 16. Critères de passage à « Spécifié »

- [ ] Architecture de décision validée.
- [ ] Rôle du LLM et des heuristiques défini.
- [ ] Format d'ordres et validation spécifiés.
- [ ] Fallback spécifié et testé.
- [ ] Gestion des engagements définie.
- [ ] Métriques d'évaluation définies.
- [ ] Scénarios de test définis.
- [ ] Validation du propriétaire.
