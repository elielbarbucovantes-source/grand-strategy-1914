# Décisions techniques — registre des choix ouverts

> **Statut :** Cadrage — aucun choix technique validé
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [overview.md](overview.md) · [data-model.md](data-model.md) · [ADR-0003](../decisions/0003-report-du-choix-de-pile-technique.md) · [ADR-0005](../decisions/0005-integration-strategique-tactique.md) · [PROJECT.md](../../PROJECT.md)

---

## 1. Objet

Ce document est le **registre de travail** des décisions techniques. Il ne remplace pas les ADR : il sert à voir d'un coup d'œil ce qui est décidé, ce qui est ouvert et ce qui bloque.

Règles :

- Une ligne `Décidé` doit pointer vers un ADR accepté.
- Une ligne `Ouvert` ne doit pas être interprétée comme un choix par défaut.
- Aucun agent ne peut passer une ligne à `Décidé` sans ADR et validation du propriétaire lorsque la décision est structurante.

**Note de révision (2026-10-31) :** les contraintes étaient numérotées `C-001` à `C-005`, ce qui entrait en collision avec les tensions `C-01` à `C-18` de [design-review-v0.1.md](../design-review-v0.1.md). Elles sont renommées `CT-001` et suivantes. Les sources incorrectes ont été corrigées (les lignes `D-005` et `D-008` ne correspondaient pas aux règles citées).

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
| TD-003 | Moteur de jeu / rendu stratégique | Moteur existant, rendu custom, 2D | **Ouvert** | — | UI, assets |
| TD-004 | Architecture applicative | Monolithe modulaire, services | **Ouvert** | — | Déploiement |
| TD-005 | Base de données / persistance | Relationnel, document, événementiel, fichiers | **Ouvert** | — | Sauvegardes, reprise |
| TD-006 | Format de sauvegarde | À étudier | **Ouvert** | — | Replay, compatibilité |
| TD-007 | Journal d'événements | Append-only, event sourcing complet, autre | **Ouvert** | — | Audit, replay, IA |
| TD-008 | Transport client-serveur | HTTP, WebSocket, autre | **Ouvert** | — | Multijoueur |
| TD-009 | Authentification / comptes | À étudier | **Ouvert** | — | Multijoueur |
| TD-010 | Intégration LLM | API distante, local, hybride, abstraction multi-fournisseur | **Ouvert** | — | IA |
| TD-011 | Framework de test | À étudier selon le langage | **Ouvert** | — | Qualité |
| TD-012 | Format de carte stratégique | JSON/YAML déclaratif, binaire, éditeur dédié | **Ouvert** | — | Gameplay |
| TD-013 | CI/CD | À étudier | **Ouvert** | — | Qualité, releases |
| TD-014 | Hébergement | À étudier | **Ouvert** | — | Exploitation |
| TD-015 | Observabilité | Logs, métriques, traces | **Ouvert** | — | Exploitation, debug IA |
| TD-016 | Formatage / lint | À étudier selon le langage | **Ouvert** | — | Style |
| TD-017 | Gestion des dépendances | À étudier selon le langage | **Ouvert** | — | Sécurité |
| TD-018 | Stratégie de versionnement du jeu et des règles | SemVer, version de règles séparée | **Ouvert** | — | Compatibilité des sauvegardes |
| TD-019 | Licence du code et des assets | À étudier | **Ouvert** | — | Publication |
| TD-020 | Modèle économique / accès | À définir par le propriétaire | **Ouvert** | — | Produit |
| TD-021 | Moteur de bataille tactique | Moteur dédié, mode du moteur principal, middleware | **Ouvert** | — | Batailles 30 min, multijoueur |
| TD-022 | Contrat de session de bataille | Instantané + commandes + résultat ; événements ; replay | **Ouvert** | ADR-0005 (proposé) | Synchronisation stratégique/tactique |
| TD-023 | Conversion stratégique ↔ tactique | Points de force, table, coefficients | **Ouvert** | — | Batailles, pertes, équilibre |
| TD-024 | Modèle de temps réel | Pas fixes, horloge serveur, pause, timers | **Ouvert** | — | Bataille, replay, multijoueur |
| TD-025 | Rendu 2D de la carte | Bibliothèque, moteur 2D, rendu custom | **Ouvert** | — | UI stratégique |
| TD-026 | Sous-système de renseignement | Messages chiffrés, accès, journal d'interception | **Ouvert** | — | Confidentialité, équité |
| TD-027 | Format des données historiques | Sources, licences, noms, provinces | **Ouvert** | — | Carte, nations, publication |

