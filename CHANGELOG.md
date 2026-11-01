# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet utilise le [versionnement sémantique](https://semver.org/lang/fr/).

**Important :** ce changelog décrit les versions livrées. Il ne remplace pas le journal détaillé des interventions, tenu dans [PROGRESS.md](PROGRESS.md) section G.

La version `0.3.0` est le **premier MVP jouable**. Elle reste provisoire : les valeurs de jeu sont des hypothèses et les batailles tactiques ne sont pas implémentées. La version `0.1.0` correspond à l'infrastructure documentaire.

---

## [Unreleased]

### Added

- —

### Changed

- —

### Fixed

- —

### Security

- Aucun secret n'est versionné.

---

## [0.3.0] — 2026-11-01

### Added

- **Premier MVP jouable de bout en bout** : `game/` fournit un moteur de stratégie mensuel, une carte d'Europe de juin 1914, le choix d'une des sept puissances ou le mode observation, des ordres simultanés, une économie, une recherche, une diplomatie simple, des événements (dont Sarajevo), un combat stratégique automatique, un brouillard de guerre, une IA heuristique, trois voies de victoire, la sauvegarde/chargement JSON et une interface web.
- **Carte provisoire** : 90 provinces, 472 hexes, grille 38 × 26, générée par `tools/generate_map.py` et chargée depuis `game/data/map.json`.
- **Données de scénario** : 22 nations (7 jouables), profils nationaux, 20 technologies, 11 événements, valeurs provisoires centralisées dans `game/data/config.json`.
- **Interface web** : HTML/CSS/JavaScript natifs, carte SVG, onglets Ordres, Diplomatie, Économie, Recherche, Monde, Rapport et Journal, sauvegarde/chargement et prise de contrôle en cours de partie.
- **Tests** : `tests/test_engine.py`, 24 tests `unittest` couvrant scénario, économie, recherche, militaire, diplomatie, événements, IA, victoire et sauvegarde.
- **Hypothèses de conception** : `DECISIONS_PENDING.md` consigne H-001 à H-023, dont les seuils de victoire économique et le garde-fou de taille (H-018, H-023).
- **ADR-0006** : pile technique du MVP — Python 3.12, bibliothèque standard, serveur HTTP, interface web native, JSON, `unittest`.
- **Documentation du MVP** : commandes de lancement et de test dans `README.md`, statut et architecture dans `PROJECT.md` v0.2.4, tableau de bord dans `PROGRESS.md` v0.3.0, registres ADR et techniques mis à jour.
- **Document fondateur gelé** : `docs/founding-document-v0.1.md` conserve intégralement le document remis par le propriétaire, avec empreinte SHA-256 `6de617ca12d9b9028b72ddae6ec85a41b394f1875a4b6af0cabfeb553e1a25ce`. Toute correction doit créer une version distincte.
- **Revue de conception** : `docs/design-review-v0.1.md` consigne les tensions internes C-01 à C-18 et les points de vigilance V-01 à V-08. Elle ne tranche aucune règle.
- **ADR-0004** : adoption du document fondateur comme source de conception (accepté, avec réserve explicite sur le cahier des charges détaillé).
- **ADR-0005** : intégration du temps stratégique et tactique (`proposé`, ne vaut pas décision).
- **Nouveaux documents thématiques** : `docs/military/tactical-battles.md`, `docs/technology/research-system.md`, `docs/intelligence/intelligence-system.md`, `docs/nations/regimes.md`.
- **Dossier des puissances jouables** : `docs/nations/nations.md` fixe les profils initiaux des sept nations en 1914 — identité, douze caractéristiques nationales, forces, faiblesses, armées, marine, économie, diplomatie, ambitions et possessions — avec une annexe d'intégration et de questions ouvertes (Q-027 à Q-031).
- **Décisions** : D-027 (douze caractéristiques nationales), D-028 (colonies simplifiées, Allemagne sans empire colonial exploitable), D-029 (ambitions initiales non contraignantes).
- **Tâches de suivi** : T-029 (arbitrage stratégique/tactique), T-030 (validation du cahier des charges), T-031 (alignement documentaire), T-032 (modélisation des profils), T-033 (relations et traités initiaux), T-034 (évolution des caractéristiques).
- **Nom officiel du jeu** : *Grand Strategy-1914*, arrêté par le propriétaire le 2026-10-31 (D-030). Il remplace la dénomination provisoire `GrandStrategy`, qui ne subsiste que comme nom du répertoire Git.

