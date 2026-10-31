# Index de la documentation

> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode

Ce dossier contient la documentation de conception et de gouvernance du projet. **Aucun système décrit ici n'est implémenté.** Les documents de cadrage listent les objectifs, les hypothèses, les questions ouvertes et les éléments à définir.

**Cohérence :** la fiche maîtresse du propriétaire (PROJECT.md v0.2.0, 2026-10-31) fixe désormais le cadre du jeu. Les documents thématiques ont été rédigés avant elle : plusieurs de leurs hypothèses sont tranchées ou contredites. Ils ne font plus autorité ; les plus directement concernés portent une note de cohérence. Leur alignement est la tâche **T-031** de [PROGRESS.md](../PROGRESS.md).

## Règles de lecture

- Les documents racine font autorité : [AGENTS.md](../AGENTS.md), [PROJECT.md](../PROJECT.md), [PROGRESS.md](../PROGRESS.md).
- Les étiquettes **[VALIDÉ]**, **[PROPOSITION]**, **[HYPOTHÈSE]**, **[À DÉFINIR]** ont la même signification que dans PROJECT.md.
- Un document thématique ne peut pas contredire un ADR accepté. En cas de contradiction, l'ADR prévaut et la contradiction doit être signalée.
- Les liens croisés doivent être maintenus ; un document orphelin ou un lien mort est un défaut à corriger.

## Cartographie

### Architecture

| Document | Objet |
|---|---|
| [architecture/overview.md](architecture/overview.md) | Décomposition logique proposée, frontières, flux, risques. |
| [architecture/technical-decisions.md](architecture/technical-decisions.md) | Registre des choix techniques ouverts et critères d'évaluation. |
| [architecture/data-model.md](architecture/data-model.md) | Modèle conceptuel préliminaire, invariants, questions ouvertes. |

### Gameplay

| Document | Objet |
|---|---|
| [gameplay/rules.md](gameplay/rules.md) | Boucle de jeu, phases, ordres, résolution, victoire. |
| [gameplay/map-system.md](gameplay/map-system.md) | Territoires, adjacences, centres, formats de carte. |
| [gameplay/military-system.md](gameplay/military-system.md) | Unités, mouvement, soutien, attrition. |
| [gameplay/economy-system.md](gameplay/economy-system.md) | Ressources et production (existence confirmée par la fiche maîtresse ; à réviser). |

### Diplomatie

| Document | Objet |
|---|---|
| [diplomacy/treaties.md](diplomacy/treaties.md) | Types de traités, cycle de vie, rupture, application. |
| [diplomacy/negotiations.md](diplomacy/negotiations.md) | Canaux, propositions, tours, protocole de messages. |
| [diplomacy/alliances.md](diplomacy/alliances.md) | Coalitions, coordination, victoire partagée. |
| [diplomacy/reputation.md](diplomacy/reputation.md) | Confiance, mémoire sociale, conséquences. |

### Intelligence artificielle

| Document | Objet |
|---|---|
| [artificial-intelligence/ai-architecture.md](artificial-intelligence/ai-architecture.md) | Pipeline perception → mémoire → décision → action. |
| [artificial-intelligence/personalities.md](artificial-intelligence/personalities.md) | Traits, cohérence, diversité des agents. |
| [artificial-intelligence/memory-system.md](artificial-intelligence/memory-system.md) | Mémoire épisodique, sociale, résumé, oubli. |
| [artificial-intelligence/decision-making.md](artificial-intelligence/decision-making.md) | Planification, rôle des LLM, validation des ordres. |
| [artificial-intelligence/multi-agent-interactions.md](artificial-intelligence/multi-agent-interactions.md) | Protocole, coalitions, sécurité, observabilité. |

### Développement

| Document | Objet |
|---|---|
| [development/coding-standards.md](development/coding-standards.md) | Conventions, qualité, dépendances, secrets. |
| [development/testing-strategy.md](development/testing-strategy.md) | Niveaux de test, preuves, évaluation des IA. |
| [development/contribution-guide.md](development/contribution-guide.md) | Workflow Git, réservation, revue, conflits. |

### Décisions

| Document | Objet |
|---|---|
| [decisions/README.md](decisions/README.md) | Règles des ADR, index, statuts. |
| [decisions/0000-template.md](decisions/0000-template.md) | Modèle à copier pour un nouvel ADR. |

## Ajouter un document

1. Vérifier qu'il n'existe pas déjà.
2. Créer le fichier avec l'en-tête standard (statut, date, auteur, documents liés).
3. L'ajouter à cet index.
4. Mettre à jour les liens depuis les documents concernés.
5. Signer l'intervention dans PROGRESS.md.

## En-tête standard

```markdown
# Titre

> **Statut :** Cadrage | Spécifié | En développement | Implémenté | Vérifié
> **Dernière mise à jour :** AAAA-MM-JJ
> **Dernière modification par :** <outil ou personne>
> **Documents liés :** ...
```

« Cadrage » signifie que le document pose les questions et le périmètre, pas que le système est conçu.
