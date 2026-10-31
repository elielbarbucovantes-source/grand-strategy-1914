# Guide de contribution

> **Statut :** Opérationnel pour la documentation ; à compléter pour le code
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [AGENTS.md](../../AGENTS.md) · [PROGRESS.md](../../PROGRESS.md) · [coding-standards.md](coding-standards.md) · [testing-strategy.md](testing-strategy.md)

---

## 1. À qui s'adresse ce guide

À tout nouvel intervenant : agent IA (OpenCode, Codex, Claude Code, autre) ou humain. Il décrit le workflow concret. Les règles de fond restent dans [AGENTS.md](../../AGENTS.md).

## 2. Prise en main en 10 minutes

1. Lire [AGENTS.md](../../AGENTS.md).
2. Lire [PROJECT.md](../../PROJECT.md).
3. Lire [PROGRESS.md](../../PROGRESS.md) : sections C, D, E, F.
4. Lancer `git status`, `git log --oneline -10`, `git branch -a`, `git worktree list`.
5. Lire les documents du domaine concerné.
6. Choisir une tâche non réservée.
7. Annoncer sa prise en charge dans PROGRESS.md.
8. Travailler sur une branche dédiée.
9. Tester, documenter, signer.

Ne jamais commencer par modifier du code ou des documents sans avoir fait les étapes 1 à 4.

## 3. Choisir une tâche

Les tâches sont dans **PROGRESS.md, section D**, classées P0 à P3.

- Prendre une tâche P0 ou P1 en priorité.
- Vérifier qu'elle n'est pas déjà réservée (section C).
- Vérifier ses dépendances.
- Si la tâche est ambiguë, la reformuler ou demander un arbitrage plutôt que d'inventer.
- Ne pas prendre plus d'une tâche à la fois, sauf tâches explicitement liées.

## 4. Annoncer la prise en charge

Ajouter ou compléter une entrée dans **PROGRESS.md, section C** :

```markdown
### T-XXX — Titre de la tâche

- **Responsable :** <nom réel de l'outil>
- **Date de début :** AAAA-MM-JJ
- **Fichiers concernés :** ...
- **Dépendances :** ...
- **État actuel :** En cours
- **Prochaine étape :** ...
```

Cette annonce est un engagement de courte durée. Si la tâche est abandonnée, la déplacer ou la libérer explicitement.

## 5. Branches et worktrees

### Branche

```bash
git switch main
git pull --ff-only        # si un dépôt distant existe
git switch -c docs/ma-tache
```

Types : `feat/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`, `adr/`, `spike/`.

### Worktree (travail simultané)

```bash
git worktree add ../GrandStrategy-<agent> -b <type>/<slug>
cd ../GrandStrategy-<agent>
```

- Un worktree par agent.
- Ne jamais travailler à deux dans le même répertoire.
- Ne pas supprimer un worktree sans vérifier son état.
- Lister les worktrees dans le compte rendu.

## 6. Modifier la documentation

- Respecter l'en-tête standard ([docs/README.md](../README.md)).
- Utiliser les étiquettes **[VALIDÉ]**, **[PROPOSITION]**, **[HYPOTHÈSE]**, **[À DÉFINIR]**.
- Ne pas transformer une proposition en décision.
- Ne pas dupliquer un contenu : créer un lien.
- Mettre à jour l'index si un document est ajouté.
- Vérifier les liens relatifs.
- Signer la modification (date + outil) dans l'en-tête si le document en a un, et dans PROGRESS.md.

## 7. Modifier le code (quand il existera)

- Respecter les frontières d'architecture.
- Écrire ou mettre à jour les tests.
- Ne pas ajouter de dépendance sans justification.
- Ne pas commiter de secret.
- Documenter les décisions structurantes par ADR.
- Mettre à jour PROGRESS.md et CHANGELOG.md.

## 8. Commits

```bash
git add <fichiers précis>
git diff --staged
git commit
```