### Changed

- `README.md` décrit désormais l'état réel du MVP : installation, lancement (`python3 -m game --port 8765`), tests, première partie, structure et limites connues.
- `PROJECT.md` passe en version 0.2.4 : statut phase 2, D-031 et ADR-0006 intégrés, architecture du MVP documentée, questions Q-002/Q-007/Q-008/Q-009 marquées comme tranchées pour le MVP.
- `PROGRESS.md` passe en version 0.3.0 : MVP-001 livré, T-036 terminé, tests et parcours navigateur consignés, limites L-010 à L-015 et extensions T-037 à T-042 ajoutées.
- `docs/README.md`, `docs/decisions/README.md`, `docs/architecture/technical-decisions.md`, `docs/architecture/overview.md`, `docs/development/testing-strategy.md` et `docs/development/coding-standards.md` : index, statuts et choix du MVP alignés sur ADR-0006.
- `src/README.md` et `tests/README.md` : pointeurs vers `game/` et description des 24 tests réels.
- **Réorganisation de `docs/`** : `docs/artificial-intelligence/` devient `docs/ai/` ; `docs/gameplay/military-system.md` devient `docs/military/strategic-warfare.md` ; `docs/gameplay/economy-system.md` devient `docs/economy/economy-system.md` (déplacements via `git mv`).
- **Alignement thématique (T-031)** : réécriture de `docs/gameplay/rules.md`, `docs/gameplay/map-system.md`, `docs/military/strategic-warfare.md`, `docs/economy/economy-system.md`, des quatre documents de `docs/diplomacy/`, des trois documents de `docs/architecture/` et ajout d'une section « Cadre validé » aux cinq documents de `docs/ai/`.
- `PROJECT.md` passe en version 0.2.2 : tableau de correspondance documentaire mis à jour, ajout du document fondateur, de la revue de conception et des ADR-0004/0005. Aucune décision de jeu ajoutée.
- `README.md` et `docs/README.md` : index enrichi (nations, régimes, militaire, économie, technologie, renseignement, IA, cadre de conception) et chemins alignés sur l'arborescence réelle.
- `AGENTS.md` : document fondateur et revue de conception ajoutés aux documents de référence ; ordre de lecture obligatoire étendu.
- `PROGRESS.md` passe en version 0.2.0 puis 0.2.1 (clôture du commit) : phase 1 en cours, T-019 clôturée, backlog T-020 à T-034, constats mis à jour, journal complété et L-007 résolu.
- `scripts/check-infrastructure.sh` : fichiers obligatoires alignés sur la réorganisation, vérification de l'empreinte SHA-256 du document fondateur.
- `PROJECT.md` passe en version 0.2.3 et `README.md` porte le titre *Grand Strategy-1914* : Q-001 est close, D-030 ajoutée. Aucune règle de jeu modifiée.

### Fixed

