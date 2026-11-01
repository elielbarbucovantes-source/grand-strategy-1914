# Architecture des IA

> **Statut :** MVP : IA heuristique livrée ; architecture cible non conçue
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Documents liés :** [personalities.md](personalities.md) · [memory-system.md](memory-system.md) · [decision-making.md](decision-making.md) · [multi-agent-interactions.md](multi-agent-interactions.md) · [architecture/overview.md](../architecture/overview.md)

---

## 0. Cadre validé par la fiche maîtresse

**[VALIDÉ]** Les IA sont de **véritables acteurs politiques autonomes**, avec :

- des personnalités et des traits qui influencent sans déterminer mécaniquement (D-011, § 7.1) ;
- des objectifs combinant ambitions personnelles, intérêts du pays, survie, adaptation et victoire (§ 7.2) ;
- une **mémoire à long terme** des conversations, promesses, trahisons, alliances, conflits et erreurs (§ 7.3) ;
- la capacité de mentir, manipuler, désinformer, changer d'avis, prendre l'initiative et déclencher des crises (§ 7.4) ;
- une **non-omniscience** : elles ne connaissent pas automatiquement les intentions secrètes (§ 7.4, D-011) ;
- l'autonomie nécessaire pour que le monde évolue même si le joueur n'agit pas (§ 7.5).

**[VALIDÉ]** Les IA ne doivent **pas** attendre passivement les propositions du joueur (§ 6.5).

**[ATTENTION — V-03]** Le coût et la charge de décision d'une IA gérant diplomatie, économie, industrie, recherche et guerre ne sont pas estimés. Aucun fournisseur ni budget n'est choisi (Q-010, Q-023).

**[ATTENTION — Q-012]** L'étanchéité informationnelle (garantir qu'une IA ne lit pas l'état complet) est une condition d'équité non encore spécifiée.

## 1. Objet

Décrire les composants et les flux d'un agent IA de jeu, sans choisir de modèle, de fournisseur ni de framework.

**Aucune architecture n'est validée.** Les propositions ci-dessous servent de base de discussion.

## 2. Objectifs

**[VALIDÉ]** Les IA doivent être autonomes, réalistes, capables de :

- négocier ;
- coopérer ;
- manipuler ;
- respecter des traités ;
- trahir intelligemment.

**[PROPOSITION]** Objectifs de qualité :

1. **Crédibilité** : les décisions ont du sens dans le contexte.
2. **Cohérence** : une personnalité garde un style reconnaissable.
3. **Adaptation** : l'IA réagit aux événements et aux autres acteurs.
4. **Équité** : aucune information cachée n'est utilisée.
5. **Robustesse** : un modèle défaillant ne bloque pas la partie.
6. **Mesurabilité** : la qualité est évaluée par des scénarios reproductibles.
7. **Coût maîtrisé** : budget et latence bornés.

## 3. Pipeline proposé

```
┌──────────────┐   ┌──────────┐   ┌───────────┐   ┌────────────┐
│  Perception  │──▶│ Mémoire  │──▶│  Analyse  │──▶│Planification│
│   filtrée    │   │ mise à   │   │ situation │   │  stratégie  │
│              │   │  jour    │   │ risque    │   │             │
└──────────────┘   └──────────┘   └───────────┘   └─────┬──────┘
                                                        │
┌──────────────┐   ┌──────────┐   ┌───────────┐   ┌─────▼──────┐
│ Auto-évaluation│◀─│ Journal  │◀─│ Validation│◀─│ Négociation │
│  et mémoire   │   │ d'actes  │   │ des ordres│   │  & messages │
└──────────────┘   └──────────┘   └───────────┘   └────────────┘
```

### 3.1 Perception

- Reçoit une vue filtrée de l'état du jeu.
- Reçoit les messages qui lui sont adressés.
- Reçoit ses propres engagements et son historique.
- **Ne reçoit jamais** l'état complet, les ordres secrets des autres, ni les messages privés d'autrui.

### 3.2 Mémoire

- Mémoire de travail (tour courant).
- Mémoire épisodique (événements marquants).
- Mémoire sociale (relations, confiance, engagements).
- Mémoire stratégique (plans, objectifs).
- Résumés pour limiter le contexte.

Voir [memory-system.md](memory-system.md).

### 3.3 Analyse

- Évaluer la situation militaire, diplomatique et économique.
- Identifier les menaces, opportunités et engagements.
- Estimer les intentions des autres acteurs.
- Mesurer l'incertitude.

### 3.4 Planification

- Choisir une stratégie à moyen terme.
- Décomposer en objectifs par tour.
- Arbitrer entre coopération, neutralité et agression.
- Prévoir des plans de repli.

### 3.5 Négociation

- Décider qui contacter, quand et pourquoi.
- Formuler des propositions et des menaces.
- Répondre aux messages.
- Gérer les engagements et les mensonges.

### 3.6 Génération et validation des ordres

- Produire des ordres dans un format strict.
- Les valider contre les règles.
- En cas d'échec : corriger, puis fallback déterministe.
- Ne jamais soumettre un ordre invalide.

