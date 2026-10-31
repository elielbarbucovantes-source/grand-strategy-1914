# Architecture — vue d'ensemble

> **Statut :** Cadrage — **aucune architecture technique validée**
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [technical-decisions.md](technical-decisions.md) · [data-model.md](data-model.md) · [PROJECT.md](../../PROJECT.md) · [ADR-0003](../decisions/0003-report-du-choix-de-pile-technique.md) · [gameplay/rules.md](../gameplay/rules.md) · [artificial-intelligence/ai-architecture.md](../artificial-intelligence/ai-architecture.md)

---

## 1. Objet

Décrire la décomposition **logique** envisagée du système, ses frontières, ses flux principaux et ses risques, sans choisir de langage, de moteur, de framework ni de base de données.

**Tout contenu de ce document est une [PROPOSITION]** sauf mention explicite. Aucune couche n'est implémentée.

## 2. Objectifs architecturaux (proposés)

1. **Isoler le noyau de règles** de l'interface, de la persistance et des IA.
2. **Garantir le déterminisme** de la résolution : mêmes entrées + même graine ⇒ même résultat.
3. **Permettre la rejouabilité** et l'audit : journal d'événements complet.
4. **Protéger l'information** : chaque acteur (humain ou IA) ne reçoit que ce qu'il a le droit de voir.
5. **Rendre les IA interchangeables** : contrat stable, indépendant du fournisseur de modèle.
6. **Supporter des parties longues** : sauvegarde, reprise, rechargement, versionnement des règles.
7. **Rester testable sans interface** : simulations et évaluations automatisées.
8. **Accepter l'évolution** : ajout de mécaniques sans réécriture du cœur.

## 3. Non-objectifs à ce stade

- Choisir un moteur de jeu ou un framework.
- Définir un schéma de base de données.
- Définir un protocole réseau définitif.
- Optimiser la performance avant d'avoir un prototype.
- Supporter le multijoueur à grande échelle.

## 4. Décomposition logique proposée

```
┌─────────────────────────────────────────────────────────────┐
│                     Interfaces / API                        │
│        Joueurs humains · Agents IA · Observateurs · Admin   │
└───────────────────────────┬─────────────────────────────────┘
                            │ commandes / perceptions filtrées
┌───────────────────────────▼─────────────────────────────────┐
│                   Application / Orchestration                │
│      Cycle de partie · tours · timers · files d'attente      │
└───────┬───────────────────────┬───────────────────────┬─────┘
        │                       │                       │
┌───────▼────────┐   ┌──────────▼─────────┐   ┌─────────▼──────┐
│  Noyau règles  │   │  Couche diplomatie │   │   Couche IA    │
│  état, ordres, │   │  messages, traités │   │ perception,    │
│  résolution    │   │  réputation        │   │ mémoire, plans │
└───────┬────────┘   └──────────┬─────────┘   └─────────┬──────┘
        │                       │                       │
┌───────▼───────────────────────▼───────────────────────▼─────┐
│              Persistance · Journal d'événements              │
│        sauvegardes · rejeu · audit · versionnement           │
└─────────────────────────────────────────────────────────────┘
```

### 4.1 Noyau de règles

Responsabilités proposées :

- représenter l'état de la partie (plateau, unités, propriété, phase) ;
- valider les ordres soumis ;
- résoudre simultanément les ordres selon les règles ;
- produire des événements et un nouvel état ;
- exposer un état filtré par acteur.

