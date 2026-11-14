# RAPPORT — CONSOLIDATION GÉOMÉTRIQUE DE L'ATLAS 1914

- **Date** : 13 novembre 2026
- **Dépôt** : `/home/cassiop-e/Documents/Codex/2026-11-01/tu-es-responsable-du-d-veloppement/grand-strategy-1914`
- **Branche dédiée** : `consolidate/map-1914-geometry` (créée depuis `fix/map-geometry-gaps`, commit `219373b`)
- **Nature** : reproduction **dans le dépôt** (et non dans `/tmp`) des corrections BLK-001, BLK-002 et MAJ-004.
- **Contraintes respectées** : aucune fusion de branche, `main` non modifié, aucune source supprimée, données thématiques non modifiées, aucun remote, aucun push, Strumica non corrigée.

---

## 1. OBJECTIF ET RÉSULTAT

Produire un jeu de données géométrique **complet, reproductible et versionné** pour les 90 régions de 1914, en repartant des artefacts existants :

| Correction | Origine | Script | État |
|---|---|---|---|
| **BLK-001** — homonymie Saray (trou de Thrace + exclave de Van) | `fix/map-geometry-v2` | `build_geometry.py --saray-source …` | **Reproduite** |
| **BLK-002** — micro-chevauchements d'arrondi | `fix/map-geometry-v2` | `build_geometry.py` | **Reproduite** |
| **MAJ-004** — 4 lacunes de couture | `fix/map-geometry-gaps` | `close_geometry_gaps.py` | **Reproduite** |
| **MAJ-003** — Strumica | — | — | **Non corrigée** (hors périmètre, voir § 7) |

Les fichiers consolidés sont `data/world/map/regions.geojson` et `data/world/map/regions.json` sur la branche dédiée.

---

## 2. SOURCES UTILISÉES

Les sources externes brutes (≈ 373 Mo) ne sont pas versionnées. Pour rendre la reproduction autonome **sans committer les sources lourdes**, des **extraits minimaux** ont été produits, vérifiés géométriquement identiques à l'original, et versionnés sous `data/world/map/sources/derived/`.

| Fichier versionné | Contenu | Source d'origine | SHA-256 de l'origine |
|---|---|---|---|
| `gs1914_saray_tekirdag.geojson` | 1 feature (shapeID `54988432B91991689904144`) | `gb_tur_adm2.geojson` (geoBoundaries TUR ADM2) | `17af9a6b…358f3` |
| `gs1914_kavanagh_1914_countries.gpkg` | couche `europe_1914`, champ `name`, 4 pays (Autriche-Hongrie, Roumanie, Russie, Norvège) | `gs1914-europe-1914-low-res.geojson` (substitut pays 1914) | `99412859…61d75` |
| `gs1914_ristat_1897_finland_provinces.gpkg` | couche `provinces_1897`, champ `prov_ENG`, 2 gouvernements (Kuopio, Vyborg) | `ristat_1897_provinces.gpkg` (RISTAT 1897) | `807a7e53…09c600` |
| `SOURCE_EXTRACTS.json` | manifeste : chemins, SHA-256, noms, couches | — | — |

**Contrôle de fidélité** : chaque extrait est géométriquement **identique** à l'entité d'origine (`equals_exact=True`, différence symétrique `0.0`). Les noms de couche et de champ attendus par les scripts sont conservés, si bien que `build_geometry.py` et `close_geometry_gaps.py` s'exécutent **sans modification**.

> **Réserve majeure.** Le fichier **Kavanagh `europe_1914.gpkg` d'origine est introuvable** sur la machine et n'a jamais été versionné. Le substitut `gs1914-europe-1914-low-res.geojson` (29 pays, champ `name`) fournit les polygones nationaux nécessaires ; il reproduit **exactement** les surfaces de lacune documentées, mais sa précision de découpage interne diffère légèrement (voir § 6). Il est étiqueté `kavanagh_1914_v1` dans les `source_refs` des régions concernées, comme dans la livraison d'origine.

---

## 3. SCRIPTS

| Script | Statut | Rôle |
|---|---|---|
| `tools/map/build_geometry.py` | **inchangé** (repris de `fix/map-geometry-gaps`) | Assemble les lots `agent_1`/`agent_2`, corrige Saray (BLK-001), répare les micro-chevauchements (BLK-002), recalcule les métriques |
| `tools/map/close_geometry_gaps.py` | **inchangé** | Ferme les 4 lacunes MAJ-004 ; refuse d'écrire dans `data/world/map` |
| `tools/map/build_source_extracts.py` | **nouveau** | Produit les extraits minimaux versionnés depuis les sources brutes |
| `tools/map/consolidate_geometry.sh` | **nouveau** | Enchaîne la reproduction complète et la validation, sans `/tmp` |
| `tools/map/validate_geometry.py`, `validate_atlas.py` | inchangés | Validation |

