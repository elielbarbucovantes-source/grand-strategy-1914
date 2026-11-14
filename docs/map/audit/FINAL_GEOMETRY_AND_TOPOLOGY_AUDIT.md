# AUDIT FINAL — GÉOMÉTRIE DÉFINITIVE ET TOPOLOGIE DES 90 RÉGIONS

- **Projet** : Grand Strategy-1914, atlas européen de 90 régions au 1er janvier 1914
- **Branche de travail** : `consolidate/map-1914-topology`
- **Commit d'intégration de Strumica** : `47bc6feca3a7c0102415360093f92b82b7b2f7bf` (fast-forward déjà publié)
- **Commit de reconstruction topologique** : `6d30a512c6900c815c6b312029859cc9fd3fe997`
- **Référence temporelle** : `1914-01-01`
- **Statut** : **VALIDÉ** — géométrie 90/90, topologie 95 contrôles / 0 échec, reconstruction reproductible octet pour octet.

---

## 1. Résumé exécutif

La correction du saillant de Strumica (`MAJ-003`) est bien intégrée à la lignée
géométrique principale. Aucune nouvelle fusion n'a été nécessaire : le
fast-forward de `audit/map-strumica-final` vers
`consolidate/map-1914-geometry` était déjà réalisé et publié. Les corrections
antérieures `BLK-001` (homonymie Saray), `BLK-002` (micro-chevauchements
d'arrondi) et `MAJ-004` (quatre lacunes de couture) restent présentes et sont
revalidées.

La topologie a été **entièrement reconstruite** depuis
`data/world/map/regions.geojson` définitif, et non depuis les lots bruts ni
depuis l'ancien `adjacency.json` :

| Élément | Nombre |
|---|---:|
| Régions | 90 |
| Arêtes terrestres | **184** |
| — internes agent_1 | 97 |
| — internes agent_2 | 69 |
| — interfaces inter-lots | 17 |
| — arête manquante 033/037 (MAJ-007) | 1 |
| Détroits inter-régionaux | **10** |
| Détroits internes à une région | **3** |
| Couples de régions jouables (terre + détroits) | **192** |
| Connexions entre zones maritimes | **14** |
| Liens région ↔ zone maritime | **67** (66 géométriques + 1 catalogue) |
| Proximités non connectées inventoriées | **8** |
| Régions côtières sans zone maritime | **26** |

Le graphe terrestre conserve **exactement les 184 mêmes couples** que la
topologie antérieure : Strumica ne crée ni ne supprime aucune adjacence, elle
modifie uniquement des longueurs de frontière. L'Islande (`region_051`) reste
la seule région isolée du graphe jouable, faute de détroit documenté.

---

## 2. Intégration de Strumica (`MAJ-003`)

### 2.1 État Git vérifié

| Vérification | Résultat |
|---|---|
| `a7983e7` ancêtre de `47bc6fe` | **Oui** (`git merge-base --is-ancestor`) |
| `consolidate/map-1914-geometry` | `47bc6fe` |
| `origin/consolidate/map-1914-geometry` | `47bc6fe` |
| `audit/map-strumica-final` | `47bc6fe` |
| Fast-forward déjà appliqué et publié | **Oui** |
| `main` modifié | **Non** |

Aucun push forcé, aucune fusion improvisée, aucune modification écrasée. Le
rapport d'audit indépendant `docs/map/corrections/STRUMICA_FINAL_RESOLUTION.md`
est conservé et reste la référence de la décision `VALIDÉ`.

### 2.2 Chaîne de commits

| Commit | Rôle |
|---|---|
| `a7983e7` | Consolidation BLK-001 + BLK-002 + MAJ-004 |
| `03bce80` | Correction géométrique de Strumica (+1 151,51 km² à `region_072`, −1 151,51 km² à `region_074`) |
| `47bc6fe` | Rapport d'audit indépendant Strumica (`VALIDÉ`) — tip du fast-forward |

### 2.3 Corrections antérieures toujours présentes

Contrôlées par `tools/map/validate_geometry.py` (code de sortie **0**) :

| Correction | Contrôle | Résultat |
|---|---|---|
| `BLK-001` — Saray | point Saray dans `region_088` = `True`, dans la zone de Van = `False` | **OK** |
| `BLK-002` — micro-chevauchements | paires avec chevauchement > `1e-10` deg² = **0** | **OK** |
| `MAJ-004` — 4 lacunes de couture | lacunes sentinelles non résolues = **0/4** | **OK** |
| `MAJ-003` — Strumica | Strumica dans `region_072` = `True`, dans `region_074` = `False` | **OK** |

---

## 3. Géométrie définitive

| Métrique | Valeur |
|---|---|
| Régions présentes / valides | **90 / 90** |
| Doublons d'identifiant | 0 |
| Paires en chevauchement > `1e-10` deg² | 0 |
| Superficie totale | **10 027 649,63 km²** |
| Contacts ponctuels (≤ 10 m) entre régions | 0 |

`tools/map/validate_atlas.py` confirme également l'index éditorial (90 lignes,
champs obligatoires présents) et la validité des 90 géométries. Son
avertissement sur l'absence d'emprise de référence reste une limite
méthodologique connue, sans incidence sur la topologie.

