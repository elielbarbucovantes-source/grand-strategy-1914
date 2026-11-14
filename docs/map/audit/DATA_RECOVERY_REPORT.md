# RAPPORT — RÉCUPÉRATION ET SÉCURISATION DES DONNÉES

- **Date** : 13 novembre 2026
- **Dépôt** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **Branche de travail** : `consolidate/map-1914-geometry` (créée depuis `fix/map-geometry-gaps` = `219373b`)
- **Nature** : sauvegarde et préparation d'environnement. Aucune branche fusionnée, `main` non modifié, aucune source supprimée, aucun remote configuré, aucun push.

---

## 1. OBJECTIF

Sécuriser les acquis avant toute consolidation :

1. inventorier les données non versionnées (dont ≈ 373 Mo de sources externes) ;
2. sauvegarder branches et commits (Git bundle) ;
3. sauvegarder séparément les fichiers non versionnés et les sources externes ;
4. vérifier l'intégrité des sauvegardes ;
5. créer un environnement GIS persistant dans le projet (`.venv`) ;
6. compléter `.gitignore`.

---

## 2. INVENTAIRE DES DONNÉES NON VERSIONNÉES

Le dépôt ne versionne, sous `data/world/map/sources/` et `data/world/map/build/*/sources/`, que des `README.md` (registre de sources). Les **données** elles-mêmes vivent hors du dépôt.

### 2.1 Sources GIS externes — ≈ 373 Mo

Répertoire : `/home/cassiop-e/.gemini/antigravity-cli/brain/3ab810c9-…/scratch/regis/` (51 fichiers).

| Catégorie | Exemples | Taille |
|---|---|---:|
| geoBoundaries | `gb_tur_adm2.geojson`, `gb_tur_adm1.geojson` | 5,4 Mo |
| Europe 1914 (substitut) | `gs1914-europe-1914-low-res.geojson` | 17,1 Mo |
| RISTAT 1897 | `ristat_1897_provinces.gpkg`, `ristat_1897_districts.gpkg`, `ristat_raw.bin` | 4,8 Mo |
| REGIS national | `REGIS_Austria_Hungary.gpkg`, `REGIS_Germany.gpkg`, `REGIS_Finland.gpkg`, … (38 fichiers) | ≈ 190 Mo |
| REGIS niveaux | `REGIS_Europe_L1.gpkg`, `REGIS_Europe_L2.gpkg`, `gs1914-regis-l0.gpkg` | 207 Mo |
| REThM | `REThM_Europe_L0/L1/L2.gpkg`, … (5 fichiers) | 39 Mo |
| Natural Earth | `ne_10m_places.geojson`, `ne_10m_rivers.geojson` | 12,2 Mo |

### 2.2 Autres fichiers non versionnés

| Catégorie | Chemin | Taille |
|---|---|---:|
| Notes de recherche | `/home/cassiop-e/research_notes/Ressources naturelles 1914/*.md` (4) | 280 Ko |
| Prototypes agent_1 | `…/brain/4ed2aa96-…/scratch/*.py` (6) | 232 Ko |
| Prototypes agent_2 | `…/brain/5fcd7210-…/scratch/*.py` (9) | 320 Ko |
| Audits ad hoc | `…/brain/2e364ab6-…/scratch/*.py` (3) | 43 Ko |
| Livrables documentaires non suivis | `docs/map/audit/{PROJECT_STATUS,CONTINUATION_PLAN,GIS_ENVIRONMENT_REPORT,GIT_RECOVERY_REPORT}.md` | 77 Ko |

> Le fichier Kavanagh d'origine `europe_1914.gpkg` est **absent de la machine** (recherche exhaustive `find / -iname "*kavan*"`, `*europe_1914*`, `*.gpkg` : aucun résultat). Il n'a donc pas pu être sauvegardé.

---

## 3. SAUVEGARDES CRÉÉES

Emplacement : **`/home/cassiop-e/backups/gs1914-2026-11-13/`** (manifeste détaillé : `MANIFEST.md`).

| Élément | Chemin | Taille |
|---|---|---:|
| Bundle Git — toutes branches + worktrees | `git/gs1914-all.bundle` | 3,43 Mo |
| Archive arbre de travail (suivi + non suivi, hors `.git`) | `worktree/gs1914-worktree.tar.gz` | 118 Ko |
| Sources GIS externes | `sources/external/regis/` | 373 Mo |
| Notes de recherche | `sources/research_notes/` | 280 Ko |
| Prototypes de construction | `sources/scratch_scripts/` | ≈ 550 Ko |

