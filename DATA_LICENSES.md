# Licences et attributions des données — Grand Strategy-1914

- **Mise à jour :** 14 novembre 2026.
- **Décision du directeur (14/11/2026) :** le jeu est gratuit et open source au départ ; aucune commercialisation n'est prévue. Les données REGIS sont conservées. Un avis juridique indépendant sera demandé avant toute éventuelle commercialisation.
- **Audit détaillé :** `docs/project/audit-2026-11/02_LICENCES_PROVENANCE.md`.

> **⚠ Restriction d'usage.** Une partie des données géographiques de ce dépôt dérive de **REGIS/REThM**, distribué sous **CC BY-NC 4.0** (usage non commercial). **Les attributions ci-dessous ne valent en aucun cas autorisation d'usage commercial.** Toute utilisation commerciale de ces données, par ce projet ou par un tiers, exige l'accord écrit préalable des auteurs de REGIS ou de l'institution d'hébergement, et doit être précédée d'un avis juridique.

La licence du **code** du projet n'est pas encore choisie. Ce document ne concerne que les **données**.

## 1. Sources et licences

| # | Source | Licence | Fichiers du dépôt concernés | Obligations |
|---|---|---|---|---|
| 1 | **REGIS / REThM** — Schweikart, J., Martí-Henneberg, J., Pieper, J., Morillas-Torné, M. & Schulte, B. (2026). *Regional European Geographic Information System (REGIS), 1870–2020. A GIS Database for Thematic Mapping and Analysis.* SpringerBriefs in Geography, Springer Nature. https://doi.org/10.1007/978-3-032-14932-9 | **CC BY-NC 4.0** (données) — https://creativecommons.org/licenses/by-nc/4.0/ ; le livre est sous CC BY 4.0 | `data/world/map/regions.geojson` et `regions.json` (69 régions dont `source_refs` contient `regis_2026_v1`) ; `data/world/map/build/agent_1/*` et `build/agent_2/*` ; `data/world/map/sources/derived/gs1914_strumica_1913_salient.geojson` ; les côtes qui découpent `build/agent_2/maritime_zones.json` ; `adjacency.json`, dérivé de la géométrie | Attribution ; **usage non commercial** ; indication des modifications (§3) |
| 2 | **OpenStreetMap**, via **geoBoundaries** (William & Mary geoLab), Turquie ADM2 v6 (`TUR-ADM2-54988432`, année représentée 2021) | **ODbL 1.0** — https://opendatacommons.org/licenses/odbl/1-0/ | `regions.geojson` et `regions.json` (régions `region_087` à `region_090`) ; `data/world/map/sources/derived/gs1914_saray_tekirdag.geojson` ; `build/agent_2/*` | « © OpenStreetMap contributors » ; données disponibles sous ODbL (https://www.openstreetmap.org/copyright) ; **partage à l'identique** de toute base de données dérivée publiée |
| 3 | **OpenStreetMap**, via geoBoundaries Turquie ADM1 v6 | **CC BY-SA 2.0** (selon les métadonnées geoBoundaries) | Cité comme source par le lot `agent_2` ; usage effectif dans la géométrie finale non établi | Attribution ; partage à l'identique |
| 4 | **Kavanagh, J.** (2026). *Map of Europe, c. 1914*, v1.0. University College Dublin. Zenodo. https://doi.org/10.5281/zenodo.21341486 | **CC BY 4.0** | `data/world/map/sources/derived/gs1914_kavanagh_1914_countries.gpkg` ; contrôle des frontières internationales | Attribution |
| 5 | **Kessler, G. & Markevich, A.** (2026). *Electronic Repository of Russian Historical Statistics (RISTAT), Russian Empire Historical GIS Maps (1897)*, v3. DataverseNL. https://doi.org/10.34894/NQOASN | **CC0 1.0** (citation demandée) | `regions.geojson` et `regions.json` (régions `region_053` à `region_069`) ; `data/world/map/sources/derived/gs1914_ristat_1897_finland_provinces.gpkg` | Citation |
| 6 | **Natural Earth** 1:10m, v5.1.2 | **Domaine public** | Zones maritimes, catalogue des fleuves (lots) | Aucune (mention facultative : « Made with Natural Earth ») |
| 7 | Guides **Baedeker** et **Bradshaw** (1909–1914), *Encyclopaedia Britannica* (1911) | Domaine public | Sélection et attributs des villes, ports, places fortes et voies ferrées (`cities.json`, `terrain.json`, `infrastructure.json`) | Aucune ; les coordonnées sont des faits géographiques |

## 2. Fichiers de données mixtes

`data/world/map/regions.geojson`, `regions.json` et `adjacency.json` combinent des éléments dérivés de REGIS (CC BY-NC 4.0), d'OpenStreetMap (ODbL 1.0) et de RISTAT (CC0).

**La compatibilité entre l'obligation de partage à l'identique de l'ODbL et la clause non commerciale de CC BY-NC dans un même fichier n'est pas établie.** Elle sera soumise à l'avis juridique prévu. En attendant, ces fichiers sont diffusés :
- **pour un usage non commercial uniquement** ;
- avec l'ensemble des attributions ci-dessus ;
- sachant que les parties dérivées d'OpenStreetMap (régions 087 à 090) restent disponibles sous ODbL 1.0.

## 3. Modifications apportées aux données sources (obligation CC BY-NC et ODbL)

Les données sources ont été transformées comme suit (méthodes et preuves dans `docs/map/`) :
1. reprojection (EPSG:3035 et EPSG:4326) et agrégation d'unités administratives historiques en 90 régions de jeu (`data/world/map/tables/region_plan.csv`) ;
2. corrections topologiques : micro-chevauchements (BLK-002) et lacunes de couture (MAJ-004) ;
3. corrections historiques : Saray (BLK-001) et saillant de Strumica au 1er janvier 1914 (MAJ-003) ;
4. dérivation d'un graphe d'adjacence et de liens avec les zones maritimes (`adjacency.json`) ;
5. densification géométrique des zones maritimes (lot 2, sans changement de tracé).

Ces outils sont versionnés dans `tools/map/`, et la chaîne est reproductible (`tools/map/validate_all.sh --full`).

## 4. Ce que ce document ne fait pas

- Il **n'accorde aucun droit** au-delà de ceux des licences sources.
- Il **n'autorise pas** d'usage commercial.
- Il ne fixe **pas** la licence du code du projet (décision en attente).
