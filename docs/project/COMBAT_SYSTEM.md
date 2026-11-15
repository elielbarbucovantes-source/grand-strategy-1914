# Système de combat terrestre — documentation technique

- **Branche :** `dev/combat-system`. **Moteur :** Godot 4.7.2, GDScript typé (ADR-0007).
- **Cahier des charges :** décisions T-029 à T-044 du directeur (mission du 15/11/2026).
- **Statut :** **fonctionnel et testé sur le bac à sable fictif**. Dans la campagne historique, les effectifs sont inconnus (MIL-01) : le combat tactique n'y est pas simulable (voir §7).

## 1. Architecture

```text
data/rules/combat_rules.json      TOUS les paramètres (provisoires, configurables), avec leur statut
src/domains/combat/
  combat_data.gd     constantes, statuts d'unité, conversions, normalisation JSON
  battlefield.gd     champ de bataille : forme de la région, terrain, objectifs (villes), points d'entrée
  tactical_sim.gd    simulation à pas fixe : arrivées, brouillard, mouvements, construction, tir,
                     mêlée, pertes par unité, moral, déroute et ralliement, objectifs, fin
  tactical_orders.gd commandes (joueur, IA, futur réseau) : formation, déplacement de groupe,
                     charge, tenir, tranchée, installation, réserve, renfort, objectif commun
  battle_result.gd   résultat : pertes et état des forces + contrôle territorial (pondéré)
  battle_manager.gd  intégration stratégique : création, verrous, commandant, durée, priorité,
                     file, avance, pause, déconnexion, clôture, pertes persistantes, occupation,
                     retraite, encerclement mensuel, moral mensuel
  defense_system.gd  construction défensive hors bataille (ordres stratégiques, travaux mensuels)
src/ai/tactical_ai.gd           IA tactique (niveau 1) sur la seule information du brouillard
src/ui/battle_view.gd           interface tactique (bataille et préparation des défenses)
```

- **Simulation pure et déterministe**, sans aucune dépendance à l'interface. Une bataille est un `Dictionary` JSON : elle est sauvegardée avec la partie (y compris en cours de bataille), rejouable et transmissible.
- **Interface sans règle métier.** Toutes les actions passent par `TacticalOrders`, `GameSession` ou des ordres stratégiques.
- **Déterminisme.** Les itérations se font en ordre trié, sans tirage aléatoire. Deux batailles identiques produisent des unités identiques (testé).

## 2. Modèle de données

- **Hiérarchie stratégique (VALIDÉE)** : armée → divisions → régiments → unités (`echelon` et `parent`). Seules les armées se déplacent sur la carte, et leurs subordonnées les suivent. Effectif d'une armée = somme de ses unités ; `null` si un effectif est inconnu.
- **Unité tactique** (`battle.units[id]`) : nation, camp, type, soldats (actuels et de départ), moral, formation, position, destination, ordre, statut, armée, région source, compteurs (feu reçu, engagement, report fractionnaire des pertes).
  - Statuts : `active`, `routing`, `withdrawn`, `destroyed`, `reserve`, `arriving`, `available`.
