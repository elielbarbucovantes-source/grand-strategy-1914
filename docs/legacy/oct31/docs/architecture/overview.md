# Architecture — vue d'ensemble

> **Statut :** Cadrage — **aucune architecture technique validée**
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 5, § 8, § 16, § 21 · [founding-document-v0.1.md](../founding-document-v0.1.md)
> **Documents liés :** [technical-decisions.md](technical-decisions.md) · [data-model.md](data-model.md) · [PROJECT.md](../../PROJECT.md) · [ADR-0003](../decisions/0003-report-du-choix-de-pile-technique.md) · [ADR-0005](../decisions/0005-integration-strategique-tactique.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../military/tactical-battles.md](../military/tactical-battles.md) · [../ai/ai-architecture.md](../ai/ai-architecture.md)

---

## 1. Objet

Décrire la décomposition **logique** envisagée du système, ses frontières, ses flux principaux et ses risques, sans choisir de langage, de moteur, de framework ni de base de données.

**Tout contenu de ce document est une [PROPOSITION]** sauf mention explicite. Aucune couche n'est implémentée.

## 2. Cadre validé qui contraint l'architecture

| Élément | Décision | Conséquence architecturale |
|---|---|---|
| Un tour = un mois, résolution simultanée. | D-006, § 5 | Un calendrier stratégique discret, journalier ou mensuel, déterministe. |
| Batailles tactiques indépendantes, 30 minutes max. | D-014, § 8.3 | Un **second moteur** ou un **mode de session** distinct, avec un contrat de synchronisation. |
| Effectifs proportionnels. | D-014 | Conversion explicite stratégique ↔ tactique. |
| Multijoueur non indispensable, architecture anticipée. | D-026, § 16 | Session de bataille isolée, transport abstrait, pas de couplage au solo. |
| IA autonomes et non omniscientes. | D-011, § 7.4 | Frontière informationnelle stricte, perception filtrée. |
| Diplomatie confidentielle par défaut + interception. | D-008, D-023 | Les messages sont des données sensibles, avec accès contrôlé. |
| Économie, industrie, recherche, renseignement. | D-018 à D-023 | Plusieurs sous-systèmes et un modèle de données plus riche. |
| Sauvegarde et reprise. | Exigence générale | Persistance d'état + journal d'événements. |

**Ce que cela impose :** le système n'est plus un simple « moteur Diplomacy ». Il combine un **jeu de stratégie mensuel** et des **sessions tactiques temps réel**, ce qui est la source des tensions C-01, C-02, C-15 et C-17.

## 3. Objectifs architecturaux (proposés)

1. **Isoler le noyau de règles** de l'interface, de la persistance et des IA.
2. **Garantir le déterminisme** de la résolution stratégique : mêmes entrées + même graine ⇒ même résultat.
3. **Isoler le moteur de bataille** du calendrier stratégique, avec un contrat de session stable.
4. **Permettre la rejouabilité** et l'audit : journal d'événements complet.
5. **Protéger l'information** : chaque acteur (humain ou IA) ne reçoit que ce qu'il a le droit de voir.
6. **Rendre les IA interchangeables** : contrat stable, indépendant du fournisseur de modèle.
7. **Supporter des parties longues** : sauvegarde, reprise, rechargement, versionnement des règles.
8. **Rester testable sans interface** : simulations et évaluations automatisées.
9. **Anticiper le multijoueur** sans le livrer : aucune hypothèse « un seul joueur » dans le moteur de bataille.

## 4. Décomposition logique proposée

```
┌────────────────────────────────────────────────────────────────┐
│                        Interfaces / API                          │
│       Joueurs humains · Agents IA · Observateurs · Admin         │
└──────────────────────────────┬─────────────────────────────────┘
                               │ commandes / perceptions filtrées
┌──────────────────────────────▼─────────────────────────────────┐
│                    Application / Orchestration                    │
│   Calendrier mensuel · tours · verrouillage · files d'attente     │
└───────┬───────────────────────┬────────────────────────┬────────┘
        │                       │                        │
┌───────▼────────┐   ┌──────────▼─────────┐   ┌──────────▼───────┐
│  Noyau règles  │   │  Couche diplomatie │   │    Couche IA     │
│  stratégique   │   │  messages, accords │   │ perception,      │
│  état, ordres, │   │  réputation        │   │ mémoire, plans   │
│  résolution    │   │                    │   │                  │
└───────┬────────┘   └──────────┬─────────┘   └──────────┬───────┘
        │                       │                        │
┌───────▼───────────────────────▼────────────────────────▼───────┐
│                Persistance · Journal d'événements                │
│       sauvegardes · replay · audit · versionnement               │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────▼─────────────────────────────────┐
│              Moteur de bataille (session isolée)                  │
│   terrain · unités · ordres simultanés · timer 30 min             │
│   résultat → pertes, occupation, état des survivants              │
└──────────────────────────────────────────────────────────────────┘
```

