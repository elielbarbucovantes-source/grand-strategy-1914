# Système de carte

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [rules.md](rules.md) · [military-system.md](military-system.md) · [architecture/data-model.md](../architecture/data-model.md)

---

## 1. Objet

Définir les besoins du système de carte : territoires, adjacences, propriété, centres, representation, édition et validation. Aucun format ni schéma n'est arrêté.

## 2. Besoins fonctionnels envisagés

- Représenter des territoires de types différents (terre, mer, côte, éventuellement autre).
- Définir les adjacences et les règles de déplacement.
- Identifier les centres de production / d'intérêt.
- Suivre la propriété et le contrôle.
- Afficher l'état de façon lisible.
- Supporter plusieurs cartes, si le jeu le permet.
- Permettre la validation automatique d'une carte.

**[À DÉFINIR]** La carte est-elle unique (inspirée de l'Europe diplomatie) ou multiple ? Est-elle abstraite (graphe) ou géographique (rendu) ?

## 3. Concepts proposés

| Concept | Description | Statut |
|---|---|---|
| `Map` | Ensemble cohérent de territoires et de règles | Proposition |
| `Territory` | Nœud du graphe (province, mer, côte) | Proposition |
| `Adjacency` | Arête de déplacement / soutien / convoi | Proposition |
| `SupplyCenter` | Territoire produisant ou donnant un avantage | Proposition |
| `HomeCenter` | Centre de départ d'une puissance | Proposition |
| `Region` | Regroupement optionnel (continent, théâtre) | Proposition |
| `Owner` | Puissance contrôlant un territoire | Proposition |
| `Occupant` | Unité présente | Proposition |

Les noms et la granularité sont provisoires.

## 4. Adjacences

**[À DÉFINIR]** Types d'adjacence à distinguer :

- déplacement terrestre ;
- déplacement maritime ;
- côte (embarquement/débarquement) ;
- soutien ;
- convoi ;
- vision / renseignement.

Une même paire de territoires peut avoir plusieurs relations. Le modèle doit permettre de les distinguer sans ambiguïté.

## 5. Propriété et contrôle

**[À DÉFINIR]**

- Différence entre propriété, contrôle et occupation.
- Effets sur la construction, les revenus, la victoire.
- Durée et conditions de changement de contrôle.
- Que se passe-t-il si un territoire est contesté ?

## 6. Fog of war et information

**[À DÉFINIR — Q-013]** La carte doit-elle exposer :

- toutes les positions d'unités (modèle Diplomacy) ?
- seulement les territoires observés ?
- les mouvements en cours ?
- les intentions ?

Toute information cachée doit être filtrée côté serveur avant d'atteindre un acteur ou une IA.

## 7. Format de carte

**[À DÉFINIR — TD-012]** Options :

- fichier déclaratif lisible (JSON, YAML, TOML) ;
- format binaire compact ;
- éditeur de carte dédié ;
- combinaison (source déclarative + export).

Critères proposés :

- lisible et diffable dans Git ;
- validable automatiquement ;
- versionnable ;
- indépendant du rendu ;
- compatible avec plusieurs cartes ;
- documenté.

**[HYPOTHÈSE]** Un format déclaratif versionné faciliterait la revue, les tests et le modding. À valider.

## 8. Validation d'une carte

Contrôles proposés :

- identifiants uniques ;
- adjacences symétriques ou justifiées ;
- pas de territoire isolé injustifié ;
- centres de départ cohérents ;
- connexité selon les règles ;
- équilibrage minimal (nombre de centres par puissance) ;
- assets graphiques présents si nécessaires.

Un validateur automatique serait un livrable d'infrastructure, pas une mécanique de jeu.

## 9. Rendu et assets

**[À DÉFINIR]** 2D, 2.5D ou 3D ? Carte stylisée ou géographique ? Quelles sources d'assets et quelles licences ?

Contrainte : ne pas dépendre d'assets sous licence incompatible. Vérifier avant intégration.

## 10. Questions ouvertes

- Une ou plusieurs cartes ?
- Taille et nombre de territoires cibles ?
- Carte géographique réelle ou fictive ?
- Éditeur de carte intégré ou outil externe ?
- Comment gérer les mises à jour de carte sans casser les sauvegardes ?
- Les cartes sont-elles moddables (Q-018) ?
- Quel niveau de détail visuel pour le MVP ?

## 11. Dépendances

- [rules.md](rules.md) : types de territoires, déplacements, victoire.
- [military-system.md](military-system.md) : occupation, soutien, convois.
- [architecture/data-model.md](../architecture/data-model.md) : entités et invariants.
- ADR de format de carte à créer.

## 12. Critères de passage à « Spécifié »

- [ ] Q-003 tranchée (carte Diplomacy ou originale).
- [ ] Format de carte choisi par ADR.
- [ ] Types de territoires et adjacences définis.
- [ ] Règles de propriété et de contrôle définies.
- [ ] Validateur spécifié avec cas de test.
- [ ] Une carte de test est décrite (pas nécessairement illustrée).
