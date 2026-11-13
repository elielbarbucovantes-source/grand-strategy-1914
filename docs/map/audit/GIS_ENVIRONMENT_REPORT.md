# RAPPORT — ENVIRONNEMENT GIS DE VALIDATION

- **Date** : 13 novembre 2026
- **Dépôt** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **HEAD au moment du rapport** : branche `fix/map-thematic-data`, commit `b5a07ae`
- **Nature** : préparation d'environnement en lecture seule sur les données. Aucune géométrie, branche ou commit n'a été modifié.
- **Objet** : installer les dépendances GIS absentes, vérifier les versions, exécuter les validateurs et documenter les problèmes de compatibilité.

---

## 1. OBJECTIF

Le diagnostic global a montré qu'aucun validateur GIS ne pouvait être exécuté : ni `shapely`, ni `pyogrio`, ni `pyproj`, ni `geopandas`, ni `fiona` n'étaient présents. Ce rapport :

1. inventorie les dépendances réellement requises par le code versionné ;
2. documente l'environnement Python isolé créé ;
3. relève les versions effectivement installées ;
4. restitue l'exécution des quatre validateurs sur les données disponibles ;
5. signale les problèmes de compatibilité rencontrés.

---

## 2. DÉPENDANCES REQUISES

### 2.1 Déclaration officielle — `tools/map/requirements.txt`

| Branche | Contenu de `requirements.txt` |
|---|---|
| `main`, `audit/map-1914`, `fix/map-topology-v2`, `fix/map-thematic-data-v2` | `pyogrio>=0.11,<1`<br>`shapely>=2.0,<3` |
| `fix/map-geometry-v2`, `fix/map-geometry-gaps` | `pyogrio>=0.11,<1`<br>`shapely>=2.0,<3`<br>`pyproj>=3.6,<4` |

### 2.2 Dépendances réellement importées par les scripts

Inventaire établi en lisant les `import` de chaque script versionné (`tools/map/*.py`, `docs/map/audit/*.py`) sur toutes les branches :

| Script | Branche(s) | Import tiers |
|---|---|---|
| `tools/map/validate_atlas.py` | toutes | `shapely` |
| `tools/map/validate_geometry.py` | `fix/map-geometry-v2`, `fix/map-geometry-gaps` | `shapely`, `pyproj` |
| `tools/map/build_geometry.py` | `fix/map-geometry-v2`, `fix/map-geometry-gaps` | `shapely`, `pyproj` |
| `tools/map/build_adjacency.py` | `fix/map-topology-v2` | `shapely`, `pyproj` |
| `tools/map/validate_topology.py` | `fix/map-topology-v2` | `shapely`, `pyproj` |
| `tools/map/unify_thematic_data.py` | `fix/map-thematic-data-v2` | `shapely`, `pyproj` (`Geod`) |
| `tools/map/close_geometry_gaps.py` | `fix/map-geometry-gaps` | `shapely`, `pyproj`, `pyogrio` |
| `docs/map/audit/validate_global_atlas.py` | `audit/map-1914` et suivantes | `shapely`, `pyproj` |

**Conclusion sur les dépendances** :

- Le socle strict est **`shapely` + `pyogrio` + `pyproj`**.
- **`geopandas` n'est requis par aucun script.** `pyogrio` est utilisé via son API bas niveau `pyogrio.raw.read(...)`, pas via `read_dataframe()`. (`pyogrio.read_dataframe()` exigerait `geopandas`, mais ce point d'entrée n'est jamais appelé — vérifié par recherche `grep -rn "geopandas\|read_dataframe"` : aucun résultat dans le code versionné.)
- **`fiona` n'est pas requis.**
- `numpy` est une dépendance transitive de `shapely`/`pyproj`/`pyogrio` ; `certifi` et `packaging` sont des dépendances transitives de `pyproj`/`pyogrio`.

### 2.3 Note d'écart

`docs/map/audit/PROJECT_STATUS.md` mentionnait `geopandas` et `fiona` parmi les bibliothèques manquantes. Après inspection du code réel, **ces deux paquets ne sont pas nécessaires** ; l'installation se limite donc à `shapely`, `pyogrio` et `pyproj`.