### Empreintes des sources

| Fichier | SHA-256 |
|---|---|
| `data/world/map/regions.geojson` | `183e5e8073006f32a72b7fdd43774861f8a98f649ef24ee71a49e6be47ee3623` |
| `data/world/map/regions.json` | `4b26f0bd133dd9d85dbac6a7d3319aa27da82569af94533e453ac1d76734e771` |
| `data/world/map/build/agent_1/adjacency.json` | `5e58968e59f9d4bdb7a1880a6e1a3fe86ab8a783333463f837f1334da7cf6fd7` |
| `data/world/map/build/agent_2/adjacency.json` | `3ffbdfe7b47efac47c6af0cfdd981df466e20232c07c04e004b1ed4901f9aedd` |
| `data/world/map/build/agent_2/maritime_zones.json` | `6bf861ad5930453c3a5144f70446d369bd68ee4f71052b08076ce555f283995b` |
| `tools/map/rebuild_topology.py` | `15f7b9f9a7b0ba6477bd8d90b1c50bfc644e3ed7b0ce9ce2a243a42b33f604a3` |
| `data/world/map/adjacency.json` | `4013f26e2e816b4f77cead6b6147270d823d96efcf37493dd6e7229d43a28bb8` |

`regions.json` **n'a pas été modifié** : son empreinte auditée `4b26f0bd…`
reste stable. Le champ `adjacent_region_ids` qu'il contient est une donnée
legacy incomplète (166 couples) ; `adjacency.json` est désormais l'artefact
topologique autoritaire.

---

## 4. Méthode de reconstruction topologique

### 4.1 Principe

1. **Frontières terrestres** : intersection des frontières des 90 polygones de
   `regions.geojson` reprojetés en **EPSG:3035**, seuil de **10 m**. Aucune
   arête n'est créée sans support géométrique mesuré.
2. **Métadonnées curatées** : les champs documentaires des lots
   (`terrain_boundary_class`, obstacles naturels, passages documentés,
   références) sont fusionnés par couple de régions. La longueur géométrique
   devient la valeur autoritaire (`shared_border_km`) ; la valeur curatée est
   conservée dans `curated_shared_border_km`.
3. **Interfaces inter-lots** : les 17 interfaces sont recalculées depuis la
   géométrie définitive et enrichies des notes de l'interface `agent_2`.
4. **Détroits** : les traversées documentées des lots et quatre passages
   occidentaux curatés (Douvres, Canal du Nord, Saint-Georges, Bonifacio) sont
   revalidés par la distance minimale en EPSG:3035. Les détroits internes sont
   séparés des traversées inter-régionales.
