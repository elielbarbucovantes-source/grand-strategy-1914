# Sources cartographiques, méthodologie et approximations — Agent 1 (Europe occidentale, centrale, méridionale et insulaire, 1er janvier 1914)

Ce document recense l'ensemble des sources vectorielles historiques, des références d'infrastructures, des règles d'agrégation et des approximations cartographiques utilisées pour construire le lot **Agent 1** (**50 régions**) de l'atlas **Grand Strategy-1914** au **1er janvier 1914**.

---

## 1. Périmètre couvert par l'Agent 1 (50 régions)

Conformément au plan de découpage de référence (`data/world/map/tables/region_plan.csv`), le périmètre de l'Agent 1 couvre exactement **50 régions** réparties en 5 zones :

| Zone | Identifiants | Nombre de régions | Souverainetés au 1er janvier 1914 |
|---|---|---:|---|
| **Îles Britanniques** | `region_001` à `region_006` | 6 | Royaume-Uni (6) |
| **Europe occidentale** | `region_007` à `region_019` | 13 | France (6), Belgique (2), Pays-Bas (2), Suisse (2), Luxembourg (1) |
| **Péninsule ibérique** | `region_020` à `region_025` | 6 | Portugal (1), Espagne (5) |
| **Europe centrale** | `region_026` à `region_043` | 18 | Empire allemand (10), Autriche-Hongrie (8) |
| **Italie** | `region_080` à `region_086` | 7 | Italie (7) |
| **Total Agent 1** | — | **50** | **11 États souverains** |

> **Note d'isolation** : Aucune des 40 régions attribuées à l'Agent 2 (`region_044` à `region_079`, `region_087` à `region_090`) ni aucun fichier partagé hors de `data/world/map/build/agent_1/` n'a été modifié.

---

## 2. Sources vectorielles historiques retenues (polygones 1914)

