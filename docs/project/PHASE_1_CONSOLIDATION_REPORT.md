# RAPPORT DE PHASE 1 — CONSOLIDATION TECHNIQUE ET DOCUMENTAIRE

- **Date :** 14 novembre 2026
- **Branche :** `consolidate/phase-1`, construite sur `docs/project-handover-audit` (`34e4a63`), elle-même construite sur `40a3117`.
- **Mandat :** tâches 1 à 4 et inventaire du prototype (section 5 de la mission de phase 1).
- **Hors mandat, non fait :**
  - aucun gameplay ;
  - aucune décision de conception ;
  - aucune fusion dans `main` ;
  - aucune suppression de branche ;
  - aucune réécriture d'historique ;
  - aucun force push ;
  - aucune modification des données cartographiques, des villes ou des ressources.

---

## Partie I — Environnement

### Dépendances

`tools/map/requirements.lock`, inchangé et conservé tel quel :

| Paquet | Version |
|---|---|
| Python | 3.12 |
| shapely | 2.2.0 |
| pyproj | 3.8.0 |
| pyogrio | 0.13.0 |
| numpy | 2.5.4 |
| certifi | 2026.10.23 |
| packaging | 26.3 |

Ce sont exactement les versions de l'ancien venv `/tmp/opencode/gs1914-gis-venv`, vérifiées avec `uv pip freeze`. pyogrio embarque GDAL : aucune bibliothèque système n'est requise.

### Installation durable

- Environnement : `~/.venvs/gs1914-gis`, hors du dépôt et hors de `/tmp`.
- Le système ne fournit pas `ensurepip` (`python3 -m venv` échoue sans `python3-venv`). L'installation passe donc par `uv`, déjà présent sur le poste :
  - `uv venv --python /usr/bin/python3 ~/.venvs/gs1914-gis`
  - `VIRTUAL_ENV=~/.venvs/gs1914-gis uv pip install -r tools/map/requirements.lock`
- La procédure alternative avec la bibliothèque standard est documentée dans `tools/map/README.md` §2.

### Commandes

| Commande | Rôle |
|---|---|
| `tools/map/validate_all.sh` | **Nouveau.** Point d'entrée unique : empreintes, puis les 4 validateurs |
| `tools/map/validate_all.sh --full` | Ajoute la reconstruction **complète** de la géométrie dans une copie temporaire, comparée octet pour octet |
| `tools/map/REFERENCE_SHA256SUMS` | **Nouveau.** Les 5 empreintes de référence du dossier |
| `tools/map/README.md` | **Nouveau.** Dépendances, installation, commandes individuelles, CI, procédure de modification d'une donnée de référence |

### Résultats des validateurs [exécutés réellement]

