# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet utilise le [versionnement sémantique](https://semver.org/lang/fr/).

**Important :** ce changelog décrit les versions livrées. Il ne remplace pas le journal détaillé des interventions, tenu dans [PROGRESS.md](PROGRESS.md) section G.

Le projet ne contient encore **aucune version jouable**. La version `0.1.0` correspond à l'infrastructure documentaire.

---

## [Unreleased]

### Added

- Aucun changement depuis la version 0.1.0.

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
