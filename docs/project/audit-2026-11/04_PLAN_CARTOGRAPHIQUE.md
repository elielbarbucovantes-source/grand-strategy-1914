# Livrable 4 — Audit cartographique approfondi et plan de la phase 2

- **Base :** `regions.geojson`, `adjacency.json` et `build/agent_2/maritime_zones.json` de `40a3117` (inchangés depuis) ; `cities.json` de `4dbf4f8`.
- **Outil :** `tools/audit/map_audit.py`, en lecture seule. La sortie brute est en annexe A.
- **Statut :** constats mesurés et **tâches proposées**. Aucune donnée n'a été modifiée. Les tests de correction ont été faits sur des copies jetables.

## 1. Catalogue maritime

### 1.1 Constats

- **16 zones**, toutes construites comme des **rectangles en longitude et latitude** dont on a soustrait les terres. Exemple : `mz_north_atlantic_iceland` = [−26,5 ; 60] → [−10 ; 68].
- **Liens :** 52 sont déclarés dans le catalogue et confirmés par la géométrie ; **14 sont géométriques mais non catalogués** ; 1 n'existe que dans le catalogue (051 ↔ `mz_norwegian_sea`, à 170,22 km). Total : 67.

  Les 14 liens géométriques non catalogués :

  | Région | Zone |
  |---|---|
  | 026, 027, 028 | `mz_baltic_south_central` |
  | 028, 029 | `mz_skagerrak_kattegat` |
  | 029, 045 | `mz_north_sea_eastern` |
  | 043, 077, 084 | `mz_adriatic_south_otranto` |
  | 050 | `mz_barents_white_sea`, `mz_norwegian_sea` |
  | 052 | `mz_barents_white_sea` |
  | 053 | `mz_gulf_of_bothnia` |

  Plusieurs figuraient déjà dans le champ `external_coastal_region_ids` du catalogue : le lot `agent_2` les connaissait mais ne les déclarait pas, car ils sortaient de son périmètre.
- **Graphe naval : 3 composantes disjointes.**
  1. Islande, Norvège, Barents, mer du Nord orientale, Skagerrak, Baltique, Botnie, golfes de Finlande et de Riga.
  2. Otrante, Ionienne, Égée, Marmara, mer Noire (Ouest et Est), Azov.
  3. Caspienne.

  Aucune liaison ne relie l'Atlantique à la Méditerranée.

### 1.2 Les 26 façades orphelines, regroupées par mer manquante

Pour toutes, la zone existante la plus proche est à plus de 145 km. L'absence est **structurelle** : le lot `agent_1` n'a produit aucune zone maritime.

| Mer manquante | Régions | Classement proposé |
|---|---|---|
| Mer du Nord occidentale et méridionale | 002, 003, 013, 015, 016 (et 029 en partie) | Zone à créer, ou extension de `mz_north_sea_eastern` vers l'Ouest et le Sud |
| Manche | 001, 007, 008, 009 | Zone à créer |
| Mer d'Irlande et Atlantique britannique | 003, 004, 005, 006 | Zone à créer |
| Golfe de Gascogne et Atlantique ibérique | 009, 010, 020, 021, 025 | Une ou deux zones à créer |
| Méditerranée occidentale (Baléares, golfe du Lion) | 012, 022, 024, 025, 086 | Zone à créer (Gibraltar inclus ou comme détroit) |
| Ligurie et Tyrrhénienne | 080, 082, 085 (et 086, 012 Corse) | Zone à créer |
| Adriatique Nord | 037, 081, 083 (et 043) | Zone à créer, ou extension de `mz_adriatic_south_otranto` |
| Sicile orientale et mer Ionienne | 085 | Extension de `mz_ionian_sea`, dont la limite actuelle est 18,5°E |

**Aucune façade n'est « normale » sans zone.** Chacune donne sur une mer navigable en 1914. Le nombre de zones et leurs limites relèvent de **MAP-OPEN-08** (« nombre et limites des zones ») et du principe validé MAP-DEC-11 (« zones maritimes intermédiaires »). C'est donc une **décision du directeur** (U3).

### 1.3 Catalogue corrigé proposé (non appliqué)

