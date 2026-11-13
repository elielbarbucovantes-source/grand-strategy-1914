# AGENTS.md — Point d'entrée commun et règles de travail des IA

> **Statut du projet :** CONCEPTION EN COURS — **DÉVELOPPEMENT DU GAMEPLAY STRICTEMENT INTERDIT SANS AUTORISATION EXPLICITE DU DIRECTEUR DE CONCEPTION (`GATE-01`)**
> **Dépôt central GitHub (privé) :** `https://github.com/elielbarbucovantes-source/grand-strategy-1914` (`origin`)
> **Portée :** Ce document constitue la constitution commune de toutes les intelligences artificielles et de tous les environnements de travail (locaux ou multi-ordinateurs) intervenant sur **Grand Strategy-1914**.

---

## 1. Présentation du projet et objectifs

**Grand Strategy-1914** est une simulation géopolitique et militaire de grande stratégie prenant pour point de départ l'Europe du **1er janvier 1914**. Le joueur dirige un État en tant que chef de l'État ; tous les autres pays sont gouvernés par des intelligences artificielles autonomes.

La formule directrice du projet est :

> **« Le joueur dirige son pays, mais ne dirige pas le monde. »**

### Les trois piliers d'égale importance
Toute proposition, analyse ou donnée doit équilibrer trois priorités indissociables :
1. **Profondeur stratégique** : décisions nationales aux conséquences durables et interdépendantes (diplomatie, économie, industrie, logistique, armées, renseignement, politique intérieure).
2. **Autonomie convaincante de l'IA** : les États non contrôlés poursuivent leurs propres intérêts, négocient, forment des coalitions, peuvent se tromper, mentir ou trahir, sans omniscience ni triche d'information.
3. **Réalisme historique** : situations de départ au 1er janvier 1914, capacités nationales, contraintes géographiques et rapports de force historiquement sourcés et crédibles.

