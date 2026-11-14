# Rapport du lot 2 — Consolidation cartographique et documentaire

- **Autorisation :** directeur, 14/11/2026. **Réalisation :** 14–15/11/2026.
- **Branche :** `consolidate/map-phase-2`, construite sur `audit/licences-2026-11` (elle-même sur `audit/deep-2026-11`, puis `consolidate/phase-1`, puis la cartographie `40a3117`).
- **Interdits respectés :**
  - aucune frontière modifiée ;
  - aucune zone maritime créée ;
  - aucune proximité convertie en adjacence ;
  - aucune donnée historique ajoutée ;
  - aucune fusion de lignées, `main` inchangé ;
  - aucune suppression ;
  - aucun gameplay.

## 1. Modifications et commits

| Commit | Tâche | Modification |
|---|---|---|
| `13563ae` | Licences | `DATA_LICENSES.md` et `NOTICE` : REGIS CC BY-NC 4.0 (usage non commercial, **les attributions ne valent pas autorisation commerciale**), OpenStreetMap / geoBoundaries ODbL 1.0 (et CC BY-SA 2.0 pour ADM1), Kavanagh CC BY 4.0, RISTAT CC0, Natural Earth domaine public ; fichiers mixtes signalés (avis juridique avant toute commercialisation) ; décision du directeur consignée dans l'audit des licences et le questionnaire ; rappel dans `AGENTS.md` et `README.md` |
| `6ed5210` | C1 | `tools/map/repair_maritime_zones.py` : densification à 0,25° en WGS 84. Sommets d'origine conservés, tracé inchangé (écart ≤ 2,3e-15 deg²), 16/16 zones valides en EPSG:3035 |
| `32ed0e6` | C2a | `tools/map/sync_maritime_catalogue.py` : 14 liens géométriques catalogués, soit 67/67 liens déclarés ; validateur 53 → 67, plus un contrôle « aucun lien géométrique hors catalogue » |
| `ed594fb` | C8 | `tools/map/sync_region_attributes.py` (étape 4b de `consolidate_geometry.sh`) : `adjacent_region_ids` (20 régions corrigées), `maritime_zone_ids` (90/90), suppression de `external_adjacent_region_ids` ; note `docs/map/decisions/ATTRIBUTS_DERIVES.md` |
| `45e4cbc` | C6, C7, C3–C5 | `tools/map/build_thematic_layers.py` et `validate_thematic.py` : `cities.json`, `terrain.json`, `infrastructure.json` ; fiches `docs/map/decisions/` (Islande, Corfou, proximités, couches thématiques) |
| *(ce commit)* | Documentation | Ce rapport ; `ISSUES_STATUS.md`, `tools/map/README.md`, `PROGRESS.md`, `CHANGELOG.md` |

## 2. Comparaisons avant et après

