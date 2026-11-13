# CONTRIBUTING.md — Guide de contribution multi-IA et multi-ordinateurs

Ce document explique comment connecter un nouvel ordinateur ou un nouvel agent IA au dépôt central de **Grand Strategy-1914**, comment travailler simultanément sans perte de données et comment publier proprement chaque contribution.

> **Prérequis d'accès :** Le dépôt `https://github.com/elielbarbucovantes-source/grand-strategy-1914` est **strictement privé**. L'existence du dépôt distant ne donne pas automatiquement accès à tous les agents : chaque ordinateur ou environnement d'exécution IA doit être explicitement authentifié auprès de GitHub avec un compte ou un jeton disposant des droits `repo` sur ce dépôt.

---

## 1. Connexion d'un nouvel ordinateur (procédure Ubuntu / Debian)

### Étape 1 — Installer Git et Python 3 (environnement GIS)
```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip
```

### Étape 2 — Installer GitHub CLI (`gh`)
```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
```

### Étape 3 — Authentifier l'utilisateur auprès de GitHub
```bash
gh auth login
# Choisir : GitHub.com -> HTTPS -> Authenticate Git with your GitHub credentials (Yes) -> Login with a web browser
gh auth setup-git
gh auth status
```
> **Sécurité :** Ne stockez jamais de mot de passe, de token (`ghp_...`, `github_pat_...`) ou de clé privée dans un fichier du dépôt ni dans l'URL du remote `origin`.

### Étape 4 — Cloner le dépôt et récupérer toutes les branches
```bash
git clone https://github.com/elielbarbucovantes-source/grand-strategy-1914.git
cd grand-strategy-1914
git fetch origin --prune
git branch -a -vv
```

