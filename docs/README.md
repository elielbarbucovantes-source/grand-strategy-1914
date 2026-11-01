# Index de la documentation

> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Cadre de référence :** [PROJECT.md](../PROJECT.md) v0.2.4

Ce dossier contient la documentation de conception et de gouvernance du projet. **Un MVP jouable est implémenté** dans [`game/`](../game/) depuis le 2026-11-01 (voir [ADR-0006](decisions/0006-pile-technique-mvp.md)) : il couvre la boucle stratégique, une IA minimale et une interface web. Les documents de cadrage décrivent la cible, pas l'état exact du MVP ; les valeurs provisoires sont dans [DECISIONS_PENDING.md](../DECISIONS_PENDING.md).

**Cohérence :** la fiche maîtresse du propriétaire (PROJECT.md v0.2.4) fixe le cadre du jeu. Les documents thématiques ont été alignés sur ce cadre en 2026-10-31 (tâche **T-031**) : ils reprennent les décisions validées D-001 à D-029, signalent les tensions C-01 à C-18 de la [revue de conception](design-review-v0.1.md) et distinguent explicitement ce qui reste **[À DÉFINIR]**. La décision D-031 autorise le MVP et délègue les choix techniques ordinaires. Les documents thématiques restent des documents de **cadrage** : aucun système complet n'est spécifié ni validé.

## Règles de lecture

- Les documents racine font autorité : [AGENTS.md](../AGENTS.md), [PROJECT.md](../PROJECT.md), [PROGRESS.md](../PROGRESS.md).
- Les étiquettes **[VALIDÉ]**, **[PROPOSITION]**, **[HYPOTHÈSE]**, **[À DÉFINIR]** ont la même signification que dans PROJECT.md.
- Un document thématique ne peut pas contredire un ADR accepté. En cas de contradiction, l'ADR prévaut et la contradiction doit être signalée.
- Un ADR **proposé** (ADR-0005) ne vaut pas décision : les documents qui le citent ne doivent pas le présenter comme tranché.
- Les liens croisés doivent être maintenus ; un document orphelin ou un lien mort est un défaut à corriger.

## Cartographie

### Cadre de conception et gouvernance

| Document | Objet |
|---|---|
| [founding-document-v0.1.md](founding-document-v0.1.md) | Document fondateur du propriétaire, conservé intégralement et gelé par empreinte SHA-256. |
| [design-review-v0.1.md](design-review-v0.1.md) | Revue critique du document fondateur : tensions C-01 à C-18, vigilances V-01 à V-08. Ne tranche rien. |
| [decisions/README.md](decisions/README.md) | Règles des ADR, index, statuts. |
| [decisions/0000-template.md](decisions/0000-template.md) | Modèle à copier pour un nouvel ADR. |
| [decisions/0001-documentation-et-git-comme-socle.md](decisions/0001-documentation-et-git-comme-socle.md) | Documentation et Git comme socle de collaboration. |
| [decisions/0002-interoperabilite-multi-agents.md](decisions/0002-interoperabilite-multi-agents.md) | Interopérabilité multi-agents via un fichier de règles unique. |
| [decisions/0003-report-du-choix-de-pile-technique.md](decisions/0003-report-du-choix-de-pile-technique.md) | Report du choix de pile technique. |
| [decisions/0004-adoption-du-document-fondateur.md](decisions/0004-adoption-du-document-fondateur.md) | Adoption du document fondateur comme source de conception (accepté, avec réserve sur le cahier des charges). |
| [decisions/0005-integration-strategique-tactique.md](decisions/0005-integration-strategique-tactique.md) | Intégration du temps stratégique et tactique (**proposé**, ne vaut pas décision). |
| [decisions/0006-pile-technique-mvp.md](decisions/0006-pile-technique-mvp.md) | Pile technique du premier MVP jouable (Python 3.12, web natif, JSON, `unittest`). |

### Architecture

| Document | Objet |
|---|---|
| [architecture/overview.md](architecture/overview.md) | Décomposition logique proposée, frontières, flux, moteur de bataille isolé, risques. |
| [architecture/technical-decisions.md](architecture/technical-decisions.md) | Registre des choix techniques : décisions provisoires du MVP (ADR-0006), choix encore ouverts (TD-001 à TD-027) et contraintes fixées (CT-001 à CT-010). |
| [architecture/data-model.md](architecture/data-model.md) | Modèle conceptuel préliminaire, invariants, visibilité, questions ouvertes. |

