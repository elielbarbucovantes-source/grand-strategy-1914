# Outils cartographiques — environnement et validation

Ce dossier contient la chaîne de construction et de validation de l'atlas validé des 90 régions (géométrie consolidée, Strumica, topologie).

**Ne modifiez jamais les données de carte pour faire passer un contrôle.** Un échec signale une régression : il faut l'analyser, pas la masquer.

## 1. Dépendances

Elles sont épinglées dans `requirements.lock`, qui est la référence de reproductibilité. `requirements.txt` ne donne que les plages de versions.

| Paquet | Version validée |
|---|---|
| Python | 3.12 (validé avec 3.12.3) |
| shapely | 2.2.0 |
| pyproj | 3.8.0 |
| pyogrio | 0.13.0 (roues incluant GDAL, aucune bibliothèque système requise) |
| numpy | 2.5.4 |
| certifi, packaging | 2026.10.23, 26.3 |

## 2. Installation durable

L'environnement de référence se trouve dans `~/.venvs/gs1914-gis`, hors du dépôt et hors de `/tmp`.

Avec `uv`, recommandé, et indispensable si le module `python3-venv` / `ensurepip` n'est pas installé sur le système :

```bash
uv venv --python /usr/bin/python3 ~/.venvs/gs1914-gis
VIRTUAL_ENV=~/.venvs/gs1914-gis uv pip install -r tools/map/requirements.lock
```

Avec la bibliothèque standard, si `python3-venv` est disponible :

```bash
python3 -m venv ~/.venvs/gs1914-gis
~/.venvs/gs1914-gis/bin/pip install --no-deps -r tools/map/requirements.lock
```

Vérification :

```bash
VIRTUAL_ENV=~/.venvs/gs1914-gis uv pip freeze   # doit reproduire requirements.lock
```

Il est aussi possible d'utiliser un `.venv/` à la racine du dépôt (ignoré par Git). Les scripts le détectent.

## 3. Lancer les contrôles

Point d'entrée unique, depuis la racine du dépôt :

```bash
tools/map/validate_all.sh          # empreintes + 4 validateurs (≈ 1 min)
tools/map/validate_all.sh --full   # + reconstruction complète de la géométrie (≈ 3 min)
```

`--full` reconstruit la géométrie dans une copie temporaire des fichiers suivis. Le dépôt n'est jamais modifié. L'interpréteur peut être forcé avec `PYTHON=/chemin/python`.

Commandes individuelles :

| Commande | Ce qu'elle vérifie | Résultat de référence |
|---|---|---|
| `sha256sum -c tools/map/REFERENCE_SHA256SUMS` | Les 5 fichiers de référence (adjacence, géométrie, index, constructeur, validateur topologique) | 5 × « Réussi » / OK |
| `$PY tools/map/validate_geometry.py` | 90 géométries valides, 0 chevauchement, Saray (088), Strumica (072 et non 074), 4 lacunes résolues | code 0 |
| `$PY tools/map/validate_atlas.py` | Index éditorial de 90 lignes, géométries 90/90 | code 0 (avertissement connu : pas d'emprise de référence) |
| `$PY tools/map/validate_topology.py` | 184 arêtes terrestres, détroits, zones maritimes, empreintes des entrées | **93 contrôles, 0 échec** |
| `$PY tools/map/validate_topology.py --rebuild-check` | Rejeu de `rebuild_topology.py` dans un fichier temporaire et comparaison octet pour octet | **95 contrôles, 0 échec** |
| `PYTHON=$PY tools/map/consolidate_geometry.sh` | Reconstruit la géométrie **en place** depuis les lots et extraits versionnés | fichiers identiques octet pour octet |

`consolidate_geometry.sh` et `rebuild_topology.py` (sans `--output`) **réécrivent des fichiers suivis**. Ne les lancez directement que sur une branche dédiée, puis vérifiez avec `git diff --exit-code`. Pour un simple contrôle, préférez `validate_all.sh --full`.

## 4. Intégration continue

Le workflow `.github/workflows/map-validation.yml` exécute `validate_all.sh --full` sous Ubuntu 24.04 avec Python 3.12 et les dépendances de `requirements.lock`, puis `git diff --exit-code`.

Il se déclenche :
- sur tout push ou pull request qui touche `data/world/map/**`, `tools/map/**`, `docs/map/corrections/**` ou le workflow lui-même ;
- manuellement (*Actions → Validation cartographique → Run workflow*).

## 5. Modifier une donnée de référence

Une modification légitime (par exemple la curation du catalogue maritime) change des empreintes. Elle exige :

1. une branche dédiée et une justification écrite (décision, anomalie, source) ;
2. la reconstruction par les scripts, jamais une édition manuelle d'un fichier généré ;
3. la mise à jour de `REFERENCE_SHA256SUMS` et, le cas échéant, des empreintes internes de `validate_topology.py`, dans le **même** commit, avec l'ancienne et la nouvelle valeur dans le message ;
4. des validateurs verts, puis une revue.