---

## 3. CONTRAINTES DE L'ENVIRONNEMENT SYSTÈME

| Élément | Constat |
|---|---|
| Interpréteur système | `/usr/bin/python3` → Python **3.12.3** |
| `pip` système | **absent** (`No module named pip`) |
| `ensurepip` | **absent** (`No module named ensurepip`) |
| `python3-venv` | **non installé** (`apt` candidat `3.12.3-0ubuntu2.1`, non installable sans droits) |
| `sudo` | **mot de passe requis** (`sudo -n` échoue) — pas d'installation système possible |
| Outil disponible | **`uv` 0.12.19** (`/home/cassiop-e/.local/bin/uv`) et `uvx` |

`python3 -m venv` échoue donc sans `--without-pip`, et un venv `--without-pip` n'aurait aucun moyen d'installer des paquets. **La solution retenue est `uv`**, qui crée le venv et y installe les paquets sans toucher à l'environnement système.

---

## 4. ENVIRONNEMENT ISOLÉ CRÉÉ

```bash
uv venv /tmp/opencode/gs1914-gis-venv --python 3.12
uv pip install --python /tmp/opencode/gs1914-gis-venv/bin/python \
    "shapely>=2.0,<3" "pyogrio>=0.11,<1" "pyproj>=3.6,<4"
```

- **Emplacement** : `/tmp/opencode/gs1914-gis-venv`
- **Interpréteur** : CPython 3.12.3
- **Isolation** : environnement entièrement séparé ; **aucun paquet installé dans le Python système**, aucune modification de `apt`.

### 4.1 Versions installées (vérifiées à l'exécution)

| Paquet | Version | Bibliothèque native |
|---|---|---|
| Python | 3.12.3 | — |
| shapely | **2.2.0** | GEOS **3.14.1** |
| pyogrio | **0.13.0** | GDAL **(3, 12, 4)** |
| pyproj | **3.8.0** | PROJ **9.8.1** |
| numpy | 2.5.4 | — |
| certifi | 2026.10.23 | — |
| packaging | 26.3 | — |

Sortie de `uv pip freeze` :

```
certifi==2026.10.23
numpy==2.5.4
packaging==26.3
pyogrio==0.13.0
pyproj==3.8.0
shapely==2.2.0
```

Toutes les bornes de `requirements.txt` sont respectées (`shapely<3`, `pyogrio<1`, `pyproj<4`).

---

## 5. PROBLÈMES DE COMPATIBILITÉ RENCONTRÉS

### 5.1 Roue `pyproj` corrompue au premier essai (cache `uv`)

- **Symptôme** : à l'import, `ImportError: .../pyproj/_geod.cpython-312-x86_64-linux-gnu.so: invalid ELF header`.
- **Diagnostic** : le fichier `_geod*.so` n'était pas un ELF mais des **données « snappy framed »** (en-tête binaire de compression) — roue corrompue servie depuis le cache `uv`.
- **Correction** : réinstallation forcée sans cache :
  ```bash
  uv pip install --python /tmp/opencode/gs1914-gis-venv/bin/python \
      --reinstall --no-cache "pyproj>=3.6,<4"
  ```
- **Vérification** : `file _geod*.so` → `ELF 64-bit LSB shared object` ; `import pyproj` OK, PROJ 9.8.1.
- **Portée** : problème d'infrastructure de cache, **pas** une incompatibilité de version. À retenir : en cas d'`invalid ELF header` sur un `.so`, refaire l'installation avec `--no-cache`.

### 5.2 Avertissement de dépréciation `shapely.ops.transform`

- `tools/map/validate_geometry.py` (ligne 53) utilise `shapely.ops.transform()`, déprécié dans shapely 2.2.0 au profit de `shapely.transform()` / `shapely.transform_coordseq()`.
- **Non bloquant** : le script s'exécute et produit le résultat attendu. Aucune modification du script n'a été faite (contrainte de non-modification). À corriger lors d'une passe dédiée si l'on veut supprimer l'avertissement.