### 3.7 Auto-évaluation

- Comparer les résultats aux attentes.
- Mettre à jour la mémoire et les croyances.
- Ajuster la stratégie.
- Alimenter les métriques d'évaluation.

## 4. Séparation LLM / logique

**[PROPOSITION]** Le LLM ne doit pas être l'unique décideur. Une architecture hybride est recommandée :

| Couche | Rôle | Déterministe ? |
|---|---|---|
| Heuristiques / utility | Évaluation des coups, priorisation | Oui |
| LLM | Négociation, explication, créativité, analyse de contexte | Non |
| Validateur | Vérifie la légalité et la cohérence | Oui |
| Fallback | Joue un coup raisonnable si le LLM échoue | Oui |

Cela réduit les risques d'ordres invalides, de blocage et de comportements absurdes.

## 5. Abstraction du fournisseur de modèles

**[PROPOSITION]** Une interface unique devrait permettre :

- plusieurs fournisseurs (API distantes) ;
- des modèles locaux ;
- des modèles différents selon la tâche (négociation, résumé, analyse) ;
- le remplacement d'un fournisseur sans réécrire la logique de jeu ;
- l'enregistrement des prompts et des réponses pour l'audit (avec précaution sur les coûts et la confidentialité).

**[À DÉFINIR]** Faut-il un seul modèle par agent ou plusieurs modèles spécialisés ?

## 6. Contrat d'interface (proposition)

**Entrées** :

- identifiant de partie et de puissance ;
- phase et échéance ;
- perception filtrée ;
- messages reçus ;
- mémoire résumée ;
- configuration de personnalité ;
- contraintes (budget, temps, format).

**Sorties** :

- messages à envoyer ;
- propositions / réponses diplomatiques ;
- ordres ;
- engagements pris ;
- métadonnées (confiance, raisonnement résumé, coût, latence).

Le contrat exact reste à spécifier.

## 7. Sécurité et équité

- **Étanchéité informationnelle** : la perception est construite côté serveur ; l'IA ne peut pas lire l'état complet.
- **Instructions vs données** : les messages de jeu ne sont jamais des instructions système.
- **Validation** : tout ordre est vérifié par le noyau.
- **Traçabilité** : chaque décision importante est journalisée.
- **Rate limiting** : pas d'appels illimités.
- **Isolation** : une IA compromise ne doit pas pouvoir agir sur les autres.

## 8. Coût, latence et disponibilité

**[À DÉFINIR — Q-023]**

- budget par partie et par tour ;
- nombre d'appels par tour ;
- taille maximale du contexte ;
- timeout et politique de retry ;
- cache des analyses ;
- modèles locaux possibles ?

**[PROPOSITION]** Un budget dur par agent et par tour, avec fallback heuristique, évite qu'une partie s'arrête à cause d'une API lente ou d'un coût excessif.

## 9. Évaluation

Une IA ne doit pas être jugée sur une impression. Il faut :

- des scénarios reproductibles ;
- des métriques (victoires, survie, respect des engagements, cohérence, coût, latence) ;
- des parties de référence ;
- une comparaison entre versions ;
- des tests adversariaux (manipulation, mensonge, coalition).

Voir [../development/testing-strategy.md](../development/testing-strategy.md).

## 10. Questions ouvertes

| ID | Question |
|---|---|
| AI-001 | Un LLM par agent ou plusieurs modèles ? |
| AI-002 | Quelle part de logique déterministe ? |
| AI-003 | Comment construire la perception filtrée ? |
| AI-004 | Quel format de sortie pour les ordres ? |
| AI-005 | Comment gérer les timeouts et les échecs ? |
| AI-006 | Quel budget par partie (Q-023) ? |
| AI-007 | Les modèles locaux sont-ils requis (Q-011) ? |
| AI-008 | Comment auditer les décisions ? |
| AI-009 | Comment éviter la prompt injection ? |
| AI-010 | Comment mesurer la qualité ? |
| AI-011 | Un agent peut-il changer de personnalité en cours de partie ? |
| AI-012 | Les agents partagent-ils du code ou sont-ils indépendants ? |

## 11. Dépendances

- [gameplay/rules.md](../gameplay/rules.md) : ordres légaux et état.
- [architecture/overview.md](../architecture/overview.md) : frontières.
- [memory-system.md](memory-system.md), [decision-making.md](decision-making.md), [personalities.md](personalities.md), [multi-agent-interactions.md](multi-agent-interactions.md).
- [diplomacy/negotiations.md](../diplomacy/negotiations.md) : messages.
- ADR sur l'intégration LLM (TD-010).

## 12. Critères de passage à « Spécifié »

- [ ] Pipeline validé.
- [ ] Contrat d'interface entrée/sortie spécifié.
- [ ] Frontière informationnelle validée et testable.
- [ ] Stratégie de fallback définie.
- [ ] Budget et timeouts définis.
- [ ] Harnais d'évaluation spécifié.
- [ ] ADR d'intégration LLM accepté.
- [ ] Validation du propriétaire.
