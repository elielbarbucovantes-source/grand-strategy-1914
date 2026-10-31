# PROGRESS.md — Tableau de bord permanent

> **Version :** 0.2.0
> **Dernière mise à jour :** 2026-10-31
> **Dernier agent intervenu :** OpenCode
> **Phase actuelle :** Phase 1 — Conception (démarrée)
> **Prochaine étape :** Définition des sept grandes puissances de 1914 (T-020)

> **À lire avant toute intervention.** Ce document décrit l'état réel du projet. Il ne remplace pas Git. Toute modification doit respecter [AGENTS.md](AGENTS.md) § 7.3 (mise à jour séquentielle).

---

## A. État général

| Élément | Valeur |
|---|---|
| Phase actuelle | Phase 1 — Conception, **démarrée** |
| Avancement des fonctionnalités de jeu | **0 fonctionnalité terminée** |
| Backlog fonctionnel de jeu | **En cours de définition** : la fiche maîtresse fixe le cadre, les spécifications détaillées restent à écrire |
| Livrables d'infrastructure | **3 / 3 vérifiés** (INF-001, INF-002, INF-003) |
| Dernière mise à jour | 2026-10-31 |
| Dernier agent intervenu | OpenCode |
| Stabilité du projet | **Stable** : aucun code exécutable, aucun conflit Git non traité, documentation cohérente ; voir la limite L-007 sur la coexistence de deux restructurations documentaires |
| Dépôt Git | Branche `docs/fiche-maitresse-opencode` dans le worktree `../GrandStrategy-opencode` ; `main` reste à `459375a` |

### Méthode de calcul de l'avancement

- **Avancement jeu** = fonctionnalités de jeu terminées / fonctionnalités de jeu planifiées.
  Le backlog fonctionnel n'est pas encore stabilisé ; le dénominateur est inconnu. **Aucun pourcentage de jeu n'est affiché.**
- **Avancement infrastructure** = livrables d'infrastructure vérifiés / livrables d'infrastructure définis.
  Aujourd'hui : 3 / 3. Ce chiffre ne mesure **pas** l'avancement du jeu.
- Aucun pourcentage arbitraire, aucune estimation subjective.

### État de stabilité

- Aucun code exécutable : aucun bug logiciel possible à ce stade.
- Documentation créée et vérifiée par script (structure et liens).
- Aucune décision technique de jeu prise.
- Aucun travail non sauvegardé dans ce worktree.
- Risque principal : démarrer le développement avant d'avoir tranché le périmètre du MVP (T-030 / Q-002).

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
| INF-003 | Intégration de la fiche maîtresse | `PROJECT.md` v0.2.0 reprend la fiche maîtresse du propriétaire : cadre 1914, sept puissances, tours mensuels, diplomatie, IA, militaire, économie, recherche, renseignement, victoire. Décisions D-001 à D-026 tracées. | 2026-10-31 | OpenCode | `./scripts/check-infrastructure.sh` — voir journal section G ; relecture du diff. | Ne vaut pas validation du cahier des charges. Les documents thématiques restent à réviser (T-031). Certaines formulations de la fiche ont été transposées et non recopiées mot à mot. |

---

## C. Travaux en cours

**Aucun travail en cours dans ce worktree.**

La tâche T-019 (« Intégrer la fiche maîtresse du propriétaire dans PROJECT.md ») est terminée et consignée au journal. Aucune tâche n'est réservée ici. Le prochain agent doit choisir une tâche dans la section D et l'annoncer ici avant de commencer.

> **Coordination :** ce worktree (`../GrandStrategy-opencode`, branche `docs/fiche-maitresse-opencode`) a été créé parce qu'une autre session OpenCode travaillait simultanément dans le checkout principal. Voir la limite L-007. Ne pas fusionner avant arbitrage du propriétaire.

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

### P0 — Conception, séquence issue de la fiche maîtresse

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-020 | Définir les sept grandes puissances de 1914 | Statistiques, ressources, forces, faiblesses, objectifs nationaux, spécialisations scientifiques. Livrable : `docs/nations/` et synthèse dans PROJECT.md. Validation du propriétaire requise. | Fiche maîtresse | **Prochaine — agent, validation propriétaire** |
| T-021 | Carte : provinces et territoires | Liste des provinces, frontières, attributs (géographie, ressources, importance, infrastructures, fortifications), territoires jouables. | T-020 | À faire |
| T-022 | Économie : ressources et production | Liste définitive des trois ressources, profils provinciaux, budget, coûts de construction, industrie. | T-020, T-021 | À faire |
| T-023 | Règles de base v0.2 | Tours mensuels, ordres simultanés, résolution des conflits d'ordres, conditions de victoire et de défaite. Remplace T-005. | T-020 à T-022 | À faire |