### Périmètre de la V1
- **Inclus** : campagne historique 1914 en Europe (de l'Atlantique à l'Oural, Scandinavie et Balkans compris), 7 grandes puissances jouables (Empire allemand, Royaume-Uni / Empire britannique, France, Empire russe, Autriche-Hongrie, Italie, Empire ottoman), autres États européens autonomes gérés par l'IA, atlas de **90 régions terrestres** indivisibles en V1, tours mensuels à résolution simultanée d'ordres secrets, batailles tactiques déclenchées uniquement par les offensives, mode solo et mode observation.
- **Exclus de la V1** : gestion démographique individuelle, parlements détaillés, stocks économiques provinciaux indépendants, opérations clandestines/sabotage joueur, carte coloniale détaillée (colonies abstraites), campagnes multiples, multijoueur en V1 (architecture préparée pour l'après-solo), technologies post-1945.

---

## 2. Interdictions absolues

1. **Interdiction de développer le gameplay (`GATE-01`)** :
   **Il est formellement interdit de commencer le développement du gameplay sans une autorisation explicite de l'utilisateur (directeur de conception).** Cela inclut les règles exécutables, données de gameplay, système de tours fonctionnel, moteur de simulation, IA de jeu, carte jouable, économie, diplomatie, politique, armées, batailles, interface de jeu ou contenu jouable. La préparation documentaire, l'architecture et les outils purement techniques/cartographiques explicitement mandatés (comme les scripts de construction et validation GIS de l'atlas) sont autorisés mais ne doivent jamais préremplir de mécanique de gameplay. Les anciennes consignes du dossier initial qui demandaient une première partie jouable sont **annulées**.
2. **Interdiction de modifier les décisions validées sans autorisation** :
   Aucune IA ne peut modifier, contredire ou remplacer une décision marquée **VALIDÉ** dans `PROJECT.md`, `docs/map/TECHNICAL_SPEC.md` (`MAP-DEC-01` à `MAP-DEC-69`) ou `docs/decisions/DECISIONS_PENDING.md` sans autorisation explicite du directeur de conception. Une proposition ou hypothèse d'agent ne devient jamais une décision validée d'elle-même.
3. **Interdiction de travailler directement sur `main` ou de réécrire l'historique** :
   Aucune IA ne doit travailler directement sur `main`, effectuer un `git push --force` sur `main`, fusionner arbitrairement des branches, ni supprimer des branches, des commits, des rapports ou des sauvegardes.

---

## 3. Architecture des dossiers

```text
grand-strategy-1914/
├── AGENTS.md                        # Point d'entrée obligatoire et règles pour toutes les IA
├── CONTRIBUTING.md                  # Guide opérationnel multi-IA, multi-ordinateurs et worktrees
├── PROJECT.md                       # Document maître de conception (vision, piliers, règles VALIDÉES)
├── PROGRESS.md                      # Tableau de bord de l'avancement, jalons et blocages
├── CHANGELOG.md                     # Journal chronologique des évolutions documentaires et techniques
├── STRUCTURE.md                     # Vue d'ensemble de l'arborescence
├── README.md                        # Présentation synthétique du dépôt
├── project.godot                    # Coquille Godot (aucune scène ni logique de gameplay)
├── docs/
│   ├── architecture/
│   │   ├── PRINCIPLES.md            # Principes architecturaux sources
│   │   └── TECHNICAL_ARCHITECTURE.md# Proposition d'architecture modulaire (Godot 4.7.2 + GDScript typé)
│   ├── decisions/
│   │   └── DECISIONS_PENDING.md     # Registre des décisions VALIDÉES et À DÉFINIR
│   ├── map/
│   │   ├── TECHNICAL_SPEC.md        # 69 décisions cartographiques VALIDÉES + spécification technique
│   │   ├── ATLAS_BUILD_STATUS.md    # Statut éditorial de construction de l'atlas à 90 régions
│   │   ├── audit/                   # Rapports d'audit (GLOBAL_AUDIT, GEOMETRY_CONSOLIDATION, etc.)
│   │   └── corrections/             # Rapports et métriques de correction (MAJ-004, MAJ-003, topologie)
│   └── {gameplay,diplomacy,military,economy,technology,intelligence,ai,nations}/
│       └── OVERVIEW.md / PLAYABLE_POWERS.md
├── data/
│   ├── schemas/map.schema.json      # Schéma JSON formel de l'atlas (plafond 100 régions)
│   └── world/map/
│       ├── tables/region_plan.csv   # Référentiel éditorial validé des 90 régions (region_001..090)
│       ├── sources/                 # Registre des sources et extraits minimaux versionnés (derived/)
│       ├── build/{agent_1,agent_2}/ # Lots sources audités (50 + 40 régions)
│       └── regions.geojson / .json  # Géométries et métadonnées consolidées (selon la branche active)
├── tools/
│   └── map/                         # Scripts reproductibles de construction et validation GIS
│       ├── build_source_extracts.py # Extraction minimale des sources externes vers sources/derived/
│       ├── build_geometry.py        # Assemblage 90 régions + corrections BLK-001 (Saray) et BLK-002
│       ├── close_geometry_gaps.py   # Fermeture reproductible des 4 lacunes MAJ-004
│       ├── fix_strumica_salient.py  # Correction de la frontière 1913 de Stroumitsa (MAJ-003, sur fix/map-strumica-final)
│       ├── consolidate_geometry.sh  # Pipeline complet de reconstruction déterministe
│       ├── validate_atlas.py        # Validateur de l'index éditorial et des géométries
│       ├── validate_geometry.py     # Validateur géométrique strict (OGC, chevauchements, sentinelles)
│       └── requirements.txt / .lock # Dépendances Python GIS (shapely, pyogrio, pyproj)
├── prompts/OPENCODE_PROMPT.md       # Instructions harmonisées pour agents
├── src/                             # Squelette de répertoires (aucun code de gameplay autorisé)
├── tests/                           # Squelette de tests
└── assets/                          # Squelette d'assets
```

---

## 4. Documents de conception prioritaires (ordre d'autorité)

Avant toute intervention, chaque IA doit lire dans cet ordre :
1. **`AGENTS.md`** (ce fichier) — règles impératives de gouvernance, sécurité, validation et collaboration.
2. **`PROJECT.md`** — document maître du projet et principes de conception validés.
3. **`PROGRESS.md`** — état réel d'avancement, jalons et chantiers en cours.
4. **`docs/decisions/DECISIONS_PENDING.md`** — registre distinguant les décisions **VALIDÉES** des points **À DÉFINIR** ou **BLOQUÉS**.
5. **`docs/map/TECHNICAL_SPEC.md`** et **`data/world/map/tables/region_plan.csv`** — pour toute mission touchant à la carte ou à l'atlas de 1914.
6. **`docs/map/audit/PROJECT_STATUS.md`**, **`docs/map/audit/CONTINUATION_PLAN.md`** et **`docs/map/audit/GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md`** — pour connaître l'état exact des branches cartographiques et des audits.
7. **`CONTRIBUTING.md`** — procédure Git multi-IA, multi-ordinateurs et worktrees.

En cas de contradiction entre deux documents, **signaler immédiatement le conflit** sans trancher arbitrairement ; les décisions explicites du directeur de conception et l'interdiction de développer le gameplay priment toujours.

---

## 5. Décisions validées vs décisions en attente

### Statuts normatifs obligatoires
- **VALIDÉ** : décision explicitement confirmée par le directeur de conception (intouchable sans nouvel arbitrage).
- **PROPOSITION** : recommandation technique ou architecturale non encore entérinée comme règle.
- **HYPOTHÈSE À VALIDER** : hypothèse temporaire formulée pour une analyse isolée.
- **À DÉFINIR** : paramètre, formule ou règle de conception non encore tranché.
- **BLOQUÉ** : dépend d'un arbitrage du directeur ou d'une ressource externe.
- **IMPLÉMENTÉ** / **TESTÉ** : présent dans l'outillage autorisé et vérifié par exécution réelle des tests.

### Principales décisions VALIDÉES à préserver impérativement
- **Identité et boucle** : point de départ au 1er janvier 1914, tours mensuels simultanés à ordres secrets, 7 puissances jouables, mode solo initial + mode observation, absence de multijoueur en V1.
- **Décisions cartographiques `MAP-DEC-01` à `MAP-DEC-69`** :
  - Plafond de 100 régions terrestres ; cible éditoriale fixée à **90 régions** (`region_001` à `region_090` dans `data/world/map/tables/region_plan.csv`), avec le **Pays de Galles** comme région distincte (`region_003`).
  - Frontières politiques de référence au **1er janvier 1914** (Alsace-Lorraine allemande, Trentin/Trieste/Istrie/Bosnie-Herzégovine austro-hongrois, Irlande entière britannique, Islande danoise, Finlande/Pologne/pays baltes russes, Quadrilatère de Dobroudja roumain, Thrace occidentale et saillant de Stroumitsa bulgares au traité de Bucarest d'août 1913, Edirne ottomane).
  - Zoom libre du niveau continental au niveau régional, affichage adaptatif des noms (les noms ordinaires peuvent être masqués, mais **les noms de capitales restent toujours visibles** selon `MAP-DEC-41`), regroupement automatique des unités selon le zoom, flottes placées au centre de leur zone maritime.
  - Occupation militaire représentée par hachures aux couleurs de l'occupant sans déplacement visuel des frontières souveraines ; absence de marquage cartographique dédié pour les revendications contestées (`MAP-DEC-51`).
  - Seuil de victoire militaire fixé au contrôle d'au moins 90 % des régions (`MAP-DEC-13`).

### Principales décisions EN ATTENTE (`À DÉFINIR` / `BLOQUÉ`)
- **Atlas et données thématiques** : validation finale de l'atlas par le directeur (`MAP-OPEN-01`), reconstruction de la topologie (`adjacency.json`) sur la géométrie finale, unification des terrains/infrastructures/zones maritimes (`MAJ-001`, `MAJ-002`, `MAJ-006`), inventaire des routes (`MAP-DEC-08`) et arbitrage sur le périmètre des ressources naturelles.
- **Mécaniques et formules chiffrées** : formules des 12 statistiques nationales (`NAT-01` à `NAT-05`), unités/prix/budgets économiques (`ECO-01` à `ECO-07`), ordre de bataille et règles tactiques (`MIL-01` à `MIL-09`), catalogue diplomatique et cognition IA (`DIP-01` à `AI-05`), arbre technologique (`TECH-01`), calcul détaillé des cas particuliers de victoire à 90 % (`MAP-OPEN-11`/`MAP-OPEN-16`) et formule de victoire socio-économique (`WIN-02`).
- **Architecture et plateformes** : confirmation des plateformes cibles (`UX-01`) et validation du prototype technique neutre Godot 4.7.2 (`ARCH-01`).

---

## 6. Règles de collaboration multi-IA et procédure de contribution

Le dépôt GitHub `origin` (`https://github.com/elielbarbucovantes-source/grand-strategy-1914.git`) est le point de synchronisation unique entre toutes les IA et tous les ordinateurs.

### Règles d'or de collaboration
1. **Ne jamais travailler directement sur `main`** : toute mission s'effectue sur une branche dédiée nommée selon la convention :
   - `feature/<nom>`
   - `fix/<nom>`
   - `docs/<nom>`
   - `audit/<nom>`
   - `research/<nom>`
   - `consolidate/<nom>` ou `integrate/<nom>` (pour les consolidations explicitement mandatées)
2. **Un agent = un répertoire de travail isolé** :
   - Sur **un même ordinateur**, deux agents ne doivent jamais travailler simultanément dans le même répertoire. Utiliser obligatoirement un **worktree Git dédié** (`git worktree add ../worktrees/<nom-branche> -b <type>/<nom> <base>`).
   - Sur **plusieurs ordinateurs**, chaque machine dispose de son propre clone complet et synchronise son travail via `git fetch origin` et `git push -u origin <branche>`.
3. **Ne jamais écraser ni fusionner sans contrôle** :
   - En cas de divergence ou de conflit entre branches, **ne supprimer aucune modification**, ne privilégier arbitrairement aucune version, documenter précisément les différences et demander l'arbitrage de l'utilisateur.
   - Les fusions vers `main` sont soumises à contrôle strict et validation explicite.

### Procédure obligatoire en 7 étapes pour chaque mission
1. **Synchroniser** : `git fetch origin --prune` et inspecter l'état des branches (`git branch -a -vv`).
2. **Isoler** : créer une branche dédiée (et un worktree dédié si plusieurs tâches coexistent sur la machine) à partir de la branche de référence indiquée par la mission.
3. **Exécuter dans le périmètre** : modifier uniquement les fichiers relevant de la mission, sans altérer le travail d'une autre mission ni toucher aux régions/données hors périmètre.
4. **Valider** : exécuter les validateurs et tests requis (ex. `tools/map/validate_geometry.py`, `tools/map/validate_atlas.py`) et vérifier `git diff` / `git status`.
5. **Committer** : créer un commit atomique et explicite (`type(portée): description concise`).
6. **Publier** : pousser la branche vers GitHub (`git push -u origin <nom-branche>`).
7. **Rendre compte** : fournir à l'utilisateur la liste exacte des fichiers créés/modifiés, le nom de la branche, le hash complet du commit, les résultats des validateurs et les points restant à arbitrer.

---

## 7. Règles de sécurité et de fiabilité

- **Confidentialité absolue du dépôt** : le dépôt GitHub `grand-strategy-1914` est **privé** (`PRIVATE`) et ne doit jamais être rendu public.
- **Zéro secret dans Git** : ne jamais inscrire de mot de passe, token GitHub (`ghp_`, `gho_`, `github_pat_`), clé privée SSH/TLS ou identifiant sensible dans un fichier suivi, un script ou une URL de remote. Utiliser `gh auth login` (keyring système) ou SSH.
- **Propreté du versionnement** : respecter `.gitignore` (ne jamais committer `.venv/`, `__pycache__/`, `.godot/`, `/backups/`, `.consolidation-stage*/`, ni de fichiers temporaires).
- **Reproductibilité hors `/tmp`** : ne jamais stocker un livrable, une source dérivée ou un rapport uniquement dans `/tmp`. Tout artefact produit par une mission doit être versionné dans le dépôt, accompagné des scripts et extraits sources (`data/world/map/sources/derived/`) nécessaires à sa reproduction déterministe.
- **Préservation des sauvegardes** : ne jamais supprimer les bundles Git ou sauvegardes locales (`/home/cassiop-e/backups/`).

---

## 8. Règles de validation et d'audit indépendant

- **Honnêteté des vérifications** : ne jamais déclarer qu'un test ou validateur a réussi s'il n'a pas été réellement exécuté. Toujours rapporter la commande exacte et sa sortie.
- **Distinction entre validation géométrique et validation définitive** :
  - Le passage des scripts techniques (`tools/map/validate_geometry.py`, `tools/map/validate_atlas.py`) et du test de reproductibilité bit-à-bit (`tools/map/consolidate_geometry.sh`) est **nécessaire mais non suffisant**.
  - Aucune correction cartographique majeure (telle que la consolidation géométrique ou la résolution de Stroumitsa `MAJ-003` sur `fix/map-strumica-final`) ni l'atlas global ne doivent être déclarés définitivement validés tant que **l'audit indépendant** et **l'approbation du directeur de conception** ne sont pas achevés.