- **C2a (factuel, sans décision) :** ajouter les 14 liens géométriques au champ `coastal_region_ids` des zones concernées, et décider du sort du lien `catalogue_only` 051 ↔ `mz_norwegian_sea` (voir §3).
- **C2b (sur décision U3) :** deux variantes seront chiffrées :
  - **V1, 7 zones :** mer du Nord Sud-Ouest, Manche, mer d'Irlande, Atlantique (Gascogne et Ibérie), Méditerranée occidentale, Tyrrhénienne, Adriatique Nord ;
  - **V2, 9 zones :** V1 avec l'Atlantique scindé en Gascogne et Ibérie, et un détroit de Gibraltar explicite.

  Les deux variantes rendent le graphe naval connexe, hors Caspienne. Elles seraient construites par la même méthode (rectangles moins terres), avec densification des arêtes.

## 2. Zone `mz_norwegian_sea`

| Point | Constat |
|---|---|
| **Origine** | La géométrie source est **valide en WGS 84**. Le défaut apparaît **après reprojection en EPSG:3035** : les arêtes longues du rectangle, droites en longitude et latitude, deviennent des courbes, et deux segments se croisent. Il ne se produit que dans la partie 0 (sur trois). |
| **Emplacement** | EPSG:3035 (4 032 158 ; 4 223 781), soit environ 4,67°E et 61,02°N, sur la côte norvégienne au nord de Bergen |
| **Contournement actuel** | `rebuild_topology.py` (l. 541–545) applique `buffer(0)` **pour la mesure seulement**, et inscrit `geometry_valid: false`. L'aire mesurée vaut 1 235 732 km². |
| **Correction réelle proposée** | `shapely.segmentize(geometry, 0.25)` en WGS 84 **avant** projection : même tracé en longitude et latitude, avec des sommets intermédiaires. La zone devient valide en 3035, pour une aire de 1 208 809 km². Le `buffer(0)` surestimait donc l'aire d'environ 27 000 km² (2,2 %). |
| **Effet testé** (copie jetable, `rebuild_topology.py --output`) | Aucun lien ajouté ni retiré. `geometry_valid` passe à vrai. 051 ↔ `mz_norwegian_sea` (lien `catalogue_only`) passe de 170,22 à 166,05 km. Les empreintes de `maritime_zones.json` et d'`adjacency.json` changent. |
| **Risque** | Faible : le tracé ne change pas. Il faut mettre à jour les empreintes dans `REFERENCE_SHA256SUMS` et dans `validate_topology.py`, dans le **même** commit, en indiquant l'ancienne et la nouvelle valeur. |

Je recommande d'appliquer la densification à **toutes** les zones, par prévention : les futures zones de C2b seront elles aussi des rectangles.

## 3. Région 051 (Islande)

- **Géographie :** île sans frontière terrestre. Régions les plus proches : Écosse 003 (780,6 km), Norvège Ouest 046 (969,6 km), Ulster 005 (1 071 km).
- **Données :** elle est reliée **géométriquement** à `mz_north_atlantic_iceland` (lien `geometry`, frontière partagée de 0,4 km), et par le catalogue seulement à `mz_norwegian_sea`. Cette zone est connectée à `mz_norwegian_sea`, puis à la mer du Nord orientale.
- **Pourquoi « isolée » :** le graphe `passable_neighbors_by_region` ne comprend que les arêtes terrestres et les **détroits**. Aucun détroit ne peut historiquement relier l'Islande : ce n'est pas un manque de données.
- **Historique :** en 1914, l'Islande est danoise. Les liaisons sont maritimes (lignes régulières de Copenhague via Leith et les Féroé).
- **Conclusion :** l'isolement est **justifié** dans le graphe terre et détroits. L'accessibilité relève du **mouvement naval par zones** (MAP-DEC-19 : débarquement sur les côtes accessibles). Il ne faut créer **aucun détroit**.
- **Décision (C3) :** « Le mouvement et le débarquement via les zones maritimes font-ils partie du graphe de déplacement jouable ? » Si oui, 051 devient accessible sans aucune modification géométrique.

## 4. Canal de Corfou (076/077)