| Contrôle | Avant | Après |
|---|---|---|
| Géométrie des 90 régions (objets `geometry`) | — | **Strictement identique** |
| Reconstruction complète de la géométrie (`--full`) | Identique | **Identique octet pour octet** (pipeline étendu à l'étape 4b) |
| Arêtes terrestres, détroits, graphe jouable, proximités, façades orphelines | 184 / 10 + 3 / 192 / 8 / 26 | **Inchangés** |
| Zones maritimes valides en EPSG:3035 | 15/16 | **16/16** |
| Liens région/zone déclarés au catalogue | 53/67 | **67/67** (0 lien ajouté ou retiré dans la topologie) |
| 051 ↔ `mz_norwegian_sea` (catalogue seulement) | 170,22 km (mesure sur `buffer(0)`) | 166,05 km (géométrie valide) |
| `adjacent_region_ids` divergents | 20 régions | **0** |
| Jeux de clés distincts dans `regions.geojson` | 7 | 4 (propriétés optionnelles légitimes) |
| Villes | Hors lignée de référence | 175/175 validées sur la géométrie |
| Fleuves et massifs | 61 et 22 (doublons MAJ-006) | 59 et 20 |

**Empreintes de référence** (`tools/map/REFERENCE_SHA256SUMS`, ancienne puis nouvelle valeur, chacune justifiée dans son commit) :
- `adjacency.json` : `4013f26e…` → `b60d4ef6…`
- `regions.geojson` : `183e5e80…` → `10a274e8…`
- `regions.json` : `4b26f0bd…` → `a6b5a8e4…`
- `validate_topology.py` : `2ebb5123…` → `7f6a3c69…`
- `rebuild_topology.py` : inchangé (`15f7b9f9…`).

## 3. Tests exécutés

- `tools/map/validate_all.sh --full` après chaque étape. Résultat final :
  - empreintes OK ;
  - zones densifiées, catalogue aligné, attributs synchronisés, couches thématiques reproduites ;
  - `validate_geometry` et `validate_atlas` OK ;
  - `validate_topology` **94/0**, `--rebuild-check` **96/0** ;
  - `validate_thematic` **34/0** ;
  - géométrie reconstruite identique.
- **Tests négatifs** : `adjacency.json` altéré, échec à l'étape 1 (phase 1) ; ville déplacée hors de sa région, 3 échecs détectés par `validate_thematic.py`.
- **Idempotence** : chaque script en `--check` après application, et point fixe vérifié entre attributs et topologie.
- CI GitHub Actions : voir la section Git.

## 4. Anomalies corrigées

- **MAJ-005** (clés hétérogènes).
- **MAJ-006** (doublons transfrontaliers).
- Validité de `mz_norwegian_sea`.
- 14 liens non catalogués.
- 20 listes de voisinage obsolètes.
- Réintégration des villes.
- Attributions de licences manquantes dans le dépôt public.

## 5. Anomalies restantes

| Anomalie | Raison | Suite |
|---|---|---|
| 26 façades sans zone maritime (mers occidentales) ; graphe naval en 3 composantes | Création de zones interdite sans décision | **Décision U3** |
| Réseau ferré en **17 composantes** (134/175 villes desservies) ; MAJ-002 | Axes limités à leurs extrémités ; données sourcées nécessaires | Collecte ferroviaire sourcée |
| Noms composites de capitales ; capitale albanaise | Modélisation historique | **Décision C6b** |
| « Oslofjord » (OPT-001), districts turcs modernes dans `historical_admin_units` (087 à 090) | Toponymie à sourcer | Révision documentaire |
| `region_plan.csv` : `etat_geometrie = non_construite` (OPT-002) | Index éditorial non révisé | Révision de l'index |
| Compatibilité ODbL / CC BY-NC dans les fichiers mixtes | Juridique | Avis juridique (avant toute commercialisation) |

## 6. Décisions du directeur encore nécessaires

1. **U3** : mers occidentales (7 ou 9 zones) et intégration du mouvement naval au graphe jouable (règle aussi le cas de l'Islande, C3).
2. **C4** : canal de Corfou (recommandation : statu quo).
3. **C5** : confirmation des huit proximités (recommandation : statu quo).
4. **C6b** : capitales à nom composite et capitale albanaise.
5. **U8 (précision)** : licence open source exacte du code.

## 7. Évaluation de cohérence

- **Géométrie et topologie terrestre :** cohérentes, validées, reproductibles octet pour octet sur deux machines.
- **Couche maritime :** cohérente avec la géométrie (16/16 valides, catalogue complet), mais **incomplète** à l'Ouest.
- **Villes, terrain et infrastructures :** cohérents entre eux et avec la géométrie (34 contrôles).
- **Réseau ferré :** inutilisable comme graphe de transport en l'état.
- **Licences :** attributions conformes publiées. L'usage reste non commercial.
- **Conclusion :** l'atlas est **utilisable pour le prototypage** des déplacements terrestres (`adjacency.json`) et de l'affichage (régions, villes, capitales, relief). Il ne l'est **pas encore** pour la logistique ferroviaire et le mouvement naval occidental.
