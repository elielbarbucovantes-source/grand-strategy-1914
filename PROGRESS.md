# PROGRESS.md — Tableau de bord permanent

> **Version :** 0.1.0
> **Dernière mise à jour :** 2026-10-31
> **Dernier agent intervenu :** OpenCode
> **Phase actuelle :** Phase 0 — Fondations documentaires (terminée)
> **Prochaine phase :** Phase 1 — Cadrage produit (non démarrée)

> **À lire avant toute intervention.** Ce document décrit l'état réel du projet. Il ne remplace pas Git. Toute modification doit respecter [AGENTS.md](AGENTS.md) § 7.3 (mise à jour séquentielle).

---

## A. État général

| Élément | Valeur |
|---|---|
| Phase actuelle | Phase 0 — Fondations documentaires, **terminée** |
| Avancement des fonctionnalités de jeu | **0 fonctionnalité terminée** |
| Backlog fonctionnel de jeu | **Non défini** : aucun pourcentage global ne peut être calculé honnêtement |
| Livrables d'infrastructure | **2 / 2 vérifiés** (INF-001, INF-002) |
| Dernière mise à jour | 2026-10-31 |
| Dernier agent intervenu | OpenCode |
| Stabilité du projet | **Stable** : aucun code exécutable, aucun conflit Git, documentation vérifiée structurellement |
| Dépôt Git | Initialisé, branche `main`, aucun historique antérieur |

### Méthode de calcul de l'avancement

- **Avancement jeu** = fonctionnalités de jeu terminées / fonctionnalités de jeu planifiées.
  Le backlog fonctionnel n'existe pas encore ; le dénominateur est inconnu. **Aucun pourcentage de jeu n'est affiché.**
- **Avancement infrastructure** = livrables d'infrastructure vérifiés / livrables d'infrastructure définis.
  Aujourd'hui : 2 / 2. Ce chiffre ne mesure **pas** l'avancement du jeu.
- Aucun pourcentage arbitraire, aucune estimation subjective.

### État de stabilité

- Aucun code exécutable : aucun bug logiciel possible à ce stade.
- Documentation créée et vérifiée par script (structure et liens).
- Aucune décision technique de jeu prise.
- Aucun travail non sauvegardé.
- Risque principal : démarrer le développement avant d'avoir tranché le périmètre (voir section F).

---

## B. Fonctionnalités terminées

### B.1 Fonctionnalités du jeu

**Aucune.** Aucune règle, aucun moteur, aucune interface, aucune IA n'est implémenté.

| Nom | Description | Date | Agent | Tests | Limitations |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

### B.2 Livrables d'infrastructure

| ID | Nom | Description | Date | Agent | Tests effectués | Limitations |
|---|---|---|---|---|---|---|
| INF-001 | Infrastructure documentaire | Création des documents de référence, de la documentation thématique, des ADR et des dossiers de base. | 2026-10-31 | OpenCode | Vérification de présence, de non-vacuité et des liens par `scripts/check-infrastructure.sh` ; inspection manuelle de la cohérence. | Les documents sont des documents de **cadrage**, pas des spécifications validées. La cohérence sémantique n'est pas vérifiée automatiquement. |
| INF-002 | Script de vérification | `scripts/check-infrastructure.sh` : contrôle des fichiers, dossiers, sections obligatoires, champs d'ADR, liens relatifs, secrets et état Git. | 2026-10-31 | OpenCode | Exécution réelle : voir journal section G. | Ne vérifie pas le sens du contenu ni l'exactitude des décisions. Pas encore intégré à une CI. |

---

## C. Travaux en cours

**Aucun travail en cours.**

La phase 0 est clôturée. Aucune tâche n'est réservée. Le prochain agent doit choisir une tâche dans la section D et l'annoncer ici avant de commencer.

### Modèle d'entrée (à utiliser pour toute nouvelle tâche)

```markdown
### T-XXX — Titre

- **Responsable :** <nom réel de l'outil>
- **Date de début :** AAAA-MM-JJ
- **Fichiers concernés :** ...
- **Dépendances :** ...
- **État actuel :** En cours
- **Prochaine étape :** ...
```

---

## D. Travaux à effectuer

### P0 — Bloquant / indispensable

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-001 | Valider la vision et le périmètre du MVP | Le propriétaire tranche Q-002 : ce que le MVP doit démontrer, ce qu'il exclut. | Aucune | **À faire — propriétaire** |
| T-002 | Trancher la relation à Diplomacy | Décider Q-003 : reprise fidèle, adaptation libre ou inspiration thématique. Impacte règles, carte, juridique. | Aucune | **À faire — propriétaire** |
| T-003 | Trancher le rythme de partie | Décider Q-005 : temps réel, tour par tour, asynchrone ou hybride. Impacte architecture et IA. | T-001, T-002 | **À faire — propriétaire** |
| T-004 | Étude de pile technique + ADR | Comparer les options (langage, application, moteur, persistance) et produire un ADR. Ne rien implémenter avant validation. | T-001 à T-003 | **À faire — agent** |
| T-005 | Spécifier les règles de base v0.1 | Compléter `docs/gameplay/rules.md` : ordres, résolution, victoire, visibilité. | T-002, T-003 | **À faire — agent** |