### P1 — Haute priorité

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-024 | Diplomatie détaillée | Traités (deux catégories), canaux, rupture, sanctions, trahison, crises. Remplace T-009. | T-023 | À faire |
| T-025 | IA dirigeantes | Personnalités, mémoire longue, objectifs, négociation, crises, décision militaire, limites d'information. Remplace T-012. | T-023 | À faire |
| T-026 | Militaire et batailles tactiques | Unités, coûts, organisation, ravitaillement, offensives, terrain, fortifications, batailles de 30 minutes. | T-021, T-023 | À faire |
| T-027 | Technologies et renseignement | Arbre 1914-1945, prérequis, spécialisations, interception, cryptographie, espionnage industriel. | T-022, T-023 | À faire |
| T-028 | Interface et modes de jeu | Carte, diplomatie, batailles, campagnes, parties libres, mode observateur. | T-023 | À faire |
| T-031 | Aligner les documents thématiques | Réviser les documents de `docs/` antérieurs à la fiche maîtresse et retirer les contradictions (économie confirmée, tours, 1914, victoire, traités, batailles). | T-020 à T-027 | À faire |

### P2 — Priorité normale

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-029 | Étude de pile technique + ADR | Comparer les options (langage, application, moteur, persistance) et produire un ADR. Ne rien implémenter avant validation. Remplace T-004. | T-023, T-028 | À faire |
| T-030 | Cahier des charges et périmètre du MVP | Décision du propriétaire : ce que le MVP démontre et exclut. Remplace T-001. | T-020 à T-023 | **À faire — propriétaire** |
| T-032 | Modèle de données v0.3 | Passer du modèle conceptuel à un modèle aligné sur la fiche maîtresse (provinces, armées, traités, tour). Remplace T-006. | T-021, T-023 | À faire |
| T-033 | Harnais d'évaluation des IA | Scénarios reproductibles, métriques, comparaison de versions. Remplace T-010. | T-025 | À faire |
| T-034 | Persistance et replay | Sauvegarde, journal d'événements, versionnement, compatibilité. Remplace T-011. | T-029, T-032 | À faire |
| T-035 | Observabilité | Logs, métriques, traces, audit des décisions IA. Remplace T-014. | T-029 | À faire |

### P3 — Amélioration facultative

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-015 | Modding | Étudier l'ouverture des règles et des cartes. | T-023, T-021 | À faire |
| T-016 | Localisation | Choisir les langues et le mécanisme i18n. | T-028 | À faire |
| T-017 | Accessibilité | Contraste, navigation clavier, lisibilité. | T-028 | À faire |
| T-018 | Éditeur de carte | Outil interne ou externe. | T-021 | À faire |
| T-036 | Multijoueur humain | Synchronisation, déconnexions, modération. Non requis en v1, architecture à anticiper. | T-029, T-030 | À faire |

### Anciennes tâches — état après la fiche maîtresse

| ID | Tâche initiale | État |
|---|---|---|
| T-001 | Valider la vision et le périmètre du MVP | Vision fixée par la fiche maîtresse ; périmètre du MVP toujours ouvert → **T-030** |
| T-002 | Trancher la relation à Diplomacy | **Tranché** : inspiration combinée (D-001). Volet juridique ouvert (Q-026). |
| T-003 | Trancher le rythme de partie | **Tranché** : un tour = un mois, résolution simultanée (D-006). |
| T-004 | Étude de pile technique + ADR | Reporté → **T-029** |
| T-005 | Spécifier les règles de base v0.1 | Remplacé par **T-023** |
| T-006 à T-014 | Modèle de données, contrat IA, carte, traités, évaluation, persistance, personnalités, UI, observabilité | Repris dans T-024 à T-035 |
| T-015 à T-018 | Modding, localisation, accessibilité, éditeur | Conservés |

---

## E. Bugs et problèmes connus

### E.1 Bugs logiciels

**Aucun bug logiciel connu.** Il n'existe aucun code exécutable.

| ID | Description | Gravité | Origine | Reproduction | État | Responsable |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

### E.2 Limitations connues de l'infrastructure et de la coordination

