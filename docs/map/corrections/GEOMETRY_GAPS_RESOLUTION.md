# Résolution des quatre lacunes géométriques MAJ-004 — Atlas 1914

## Résumé exécutif

Les quatre lacunes de couture MAJ-004 de l'atlas Grand Strategy-1914 ont été reproduites, qualifiées et comblées dans une copie de travail, sans toucher aux fichiers canoniques ni aux lots sources. La correction ajoute **1 097,485161 km²** répartis entre six régions, supprime les quatre vides et ne crée aucun chevauchement au seuil strict de `1e-10 deg²`.

| Lacune | Sentinelle | Surface initiale | Régions concernées |
|---|---:|---:|---|
| Finlande / Olonets (Suojärvi) | `[32.3258, 62.6315]` | 662,474739 km² | `region_052`, `region_064` |
| Tripoint Khotin / Herța | `[26.1997, 48.3030]` | 225,876731 km² | `region_040`, `region_062`, `region_071` |
| Pasvik nord | `[30.5256, 69.5879]` | 117,048461 km² | `region_047`, `region_065` |
| Pasvik sud | `[29.7994, 69.4143]` | 92,085230 km² | `region_047`, `region_065` |
| **Total** | | **1 097,485161 km²** | |

Après correction, dans la copie de test :

- `tools/map/validate_geometry.py` : **0/4 lacune sentinelle non résolue**, **0 paire avec chevauchement > `1e-10 deg²`**, **90/90 géométries valides**, superficie totale **10 027 648,69 km²** ;
- le même validateur échoue encore uniquement sur **Strumica**, anomalie préexistante et indépendante de MAJ-004 ;
- `tools/map/validate_atlas.py` : **succès**, 90 lignes, 90/90 géométries valides.

La superficie totale augmente de **1 097,49 km²**, aux arrondis près la somme des quatre lacunes. Aucune branche n'a été fusionnée. Les fichiers `data/world/map/regions.geojson`, `data/world/map/regions.json` et les deux lots `data/world/map/build/agent_1`, `data/world/map/build/agent_2` sont restés inchangés.

> **Limite documentaire.** Le fichier `docs/map/audit/INDEPENDENT_GEOMETRY_AUDIT.md`, cité dans certaines consignes, **n'existe pas** dans le dépôt au commit de base `fc26c18`. Le diagnostic s'appuie donc sur `docs/map/audit/GLOBAL_AUDIT.md`, `docs/map/audit/ISSUES.json` (définition MAJ-004) et `docs/map/corrections/AGENT_1_GEOMETRY_REPORT.md`. Cette absence est signalée ici pour éviter de faire croire à une source qui n'a pas été consultée.

## Contexte de travail

