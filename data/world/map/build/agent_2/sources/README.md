# Sources Géographiques et Historiques — Lot Cartographique Agent 2 (40 régions)

Ce document recense l'ensemble des sources géographiques, administratives, physiques et d'infrastructures effectivement vérifiées et utilisées pour construire les **40 régions** du périmètre de l'**Agent 2** au **1er janvier 1914** (`Scandinavie` 8, `Europe orientale` 18, `Balkans` 10, `Territoires ottomans européens` 4).

Pour chaque source sont précisés :
- **son origine** (auteurs, institution, identifiant/DOI) ;
- **sa date ou période historique couverte** ;
- **sa licence juridique** ;
- **son utilisation exacte dans le lot de l'Agent 2** ;
- **ses limites historiques et géographiques**.

---

## 1. `regis_2026_v1` — REGIS Historical GIS of Europe (1870–2020)

- **Origine** : Schweikart, J., Pieper, J., Sinning, M. et al. (2026), *Regional Enumeration of Geospatial Information for Societies (REGIS) — Data Tracking of Centuries (DATA-TOC)*, Springer / Figshare. DOI : `10.1007/978-3-032-14932-9_3`. Système de coordonnées natif : `EPSG:3035` (ETRS89 / LAEA Europe), reprojeté en `EPSG:4326` (WGS 84).
- **Date ou période** : Découpages administratifs historiques par tranches chronologiques couvrant la date de référence du **1er janvier 1914** :
  - `REGIS_Denmark.gpkg` (`REGIS_Denmark_L1_1870-1919`, 18 *Amter*) ;
  - `REGIS_Norway.gpkg` (`REGIS_Norway_L1_1880-1919`, 18 *Amter*) ;
  - `REGIS_Sweden.gpkg` (`REGIS_Sweden_L1_1870-1967`, 24 *Län*) ;
  - `REGIS_Iceland.gpkg` (`REGIS_Iceland_L0_1870-1918`, *Danish Iceland*) ;
  - `REGIS_Finland.gpkg` (`REGIS_Finland_L1_1870-1918`, 8 *Lääni* du Grand-Duché de Finlande) ;
  - `REGIS_Romania.gpkg` (`REGIS_Romania_L1_1879-1913` et `L2_1879-1913`, 4 provinces historiques et 32 *județe*) ;
  - `REGIS_Bulgaria.gpkg` (`REGIS_Bulgaria_L0_1886-1912`, `L0_1923-1940` et `L2_1923-1925`, 16 *okrugs*) ;
  - `REGIS_Serbia.gpkg` (`REGIS_Serbia_L1_1900-1901`) & `REGIS_Yugoslavia.gpkg` (`REGIS_Yugoslavia_L1_1920-1923` et `L2_1948-1954`) ;
  - `REGIS_Montenegro.gpkg` (`REGIS_Montenegro_L0_1879-1913` et `L0_2007-2020`) ;
  - `REGIS_Albania.gpkg` (`REGIS_Albania_L0_1921-1926` et `L1_1921-1926`, 10 préfectures) ;
  - `REGIS_Greece.gpkg` (`REGIS_Greece_L0_1914-1919`, `L0_1928-1940` et `L3_1914-1919`, 35 nomes/départements).