### 5.3 `pyogrio.read_dataframe()` exige `geopandas`

- `pyogrio.read_dataframe()` lève `ImportError: geopandas is required`. **Ce point d'entrée n'est pas utilisé** par les scripts versionnés (qui emploient `pyogrio.raw.read`). Donc `geopandas` reste inutile.
- Rappel d'API utile pour `close_geometry_gaps.py` : `pyogrio.raw.read(path, layer=..., columns=[...], read_geometry=True)` renvoie `(meta, fids, geometries, fields)`, avec `fields[0]` = tableau des noms.

### 5.4 Nommage de couche du substitut Europe 1914 (contexte MAJ-004)

- Le fichier non versionné `gs1914-europe-1914-low-res.geojson` ne porte **aucun nom de couche** exploitable : `pyogrio.raw.read(..., layer="europe_1914")` échoue (`DataLayerError`). Il faut lire avec `layer=None`.
- Le vrai `europe_1914.gpkg` de Kavanagh (attendu par `close_geometry_gaps.py` avec `layer="europe_1914"`, champ `name`) **est absent de la machine** ; voir le rapport de récupération pour les conséquences.

---

## 6. EXÉCUTION DES VALIDATEURS

Les validateurs ont été exécutés sur des copies extraites par `git archive` dans `/tmp/opencode/gs1914-test/` (aucune écriture dans le dépôt), sauf `validate_global_atlas.py`, lancé depuis la racine du dépôt car il lit les lots via `git show`.

| # | Validateur | Branche | Résultat | Code |
|---|---|---|---|---|
| 1 | `tools/map/validate_geometry.py` | `fix/map-geometry-v2` | 90/90 valides ; 0 chevauchement > 1e-10 deg² ; total **10 026 551,20 km²** ; Saray dans 088 = True ; **Strumica non corrigée** (dans 074, pas 072) ; **2/4 lacunes** non résolues (`MAJ-004 Finlande/Olonets`, `MAJ-004 tripoint Khotin/Herța`) | **1** |
| 2 | `tools/map/validate_atlas.py` | `fix/map-geometry-v2` | Index 90 lignes ; 90/90 géométries valides ; avertissement d'absence d'emprise de référence | **0** |
| 3 | `tools/map/validate_topology.py` | `fix/map-topology-v2` | **55 contrôles, 0 échec** — 184 arêtes, 17 interfaces inter-lots, arête 026↔056, arête 033↔037, détroits, régions isolées 051/085/086 | **0** |
| 4 | `docs/map/audit/validate_global_atlas.py` | `audit/map-1914` (lecture `agent_1`/`agent-2`) | **3 erreurs bloquantes** (BLK-001, BLK-002, BLK-003) + **2 importantes** (MAJ-007, MAJ-003) sur les lots **pré-intégration** | **0** par défaut, **1** avec `--strict` |

### 6.1 Détail — `validate_geometry.py` (`fix/map-geometry-v2`)

```
Régions: 90/90; géométries valides: 90/90
Doublons: 0; paires avec chevauchement > 1e-10 deg²: 0
Somme des superficies: 10026551.20 km²
Saray: point dans 088=True, Van dans 088=False
Strumica: dans 072=False, dans 074=True
Lacunes sentinelles non résolues: 2/4 ['MAJ-004 Finlande/Olonets', 'MAJ-004 tripoint Khotin/Herța']
ERREUR: Strumica n'est pas attribuée exclusivement à region_072 (072=False, 074=True)
```

### 6.2 Détail — `validate_topology.py` (`fix/map-topology-v2`)

```
RÉSULTAT : VALIDÉ — 55 contrôles, 0 échec
```

### 6.3 Détail — `validate_global_atlas.py` (lots pré-intégration)

