# Statut des anomalies de `ISSUES.json` (état au 14/11/2026)

`docs/map/audit/ISSUES.json` (audit global du 02/11/2026, `b5a07ae`) n'a pas de champ de statut. Ce tableau en tient lieu ; le fichier JSON d'origine n'est pas modifié. Les statuts sont **constatés** sur `consolidate/phase-1` (`f81c3d9`, cartographie `40a3117`) avec `tools/map/validate_all.sh` et `tools/audit/map_audit.py`.

Légende :
- **RÉSOLUE** : corrigée et vérifiée ;
- **PARTIELLE** : en partie corrigée ;
- **OUVERTE** : à traiter ;
- **ACCEPTÉE** : approximation documentée (l'approbation du directeur n'est pas consignée) ;
- **À VÉRIFIER** : non contrôlée.

| ID | Objet | Statut | Preuve ou commentaire | Tâche |
|---|---|---|---|---|
| BLK-001 | Homonymie Saray (Van ou Thrace) | **RÉSOLUE** | `a7983e7` ; `validate_geometry.py` : « Saray: point dans 088=True, Van dans 088=False » | — |
| BLK-002 | 15 micro-chevauchements | **RÉSOLUE** | `a7983e7` ; 0 chevauchement > 1e-10 deg² | — |
| BLK-003 | Frontière 026–056 omise | **RÉSOLUE** | Arête `adj_region_026_region_056` dans `adjacency.json` (365,47 km géométriques, 369,18 km curés) | — |
| MAJ-001 | Zones maritimes limitées au lot 2 | **PARTIELLE** | Intégrées à la topologie (`40a3117`), mais aucune zone pour les mers occidentales (26 façades orphelines) et `mz_norwegian_sea` invalide après reprojection | C1, C2a, C2b |
| MAJ-002 | Pas d'axes ferroviaires transfrontaliers entre lots | **OUVERTE** | `infrastructure.json` reste dans les lots (76 + 53 axes) | C7 |
| MAJ-003 | Saillant de Strumica | **RÉSOLUE** | `03bce80`, audit indépendant `47bc6fe` ; Strumica dans 072 = vrai, dans 074 = faux | — |
| MAJ-004 | 4 lacunes de couture | **RÉSOLUE** | `219373b` et `a7983e7` ; « Lacunes sentinelles non résolues: 0/4 » | — |
| MAJ-005 | Divergence des clés JSON entre lots | **PARTIELLE** | `regions.geojson` compte encore 7 jeux de clés distincts ; `external_adjacent_region_ids` et `maritime_zone_ids` hérités | C8 |
| MAJ-006 | Fleuves et chaînes en double | **OUVERTE** | `terrain.json` des lots : aucun identifiant commun pour des entités transfrontalières décrites deux fois | C7 |
| MAJ-007 | Arête 033–037 manquante | **RÉSOLUE** | Arête `adj_region_033_region_037` (1,13 km) | — |
| APP-001 à APP-008 | Approximations (Kholm, Oural et Caucase, Eupen-Malmedy, Monmouthshire, Thrace, plans d'eau, micro-exclaves, territoires hors cadre) | **ACCEPTÉES** (documentées) | Décrites dans `ISSUES.json` et les rapports des lots | Confirmation du directeur souhaitable |
| OPT-001 | Toponymes postérieurs à 1914 | **PARTIELLE** | « Dniepropetrovsk » absent du `cities.json` unifié (`4dbf4f8`) ; « Oslofjord » encore présent dans `agent_2/terrain.json` ; `historical_admin_units` des régions 087 à 090 = districts turcs modernes | C7 (terrain) ; documentation pour 087 à 090 |
| OPT-002 | `etat_geometrie` dans `region_plan.csv` et `ATLAS_BUILD_STATUS.md` | **PARTIELLE** | Bandeau « obsolète » ajouté à `ATLAS_BUILD_STATUS.md` (14/11) ; `region_plan.csv` indique encore `non_construite` × 90, alors que `regions.geojson` indique `construite` × 90 | Lot 2 (donnée d'index : mise à jour par script) |
| OPT-003 | `validate_agent_1.py` incohérent | **OUVERTE**, sans effet | Script de lot, non utilisé par la CI | Aucune (historique) |
| OPT-004 | Cap de Taganrog (RISTAT) | **ACCEPTÉE** | Aucun effet sur la topologie | — |
| OPT-005 | Densité de sommets hétérogène | **OUVERTE** | Pertinente pour le rendu : simplification prévue au prototype NP-0 | NP-0 |