5. **Zones maritimes** : les liens région ↔ zone sont dérivés du contact
   géométrique avec les polygones de `maritime_zones.json` (seuil 200 m ou
   frontière partagée > 50 m). Les liens déclarés au catalogue mais non
   reproduits sont conservés avec la mention `catalogue_only`.
6. **Proximités** : tout couple à moins de 20 km sans frontière terrestre ni
   détroit documenté est inventorié dans `proximity_only_pairs`, qualifié et
   **jamais** converti en adjacence.

### 4.2 Distinctions sémantiques du fichier

| Champ / section | Signification |
|---|---|
| `edges` (`connection_type: land`) | Frontière terrestre jouable |
| `strait_crossings` (`connection_type: strait`) | Passage par détroit documenté |
| `internal_straits` (`connection_type: internal_strait`) | Détroit interne à une seule région (Bosphore, Belts, Dardanelles) |
| `proximity_only_pairs` (`connection_type: proximity_only`) | Proximité sans connexion jouable |
| `region_maritime_zone_links` | Façade maritime, pas une adjacence terrestre |
| `maritime_zone_connections` | Continuité entre bassins maritimes |
| `neighbors_by_region` | Voisinage **terrestre** uniquement |
| `passable_neighbors_by_region` | Voisinage **terrestre + détroits** |

Deux couples cumulent volontairement une frontière terrestre et un détroit :
`053/054` (Moonsund + frontière de Courlande) et `077/079` (Rio-Antirrio +
isthme de Corinthe). Le drapeau `also_land_adjacent` et la note de distance
l'indiquent explicitement.

### 4.3 Reproductibilité

Le constructeur est déterministe : ordre des clés trié, aucun horodatage,
aucun accès réseau, empreintes SHA-256 des sources inscrites dans
`generated_from`. Trois exécutions successives produisent le même fichier
`4013f26e…`. Le contrôle `--rebuild-check` rejoue le constructeur dans un
fichier temporaire et compare les octets : **identique**.

Un clone propre de la branche `consolidate/map-1914-topology` (commit
`6d30a51`), exécuté avec le même interpréteur GIS, produit également
`4013f26e…` : la reconstruction ne dépend ni du répertoire de travail ni de
fichiers non versionnés.

---

## 5. Effets de Strumica et des corrections antérieures sur les longueurs

Les 184 couples sont inchangés. **15 interfaces** varient de plus de 0,5 km,
dont 12 de plus de 1 km. La longueur cumulée passe de 62 408,85 km à
**62 838,14 km** (+429,29 km).

| Interface | Avant (km) | Après (km) | Écart | Origine |
|---|---:|---:|---:|---|
| `052` ↔ `064` | 461,19 | 589,48 | +128,29 | MAJ-004 (Finlande/Olonets) |
| `047` ↔ `065` | 67,33 | 162,48 | +95,15 | MAJ-004 |
| `088` ↔ `089` | 199,34 | 267,21 | +67,87 | BLK-001 (Saray) |
| **`072` ↔ `074`** | **452,21** | **513,38** | **+61,17** | **Strumica** |
| `040` ↔ `062` | 33,22 | 79,73 | +46,51 | MAJ-004 |
| **`072` ↔ `078`** | **118,94** | **131,73** | **+12,79** | **Strumica** |
| **`074` ↔ `078`** | **226,02** | **213,24** | **−12,78** | **Strumica** |
| `062` ↔ `071` | 450,08 | 462,51 | +12,43 | MAJ-004 |
| `040` ↔ `071` | 268,20 | 276,04 | +7,84 | MAJ-004 |
| `037` ↔ `081` | 426,54 | 429,78 | +3,24 | consolidation |
| `074` ↔ `076` | 294,07 | 297,14 | +3,07 | consolidation |
| `070` ↔ `073` | 286,68 | 288,31 | +1,63 | consolidation |

Le sens des variations Strumica est cohérent avec le transfert de
1 151,51 km² de `region_074` vers `region_072` : la frontière serbo-bulgare
`072/074` s'allonge, la frontière `072/078` s'allonge et la frontière
`074/078` se raccourcit.

---

## 6. Détroits et passages maritimes

