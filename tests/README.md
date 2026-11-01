# tests/ — Tests du moteur

Ce dossier contient les tests automatisés du MVP, exécutés avec `unittest` de la bibliothèque standard Python.

## Lancer les tests

Depuis la racine du dépôt :

```bash
python3 -m unittest discover -s tests -v
```

Résultat au moment de la rédaction : **24 tests, 0 échec**.

## Contenu

`tests/test_engine.py` couvre :

- **Scénario** : structure d'une nouvelle partie, mode observation, validation des nations jouables.
- **Économie** : production/consommation, construction et recrutement, indice de développement.
- **Recherche** : prérequis, achèvement d'une technologie.
- **Militaire** : capture d'une province non défendue, guerre requise pour entrer, brouillard de guerre, perte de ravitaillement.
- **Diplomatie** : amélioration des relations, guerre et paix, cascade d'alliances.
- **Événements** : chaîne de Sarajevo, déclenchement de guerre par l'IA.
- **IA** : légalité des ordres, simulation longue.
- **Victoire** : absence de victoire au départ, victoire territoriale, garde-fous de la victoire économique.
- **Sauvegarde** : aller-retour sauvegarde/chargement.

La stratégie générale est décrite dans [docs/development/testing-strategy.md](../docs/development/testing-strategy.md). Les tests manuels navigateur sont consignés dans le journal de [PROGRESS.md](../PROGRESS.md) section G.

## Principes

- résultats réels uniquement, jamais inventés ;
- tests déterministes (graine explicite) ;
- un bug corrigé ⇒ un test de non-régression ;
- les scénarios de référence du noyau de règles sont versionnés ici.
