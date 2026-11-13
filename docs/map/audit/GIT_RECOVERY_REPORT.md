# RAPPORT — RÉCUPÉRATION ET SÉCURISATION GIT

- **Date** : 13 novembre 2026
- **Dépôt** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **HEAD au moment du rapport** : branche `fix/map-thematic-data`, commit `b5a07ae`
- **Nature** : diagnostic et préparation en **lecture seule**. Aucune branche fusionnée, aucun worktree supprimé, aucune géométrie modifiée, aucun commit créé, aucun push effectué.
- **Objet** : vérifier l'état des branches et worktrees, inventorier le non-commité et le non-versionné, proposer une stratégie de sauvegarde et **préparer** la configuration d'un remote sans publier ni pousser.

---

## 1. ÉTAT GIT CONSTATÉ

| Élément | Constat |
|---|---|
| Remote configuré | **aucun** (`git remote -v` vide) |
| Branches avec upstream | **aucune** (`git branch -vv` sans `[origin/...]`) |
| Stash | **aucun** (`git stash list` vide) |
| Tags | **aucun** |
| Taille de `.git` | ≈ 7,6 Mio, 229 objets, **aucun packfile** (`in-pack: 0`) |

**Conséquence** : l'intégralité du travail cartographique n'existe que sur ce disque, dans un dépôt **sans copie distante ni sauvegarde**. Une perte du répertoire serait irréversible.

### 1.1 Branches locales et commits