- **Mesure :** 2,31 km au plus près, entre (19,9875 ; 39,7462) côté albanais et (19,9617 ; 39,7521) côté Corfou (Grèce, région 077, en 23 parties).
- **Topologie :** aucune arête ni détroit. Classé `sea_gap_undocumented` dans les proximités. Les deux régions touchent déjà `mz_adriatic_south_otranto` et `mz_ionian_sea`.
- **Navigabilité :** passage maritime étroit, mais navigable et emprunté par le cabotage. Aucune traversée militaire ou ferroviaire documentée dans le corpus pour 1914.
- **Contexte historique :** crise de l'Épire du Nord (1914), État albanais naissant, Corfou grecque depuis 1864.
- **Options :**

  | Option | Modification | Effet en jeu |
  |---|---|---|
  | A. Proximité seule (statu quo) | Aucune | Traversée uniquement par mouvement naval |
  | B. Détroit franchissable, comme Messine | Ajout dans `strait_crossings` | Traversée directe d'armées |
  | C. Passage naval privilégié | Attribut de zone | Dépend du modèle naval |

- **Recommandation :** A, cohérent avec la règle « détroit = passage documenté ». Décision mineure (C4).

## 5. Les huit proximités de moins de 20 km

| Couple | Distance | Classement actuel | Géographie | Proposition |
|---|---|---|---|---|
| 001–009 | 15,23 km | Écart maritime insulaire | Îles Anglo-Normandes face au Cotentin | Proximité (statu quo) |
| 013–032 | 4,72 km | Interposition d'une tierce région | Limbourg néerlandais (016) | Proximité (statu quo) |
| 014–035 | 8,82 km | Interposition d'une tierce région | Luxembourg (019) | Proximité (statu quo) |
| 018–034 | 1,11 km | Écart lacustre | Lac de Constance | Proximité (statu quo) |
| 018–035 | 9,61 km | Écart fluvial | Rhin au sud de Bâle ; passage porté par 017/035 | Proximité (statu quo) |
| 043–076 | 15,36 km | Interposition d'une tierce région | Monténégro (075) | Proximité (statu quo) |
| 046–049 | 6,0 km | Écart lacustre | Femunden / Kjölen ; frontière portée par 045/049 et 046/050 | Proximité (statu quo) |
| 076–077 | 2,31 km | Écart maritime non documenté | Canal de Corfou (§4) | Voir C4 |

Les huit classements sont **cohérents avec la géographie**. Je propose le statu quo, à confirmer en une seule fois (C5).

## 6. Les 175 villes

- **Résultats sur la géométrie validée** (`cities.json` de `4dbf4f8`) :
  - **0 ville hors région**, **0 rattachement modifié**, notamment pour Saray et Strumica ;
  - 0 doublon d'identifiant, de nom ou de coordonnées ;
  - souveraineté de chaque ville = souveraineté de sa région ;
  - les `city_ids` des 90 régions correspondent exactement aux 175 villes ;
  - 76 villes à moins de 5 km d'une frontière ou d'une côte, ce qui est attendu (67 grands ports) ;
  - 22 capitales pour 22 États souverains représentés.