- **Bataille** : région, pas courant et pas maximal, champ, objectifs (villes de la région et centre), camps (nations, armées, commandant, objectif commun, point d'entrée, effectifs de départ), défenses, brouillard (mémoire datée par camp), visibilité, moral des armées, journal, pause et votes, contrôleurs (humain, IA, déconnecté), priorité.
- **Défenses d'une région** : `state.regions[rid].defenses` = tranchées (segments a→b, niveau, cible, progression, état) et installations (type, position, progression, état). Mêmes coordonnées que le champ de bataille.

## 3. Boucle d'un pas (2 s de bataille)

1. arrivées des renforts et réserves ;
2. brouillard (tous les 3 pas) ;
3. mouvements (déroute, charge, travaux, déplacement) ;
4. construction ;
5. tir automatique et mêlée : pertes accumulées **par unité** ;
6. application des pertes (destruction sous un seuil) ;
7. moral, déroute, ralliement ;
8. contrôle des objectifs ;
9. fin si la durée maximale est atteinte ou si un camp ne peut plus combattre.

**Pertes infligées par un tireur** = létalité du type × soldats × tir de la formation × efficacité (moral, désorganisation, fatigue) × (1 + bonus d'installation) × atténuation avec la distance × durée du pas × **exposition de la cible**.

**Exposition** = type × formation × (1 − couverture : terrain + tranchée selon la formation + installation) × vulnérabilité (déroute, travaux) × facteur de rôle (artillerie en retrait).

## 4. Correspondance avec les décisions

Légende :
- **V** : décision VALIDÉE par le directeur ;
- **I** : IMPLÉMENTÉE ;
- **T** : TESTÉE ;
- **F** : FONCTIONNELLE dans le prototype ;
- **D** : DOCUMENTÉE ;
- **P** : valeur ou règle PROPOSÉE (provisoire) ;
- **partiel** : voir la colonne de droite.

| Décision | Statut | Mise en œuvre | Tests |
|---|---|---|---|
| Deux niveaux ; effectifs = forces mobilisées ; pertes persistantes | V I T F D | Unités réelles des armées de la région ; pertes réécrites dans l'état stratégique ; unités détruites retirées | `test_battle_creation…`, `test_full_ai_battle…`, `test_destroyed_unit_removed…` |
| T-030 Contrôle tactique direct, tâches ordinaires automatisées | V I T F | Ordres explicites ; tir, exécution des mouvements, travaux et déroute automatiques | `test_group_orders…`, interface |
| T-031 Trois formations (principe de Lines of Battle, adapté) | V I T F, valeurs P | Ligne de tirailleurs, colonne d'assaut, position retranchée (vitesse, feu, exposition, charge, moral, discrétion, bonus de terrain) ; aucune quatrième formation | `test_formations…` |
| T-032/T-033 Tranchées dessinées et installations placées, hors bataille et en bataille, plus lentes sous le feu, étendue liée aux soldats | V I T F, valeurs P | `TacticalOrders.build_*` (bataille), `DefenseSystem` (mensuel) ; capacité du réseau = soldats × facteur ; taux réduit sous le feu ; terrain, type et moral pris en compte | `test_construction_in_battle…`, `test_trench_extent…`, `test_strategic_construction…`, interface |
| T-034 Contrôle individuel, sélection multiple, ordres de groupe, modification individuelle | V I T F | Clic, Maj+clic, rectangle ; déplacement de groupe en conservant la disposition ; ordre individuel ensuite | `test_group_orders…`, `battle_ui_smoke` |
| T-035 Brouillard tactique (repérage, mémoire datée qui vieillit et s'efface) | V I T F, valeurs P | Portée de repérage par type × terrain × discrétion de la formation × tranchée ; mémoire (position, estimation arrondie, date) ; « ? » si ancienne ; effacement | `test_ai_respects_fog`, rendu |
| T-036 Durée variable, fin automatique, pas de prolongation | V I T F, formule P | Base + effectifs + terrain + nations + objectifs, bornée à [8, 30] min | `test_battle_ends_at_max_duration…` |
| T-037 Victoire = pertes + territoire, pondération configurable | V I T F, poids P | `BattleResult` | `test_full_ai_battle…` |
| T-038 Moral individuel influencé par l'armée | V I T F, valeurs P | Dérive vers le moral de l'armée ; pertes, feu, contagion de la déroute, poste de commandement, objectifs tenus ; effet sur l'efficacité et la vitesse ; moral d'armée après victoire ou défaite ; récupération mensuelle. **Remplace D-016 sur ce point** (décision explicite du directeur) | `test_morale…` |
| T-039 Déroute individuelle, seuil configurable | V I T F | Retrait automatique vers l'arrière, non contrôlable, vulnérable, contagion ; ralliement possible | `test_morale…` |
| T-040 Renforts progressifs, réserves, tranchées | V I T F, valeurs P | Unités des régions voisines (amies ou alliées) avec délai (distance, terrain, **axe ferroviaire attesté**, détroit) ; réserves à engager avec délai ; plafond ; verrou anti-double emploi ; tranchées comme boyaux | `test_reinforcements…`, `test_reserve_commit…` |
| T-041 Positions défensives intégrées au début | V I T F | Copie des défenses de la région (emplacement, niveau, état), sans réorganisation ; réécrites après la bataille | `test_existing_defenses…` |
| T-042 Pertes individuelles (exposition, rôle, position, formation, terrain, fortifications, durée, conditions) | V I T F, formules P | Voir §3 ; la fatigue d'engagement est incluse | `test_losses_are_individual`, `test_morale…` |
| T-043 Retraite vers un territoire sûr | V I T F, critères P | Voisin national ou allié sans armée ennemie ; préférence pour la continuité avec la capitale, le rail et une exposition faible ; jamais en territoire ennemi | `test_retreat_and_encirclement…` |
| T-044 Encerclement : destruction, reddition, libération | V I T F, valeurs P | Statut maintenu ; bataille de siège au contact ; attrition et chute du moral mensuelles ; reddition sous un seuil ; libération dès qu'une route sûre existe ; destruction par les combats | `test_retreat_and_encirclement…`, `test_encircled_army…` |
| T-029 A Synchronisation | V I T F | Fin de mois refusée tant qu'une bataille est active ; batailles IA contre IA résolues immédiatement | `test_strategic_move_blocked…`, `test_player_battle_flow…` |
| T-029 B File, une bataille à la fois par joueur | V I T F | `BattleManager.queue` et `next_for` | `test_queue…` |
| T-029 C Contrôle national | V I T F | Toute commande vérifie la nation | `test_group_orders…` |
| T-029 D Priorité (critères configurables) | V I T, critères P | Capitale, joueur humain, effectifs, unités encerclées ; seuil de criticité | `test_queue…` |
| T-029 E/F Commandement conjoint (modèle C), autorité opérationnelle | V I T, **partiel** | Le commandant fixe l'objectif commun (refusé aux autres) ; l'IA alliée le suit ; chaque pays garde ses unités | `test_queue…` (désignation) ; objectif : interface |
| T-029 G Désignation (soldats, prestige, départage) | V I T F | Départage final déterministe **PROPOSÉ** : identifiant croissant | `test_queue…`, `test_joint_command…` |
| T-029 H Durée maximale | V I T F | Voir T-036 | — |
| T-029 I Pause | V I T F | Solo : accord du seul humain ; multijoueur : unanimité ; l'IA ne vote pas | `test_queue…`, interface |
| T-029 J Déconnexion | **NON VALIDÉ**, P I T | Politique configurable `ai_hold_then_takeover` (délai de grâce, puis IA) ; autres options : `hold_position`, `auto_resolve` | `test_queue…` |

## 5. IA tactique (niveau 1, PROPOSÉE)

Elle ne connaît que la mémoire du brouillard de son camp et commande ses seules unités.

- **Commandant IA** : choisit l'objectif commun.
- **Formations** : colonne loin du contact, ligne au contact, position retranchée en défense.
- **Charges** : seulement contre des cibles repérées affaiblies (en déroute ou estimées nettement inférieures), avec un moral suffisant.
- **Unités éprouvées** : elles se replient avant la déroute.
- **Réserves** : engagées quand le front faiblit ou qu'un objectif est menacé.
- **Renforts** : appelés si le rapport estimé est défavorable, ou faute de renseignement.
- **Défenseur sans contact** : creuse une tranchée devant l'objectif.
- **Limites** : pas de manœuvre coordonnée (débordement, encerclement tactique) ni de feinte.

## 6. Paramètres provisoires à équilibrer

Tous sont dans `data/rules/combat_rules.json`, et **aucun n'est historique ni définitif** :
- types d'unités (vitesse, portée, létalité, mêlée, repérage, exposition, travaux) ;
- les trois formations ;
- modificateurs de terrain ;
- moral (influence de l'armée, choc des pertes, feu, contagion, poste de commandement, seuil de désorganisation, plancher d'efficacité, bonus et malus d'armée, récupération) ;
- déroute (seuil, ralliement, vitesse, vulnérabilité) ;
- combat (atténuation avec la distance, mêlée, charge, couverture par niveau de tranchée, rayon d'installation, fatigue, dégâts aux ouvrages, seuil d'anéantissement) ;
- brouillard (fréquence, vieillissement, oubli, arrondi des estimations) ;
- durée (base, effectifs, terrain, nations, objectifs, bornes) ;
- victoire (poids pertes et territoire, marge décisive, rayon et poids des objectifs) ;
- renforts (délais, vitesses, multiplicateur ferroviaire, plafond) ;
- construction (travail par ouvrage, taux en bataille et mensuel, pénalité sous le feu, capacité par soldat) ;
- retraite (pondérations) ;
- encerclement (moral, attrition, seuil de reddition) ;
- priorité (critères, seuil) ;
- départage final ;
- déconnexion ;
- IA.

**Constat d'équilibrage** (démonstration `tests/demo_battle.gd`) : un assaut frontal contre des troupes retranchées coûte environ 88 % des effectifs à l'attaquant, contre environ 18 % au défenseur, sur 28 minutes. La défense est très favorisée par les valeurs actuelles.

## 7. Fonctionnalités incomplètes ou limites

- **Campagne historique** : les effectifs sont inconnus (MIL-01), donc la bataille n'y est pas simulable et le repli neutre documenté s'applique. Le combat est jouable uniquement dans le **bac à sable FICTIF** (forces génériques identiques, non historiques).
- **Croisement** : deux armées ennemies qui échangent leurs positions dans le même mois ne s'affrontent pas (règle de conflit simultané TURN-03 non définie).
- **Terrain du champ** : il est uniforme par région (moyenne des catégories de relief) ; fleuves, ponts et cols ne sont pas représentés sur le champ.
- **Commandement conjoint multijoueur** : seul l'objectif commun est implémenté. Il n'existe pas de canal de coordination entre joueurs humains alliés, faute de réseau.
- **Déconnexions** : politique technique proposée, non validée, sans couche réseau.
- **Renforts** : terrestres uniquement, depuis les régions voisines ; pas de transport naval.
- **Coût des ouvrages en ressources** : non appliqué (catégories R-03 ouvertes).
- **Capture des installations** : non modélisée (l'état se dégrade, le propriétaire ne change pas).
- **IA** : niveau 1, sans manœuvre coordonnée.
- **Interface** : pas de mini-carte ni de liste globale des unités ; le choix d'une cible de charge exige qu'elle soit repérée et visible.