Contraintes proposées : pur (pas d'appels réseau), déterministe, sans dépendance à un LLM, testable unitairement.

### 4.2 Application / orchestration

- gérer le cycle de vie d'une partie et les échéances ;
- collecter les ordres et messages ;
- appeler le noyau de règles ;
- déclencher les agents IA dans un ordre explicite ;
- gérer reprises, pauses et erreurs.

**Question ouverte :** l'orchestration doit-elle être un service unique, un ensemble de workers, ou un simple processus local pour le MVP ?

### 4.3 Couche diplomatie

- canaux de communication ;
- propositions, acceptations, refus, renégociations ;
- traités et leur cycle de vie ;
- réputation et conséquences ;
- journalisation des engagements.

Cette couche ne doit pas contenir de règle militaire. Elle produit des engagements que le noyau peut éventuellement contraindre, selon une décision de game design encore ouverte (Q-016).

### 4.4 Couche IA

Pipeline proposé : **perception filtrée → mémoire → analyse → plan → négociation → ordres → auto-évaluation**.

Elle ne doit jamais accéder directement à l'état complet de la partie. Elle reçoit une vue construite par le noyau ou l'orchestrateur, et renvoie des messages et des ordres qui passent par la validation normale.

### 4.5 Interface / API

- interface joueur (à définir) ;
- API pour les agents IA (à définir) ;
- mode spectateur / replay (proposé) ;
- outils d'administration (proposé).

### 4.6 Persistance et journal

Deux besoins distincts :

1. **Sauvegarde d'état** : reprendre une partie exactement où elle s'est arrêtée.
2. **Journal d'événements** : reconstituer, auditer, rejouer et alimenter la mémoire des IA.

**[HYPOTHÈSE]** Un journal append-only, versionné et corrélé à une graine aléatoire simplifierait les tests et le replay. À valider par un prototype.

## 5. Flux principaux (proposés)

### 5.1 Tour de jeu

1. L'orchestrateur ouvre une phase et calcule les perceptions de chaque acteur.
2. Les joueurs et les IA échangent des messages selon les canaux autorisés.
3. Chaque acteur soumet ses ordres avant l'échéance.
4. Le noyau valide les ordres, résout la phase et émet des événements.
5. Les perceptions sont recalculées ; la phase suivante commence.
6. Les événements sont persistés et journalisés.

### 5.2 Décision d'une IA

1. Recevoir la perception filtrée et les messages reçus.
2. Mettre à jour la mémoire.
3. Évaluer la situation et les engagements.
4. Choisir une stratégie et un plan.
5. Négocier (messages, propositions).
6. Produire des ordres valides.
7. Enregistrer les engagements pris et les attentes.

### 5.3 Trahison / rupture

Une rupture de traité doit produire un événement visible par les acteurs concernés, puis être propagée à la réputation. Les modalités exactes restent **à définir**.

## 6. Frontières et règles de dépendance proposées

| Depuis | Vers | Autorisé ? |
|---|---|---|
| Noyau de règles | IA | **Non** |
| Noyau de règles | Interface | **Non** |
| Noyau de règles | Persistance | **Non** (il produit des événements ; la persistance les consomme) |
| IA | Noyau de règles (état complet) | **Non** (seulement la perception filtrée) |
| IA | Fournisseur LLM | Oui, via une abstraction |
| Interface | Application | Oui, via API/contrat |
| Application | Toutes les couches | Oui, en orchestration |

Ces frontières sont des propositions à valider dans un ADR avant implémentation.

## 7. Risques architecturaux identifiés

| ID | Risque | Impact | Mitigation proposée |
|---|---|---|---|
| R-001 | Une IA accède à des informations cachées et triche. | Équité, crédibilité | Perception construite côté serveur ; tests d'étanchéité. |
| R-002 | Les LLM produisent des ordres invalides ou incohérents. | Blocage, bugs | Validation stricte + plan de secours déterministe. |
| R-003 | Latence/coût des LLM incontrôlés. | Partie injouable, budget | Budgets par tour, timeouts, cache, modèles locaux. |
| R-004 | Résolution non déterministe. | Tests impossibles, litiges | Graine explicite, ordre stable, absence d'itération non ordonnée. |
| R-005 | Fuite de prompt ou injection via messages de jeu. | Sécurité, manipulation | Traiter les messages comme données ; séparation instructions/contenu. |
| R-006 | Modèle de données figé trop tôt. | Dette, migrations | Modèle conceptuel d'abord ; versionnement. |
| R-007 | Complexité prématurée (microservices, temps réel). | Retard | MVP simple, monolithe modulaire proposé. |
| R-008 | Documentation qui diverge du code. | Perte de continuité | DoD, revue, ADR, journal. |
| R-009 | Licence de carte/assets incompatible. | Juridique | Vérification avant intégration. |
| R-010 | Dépendance forte à un fournisseur LLM. | Coût, disponibilité | Abstraction de fournisseur. |

## 8. Options d'architecture à étudier

| Option | Avantages | Inconvénients | Statut |
|---|---|---|---|
| Monolithe modulaire | Simple, rapide à démarrer, débogage facile | Extensibilité à grande échelle limitée | **À évaluer** |
| Services séparés (règles / IA / API) | Isolation, scaling | Complexité opérationnelle | **À évaluer** |
| Moteur de jeu existant | Rendu et outils fournis | Dépendance, courbe d'apprentissage, inadapté au serveur | **À évaluer** |
| Application web pure | Déploiement facile, asynchrone naturel | Rendu 3D limité | **À évaluer** |
| Desktop natif | Performance, offline | Distribution, multijoueur plus complexe | **À évaluer** |

Aucune option n'est retenue. Voir [technical-decisions.md](technical-decisions.md).

## 9. Questions ouvertes

- Q-005 : temps réel, tour par tour ou asynchrone ?
- Q-006 : solo, multijoueur ou mixte ?
- Q-007 : quelle plateforme ?
- Q-008 : quel langage / moteur ?
- Q-009 : quelle persistance ?
- Q-012 : comment garantir l'étanchéité informationnelle des IA ?
- Q-023 : quel budget d'infrastructure ?

Liste complète : [PROJECT.md § 12](../../PROJECT.md#12-questions-encore-ouvertes).

## 10. Critères pour passer au statut « Spécifié »

- [ ] Q-002, Q-003, Q-005, Q-008 tranchées par le propriétaire.
- [ ] ADR d'architecture accepté (monolithe vs services, frontières).
- [ ] Modèle de données conceptuel validé.
- [ ] Stratégie de persistance et de replay validée.
- [ ] Contrat d'interface IA validé.
- [ ] Un prototype de résolution d'ordres existe et est testé.

Tant que ces critères ne sont pas remplis, ce document reste un document de cadrage.