### Nations et politique intérieure

| Document | Objet |
|---|---|
| [nations/nations.md](nations/nations.md) | Profils initiaux des sept puissances en 1914 : identité, douze caractéristiques, forces, faiblesses, armées, économie, diplomatie, ambitions, colonies. |
| [nations/regimes.md](nations/regimes.md) | Politique intérieure, changements de régime, conditions et conséquences. |

### Gameplay

| Document | Objet |
|---|---|
| [gameplay/rules.md](gameplay/rules.md) | Boucle de jeu, phases, ordres, résolution simultanée, victoire, visibilité. |
| [gameplay/map-system.md](gameplay/map-system.md) | Provinces, adjacences, attributs, ressources, fortifications, formats de carte. |

### Militaire

| Document | Objet |
|---|---|
| [military/strategic-warfare.md](military/strategic-warfare.md) | Guerre stratégique : formations, fronts, offensives, occupation, pertes, fortifications. |
| [military/tactical-battles.md](military/tactical-battles.md) | Batailles tactiques indépendantes, conversion des forces, terrain, contrôle, sauvegarde. |

### Économie

| Document | Objet |
|---|---|
| [economy/economy-system.md](economy/economy-system.md) | Trois ressources par territoire, production, budget, industrie, niveau de vie, commerce. |

### Recherche et renseignement

| Document | Objet |
|---|---|
| [technology/research-system.md](technology/research-system.md) | Arbre technologique 1914-1945, prérequis, avance, spécialisations nationales. |
| [intelligence/intelligence-system.md](intelligence/intelligence-system.md) | Renseignement classique, interception, cryptographie, espionnage industriel, rapports. |

### Diplomatie

| Document | Objet |
|---|---|
| [diplomacy/treaties.md](diplomacy/treaties.md) | Deux catégories d'accords, types, cycle de vie, rupture, application par le moteur. |
| [diplomacy/negotiations.md](diplomacy/negotiations.md) | Canaux, propositions officielles, protocole, mensonge, sécurité des messages. |
| [diplomacy/alliances.md](diplomacy/alliances.md) | Coalitions, coordination, dissolution, trahison, victoire partagée. |
| [diplomacy/reputation.md](diplomacy/reputation.md) | Confiance, mémoire des engagements, coût de la trahison, lisibilité. |

### Intelligence artificielle

| Document | Objet |
|---|---|
| [ai/ai-architecture.md](ai/ai-architecture.md) | Composants et flux d'un agent IA autonome, non omniscient. |
| [ai/personalities.md](ai/personalities.md) | Traits, cohérence, diversité des dirigeants. |
| [ai/memory-system.md](ai/memory-system.md) | Mémoire longue, rétention, oubli, coût. |
| [ai/decision-making.md](ai/decision-making.md) | Perception filtrée, analyse, planification, ordres, validation. |
| [ai/multi-agent-interactions.md](ai/multi-agent-interactions.md) | Protocole, coalitions, sécurité, observabilité, reproductibilité. |

### Développement

| Document | Objet |
|---|---|
| [development/coding-standards.md](development/coding-standards.md) | Conventions, qualité, dépendances, secrets. |
| [development/testing-strategy.md](development/testing-strategy.md) | Niveaux de test, preuves, évaluation des IA. |
| [development/contribution-guide.md](development/contribution-guide.md) | Workflow Git, réservation, revue, conflits. |

## Ajouter un document

1. Vérifier qu'il n'existe pas déjà.
2. Créer le fichier avec l'en-tête standard (statut, date, auteur, source de conception, documents liés).
3. L'ajouter à cet index.
4. Mettre à jour les liens depuis les documents concernés.
5. Signer l'intervention dans PROGRESS.md.

## En-tête standard

```markdown
# Titre

> **Statut :** Cadrage | Spécifié | En développement | Implémenté | Vérifié
> **Dernière mise à jour :** AAAA-MM-JJ
> **Dernière modification par :** <outil ou personne>
> **Source de conception :** PROJECT.md § … · docs/founding-document-v0.1.md § …
> **Documents liés :** ...
```

« Cadrage » signifie que le document pose les questions et le périmètre, pas que le système est conçu.