---

## 4. CHAÎNE DE REPRODUCTION

```bash
# 1) extraire les sources minimales (une seule fois, à partir des sources brutes)
python tools/map/build_source_extracts.py \
    --gb-tur <gb_tur_adm2.geojson> --europe1914 <europe_1914> --ristat <ristat_1897_provinces.gpkg> \
    --output-dir data/world/map/sources/derived

# 2) reconstruire la géométrie consolidée (entièrement depuis les fichiers versionnés)
tools/map/consolidate_geometry.sh
```

`consolidate_geometry.sh` :

1. `build_geometry.py --saray-source data/world/map/sources/derived/gs1914_saray_tekirdag.geojson` → BLK-001 + BLK-002 ;
2. `close_geometry_gaps.py --kavanagh … --ristat … --output-dir .consolidation-stage` → MAJ-004 ;
3. installation de `regions.geojson`, `regions.json` dans `data/world/map/` et du rapport dans `docs/map/corrections/geometry_gaps_report.json` ;
4. validation.

Aucune étape n'écrit dans `/tmp`.

---

## 5. RÉSULTATS DES VALIDATEURS

Environnement : `<dépôt>/.venv` (shapely 2.2.0 / GEOS 3.14.1, pyogrio 0.13.0 / GDAL 3.12.4, pyproj 3.8.0 / PROJ 9.8.1).

### 5.1 `tools/map/validate_geometry.py`

```
Régions: 90/90; géométries valides: 90/90
Doublons: 0; paires avec chevauchement > 1e-10 deg²: 0
Somme des superficies: 10027649.63 km²
Saray: point dans 088=True, Van dans 088=False
Strumica: dans 072=False, dans 074=True
Lacunes sentinelles non résolues: 0/4 []
ERREUR: Strumica n'est pas attribuée exclusivement à region_072 (072=False, 074=True)
```

- 90/90 régions, 90/90 valides, **0 chevauchement > 1e-10 deg²**, **0/4 lacune** ;
- **Saray correcte** (Thrace dans `region_088`, exclave de Van retirée) ;
- seule erreur restante : **Strumica (MAJ-003)**, non corrigée volontairement ; le code de sortie est donc `1`, uniquement pour ce motif.

### 5.2 `tools/map/validate_atlas.py`

```
Index éditorial: OK (90 IDs, champs obligatoires présents).
Géométries valides: 90/90
AVERTISSEMENT: l'absence d'une emprise de référence empêche de conclure à la couverture complète…
```

Sortie `0`.

### 5.3 Contrôles internes de `close_geometry_gaps.py`

```json
"atlas": {"features": 90, "valid": 90, "overlap_pairs_gt_1e-10_deg2": 0,
          "max_overlap_deg2": 0.0, "total_area_km2": 10027649.63}
```

Surfaces des quatre lacunes reproduites (identiques aux valeurs documentées dans `GEOMETRY_GAPS_RESOLUTION.md`) :

| Lacune | Surface (km²) | Attribution |
|---|---:|---|
| Finlande / Olonets | 662,474739 | `region_052` (Vyborg/Kuopio, RISTAT) |
| Tripoint Khotin/Herța | 225,876731 | `region_040` + `region_062` + `region_071` |
| Pasvik nord | 117,048461 | `region_047` + `region_065` |
| Pasvik sud | 92,085230 | `region_047` + `region_065` |

### 5.4 Reproductibilité (déterminisme)

`consolidate_geometry.sh` a été exécuté **deux fois** ; les trois artefacts sont **identiques octet pour octet** :

```
74c32d76787ead2f8f10be17eeec6b6026a0a85a2d3c6c9710aa7cb041aa8078  data/world/map/regions.geojson
b9137ccfbb4f3641de3a3b08b7ba2889de44726d2ed58fb340c4d0d460960ff1  data/world/map/regions.json
7c23a533d85bde059cf12a1b463207e624b669fea5a543386a05c07b56957043  docs/map/corrections/geometry_gaps_report.json
```

---

## 6. DIFFÉRENCES AVEC LES ANCIENNES LIVRAISONS

### 6.1 Écart de surface total

| Livraison | Surface totale | Note |
|---|---:|---|
| `fix/map-geometry-v2` (`fc26c18`, avant MAJ-004) | 10 026 551,20 km² | archive |
| Consolidé (BLK-001 + BLK-002 + MAJ-004) | **10 027 649,63 km²** | cette branche |
| Reproduction `/tmp` (diagnostic précédent) | 10 027 648,69 km² | non versionnée |
| `GEOMETRY_GAPS_RESOLUTION.md` (cible documentée) | 10 027 648,69 km² | doc |

