# Statut des anomalies de `ISSUES.json` (état au 15/11/2026, après le lot 2)

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
| MAJ-001 | Zones maritimes limitées au lot 2 | **PARTIELLE** | Lot 2 : 16/16 zones valides (C1, `6ed5210`), 67/67 liens catalogués (C2a, `32ed0e6`) ; **reste : aucune zone pour les mers occidentales (26 façades), décision U3** | C2b |
| MAJ-002 | Pas d'axes ferroviaires transfrontaliers entre lots | **OUVERTE** (aggravée) | Lot 2 : `infrastructure.json` consolidé (`45e4cbc`) ; réseau mesuré en **17 composantes** (axes limités à leurs extrémités) ; correction impossible sans données sourcées (`docs/map/decisions/THEMATIC_LAYERS.md`) | Données ferroviaires sourcées |
| MAJ-003 | Saillant de Strumica | **RÉSOLUE** | `03bce80`, audit indépendant `47bc6fe` ; Strumica dans 072 = vrai, dans 074 = faux | — |
| MAJ-004 | 4 lacunes de couture | **RÉSOLUE** | `219373b` et `a7983e7` ; « Lacunes sentinelles non résolues: 0/4 » | — |
| MAJ-005 | Divergence des clés JSON entre lots | **RÉSOLUE** (lot 2, C8, `ed594fb`) | Attributs dérivés régénérés depuis `adjacency.json` ; reste 4 jeux de clés, dus aux seules propriétés optionnelles `island_class` et `approximations` | — |
| MAJ-006 | Fleuves et chaînes en double | **RÉSOLUE** (lot 2, C7, `45e4cbc`) | `data/world/map/terrain.json` : Danube, Vistule, Carpates et Alpes dinariques fusionnés (`source_ids` conservés) | — |
| MAJ-007 | Arête 033–037 manquante | **RÉSOLUE** | Arête `adj_region_033_region_037` (1,13 km) | — |
| APP-001 à APP-008 | Approximations (Kholm, Oural et Caucase, Eupen-Malmedy, Monmouthshire, Thrace, plans d'eau, micro-exclaves, territoires hors cadre) | **ACCEPTÉES** (documentées) | Décrites dans `ISSUES.json` et les rapports des lots | Confirmation du directeur souhaitable |
| OPT-001 | Toponymes postérieurs à 1914 | **PARTIELLE** | « Dniepropetrovsk » absent de `data/world/map/cities.json` ; « Oslofjord » encore présent (profil de `region_045` dans `terrain.json`) ; `historical_admin_units` des régions 087 à 090 = districts turcs modernes | C7 (terrain) ; documentation pour 087 à 090 |
| OPT-002 | `etat_geometrie` dans `region_plan.csv` et `ATLAS_BUILD_STATUS.md` | **PARTIELLE** | Bandeau « obsolète » ajouté à `ATLAS_BUILD_STATUS.md` (14/11) ; `region_plan.csv` indique encore `non_construite` × 90, alors que `regions.geojson` indique `construite` × 90 | Lot 2 (donnée d'index : mise à jour par script) |
| OPT-003 | `validate_agent_1.py` incohérent | **OUVERTE**, sans effet | Script de lot, non utilisé par la CI | Aucune (historique) |
| OPT-004 | Cap de Taganrog (RISTAT) | **ACCEPTÉE** | Aucun effet sur la topologie | — |
| OPT-005 | Densité de sommets hétérogène | **OUVERTE** | Pertinente pour le rendu : simplification prévue au prototype NP-0 | NP-0 |
