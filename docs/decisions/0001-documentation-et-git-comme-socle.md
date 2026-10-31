# ADR-0001 — Documentation et Git comme socle de collaboration

> **Statut :** Accepté
> **Date :** 2026-10-31
> **Auteur :** OpenCode
> **Décideur :** Propriétaire du projet (via le brief initial)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [AGENTS.md](../../AGENTS.md) · [PROJECT.md](../../PROJECT.md) · [PROGRESS.md](../../PROGRESS.md)

---

## 1. Contexte

Le projet doit être développé sur plusieurs mois ou années par plusieurs agents IA hétérogènes (OpenCode, Codex, Claude Code) et par le propriétaire. Les agents n'ont pas de mémoire persistante entre les sessions et ne partagent pas les conversations précédentes.

Sans infrastructure commune, chaque session risque de :

- repartir de zéro ;
- contredire une décision antérieure ;
- dupliquer ou écraser du travail ;
- produire des documents incohérents ;
- perdre la trace des choix.

Le brief du propriétaire impose explicitement une documentation centrale, un tableau de bord, une constitution d'agents, un changelog, des ADR et Git comme source de vérité.

## 2. Problème à résoudre

Comment garantir qu'un agent arrivant à n'importe quel moment puisse comprendre l'état du projet, reprendre le travail et collaborer sans détruire le travail des autres ?

## 3. Solutions envisagées

### Option A — Conversations et mémoire des outils

Compter sur l'historique des sessions et la mémoire propre à chaque outil.

- **Avantages :** aucun effort initial.
- **Inconvénients :** non partageable entre outils, non fiable, non auditable, perte à chaque nouvelle session.
- **Réversibilité :** sans objet.
- **Verdict :** rejetée.

### Option B — Wiki externe

Documenter dans un wiki ou un outil tiers.

- **Avantages :** interface confortable, recherche.
- **Inconvénients :** dépendance externe, accès et permissions, séparation d'avec le code, risque de désynchronisation, agents parfois sans accès.
- **Réversibilité :** moyenne.
- **Verdict :** non retenue pour le socle, pourrait compléter plus tard.

### Option C — Documentation versionnée dans le dépôt + Git

Documents Markdown dans le dépôt, versionnés avec le code, structurés par rôle, avec un journal et des ADR. Git sert de source de vérité pour l'historique et les conflits.

- **Avantages :** accessible à tous les agents, versionné, auditable, diffable, sans dépendance externe, cohérent avec le code, portable.
- **Inconvénients :** discipline nécessaire, risque de documents obsolètes, conflits sur les fichiers partagés.
- **Réversibilité :** élevée (les fichiers restent lisibles).
- **Verdict :** retenue.

## 4. Solution retenue

- `AGENTS.md` : constitution commune.
- `PROJECT.md` : vision, périmètre, décisions, questions ouvertes.
- `PROGRESS.md` : tableau de bord opérationnel, backlog, bugs, journal.
- `README.md` : prise en main.
- `CHANGELOG.md` : historique des versions.
- `docs/` : documentation thématique et ADR.
- Git : source de vérité de l'historique, des branches et des conflits.
- `PROGRESS.md` ne remplace jamais Git.

## 5. Justification

Cette solution répond directement aux contraintes du propriétaire :

- interopérabilité entre outils ;
- continuité entre sessions ;
- traçabilité des décisions ;
- vérifiabilité ;
- absence de dépendance à une conversation ;
- possibilité de travailler hors ligne et de versionner.

Elle est aussi la moins coûteuse à mettre en place et la plus réversible.

## 6. Conséquences

### Positives

- Tout agent peut reprendre le projet à froid.
- Les décisions et les interventions sont traçables.
- Les conflits peuvent être résolus par Git.
- La documentation évolue avec le code.

### Négatives / coûts

- Chaque intervention impose une discipline de mise à jour.
- Les fichiers partagés peuvent entrer en conflit.
- Le volume documentaire peut croître et doit être entretenu.
- La documentation peut diverger du code si la Definition of Done n'est pas appliquée.

### Mesures de mitigation

- Règle de mise à jour séquentielle de `PROGRESS.md`.
- Definition of Done dans `AGENTS.md`.
- Revue avant fusion.
- Archivage plutôt que suppression.
- Vérification périodique de cohérence.

### Impacts

- Tous les agents doivent lire les documents de référence avant d'agir.
- Toute intervention significative doit être journalisée.
- Toute décision structurante doit produire un ADR.

## 7. État

**Accepté.** Décision du propriétaire, mise en œuvre par OpenCode.

## 8. Suivi

- [x] Index mis à jour
- [x] Documents créés
- [x] PROGRESS.md mis à jour
- [x] Validation du propriétaire (brief initial)

## 9. Références

- Brief du propriétaire, sections 1 à 10.
- [AGENTS.md](../../AGENTS.md)
