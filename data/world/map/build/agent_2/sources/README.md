# Sources cartographiques, audit des licences et plan d'assemblage — Agent 2 (Scandinavie, Europe orientale, Balkans, Territoires ottomans européens — 1er janvier 1914)

**Statut :** Phase d'audit documentaire, d'extraction et de qualification des sources vectorielles historiques complétée ; génération des fichiers géométriques interrompue sur instruction directe (`HANDOFF`).

---

## 1. Périmètre des 40 régions attribuées à l'Agent 2

Conformément à `data/world/map/tables/region_plan.csv`, l'Agent 2 est responsable de **40 régions** réparties en 4 zones :

### 1.1. Scandinavie (8 régions : `region_044` à `region_051`)
| ID | Nom (`region_plan.csv`) | Souveraineté (1914) | Unités administratives historiques identifiées | Source primaire |
|---|---|---|---|---|
| `region_044` | Danemark | Danemark | 18 *Amter* danois de 1870–1919 (frontière de la Kongeå au sud du Jutland, sans le Schleswig du Nord) | `REGIS_Denmark.gpkg` (`REGIS_Denmark_L1_1870-1919`) |
| `region_045` | Norvège — Sud | Norvège | *Østlandet* et *Sørlandet* : Smaalenene, Akershus incl. Kristiania, Hedemarken, Kristians, Buskerud, Jarlsberg og Larvik, Bratsberg, Nedenæs, Lister og Mandal | `REGIS_Norway.gpkg` (`REGIS_Norway_L1_1880-1919`) |
| `region_046` | Norvège — Ouest | Norvège | *Vestlandet* et *Trøndelag* : Stavanger, Søndre Bergenhus incl. Bergen, Nordre Bergenhus, Romsdal, Søndre Trondhjem, Nordre Trondhjem | `REGIS_Norway.gpkg` (`REGIS_Norway_L1_1880-1919`) |
| `region_047` | Norvège — Nord | Norvège | *Nord-Norge* : Nordland, Tromsø, Finnmarken | `REGIS_Norway.gpkg` (`REGIS_Norway_L1_1880-1919`) |
| `region_048` | Suède — Sud | Suède | *Götaland* : Malmöhus, Kristianstad, Blekinge, Halland, Kronoberg, Jönköping, Kalmar, Gotlands, Göteborg och Bohus, Älvsborg, Skaraborg, Östergötland | `REGIS_Sweden.gpkg` (`REGIS_Sweden_L1_1870-1967`) |
| `region_049` | Suède — Centre | Suède | *Svealand* : Stockholm (Stad + Län), Uppsala, Södermanland, Västmanland, Örebro, Värmland, Kopparberg | `REGIS_Sweden.gpkg` (`REGIS_Sweden_L1_1870-1967`) |
| `region_050` | Suède — Nord | Suède | *Norrland* : Gävleborg, Västernorrland, Jämtland, Västerbotten, Norrbotten | `REGIS_Sweden.gpkg` (`REGIS_Sweden_L1_1870-1967`) |
| `region_051` | Islande (sous souveraineté danoise) | Danemark | Islande autonome sous la couronne danoise en 1914 (antérieure à l'Acte d'Union dano-islandais de décembre 1918) | `REGIS_Iceland.gpkg` (`REGIS_Iceland_L0_1870-1918`) |

