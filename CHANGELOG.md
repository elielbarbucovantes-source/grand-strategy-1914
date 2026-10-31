# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet utilise le [versionnement sémantique](https://semver.org/lang/fr/).

**Important :** ce changelog décrit les versions livrées. Il ne remplace pas le journal détaillé des interventions, tenu dans [PROGRESS.md](PROGRESS.md) section G.

Le projet ne contient encore **aucune version jouable**. La version `0.1.0` correspond à l'infrastructure documentaire.

---

## [Unreleased]

### Added

- Aucun changement depuis la version 0.2.0.

### Changed

- —

### Fixed

- —

### Removed

- —

### Deprecated

- —

### Security

- —

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
- `scripts/check-infrastructure.sh` reconnaît désormais un dépôt Git dans un worktree (`.git` y est un fichier et non un dossier) : le contrôle Git ne produit plus de faux échec.

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