Le consolidé dépasse la cible documentée de **+0,94 km²**. Cet écart provient **entièrement de l'étape BLK-001** et est localisé sur la couture `region_088`/`region_089` :

| Région | v2 (km²) | Consolidé (km²) | Écart |
|---|---:|---:|---:|
| `region_088` | 7 933,51 | 7 934,35 | **+0,84** |
| `region_089` | 11 025,13 | 11 025,23 | **+0,10** |

Cause : l'archive `v2` a été produite avec un environnement **non figé** ; la reconstruction utilise **shapely 2.2.0 / GEOS 3.14.1**, dont l'union et la soustraction sur la couture de Saray donnent un tracé très légèrement différent. Les deux versions **corrigent Saray de la même façon** (Thrace dans 088, Van exclu, mêmes bornes `[26.6933, 40.7230, 28.7019, 41.6097]`) et passent tous les contrôles. La différence est de **1,03 km²** de différence symétrique sur `region_088`.

Les **surfaces de lacune MAJ-004 et les ajustements de contiguïté sont identiques** à la reproduction `/tmp` ; seul l'écart de base (+0,94 km²) se répercute sur le total.

### 6.2 Écarts de contenu

- `region_088`/`region_089` : couture Saray décalée de +0,84 / +0,10 km² (§ 6.1).
- Les 6 régions MAJ-004 gagnent les surfaces attendues (`region_052` +662,48 ; `region_047` +173,26 ; `region_062` +156,81 ; `region_040` +62,60 ; `region_065` +35,87 ; `region_071` +6,47 km²).
- Aucune autre région ne varie au-delà de 0,01 km².

### 6.3 Différence de traçabilité (amélioration)

Contrairement aux livraisons antérieures (dont les données corrigées MAJ-004 n'existaient que dans un répertoire `/tmp` supprimé), le jeu consolidé est désormais **versionné**, **reproductible depuis les fichiers versionnés**, et **indépendant de `/tmp`**.

---

## 7. STRUMICA (MAJ-003) — NON CORRIGÉE

Conformément à la consigne, Strumica n'a **pas** été corrigée : la poche (`~950 km²` autour de `[22,64, 41,44]`) reste dans `region_074` (Serbie) au lieu de `region_072` (Bulgarie), alors qu'elle était bulgare au traité de Bucarest (1913) et n'a été cédée qu'en 1919.

Raisons de l'abstention :

1. la correction suppose un **arbitrage historique et géométrique** (découpe de la poche) qui n'a pas été validé ;
2. l'instruction explicite est de ne pas la corriger « sans vérification historique et géométrique » ;
3. elle est **indépendante** de BLK-001/002 et MAJ-004.

`validate_geometry.py` signale donc encore Strumica et sort avec le code `1`. **Ce point est un blocage connu, pas une régression.**

---

## 8. FICHIERS CRÉÉS / MODIFIÉS SUR LA BRANCHE

**Données consolidées (modifiées)**
- `data/world/map/regions.geojson`, `data/world/map/regions.json`

**Sources minimales versionnées (nouvelles)**
- `data/world/map/sources/derived/gs1914_saray_tekirdag.geojson`
- `data/world/map/sources/derived/gs1914_kavanagh_1914_countries.gpkg`
- `data/world/map/sources/derived/gs1914_ristat_1897_finland_provinces.gpkg`
- `data/world/map/sources/derived/SOURCE_EXTRACTS.json`

**Outils (nouveaux)**
- `tools/map/build_source_extracts.py`, `tools/map/consolidate_geometry.sh`, `tools/map/requirements.lock`

**Rapports**
- `docs/map/corrections/geometry_gaps_report.json` (rapport machine de MAJ-004)
- `docs/map/audit/DATA_RECOVERY_REPORT.md`, `docs/map/audit/GEOMETRY_CONSOLIDATION_REPORT.md`

---

## 9. CRITÈRES DE VALIDATION

| Critère | État |
|---|---|
| 90 régions présentes | **OK** |
| 90 géométries valides | **OK** |
| Aucun chevauchement > 1e-10 deg² | **OK** |
| Les 4 lacunes MAJ-004 fermées | **OK** (0/4) |
| Saray correctement située | **OK** |
| Scripts reproductibles depuis les fichiers versionnés | **OK** (`consolidate_geometry.sh`, déterminisme vérifié) |
| Résultats indépendants de `/tmp` | **OK** |
| Sauvegardes vérifiées | **OK** (voir `DATA_RECOVERY_REPORT.md`) |

**Bloquage restant** : Strumica (MAJ-003), hors périmètre, en attente d'arbitrage.
