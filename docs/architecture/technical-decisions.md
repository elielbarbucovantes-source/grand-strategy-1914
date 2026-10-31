# Décisions techniques — registre des choix ouverts

> **Statut :** Cadrage — aucun choix technique validé
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [overview.md](overview.md) · [data-model.md](data-model.md) · [ADR-0003](../decisions/0003-report-du-choix-de-pile-technique.md) · [PROJECT.md](../../PROJECT.md)

---

## 1. Objet

Ce document est le **registre de travail** des décisions techniques. Il ne remplace pas les ADR : il sert à voir d'un coup d'œil ce qui est décidé, ce qui est ouvert et ce qui bloque.

Règles :

- Une ligne `Décidé` doit pointer vers un ADR accepté.
- Une ligne `Ouvert` ne doit pas être interprétée comme un choix par défaut.
- Aucun agent ne peut passer une ligne à `Décidé` sans ADR et validation du propriétaire lorsque la décision est structurante.

## 2. Processus de décision

1. Identifier le besoin et les contraintes.
2. Rédiger une étude comparative (options, critères, coûts, risques).
3. Créer un ADR à l'état `proposé`.
4. Recueillir l'avis du propriétaire.
5. Si accepté : passer l'ADR à `accepté`, mettre à jour ce registre et les documents impactés.
6. Si rejeté : consigner la raison dans l'ADR.

## 3. Critères d'évaluation communs

- adéquation au type de jeu et au rythme visé ;
- simplicité de mise en œuvre pour un MVP ;
- testabilité et déterminisme ;
- performance et coût d'exploitation ;
- écosystème, documentation, maintenance ;
- disponibilité des compétences (agents et propriétaire) ;
- licences compatibles ;
- réversibilité et coût de sortie ;
- sécurité ;
- accessibilité et internationalisation.

## 4. Registre

| ID | Sujet | Options envisagées | Statut | ADR | Bloquant pour |
|---|---|---|---|---|---|
| TD-001 | Langage principal | À étudier | **Ouvert** | — | Tout le code |
| TD-002 | Type d'application (web, desktop, hybride) | À étudier | **Ouvert** | — | UI, distribution |
| TD-003 | Moteur de jeu / rendu | Moteur existant, rendu custom, pas de rendu 3D | **Ouvert** | — | UI, assets |
| TD-004 | Architecture applicative | Monolithe modulaire, services | **Ouvert** | — | Déploiement |
| TD-005 | Base de données / persistance | Relationnel, document, événementiel, fichiers | **Ouvert** | — | Sauvegardes, reprise |
| TD-006 | Format de sauvegarde | À étudier | **Ouvert** | — | Replay, compatibilité |
| TD-007 | Journal d'événements | Append-only, event sourcing complet, autre | **Ouvert** | — | Audit, replay, IA |
| TD-008 | Transport client-serveur | HTTP, WebSocket, autre | **Ouvert** | — | Multijoueur |
| TD-009 | Authentification / comptes | À étudier | **Ouvert** | — | Multijoueur |
| TD-010 | Intégration LLM | API distante, local, hybride, abstraction multi-fournisseur | **Ouvert** | — | IA |
| TD-011 | Framework de test | À étudier selon le langage | **Ouvert** | — | Qualité |
| TD-012 | Format de carte | JSON/YAML déclaratif, binaire, éditeur dédié | **Ouvert** | — | Gameplay |
| TD-013 | CI/CD | À étudier | **Ouvert** | — | Qualité, releases |
| TD-014 | Hébergement | À étudier | **Ouvert** | — | Exploitation |
| TD-015 | Observabilité | Logs, métriques, traces | **Ouvert** | — | Exploitation, debug IA |
| TD-016 | Formatage / lint | À étudier selon le langage | **Ouvert** | — | Style |
| TD-017 | Gestion des dépendances | À étudier selon le langage | **Ouvert** | — | Sécurité |
| TD-018 | Stratégie de versionnement du jeu et des règles | SemVer, version de règles séparée | **Ouvert** | — | Compatibilité des sauvegardes |
| TD-019 | Licence du code et des assets | À étudier | **Ouvert** | — | Publication |
| TD-020 | Modèle économique / accès | À définir par le propriétaire | **Ouvert** | — | Produit |

## 5. Contraintes déjà fixées

| ID | Contrainte | Source |
|---|---|---|
| C-001 | Aucun moteur/framework choisi sans étude préalable. | D-005 / ADR-0003 |
| C-002 | Le noyau de règles doit rester indépendant des IA et de l'interface. | Proposition d'architecture (non validée) |
| C-003 | Aucun secret dans le dépôt. | D-008 |
| C-004 | Licences vérifiées avant intégration. | AGENTS.md § 10 |
| C-005 | Toute décision structurante passe par un ADR. | AGENTS.md § 11 |

C-002 est une **proposition**, pas une décision validée. Elle est listée ici pour être discutée explicitement.

## 6. Dépendances entre décisions

```
TD-001 (langage)
  ├── TD-011 (tests)
  ├── TD-016 (lint)
  └── TD-017 (dépendances)

TD-002 (type d'app)
  ├── TD-003 (moteur/rendu)
  └── TD-008 (transport)

TD-005 (persistance)
  ├── TD-006 (sauvegarde)
  └── TD-018 (versionnement)

TD-010 (LLM)
  └── budget Q-023, confidentialité Q-011
```

Une décision peut être prise indépendamment si ses dépendances sont explicitement provisionnées.

## 7. Questions à trancher avant toute implémentation

1. Le jeu est-il jouable sans interface graphique lourde (MVP web ou CLI) ?
2. Une partie doit-elle pouvoir être rejouée à l'identique des années plus tard ?
3. Les règles doivent-elles être modifiables par des tiers ?
4. Les IA doivent-elles fonctionner hors ligne / avec des modèles locaux ?
5. Quel est le budget maximal par partie et par mois ?
6. Quelles données de joueurs sont conservées et pendant combien de temps ?
7. Le jeu doit-il fonctionner sur mobile ?

## 8. Ce que ce document n'est pas

- Ce n'est pas une recommandation déguisée : l'ordre des lignes n'indique aucune préférence.
- Ce n'est pas un plan de développement.
- Ce n'est pas un engagement de délai.