| ID | Problème | Gravité | Origine | État | Responsable |
|---|---|---|---|---|---|
| L-001 | Le script vérifie la structure et les liens, pas la cohérence sémantique des documents. | Faible | Limite de l'automatisation | Connu, accepté | OpenCode |
| L-002 | Aucune CI n'exécute le script automatiquement. | Moyenne | Pile technique non choisie | Ouvert | À assigner |
| L-003 | La protection de branche et la revue obligatoire ne sont pas configurées côté hébergeur. | Moyenne | Dépôt local, pas de remote | Ouvert | Propriétaire |
| L-004 | L'identité formelle du propriétaire et le canal d'arbitrage ne sont pas définis. | Moyenne | Information manquante | Ouvert — voir Q-025 | Propriétaire |
| L-005 | Aucun glossaire commun n'existe encore ; certains termes peuvent être interprétés différemment. | Faible | Cadrage initial | Ouvert | À assigner |
| L-006 | Deux sessions OpenCode ont travaillé simultanément dans le même checkout principal le 2026-10-31. Les modifications de la session courante n'étaient pas commitées ; elles ont été isolées dans le worktree `../GrandStrategy-opencode` après sauvegarde dans `/tmp/opencode/t019-snapshot/`. Aucune perte constatée. | Moyenne | Absence de worktree distinct au démarrage | Traité — voir journal | OpenCode |
| L-007 | Deux restructurations documentaires coexistent : (a) celle de la session courante, qui conserve l'arborescence `docs/gameplay/`, `docs/artificial-intelligence/`, `docs/diplomacy/` ; (b) celle de l'autre session, qui a commencé à déplacer les documents vers `docs/ai/`, `docs/economy/`, `docs/military/` et à créer `docs/nations/`, `docs/technology/`, `docs/intelligence/`. Les deux ne sont pas fusionnées. | Haute | Travail concurrent | Ouvert — **arbitrage propriétaire requis** | Propriétaire |
| L-008 | `PROJECT.md` § 22 pointe vers l'arborescence actuelle. Si la restructuration (b) est retenue, ces liens devront être réécrits. | Moyenne | Dépend de L-007 | Ouvert | À assigner après arbitrage |

### E.3 Risques suivis (rappel)

Les risques architecturaux sont détaillés dans [docs/architecture/overview.md § 7](docs/architecture/overview.md#7-risques-architecturaux-identifiés). Ils ne sont pas des bugs.

---

## F. Prochaines étapes

| # | Tâche | Responsable | Dépendances | Pourquoi maintenant |
|---|---|---|---|---|
| 1 | **T-020** — Définir les sept grandes puissances de 1914 | Agent, validation propriétaire | Fiche maîtresse | C'est l'étape 2 de la priorité de développement : tout le reste (carte, économie, armées) en dépend. |
| 2 | **T-021** — Définir la carte et les provinces | Agent | T-020 | Les caractéristiques nationales n'ont de sens que sur un territoire délimité. |
| 3 | **T-022** — Définir les ressources et l'économie | Agent | T-020, T-021 | Les trois ressources par province conditionnent budget, industrie et recherche. |
| 4 | **T-023** — Règles de base v0.2 | Agent | T-020 à T-022 | Fixe les tours, la résolution et la victoire : socle testable. |
| 5 | **T-031** — Aligner les documents thématiques | Agent | T-020 à T-027 | Retirer les contradictions avec la fiche maîtresse avant d'aller plus loin. |

**Point de blocage actuel :** l'arbitrage L-007 (quelle arborescence documentaire retenir) et la décision T-030 (périmètre du MVP) appartiennent au propriétaire. Aucun agent ne doit les trancher seul.

---

## G. Journal des interventions

| Date | Agent | Intervention | Fichiers | Tests | Résultat |
|---|---|---|---|---|---|
| 2026-10-31 | OpenCode | Création de l'infrastructure documentaire initiale : documents de référence, documentation thématique, ADR 0001–0003, script de vérification, initialisation Git. | `AGENTS.md`, `PROJECT.md`, `PROGRESS.md`, `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `.gitignore`, `.env.example`, `docs/**`, `scripts/check-infrastructure.sh`, `src/README.md`, `tests/README.md`, `assets/README.md` | `./scripts/check-infrastructure.sh` — 67 vérifications, 0 échec (après correction d'un lien cassé) ; `git status` — vérification avant commit. | Terminé |
| 2026-10-31 | OpenCode | Intégration de la fiche maîtresse v0.1 dans `PROJECT.md` (v0.2.0) : décisions D-001 à D-026, questions tranchées, priorité de développement, correspondance documentaire. Alignement de `PROGRESS.md`, `CHANGELOG.md`, `README.md`, `docs/README.md` et notes de cohérence sur cinq documents thématiques. Correction du test Git du script pour les worktrees. Travail isolé dans le worktree `../GrandStrategy-opencode` en raison d'une session concurrente (L-006, L-007). | `PROJECT.md`, `PROGRESS.md`, `CHANGELOG.md`, `README.md`, `docs/README.md`, `docs/gameplay/rules.md`, `docs/gameplay/map-system.md`, `docs/gameplay/military-system.md`, `docs/gameplay/economy-system.md`, `docs/diplomacy/treaties.md`, `scripts/check-infrastructure.sh` | `./scripts/check-infrastructure.sh` — 67 vérifications, 0 échec (exécuté dans le worktree) ; `git diff --check` — aucune erreur d'espacement. | Terminé |

> Le journal est append-only. Ne jamais supprimer ni réécrire une ligne existante. Une correction s'ajoute avec une référence à la ligne corrigée.

---

## H. Historique du tableau de bord

| Date | Agent | Changement |
|---|---|---|
| 2026-10-31 | OpenCode | Création initiale. |
| 2026-10-31 | OpenCode | Version 0.2.0 : intégration de la fiche maîtresse, phase 1 démarrée, backlog réorganisé (T-020 à T-036), limitations de concurrence L-006 à L-008. |