### 1.2. Europe orientale (18 régions : `region_052` à `region_069`)
| ID | Nom (`region_plan.csv`) | Souveraineté (1914) | Unités administratives historiques identifiées (Gouvernements / *Gubernii* et *Uyezdy*) | Source primaire |
|---|---|---|---|---|
| `region_052` | Finlande | Empire russe | Grand-duché autonome de Finlande (8 *lääni* : Uusimaa/Nyland, Åbo-Björneborg, Tavastehus/Häme, Viborg/Viipuri, St. Michel/Mikkeli, Kuopio, Vaasa, Uleåborg/Oulu) | `REGIS_Finland.gpkg` (`REGIS_Finland_L1_1870-1918`) + `ristat_1897_provinces.gpkg` |
| `region_053` | Pays baltes du Nord | Empire russe | Gouvernements d'Estonie (*Estland*) et de Livonie (*Lifland*, incluant Riga, Dorpat/Tartu, Ösel/Saaremaa) | `ristat_1897_provinces.gpkg` (`Gub_ID` 19, 20) |
| `region_054` | Pays baltes du Sud | Empire russe | Gouvernements de Courlande (*Kurland*) et de Kovno (*Kaunas*) | `ristat_1897_provinces.gpkg` (`Gub_ID` 21, 22) |
| `region_055` | Pologne russe occidentale | Empire russe | Royaume du Congrès (rive gauche et nord-ouest) : gouvernements de Varsovie, Kalisz, Piotrków, Kielce, Radom, Płock | `ristat_1897_provinces.gpkg` (`Gub_ID` 28, 29, 30, 31, 32, 33) |
| `region_056` | Pologne russe orientale | Empire russe | Gouvernements de Lublin, Siedlce / Chełm (Kholm créé en 1912), Łomża et Suwałki | `ristat_1897_provinces.gpkg` (`Gub_ID` 25, 27, 34, 107) |
| `region_057` | Biélorussie | Empire russe | Gouvernements du Nord-Ouest : Vilna, Grodno, Minsk, Vitebsk, Moguilev | `ristat_1897_provinces.gpkg` (`Gub_ID` 23, 26, 36, 37, 45) |
| `region_058` | Ukraine occidentale | Empire russe | Gouvernements de Volhynie et de Podolie | `ristat_1897_provinces.gpkg` (`Gub_ID` 38, 39) |
| `region_059` | Ukraine centrale | Empire russe | Gouvernements de Kiev, Tchernigov, Poltava et Kharkov (hors district oriental de Starobelsk) | `ristat_1897_provinces.gpkg` (`Gub_ID` 40, 43, 44, 52) + `ristat_1897_districts.gpkg` |
| `region_060` | Ukraine méridionale | Empire russe | Gouvernement de Kherson (Odessa, Nikolaïev, Kherson, Elisavetgrad), partie occidentale d'Ekaterinoslav, et les 3 ouïezds continentaux de Tauride au nord de Perekop (Dnieprovsk, Melitopol, Berdiansk) | `ristat_1897_provinces.gpkg` (`Gub_ID` 42, 53, 54) + `ristat_1897_districts.gpkg` |
| `region_061` | Donbass | Empire russe | Bassin houiller et métallurgique du Donets : ouïezds orientaux d'Ekaterinoslav (Bakhmout, Slavianoserbsk, Marioupol), Starobelsk (Kharkov) et okroug de Taganrog / Donetsk (Oblast du Don) | `ristat_1897_districts.gpkg` |
| `region_062` | Bessarabie | Empire russe | Gouvernement de Bessarabie (Kichinev, Izmaïl, Akkerman, Khotin) | `ristat_1897_provinces.gpkg` (`Gub_ID` 41) |
| `region_063` | Crimée | Empire russe | Péninsule de Crimée : 5 ouïezds péninsulaires du gouvernement de Tauride (Simferopol, Eupatoria, Yalta, Théodosie, Perekop + Sébastopol et Kertch) | `ristat_1897_districts.gpkg` (`Gub_ID` 53 péninsulaire) |
| `region_064` | Russie du Nord-Ouest | Empire russe | Gouvernements de Saint-Pétersbourg, Pskov, Novgorod et Olonets | `ristat_1897_provinces.gpkg` (`Gub_ID` 2, 3, 11, 18) |
| `region_065` | Russie septentrionale | Empire russe | Gouvernements d'Arkhangelsk et de Vologda | `ristat_1897_provinces.gpkg` (`Gub_ID` 12, 15) |
| `region_066` | Russie centrale | Empire russe | Gouvernements de Moscou, Smolensk, Tver, Iaroslavl, Kostroma, Vladimir, Nijni Novgorod, Kalouga, Toula, Riazan, Orel, Koursk, Tambov, Voronej | `ristat_1897_provinces.gpkg` (`Gub_ID` 13, 14, 16, 17, 46, 47, 48, 49, 50, 51, 55, 56, 57, 74) |
| `region_067` | Volga moyenne | Empire russe | Gouvernements de Kazan, Simbirsk, Penza, Viatka, Perm et Oufa | `ristat_1897_provinces.gpkg` (`Gub_ID` 24, 73, 75, 76, 82, 84) |
| `region_068` | Volga inférieure | Empire russe | Gouvernements de Samara, Saratov, Astrakhan et Orenbourg | `ristat_1897_provinces.gpkg` (`Gub_ID` 77, 78, 79, 83) |
| `region_069` | Russie méridionale | Empire russe | Oblast de l'Armée du Don (hors Taganrog) et Ciscaucasie / Caucase du Nord (Kouban, Mer Noire, Stavropol, Terek, Daghestan) | `ristat_1897_provinces.gpkg` (`Gub_ID` 58, 59, 60, 69, 71, 72) |

