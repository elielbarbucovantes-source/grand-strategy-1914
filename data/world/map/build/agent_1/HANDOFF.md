# HANDOFF — AGENT 1 (Construction cartographique Europe occidentale, centrale, méridionale et insulaire — 1er janvier 1914)

- **Date** : 2026-11-01
- **Agent** : Agent 1
- **Périmètre** : 50 régions (`region_001` à `region_043`, `region_080` à `region_086`)
- **Espace de sortie isolé** : `data/world/map/build/agent_1/`
- **Statut de la mission** : **100 % terminé et validé** (7/7 livrables produits, 0 erreur de validation).

---

## 1. Fichiers créés dans `data/world/map/build/agent_1/`

Aucun fichier existant du dépôt ni aucun fichier de l'Agent 2 n'a été modifié ou supprimé. Tous les fichiers créés résident exclusivement dans `data/world/map/build/agent_1/` :

1. `data/world/map/build/agent_1/regions.geojson` (8,06 Mo) — `FeatureCollection` GeoJSON (`EPSG:4326`, conforme RFC 7946) contenant les 50 polygones/multipolygones historiques réels au 1er janvier 1914.
2. `data/world/map/build/agent_1/regions.json` (98,9 Ko) — Métadonnées structurées des 50 régions (identifiants, noms, zones, souverainetés 1914, superficies en km², centroïdes, points représentatifs, catégories de relief, unités historiques agrégées, villes, adjacences, infrastructures et approximations).
3. `data/world/map/build/agent_1/adjacency.json` (61,2 Ko) — Graphe d'adjacence symétrique interne au périmètre Agent 1 (97 arêtes terrestres internes, 1 traversée de détroit documentée pour le détroit de Messine, et 14 interfaces frontalières externes vers le périmètre de l'Agent 2).
4. `data/world/map/build/agent_1/cities.json` (124,9 Ko) — 103 villes et sites stratégiques documentés en 1914 (dont les 11 capitales d'État du périmètre), tous vérifiés géométriquement à l'intérieur de leur polygone régional.
5. `data/world/map/build/agent_1/terrain.json` (43,0 Ko) — Données de relief par région (`plains`, `hills`, `mountains`, `forests`, `marshes`), façades maritimes, grands fleuves et massifs montagneux.
6. `data/world/map/build/agent_1/infrastructure.json` (149,6 Ko) — Réseau ferré stratégique de 1914 (76 axes ferroviaires documentés), 47 grands ports et 32 systèmes fortifiés historiques de 1914.
7. `data/world/map/build/agent_1/sources/README.md` (14,9 Ko) — Documentation complète des sources vectorielles (REGIS CC BY 4.0, Kavanagh 1914 CC BY 4.0, COREDEM Railways 1914, Baedeker/Bradshaw), table de correspondance des 50 régions et approximations topologiques.
8. `data/world/map/build/agent_1/validate_agent_1.py` — Script autonome de contrôle et de validation géométrique, topologique et historique du lot Agent 1.

---

## 2. Travail accompli

- **Géométries historiques 1914 construites** à partir des couches historiques REGIS (*Regional Historical GIS of Europe*, DOI `10.1007/978-3-032-14932-9_3`, licence CC BY 4.0) couvrant exactement la date du 1er janvier 1914 :
  - **Îles Britanniques (6 régions, `region_001` à `region_006`)** : Pays de Galles distinct (`region_004`), Irlande intégralement sous souveraineté britannique sans frontière politique de partition de 1921 (`region_005` Ulster géographique complet à 9 comtés ; `region_006` Leinster, Munster et Connacht à 23 comtés).
  - **Europe occidentale (13 régions, `region_007` à `region_019`)** : France dans ses frontières de 1871–1914 (sans l'Alsace-Lorraine, avec le Territoire de Belfort dans `region_011` et la Corse rattachée à `region_012` *France — Sud-Est*) ; Belgique en 2 régions avec Bruxelles intégrée cartographiquement à la Flandre (`region_013`) et la Wallonie (`region_014`) sans Eupen-Malmedy ; Pays-Bas avant l'assèchement du Flevoland (`region_015`, `region_016`) ; Suisse (`region_017`, `region_018`) ; Luxembourg (`region_019`).
  - **Péninsule ibérique (6 régions, `region_020` à `region_025`)** : Portugal continental (`region_020`) et Espagne en 5 régions (`region_021` à `region_025`, incluant les Baléares dans `region_024`).
  - **Europe centrale (18 régions, `region_026` à `region_043`)** : Empire allemand en 10 régions (`region_026` à `region_035`) incluant le Schleswig du Nord, Eupen-Malmedy, la Posnanie, la Prusse-Occidentale et Orientale, et l'**Alsace-Lorraine** (`region_035`) ; Autriche-Hongrie en 8 régions (`region_036` à `region_043`) incluant le **Trentin, le Tyrol du Sud, Gorizia-Gradisca, Trieste et l'Istrie** dans `region_037` (*Alpes autrichiennes*), ainsi que la Bosnie-Herzégovine, la Croatie-Slavonie et la Dalmatie dans `region_043`.
  - **Italie (7 régions, `region_080` à `region_086`)** : frontières du Royaume d'Italie au 1er janvier 1914 (excluant strictement le Trentin, le Tyrol du Sud, Trieste et l'Istrie).

---

## 3. Travail restant

- **Aucun travail restant sur le périmètre Agent 1** : les 7 livrables demandés sont complets et validés dans `data/world/map/build/agent_1/`.
- **Étape ultérieure (hors périmètre Agent 1)** : fusion finale des lots `agent_1` (50 régions) et `agent_2` (40 régions) dans `data/world/map/regions.geojson` et les tables partagées par l'intégrateur principal une fois le lot `agent_2` achevé.

---

## 4. Résultats de validation et erreurs

Exécution de `validate_agent_1.py` sur `data/world/map/build/agent_1/` :

- **Nombre de régions** : `50 / 50` dans `regions.geojson` et `50 / 50` dans `regions.json` (**OK**).
- **Répartition par zone** : Îles Britanniques (6), Europe occidentale (13), Péninsule ibérique (6), Europe centrale (18), Italie (7) (**OK**).
- **Unicité et conformité des identifiants** : 50 identifiants uniques strictement conformes à `data/world/map/tables/region_plan.csv` ; 0 région de l'Agent 2 touchée (**OK**).
- **Validité géométrique (`EPSG:4326`)** : `50 / 50` géométries `Polygon`/`MultiPolygon` non vides, `is_valid == True`, orientées selon RFC 7946 (**OK**).
- **Superficie totale couverte** : `3 053 472,80 km²` (**OK**).
- **Chevauchements (`> 1e-6 deg²`)** : `0` chevauchement (intersection résiduelle maximale liée à l'arrondi à 6 décimales = `1.132e-08 deg²`, inférieure de deux ordres de grandeur au seuil `OVERLAP_EPSILON = 1e-6` de `tools/map/validate_atlas.py`) (**OK**).
- **Contrôles historiques 1914** : `11 / 11` validés (Pays de Galles distinct, Ulster à 9 comtés sans partition de 1921, Irlande britannique, Alsace-Lorraine allemande, Trentin/Trieste/Istrie austro-hongrois, Bruxelles en Flandre, Corse en France — Sud-Est) (**OK**).
- **Adjacences** : 97 arêtes terrestres internes symétriques sans boucle + 1 détroit (Messine) + 14 interfaces frontalières documentées vers l'Agent 2 (**OK**).
- **Villes et infrastructures** : 103 villes (11 capitales d'État 1914, 50/50 régions couvertes, 100 % des coordonnées incluses dans leur région), 76 axes ferroviaires, 47 ports majeurs, 32 places fortes (**OK**).
- **Erreurs détectées** : **0 erreur**.

---

## 5. Décisions importantes et points d'attention pour l'intégration

1. **Conformité des licences** : Exclusivement construit à partir de sources **CC BY 4.0** (`REGIS`, `Kavanagh 1914`, `Esteban-Oliver & Martí-Henneberg 2023`, `Ciccarelli & Groote 2017`). `RShapes` (*CC BY-NC-SA 4.0*) a été écarté conformément à `docs/map/TECHNICAL_SPEC.md` §10.
2. **Interfaces frontalières avec l'Agent 2** : Les 14 arêtes terrestres et détroits reliant le périmètre Agent 1 au périmètre Agent 2 (Schleswig/Danemark `region_029`–`region_044`, Prusse/Russie/Pologne russe, Galicie/Russie/Roumanie, Transylvanie/Roumanie, Hongrie-Croatie-Bosnie/Roumanie-Serbie-Monténégro) sont pré-documentés dans la section `external_interfaces_agent_2` de `adjacency.json` pour faciliter la couture topologique des deux lots.
