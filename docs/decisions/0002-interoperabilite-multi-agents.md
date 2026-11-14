# ADR-0002 — Interopérabilité multi-agents via un fichier de règles unique

> **Statut :** Accepté
> **Date :** 2026-10-31
> **Auteur :** OpenCode
> **Décideur :** OpenCode, dans le périmètre délégué de l'infrastructure documentaire (décision réversible)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [AGENTS.md](../../AGENTS.md) · [CLAUDE.md](../../CLAUDE.md) · [docs/development/contribution-guide.md](../development/contribution-guide.md)

---

## 1. Contexte

Les trois outils prévus ne lisent pas les mêmes fichiers de configuration :

- OpenCode lit `AGENTS.md` ;
- Codex lit `AGENTS.md` ;
- Claude Code lit `CLAUDE.md`.

Si chaque outil possède son propre fichier de règles, les règles divergent avec le temps. Un agent peut alors suivre une version obsolète ou contradictoire.

## 2. Problème à résoudre

Comment faire en sorte que tous les agents appliquent exactement les mêmes règles, sans duplication ni divergence, tout en respectant les conventions de chaque outil ?

## 3. Solutions envisagées

### Option A — Dupliquer les règles dans chaque fichier

- **Avantages :** simple, natif pour chaque outil.
- **Inconvénients :** duplication, divergence inévitable, maintenance multipliée, risque de contradiction.
- **Verdict :** rejetée.

### Option B — Liens symboliques

Créer `CLAUDE.md` comme lien symbolique vers `AGENTS.md`.

- **Avantages :** une seule source.
- **Inconvénients :** comportement variable selon les systèmes et les outils, problèmes sous Windows, liens parfois non suivis, risque de casse lors d'un clone.
- **Verdict :** fragile, non retenue.

### Option C — Fichier pointeur

`AGENTS.md` contient l'intégralité des règles. `CLAUDE.md` est un fichier court qui renvoie explicitement à `AGENTS.md` et interdit la duplication.

- **Avantages :** source unique, compatible avec tous les outils, lisible, versionné, sans dépendance technique.
- **Inconvénients :** nécessite que l'agent suive le pointeur ; un fichier supplémentaire à maintenir (mais minimal).
- **Réversibilité :** élevée.
- **Verdict :** retenue.

### Option D — Génération automatique

Générer les fichiers par un script à partir d'une source.

- **Avantages :** cohérence garantie.
- **Inconvénients :** outillage prématuré, complexité, dépendance à un script avant même le choix de la pile.
- **Verdict :** reportée ; pourra remplacer l'option C plus tard.

## 4. Solution retenue

- `AGENTS.md` est **l'unique constitution**.
- `CLAUDE.md` est un **pointeur** qui ne contient aucune règle propre.
- Tout nouvel outil qui exige un fichier dédié reçoit un pointeur du même type.
- Aucune règle ne doit être dupliquée dans un fichier propre à un outil.

## 5. Justification

- Respecte le principe de source unique de vérité.
- Compatible avec les trois outils sans outillage supplémentaire.
- Facile à comprendre et à maintenir.
- Réversible : si un outil exige un format différent, on peut créer un adaptateur sans changer les règles.

## 6. Conséquences

### Positives

- Une seule version des règles.
- Les mises à jour profitent à tous les agents.
- Pas de divergence silencieuse.

### Négatives / coûts

- Un agent peut ignorer le pointeur s'il ne lit pas son fichier de configuration.
- Le fichier pointeur doit être maintenu si un outil change de convention.
- Les fichiers générés ne sont pas encore automatisés.

### Impacts

- `CLAUDE.md` créé.
- `AGENTS.md` contient la section 15 sur les spécificités des outils.
- Le guide de contribution renvoie à `AGENTS.md`.

## 7. État

**Accepté.** Décision d'infrastructure, réversible, prise dans le périmètre délégué. Le propriétaire peut la remplacer par un ADR ultérieur.

## 8. Suivi

- [x] `CLAUDE.md` créé
- [x] `AGENTS.md` mis à jour
- [x] Index mis à jour
- [x] PROGRESS.md mis à jour
- [ ] Validation explicite du propriétaire (non requise pour cette décision réversible, mais recommandée)

## 9. Références

- [AGENTS.md § 15](../../AGENTS.md#15-spécificités-des-outils)
- [CLAUDE.md](../../CLAUDE.md)