Message :

```
<type>(<périmètre>): <résumé>

<corps : pourquoi, limites>

Agent: <nom réel>
Refs: T-XXX, ADR-XXXX
```

Règles :

- un commit = un sujet ;
- ne pas commiter tout le dépôt par réflexe (`git add .`) sans vérifier ;
- ne pas inclure de fichiers générés ou secrets ;
- ne pas réécrire l'historique publié ;
- ne pas signer à la place d'un autre agent.

## 9. Mettre à jour PROGRESS.md

Après une intervention significative :

1. Mettre à jour l'état général (section A).
2. Déplacer la tâche de « en cours » à « terminée » si elle l'est réellement.
3. Mettre à jour le backlog (section D).
4. Ajouter les bugs découverts (section E).
5. Mettre à jour les prochaines étapes (section F).
6. Ajouter une ligne signée au journal (section G).

**Mise à jour séquentielle :** si un autre agent a modifié PROGRESS.md, intégrer ses changements avant les siens. Ne jamais supprimer une entrée.

## 10. Mettre à jour CHANGELOG.md

Un changement va dans le changelog s'il est visible pour :

- un joueur ;
- un intégrateur ;
- un autre agent qui dépend du format ;
- l'exploitation.

Les corrections de documentation internes sans impact peuvent ne pas y figurer, mais doivent figurer dans le journal de PROGRESS.md.

## 11. Créer un ADR

1. Copier [docs/decisions/0000-template.md](../decisions/0000-template.md).
2. Numéroter de façon séquentielle.
3. Remplir toutes les sections.
4. Statut initial : `proposé` (sauf décision déjà validée par le propriétaire).
5. Ajouter l'ADR à l'index.
6. Demander la validation si la décision est structurante.
7. Ne jamais modifier un ADR accepté : créer un ADR de remplacement.

## 12. Revue avant fusion

Checklist :

- [ ] Le périmètre annoncé est respecté.
- [ ] Le diff ne contient pas de fichiers inattendus.
- [ ] Les tests ont été exécutés et les résultats consignés.
- [ ] La documentation est à jour.
- [ ] PROGRESS.md est à jour.
- [ ] CHANGELOG.md est à jour si nécessaire.
- [ ] Aucun secret.
- [ ] Aucune décision non validée présentée comme définitive.
- [ ] Les limitations sont explicites.
- [ ] Un ADR existe si nécessaire.

La revue est faite par un humain ou par un agent différent de l'auteur.

## 13. Conflits

1. Suspendre.
2. Identifier les auteurs et intentions (`git log`, `git blame`, journal).
3. Fusionner explicitement si compatible.
4. Sinon, consigner dans PROGRESS.md section E et demander un arbitrage.
5. Ne jamais résoudre en écrasant une version sans examen.

## 14. Fin de session

Même si le travail est incomplet :

- laisser la branche dans un état récupérable ;
- documenter l'état exact ;
- indiquer la prochaine étape ;
- libérer ou requalifier la réservation ;
- ne pas laisser de secrets ;
- ne pas laisser de processus en arrière-plan non documenté.

## 15. Signaler un problème

- Bug logiciel : section E de PROGRESS.md.
- Erreur dans un document : signalement + correction si triviale, sinon proposition.
- Décision contradictoire : ne pas trancher seul, documenter.
- Risque de sécurité : signaler immédiatement, ne pas reproduire publiquement.
- Blocage : journal + demande d'arbitrage.

## 16. Ce qu'il ne faut pas faire

- Commencer à coder une mécanique non validée.
- Choisir un moteur ou un langage seul.
- Modifier une décision acceptée sans ADR.
- Supprimer l'historique ou une entrée de journal.
- Inventer un résultat de test.
- Déclarer une tâche terminée sans preuve.
- Copier du contenu protégé sans vérifier la licence.
- Commiter un secret.
- Travailler directement sur la branche principale quand une revue est requise.
