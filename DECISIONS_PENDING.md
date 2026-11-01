# Décisions de conception en attente — hypothèses du MVP

> **Statut :** document de travail. Les éléments ci-dessous sont des **HYPOTHÈSES À VALIDER**, pas des règles validées.
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Référence :** [PROJECT.md](PROJECT.md) · [PROGRESS.md](PROGRESS.md) · [ADR-0006](docs/decisions/0006-pile-technique-mvp.md)

---

## 1. Règle d'usage

Le propriétaire a autorisé un premier MVP jouable (D-031) tout en maintenant la règle : une proposition d'agent ne devient pas une règle validée. Pour avancer, les valeurs et mécaniques non tranchées sont implémentées comme **hypothèses provisoires** :

- elles sont centralisées dans `game/data/` ou dans ce document ;
- elles sont nommées `H-xxx` et référencées dans le code ;
- elles peuvent être modifiées sans réécrire le moteur ;
- elles ne doivent pas être présentées comme définitives dans l'interface ou la documentation.

Toute hypothèse qui change fondamentalement l'expérience doit être arbitrée avant d'être figée. Les hypothèses listées ici sont celles nécessaires au MVP.

---

## 2. Hypothèses de simulation

| ID | Hypothèse | Valeur / choix provisoire | Pourquoi elle est nécessaire | Impact si invalidée |
|---|---|---|---|---|
| H-001 | Date de début | **Juin 1914** | Permet d'ouvrir sur la crise de Sarajevo sans imposer son issue. | Décalage de tous les événements et de l'équilibrage. |
| H-002 | Atlas provisoire | Carte hexagonale stylisée de **90 provinces** (472 hexes, grille 38 × 26), regroupées en régions historiques. Les frontières sont approximatives. | Le tracé définitif n'est pas validé ; il faut une carte jouable. | Remplacement des données `map.json` ; le moteur reste inchangé. |
| H-003 | Unités de ressources | Unités abstraites : une province produit 1 (faible), 2 (moyen) ou 3 (fort) par ressource et par mois. | D-018 fixe le principe faible/moyen/fort, pas l'échelle. | Rééquilibrage des stocks, coûts et budgets. |
| H-004 | Production et consommation | Production = somme des provinces contrôlées + régions impériales abstraites. Consommation = population/armée/industrie. Budget mensuel simplifié en richesse. | Aucune formule validée. | Rééquilibrage économique complet. |
| H-005 | Ordre de résolution du tour | Diplomatie → économie/construction → recherche → mouvements → combats → occupation → événements → renseignement → victoire. | L'ordre exact est à définir (C-01, C-16). | Changements d'effets et de priorités. |
| H-006 | Combat stratégique provisoire | Les offensives sont résolues sur la carte par une formule déterministe (effectifs, équipement, terrain, fortification, ravitaillement, soutien). Les batailles tactiques distinctes ne sont **pas** encore implémentées. | Le MVP doit être jouable avant le moteur tactique. | Remplacement par le moteur tactique ; conservation des pertes/occupation. |
| H-007 | Échelle militaire | Chaque formation est un **corps** composé de régiments d'infanterie, d'artillerie et de cavalerie. | La hiérarchie exacte n'est pas chiffrée. | Modification des données et de l'interface. |
| H-008 | Relations diplomatiques | Échelle −100 à +100 ; catégories : hostilité (< −25), neutralité (−25 à +25), amitié (> +25). | D-010 fixe trois catégories, pas l'échelle. | Ajustement des seuils et de l'IA. |
| H-009 | Traités du MVP | Alliance défensive, pacte de non-agression, accord commercial, droit de transit. Les traités sont rompus par décision ou par guerre. | Le catalogue définitif est à définir. | Ajout/retrait de types et de clauses. |
| H-010 | Paix provisoire | Une paix met fin à la guerre ; le contrôle militaire actuel est conservé et la souveraineté des provinces contrôlées est transférée au vainqueur. | Les règles de paix ne sont pas définies. | Révision des transferts territoriaux. |
| H-011 | Recherche | 5 branches, 20 technologies de 1914 à 1945, coût en points de recherche, prérequis, recherche en avance plus coûteuse. | L'arbre définitif n'existe pas. | Remplacement des données technologiques. |
| H-012 | Renseignement | Estimation imparfaite des forces adverses selon le niveau de renseignement ; pas d'interception de messages dans le MVP. | Les règles d'interception ne sont pas chiffrées. | Ajout d'un sous-système d'interception. |
| H-013 | Brouillard de guerre | Le joueur voit ses provinces, celles adjacentes et les provinces alliées ; les armées ennemies hors de cette zone sont masquées. Les IA utilisent le même filtre. | Le niveau exact de fog of war est à définir (C-06). | Modification de la visibilité et de l'IA. |
| H-014 | Politique intérieure | Indicateur de stabilité 0–100, modifié par la guerre, les pénuries, les réformes et les événements. Pas de parlement détaillé. | Les règles politiques ne sont pas chiffrées. | Rééquilibrage et ajout de mécaniques. |
| H-015 | Événements | Chaîne de Sarajevo proposée en juin-juillet 1914, avec choix pour l'Autriche-Hongrie, la Serbie et les grandes puissances ; aucune issue n'est forcée. Quelques événements génériques (grève, découverte, crise) peuvent survenir. | L'histoire doit pouvoir diverger. | Réécriture du contenu événementiel. |
| H-016 | Victoire territoriale | Contrôler au moins **90 %** des provinces européennes. | D-025 fixe le principe, pas le seuil. | Ajustement du seuil. |
| H-017 | Victoire diplomatique | Être à la tête d'une coalition couvrant au moins **70 %** des provinces européennes et avoir des relations amicales avec ses membres. | Le seuil et la définition restent à valider. | Révision complète de la condition. |
| H-018 | Victoire économique et sociale | Atteindre le meilleur indice de développement (richesse par habitant, stabilité, technologie, infrastructures), avec un indice **≥ 0,58** et une avance **≥ 0,06** sur le deuxième, puis conserver la première place **18 tours consécutifs**. | La formule exacte reste à définir. | Révision de l'indicateur et des seuils. |
| H-019 | Ordres par défaut | Sans ordre, une armée tient sa position ; la recherche et le budget conservent la dernière allocation ; aucune nouvelle diplomatie n'est initiée. | Les ordres par défaut ne sont pas spécifiés. | Modification de l'IA et de l'interface. |
| H-020 | Construction et recrutement | Les ordres de construction/recrutement coûtent des ressources et se terminent au tour suivant (ou après un délai indiqué). | Les coûts et délais ne sont pas validés. | Rééquilibrage. |
| H-021 | Mapping des statistiques nationales | Les douze notes 1–10 servent de multiplicateurs aux capacités de départ (économie, armée, recherche, diplomatie) sans double comptage avec les provinces. | L'articulation est une question ouverte (Q-028). | Refonte du modèle de données. |
| H-022 | Modes de jeu | Solo avec choix d'une des sept puissances, mode observation et prise de contrôle en cours de partie. Pas de multijoueur. | Le MVP doit couvrir le mode solo et l'observation. | Extension réseau ultérieure. |
| H-023 | Éligibilité à la victoire économique | Pour être éligible, une nation doit contrôler **au moins 6 provinces** et **au moins 10 millions d'habitants**. Ce garde-fou évite qu'un micro-État (Norvège, Danemark…) gagne dès 1914 avec un indice élevé mais un poids démographique et territorial marginal. | La victoire économique doit rester une victoire de grande puissance, pas un artefact statistique. | Ajustement des seuils ou remplacement par une autre condition de taille. |

---

## 3. Points explicitement non implémentés dans le MVP

Ces points ne sont pas simulés par un bouton décoratif ; ils sont absents ou signalés comme non disponibles :

- batailles tactiques distinctes contrôlables (résolution stratégique provisoire, H-006) ;
- combat naval et aérien détaillé ;
- interception et décryptage des communications ;
- sabotage, contre-espionnage, opérations clandestines ;
- parlement et partis détaillés ;
- gestion province par province des stocks économiques ;
- multijoueur réseau ;
- éditeur de carte ;
- modding ;
- campagnes historiques multiples ;
- technologies au-delà de 1945.

---

## 4. Prochaines décisions à demander au propriétaire

1. Valider ou corriger l'atlas provisoire (nombre et tracé des provinces).
2. Valider l'échelle des ressources et les formules économiques (H-003, H-004).
3. Trancher la place des batailles tactiques dans le tour mensuel (C-01, ADR-0005).
4. Valider les seuils de victoire (H-016 à H-018) et le garde-fou de taille (H-023).
5. Valider le modèle de paix et de transfert territorial (H-010).
6. Valider le niveau de brouillard de guerre (H-013).
