# Données historiques — index

| Document | Contenu |
|---|---|
| [`MIL01_METHODE.md`](MIL01_METHODE.md) | Modèle validé (actifs et réserves), normalisation des définitions, répartition territoriale estimée, forces hors carte, inconnues |
| [`BIBLIOGRAPHIE.md`](BIBLIOGRAPHIE.md) | Sources utilisées (fiabilité, pages contrôlées), sources de contrôle, sources consultées sans résultat, sources primaires recommandées |
| [`fiches/`](fiches/) | Une fiche par puissance jouable, **générée** depuis la base (`tools/history/render_fiches.py`, contrôlée en CI) |
| `data/history/military_forces_1914.json` | Base structurée : chaque valeur avec source, page, définition, fiabilité et divergences |
| [`../military/MOBILISATION.md`](../military/MOBILISATION.md) | Fonctionnement de la mobilisation progressive dans le jeu |

**Règle :** aucune valeur n'est inventée. Une donnée introuvable vaut `null`, avec son motif, et une estimation est toujours signalée comme telle.