### 6.1 Détroits inter-régionaux (10)

| Détroit | Régions | Largeur catalogue | Distance mesurée | Cumul terrestre |
|---|---|---:|---:|---|
| Pas de Calais / Douvres | `001` ↔ `007` | 33,0 km | 32,62 km | non |
| Canal du Nord | `003` ↔ `005` | 21,0 km | 21,50 km | non |
| Canal Saint-Georges | `004` ↔ `006` | 80,0 km | 78,72 km | non |
| Bouches de Bonifacio | `012` ↔ `086` | 11,0 km | 11,87 km | non |
| Øresund | `044` ↔ `048` | 4,0 km | 4,42 km | non |
| Mer d'Åland | `049` ↔ `052` | 38,0 km | 37,34 km | non |
| Moonsund / Irbe | `053` ↔ `054` | 27,0 km | 0,00 km | **oui** |
| Kertch | `063` ↔ `069` | 4,5 km | 3,37 km | non |
| Rio-Antirrio / Corinthe | `077` ↔ `079` | 2,2 km | 0,00 km | **oui** |
| Messine | `084` ↔ `085` | 3,1 km | 2,45 km | non |

Les distances nulles des deux cas cumulés signifient que les régions se
touchent **ailleurs** par une frontière terrestre ; la largeur du détroit reste
celle du catalogue et le cumul est signalé, pas fusionné.

### 6.2 Détroits internes (3)

| Détroit | Région | Largeur catalogue |
|---|---:|---:|
| Grand Belt / Petit Belt | `044` Danemark | 16,0 km |
| Bosphore | `087` Constantinople | 0,7 km |
| Dardanelles | `090` Gallipoli | 1,2 km |

Ces détroits ne créent pas d'auto-adjacence : ils sont stockés avec un
`region_id` unique, sans `region_a_id` / `region_b_id`.

---

## 7. Relations entre régions et zones maritimes

- **16 zones maritimes** au catalogue, dont **14 connexions réciproques** entre
  bassins. Seule `mz_caspian_sea` est isolée côté maritime.
- **67 liens région ↔ zone** : 66 dérivés du contact géométrique, 1 conservé
  depuis le catalogue (`region_051` ↔ `mz_norwegian_sea`).
- **36 régions** touchant au moins une zone.
- **53 liens** sont déclarés au catalogue ; 52 sont reproduits par la
  géométrie, 1 ne l'est pas (Islande / mer de Norvège).
- **14 liens géométriques supplémentaires** ne figurent pas dans
  `coastal_region_ids` : `026`, `027`, `028` (×2), `029` (×2), `043`, `045`,
  `050` (×2), `052`, `053`, `077`, `084`. Le catalogue curaté était donc
  incomplet même pour le lot `agent_2` ; la géométrie définitive fait foi et le
  drapeau `catalogue_declared` permet de distinguer les deux origines.
- **26 régions côtières** n'ont aucune zone maritime configurée, faute de
  polygone de bassin pour la Manche, l'Atlantique, la Méditerranée occidentale
  et la mer Tyrrhénienne : `001`, `002`, `003`, `004`, `005`, `006`, `007`,
  `008`, `009`, `010`, `012`, `013`, `015`, `016`, `020`, `021`, `022`, `024`,
  `025`, `037`, `080`, `081`, `082`, `083`, `085`, `086`. C'est une **limite de
  couverture du catalogue maritime**, pas une erreur de topologie terrestre.

---

## 8. Proximités non connectées (8)

Ces couples ne sont ni des frontières terrestres ni des détroits documentés.
Ils sont conservés hors du graphe jouable avec une qualification explicite.