## 5. Contraintes déjà fixées

| ID | Contrainte | Source |
|---|---|---|
| CT-001 | Aucun moteur/framework choisi sans étude préalable. | PROJECT.md § 21, ADR-0003 |
| CT-002 | Le noyau de règles doit rester indépendant des IA et de l'interface. | Proposition d'architecture (non validée) |
| CT-003 | Aucun secret dans le dépôt. | AGENTS.md § 9 |
| CT-004 | Licences vérifiées avant intégration. | AGENTS.md § 10 |
| CT-005 | Toute décision structurante passe par un ADR. | AGENTS.md § 11 |
| CT-006 | Le calendrier stratégique reste mensuel et à résolution simultanée. | D-006, PROJECT.md § 5 |
| CT-007 | Les batailles tactiques durent 30 minutes maximum. | D-014, PROJECT.md § 8.3 |
| CT-008 | L'architecture doit anticiper le multijoueur sans l'exiger en v1. | D-026, PROJECT.md § 16 |
| CT-009 | Une IA ne reçoit jamais l'état complet du jeu. | D-011, Q-012 |
| CT-010 | Les communications sont confidentielles par défaut ; l'interception est une exception. | D-008, D-023 |

CT-002 est une **proposition**, pas une décision validée. Elle est listée ici pour être discutée explicitement.

## 6. Dépendances entre décisions

```
TD-001 (langage)
  ├── TD-011 (tests)
  ├── TD-016 (lint)
  └── TD-017 (dépendances)

TD-002 (type d'app)
  ├── TD-003 (moteur/rendu stratégique)
  ├── TD-025 (rendu 2D)
  └── TD-008 (transport)

TD-005 (persistance)
  ├── TD-006 (sauvegarde)
  └── TD-018 (versionnement)

TD-021 (moteur de bataille)
  ├── TD-022 (contrat de session)
  ├── TD-023 (conversion)
  └── TD-024 (temps réel)

TD-010 (LLM)
  └── budget Q-023, confidentialité Q-011
```

Une décision peut être prise indépendamment si ses dépendances sont explicitement provisionnées.

## 7. Questions à trancher avant toute implémentation

1. Le jeu est-il jouable sans interface graphique lourde (MVP web ou CLI) ?
2. Une partie doit-elle pouvoir être rejouée à l'identique des années plus tard ?
3. Les règles doivent-elles être modifiables par des tiers (Q-018) ?
4. Les IA doivent-elles fonctionner hors ligne / avec des modèles locaux (Q-011) ?
5. Quel est le budget maximal par partie et par mois (Q-023) ?
6. Quelles données de joueurs sont conservées et pendant combien de temps (Q-024) ?
7. Le jeu doit-il fonctionner sur mobile (Q-007) ?
8. Une bataille doit-elle être sauvegardable, pausable et rejouable (C-15) ?
9. Combien de batailles simultanées un joueur peut-il commander (C-02) ?
10. Comment le calendrier stratégique attend-il une bataille (C-01) ?

## 8. Ce que ce document n'est pas

- Ce n'est pas une recommandation déguisée : l'ordre des lignes n'indique aucune préférence.
- Ce n'est pas un plan de développement.
- Ce n'est pas un engagement de délai.