Commandes principales :

```bash
git bundle create /home/cassiop-e/backups/gs1914-2026-11-13/git/gs1914-all.bundle --all
tar czf …/worktree/gs1914-worktree.tar.gz --exclude='.git' grand-strategy-1914
rsync -a <sources externes>/  …/sources/external/regis/
```

---

## 4. VÉRIFICATION D'INTÉGRITÉ

| Contrôle | Résultat |
|---|---|
| `git bundle verify` | « Le colis est correct », **historique complet**, 22 références |
| `git clone` du bundle dans un répertoire neuf | 14 branches restaurées, commits conformes (`main` `4ffdb8a`, `fix/map-geometry-gaps` `219373b`, `fix/map-geometry-v2` `fc26c18`, …) |
| SHA-256 origine ↔ copie — sources externes | **51/51 identiques** |
| SHA-256 origine ↔ copie — notes + prototypes | **4/4 et 17/17 identiques** |
| `tar tzf` archive d'arbre | 116 entrées, les 4 rapports non suivis présents |

Empreintes des artefacts :

```
dfb351dd7bf9bfeff752eed717d2626238290fa0eb6a31e496a7a3361129233a  git/gs1914-all.bundle
9618ca4ca56063cb0cdff10d34aa491c8ef391c6382c031a02260c8d4d111a08  worktree/gs1914-worktree.tar.gz
```

**Aucun fichier temporaire n'a été supprimé** : la consigne « ne rien supprimer avant vérification » est respectée, et rien n'avait besoin d'être supprimé.

---

## 5. ENVIRONNEMENT GIS PERSISTANT

Un environnement **dans le projet** a été créé : `<dépôt>/.venv` (auparavant, l'environnement vivait dans `/tmp/opencode/gs1914-gis-venv`, non persistant).

```bash
uv venv .venv --python 3.12
uv pip install --python .venv/bin/python "shapely>=2.0,<3" "pyogrio>=0.11,<1" "pyproj>=3.6,<4"
```

Versions vérifiées à l'exécution :

| Paquet | Version | Bibliothèque native |
|---|---|---|
| Python | 3.12.3 | — |
| shapely | 2.2.0 | GEOS 3.14.1 |
| pyogrio | 0.13.0 | GDAL 3.12.4 |
| pyproj | 3.8.0 | PROJ 9.8.1 |
| numpy | 2.5.4 | — |
| certifi | 2026.10.23 | — |
| packaging | 26.3 | — |

Les versions exactes sont figées dans **`tools/map/requirements.lock`** (fichier versionné). Le socle requis reste `shapely` + `pyogrio` + `pyproj` ; **`geopandas` et `fiona` ne sont pas nécessaires** (aucun script ne les importe ; `pyogrio` est utilisé via `pyogrio.raw.read`).

### 5.1 Incident de cache `uv` (reproduit puis corrigé)

Comme lors du diagnostic précédent, la première installation a livré une roue `pyproj` corrompue :

```
ImportError: …/pyproj/_geod.cpython-312-x86_64-linux-gnu.so: invalid ELF header
```

Le fichier `_geod*.so` contenait des données « snappy framed », pas un ELF. Correction appliquée :

```bash
uv cache clean pyproj
uv pip install --python .venv/bin/python --reinstall --no-cache "pyproj>=3.6,<4"
```

Après correction, `file` confirme un ELF valide et `import pyproj` réussit. La purge du cache évite la réapparition du problème.

---

## 6. `.gitignore`

Règles ajoutées (en plus des règles existantes) :

```gitignore
# Python virtual environment and bytecode (GIS validators)
.venv/
__pycache__/
*.pyc

# Local consolidation staging (transient, never committed)
.consolidation-stage/

# Local backups
/backups/
```

L'environnement `.venv`, le répertoire de transit `.consolidation-stage/` (utilisé par la consolidation) et les sauvegardes locales ne sont donc pas versionnés.

---

## 7. LIMITES

- Sauvegarde **locale** (même disque) : protège des erreurs Git, pas d'une panne matérielle. Une copie sur support distinct reste recommandée.
- Le fichier Kavanagh d'origine est perdu ; la consolidation utilise un substitut documenté.
- `.venv` est propre à cette machine (chemins absolus) ; il est ignoré par Git et se recrée via `requirements.lock`.