### 2.1. Source primaire : REGIS (*Regional Historical GIS of Europe*)
- **Référence bibliographique** : Schweikart, J., Piepho, M., & Riedel, H. (2025/2026). *REGIS – Regional Historical GIS of Europe (1870–2020)*. DOI : `10.1007/978-3-032-14932-9_3`.
- **Licence** : **CC BY 4.0** (compatible et approuvée par `docs/map/TECHNICAL_SPEC.md` §10).
- **Projection native** : `EPSG:3035` (ETRS89-extended / LAEA Europe), reprojetée vers `EPSG:4326` (WGS84, conforme RFC 7946) après union topologique en coordonnées métriques.
- **Couches historiques exactes (millésime couvrant le 1er janvier 1914) utilisées par pays** :
  1. **Royaume-Uni (`REGIS_UK.gpkg`)** :
     - Angleterre : `REGIS_UK_England_L2_1911-1921` (50 comtés historiques et administratifs du recensement de 1911).
     - Pays de Galles : `REGIS_UK_Wales_L1_1871-1921` (12 comtés historiques gallois — Anglesey, Brecknockshire, Caernarfonshire, Cardiganshire, Carmarthenshire, Denbighshire, Flintshire, Glamorganshire, Merionethshire, Montgomeryshire, Pembrokeshire, Radnorshire). *Note : le Monmouthshire est rattaché à la couche anglaise dans les recensements britanniques de 1911 (`region_001`).*
     - Écosse : `REGIS_UK_Scotland_L1_1871-2020` (33 comtés historiques écossais pour `region_003`).
     - Irlande : `REGIS_UK_Ireland_L2_1871-1921` (4 provinces historiques antérieures à la partition de 1921 : `Ulster` complet à 9 comtés pour `region_005`, et `Leinster` + `Munster` + `Connaught` à 23 comtés pour `region_006`).
  2. **France (`REGIS_France.gpkg`)** :
     - `REGIS_France_L2_1871-1913` : 87 départements de la IIIe République dans les frontières du traité de Francfort (10 mai 1871) en vigueur le 1er janvier 1914 (incluant le Territoire de Belfort dans `region_011` et la Corse dans `region_012` ; excluant l'Alsace-Lorraine).
  3. **Belgique (`REGIS_Belgium.gpkg`)** :
     - `REGIS_Belgium_L2_1870-1919` : 9 provinces historiques antérieures au traité de Versailles (sans les cantons d'Eupen-Malmedy, alors prussiens) + découpage de la province de Brabant selon la limite de l'arrondissement de Nivelles (`REGIS_Belgium_L3_2020` / Brabant wallon) afin d'intégrer Bruxelles et Louvain à la Flandre (`region_013`) et Nivelles à la Wallonie (`region_014`).
  4. **Pays-Bas (`REGIS_Netherlands.gpkg`)** :
     - `REGIS_Netherlands_L1_1870-1932` : 11 provinces historiques antérieures aux polders du Zuiderzee / Flevoland.
  5. **Suisse (`REGIS_Switzerland.gpkg`)** :
     - `REGIS_Switzerland_L1_1870-1978` : 25 cantons historiques (le Jura bernois étant intégré au canton de Berne en 1914).
  6. **Luxembourg (`REGIS_Luxembourg.gpkg`)** :
     - `REGIS_Luxembourg_L0_1870-2020` : Grand-Duché de Luxembourg dans ses frontières de 1839/1914.
  7. **Portugal (`REGIS_Portugal.gpkg`)** :
     - `REGIS_Portugal_L0_1870-2020` : 17 districts continentaux de la Première République portugaise.
  8. **Espagne (`REGIS_Spain.gpkg`)** :
     - `REGIS_Spain_L2_1870-1979` : 48 provinces continentales et baléares issues de la division de Javier de Burgos (1833) en vigueur en 1914.
  9. **Empire allemand (`REGIS_Germany.gpkg`)** :
     - `REGIS_Germany_L3_1905-1918` : 78 *Regierungsbezirke*, principautés, duchés, villes hanséatiques et *Reichsland Elsaß-Lothringen* dans leurs frontières impériales de 1905–1918 (incluant le Schleswig du Nord, Eupen-Malmedy, l'Alsace-Lorraine, la Posnanie, la Prusse-Occidentale avec Dantzig et la Prusse-Orientale).
  10. **Autriche-Hongrie (`REGIS_Austria_Hungary.gpkg`)** :
      - `REGIS_Austria_Hungary_L3_1908-1914` : 91 unités administratives de la Double Monarchie après l'annexion de la Bosnie-Herzégovine (1908) et jusqu'en 1914 : *Kronländer* cisleithaniens, comitats (*vármegyék*) transleithaniens du Royaume de Hongrie et de Croatie-Slavonie, *Corpus separatum* de Fiume, et condominium de Bosnie-Herzégovine.
  11. **Italie (`REGIS_Italia.gpkg`)** :
      - `REGIS_Italia_L1_1872-1915` : 16 *compartimenti* historiques du Royaume d'Italie entre la prise de Rome (1870/1872) et l'entrée en guerre de 1915 (excluant strictement le Trentin, le Tyrol du Sud, Gorizia-Gradisca, Trieste et l'Istrie).

### 2.2. Sources de contrôle et de validation des frontières internationales (1914)
- **Kavanagh / University College Dublin (2014)** : *Map of Europe, c. 1914* (DOI : `10.5281/zenodo.21341486`, licence **CC BY 4.0**). Utilisé pour vérifier la conformité des frontières internationales au 1er janvier 1914 (frontière franco-allemande des Vosges, frontière austro-italienne des Alpes carniques et du Trentin, frontière germano-belge d'Eupen-Malmedy, frontière germano-danoise du Jutland).
- **Couche européenne de référence REGIS** : `REGIS_Europe_L0_1910` (`/tmp/gs1914-regis-l0.gpkg`).

### 2.3. Sources historiques pour le réseau ferré, les villes et les fortifications (1914)
- **Esteban-Oliver, G., & Martí-Henneberg, J. (2023)** : *The Historical European Railway Map (1830–1910/1914)*, COREDEM / Dataverse (DOI : `10.34810/data917`, licence **CC BY 4.0**).
- **Ciccarelli, C., & Groote, P. (2017)** : *Railway Endowment in Italy's Provinces, 1839–1913*, Mendeley Data (DOI : `10.17632/rjwccjgy7z.1`, licence **CC BY 4.0**).
- **Bradshaw (1913)** : *Bradshaw's April 1913 Continental Railway, Steam Transit, and General Guide for Travellers Through Europe*.
- **Baedeker (1911–1914)** : *Austria-Hungary, Including Dalmatia and Bosnia (1911)* ; *Northern Germany (1913)* ; *Southern Germany (1914)* ; *Northern France (1909)* ; *Belgium and Holland (1910)* ; *Northern Italy (1913)*.
- **États-majors et fortifications en 1914** : système Séré de Rivières (Verdun, Toul, Épinal, Belfort, Maubeuge), réduit national belge (Liège, Namur, Anvers), *Festung* allemandes (Metz-Thionville, Strasbourg-Mutzig, Cologne, Coblence, Mayence, Germersheim, Ulm, Ingolstadt, Königsberg, Thorn, Posen, Breslau, Glogau, Küstrin, Wilhelmshaven, Kiel, Heligoland), fortifications austro-hongroises (Trente, Pola, Cracovie, Przemyśl, Komárom, Peterwardein, Cattaro, Sarajevo).

### 2.4. Exclusion documentée (conformité licence)
- **RShapes / CShapes 2.0 (ETH Zürich)** : **Non utilisé** conformément à la directive `docs/map/TECHNICAL_SPEC.md` §10, sa licence *CC BY-NC-SA 4.0* comportant une clause non-commerciale incompatible avec les exigences du projet.

---

## 3. Inventaire détaillé des 50 régions construites

| ID | Zone | Nom (`nom_fr`) | Souveraineté (1914) | Superficie (km²) | Villes stratégiques rattachées | Couche REGIS source |
|---|---|---|---|---:|---|---|
| `region_001` | Îles Britanniques | Angleterre du Sud | Royaume-Uni | 74,429.55 | Londres, Portsmouth, Birmingham, Plymouth | `REGIS_UK.gpkg:REGIS_UK_England_L2_1911-1921 + Channel Islands L0` |
| `region_002` | Îles Britanniques | Angleterre du Nord | Royaume-Uni | 58,885.55 | Manchester, Liverpool, Sheffield, Newcastle upon Tyne | `REGIS_UK.gpkg:REGIS_UK_England_L2_1911-1921 + REGIS_Isle_of_Man_L0_1870-2020` |
| `region_003` | Îles Britanniques | Écosse | Royaume-Uni | 78,465.13 | Glasgow, Édimbourg (Rosyth) | `REGIS_UK.gpkg:REGIS_UK_Scotland_L1_1871-2020 (33 comtés L2 1901-1975)` |
| `region_004` | Îles Britanniques | Pays de Galles | Royaume-Uni | 19,154.43 | Cardiff | `REGIS_UK.gpkg:REGIS_UK_Wales_L1_1871-1921 (12 comtés historiques L2 1889-1921)` |
| `region_005` | Îles Britanniques | Ulster géographique | Royaume-Uni | 22,384.11 | Belfast | `REGIS_UK.gpkg:REGIS_UK_Ireland_L2_1871-1921 (Ulster, 9 comtés L3 1901-1921)` |
| `region_006` | Îles Britanniques | Irlande hors Ulster | Royaume-Uni | 61,534.69 | Dublin, Cork (Queenstown) | `REGIS_UK.gpkg:REGIS_UK_Ireland_L2_1871-1921 (Leinster, Munster, Connaught — 23 comtés)` |
| `region_007` | Europe occidentale | France — Nord | France | 31,867.03 | Lille, Calais, Amiens | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_008` | Europe occidentale | France — Bassin parisien | France | 63,754.40 | Paris, Le Havre, Bourges | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_009` | Europe occidentale | France — Ouest | France | 103,614.44 | Nantes (Saint-Nazaire), Brest, Cherbourg | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_010` | Europe occidentale | France — Sud-Ouest | France | 104,343.61 | Bordeaux, Toulouse | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_011` | Europe occidentale | France — Est | France | 91,922.12 | Verdun, Nancy (Toul), Belfort, Le Creusot | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_012` | Europe occidentale | France — Sud-Est | France | 138,700.19 | Lyon (Saint-Étienne), Marseille, Toulon | `REGIS_France.gpkg:REGIS_France_L2_1871-1913` |
| `region_013` | Europe occidentale | Flandre (Bruxelles incluse) | Belgique | 13,736.14 | Bruxelles, Anvers | `REGIS_Belgium.gpkg:REGIS_Belgium_L2_1870-1919 (découpe Brabant nord/Bruxelles)` |
| `region_014` | Europe occidentale | Wallonie | Belgique | 15,857.22 | Liège, Namur (Charleroi) | `REGIS_Belgium.gpkg:REGIS_Belgium_L2_1870-1919 (frontière 1914 sans Eupen-Malmedy)` |
| `region_015` | Europe occidentale | Pays-Bas — Ouest | Pays-Bas | 9,134.37 | Amsterdam, Rotterdam | `REGIS_Netherlands.gpkg:REGIS_Netherlands_L1_1870-1932` |
| `region_016` | Europe occidentale | Pays-Bas — Est et Nord | Pays-Bas | 24,328.19 | Arnhem (Nimègue) | `REGIS_Netherlands.gpkg:REGIS_Netherlands_L1_1870-1932` |
| `region_017` | Europe occidentale | Suisse — Ouest | Suisse | 19,361.78 | Berne, Bâle | `REGIS_Switzerland.gpkg:REGIS_Switzerland_L1_1870-1978` |
| `region_018` | Europe occidentale | Suisse — Est | Suisse | 22,189.18 | Zurich | `REGIS_Switzerland.gpkg:REGIS_Switzerland_L1_1870-1978 + Liechtenstein L0` |
| `region_019` | Europe occidentale | Luxembourg | Luxembourg | 2,608.86 | Luxembourg | `REGIS_Luxembourg.gpkg:REGIS_Luxembourg_L0_1870-2020` |
| `region_020` | Péninsule ibérique | Portugal | Portugal | 88,923.32 | Lisbonne, Porto | `REGIS_Portugal.gpkg:REGIS_Portugal_L0_1870-2020 (17 districts continentaux L1 1870-1925)` |
| `region_021` | Péninsule ibérique | Espagne — Nord-Ouest | Espagne | 115,301.65 | La Corogne (Ferrol), Oviedo (Gijón) | `REGIS_Spain.gpkg:REGIS_Spain_L2_1870-1979` |
| `region_022` | Péninsule ibérique | Espagne — Nord-Est | Espagne | 104,830.52 | Barcelone, Bilbao, Saragosse | `REGIS_Spain.gpkg:REGIS_Spain_L2_1870-1979` |
| `region_023` | Péninsule ibérique | Espagne — Centre | Espagne | 139,796.94 | Madrid | `REGIS_Spain.gpkg:REGIS_Spain_L2_1870-1979` |
| `region_024` | Péninsule ibérique | Espagne — Méditerranée | Espagne | 54,956.40 | Valence, Carthagène | `REGIS_Spain.gpkg:REGIS_Spain_L2_1870-1979` |
| `region_025` | Péninsule ibérique | Espagne — Sud | Espagne | 85,391.24 | Séville, Cadix | `REGIS_Spain.gpkg:REGIS_Spain_L2_1870-1979` |
| `region_026` | Europe centrale | Prusse-Orientale | Empire allemand | 37,373.78 | Königsberg | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_027` | Europe centrale | Prusse-Occidentale et Posnanie | Empire allemand | 55,226.78 | Dantzig, Posen (Thorn) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_028` | Europe centrale | Poméranie, Mecklembourg et Brandebourg | Empire allemand | 86,502.95 | Berlin, Stettin | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_029` | Europe centrale | Allemagne du Nord-Ouest | Empire allemand | 68,597.49 | Hambourg, Kiel, Wilhelmshaven (Brême), Hanovre | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_030` | Europe centrale | Silésie | Empire allemand | 40,492.77 | Breslau, Kattowitz (Haute-Silésie) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_031` | Europe centrale | Saxe et Thuringe | Empire allemand | 55,486.90 | Leipzig (Halle), Dresde (Chemnitz) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_032` | Europe centrale | Rhénanie-Westphalie | Empire allemand | 49,706.72 | Essen (Bassin de la Ruhr), Cologne (Coblence) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_033` | Europe centrale | Allemagne du Sud-Ouest | Empire allemand | 65,504.52 | Francfort-sur-le-Main (Mayence), Stuttgart (Mannheim) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_034` | Europe centrale | Bavière | Empire allemand | 70,333.78 | Munich, Nuremberg (Ingolstadt) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_035` | Europe centrale | Alsace-Lorraine | Empire allemand | 14,459.14 | Strasbourg, Metz (Thionville) | `REGIS_Germany.gpkg:REGIS_Germany_L3_1905-1918` |
| `region_036` | Europe centrale | Autriche centrale | Autriche-Hongrie | 54,461.52 | Vienne, Graz (Linz) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_037` | Europe centrale | Alpes autrichiennes | Autriche-Hongrie | 64,587.70 | Trieste, Pola, Innsbruck (Trente) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_038` | Europe centrale | Bohême | Autriche-Hongrie | 52,073.14 | Prague (Pilsen) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_039` | Europe centrale | Moravie et Silésie autrichienne | Autriche-Hongrie | 27,115.66 | Brünn (Ostrava) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_040` | Europe centrale | Galicie et Bucovine | Autriche-Hongrie | 89,432.34 | Lemberg (Lwów), Przemyśl (Cracovie) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_041` | Europe centrale | Hongrie et Slovaquie | Autriche-Hongrie | 225,268.05 | Budapest, Presbourg (Pozsony) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_042` | Europe centrale | Transylvanie | Autriche-Hongrie | 56,832.63 | Kolozsvár (Kronstadt/Brașov) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_043` | Europe centrale | Croatie et territoires méridionaux | Autriche-Hongrie | 107,005.24 | Zagreb (Agram), Sarajevo, Fiume (Cattaro) | `REGIS_Austria_Hungary.gpkg:REGIS_Austria_Hungary_L3_1908-1914` |
| `region_080` | Italie | Italie — Nord-Ouest | Italie | 58,630.14 | Milan, Turin, Gênes | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_081` | Italie | Italie — Nord-Est | Italie | 45,737.07 | Venise (Vérone), Bologne | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_082` | Italie | Italie — Centre-Ouest | Italie | 45,649.45 | Rome, La Spezia (Livourne) | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_083` | Italie | Italie — Centre-Est | Italie | 26,799.16 | Ancône | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_084` | Italie | Italie — Sud | Italie | 60,679.29 | Naples, Tarente (Brindisi) | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_085` | Italie | Sicile | Italie | 25,909.94 | Palerme (Messine) | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |
| `region_086` | Italie | Sardaigne | Italie | 24,135.58 | Cagliari | `REGIS_Italia.gpkg:REGIS_Italia_L1_1872-1915` |

---

## 4. Points historiques essentiels vérifiés

1. **Pays de Galles distinct (`region_004`)** : Construit comme région autonome à partir de la couche `REGIS_UK_Wales_L1_1871-1921`, distincte de l'Angleterre du Sud (`region_001`), de l'Angleterre du Nord (`region_002`) et de l'Écosse (`region_003`).
2. **Irlande sans frontière politique moderne (`region_005` et `region_006`)** : L'Irlande est intégralement sous souveraineté du `Royaume-Uni` au 1er janvier 1914. La césure interne entre `region_005` (*Ulster géographique*) et `region_006` (*Irlande hors Ulster*) suit la limite de la province historique d'Ulster à **9 comtés** (incluant Donegal, Cavan et Monaghan), sans aucune frontière de partition de 1921.
3. **Alsace-Lorraine allemande (`region_035`)** : Le *Reichsland Elsaß-Lothringen* est attribué à l'`Empire allemand` (`region_035`). La région française frontalière `region_011` (*France — Est*) s'arrête sur la crête des Vosges et en Meurthe-et-Moselle (incluant le Territoire de Belfort).
4. **Terres irrédentes sous souveraineté austro-hongroise (`region_037`)** : Le Trentin, le Tyrol du Sud, Gorizia-Gradisca, Trieste et l'Istrie appartiennent intégralement à l'`Autriche-Hongrie` (`region_037` *Alpes autrichiennes*) et sont exclus des régions italiennes (`region_080` à `region_086`).
5. **Bruxelles intégrée à la Flandre (`region_013`)** : La province historique de Brabant (1914) a été scindée le long de la limite nord de l'arrondissement de Nivelles (Brabant wallon) afin que Bruxelles et Louvain soient intégrées à `region_013` (*Flandre (Bruxelles incluse)*) et Nivelles à `region_014` (*Wallonie*).
6. **Corse rattachée à une région française (`region_012`)** : Le département de la Corse (`REGIS_France_L2_1871-1913`) est intégré au MultiPolygon de `region_012` (*France — Sud-Est*).

---

## 5. Approximations cartographiques et traitements topologiques documentés

Conformément aux spécifications techniques (`docs/map/TECHNICAL_SPEC.md` §5.3 et §9), les simplifications et traitements suivants sont explicitement documentés :

1. **Micro-États absorbés à l'échelle stratégique (90 régions)** :
   - **Andorre** : intégrée à l'enveloppe pyrénéenne franco-espagnole (`region_022`).
   - **Monaco** : intégrée aux Alpes-Maritimes (`region_012`).
   - **Liechtenstein** : situé à l'interface entre le Vorarlberg (`region_037`) et le canton de Saint-Gall (`region_018`).
   - **Saint-Marin** : intégré à l'interface Émilie-Romagne / Marches (`region_081` / `region_083`).
   - **Territoire neutre de Moresnet** : absorbé à la frontière germano-belge entre `region_014` et `region_032`.
   - **Gibraltar** : rattaché cartographiquement à la continuité continentale andalouse (`region_025`), sa fonction navale restant documentée dans les notes stratégiques.
2. **Enclaves administratives internes de 1914** :
   - **Palatinat rhénan bavarois (*Rheinpfalz*) et Hohenzollern** : le Palatinat rhénan et Hohenzollern sont rattachés à `region_033` (*Allemagne du Sud-Ouest*) pour assurer la continuité territoriale de la rive gauche du Rhin supérieur et du Neckar, tandis que la Bavière proprement dite forme `region_034` (*Bavière*).
   - **Enclaves de Llívia (Espagne), Campione d'Italia (Italie), Büsingen (Allemagne) et Baarle-Hertog (Belgique)** : absorbées ou lissées à la résolution régionale.
3. **Chaîne de traitement topologique (zéro chevauchement)** :
   - Toutes les géométries sources REGIS (`EPSG:3035`) ont été fusionnées par région via `shapely.unary_union`, nettoyées des artefacts linéaires ou ponctuels (`buffer(0)` / `make_valid`), simplifiées avec préservation de topologie (tolérance de `150 m` pour les grands polygones continentaux et `50 m` pour les îles principales), filtrées des micro-îlots `< 5 km²`, puis reprojetées en `EPSG:4326`.
   - Une passe finale de soustraction topologique en `EPSG:4326` (avec `grid_size=0.0` après arrondi à 6 décimales et réorientation `shapely.orient_polygons` conforme RFC 7946) garantit **0 chevauchement** (`overlap > 1e-10 deg² = 0`) entre les 50 régions.