| Branche | Commit | Rôle | Contenu réel |
|---|---|---|---|
| `main` | `4ffdb8a` | Socle documentaire | Docs + schéma + `region_plan.csv` ; aucune donnée cartographique |
| `agent_1` | `286975a` | Lot 1 (50 régions) | Géométries, villes, terrain, infra, adjacence interne |
| `agent-2` | `baa0c90` | Lot 2 (40 régions) | Idem + `maritime_zones.json` |
| `audit/map-1914` | `b5a07ae` | Audit global | `GLOBAL_AUDIT.md`, `ISSUES.json`, `INTEGRATION_CHECKLIST.md`, validateur |
| `fix/map-geometry` | `b5a07ae` | — | **Branche vide** (pointe sur le commit d'audit) |
| `fix/map-geometry-v2` | `fc26c18` | Géométrie assemblée | `regions.geojson`/`regions.json` canoniques ; BLK-001 + BLK-002 corrigées |
| `fix/map-geometry-gaps` | `219373b` | Lacunes MAJ-004 | Script `close_geometry_gaps.py` + rapport ; **données corrigées non commitées** |
| `fix/map-topology` | `b5a07ae` | — | **Branche vide** |
| `fix/map-topology-v2` | `76333e1` | Adjacence unifiée | `adjacency.json` à 184 arêtes |
| `fix/map-thematic-data` | `b5a07ae` | — | **Branche vide** (branche courante) |
| `fix/map-thematic-data-v2` | `4dbf4f8` | Données thématiques | 175 villes/sites unifiés |
| `audit/map-thematic-data` | `8a5d2bf` | Audit thématique | Pointe sur `8a5d2bf` |
| `audit/natural-resources-inventory` | `8a5d2bf` | Inventaire ressources | Pointe sur `8a5d2bf` (même commit) |
| `integrate/map-1914-final-audit` | `219373b` | Intégration | Même commit que `fix/map-geometry-gaps` |

**Observations** :

- `fix/map-geometry-gaps` et `integrate/map-1914-final-audit` pointent sur le **même commit** `219373b`.
- `audit/map-thematic-data` et `audit/natural-resources-inventory` pointent sur le **même commit** `8a5d2bf`.
- Trois branches sont **vides** (aucun travail propre) : `fix/map-geometry`, `fix/map-topology`, `fix/map-thematic-data`.
- Aucune branche n'est fusionnée dans `main` : les artefacts vivent sur des lignes parallèles.

### 1.2 Reflog (activité récente)

```
b5a07ae HEAD@{0}: checkout: moving from audit/map-1914 to fix/map-thematic-data
b5a07ae HEAD@{1}: commit: docs(audit): complete global cartographic audit of the 90-region 1914 atlas
4ffdb8a HEAD@{2}: checkout: moving from agent-2 to audit/map-1914
baa0c90 HEAD@{3}: commit: feat(map/agent-2): build 40 historical 1914 regions
494abe0 HEAD@{4}: checkout: moving from main to agent-2
4ffdb8a HEAD@{5}: commit: docs(map): register 90-region atlas plan and source status
b953a5f HEAD@{6}: commit: docs: reconcile validated map presentation rules
fc01357 HEAD@{7}: commit: docs: integrate validated cartography decisions
5d8579f HEAD@{8}: commit (initial): docs: prepare cartography data foundation
```

---

## 2. WORKTREES

`git worktree list` déclare **7 worktrees**, dont **6 « prunable »** :

| Chemin | Commit | Branche | État réel |
|---|---|---|---|
| `.../grand-strategy-1914` | `b5a07ae` | `fix/map-thematic-data` | **Existe** (dépôt principal) |
| `.../brain/2e364ab6-.../scratch/wt_fix_geometry` | `b5a07ae` | `fix/map-geometry` | **Existe** (568 K) |
| `/tmp/mammouth/gs1914-geometry-audit` | `fc26c18` | detached HEAD | **MISSING** (prunable) |
| `/tmp/mammouth/gs1914-natural-resources` | `8a5d2bf` | `audit/natural-resources-inventory` | **MISSING** (prunable) |
| `/tmp/mammouth/gs1914-thematic-data-audit` | `8a5d2bf` | `audit/map-thematic-data` | **MISSING** (prunable) |
| `/tmp/opencode/gs1914-final-audit` | `219373b` | `integrate/map-1914-final-audit` | **MISSING** (prunable) |
| `/tmp/opencode/gs1914-geometry-gaps` | `219373b` | `fix/map-geometry-gaps` | **MISSING** (prunable) |
| `/tmp/opencode/gs1914-geometry-v2` | `fc26c18` | `fix/map-geometry-v2` | **MISSING** (prunable) |

**Interprétation** : les six répertoires `/tmp/...` ont été effacés (nettoyage `/tmp`) ; Git les marque encore « prunable ». **Aucun travail n'est perdu du fait de leur disparition**, car chaque worktree pointait sur un **commit déjà présent** dans le dépôt principal. Ces entrées sont purement administratives.

**Aucun `git worktree prune` n'a été exécuté** (contrainte : ne supprimer aucun worktree).

Le seul worktree secondaire encore présent (`wt_fix_geometry`) pointe sur `b5a07ae` (`fix/map-geometry`, branche vide) : il ne contient pas de travail propre.

---

## 3. MODIFICATIONS NON COMMITÉES

`git status` (branche `fix/map-thematic-data`) :

```
Fichiers non suivis:
	docs/map/audit/CONTINUATION_PLAN.md
	docs/map/audit/PROJECT_STATUS.md
```

- **Aucune modification** de fichier suivi (`aucune modification ajoutée à la validation`).
- **Deux fichiers non suivis**, tous deux des livrables documentaires produits par la mission précédente :
  - `docs/map/audit/PROJECT_STATUS.md` (18 286 octets)
  - `docs/map/audit/CONTINUATION_PLAN.md` (14 063 octets)

Ces deux rapports sont **à sécuriser** : ils n'existent que dans l'arbre de travail de cette branche et disparaîtraient avec lui. **Ils n'ont pas été committés** (la mission précédente imposait la lecture seule) ; le présent rapport les laisse également non committés, la décision de commit revenant au responsable.

---

## 4. FICHIERS IMPORTANTS NON VERSIONNÉS

Les données externes de construction ne sont **pas** dans le dépôt. Les seuls fichiers versionnés sous `data/world/map/sources/` et `data/world/map/build/*/sources/` sont des **`README.md`** (registre de sources), pas les données. Or plusieurs scripts (et le correctif MAJ-004) dépendent de ces données.

### 4.1 Jeux de données sources (non versionnés)

Répertoire : `/home/cassiop-e/.gemini/antigravity-cli/brain/3ab810c9-cc80-4c2c-b642-e4591b88b9ed/scratch/regis/` — **≈ 373 Mo au total**.

| Fichier | Taille | Usage |
|---|---|---|
| `gb_tur_adm2.geojson` | 3,87 Mo | **BLK-001** : district thrace de Saray (`shapeID 54988432B91991689904144`) |
| `gb_tur_adm1.geojson` | 1,56 Mo | Contexte Turquie |
| `gs1914-europe-1914-low-res.geojson` | 17,1 Mo | **Substitut** Kavanagh 1914 (29 pays, champ `name`) |
| `ristat_1897_provinces.gpkg` | 1,27 Mo | **MAJ-004 Finlande** (`provinces_1897`, champ `prov_ENG`) |
| `ristat_1897_districts.gpkg` | 3,38 Mo | Contexte RISTAT |
| `ristat_raw.bin` | 116 Ko | Source brute RISTAT |
| `gs1914-regis-l0.gpkg` | 46,3 Mo | REGIS niveau 0 (séries temporelles 1870→2020) |
| `REGIS_*.gpkg` (38 fichiers) | ≈ 190 Mo | Sources nationales REGIS (Autriche-Hongrie, Allemagne, Russie, etc.) |
| `REGIS_Europe_L1.gpkg` / `_L2.gpkg` | 72,1 / 88,8 Mo | REGIS niveaux 1 et 2 |
| `REThM_*.gpkg` (5 fichiers) | ≈ 38,9 Mo | Sources REThM |
| `ne_10m_places.geojson` | 4,93 Mo | Natural Earth lieux |
| `ne_10m_rivers.geojson` | 7,31 Mo | Natural Earth rivières |

**Point critique** : le **vrai fichier Kavanagh `europe_1914.gpkg`** (attendu par `close_geometry_gaps.py` avec `layer="europe_1914"`, champ `name`) **est introuvable sur toute la machine**. Recherche exhaustive (`find / -iname "*kavan*"`, `*europe_1914*`, `*.gpkg`) : aucun résultat. Seul le **substitut basse résolution** (`gs1914-europe-1914-low-res.geojson`) permet de rejouer MAJ-004 — voir § 6.

### 4.2 Scripts de construction (non versionnés)

Présents dans des répertoires `scratch` (jamais committés) :

- `.../brain/4ed2aa96-.../scratch/` : `build_agent_1_atlas.py`, `generate_all_agent_1.py`, `validate_agent_1.py`, `test_clean_wgs84.py`, `test_regions.py`
- `.../brain/5fcd7210-.../scratch/` : `build_agent_2_atlas.py`, `generate_all_agent_2.py`, `check_all_slivers.py`, `inspect_districts_and_thrace.py`, `inspect_layers_detail.py`, `inspect_sources.py`, `test_balkan_and_agent1_alignment.py`, `test_prototype_40.py`, `test_seams_and_balkans.py`
- `.../brain/2e364ab6-.../scratch/` : `run_deep_audit.py`, `run_deep_audit_part2.py`, `inspect_specifics.py`

**Note** : les scripts canoniques correspondants **sont** versionnés sur les branches (`tools/map/build_geometry.py`, `build_adjacency.py`, etc.). Les scripts `scratch` sont les **prototypes de construction des lots** ; leur perte dégraderait la traçabilité des lots `agent_1`/`agent-2`.

### 4.3 Notes de recherche (non versionnées)

`/home/cassiop-e/research_notes/Ressources naturelles 1914/` — **280 Ko**, 4 fichiers :

- `regions_001_025.md`
- `regions_026_043_080_086.md`
- `regions_044_069.md`
- `regions_070_079_087_090.md`

Ces notes documentent l'inventaire des ressources naturelles ; elles **contredisent les IDs de `region_plan.csv`** sur certains points et devront être réconciliées lors de l'intégration thématique.

---

## 5. STRATÉGIE DE SAUVEGARDE PROPOSÉE

Aucune de ces actions n'a été exécutée (contraintes de non-publication et de non-modification). Elles sont prêtes à lancer sur décision du responsable.

### 5.1 Sauvegarde complète du dépôt (recommandé, immédiat)

Un **bundle Git** capture **toutes les branches et tous les commits** dans un fichier unique :

```bash
cd /home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914
git bundle create /home/cassiop-e/backups/gs1914-$(date +%Y%m%d).bundle --all
git bundle verify /home/cassiop-e/backups/gs1914-$(date +%Y%m%d).bundle
```

- **Avantage** : un seul fichier restaurable (`git clone <bundle>`), contient les 14 branches et l'historique complet.
- **Taille** : quelques Mo (le dépôt ne pèse que ~7,6 Mo sans packfile).

### 5.2 Sauvegarde de l'arbre de travail (inclut le non-commité)

Pour capturer aussi `PROJECT_STATUS.md` et `CONTINUATION_PLAN.md` **avant** tout commit :

```bash
tar czf /home/cassiop-e/backups/gs1914-worktree-$(date +%Y%m%d).tar.gz \
  --exclude='.git' \
  -C /home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement \
  grand-strategy-1914
```

### 5.3 Sauvegarde des données sources non versionnées (≈ 373 Mo + 280 Ko)

```bash
mkdir -p /home/cassiop-e/backups/gs1914-sources
rsync -a --info=progress2 \
  "/home/cassiop-e/.gemini/antigravity-cli/brain/3ab810c9-cc80-4c2c-b642-e4591b88b9ed/scratch/regis/" \
  /home/cassiop-e/backups/gs1914-sources/regis/
rsync -a \
  "/home/cassiop-e/research_notes/" \
  /home/cassiop-e/backups/gs1914-sources/research_notes/
# prototypes de construction
rsync -a "/home/cassiop-e/.gemini/antigravity-cli/brain/4ed2aa96-.../scratch/"  /home/cassiop-e/backups/gs1914-sources/scratch_agent1/
rsync -a "/home/cassiop-e/.gemini/antigravity-cli/brain/5fcd7210-.../scratch/"  /home/cassiop-e/backups/gs1914-sources/scratch_agent2/
```

> **Note de versionnement** : à terme, ces sources devraient être référencées sous `data/world/map/sources/` **avec licence, période, somme de contrôle** (conformément au `README` des sources) — ou, si la redistribution n'est pas autorisée, remplacées par un **manifeste** (URL, date de téléchargement, SHA-256). Ce point est hors périmètre immédiat (aucune nouvelle construction).

### 5.4 Emplacements et rétention

- **Cible recommandée** : un disque **distinct** du disque de travail, ou un stockage cloud privé.
- **Rétention** : conserver au minimum les 3 dernières sauvegardes datées ; vérifier la restaurabilité du bundle par `git bundle verify` après chaque création.
- **Ne pas** stocker les sauvegardes dans `/tmp` (effacé au redémarrage).

---

## 6. REPRODUCTIBILITÉ DE MAJ-004 DEPUIS LES ARTEFACTS VERSIONNÉS

Question posée : les corrections MAJ-004 sont-elles reproductibles **à partir d'artefacts réellement versionnés** ?

**Réponse : partiellement, avec une réserve importante.**

- **Ce qui est versionné et suffisant** : `tools/map/close_geometry_gaps.py` (616 lignes) et `docs/map/corrections/GEOMETRY_GAPS_RESOLUTION.md` (280 lignes), tous deux sur `fix/map-geometry-gaps` (`219373b`). Le script est déterministe et refuse d'écrire dans `data/world/map`.
- **Ce qui manque** : la **source externe Kavanagh `europe_1914.gpkg`**, introuvable sur la machine et **non versionnée**. Le script la requiert (`--kavanagh`, `layer="europe_1914"`, champ `name`).
- **Substitut utilisé pour le test** : `gs1914-europe-1914-low-res.geojson` (non versionné), 29 pays, contient bien `Austria-Hungary`, `Romania`, `Russia`, `Norway`.

**Résultat du rejeu** (dans `/tmp/opencode/gs1914-maj004-test`, jamais dans le dépôt) :

| Lacune | Surface attendue | Surface reproduite |
|---|---:|---:|
| Finlande / Olonets | 662,474739 km² | 662,474739 km² |
| Tripoint Khotin/Herța | 225,876731 km² | 225,876731 km² |
| Pasvik nord | 117,048461 km² | 117,048461 km² |
| Pasvik sud | 92,085230 km² | 92,085230 km² |
| **Total atlas** | **10 027 648,69 km²** | **10 027 648,69 km²** |

Les surfaces de lacune et la superficie totale **correspondent exactement** à `GEOMETRY_GAPS_RESOLUTION.md`, et `validate_geometry.py` reporte **0/4 lacunes** (seule Strumica/MAJ-003 échoue encore).

**Réserve** : les **découpes internes** (splits entre pays) et les micro-ajustements de contiguïté diffèrent légèrement (~0,02–0,05 km²) dans les zones *tripoint* et *pasvik_north*, car le substitut basse résolution n'a pas la même précision que le Kavanagh d'origine. La correction est donc **fonctionnellement reproduite** (lacunes comblées, surfaces exactes) mais **pas bit-à-bit identique** à la production d'origine.

**Conclusion MAJ-004** : les corrections **peuvent être régénérées** à partir des artefacts versionnés **plus** une source pays 1914 (idéalement le Kavanagh d'origine, à défaut le substitut basse résolution). Le résultat est déterministe et conforme aux surfaces documentées ; seule la géométrie interne exacte des coutures dépend de la source utilisée.

---

## 7. CONFIGURATION D'UN REMOTE — PRÉPARATION SANS PUSH

**Aucun remote n'a été ajouté et aucun push n'a été effectué.** La configuration ci-dessous est prête à appliquer, mais nécessite une décision et une autorisation explicites.

### 7.1 Prérequis avant toute publication

1. **Créer un dépôt distant privé** (le projet contient des données cartographiques ; ne pas publier en accès libre).
2. **Vérifier l'absence de données privées/lourdes** avant push :
   - le `.gitignore` ignore déjà `/build/`, `/dist/`, `.godot/`, `*.tmp`, `*.bak` ;
   - **vérifier** qu'aucune donnée source sous licence ne serait poussée (les sources ne sont pas versionnées, donc par défaut non publiées) ;
   - décider du sort des **deux rapports non suivis** (`PROJECT_STATUS.md`, `CONTINUATION_PLAN.md`) : les committer avant push, ou les exclure.
3. **Choisir la/les branche(s)** à publier. Rappel : 14 branches, dont 3 vides.

### 7.2 Commandes de configuration (à exécuter sur autorisation)

```bash
cd /home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914

# 1) Déclarer le remote (remplacer par l'URL réelle)
git remote add origin git@github.com:<compte>/<depot-prive>.git
git remote -v

# 2) (Optionnel) Committer d'abord les deux rapports de la mission précédente
#    git add docs/map/audit/PROJECT_STATUS.md docs/map/audit/CONTINUATION_PLAN.md
#    git commit -m "docs(audit): publier l'état réel et le plan de continuation"

# 3) Publier les branches (NE PAS exécuter sans autorisation explicite)
# git push -u origin main
# git push origin agent_1 agent-2 audit/map-1914 \
#     fix/map-geometry-v2 fix/map-geometry-gaps fix/map-topology-v2 fix/map-thematic-data-v2 \
#     integrate/map-1914-final-audit
```

### 7.3 Recommandations

- **Ne pas pousser les branches vides** (`fix/map-geometry`, `fix/map-topology`, `fix/map-thematic-data`) : elles n'ont aucun contenu propre.
- **Utiliser SSH** (ou un jeton d'accès stocké hors dépôt) ; ne pas inscrire de secret dans l'URL du remote.
- Après configuration, **`git push --dry-run`** permet de vérifier sans publier.
- Conserver le **bundle** du § 5.1 comme sauvegarde indépendante du remote (un remote n'est pas une sauvegarde s'il est le seul exemplaire).

---

## 8. RISQUES IDENTIFIÉS

| Risque | Gravité | Mitigation |
|---|---|---|
| Dépôt sans remote ni sauvegarde | **Élevée** | Bundle Git (§ 5.1) + archive de l'arbre (§ 5.2) |
| Deux rapports non suivis | **Moyenne** | Les committer ou les sauvegarder (§ 5.2) |
| Sources externes non versionnées (373 Mo) | **Élevée** | rsync vers sauvegarde + manifeste de sources (§ 5.3) |
| Kavanagh `europe_1914.gpkg` perdu | **Moyenne** | Substitut basse résolution (§ 6) ou re-téléchargement |
| Worktrees `/tmp` disparus | **Faible** | Aucun commit perdu ; entrées administratives |
| Avertissement `shapely.ops.transform` | **Faible** | Non bloquant ; corriger plus tard |

---

## 9. CONCLUSION

- L'état Git est **sain mais fragile** : 14 branches locales cohérentes, aucun stash, aucun remote, **aucune sauvegarde**.
- Le non-commité se limite à **deux rapports documentaires** ; aucun fichier suivi n'est modifié.
- Les **données sources externes (373 Mo) et les prototypes de construction ne sont pas versionnés** : c'est le principal risque de perte.
- MAJ-004 est **reproductible** de façon déterministe à partir des artefacts versionnés + une source pays 1914 ; les surfaces documentées sont retrouvées **à l'identique**, les découpes internes au centième de km² près.
- La configuration d'un remote est **prête** mais **volontairement non appliquée** : aucun remote ajouté, aucun push effectué.