- **Problèmes historiques (pas géométriques) :**
  - **Noms composites** qui mélangent plusieurs sites dans un seul point : « Saint-Pétersbourg (Kronstadt) », « Bucarest (Ploiești) », « Sofia (Vidin) », « Cetinje (Antivari/Bar) », « Durrës (Scutari / Vlora) », « Athènes (Le Pirée) ». Les coordonnées sont celles de la capitale ; le second site (port, pétrole, forteresse) n'a pas de point propre. « Christiania (Oslo) » et « Constantinople (Istanbul) » sont de simples équivalences de nom, sans problème.
  - **Capitale albanaise au 1/1/1914 :** Vlora (gouvernement provisoire jusqu'en janvier 1914) ou Durrës (prince de Wied, à partir de mars 1914). Le point retenu est Durrës. Dépend de R-13.
- **Provenance :** `source_refs` = `baedeker_bradshaw_1914` (175), REGIS (136), RISTAT (35), geoBoundaries (4), Kavanagh (4). Les coordonnées sont des valeurs modernes, dont la source n'est **pas** tracée.

## 7. Attributs des 90 régions

| Champ ou contrôle | Résultat | Fiabilité |
|---|---|---|
| `id`, `name_fr`, `name_key`, `zone`, `sovereign_1914`, `initial_sovereign_id` | Complets | Fiables (index éditorial validé) |
| `area_km2`, `centroid_lon_lat`, `representative_point_lon_lat`, `bbox` | Exacts (écart < 1 km² sur 90/90) | Fiables (dérivés) |
| `historical_admin_units`, `source_layer`, `source_refs` | Complets | Fiables pour la provenance ; voir l'audit des licences |
| `adjacent_region_ids` | **Diffère d'`adjacency.json` pour 20 régions** (026, 027, 029, 030, 033, 037, 040–044, 054–056, 058, 062, 070…) | **Obsolète** : héritage des lots ; `adjacency.json` fait référence |
| `external_adjacent_region_ids` | Vide pour 30 régions | Hérité des lots, obsolète |
| `maritime_zone_ids` | Vide pour 10 régions côtières | Incomplet (voir §1) |
| `relief_categories`, `importance_dimensions`, `island_class` | Présents (`island_class` = null pour 54, attendu) | À documenter : catégories non consolidées avec `terrain.json` |
| `notes` | Vide pour 28 | Sans effet |
| `etat_geometrie` | « construite » × 90 | À jour |
| `regions.json` comparé au GeoJSON | Identiques sur nom, souveraineté, aire et villes | — |

**Couches thématiques restées dans les lots :**
- `terrain.json` : 29 + 32 fleuves, 11 + 11 chaînes, sans identifiant commun alors que plusieurs fleuves et chaînes transfrontaliers sont décrits deux fois (MAJ-006) ;
- `infrastructure.json` : 76 + 53 axes ferroviaires, 47 + 37 ports, 32 + 33 forteresses, sans axe transfrontalier entre lots (MAJ-002).

## 8. Notes de recherche sur les ressources (hors Git)

`~/backups/gs1914-2026-11-13/sources/research_notes/Ressources naturelles 1914/` contient quatre fichiers (environ 270 Ko), sourcés surtout à l'Encyclopaedia Britannica de 1911 (Wikisource), au BGS, au BRGM, à l'IGME et à la SGU.

Elles utilisent une **numérotation provisoire différente** : leur « Region 001 — Scotland » correspond à `region_003`. Il faut une **table de correspondance** (C10) avant tout usage. Le statut « Attested / No evidence / Uncertain » et le niveau de confiance par ressource sont exploitables.

## 9. Plan d'exécution de la phase 2

Complexité : S < ½ jour d'agent ; M ≈ 1 jour ; L > 2 jours.

| ID | Objectif | État | Fichiers | Sources | Méthode | Tests | Acceptation | Risques | Dépend de | Décision humaine | Cplx |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **C1** | Rendre `mz_norwegian_sea` valide | Testé sur copie | `build/agent_2/maritime_zones.json`, `adjacency.json`, `tools/map/REFERENCE_SHA256SUMS`, empreintes de `validate_topology.py` | — | Nouveau `tools/map/repair_maritime_zones.py` (segmentize 0,25°, toutes zones, déterministe) ; rebuild | `validate_all.sh --full` ; diff des liens (0 ajout ou retrait attendu) | Zone valide, `geometry_valid` vrai pour 16/16 | Empreintes | — | Non | S |
| **C2a** | Cataloguer les 14 liens géométriques | Mesuré | `maritime_zones.json` | `adjacency.json` | Script déterministe | Rebuild : 66 liens déclarés = 66 géométriques | 0 lien géométrique non catalogué | Empreintes | C1 | Non | S |
| **C2b** | Mers occidentales | Analysé | `maritime_zones.json` (+ 7 ou 9 zones) | Natural Earth (domaine public) | Proposition V1 et V2 avec cartes, puis application de la variante choisie | Graphe naval connexe ; 0 façade orpheline | Décision appliquée | Licence : les trous côtiers dérivent de la géométrie des régions (voir livrable 2) | C2a, U1, **U3** | **Oui** | L |
| **C3** | Statut de la région 051 | Analysé | `docs/map/decisions/REGION_051.md` | — | Fiche | — | Décision consignée | — | — | **Oui** (modèle naval) | S |
| **C4** | Canal de Corfou | Analysé | `docs/map/decisions/CORFU_CHANNEL.md` | Sources de 1914 à citer | Fiche | — | Décision consignée | — | — | Oui (mineure) | S |
| **C5** | Huit proximités | Analysé | `docs/map/decisions/PROXIMITIES.md` | — | Tableau §5 | — | Confirmation | — | — | Confirmation groupée | S |
| **C6** | Réintégrer les villes | Mesuré : 175/175 conformes | `data/world/map/cities.json`, `tools/map/unify_thematic_data.py` (de `4dbf4f8`), nouveau `tools/map/validate_cities.py`, `validate_all.sh`, CI | — | `git checkout 4dbf4f8 -- …` ; validateur (point dans polygone, souveraineté, capitales, `city_ids`) | `validate_all --full` ; nouveau test négatif | 175/175 ; CI verte | Faible | — | Non | M |
| **C6b** | Noms composites et capitale albanaise | Analysé | `cities.json` | Baedeker 1914 | Proposition de séparation des sites (par exemple Kronstadt et Ploiești comme points distincts) | Validateur | Décision appliquée | Historique | C6, R-13 | **Oui** | S |
| **C7** | Consolider terrain et infrastructures | Mesuré | Nouveaux `data/world/map/terrain.json` et `infrastructure.json` ; `tools/map/consolidate_thematic.py` ; validateur | Lots `agent_*` | Fusion, dédoublonnage par identifiant canonique, contrôle des `region_ids`, liste des axes transfrontaliers manquants (sans les inventer) | Validateur dédié | Identifiants uniques ; références valides | Inventer des données : interdit | — | Oui, pour tout ajout historique | L |
| **C8** | Attributs dérivés obsolètes | Mesuré : 20 et 10 divergences | Propriétés de `regions.geojson` et `regions.json` | `adjacency.json` | ADR technique : **régénérer** depuis `adjacency.json` ou **retirer** ces champs ; script | `validate_all --full` ; reconstruction de la géométrie identique | 0 divergence | Empreintes du fichier de référence (aucun changement de géométrie) | C1, C2a | Non | M |
| **C9** | Statut des anomalies | Fait au lot 1 | `docs/map/audit/ISSUES_STATUS.md` | — | — | — | — | — | — | Non | S |
| **C10** | Correspondance des notes sur les ressources | Constaté | `data/research/resource_notes_mapping.csv` (nouveau) | Notes hors Git | Correspondance par nom et unités historiques | Contrôle croisé avec `region_plan.csv` | 90/90 correspondances | Interprétation | R-03 | Non | M |

**Parallélisation sans conflit :**
- **Série obligatoire :** C1, C2a, C8, puis C2b, sur une seule branche d'intégration (`consolidate/map-phase-2`). Toutes réécrivent `adjacency.json`, `maritime_zones.json` ou les empreintes.
- **En parallèle,** dans des worktrees distincts : C3, C4, C5 (documents seuls), C6 (nouveaux fichiers), C7 (nouveaux fichiers), C10.

**La cartographie ne sera pas « terminée »** tant que C1 à C8 ne sont pas traités ou explicitement acceptés, et que l'audit des licences n'est pas tranché.

## Annexe A — Sortie brute (`tools/audit/map_audit.py --cities-ref 4dbf4f8`, 14/11/2026)

```text
#### 1. ZONES MARITIMES
mz_north_atlantic_iceland      valide4326=True  valide3035=True  bbox=[-26.5, 60.0, -10.0, 68.0] cotes=['region_051'] externes=['region_003', 'region_005', 'region_006']
mz_norwegian_sea               valide4326=True  valide3035=False bbox=[-10.0, 61.0, 20.0, 71.5] cotes=['region_046', 'region_047', 'region_051'] externes=['region_003']
   3035 : Self-intersection[4032158.03968714 4223780.88751447]
mz_barents_white_sea           valide4326=True  valide3035=True  bbox=[20.0, 63.5, 68.5, 77.0] cotes=['region_047', 'region_065'] externes=[]
mz_north_sea_eastern           valide4326=True  valide3035=True  bbox=[3.0, 54.8, 8.7, 61.0] cotes=['region_044', 'region_046'] externes=['region_001', 'region_002', 'region_003', 'region_015', 'region_016', 'region_029']
mz_skagerrak_kattegat          valide4326=True  valide3035=True  bbox=[8.7, 54.5, 13.2, 59.9] cotes=['region_044', 'region_045', 'region_048'] externes=['region_029']
mz_baltic_south_central        valide4326=True  valide3035=True  bbox=[13.2, 53.8, 22.2, 59.5] cotes=['region_044', 'region_048', 'region_049', 'region_053', 'region_054'] externes=['region_026', 'region_027', 'region_028', 'region_029']
mz_gulf_of_bothnia             valide4326=True  valide3035=True  bbox=[17.0, 59.5, 25.5, 65.9] cotes=['region_049', 'region_050', 'region_052'] externes=[]
mz_gulf_of_finland_riga        valide4326=True  valide3035=True  bbox=[21.5, 57.0, 30.5, 60.8] cotes=['region_052', 'region_053', 'region_054', 'region_064'] externes=[]
mz_adriatic_south_otranto      valide4326=True  valide3035=True  bbox=[17.5, 39.8, 20.0, 42.6] cotes=['region_075', 'region_076'] externes=['region_043', 'region_083', 'region_084']
mz_ionian_sea                  valide4326=True  valide3035=True  bbox=[18.5, 35.8, 23.2, 39.8] cotes=['region_076', 'region_077', 'region_078', 'region_079'] externes=['region_084', 'region_085']
mz_aegean_sea                  valide4326=True  valide3035=True  bbox=[22.5, 34.8, 27.2, 41.0] cotes=['region_073', 'region_077', 'region_078', 'region_079', 'region_090'] externes=[]
mz_marmara_straits             valide4326=True  valide3035=True  bbox=[26.1, 40.0, 29.5, 41.3] cotes=['region_087', 'region_088', 'region_090'] externes=[]
mz_black_sea_west              valide4326=True  valide3035=True  bbox=[27.5, 41.1, 34.0, 46.7] cotes=['region_060', 'region_062', 'region_063', 'region_070', 'region_073', 'region_087', 'region_088', 'region_089'] externes=[]
mz_black_sea_east              valide4326=True  valide3035=True  bbox=[34.0, 41.5, 41.8, 45.3] cotes=['region_063', 'region_069'] externes=[]
mz_sea_of_azov                 valide4326=True  valide3035=True  bbox=[34.7, 45.2, 39.3, 47.3] cotes=['region_060', 'region_061', 'region_063', 'region_069'] externes=[]
mz_caspian_sea                 valide4326=True  valide3035=True  bbox=[46.5, 41.5, 53.5, 47.5] cotes=['region_068', 'region_069'] externes=[]
liens (dérivation, contact, catalogue) : {('geometry', True, False): 14, ('geometry', True, True): 52, ('catalogue_only', False, True): 1}
   géométrique non catalogué : region_026 -> mz_baltic_south_central
   géométrique non catalogué : region_027 -> mz_baltic_south_central
   géométrique non catalogué : region_028 -> mz_baltic_south_central
   géométrique non catalogué : region_028 -> mz_skagerrak_kattegat
   géométrique non catalogué : region_029 -> mz_north_sea_eastern
   géométrique non catalogué : region_029 -> mz_skagerrak_kattegat
   géométrique non catalogué : region_043 -> mz_adriatic_south_otranto
   géométrique non catalogué : region_045 -> mz_north_sea_eastern
   géométrique non catalogué : region_050 -> mz_barents_white_sea
   géométrique non catalogué : region_050 -> mz_norwegian_sea
   catalogue seulement : region_051 -> mz_norwegian_sea (170.22 km)
   géométrique non catalogué : region_052 -> mz_barents_white_sea
   géométrique non catalogué : region_053 -> mz_gulf_of_bothnia
   géométrique non catalogué : region_077 -> mz_adriatic_south_otranto
   géométrique non catalogué : region_084 -> mz_adriatic_south_otranto
composantes connexes du graphe naval : 3
    ['mz_adriatic_south_otranto', 'mz_aegean_sea', 'mz_black_sea_east', 'mz_black_sea_west', 'mz_ionian_sea', 'mz_marmara_straits', 'mz_sea_of_azov']
    ['mz_baltic_south_central', 'mz_barents_white_sea', 'mz_gulf_of_bothnia', 'mz_gulf_of_finland_riga', 'mz_north_atlantic_iceland', 'mz_north_sea_eastern', 'mz_norwegian_sea', 'mz_skagerrak_kattegat']
    ['mz_caspian_sea']
#### 1b. FAÇADES CÔTIÈRES SANS ZONE MARITIME
   region_001 Angleterre du Sud                  plus proches=[('mz_north_sea_eastern', 236.7), ('mz_skagerrak_kattegat', 504.0)]
   region_002 Angleterre du Nord                 plus proches=[('mz_north_sea_eastern', 214.1), ('mz_skagerrak_kattegat', 567.8)]
   region_003 Écosse                             plus proches=[('mz_norwegian_sea', 36.4), ('mz_north_sea_eastern', 205.6)]
   region_004 Pays de Galles                     plus proches=[('mz_north_sea_eastern', 429.7), ('mz_skagerrak_kattegat', 776.6)]
   region_005 Ulster géographique                plus proches=[('mz_north_atlantic_iceland', 537.1), ('mz_north_sea_eastern', 545.4)]
   region_006 Irlande hors Ulster                plus proches=[('mz_north_sea_eastern', 597.7), ('mz_north_atlantic_iceland', 623.8)]
   region_007 France — Nord                      plus proches=[('mz_north_sea_eastern', 413.9), ('mz_skagerrak_kattegat', 557.9)]
   region_008 France — Bassin parisien           plus proches=[('mz_north_sea_eastern', 535.6), ('mz_skagerrak_kattegat', 698.2)]
   region_009 France — Ouest                     plus proches=[('mz_north_sea_eastern', 624.8), ('mz_skagerrak_kattegat', 804.8)]
   region_010 France — Sud-Ouest                 plus proches=[('mz_north_sea_eastern', 933.1), ('mz_skagerrak_kattegat', 1009.8)]
   region_012 France — Sud-Est                   plus proches=[('mz_adriatic_south_otranto', 655.8), ('mz_ionian_sea', 796.7)]
   region_013 Flandre (Bruxelles incluse)        plus proches=[('mz_north_sea_eastern', 369.3), ('mz_skagerrak_kattegat', 415.5)]
   region_015 Pays-Bas — Ouest                   plus proches=[('mz_north_sea_eastern', 181.6), ('mz_skagerrak_kattegat', 290.8)]
   region_016 Pays-Bas — Est et Nord             plus proches=[('mz_north_sea_eastern', 145.6), ('mz_skagerrak_kattegat', 168.5)]
   region_020 Portugal                           plus proches=[('mz_north_sea_eastern', 1589.4), ('mz_skagerrak_kattegat', 1786.8)]
   region_021 Espagne — Nord-Ouest               plus proches=[('mz_north_sea_eastern', 1342.6), ('mz_skagerrak_kattegat', 1506.8)]
   region_022 Espagne — Nord-Est                 plus proches=[('mz_adriatic_south_otranto', 1169.2), ('mz_ionian_sea', 1309.0)]
   region_024 Espagne — Méditerranée             plus proches=[('mz_adriatic_south_otranto', 1127.8), ('mz_ionian_sea', 1217.4)]
   region_025 Espagne — Sud                      plus proches=[('mz_adriatic_south_otranto', 1700.4), ('mz_ionian_sea', 1785.5)]
   region_037 Alpes autrichiennes                plus proches=[('mz_adriatic_south_otranto', 311.9), ('mz_ionian_sea', 606.3)]
   region_080 Italie — Nord-Ouest                plus proches=[('mz_adriatic_south_otranto', 552.3), ('mz_ionian_sea', 811.3)]
   region_081 Italie — Nord-Est                  plus proches=[('mz_adriatic_south_otranto', 410.9), ('mz_ionian_sea', 655.7)]
   region_082 Italie — Centre-Ouest              plus proches=[('mz_adriatic_south_otranto', 332.2), ('mz_ionian_sea', 460.5)]
   region_083 Italie — Centre-Est                plus proches=[('mz_adriatic_south_otranto', 194.2), ('mz_ionian_sea', 349.9)]
   region_085 Sicile                             plus proches=[('mz_adriatic_south_otranto', 225.5), ('mz_ionian_sea', 249.9)]
   region_086 Sardaigne                          plus proches=[('mz_adriatic_south_otranto', 652.4), ('mz_ionian_sea', 746.0)]
#### 2. mz_norwegian_sea
WGS 84 : Valid Geometry | EPSG:3035 : Self-intersection[4032158.03968714 4223780.88751447]
aire buffer(0) km² : 1235732.4
segmentize 1.0° : valide=True aire km²=1208766.1
segmentize 0.25° : valide=True aire km²=1208808.7
#### 3. RÉGIONS ISOLÉES
   terre : region_051 - Islande : île sans frontière terrestre ; aucun détroit inter-régional documenté ne la relie à une autre région.
   terre : region_085 - Sicile : île sans frontière terrestre ; reliée à region_084 par le détroit de Messine.
   terre : region_086 - Sardaigne : île sans frontière terrestre ; reliée à region_012 par les Bouches de Bonifacio.
   graphe jouable : ['region_051']
   051 liens maritimes : [('mz_north_atlantic_iceland', 'geometry', 0.0), ('mz_norwegian_sea', 'catalogue_only', 170.22)]
   051 régions les plus proches : [('region_003', 780.6), ('region_046', 969.6), ('region_005', 1071.0)]
#### 4. CANAL DE CORFOU 076/077
   distance min km : 2.31 | points : [(19.9875, 39.7462), (19.9617, 39.7521)]
   region_076 zones : ['mz_adriatic_south_otranto', 'mz_ionian_sea']
   region_077 zones : ['mz_adriatic_south_otranto', 'mz_aegean_sea', 'mz_ionian_sea']
#### 5. PROXIMITÉS
   region_001-region_009 15.23 km island_sea_gap
   region_013-region_032 4.72 km third_region_interposition
   region_014-region_035 8.82 km third_region_interposition
   region_018-region_034 1.11 km lake_gap
   region_018-region_035 9.61 km river_gap
   region_043-region_076 15.36 km third_region_interposition
   region_046-region_049 6.0 km lake_gap
   region_076-region_077 2.31 km sea_gap_undocumented
#### 6. VILLES
   total : 175 | capitales : 22
   doublons id : []
   doublons name_fr : []
   hors région : []
   rattachements modifiés : []
   à moins de 5 km d'une frontière ou côte : 76
   noms composites : ['Christiania (Oslo)', 'Saint-Pétersbourg (Kronstadt)', 'Bucarest (Ploiești)', 'Sofia (Vidin)', 'Cetinje (Antivari/Bar)', 'Durrës (Scutari / Vlora)', 'Athènes (Le Pirée)', 'Constantinople (Istanbul)']
#### 7. ATTRIBUTS DES RÉGIONS
   champs vides : {'notes': 28, 'adjacent_region_ids': 4, 'external_adjacent_region_ids': 30, 'maritime_zone_ids': 10}
   adjacent_region_ids (GeoJSON) ≠ adjacency.json : 20 ['region_026', 'region_027', 'region_029', 'region_030', 'region_033', 'region_037', 'region_040', 'region_041', 'region_042', 'region_043', 'region_044', 'region_054', 'region_055', 'region_056', 'region_058', 'region_062', 'region_070', 'region_071', 'region_074', 'region_075']
   regions.json ≠ GeoJSON : []
   area_km2 inexacte (> 1 km²) : []
   source_refs : {'regis_2026_v1': 69, 'kavanagh_1914_v1': 90, 'ristat_1897_v1': 18, 'geoboundaries_tur_v6': 4}
```