### 1.3. Balkans (10 régions : `region_070` à `region_079`)
| ID | Nom (`region_plan.csv`) | Souveraineté (1914) | Unités administratives historiques identifiées (après les traités de Bucarest et Constantinople d'août–septembre 1913) | Source primaire |
|---|---|---|---|---|
| `region_070` | Roumanie méridionale | Roumanie | Valachie (*Oltenia* + *Muntenia*) + Dobroudja (*Tulcea*, *Constanța*) + Quadrilatère / Dobroudja du Sud (*Durostor* / Silistra et *Caliacra* / Dobritch annexés en août 1913) | `REGIS_Romania.gpkg` (`L1_1879-1913`) + `gs1914-europe-1914-low-res.geojson` |
| `region_071` | Roumanie septentrionale | Roumanie | Moldavie historique (13 *județe* : Dorohoi, Botoșani, Suceava, Neamț, Iași, Roman, Vaslui, Bacău, Fălciu, Tutova, Putna, Tecuci, Covurlui) | `REGIS_Romania.gpkg` (`L1_1879-1913` / `L2_1879-1913`) |
| `region_072` | Bulgarie occidentale | Bulgarie | Okrougs occidentaux (Sofia, Vidin, Vratsa, Pleven, Kyoustendil) + Macédoine du Pirin / Stroumitsa (traité de Bucarest 1913) | `REGIS_Bulgaria.gpkg` (`L2_1901-1912` / `L2_1923-1925`) + `gs1914-europe-1914-low-res.geojson` |
| `region_073` | Bulgarie orientale | Bulgarie | Okrougs orientaux (Tarnovo, Roussé, Choumen, Varna [sans le Quadrilatère], Plovdiv, Stara Zagora, Bourgas) + Thrace occidentale / littoral égéen de Dedeağaç (Alexandroupoli) et Komotini (1913) | `REGIS_Bulgaria.gpkg` (`L2_1901-1912` / `L2_1923-1925`) + `gs1914-europe-1914-low-res.geojson` |
| `region_074` | Serbie | Serbie | Royaume de Serbie dans ses frontières du traité de Bucarest (août 1913) : Vieille Serbie (17 okrougs de 1902–1912) + Sandjak de Novi Pazar oriental, Kosovo et Macédoine du Vardar (Skopje, Bitola, Ohrid) ; **excluant strictement la Bosnie-Herzégovine** (`region_043`, Autriche-Hongrie) | `gs1914-europe-1914-low-res.geojson` + `REGIS_Serbia.gpkg` + `REGIS_Yugoslavia.gpkg` |
| `region_075` | Monténégro | Monténégro | Royaume du Monténégro dans ses frontières de fin 1913 (incluant Pljevlja, Bijelo Polje, Berane, Peć et Gjakova après le partage du Sandjak de Novi Pazar ; excluant Cattaro et l'Herzégovine austro-hongroises) | `gs1914-europe-1914-low-res.geojson` + `REGIS_Montenegro.gpkg` |
| `region_076` | Albanie | Albanie | Principauté indépendante d'Albanie (traité de Londres de mai 1913 et protocole de Florence de décembre 1913) | `gs1914-europe-1914-low-res.geojson` + `REGIS_Albania.gpkg` (`L0_1921-1926`) |
| `region_077` | Grèce centrale | Grèce | Attique-Béotie, Phthiotide-Phocide, Étolie-Acarnanie, Eubée (`Attiki + Sterea Ellada`, `Dytiki Ellada` continentale) et îles Ioniennes | `REGIS_Greece.gpkg` (`L2_1914-1919`) |
| `region_078` | Grèce septentrionale | Grèce | Thessalie + territoires acquis en 1912–1913 : Épire (Ioannina, Arta, Preveza), Macédoine égéenne occidentale et centrale (Salonique, Kozani, Florina) et Macédoine orientale (Kavala, Drama, Serrès) + Mont Athos | `REGIS_Greece.gpkg` (`L2_1914-1919`) + `gs1914-europe-1914-low-res.geojson` |
| `region_079` | Grèce méridionale et îles | Grèce | Péloponnèse, Cyclades, Crète (unie formellement en 1913) et îles de l'Égée orientale sous contrôle grec en janvier 1914 (Lesbos, Chios, Samos, Lemnos, Thasos, Samothrace ; hors Dodécanèse occupé par l'Italie et hors Imbros/Ténédos ottomanes) | `REGIS_Greece.gpkg` (`L2_1914-1919`) + `gs1914-europe-1914-low-res.geojson` |

### 1.4. Territoires ottomans européens (4 régions : `region_087` à `region_090`)
| ID | Nom (`region_plan.csv`) | Souveraineté (1914) | Unités administratives historiques identifiées (après le traité de Constantinople du 29 septembre 1913) | Source primaire |
|---|---|---|---|---|
| `region_087` | Constantinople et environs | Empire ottoman | Vilayet de Constantinople (rive européenne jusqu'au Bosphore : Stamboul/Fatih, Péra/Beyoğlu, Beşiktaş, Sarıyer, Eyüp, Bakırköy/Makriköy, Küçükçekmece) | `gs1914-europe-1914-low-res.geojson` + `gb_tur_adm2.geojson` (ODbL) |
| `region_088` | Çatalca et Tekirdağ | Empire ottoman | Sandjak autonome de Çatalca (lignes de Tchataldja, Silivri, Büyükçekmece) + Sandjak de Tekfurdağı / Tekirdağ (Rodosto, Çorlu, Malkara, Hayrabolu, Saray) | `gs1914-europe-1914-low-res.geojson` + `gb_tur_adm2.geojson` (ODbL) |
| `region_089` | Edirne | Empire ottoman | Vilayet d'Andrinople reconquis en juillet–septembre 1913 : Sandjak d'Edirne (Andrinople, Uzunköprü, Havsa, Meriç, Lalapaşa, İpsala) + Sandjak de Kırkkilise / Kırklareli (Lüleburgaz, Babaeski, Vize, Demirköy) | `gs1914-europe-1914-low-res.geojson` + `gb_tur_adm1.geojson` |
| `region_090` | Gallipoli et rive européenne des Dardanelles | Empire ottoman | Sandjak de Gelibolu (péninsule de Gallipoli, Eceabat/Maidos, Şarköy, Keşan, Enez) + îles d'Imbros (Gökçeada) et Ténédos (Bozcaada) | `gs1914-europe-1914-low-res.geojson` + `gb_tur_adm2.geojson` (ODbL) |

---

## 2. Registre des sources téléchargées et vérifiées

| Identifiant | Source | Fichiers extraits / téléchargés | Licence | Statut |
|---|---|---|---|---|
| `regis_2026_v1` | Schweikart et al., *REGIS — Historical GIS of Europe* (DOI `10.1007/978-3-032-14932-9_3`) | `REGIS_Denmark.gpkg`, `REGIS_Norway.gpkg`, `REGIS_Sweden.gpkg`, `REGIS_Iceland.gpkg`, `REGIS_Finland.gpkg`, `REGIS_Romania.gpkg`, `REGIS_Bulgaria.gpkg`, `REGIS_Serbia.gpkg`, `REGIS_Montenegro.gpkg`, `REGIS_Albania.gpkg`, `REGIS_Greece.gpkg`, `REGIS_Ottoman_Empire.gpkg`, `REGIS_Yugoslavia.gpkg`, `REGIS_Europe_L0.gpkg`, `REGIS_Europe_L1.gpkg`, `REGIS_Europe_L2.gpkg` | **CC BY 4.0** | Extrait et vérifié |
| `ristat_1897_v1` | Kessler & Markevich, *RISTAT — Electronic Repository of Russian Historical Statistics: Russian Empire Historical GIS Maps (1897)* (DataverseNL DOI `10.34894/NQOASN`) | `ristat_1897_provinces.gpkg` (103 gouvernements/oblasts, EPSG:4326), `ristat_1897_districts.gpkg` (824 ouïezds/districts, EPSG:4326) | **CC0 1.0** (citation demandée) | Téléchargé et vérifié |
| `kavanagh_1914_v1` | Jack Kavanagh, UCD, *Map of Europe, c. 1914* (Zenodo DOI `10.5281/zenodo.21341486`) | `gs1914-europe-1914-low-res.geojson` (29 États souverains en 1914, EPSG:4326) | **CC BY 4.0** | Vérifié (frontières balkaniques et ottomanes post-1913 exactes) |
| `geoboundaries_tur_2023` | Runfola et al., *geoBoundaries* (TUR ADM1 / ADM2, OpenStreetMap) | `gb_tur_adm1.geojson`, `gb_tur_adm2.geojson` | **CC BY 4.0 / ODbL 1.0** | Téléchargé pour la découpe interne des sandjaks et kazas de Thrace orientale |
| `natural_earth_10m` | Natural Earth 10m Physical & Cultural Vectors | `ne_10m_rivers.geojson`, `ne_10m_places.geojson` | **CC0 / Domaine public** | Téléchargé et vérifié |
| `gadm_41` | GADM 4.1 | Supprimé immédiatement après vérification | *Non-commercial* | **Exclu** (clause non-commerciale incompatible) |
| `rshapes_ethz` | ETH Zürich RShapes | Non téléchargé | *CC BY-NC-SA 4.0* | **Exclu** (clause non-commerciale incompatible) |