> **Note importante sur les branches de référence actuelles :**
> - Socle documentaire du 1er novembre 2026 (90 régions, 69 décisions cartographiques) : branche `foundation/main-2026-11-01` (commit `4ffdb8a`).
> - Socle géométrique consolidé (`BLK-001`, `BLK-002`, `MAJ-004`) : branche `consolidate/map-1914-geometry` (commit `a7983e7`).
> - Correction géométrique de Stroumitsa (`MAJ-003`, en attente d'audit indépendant) : branche `fix/map-strumica-final` (commit `03bce80`).
> - Documentation centralisée multi-IA (présent guide) : branche `docs/github-central-infrastructure`.

Pour basculer sur la branche consolidée de référence après le clone :
```bash
git checkout consolidate/map-1914-geometry
```

### Étape 5 — Installer les dépendances Python GIS (`.venv`)
```bash
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r tools/map/requirements.lock
```

### Étape 6 — Lire `AGENTS.md` et vérifier les validateurs
Avant toute action, lire impérativement `AGENTS.md`, `PROJECT.md` et `PROGRESS.md`, puis vérifier que l'outillage fonctionne :
```bash
.venv/bin/python tools/map/validate_atlas.py
```

### Étape 7 — Vérifier la récupération et la publication
```bash
git fetch origin --prune
git push --dry-run origin HEAD
```

---

## 2. Instructions rapides pour les autres systèmes d'exploitation

- **Fedora / RHEL** :
  ```bash
  sudo dnf install -y git gh python3 python3-virtualenv
  gh auth login && gh auth setup-git
  ```
- **Arch Linux** :
  ```bash
  sudo pacman -S --needed git github-cli python
  gh auth login && gh auth setup-git
  ```
- **macOS (Homebrew)** :
  ```bash
  brew install git gh python
  gh auth login && gh auth setup-git
  ```
- **Windows** :
  Privilégier **WSL2 (Ubuntu)** en suivant exactement la procédure Ubuntu de la section 1 afin de garantir l'exécution identique des scripts bash (`tools/map/consolidate_geometry.sh`) et des bibliothèques C/GEOS (`pyogrio`, `shapely`, `pyproj`).

---

## 3. Organisation du travail entre les IA

### Conventions de nommage des branches
Aucune IA ne doit travailler directement sur `main`. Toute tâche doit utiliser une branche dédiée :
- `feature/<nom>` : nouvelle capacité d'outillage ou de données autorisée par mission.
- `fix/<nom>` : correction ciblée (ex. `fix/map-strumica-final`, `fix/map-topology-v2`).
- `docs/<nom>` : mise à jour documentaire ou d'infrastructure (ex. `docs/github-central-infrastructure`).
- `audit/<nom>` : rapport d'audit ou de contrôle indépendant (ex. `audit/map-1914`).
- `research/<nom>` : recherche historique ou cartographique sourcée.
- `consolidate/<nom>` / `integrate/<nom>` : consolidation multi-lots explicitement mandatée.

### Cycle de vie d'une mission (7 étapes obligatoires)
1. **Synchroniser** :
   ```bash
   git fetch origin --prune
   ```
2. **Créer une branche dédiée** à partir du commit/branche de référence de la mission :
   ```bash
   git checkout -b <type>/<nom-mission> origin/<branche-reference>
   ```
3. **Travailler de manière isolée** : ne modifier aucun fichier appartenant à une autre mission en cours et ne jamais écrire de livrable uniquement dans `/tmp`.
4. **Vérifier les changements** :
   ```bash
   git status --short --branch
   git diff --stat
   .venv/bin/python tools/map/validate_geometry.py
   .venv/bin/python tools/map/validate_atlas.py
   ```
5. **Effectuer un commit explicite** :
   ```bash
   git add <fichiers-cibles>
   git commit -m "<type>(<portée>): <description précise>"
   ```
6. **Publier la branche sur `origin`** :
   ```bash
   git push -u origin <type>/<nom-mission>
   ```
7. **Fournir un compte rendu complet** incluant la branche, le hash complet (`git rev-parse HEAD`), les fichiers touchés et la sortie réelle des validateurs.

---

## 4. Travail simultané : un ordinateur vs plusieurs ordinateurs

### Sur un même ordinateur : utiliser obligatoirement `git worktree`
> **Attention :** Deux branches différentes dans un même répertoire de travail ne permettent **pas** à deux agents de travailler indépendamment au même moment (un `git checkout` d'un agent basculerait immédiatement les fichiers sous les pieds de l'autre agent).

Lorsque deux agents (ex. un agent de correction et un agent d'audit) travaillent simultanément sur la même machine, chaque agent doit disposer de son propre **worktree Git** dans un répertoire parent dédié (et jamais dans `/tmp`, qui est purgé au redémarrage) :

```bash
# Depuis le dépôt principal :
mkdir -p ../worktrees
git fetch origin --prune

# Créer un worktree isolé pour l'agent A :
git worktree add -b fix/nom-tache-a ../worktrees/fix-nom-tache-a origin/consolidate/map-1914-geometry

# Créer un second worktree isolé pour l'agent B :
git worktree add -b audit/nom-tache-b ../worktrees/audit-nom-tache-b origin/consolidate/map-1914-geometry

# Lister les worktrees actifs :
git worktree list -v
```
Tous les worktrees partagent automatiquement la même base d'objets `.git` et le même remote `origin`, tout en disposant chacun d'un arbre de fichiers 100 % indépendant.

### Sur plusieurs ordinateurs : un clone par machine
Chaque ordinateur possède son propre clone local créé avec `git clone`. Avant de commencer une session :
1. Exécuter `git fetch origin --prune`.
2. Inspecter les branches publiées par les autres machines (`git branch -r --sort=-committerdate`).
3. Créer sa propre branche de mission et la pousser dès la fin de la tâche (`git push -u origin <branche>`).

---

## 5. Gestion des conflits et arbitrage

En cas de divergence ou de conflit entre deux branches ou deux agents :
1. **Ne supprimer aucune modification** et n'exécuter jamais `git push --force` sur `main` ni sur la branche d'un autre agent.
2. **Ne privilégier arbitrairement aucune version** lorsque le choix a un impact historique, géographique ou de conception.
3. **Identifier précisément les différences** (`git log --graph --oneline <branche-A>...<branche-B>`, `git diff <branche-A>...<branche-B>`).
4. **Documenter le conflit** dans un rapport sous `docs/map/audit/` ou `docs/decisions/`.
5. **Demander un arbitrage explicite** au directeur de conception avant toute fusion.
