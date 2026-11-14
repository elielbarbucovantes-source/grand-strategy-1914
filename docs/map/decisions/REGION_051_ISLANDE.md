# Fiche — Région 051 (Islande, souveraineté danoise)

- **Statut :** fiche documentaire. **Décision du directeur requise** sur le modèle naval (C3).

## Faits mesurés (géométrie et topologie validées, lot 2)

| Élément | Valeur |
|---|---|
| Frontière terrestre | Aucune (île) |
| Régions les plus proches | Écosse 003 : 780,6 km ; Norvège Ouest 046 : 969,6 km ; Ulster 005 : 1 071 km |
| Liens maritimes | `mz_north_atlantic_iceland`, contact géométrique (frontière partagée de 0,4 km) ; `mz_norwegian_sea`, déclaré au catalogue seulement (distance 166,05 km après la densification C1) |
| Graphe naval | `mz_north_atlantic_iceland` ↔ `mz_norwegian_sea` ↔ `mz_north_sea_eastern` / `mz_barents_white_sea`, donc reliée au reste de la composante maritime Nord |
| Graphe jouable (terre et détroits) | Isolée (`isolated_in_passable_graph`) |

## Analyse

- L'isolement est **justifié** dans un graphe limité aux frontières terrestres et aux détroits : aucun détroit ne peut relier l'Islande à une autre région.
- Historiquement, en 1914, l'Islande est accessible **par mer**, par des lignes régulières depuis Copenhague via Leith et les Féroé.
- Ce n'est **pas** une erreur de données. C'est une question de **modèle de déplacement** : le mouvement naval et le débarquement via les zones maritimes font-ils partie du graphe jouable (MAP-DEC-19 : débarquement sur les côtes accessibles, facilité par les ports) ?
- Le lien `catalogue_only` vers la mer de Norvège reflète l'intention du lot 2 (Islande riveraine de la mer de Norvège). La géométrie de la zone s'arrête à 166 km de la côte. Il est conservé tel quel.

## Options

| Option | Modification | Effet |
|---|---|---|
| A. Mouvement naval par zones intégré au graphe jouable | Aucune modification de données ; règle de déplacement à implémenter | 051 accessible via `mz_north_atlantic_iceland` |
| B. Statu quo (terre et détroits seulement) | Aucune | 051 inaccessible militairement |
| C. Détroit fictif | **Déconseillé** : aucun fondement géographique | — |

**Recommandation :** A, à confirmer. Ne créer **aucun** détroit.
