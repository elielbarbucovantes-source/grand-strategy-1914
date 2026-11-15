# Mobilisation autonome de l'IA (T-052) — MIL-01, phase 3

- **Code :** `src/ai/mobilization_agent.gd`, appelé par `NationAgent.decide` pour chaque puissance conduite par l'IA.
- **Doctrines :** `data/rules/ai_doctrines.json`. **Toutes les valeurs sont PROPOSÉES** : ce sont des paramètres de comportement, non des données historiques.
- **Tests :** `tests/unit/test_ai_mobilization.gd`. Rapport de comportement, non probatoire : `tests/ai_mobilization_report.gd`.
- **Décision :** T-052 (choix D) : doctrine nationale, seuils de menace, réactions aux mobilisations étrangères, alliances et tensions, sans information secrète.

## 1. Ce que l'IA perçoit (et ne perçoit pas)

L'IA décide **uniquement** à partir de `IntelSystem.view_for(état, carte, pays)`, la vue de son gouvernement.

| Information | Accessible | Source dans la vue |
|---|---|---|
| Guerres déclarées | oui (publiques) | `wars` |
| Traités actifs (alliances, ententes) | oui (publics) | `public_treaties` |
| Carte politique (contrôle, souveraineté) | oui (publique) | `political` |
| Posture et échelons ouverts des autres puissances | oui (publics, T-056) | `public_mobilization` |
| Formations étrangères dans les régions voisines | oui, **sans effectif** | `formations` |
| Ses propres effectifs, échelons, posture, allocation | oui (son gouvernement) | `own_forces` |
| Volumes appelés, réservoirs, cohortes des autres puissances | **non** | — |
| Ordres secrets en attente des autres puissances | **non** | — |

Un test vérifie que modifier les volumes confidentiels de la France ou ajouter un ordre secret russe ne change **pas** la décision allemande.

## 2. Score de menace (poids communs PROPOSÉS)

| Composante | Calcul |
|---|---|
| Postures étrangères | Pour chaque puissance **non alliée** : valeur de posture (paix 0, préparatoire 1, générale 2) × 10 si frontalière ou × 3 sinon × réaction nationale |
| Guerre | 100 par adversaire en guerre |
| Allié en guerre | 30 par allié (alliance ou entente) en guerre |
| Armées ennemies | 5 par armée ennemie visible au contact (guerre seulement) |
| Occupation | 20 par région souveraine occupée |
| Tension générale | 5 par guerre en cours impliquant une grande puissance × sensibilité nationale |

## 3. Doctrines nationales (PROPOSÉES)

Elles s'inspirent de la conduite des puissances en 1914, qui relève de la connaissance générale et n'est **pas sourcée dans le dépôt**. **Aucune date n'est scriptée** (HIS-01).

