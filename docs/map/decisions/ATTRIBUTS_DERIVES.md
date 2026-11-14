# Décision technique — attributs dérivés des régions (lot 2, C8)

- **Date :** 15/11/2026. **Nature :** décision technique (aucune règle de jeu, aucune donnée historique modifiée).
- **Outil :** `tools/map/sync_region_attributes.py`, exécuté par `tools/map/consolidate_geometry.sh` (étape 4b) et contrôlé par `tools/map/validate_all.sh` (`--check`).

## Problème

`regions.geojson` et `regions.json` portaient des listes de voisinage héritées des lots `agent_1` et `agent_2` :
- `adjacent_region_ids` différait d'`adjacency.json` pour 20 régions ;
- `maritime_zone_ids` n'existait que pour 40 régions ;
- `external_adjacent_region_ids` (périmètre de lot) existait pour 40 régions.

C'est l'anomalie MAJ-005 (clés hétérogènes) et l'audit approfondi C8.

## Règle retenue

| Propriété | Valeur |
|---|---|
| `adjacent_region_ids` | Copie de `adjacency.json` → `neighbors_by_region` (frontières terrestres mesurées sur la géométrie validée) |
| `maritime_zone_ids` | Zones liées à la région dans `adjacency.json` → `region_maritime_zone_links` (contact géométrique ou catalogue), triées ; présente pour les 90 régions, liste vide sans lien |
| `external_adjacent_region_ids` | **Supprimée** : notion de périmètre de lot, sans objet après la consolidation |

**Sources de vérité :** `adjacency.json` pour les liens, et la géométrie pour tout le reste. Les propriétés des régions n'en sont que des copies dérivées.

## Vérifications

- Géométries strictement identiques (90/90, comparaison des objets `geometry`).
- Seules les trois propriétés ci-dessus changent.
- **Point fixe :** reconstruire `adjacency.json` après la synchronisation ne change que `generated_from` (empreintes), et `--check` passe.
- `validate_all.sh --full` : 94/0, 96/0, géométrie reconstruite identique octet pour octet.

## Hors périmètre

- `island_class` (absente = région non insulaire) et `approximations` (10 régions) restent optionnelles : il en reste 4 jeux de clés distincts, légitimes.
- `region_plan.csv` (`etat_geometrie = non_construite`, OPT-002) n'est pas modifié. C'est un index éditorial ; sa mise à jour relève d'une révision de l'index.