### 4.1 Noyau de règles stratégique

Responsabilités proposées :

- représenter l'état de la partie (provinces, nations, formations, économie, recherche, renseignement, relations) ;
- valider les ordres soumis ;
- résoudre simultanément les ordres selon les règles ;
- produire des événements et un nouvel état ;
- exposer un état filtré par acteur ;
- ouvrir et clore les sessions de bataille, puis appliquer leur résultat.

Contraintes proposées : pur (pas d'appels réseau), déterministe, sans dépendance à un LLM, testable unitairement.

### 4.2 Application / orchestration

- gérer le cycle de vie d'une partie et les échéances ;
- collecter les ordres et messages ;
- appeler le noyau de règles ;
- déclencher les agents IA dans un ordre explicite ;
- ordonner les batailles (file d'attente, priorité, timeout) ;
- gérer reprises, pauses et erreurs.

**Question ouverte :** l'orchestration doit-elle être un service unique, un ensemble de workers, ou un simple processus local pour le MVP ?

### 4.3 Couche diplomatie

- canaux de communication ;
- propositions, acceptations, refus, renégociations ;
- traités et leur cycle de vie, avec deux catégories (D-009) ;
- réputation et conséquences ;
- journalisation des engagements ;
- contrôle d'accès aux messages (confidentialité, interception).

Cette couche ne doit pas contenir de règle militaire. Elle produit des engagements que le noyau peut contraindre si l'accord est **contraignant** (D-009).

### 4.4 Couche IA

Pipeline proposé : **perception filtrée → mémoire → analyse → plan → négociation → ordres → auto-évaluation**.

Elle ne doit jamais accéder directement à l'état complet de la partie. Elle reçoit une vue construite par le noyau ou l'orchestrateur, et renvoie des messages et des ordres qui passent par la validation normale.

**[À DÉFINIR — Q-012]** Le filtre de perception doit être identique pour tous les acteurs, humains ou IA. C'est une condition d'équité, pas une option.

### 4.5 Moteur de bataille

Le moteur de bataille est **distinct** du noyau stratégique. Il reçoit :

- les forces engagées, converties depuis le stratégique ;
- le terrain, cohérent avec la province ;
- les fortifications et les conditions ;
- l'identité des participants et le mode (humain, IA, résolution automatique).

Il renvoie :

- le vainqueur ;
- les pertes par camp et par unité ;
- l'état des survivants ;
- l'occupation éventuelle ;
- un journal de commandes pour le replay.

**[À DÉFINIR — C-01, C-02, C-15, C-17]** Le moment d'ouverture, le timer, la pause, la synchronisation multijoueur, le timeout et le replay.

### 4.6 Interface / API

- interface joueur (à définir) ;
- API pour les agents IA (à définir) ;
- mode spectateur / replay (proposé) ;
- outils d'administration (proposé) ;
- interface de bataille indépendante (validée par § 15.3).

### 4.7 Persistance et journal

Trois besoins distincts :

1. **Sauvegarde d'état** : reprendre une partie exactement où elle s'est arrêtée.
2. **Journal d'événements** : reconstituer, auditer, rejouer et alimenter la mémoire des IA.
3. **Journal de bataille** : commandes horodatées et résultat, pour le replay et l'audit.

**[HYPOTHÈSE]** Un journal append-only, versionné et corrélé à une graine aléatoire simplifierait les tests et le replay. À valider par un prototype.

## 5. Flux principaux (proposés)

### 5.1 Tour stratégique

1. L'orchestrateur ouvre une phase et calcule les perceptions de chaque acteur.
2. Les joueurs et les IA échangent des messages selon les canaux autorisés.
3. Chaque acteur soumet ses ordres avant l'échéance.
4. Le noyau valide les ordres, résout la phase et émet des événements.
5. Les offensives qui rencontrent des armées ouvrent des sessions de bataille.
6. Les résultats de bataille sont appliqués au tour courant.
7. Les perceptions sont recalculées ; la phase suivante commence.
8. Les événements sont persistés et journalisés.

**[ATTENTION — C-01]** La position exacte de l'étape 5–6 dans le calendrier n'est pas tranchée. Voir [ADR-0005](../decisions/0005-integration-strategique-tactique.md), `proposé`.

### 5.2 Décision d'une IA

1. Recevoir la perception filtrée et les messages reçus.
2. Mettre à jour la mémoire.
3. Évaluer la situation et les engagements.
4. Choisir une stratégie et un plan.
5. Négocier (messages, propositions).
6. Produire des ordres valides.
7. Enregistrer les engagements pris et les attentes.

### 5.3 Bataille

1. Le noyau stratégique identifie une offensive et les forces engagées.
2. L'orchestrateur ouvre une session de bataille (file d'attente si nécessaire).
3. Le moteur de bataille charge terrain, unités, fortifications et conditions.
4. Les participants donnent leurs ordres ; le moteur résout.
5. La session se termine par un résultat déterministe.
6. Le noyau applique pertes, état des survivants et occupation.

### 5.4 Trahison / rupture

Une rupture d'accord doit produire un événement visible par les acteurs concernés, puis être propagée à la réputation. Les modalités exactes restent **à définir** (T-022).

## 6. Frontières et règles de dépendance proposées

| Depuis | Vers | Autorisé ? |
|---|---|---|
| Noyau stratégique | IA | **Non** |
| Noyau stratégique | Interface | **Non** |
| Noyau stratégique | Persistance | **Non** (il produit des événements ; la persistance les consomme) |
| Noyau stratégique | Moteur de bataille | **Oui**, via un contrat de session explicite |
| Moteur de bataille | Noyau stratégique | **Non** (il reçoit un instantané, il renvoie un résultat) |
| IA | Noyau stratégique (état complet) | **Non** (seulement la perception filtrée) |
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
| R-009 | Licence de carte/assets/données historiques incompatible. | Juridique | Vérification avant intégration (C-13). |
| R-010 | Dépendance forte à un fournisseur LLM. | Coût, disponibilité | Abstraction de fournisseur. |
| R-011 | Le moteur tactique temps réel bloque le calendrier. | Partie bloquée | Timeout, résolution automatique, file d'attente (ADR-0005). |
| R-012 | Impossible de sauvegarder ou rejouer une bataille. | Fiabilité, litiges | Journal de commandes, pas fixes, résultat canonique. |
| R-013 | Le multijoueur est rendu coûteux par un couplage solo. | Dette | Session de bataille isolée, transport abstrait. |
| R-014 | Coût de conception de tous les systèmes. | Retard, scope creep | Priorité validée de PROJECT.md § 17 ; MVP réduit. |

## 8. Options d'architecture à étudier

| Option | Avantages | Inconvénients | Statut |
|---|---|---|---|
| Monolithe modulaire | Simple, rapide à démarrer, débogage facile | Extensibilité à grande échelle limitée | **À évaluer** |
| Services séparés (règles / IA / API / bataille) | Isolation, scaling | Complexité opérationnelle | **À évaluer** |
| Moteur de jeu existant | Rendu et outils fournis | Dépendance, courbe d'apprentissage, inadapté au serveur | **À évaluer** |
| Application web pure | Déploiement facile, asynchrone naturel | Rendu 2D/3D limité | **À évaluer** |
| Desktop natif | Performance, offline | Distribution, multijoueur plus complexe | **À évaluer** |
| Moteur de bataille séparé du jeu stratégique | Isole le temps réel, prépare le multijoueur | Deux runtimes à maintenir | **À évaluer** |

Aucune option n'est retenue. Voir [technical-decisions.md](technical-decisions.md).

## 9. Questions ouvertes

- Q-002 : périmètre exact du MVP (bloquante).
- Q-007 : quelle plateforme ?
- Q-008 : quel langage / moteur ? (bloquante, étude requise)
- Q-009 : quelle persistance ?
- Q-010 : quels fournisseurs LLM et quels coûts ?
- Q-012 : comment garantir l'étanchéité informationnelle des IA ?
- Q-023 : quel budget d'infrastructure ?
- Q-026 : quel périmètre juridique pour l'inspiration HoI4 / Lines of Battle ?

Q-005 (rythme) est tranchée (tour mensuel) ; Q-006 (solo/multijoueur) est tranchée (solo prioritaire, multijoueur anticipé). Liste complète : [PROJECT.md § 20.4](../../PROJECT.md#204-questions-encore-ouvertes).

## 10. Critères pour passer au statut « Spécifié »

- [ ] Q-002, Q-007, Q-008, Q-009 tranchées par le propriétaire.
- [ ] ADR d'architecture accepté (monolithe vs services, frontières).
- [ ] Contrat de session de bataille défini (ADR-0005 accepté ou remplacé).
- [ ] Modèle de données conceptuel validé.
- [ ] Stratégie de persistance et de replay validée.
- [ ] Contrat d'interface IA validé.
- [ ] Un prototype de résolution d'ordres existe et est testé.

Tant que ces critères ne sont pas remplis, ce document reste un document de cadrage.