- Serveur : `Handler.log_message` plantait sur les réponses 404 (`send_error` recevait un entier au lieu d'un message).
- Interface : à 768 px de hauteur, les onglets passaient sous la barre supérieure ; l'écran de jeu utilise maintenant `100vh` avec des panneaux défilants.
- Mode observation : `build_view` supposait une nation joueur non nulle ; un helper `_view()` gère désormais l'absence de joueur.
- Ajout de `favicon.svg` et service correct des fichiers statiques.
- `scripts/check-infrastructure.sh` reconnaît désormais un dépôt Git dans un worktree (`.git` y est un fichier et non un dossier) : le contrôle Git ne produit plus de faux échec hors du checkout principal.
- Liens relatifs cassés vers `docs/artificial-intelligence/`, `docs/gameplay/military-system.md` et `docs/gameplay/economy-system.md` dans les documents de référence et d'architecture.
- Référence obsolète `docs/artificial-intelligence/` dans `AGENTS.md`.
- Collision d'identifiants `C-001…C-005` renommée `CT-001…CT-010` pour laisser `C-01…C-18` à la revue de conception ; sources incorrectes corrigées dans le registre technique.

### Removed

- —

### Deprecated

- Les hypothèses de cadrage antérieures à la fiche maîtresse (existence de l'économie incertaine, reprise fidèle de Diplomacy, temps réel global, victoire unique) sont conservées comme historique mais ne font plus autorité.

### Security

- Aucun secret n'est versionné.

---

## [0.2.0] — 2026-10-31

### Added

- **Fiche maîtresse intégrée** : `PROJECT.md` reprend la fiche maîtresse v0.1 remise par le propriétaire (Europe 1914, sept grandes puissances, tours mensuels à résolution simultanée, diplomatie, IA autonomes, batailles tactiques, économie, recherche 1914-1945, renseignement, régimes, victoire, interface, multijoueur).
- **Décisions tracées** : D-001 à D-026 (décisions du propriétaire), tableau des questions tranchées (Q-003, Q-004, Q-005, Q-006, Q-013 à Q-016) et nouvelle question Q-026 (périmètre juridique des inspirations).
- **Priorité de développement** : séquence de conception en onze étapes, avec la définition des sept grandes puissances comme prochaine étape.
- **Correspondance documentation** : tableau liant chaque système de la fiche maîtresse à son document thématique et à son état de révision.

### Changed

- `PROJECT.md` passe en version 0.2.0. La formulation antérieure « jeu inspiré de webDiplomacy » est remplacée par la description combinée de la fiche maîtresse (D-001 révisée).
- `PROGRESS.md` : phase 1 (conception) démarrée, backlog réorganisé selon la priorité de la fiche maîtresse, tâches T-020 à T-031 ajoutées, T-002 et T-003 marquées tranchées, T-005 remplacée par T-023.
- `README.md` : présentation et état du projet alignés sur la fiche maîtresse.
- `docs/README.md` : économie confirmée, avertissement de cohérence sur les documents thématiques antérieurs.
- `docs/gameplay/rules.md`, `map-system.md`, `military-system.md`, `economy-system.md`, `docs/diplomacy/treaties.md` : note de cohérence renvoyant à la fiche maîtresse et à la tâche d'alignement T-031.

### Fixed

- Suppression de l'affirmation « existence de l'économie non confirmée », contredite par la fiche maîtresse.

### Removed

- —

### Deprecated

- Le contenu de cadrage des documents thématiques antérieurs à la fiche maîtresse est conservé pour historique mais n'est plus la référence : voir `PROJECT.md` § 22.

### Security

- Aucun secret n'est versionné.

---

## [0.1.0] — 2026-10-31

### Added

- **Documents de référence** : `AGENTS.md` (constitution des agents), `PROJECT.md` (vision, décisions, questions ouvertes), `PROGRESS.md` (tableau de bord), `README.md` (prise en main), `CHANGELOG.md`.
- **Interopérabilité multi-agents** : `CLAUDE.md` comme pointeur vers `AGENTS.md`.
- **Protection du dépôt** : `.gitignore`, `.env.example` sans secret.
- **Documentation d'architecture** : vue d'ensemble, registre des décisions techniques, modèle de données conceptuel.
- **Documentation de gameplay** : règles, carte, militaire, économie (existence non confirmée).
- **Documentation de diplomatie** : traités, négociations, alliances, réputation.
- **Documentation d'IA** : architecture, personnalités, mémoire, décision, interactions multi-agents.
- **Documentation de développement** : conventions, stratégie de test, guide de contribution.
- **ADR** : modèle, index, ADR-0001 (documentation et Git), ADR-0002 (interopérabilité), ADR-0003 (report du choix de pile).
- **Outillage** : `scripts/check-infrastructure.sh` pour vérifier la structure, les sections obligatoires, les liens et l'absence de secrets.
- **Arborescence** : `src/`, `tests/`, `assets/` avec fichiers de cadrage ; aucun code de jeu.

### Changed

- Aucun changement antérieur : version initiale.

### Fixed

- Aucun.

### Removed

- Aucun.

### Deprecated

- Aucun.

### Security

- Aucun secret n'est versionné.
- `.env` et les fichiers de clés sont ignorés par Git.

### Notes

- Aucune technologie de jeu n'est choisie.
- Aucune fonctionnalité de jeu n'est implémentée.
- Les documents de conception sont des documents de **cadrage** : ils listent des hypothèses et des questions ouvertes, pas des spécifications validées.

---

## Modèle pour les prochaines versions

```markdown
## [X.Y.Z] — AAAA-MM-JJ

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Removed
- ...

### Deprecated
- ...

### Security
- ...

### Breaking changes
- ...
```

Règles :

- une entrée par version livrée, de la plus récente à la plus ancienne ;
- ne pas confondre correction interne et changement visible ;
- signaler explicitement les changements incompatibles ;
- ne jamais inventer une version ou une date.