```
BILAN : 3 erreur(s) bloquante(s), 2 erreur(s) importante(s) signalée(s).
  [BLOQUANT] BLK-001: region_088 exclave parasite (938,36 km²) + trou Thrace (684,40 km²), collision 'Saray' (gb_tur_adm2.geojson)
  [BLOQUANT] BLK-002: 15 paires internes agent_1 avec micro-intersection d'arrondi (1e-10 à 1,13e-8 deg²)
  [BLOQUANT] BLK-003: interface 026↔056 (368,87 km) présente dans agent-2, omise dans agent_1
  [IMPORTANT] MAJ-007: 3 détroits en auto-boucle dans agent-2
  [IMPORTANT] MAJ-003: saillant de Strumica attribué à region_074 au lieu de region_072
```

Ces cinq points concernent l'état **avant intégration** (lots `agent_1`/`agent-2`). Les blocages BLK-001/BLK-002 sont traités sur `fix/map-geometry-v2`, BLK-003 sur `fix/map-topology-v2`.

### 6.4 Rejeu du correctif MAJ-004 (branche `fix/map-geometry-gaps`)

`close_geometry_gaps.py` a été rejoué avec un **substitut** du fichier Kavanagh manquant (voir rapport de récupération). Résultat reproductible dans `/tmp/opencode/gs1914-maj004-test` :

```
Lacunes sentinelles non résolues: 0/4 []
Somme des superficies: 10027648.69 km²
Géométries valides: 90/90; chevauchements > 1e-10 deg²: 0
Strumica: dans 072=False, dans 074=True   → EXIT=1
```

La superficie totale (`10 027 648,69 km²`) et les quatre surfaces de lacune (`662,474739` / `225,876731` / `117,048461` / `92,085230 km²`) correspondent **exactement** aux valeurs documentées dans `docs/map/corrections/GEOMETRY_GAPS_RESOLUTION.md`. Seule Strumica (`MAJ-003`) échoue encore, anomalie préexistante et indépendante de MAJ-004.

---

## 7. COMMANDES DE REPRODUCTION

```bash
export PATH="$HOME/.local/bin:$PATH"
PY=/tmp/opencode/gs1914-gis-venv/bin/python

# 1) Créer l'environnement isolé
uv venv /tmp/opencode/gs1914-gis-venv --python 3.12
uv pip install --python "$PY" "shapely>=2.0,<3" "pyogrio>=0.11,<1" "pyproj>=3.6,<4"

# 2) Extraire les branches à tester (sans muter le dépôt)
rm -rf /tmp/opencode/gs1914-test && mkdir -p /tmp/opencode/gs1914-test
for b in fix/map-geometry-v2 fix/map-geometry-gaps fix/map-topology-v2; do
  d=/tmp/opencode/gs1914-test/$(echo "$b" | tr '/' '_'); mkdir -p "$d"
  git archive "$b" | tar -x -C "$d"
done

# 3) Exécuter les validateurs
(cd /tmp/opencode/gs1914-test/fix_map-geometry-v2 && "$PY" tools/map/validate_geometry.py)
(cd /tmp/opencode/gs1914-test/fix_map-geometry-v2 && "$PY" tools/map/validate_atlas.py)
(cd /tmp/opencode/gs1914-test/fix_map-topology-v2 && "$PY" tools/map/validate_topology.py)
"$PY" docs/map/audit/validate_global_atlas.py            # depuis la racine du dépôt
"$PY" docs/map/audit/validate_global_atlas.py --strict   # EXIT=1 attendu sur les lots pré-intégration
```

---

## 8. CONCLUSION

- L'environnement GIS isolé est **opérationnel** ; les trois dépendances requises sont installées avec des versions respectant `requirements.txt`.
- Les **quatre validateurs s'exécutent** et **reproduisent les résultats documentés**, ce qui permet désormais de valider tout nouveau travail cartographique.
- `geopandas`/`fiona` sont **inutiles** : aucune dépendance au code versionné.
- Le seul défaut d'environnement notable (roue `pyproj` corrompue) est **corrigé** et documenté ; l'avertissement `shapely.ops.transform` est **non bloquant**.
- L'environnement vit dans `/tmp` : il **ne survivra pas à un redémarrage**. Voir `GIT_RECOVERY_REPORT.md` pour la stratégie de persistance des artefacts.