| Couple | Distance | Classification | Justification |
|---|---:|---|---|
| `001` ↔ `009` | 15,23 km | `island_sea_gap` | Îles Anglo-Normandes (rattachées à `001`) et côte normande ; le transmanche documenté reste Douvres—Calais (`001/007`). |
| `013` ↔ `032` | 4,72 km | `third_region_interposition` | Le Limbourg néerlandais (`016`) sépare la Flandre de la Rhénanie. |
| `014` ↔ `035` | 8,82 km | `third_region_interposition` | Le Luxembourg (`019`) sépare la Wallonie de l'Alsace-Lorraine. |
| `018` ↔ `034` | 1,11 km | `lake_gap` | Lac de Constance : pas de frontière terrestre tracée ; la frontière germano-suisse est portée par `033`. |
| `018` ↔ `035` | 9,61 km | `river_gap` | Couloir rhénan au sud de Bâle ; la traversée Suisse—Alsace est déjà portée par `017/035`. |
| `043` ↔ `076` | 15,36 km | `third_region_interposition` | Le Monténégro (`075`) sépare la Bosnie-Herzégovine de l'Albanie. |
| `046` ↔ `049` | 6,00 km | `lake_gap` | Lac de Femunden / Kjölen ; la frontière norvégo-suédoise est couverte par `045/049` et `046/050`. |
| `076` ↔ `077` | 2,31 km | `sea_gap_undocumented` | Canal de Corfou (Albanie—Corfou) : passage étroit mais aucune traversée de 1914 documentée dans le corpus ; non promu en détroit. |

Aucune de ces proximités n'apparaît dans `edges` ni dans `strait_crossings`.

---

## 9. Anomalies, écarts et limites

### 9.1 Écarts documentés

1. **`region_051` ↔ `mz_norwegian_sea`** — le catalogue déclare l'Islande
   côtière de la mer de Norvège, mais le polygone de zone en est distant de
   **170,22 km**. Le lien est conservé en `catalogue_only`, avec
   `geometry_contact: false` ; il ne crée aucune adjacence de détroit.
2. **`mz_norwegian_sea` a une géométrie invalide** (auto-intersection). Elle
   est nettoyée par `buffer(0)` **uniquement pour la mesure de distance** ; le
   catalogue n'est pas modifié et le drapeau `geometry_valid: false` est inscrit
   dans `maritime_zones`.
3. **Catalogue maritime incomplet** — 53 liens déclarés pour 66 liens
   géométriques ; 26 régions côtières sans bassin. Voir section 7.
4. **Longueur `026` ↔ `056`** — la géométrie définitive donne **365,47 km**,
   contre 369,18 km dans le lot `agent_2` et 368,87 km dans l'audit antérieur.
   La valeur géométrique est autoritaire ; les deux valeurs curatées sont
   conservées (`curated_shared_border_km`).