### P1 — Haute priorité

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-006 | Modèle de données v0.2 | Passer du modèle conceptuel à un modèle validé, avec événements et invariants. | T-005 | À faire |
| T-007 | Contrat d'interface IA + frontière informationnelle | Spécifier perceptions, entrées/sorties, garanties d'étanchéité. | T-005 | À faire |
| T-008 | Format de carte + validateur | Choisir un format déclaratif, définir les contrôles, produire une carte de test. | T-005 | À faire |
| T-009 | Spécifier traités et négociations | Structure des clauses, cycle de vie, canaux, timeouts, trahison. | T-005 | À faire |
| T-010 | Harnais d'évaluation des IA | Scénarios reproductibles, métriques, comparaison de versions. | T-007 | À faire |

### P2 — Priorité normale

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-011 | Persistance et replay | ADR sur sauvegarde, journal, versionnement, compatibilité. | T-004, T-006 | À faire |
| T-012 | Personnalités et mémoire | Spécifier traits, génération, mémoire, oubli, coûts. | T-007 | À faire |
| T-013 | Étude UI/UX | Support, lisibilité, informations visibles, accessibilité. | T-004 | À faire |
| T-014 | Observabilité | Logs, métriques, traces, audit des décisions IA. | T-004 | À faire |

### P3 — Amélioration facultative

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-015 | Modding | Étudier l'ouverture des règles et des cartes. | T-005, T-008 | À faire |
| T-016 | Localisation | Choisir les langues et le mécanisme i18n. | T-013 | À faire |
| T-017 | Accessibilité | Contraste, navigation clavier, lisibilité. | T-013 | À faire |
| T-018 | Éditeur de carte | Outil interne ou externe. | T-008 | À faire |

---

## E. Bugs et problèmes connus

### E.1 Bugs logiciels

**Aucun bug logiciel connu.** Il n'existe aucun code exécutable.

| ID | Description | Gravité | Origine | Reproduction | État | Responsable |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

### E.2 Limitations connues de l'infrastructure

| ID | Problème | Gravité | Origine | État | Responsable |
|---|---|---|---|---|---|
| L-001 | Le script vérifie la structure et les liens, pas la cohérence sémantique des documents. | Faible | Limite de l'automatisation | Connu, accepté | OpenCode |
| L-002 | Aucune CI n'exécute le script automatiquement. | Moyenne | Pile technique non choisie | Ouvert | À assigner |
| L-003 | La protection de branche et la revue obligatoire ne sont pas configurées côté hébergeur. | Moyenne | Dépôt local, pas de remote | Ouvert | Propriétaire |
| L-004 | L'identité formelle du propriétaire et le canal d'arbitrage ne sont pas définis. | Moyenne | Information manquante | Ouvert — voir Q-025 | Propriétaire |
| L-005 | Aucun glossaire commun n'existe encore ; certains termes peuvent être interprétés différemment. | Faible | Cadrage initial | Ouvert | À assigner |

### E.3 Risques suivis (rappel)

Les risques architecturaux sont détaillés dans [docs/architecture/overview.md § 7](docs/architecture/overview.md#7-risques-architecturaux-identifiés). Ils ne sont pas des bugs.

---

## F. Prochaines étapes

Cinq prochaines tâches recommandées, dans l'ordre :

| # | Tâche | Responsable | Dépendances | Pourquoi maintenant |
|---|---|---|---|---|
| 1 | **T-001** — Valider le périmètre du MVP | Propriétaire | Aucune | Tout le reste en dépend ; sans périmètre, les choix techniques seraient arbitraires. |
| 2 | **T-002** — Trancher la relation à Diplomacy | Propriétaire | Aucune | Conditionne les règles, la carte et le risque juridique. |
| 3 | **T-003** — Trancher le rythme de partie | Propriétaire | T-001, T-002 | Conditionne l'architecture, le rythme des IA et les coûts. |
| 4 | **T-005** — Spécifier les règles de base v0.1 | Agent (OpenCode/Codex/Claude Code) | T-002, T-003 | Permet de tester le noyau et de préparer T-004. |
| 5 | **T-004** — Étude de pile technique + ADR | Agent | T-001 à T-003 | À réaliser avec un périmètre clair, pas avant. |

**Point de blocage actuel :** les décisions T-001 à T-003 appartiennent au propriétaire. Aucun agent ne doit les prendre à sa place. En attendant, un agent peut préparer des options documentées, sans les présenter comme validées.

---

## G. Journal des interventions

| Date | Agent | Intervention | Fichiers | Tests | Résultat |
|---|---|---|---|---|---|
| 2026-10-31 | OpenCode | Création de l'infrastructure documentaire initiale : documents de référence, documentation thématique, ADR 0001–0003, script de vérification, initialisation Git. | `AGENTS.md`, `PROJECT.md`, `PROGRESS.md`, `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `.gitignore`, `.env.example`, `docs/**`, `scripts/check-infrastructure.sh`, `src/README.md`, `tests/README.md`, `assets/README.md` | `./scripts/check-infrastructure.sh` — 67 vérifications, 0 échec (après correction d'un lien cassé) ; `git status` — vérification avant commit. | Terminé |

> Le journal est append-only. Ne jamais supprimer ni réécrire une ligne existante. Une correction s'ajoute avec une référence à la ligne corrigée.

---

## H. Historique du tableau de bord

| Date | Agent | Changement |
|---|---|---|
| 2026-10-31 | OpenCode | Création initiale. |