- **Licence** : **CC BY 4.0** (Creative Commons Attribution 4.0 International).
- **Utilisation** :
  - Construction directe des **8 régions de Scandinavie** (`region_044` à `region_051`) et de la **Finlande** (`region_052`).
  - Construction des **10 régions des Balkans** (`region_070` à `region_079`) en restituant les frontières exactes issues des traités de Londres (mai 1913) et de Bucarest (10 août 1913) :
    - rattachement du Quadrilatère de Dobroudja méridionale (`REGIS_Bulgaria_L0_1886-1912 \ L0_1923-1940`) à la Roumanie méridionale (`region_070`) ;
    - rattachement de la Macédoine du Pirin (`Pétritch`) et des confins occidentaux de Tsaribrod/Bosilegrad à la Bulgarie occidentale (`region_072`) ;
    - rattachement de la Thrace occidentale égéenne (`REGIS_Greece_L0_1928-1940 \ L0_1914-1919` : Gümülcine/Komotini, Xanthi, Dedeağaç/Alexandroupoli) à la Bulgarie orientale (`region_073`) ;
    - découpage de la Grèce de 1914 (`REGIS_Greece_L3_1914-1919`) en Grèce centrale (`region_077`), Grèce septentrionale (`region_078`, incluant Épire, Thessalie, Macédoine grecque avec Salonique et Kavala, Mont Athos) et Grèce méridionale et îles (`region_079`, incluant Péloponnèse, Cyclades, Crète et îles du Nord-Est de l'Égée, sans le Dodécanèse).
- **Limites historiques et géographiques** :
  - Pour la Serbie (`region_074`) et le Monténégro (`region_075`), REGIS ne fournit pas de couche spécifique isolant la brève période d'août 1913 à novembre 1918 pour le partage interne du Sandjak de Novi Pazar et de la Métochie (Peć/Đakovica). L'union des unités de `REGIS_Yugoslavia` (hors territoires austro-hongrois `region_041` et `region_043`) permet de restituer fidèlement la frontière internationale de 1914 (excluant notamment les Bouches de Cattaro autrichiennes), tandis que la limite interne serbo-monténégrine suit la limite administrative monténégrine de REGIS (incluant Pljevlja, Bijelo Polje, Berane, Plav et Gusinje au Monténégro, et rattachant le bloc Kosovo-Métochie à `region_074`).

---

## 2. `ristat_1897_v1` — RISTAT Historical GIS of the Russian Empire (1897)

- **Origine** : Kessler, Gijs & Markevich, Andrei (International Institute of Social History — IISH / New Economic School), *Administrative boundaries of the Russian Empire, 1897*, DataverseNL. DOI : `10.34894/NQOASN`. Fichiers vérifiés : `ristat_1897_provinces.gpkg` (103 gouvernements/oblasts) et `ristat_1897_districts.gpkg` (824 ouïezds/okrougs), CRS natif `EPSG:4326`.
- **Date ou période** : Recensement impérial de 1897 (les limites des gouvernements et ouïezds d'Europe orientale sont demeurées inchangées jusqu'au 1er janvier 1914, à la seule exception de la création du gouvernement de Kholm en 1912).
- **Licence** : **CC0 1.0 Universal** (Domaine public).
- **Utilisation** :
  - Construction des **17 régions de l'Empire russe hors Finlande** (`region_053` à `region_069`).
  - Agrégation au niveau des gouvernements (*gubernii*) pour `region_053` (Estonie, Livonie), `region_054` (Courlande, Kovno), `region_055` (Varsovie, Kalisz, Piotrków, Radom, Kielce, Płock), `region_056` (Lublin, Siedlce/Kholm, Łomża, Suwałki), `region_057` (Minsk, Grodno, Vilna, Vitebsk, Moguilev), `region_058` (Volhynie, Podolie), `region_062` (Bessarabie), `region_064` (Saint-Pétersbourg, Pskov, Novgorod, Olonets), `region_065` (Arkhangelsk, Vologda), `region_066` (14 gouvernements centraux), `region_067` (Kazan, Simbirsk, Penza, Viatka, Oufa, Perm) et `region_068` (Saratov, Samara, Astrakhan, Orenbourg).
  - Découpage infra-provincial exact au niveau des **ouïezds et okrougs** (`ristat_1897_districts.gpkg`) conformément à `region_plan.csv` pour :
    - `region_059` (Ukraine centrale : Kiev, Poltava, Tchernigov + Kharkov sans l'ouïezd de Starobelsk `Distr_ID=487`) ;
    - `region_060` (Ukraine méridionale : Kherson + 5 ouïezds occidentaux d'Ekaterinoslav `498, 499, 500, 501, 502` + 3 ouïezds continentaux du Nord de Tauride : Mélitopol `489`, Berdiansk `490`, Dnieprovsk `841`) ;
    - `region_061` (Donbass : ouïezds de Bakhmout `504`, Slavianoserbsk `505` et Marioupol `503` d'Ekaterinoslav + ouïezd de Starobelsk `487` de Kharkov + okrougs de Taganrog `546` et du Donets `545` de la Terre des Cosaques du Don) ;
    - `region_063` (Crimée : 5 ouïezds péninsulaires de Tauride `491, 492, 494, 495, 496` + municipalités de Sébastopol `493` et Kertch-Iénikalé `497`) ;
    - `region_069` (Russie méridionale : Kouban, Mer Noire, Stavropol, Terek, Daghestan + 7 okrougs restants des Cosaques du Don `542, 543, 544, 547, 549, 551, 552`).
- **Limites historiques et géographiques** :
  - En 1912, le gouvernement de Kholm (Chełm) a été détaché des parties orientales des gouvernements de Siedlce et de Lublin, tandis que le reste du gouvernement de Siedlce était réparti entre Lublin et Łomża. Comme `region_056` (Pologne russe orientale) regroupe simultanément Lublin, Siedlce/Kholm et Łomża, l'enveloppe extérieure de `region_056` est strictement invariante par rapport à cette réorganisation interne de 1912.
  - Les gouvernements de Perm (`region_067`) et d'Orenbourg (`region_068`) s'étendent historiquement sur le versant oriental immédiat de l'Oural ; leurs limites administratives historiques complètes ont été conservées conformément à `region_plan.csv`.
  - Le tracé côtier et frontalier de RISTAT (numérisé à une échelle distincte de REGIS) a été aligné topologiquement sur la frontière orientale de l'Agent 1 (`region_026`, `027`, `030`, `040`), sur la Finlande (`region_052`) et sur la Roumanie (`region_070`, `071`) afin de garantir zéro chevauchement et zéro interstice entre les lots.

---

## 3. `geoboundaries_tur_v6` — geoBoundaries Turkey ADM1 & ADM2 (Thrace orientale)

- **Origine** : Runfola, D. et al. (2020), *geoBoundaries: A global database of political administrative boundaries*, William & Mary geoLab (`gb_tur_adm1.geojson`, `gb_tur_adm2.geojson`). CRS : `EPSG:4326`.
- **Date ou période** : Limites contemporaines des provinces (*iller*) et districts (*ilçeler*) de la Turquie d'Europe, correspondant aux subdivisions historiques des sandjaks ottomans de Constantinople, Çatalca, Tekirdağ (Rodosto), Kırklareli (Kirk-Kilissé), Edirne (Andrinople) et Gelibolu (Gallipoli) à l'issue du traité de Constantinople (29 septembre 1913).
- **Licence** : **CC BY 4.0**.
- **Utilisation** :
  - Construction des **4 régions des Territoires ottomans européens** (`region_087` à `region_090`) :
    - `region_087` (Constantinople et environs) : 20 districts européens de la province d'Istanbul à l'est des lignes de Çatalca et de la lagune de Büyükçekmece ;
    - `region_088` (Çatalca et Tekirdağ) : districts occidentaux d'Istanbul (`Çatalca`, `Silivri`, `Büyükçekmece`, `Beylikdüzü`, `Esenyurt`) + districts de la province de Tekirdağ hors `Şarköy` ;
    - `region_089` (Edirne) : province de Kırklareli (8 districts) + districts septentrionaux et centraux de la province d'Edirne (`Edirne merkez`, `Uzunköprü`, `Havsa`, `Meriç`, `İpsala`, `Lalapaşa`, `Süloğlu`) ;
    - `region_090` (Gallipoli et rive européenne des Dardanelles) : districts européens des Dardanelles (`Gelibolu`, `Eceabat`), îles d'Imbros (`Gökçeada`) et Ténédos (`Bozcaada`), ainsi que l'arrière-pays historique du sandjak de Gelibolu sur le golfe de Saros et la Marmara occidentale (`Şarköy`, `Keşan`, `Enez`).
- **Limites historiques et géographiques** :
  - Entre le traité de Constantinople (29 septembre 1913) et la convention bulgaro-ottomane de Sofia (septembre 1915), l'Empire ottoman contrôlait sur la rive droite de la basse Maritsa le faubourg ferroviaire de Karaağaç et une étroite bande autour de Dimetoka (Didymoteicho), cédée à la Bulgarie en 1915. La frontière occidentale de `region_089` et `region_090` suit le cours de la basse Maritsa issu de `gb_tur_adm2` / `REGIS`, approximation documentée dans `regions.json` et `HANDOFF.md`.

---

## 4. `kavanagh_1914_v1` — Frontières européennes de 1914 (CShapes 2.0 / Kavanagh)

- **Origine** : Kavanagh, Aoife (2023), *Europe 1914 GeoJSON* (`gs1914-europe-1914-low-res.geojson`), dérivé de *CShapes 2.0* (Schvitz et al., 2022, ETH Zürich).
- **Date ou période** : État des frontières internationales européennes en 1914.
- **Licence** : **CC BY 4.0**.
- **Utilisation** : Vérification croisée des frontières internationales de 1914 dans les Balkans (`Romania`, `Bulgaria`, `Serbia`, `Montenegro`, `Albania`, `Greece`, `Ottoman Empire`).
- **Limites historiques et géographiques** : Résolution côtière plus généralisée que REGIS ; utilisée comme référence de contrôle frontalier et non en remplacement des tracés côtiers haute précision de REGIS.

---

## 5. `natural_earth_10m_v5` & `baedeker_bradshaw_1914` — Géographie physique, voies ferrées et places fortes

- **Origine** :
  - *Natural Earth 1:10m Physical Vectors* v5.1.2 (fleuves, lacs, façades maritimes, reliefs).
  - *Bradshaw's April 1914 Continental Guide* (Londres, 1914) ; *Baedeker's Russia with Teheran, Port Arthur, and Peking* (Leipzig, 1914) ; *Baedeker's Konstantinopel, Balkanstaaten, Kleinasien* (Leipzig, 1914) ; atlas militaires historiques de 1914.
- **Date ou période** : État des réseaux ferroviaires, ports et systèmes fortifiés au **1er janvier 1914**.
- **Licence** : **Domaine public / CC0 1.0**.
- **Utilisation** :
  - Délimitation des **16 zones maritimes** (`maritime_zones.json`) après soustraction géométrique exacte des terres émergées (`agent_1` + `agent_2`).
  - Catalogue des **32 grands fleuves** et **11 chaînes de montagnes** (`terrain.json`).
  - Sélection et géolocalisation des **72 villes stratégiques** (`cities.json`), des **53 grands axes ferroviaires**, des **37 grands ports** et des **33 places fortes de 1914** (`infrastructure.json`).
- **Limites historiques et géographiques** :
  - Conformément au schéma établi par l'Agent 1 (`infrastructure.json`), les grands axes ferroviaires sont représentés sous forme d'arcs topologiques (`LineString`) reliant les noeuds stratégiques (`from_site_id` -> `to_site_id`) effectivement en service au 1er janvier 1914 (avec mention explicite de la jonction thessalienne Papapouli — Platy achevée entre 1914 et 1916 sur l'axe Athènes — Larissa — Salonique).