5. **`regions.json` legacy** — `adjacent_region_ids` ne liste que 166 couples
   sur 184 (18 interfaces absentes : 17 inter-lots + l'arête 033/037). Le
   fichier n'a pas été modifié, conformément à la consigne de stabilité de son
   empreinte ; `adjacency.json` est la référence.
6. **Aucun contact ponctuel** ≤ 10 m entre régions : aucune arête de type
   « point de touche » n'a été introduite.

### 9.2 Limites préexistantes

- Le fichier Kavanagh `europe_1914.gpkg` reste introuvable sur la machine ; le
  substitut basse résolution déjà documenté n'est **pas** utilisé par la
  reconstruction topologique, qui ne dépend que de `regions.geojson` définitif.
- L'absence d'emprise de référence empêche `validate_atlas.py` de conclure à la
  couverture géographique complète ; cette limite est éditoriale, pas
  topologique.
- `region_051` reste isolée dans le graphe jouable : elle n'est reliée à aucune
  autre région par un détroit documenté. Sa façade maritime est représentée par
  deux zones, mais aucune traversée inter-régionale n'est modélisée.

---

## 10. Résultats des validations

### 10.1 Validateurs exécutés

| Validateur | Commande | Résultat |
|---|---|---|
| Géométrie | `.venv/bin/python tools/map/validate_geometry.py` | **exit 0** — 90/90, 0 chevauchement, 0/4 lacune, Saray OK, Strumica OK |
| Atlas | `.venv/bin/python tools/map/validate_atlas.py` | **exit 0** — index 90 lignes, géométries 90/90 |
| Topologie | `.venv/bin/python tools/map/validate_topology.py` | **exit 0** — 93 contrôles, 0 échec |
| Topologie + rejeu | `.venv/bin/python tools/map/validate_topology.py --rebuild-check` | **exit 0** — 95 contrôles, 0 échec, reconstruction identique |

### 10.2 Couverture des contrôles topologiques

- 90 identifiants `region_001..region_090`, aucun doublon, aucune référence
  inexistante.
- 184 arêtes terrestres, couples uniques, sans auto-boucle, symétriques,
  longueurs conformes à la mesure EPSG:3035.
- 17 interfaces inter-lots, arête 033/037 marquée `missing_land_edge`.
- 10 détroits et 3 détroits internes, distances crédibles, cumuls
  terre/détroit exactement limités à Moonsund et Rio-Antirrio.
- 192 couples jouables, graphe symétrique, seule `region_051` isolée.
- 8 proximités qualifiées, aucune promue en adjacence.
- 16 zones, 14 connexions réciproques, 67 liens région/zone, 26 régions
  côtières sans zone, aucune région sans côte reliée à une zone.
- Empreintes SHA-256 des cinq sources et du constructeur exactes.
- Reconstruction reproductible octet pour octet, y compris depuis un clone
  propre de la branche.

---

## 11. Fichiers modifiés

| Fichier | Nature |
|---|---|
| `data/world/map/adjacency.json` | **Nouveau** — topologie canonique v2.0.0 des 90 régions |
| `tools/map/rebuild_topology.py` | **Nouveau** — constructeur déterministe |
| `tools/map/validate_topology.py` | **Nouveau** — validateur indépendant |
| `docs/map/audit/FINAL_GEOMETRY_AND_TOPOLOGY_AUDIT.md` | **Nouveau** — présent rapport |

Aucun autre fichier n'a été modifié : ni géométrie, ni `regions.json`, ni
données démographiques, économiques ou militaires, ni décision de conception,
ni mécanique de jeu, ni couche thématique. Le nombre de régions reste **90**.

---

## 12. Reproductibilité — commandes de référence

```bash
# Reconstruction
.venv/bin/python tools/map/rebuild_topology.py

# Validation simple
.venv/bin/python tools/map/validate_topology.py

# Validation + rejeu octet pour octet
.venv/bin/python tools/map/validate_topology.py --rebuild-check

# Géométrie et atlas
.venv/bin/python tools/map/validate_geometry.py
.venv/bin/python tools/map/validate_atlas.py
```

Empreinte attendue de `data/world/map/adjacency.json` :
`4013f26e2e816b4f77cead6b6147270d823d96efcf37493dd6e7229d43a28bb8`.

---

## 13. Prochaines opérations

1. **Fusion contrôlée** de `consolidate/map-1914-geometry` et
   `consolidate/map-1914-topology` dans la lignée d'intégration, après revue :
   la branche topologique contient déjà la géométrie définitive.
2. **Curation du catalogue maritime** : découper les façades absentes
   (Manche, Atlantique, Méditerranée occidentale, Tyrrhénienne, Adriatique
   nord) pour couvrir les 26 régions côtières orphelines.
3. **Arbitrage documentaire** sur le canal de Corfou (`076/077`) et sur les
   traversées des proximités qualifiées, si une source de 1914 est ajoutée au
   corpus.
4. **Réparation géométrique** de `mz_norwegian_sea` (auto-intersection) et
   alignement de son emprise avec la côte islandaise, afin de reproduire le
   lien `051` sans passer par `catalogue_only`.
5. **Mise à jour optionnelle de `regions.json`** : aligner
   `adjacent_region_ids` sur les 184 arêtes, dans une opération distincte et
   avec recalcul d'empreinte, puisque ce fichier est resté volontairement
   inchangé ici.
6. **Consolidation thématique** (démographie, économie, militaire) sur la base
   du graphe validé, sans modifier `adjacency.json`.