| Contrôle | Local (Python 3.12.3) | GitHub Actions (Python 3.12.16) |
|---|---|---|
| Empreintes (5 fichiers) | OK | OK |
| `validate_geometry.py` | 90/90, 0 chevauchement, Saray OK, Strumica 072 = vrai et 074 = faux, 0/4 lacune | idem |
| `validate_atlas.py` | OK (avertissement connu : pas d'emprise de référence) | idem |
| `validate_topology.py` | **93 contrôles, 0 échec** | idem |
| `validate_topology.py --rebuild-check` | **95 contrôles, 0 échec** (topologie identique octet pour octet) | idem |
| Reconstruction géométrique (`consolidate_geometry.sh` en copie) | `regions.geojson`, `regions.json`, `geometry_gaps_report.json`, `strumica_salient_report.json` **identiques** | **identiques** |
| Durée | ≈ 2 min 40 s | ≈ 1 min 25 s |

**Test négatif [exécuté] :** dans une copie jetable, l'altération d'un octet de `adjacency.json` fait échouer `validate_all.sh` (code de sortie 1).

### GitHub Actions

- Workflow : `.github/workflows/map-validation.yml`, sur Ubuntu 24.04 avec Python 3.12 (`actions/setup-python@v5`).
- Il installe `requirements.lock` avec `--no-deps`, lance `validate_all.sh --full`, puis `git diff --exit-code`.
- Il se déclenche :
  - sur push et pull request touchant `data/world/map/**`, `tools/map/**`, `docs/map/corrections/**` ou le workflow ;
  - manuellement (`workflow_dispatch`).
- Permissions : `contents: read`.
- Premier passage : run `43601951732` sur `consolidate/phase-1`, **succès**. La reconstruction complète a été vérifiée dans le journal.

### Reproductibilité

La géométrie et la topologie sont reproduites **octet pour octet sur deux machines**, avec deux révisions de Python 3.12 différentes. C'est un résultat plus fort que ce qu'exigeait le dossier, qui ne vérifiait que la topologie.

---

## Partie II — Documentation

### Fichiers modifiés ou créés

| Fichier | Changement |
|---|---|
| `AGENTS.md` | Rejoué depuis `2d7bb5c` (antérieur à Strumica), puis mis à jour : §0 repères (répertoire de référence, deux lignées, prototype gelé, moteur non décidé, T-029 ouvert) ; arborescence réelle (topologie, CI, `docs/project`, `docs/legacy`) ; état de l'atlas (Strumica validée, topologie reconstruite, anomalies connues) ; statuts jamais promus et ADR immuables ; dépôt **public** et absence de données personnelles ; `validate_all.sh` obligatoire |
| `CONTRIBUTING.md` | Rejoué depuis `2d7bb5c`, puis mis à jour : dépôt public (droits d'écriture et scope `workflow`) ; branches de référence (main ≠ référence, base `consolidate/phase-1`) ; venv durable via `uv` ; `validate_all.sh` ; §6 CI ; §7 ce qu'un agent ne peut pas décider |
| `README.md`, `.gitignore`, `docs/map/audit/GITHUB_CENTRALIZATION_AND_BRANCH_AUDIT.md` | Apportés par le rejeu de `2d7bb5c`, sans conflit. L'audit de centralisation est un rapport **daté** (13/11) qui mentionne encore « privé » ; il est conservé tel quel comme trace historique. |
| `docs/project/PROJECT_HANDOVER_AUDIT.md` | Correctif : dépôt **PUBLIC** depuis le 14/11/2026 (vérifié avec `gh repo view`) |
| `docs/decisions/DECISIONS_PENDING.md` | Ajout de la section K (renvoi vers les documents rapatriés) ; **aucune ligne existante modifiée** |
| `docs/decisions/README.md` | **Nouvel** index, qui reprend les statuts déclarés par chaque document |
| `docs/decisions/RAPATRIEMENT_LIGNEE_OCT31.md` | **Nouveau** : provenance, versions concurrentes, liens non résolus, contradictions R-01 à R-12 |
| `docs/project/OBSOLETE_WORKSPACES.md`, `PYTHON_PROTOTYPE_INVENTORY.md`, `MAIN_ALIGNMENT_PLAN.md`, ce rapport | **Nouveaux** |
| `tools/map/README.md`, `validate_all.sh`, `REFERENCE_SHA256SUMS`, `.github/workflows/map-validation.yml` | **Nouveaux** (partie I) |

### Provenance des documents rapatriés

13 fichiers ont été copiés octet pour octet ; le SHA-256 de chaque copie est égal à celui du blob d'origine. Le détail figure dans `docs/decisions/RAPATRIEMENT_LIGNEE_OCT31.md` §3.
- **Depuis `2a341d1`** : ADR 0000 à 0005, T-029, `founding-document-v0.1.md`, `design-review-v0.1.md`, l'ancien `PROJECT.md` (table D-001 à **D-030**) et la variante T-029 de l'index ADR.
- **Depuis `cdd3ab1`** : ADR-0006 et la variante MVP de l'index ADR.

### Statuts préservés

| Document | Statut |
|---|---|
| T-029 | « Document de travail, ne vaut pas décision ». D1 à D5 ouvertes, **S1 non approuvé**. |
| ADR-0005 | « Proposé, ne vaut pas décision » |
| ADR-0006 | « accepté (délégation technique du propriétaire, 2026-10-31) », historique exact conservé. L'index précise l'orientation du 14/11 : prototype gelé, moteur non décidé. |
| ADR 0001 à 0004 | « Accepté », inchangées |
| Design review v0.1 | « Non validée, gelée » |

### Conflits documentaires signalés, non résolus

Ils sont détaillés dans `RAPATRIEMENT_LIGNEE_OCT31.md` §6 :
- **R-01** : ADR-0006 (Python) face au gel du gameplay et à la proposition Godot ;
- **R-02** : ADR-0003 caduque mais non remplacée ;
- **R-03** : sens de « trois ressources » (D-018 face à §10) ;
- **R-04** : victoire « diplomatique » (A) face à « collective » (B) ;
- **R-05** : échelle de 1 à 10 des statistiques (D-027) face à NAT-01 « À DÉFINIR » ;
- **R-06** : Allemagne sans colonies exploitables (D-028), à reconfirmer ;
- **R-07** : D-010, relations à trois états, absente de B ;
- **R-08** : 30 minutes « décidées » (A) face à « envisagées » (B) ;
- **R-09** : D-023, interception exacte, absente de B ;
- **R-10** : province ou région ;
- **R-11** : chemin de dépôt obsolète ;
- **R-12** : identifiants C-xx sans concordance avec ceux du registre B.

---

## Partie III — Git

### Branches utilisées

| Branche | Rôle | Publiée |
|---|---|---|
| `docs/project-handover-audit` | Audit de reprise (`34e4a63`) | oui |
| `consolidate/phase-1` | Travail de la phase 1 | oui |
| `integrate/main-alignment-preview` | Prévisualisation du commit de jonction, **pas `main`** | oui |

### Commits de `consolidate/phase-1` (depuis `34e4a63`)

| Commit | Objet |
|---|---|
| `3f49035` | ci(map) : environnement durable et validation automatisée |
| `f1da297` | docs(project) : correctif de visibilité dans l'audit |
| `3f91fd6` | docs(decisions) : rapatriement de T-029, des ADR 0000 à 0006 et du document fondateur |
| `cc3cdc5` | docs(infra) : rejeu de `2d7bb5c` (`cherry-pick -x`, sans conflit) |
| `5762708` | docs(infra) : mise à jour d'AGENTS et CONTRIBUTING sur la lignée validée |
| `be0739d` | docs(project) : inventaire et archivage des répertoires obsolètes |
| `75b9cc8` | docs(project) : inventaire du prototype et plan d'alignement de `main` |
| *(commit suivant)* | docs(project) : le présent rapport |

`git diff --stat 40a3117..consolidate/phase-1 -- data/ tools/map/*.py tools/map/*.sh` est **vide** : aucune donnée ni aucun script cartographique existant n'a été modifié.

### Historique préservé

- Aucune branche supprimée.
- Aucun `--force`, aucune réécriture.
- Les 30 branches distantes d'origine sont inchangées. Leur liste a été capturée par `git ls-remote` avant les travaux et comparée après chaque publication : seules les nouvelles branches apparaissent.
- Seules métadonnées retirées : 6 enregistrements de worktrees `/tmp` disparus (`git worktree prune`, après simulation).

### État de `main`

**Inchangé** : `origin/main` = `1ec985f` (lignée du 31/10).

### Plan de fusion proposé

Le plan figure dans `docs/project/MAIN_ALIGNMENT_PLAN.md`. Il est **préparé, pas exécuté**.

- Un commit de préparation copie dans `docs/legacy/oct31/` les 31 fichiers de `1ec985f` absents de B et les versions de A des fichiers en conflit, octet pour octet.
- Un commit de jonction (`git commit-tree`) a pour arbre celui de B, pour parent 1 `1ec985f` et pour parent 2 la lignée B.
- Publication par **fast-forward** de `main`, après validation.

**Vérifications sur `integrate/main-alignment-preview` [exécutées] :**
- Parents corrects ; `1ec985f`, `4ffdb8a`, `a7983e7`, `03bce80`, `47bc6fe`, `6d30a51`, `40a3117` et `34e4a63` sont tous ancêtres.
- `origin/main` est ancêtre : **fast-forward possible**.
- **46/46** fichiers de `1ec985f` présents à l'identique dans l'arbre fusionné.
- 105/109 fichiers de `40a3117` inchangés ; les 4 modifiés sont les mises à jour volontaires de la phase 1.
- Empreintes de référence OK ; `validate_all.sh` vert.
- `archive/oct31-main-t029` et `archive/oct31-mvp-playable` ne deviennent pas ancêtres de `main` et restent intactes.

### Risques

- Confusion entre documents `legacy` et documents de référence (atténuée par les en-têtes et `AGENTS.md` §0).
- Liens internes des documents de A non résolus (documentés).
- Évolution de `main` avant l'exécution (vérification prévue dans la procédure).

---

## Partie IV — Prototype Python

L'inventaire complet figure dans `docs/project/PYTHON_PROTOTYPE_INVENTORY.md`.

- **Architecture :**
  - Python 3.12, bibliothèque standard seule ;
  - moteur procédural sur un `GameState` sérialisable ;
  - serveur HTTP local avec interface SVG/JS ;
  - paramètres dans `config.json` marqué `provisional`.
- **Volume [mesuré] :** environ 3 300 lignes de Python, 1 760 lignes web, 282 lignes de tests et 108 Ko de données. Les « ~11 000 lignes » du dossier comprennent documentation et données.
- **Fonctionnalités présentes :**
  - tour mensuel ;
  - économie à trois ressources et main-d'œuvre ;
  - armées et batailles **automatiques** ;
  - ravitaillement et brouillard ;
  - diplomatie simple et alliances en cascade ;
  - recherche, événements (Sarajevo) ;
  - victoire ;
  - sauvegarde ;
  - mode observation.
- **Absents :**
  - batailles tactiques ;
  - mémoire, confiance et tromperie de l'IA ;
  - atlas validé : la carte est **hexagonale et synthétique**, avec 90 provinces sans lien avec `regions.geojson`.
- **Tests [mesuré] :** 24/24 OK en 1,6 s. Déterminisme vérifié (même graine, même état). La commande du `tests/README.md` est erronée (défaut mineur).
- **Qualité [estimée] :** propre et lisible pour un prototype, mais procédurale, sans interfaces, et l'IA peut accéder à tout l'état.
- **Contradictions avec les décisions actuelles :**
  - **moral des armées**, alors que D-016 l'exclut ;
  - départ en **juin 1914** au lieu du 1er janvier ;
  - carte non conforme à l'atlas ;
  - victoire « diplomatique » à 70 % ;
  - IA sans mémoire ;
  - valeurs non sourcées.
  - De plus, la partie d'observation s'achève en janvier 1917 sur une **victoire économique ottomane**.
- **Comparaison préliminaire avec Godot [estimée, non mesurée] :**
  - le code réutilisable pour le jeu cible est faible dans les deux voies : seuls les concepts et le moteur de tour comptent ;
  - la bataille tactique en temps réel et la carte riche penchent vers un moteur de jeu ;
  - la testabilité sans interface et l'outillage Python actuel penchent vers Python.
  - **Pour mesurer :** prototypes techniques neutres comparables (rendu de l'atlas, bataille fictive), puis ADR 0007, sur autorisation.

---

## Partie V — État général

| Tâche | État | Référence |
|---|---|---|
| T1 — Environnement durable et CI | **Terminée** | `3f49035`, run `43601951732`, `tools/map/README.md` |
| T2 — AGENTS.md et CONTRIBUTING.md | **Terminée** | `cc3cdc5`, `5762708` |
| T3 — Rapatriement de T-029, des ADR et du document fondateur | **Terminée** ; contradictions **nécessitant une décision** (R-01 à R-12) | `3f91fd6`, `RAPATRIEMENT_LIGNEE_OCT31.md` |
| T4 — Répertoires obsolètes | **Terminée** (archivage) ; suppression éventuelle **nécessitant une décision** | `be0739d`, `OBSOLETE_WORKSPACES.md` |
| Correctif de visibilité (D) | **Terminée** | `f1da297` |
| Alignement de `main` (A) | **Préparée, nécessitant une décision** (validation explicite du plan) | `MAIN_ALIGNMENT_PLAN.md`, `integrate/main-alignment-preview` |
| Inventaire du prototype (C, section 5) | **Terminée** ; choix du moteur **nécessitant une décision** | `75b9cc8`, `PYTHON_PROTOTYPE_INVENTORY.md` |
| T-029 (B) | **Inchangé, ouvert** (non traité, conformément au mandat) | — |

### Anomalies découvertes pendant la phase 1

1. **Dépôt public sans fichier `LICENSE`** : le code et les données sont publiés sans conditions de réutilisation explicites.
2. **Licences des extraits de sources versionnés à confirmer**, maintenant que le dépôt est public :
   - `data/world/map/sources/README.md` indique « licence geoBoundaries à reconfirmer avant distribution » (Saray) ;
   - les extraits REGIS et RISTAT n'ont pas de licence établie ;
   - le substitut Kavanagh est en CC BY 4.0, ce qui impose une attribution ;
   - l'ancien `GIT_RECOVERY_REPORT.md` recommandait de **ne pas** publier le dépôt pour cette raison.
   - Les sources brutes REGIS (373 Mo) restent locales et ne sont pas publiées.
3. `python3-venv`/`ensurepip` absent du système. Contourné avec `uv`, et documenté.
4. La commande de test documentée dans le prototype est erronée.
5. Le prototype contredit D-016 (moral) et la date de référence (juin 1914).
6. Les rapports d'audit datés (`GITHUB_CENTRALIZATION…`, `GIT_RECOVERY_REPORT`) mentionnent encore « privé ». Ils sont conservés comme traces historiques.