- Worktree : `/tmp/opencode/gs1914-geometry-gaps`
- Branche : `fix/map-geometry-gaps`, créée depuis `fix/map-geometry-v2` au commit `fc26c18` (« data(map): assemble corrected 1914 region geometries »)
- Aucune fusion, aucun commit sur les branches d'audit ou de construction.
- Script de correction : `tools/map/close_geometry_gaps.py` (outil non canonique, refus explicite d'écrire dans `data/world/map`).
- Sortie de test : `/tmp/opencode/gs1914-corrected/regions.geojson`, `regions.json`, `geometry_gaps_report.json`.
- Validateurs exécutés dans `/tmp/opencode/gs1914-test`, copie du dépôt recevant les fichiers corrigés.

## 1. Méthode

### 1.1 Détection aréale

Pour chaque lacune, l'union des 90 géométries est calculée dans une fenêtre locale, puis soustraite d'une boîte englobante. La composante qui contient la sentinelle d'audit est retenue. Sa surface est reprojetée en EPSG:3035 et comparée à la valeur MAJ-004 avec une tolérance de `0,01 km²`. Les quatre valeurs reproduites correspondent aux valeurs d'audit (aux arrondis près) :

- Finlande : `662,474739 km²` ;
- tripoint : `225,876731 km²` ;
- Pasvik nord : `117,048461 km²` ;
- Pasvik sud : `92,085230 km²`.

La détection est aréale, pas seulement ponctuelle : le rapport de correction vérifie ensuite que la géométrie initiale de chaque lacune est entièrement couverte après correction (`residual_area_km2 = 0` pour les quatre).

### 1.2 Arbitrage historique

Aucune lacune n'est comblée par un tampon générique. Chaque pièce est attribuée avec une source cartographique et une règle explicite :

1. **Finlande / Olonets** : la couche RISTAT 1897 des provinces de l'Empire russe est utilisée pour situer la limite Vyborg/Kuopio face au gouvernement d'Olonets. L'ensemble de la lacune est attribué à `region_052` (Finlande), car elle se trouve du côté finlandais de cette limite. Kavanagh ne peut pas arbitrer cette frontière interne : son polygone « Russia » englobe le Grand-Duché de Finlande.
2. **Tripoint Khotin / Herța** : les polygones nationaux Kavanagh 1914 (Autriche-Hongrie, Roumanie, Russie) sont intersectés avec la lacune, puis répartis exactement entre `region_040`, `region_071` et `region_062`. Un contrôle de contiguïté corrige ensuite les micro-pièces qui ne touchent pas la région à laquelle la source les rattache.
3. **Pasvik nord et sud** : même méthode avec les polygones Kavanagh « Norway » et « Russia ». La ligne suit la frontière norvégo-russe de 1826, inchangée en 1914 ; la lacune est un vide de numérisation de part et d'autre de cette ligne, pas un différend frontalier.

L'ordre de partition est déterministe (`Autriche-Hongrie`, `Roumanie`, `Russie` pour le tripoint ; `Norvège`, `Russie` pour le Pasvik). Le résidu linéaire nul est attribué au dernier pays de l'ordre, ce qui rend la partition exacte sans créer de surface.

### 1.3 Contiguïté

Après partition, chaque pièce est découpée en composantes polygonales. Une composante est conservée si elle partage une frontière avec la géométrie d'origine de sa région, ou si elle touche cette même géométrie en un point (un multi-polygone OGC peut se toucher en un point). Sinon :

- elle est réaffectée à la région avec laquelle elle partage la plus longue frontière ;
- à défaut, à la région la plus proche dans la limite de `0,001°` (environ 110 m) ;
- au-delà, elle est conservée et signalée comme détachée.

Trois micro-pièces du tripoint ont été réaffectées (tableau ci-dessous). Aucune pièce du Pasvik ni de Finlande ne l'a été. Les pièces simplement tangentes en un point sont conservées avec leur région d'origine ; c'est pourquoi `region_062` et `region_065` gagnent une seconde composante polygonale de très petite taille.

### 1.4 Précision des nouvelles coutures

Les nouvelles limites conservent la précision native des sources Kavanagh/RISTAT. Elles ne sont pas réarrondies indépendamment à six décimales : un tel arrondi de part et d'autre d'une couture rouvre des vides de 21 à 78 m². Le reste de l'atlas reste sur la grille canonique à `1e-6°`. Le script ne répare que les micro-chevauchements `<= 1e-6 deg²` impliquant une région modifiée, en soustrayant de préférence du côté modifié ; cette passe n'a produit aucune réparation (`rounding_repairs: []`).

### 1.5 Garde-fous

Le script :

- lit les fichiers canoniques mais n'écrit que dans un répertoire de sortie fourni ;
- refuse toute sortie dans `data/world/map` ou un de ses sous-répertoires ;
- vérifie l'inventaire `region_001..region_090` ;
- vérifie la validité OGC, l'absence de chevauchement `> 1e-10 deg²` et la couverture résiduelle des quatre lacunes ;
- ne modifie ni les seuils des validateurs ni les fichiers des lots.

## 2. Diagnostic des quatre lacunes

### 2.1 Finlande / Olonets — 662,474739 km²

- **Emprise** : `(31,599994, 62,274354, 32,813663, 62,950827)`.
- **Centroïde d'audit** : `[32,3258, 62,6315]`.
- **Régions** : `region_052` (Finlande, source REGIS) et `region_064` (Russie du Nord-Ouest, source RISTAT 1897).
- **Origine** : couture entre deux sources hétérogènes et deux niveaux de subdivision. La couche REGIS de Finlande et la limite Vyborg/Olonets de RISTAT 1897 ne coïncident pas dans ce secteur : la première s'arrête en deçà de la seconde, et le vide épouse ce décalage. Ce n'est ni un artefact de projection ni une frontière historique incorrecte, mais un espace non numérisé entre deux généralisations.
- **Référence historique au 1er janvier 1914** : Grand-Duché de Finlande (gouvernement de Vyborg et partie de Kuopio) face au gouvernement d'Olonets de l'Empire russe. RISTAT 1897 donne Kuopio `268,482040 km²` et Vyborg `393,980580 km²` dans la lacune ; l'union de ces deux intersections couvre `662,470116 km²`, soit **99,9993 %** de la lacune. Le reliquat de `0,004623 km²` (0,0007 %) est une lisière de généralisation : `0,001296 km²` sont recouverts par le polygone généralisé d'Olonets et `0,003327 km²` ne sont couverts par aucun polygone RISTAT.
- **Décision** : attribuer la totalité de la lacune à `region_052`. La limite occidentale de `region_064` n'est pas déplacée ; une note documentaire est ajoutée à `region_064` pour expliquer que le vide adjacent a été attribué à la Finlande.
- **Incertitude** : la ligne exacte est connue à environ `±0,005 km²` près, soit moins de 0,001 % de la surface. Cette incertitude est très inférieure au seuil de validation (`0,01 km²`) et à la précision cartographique de l'atlas.
- **Confiance** : élevée pour l'attribution nationale ; moyenne-élevée pour le tracé exact à l'échelle de la parcelle.

### 2.2 Tripoint Khotin / Herța — 225,876731 km²

- **Emprise** : `(26,026420, 48,144010, 26,473991, 48,572255)`.
- **Centroïde d'audit** : `[26,1997, 48,3030]`.
- **Régions** : `region_040` (Galicie-Bucovine, lot agent_1), `region_062` (Bessarabie, lot agent_2) et `region_071` (Roumanie septentrionale, lot agent_2).
- **Origine** : couture inter-lots à un tripoint. Les polygones de Bucovine (REGIS Autriche-Hongrie), de Bessarabie (RISTAT 1897) et de Moldavie (REGIS Roumanie) sont généralisés indépendamment ; leur rencontre laisse un vide triangulaire. Ce n'est pas une frontière historique erronée : les trois souverainetés de 1914 sont correctes, mais l'espace entre leurs tracés n'est attribué à personne.
- **Référence historique au 1er janvier 1914** : Autriche-Hongrie (Bucovine, autour de Czernowitz/Tchernivtsi) ; Empire russe (Bessarabie, district de Khotin) ; Royaume de Roumanie (Moldavie, district de Dorohoi/Herța). Kavanagh 1914 donne la répartition brute suivante dans la lacune :

| Pays Kavanagh | Surface brute |
|---|---:|
| Autriche-Hongrie | 61,676534 km² |
| Roumanie | 6,372535 km² |
| Russie | 157,827646 km² |

- **Décision** : partition exacte selon ces trois polygones, puis réaffectation de contiguïté des trois composantes détachées.

| Pièce réaffectée | De | Vers | Surface | Motif | Bornes |
|---|---|---|---:|---|---|
| Pièce détachée de Bucovine | `region_040` | `region_062` | 0,079419 km² | région la plus proche (`region_062`) à `3,5e-16°`, contact ponctuel | `(26,073917, 48,481777, 26,077380, 48,490117)` |
| Pièce détachée de Russie | `region_062` | `region_040` | 1,048056 km² | frontière commune avec `region_040` (`0,0482642°`) | `(26,026420, 48,406594, 26,070344, 48,428685)` |
| Pièce détachée de Russie | `region_062` | `region_071` | 0,050559 km² | frontière commune avec `region_071` (`0,0127938°`) | `(26,374819, 48,187019, 26,385947, 48,193135)` |

- **Répartition finale** :

| Région | Avant (Kavanagh) | Après contiguïté | Écart |
|---|---:|---:|---:|
| `region_040` (Bucovine) | 61,676534 km² | 62,645172 km² | +0,968638 km² |
| `region_062` (Bessarabie) | 157,827646 km² | 156,808106 km² | −1,019540 km² |
| `region_071` (Moldavie) | 6,372535 km² | 6,423094 km² | +0,050559 km² |
| **Total** | **225,876715 km²** | **225,876372 km²** | **−0,000343 km²** |

L'écart de `0,000359 km²` entre la somme des pièces et la surface de la lacune est un effet d'additivité de la projection EPSG:3035, pas un vide ni un chevauchement : les tests géométriques donnent un résidu nul. L'écart net par rapport à la répartition Kavanagh (`−0,000343 km²`) a la même origine. Les réaffectations représentent **1,18 km², soit 0,52 %** de la lacune ; elles corrigent des pièces détachées de la région à laquelle Kavanagh les rattachait, pas la logique nationale de la partition.

- **Confiance** : élevée pour la répartition nationale ; moyenne pour le tracé exact, Kavanagh étant une carte généralisée à l'échelle nationale.

### 2.3 Pasvik nord et sud — 117,048461 km² et 92,085230 km²

- **Pasvik nord** : emprise `(30,120838, 69,526602, 30,948560, 69,690750)`, sentinelle `[30,5256, 69,5879]`.
- **Pasvik sud** : emprise `(29,340019, 69,321363, 30,216158, 69,583963)`, sentinelle `[29,7994, 69,4143]`.
- **Régions** : `region_047` (Norvège — Nord, source geoBoundaries NOR) et `region_065` (Russie septentrionale, source RISTAT 1897).
- **Origine** : couture inter-lots le long d'une frontière fluviale très sinueuse, dans la vallée de la Pasvik. La paire `region_047`/`region_065` est absente de la liste `seam_pairs` du build agent_2, ce qui explique que le vide n'ait pas été traité lors de l'assemblage. Les deux polygones suivent la même frontière historique mais avec des généralisations différentes ; le vide est un espace non numérisé, pas un déplacement de frontière.
- **Référence historique au 1er janvier 1914** : frontière norvégo-russe issue du traité de Saint-Pétersbourg de 1826, inchangée en 1914. La Norvège est indépendante depuis 1905 ; la Russie impériale contrôle la rive orientale et Petsamo (acquis par la Finlande seulement en 1920). Kavanagh 1914 reprend cette ligne.
- **Répartition Kavanagh brute** :

| Lacune | Norvège | Russie |
|---|---:|---:|
| Pasvik nord | 81,727082 km² | 35,322072 km² |
| Pasvik sud | 91,483370 km² | 0,603785 km² |

- **Décision** : affecter les pièces Kavanagh à `region_047` et `region_065`, sans réaffectation de contiguïté. La seule pièce non contiguë est un micro-sliver russe de `4,17e-6 deg²` (environ 0,018 km²) qui touche `region_065` en un point ; il est conservé avec la Russie et signalé. Il explique le passage de `region_065` de 1 à 2 composantes polygonales.
- **Répartition finale** :

| Lacune | `region_047` (Norvège) | `region_065` (Russie) |
|---|---:|---:|
| Pasvik nord | 81,727082 km² | 35,322061 km² |
| Pasvik sud | 91,483370 km² | 0,603502 km² |
| **Total** | **173,210452 km²** | **35,925563 km²** |

Les écarts de sommation (`+0,000682 km²` au nord, `+0,001642 km²` au sud) sont également des effets d'additivité de projection ; les résidus géométriques sont nuls.

- **Confiance** : élevée pour la frontière nationale de 1826 ; moyenne pour le tracé exact du lit de la Pasvik, du fait de la généralisation des deux sources.

### 2.4 Synthèse des causes

| Lacune | Cause retenue | Frontière historique incorrecte ? | Artefact de projection ? |
|---|---|---|---|
| Finlande / Olonets | couture REGIS/RISTAT, généralisations et niveaux de subdivision différents | non | non |
| Tripoint Khotin / Herța | couture inter-lots à un tripoint, trois polygones généralisés | non | non |
| Pasvik nord | couture inter-lots, paire de couture absente du build | non | non |
| Pasvik sud | même cause | non | non |

La projection a été écartée : les vides sont des bandes ou des triangles irréguliers qui suivent les tracés sources, et non des bandes de méridiens/parallèles. Une erreur de projection de l'ordre de la centaine de km² serait incompatible avec les autres coutures de l'atlas, qui restent nulles au seuil strict.

## 3. Modifications exactes

Six régions changent de géométrie ; `region_064` ne change que de métadonnées. Les 84 autres géométries sont identiques au sens `equals_exact(..., 0)`.

| Région | Géométrie | Aire avant | Aire après | Delta | Parties |
|---|---|---:|---:|---:|---:|
| `region_040` | modifiée | 89 432,34 km² | 89 494,98 km² | +62,64 km² | 1 → 1 |
| `region_047` | modifiée | 109 863,17 km² | 110 036,38 km² | +173,21 km² | 52 → 52 |
| `region_052` | modifiée | 369 406,96 km² | 370 069,44 km² | +662,48 km² | 61 → 61 |
| `region_062` | modifiée | 45 446,92 km² | 45 603,73 km² | +156,81 km² | 1 → 2 |
| `region_064` | inchangée | 368 914,81 km² | 368 914,81 km² | 0,00 km² | 1 → 1 |
| `region_065` | modifiée | 1 165 520,39 km² | 1 165 556,31 km² | +35,92 km² | 1 → 2 |
| `region_071` | modifiée | 38 904,39 km² | 38 910,82 km² | +6,43 km² | 1 → 1 |

Somme des deltas : **1 097,49 km²**. Les centroïdes, points représentatifs, boîtes englobantes, nombres de sommets et nombres de parties sont recalculés pour les régions modifiées.

Métadonnées ajoutées :

- `source_refs` : `ristat_1897_v1` ajouté à `region_052` ; les autres régions concernées disposaient déjà de la référence Kavanagh et aucune référence n'a été retirée.
- `approximations` : une note MAJ-004 par région concernée, avec les surfaces finales. `region_064` reçoit une note explicative alors que sa géométrie reste inchangée. Les notes sont générées après les réaffectations de contiguïté, ce qui évite les doublons et les surfaces obsolètes.

## 4. Résultats de validation

### 4.1 Avant correction (référence)

Exécution sur le dépôt de base, fichiers canoniques non modifiés :

```text
Régions: 90/90; géométries valides: 90/90
Doublons: 0; paires avec chevauchement > 1e-10 deg²: 0
Somme des superficies: 10026551.20 km²
Saray: point dans 088=True, Van dans 088=False
Strumica: dans 072=False, dans 074=True
Lacunes sentinelles non résolues: 2/4 ['MAJ-004 Finlande/Olonets', 'MAJ-004 tripoint Khotin/Herța']
ERREUR: Strumica n'est pas attribuée exclusivement à region_072 (072=False, 074=True)
```

`validate_geometry.py` sort avec le code 1 à cause de Strumica ; il signale en plus `2/4` lacunes sentinelles non résolues. `validate_atlas.py` sort avec le code 0, avec l'avertissement habituel sur l'absence d'emprise de référence.

### 4.2 Après correction (copie de test)

```text
Régions: 90/90; géométries valides: 90/90
Doublons: 0; paires avec chevauchement > 1e-10 deg²: 0
Somme des superficies: 10027648.69 km²
Saray: point dans 088=True, Van dans 088=False
Strumica: dans 072=False, dans 074=True
Lacunes sentinelles non résolues: 0/4 []
ERREUR: Strumica n'est pas attribuée exclusivement à region_072 (072=False, 074=True)
```

`validate_geometry.py` sort encore avec le code 1, mais **uniquement à cause de Strumica**, anomalie préexistante. Les quatre lacunes MAJ-004 ne figurent plus parmi les échecs. `validate_atlas.py` sort avec le code 0.

Le rapport de correction confirme en outre :

- `90` géométries valides et non vides ;
- `0` paire avec chevauchement `> 1e-10 deg²` ;
- `0` résidu de lacune pour les quatre géométries initiales ;
- `0` réparation d'arrondi nécessaire ;
- superficie totale `10 027 648,69 km²`.

### 4.3 Ce qui n'est pas corrigé

**Strumica** (`[22,6427, 41,4378]`) reste dans `region_074` et non dans `region_072`. Cette anomalie est antérieure à MAJ-004, relève d'une autre décision historique (frontière bulgaro-serbe de 1913-1919) et ne doit pas être confondue avec les quatre lacunes. Le validateur géométrique continue donc d'échouer sur ce point ; le présent rapport ne prétend pas avoir rendu `validate_geometry.py` entièrement vert.

## 5. Sources et licences

| Source | Usage | Fichier / couche | Licence |
|---|---|---|---|
| RISTAT, *Russian Empire 1897 — Provinces* | arbitrage Finlande/Olonets ; contrôle Bessarabie et Pasvik | `ristat_1897_provinces.gpkg`, couche `provinces_1897`, champ `prov_ENG` (Kuopio, Vyborg, Olonets, Bessarabie) | CC0 ; DOI `10.34894/NQOASN` (DataverseNL) |
| Jack Kavanagh, *Map of Europe, c. 1914* | partition du tripoint et du Pasvik | `europe_1914.gpkg`, couche `europe_1914`, champ `name` (Austria-Hungary, Romania, Russia, Norway) | CC BY 4.0 ; DOI `10.5281/zenodo.21341486` |
| REGIS, *Historical GIS of Europe* | diagnostic des coutures et contexte des lots | `REGIS_Finland_L1_1870-1918`, `REGIS_Austria_Hungary_L2_1908-1914`, `REGIS_Romania_L1_1879-1913` / `L2_1879-1913`, `REGIS_Norway_L0_1870-2020` | CC BY 4.0 ; DOI `10.1007/978-3-032-14932-9_3` |

Remarques :

- Kavanagh est une carte historique généralisée ; elle est utilisée pour la **logique nationale** de la partition, pas comme levé cadastral. Les réaffectations de contiguïté du tripoint sont explicitées pour que cette limite soit visible.
- REGIS n'est pas requis par le script de correction ; il a servi à qualifier les sources et les vides. Le script ne dépend que de RISTAT et de Kavanagh.
- OpenStreetMap a été envisagé comme contrôle pour le Pasvik, mais n'a pas été retenu pour l'attribution finale : couverture Overpass incomplète dans cet environnement et contraintes d'attribution ODbL. Kavanagh (CC BY 4.0) fournit une source unique, cohérente et attribuable pour les deux côtés de la frontière.
- Les jeux externes ne sont pas versionnés dans le dépôt. La reproductibilité exige de les télécharger depuis les DOI ci-dessus et de passer leurs chemins au script.

## 6. Reproductibilité

```bash
# Depuis la racine du worktree
python tools/map/close_geometry_gaps.py \
  --kavanagh /chemin/europe_1914.gpkg \
  --ristat /chemin/ristat_1897_provinces.gpkg \
  --output-dir /tmp/opencode/gs1914-corrected

# Copier les trois sorties dans une copie de test, puis :
python tools/map/validate_geometry.py
python tools/map/validate_atlas.py
```

Le script :

- vérifie que la sortie n'est pas `data/world/map` ;
- réécrit `regions.geojson`, `regions.json` et `geometry_gaps_report.json` dans le répertoire fourni ;
- échoue si une lacune ne correspond pas à la surface attendue à `0,01 km²` près ;
- échoue si la partition n'est pas exacte, si une géométrie devient invalide ou si un chevauchement `> 1e-10 deg²` subsiste.

Le rapport JSON de la copie de test contient les surfaces avant/après, les couvertures RISTAT/Kavanagh, les trois réaffectations de contiguïté et les contrôles de résidu. Il n'est pas destiné à être commité dans les données canoniques : il documente l'exécution de test.

## 7. Conclusion et recommandation

Les quatre lacunes MAJ-004 sont **résolues dans la copie de test** avec une justification historique explicite :

- Finlande/Olonets : RISTAT 1897, attribution à la Finlande, incertitude `±0,005 km²` ;
- tripoint Khotin/Herța : Kavanagh 1914, partition en trois, trois réaffectations de contiguïté totalisant 1,18 km² ;
- Pasvik nord/sud : Kavanagh 1914 et frontière de 1826, partition Norvège/Russie.

La correction ne crée aucun chevauchement, ne laisse aucun vide, ne modifie pas les seuils et ne touche ni aux lots sources ni aux fichiers canoniques. Elle laisse intacte l'anomalie préexistante de Strumica, qui relève d'un autre chantier.

Recommandation : intégrer les sorties de `close_geometry_gaps.py` dans le fichier canonique lors d'une étape d'intégration dédiée, après revue de ce rapport, puis relancer les deux validateurs. Ne pas fusionner la branche `fix/map-geometry-gaps` en l'état : elle porte l'outil et le rapport, pas les données corrigées.