| Puissance | Doctrine | Seuil préparatoire | Seuil général | Réaction | Tension | Échelon suivant | Désescalade |
|---|---|---|---|---|---|---|---|
| Allemagne | Mobilisation rapide en réponse à un voisin | 10 | 20 | 1,5 | 1,0 | en guerre | après 2 mois |
| France | Réponse à la mobilisation allemande | 10 | 20 | 1,0 | 1,0 | en guerre | 2 mois |
| Russie | Mobilisation graduée (préparatoire d'abord) | 10 | 30 | 1,0 | 1,0 | en guerre | 2 mois |
| Autriche-Hongrie | Préparatoire précoce, générale en cas de crise | 10 | 20 | 1,2 | 1,0 | en guerre | 2 mois |
| Royaume-Uni | Pas de mobilisation en paix ; rappel à l'entrée en guerre | jamais | 100 (guerre) | 0 | 0 | en guerre | 1 mois |
| Italie | Prudence : pas de mobilisation malgré la tension | 60 | 100 | 0,5 | 0,5 | en guerre | 2 mois |
| Empire ottoman | Mobilisation précoce en cas de guerre générale | 30 | 60 | 1,0 | 2,0 | menace ≥ 120 | 3 mois |

**Décisions de l'IA chaque mois** (ordres secrets, résolus comme ceux du joueur) :
1. **Posture.** Elle **monte** immédiatement au niveau dicté par le score. Elle **descend** d'un niveau à la fois, hors guerre, si le score est sous le seuil et si la posture est inchangée depuis la durée de désescalade de la doctrine. Ce n'est pas une démobilisation : les incorporés restent (MIL-02 ouvert).
2. **Échelon suivant**, selon la politique de la doctrine. Il est validé à la résolution : échelon épuisé et délai écoulé.
3. **Allocation** situationnelle, la même pour tous : 34 / 33 / 33 par défaut ; 25 / 25 / 50 (logistique) si des réservistes sont bloqués ou un district occupé.

## 4. Comportements observés

Résultats de `tests/ai_mobilization_report.gd` (15/11/2026), le joueur observant sans donner d'ordre.

- **Europe calme :** aucune puissance ne mobilise en 8 mois.
- **Mobilisation générale russe publique :**
  - l'Allemagne et l'Autriche-Hongrie passent en posture générale le mois même ;
  - la France le mois suivant, en réponse à l'Allemagne ;
  - l'Italie, l'Empire ottoman et le Royaume-Uni restent en paix.
- **Guerres franco-allemande et austro-russe :**
  - les quatre belligérants passent en posture générale ; l'Allemagne et l'Autriche-Hongrie ouvrent leur second échelon ;
  - l'Italie et l'Empire ottoman passent en posture préparatoire ;
  - le Royaume-Uni (allié en guerre, sans y être) reste en paix.
- **Après la paix :** l'Italie, puis l'Empire ottoman, reviennent à la paix.
- **Guerre anglo-allemande seule :**
  - le Royaume-Uni mobilise ;
  - l'Autriche-Hongrie passe en posture générale, son allié étant en guerre ;
  - la Russie suit au mois 2, en réponse aux postures allemande et austro-hongroise.

## 5. Limites

1. **Spirale d'escalade.** Deux blocs rivaux mobilisés se maintiennent mutuellement en posture générale, même après la paix ou après la démobilisation de l'initiateur : chacun réagit à la posture publique de l'autre. Ce comportement est documenté et testé. Aucun mécanisme de détente (négociation, garanties) n'existe ; il dépend de DIP-01 à DIP-04.
   - **Décision MIL01-P3-D1 :** ce comportement n'est **pas acceptable** dans la version finale. Une désescalade diplomatique progressive est prévue dans une phase ultérieure (diplomatie et IA stratégique). La paix ne doit pas entraîner de démobilisation automatique complète.
   - **Décision MIL01-P3-D2 :** la guerre d'un allié ne doit pas suffire à déclencher la posture générale. Une réaction graduée est prévue dans la même phase ; le comportement actuel n'est pas modifié d'ici là.
2. **Doctrines non sourcées.** Elles s'inspirent de la conduite de 1914 sans référence consultée. Seuils et poids sont des valeurs de jeu à ajuster.
3. **Ni économie ni calendrier.** La « situation économique » n'est pas prise en compte (ECO non défini). Le calendrier historique n'est pas utilisé (HIS-01 non scripté).
4. **Pas de renseignement.** L'IA ne connaît pas les volumes adverses (INT-01/02 ouverts). Elle réagit aux postures publiques et aux armées visibles.
5. **Mobilisation sans offensive.** L'IA n'attaque toujours pas les régions défendues (phase 6). Mobiliser n'entraîne donc pas de bataille.
6. **Performance.** Après mobilisation (plus de 1 000 formations), un tour prend environ 1,2 s, dont environ 0,7 s pour construire les vues nationales. Le coût est quadratique (effectif de chaque armée recalculé en parcourant toutes les formations) ; c'est du code antérieur, à traiter en phase 6.
