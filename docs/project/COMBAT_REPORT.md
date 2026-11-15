# Rapport — mission « système de combat terrestre » (15/11/2026)

- **Branche :** `dev/combat-system`, construite sur `dev/prototype-foundation`.
- **Interdits respectés :** aucune branche supprimée, `main` inchangé, aucune fusion, aucune décision de conception modifiée, aucune donnée historique inventée.
- **Documentation technique :** `docs/project/COMBAT_SYSTEM.md`.

## 1. Audit initial (constats)

- **Existant :**
  - armées à un seul niveau, sans effectif dans la campagne ;
  - détection des rencontres ;
  - `BattleSystem` : file, commandement conjoint, pause, et un **résolveur neutre** sans issue ;
  - aucun verrou d'unité engagée ; aucune interface tactique.
- **Point de conception relevé :** le moral (T-038) remplace explicitement D-016 (« moral non retenu »). C'est une décision du directeur, appliquée et consignée.
- **Blocage de données :** les effectifs de 1914 sont inconnus (MIL-01).
  - Solution retenue : un **scénario bac à sable FICTIF** séparé, étiqueté comme tel, avec des forces génériques identiques pour tous les États.
  - Dans la campagne, le repli neutre est conservé.

## 2. Fichiers créés

- `data/rules/combat_rules.json` : tous les paramètres provisoires.
- `data/scenarios/sandbox_fictif.json`, généré par `tools/export/build_scenario.py`.
- `src/domains/combat/` : `combat_data.gd`, `battlefield.gd`, `tactical_sim.gd`, `tactical_orders.gd`, `battle_result.gd`, `battle_manager.gd`, `defense_system.gd`.
- `src/ai/tactical_ai.gd`, `src/ui/battle_view.gd`.
- Tests : `tests/unit/test_combat.gd` (21 tests), `tests/battle_ui_smoke.gd` (18 contrôles), `tests/demo_battle.gd`, `tests/battle_screenshot.gd`.
- Documentation : `docs/project/COMBAT_SYSTEM.md`, ce rapport.

## 3. Fichiers modifiés

| Fichier | Modification |
|---|---|
| `src/simulation/game_state.gd` | Hiérarchie (`armies_in`, `units_of`, `soldiers_of`, `descendants`, `move_army`, `remove_formation`, `is_engaged`) ; `active_battles`, `human_nations`, `defense_orders` ; empreinte calculée sur une forme canonique stable |
| `src/domains/military/military_system.gd` | Seules les armées se déplacent ; armée engagée verrouillée ; rencontres entre armées |
| `src/domains/military/battle_system.gd` | Départage du commandant délégué à `BattleManager.commander` (T-029 G) |
| `src/simulation/turn_resolver.gd` | Batailles tactiques, sièges d'armées encerclées, résolution immédiate des batailles sans humain, travaux, encerclement et moral mensuels, ordres de construction |
| `src/simulation/orders.gd` | `build_defense` (tranchée ou installation) |
| `src/app/game_session.gd` | Règles de combat, choix du scénario, fin de mois bloquée par une bataille active, `current_battle`, `advance_battle`, `auto_resolve_battle`, `set_reserve` |
| `src/adapters/save_repository.gd` | Précision complète ; sauvegardes triées par date (corrige « Charger » qui prenait la dernière par ordre alphabétique) |
| `src/domains/intelligence/intel_system.gd` | Vue stratégique limitée aux armées, avec effectif et état (engagée, encerclée) |
| `src/map/world_map.gd`, `tools/export/build_game_data.py`, `data/game/world_map.json` | Liaisons ferroviaires réelles entre régions (91 paires, `infrastructure.json`) |
| `src/ui/main.gd`, `src/ui/game_ui.gd` | Choix du scénario, bouton « Bataille en cours », ouverture automatique de la bataille, composition des armées, réserves, préparation des défenses, message de blocage |
| `tests/run_tests.gd`, `tests/run.sh` | Un script de test illisible compte comme un échec (au lieu de bloquer) ; délais maximaux ; test d'interface de bataille |
| `tests/unit/test_rules.gd` | Test du départage mis à jour selon T-029 G (l'ancienne attente « indéterminé » contredisait la décision) |
| `tools/export/build_scenario.py` | Génère aussi le bac à sable fictif |

## 4. Tests exécutés et résultats

`bash tests/run.sh` :
- **37 tests de simulation, 0 échec** (16 existants et 21 de combat) ;
- **test d'interface stratégique : VALIDÉ** ;
- **test d'interface de bataille : VALIDÉ** (18 contrôles).

La couverture suit la liste de la mission :
- déclenchement, création, unités engagées, fin à la durée maximale, résultat ;
- sélection individuelle et multiple, ordres collectifs, modification individuelle, formations, construction ;
- moral (évolution, influence de l'armée, fatigue), déroute, retrait ;
- pertes individuelles et persistantes, effectifs stratégiques, destruction ;
- renforts progressifs, réserves, absence de double emploi, rail ;
- défenses intégrées, état, construction en bataille et hors bataille ;
- retraite, absence de retraite, encerclement, reddition, libération, siège ;
- file, commandant (soldats, prestige, départage), pause unanime, l'IA ne vote pas, déconnexion, synchronisation ;
- sauvegarde en bataille et rechargement ;
- déterminisme ; non-omniscience de l'IA ;
- interface : chaque bouton testé a un effet vérifié dans la simulation.

**Démonstration :** `tests/demo_battle.gd`, bataille IA contre IA de 27,8 min en environ 0,6 s de calcul. Capture du rendu : `tests/battle_screenshot.gd`.

## 5. Problèmes rencontrés et corrigés

1. Création de bataille avec deux armées entrant simultanément : camps mal attribués (corrigé au lot précédent, toujours couvert).
2. **Rechargement refusé** : la relecture JSON transforme les entiers en flottants, ce qui modifiait l'empreinte. Corrigé par une forme canonique stable en précision complète.
3. **Double emploi d'une unité** entre deux batailles. Corrigé par les verrous à la création.
4. **« Charger »** reprenait la sauvegarde la plus récente par ordre alphabétique et non par date. Corrigé.
5. **Bonus ferroviaire** d'abord approximé par le relief, ce qui revenait à une règle inventée. Remplacé par les axes ferroviaires attestés.
6. **Lanceur de tests** bloqué indéfiniment par un script de test illisible. Échec désormais explicite, avec des délais maximaux.
7. **Croisement d'armées ennemies sans combat** : non corrigé (règle TURN-03 non définie). Documenté.

## 6. Décisions techniques prises (provisoires, configurables)

- Champ de bataille = forme réelle de la région, normalisée.
- Objectifs = villes réelles (capitale pondérée) et centre.
- Pas de 2 s.
- Bataille indécise : le défenseur tient.
- Départage final du commandant par identifiant croissant.
- Déconnexion : délai de grâce, puis reprise par l'IA.
- Renforts : voisins amis ou alliés, verrouillés dès la création.
- Retraite par armée entière.
- Installations dégradées par l'artillerie.
- Fatigue d'engagement.
- Interface : temps réel ×1 (une bataille dure au plus 30 min réelles), ×4, ×16 et résolution automatique.

## 7. Lancer et tester

```bash
GODOT=~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
$GODOT --path .                                   # jouer
bash tests/run.sh                                 # tests (simulation et interfaces)
$GODOT --headless --path . --script tests/demo_battle.gd    # bataille IA contre IA commentée
```

**Pour jouer une bataille :**
1. Au menu, choisir **« Bac à sable FICTIF »**.
2. Onglet **Diplomatie** : déclarer la guerre à un voisin.
3. Onglet **Armée** : sélectionner l'armée, puis cliquer une région ennemie voisine. « Fin du mois » ; au mois suivant, recommencer jusqu'au contact. Une armée ennemie présente déclenche la bataille, et l'écran tactique s'ouvre seul.
4. **Dans l'écran tactique :**
   - clic gauche : sélectionner (Maj pour ajouter ; glisser pour un rectangle) ;
   - clic droit : déplacer la sélection ;
   - boutons : formations, charge (puis cliquer un ennemi repéré), tenir, tranchée (2 clics), installations ;
   - panneau de droite : réserves (« Engager ») et renforts (« Appeler ») ;
   - « Fixer l'objectif commun » si vous commandez ;
   - pause et vitesses ;
   - « Résolution automatique ».
5. **Hors bataille** : onglet Armée, « Préparer les défenses de… ». Les travaux avancent chaque mois.

## 8. Ce qui reste

Voir `COMBAT_SYSTEM.md` §7, en priorité :
1. effectifs historiques sourcés (MIL-01), pour activer le combat dans la campagne ;
2. règle de conflit simultané pour les croisements (TURN-03) ;
3. équilibrage, la défense étant très favorisée ;
4. validation de la politique de déconnexion ;
5. coordination multijoueur et couche réseau ;
6. terrain local du champ de bataille (fleuves, ponts) ;
7. IA de niveau 2.

## 9. Mise à jour : mission « T-045, T-046 et MIL-01 » (15/11/2026, branche `dev/historical-forces`)

Rapport complet : [`MIL01_T045_T046_REPORT.md`](MIL01_T045_T046_REPORT.md).

**État des points de la section 8 :**

| Point | Avant | Après |
|---|---|---|
| 1. Effectifs historiques (MIL-01) | Inconnus ; combat impossible en campagne | Effectifs actifs et réserves **sourcés** pour les 7 puissances ; répartition **estimée** ; batailles tactiques réelles en campagne. **MIL-01 non déclaré terminé** : sièges à vérifier, ventilation ottomane inconnue |
| 2. Croisements (TURN-03) | Limite non définie | **T-045 validée et implémentée** ; départages symétriques rendus neutres |
| 3. Équilibrage | Défense très favorisée (sandbox) | Simulations historiques faites, **aucun paramètre de combat modifié** ; létalité jugée trop élevée, calibrage à décider |
| 4. Politique de déconnexion | Proposition non validée | **T-046 validée et implémentée** dans la simulation ; réseau absent |
| 5-7 | — | Inchangés |

**Autres corrections apportées au système de combat :**
- Candidats renforts plafonnés à `max_reinforcement_units_per_side`, les plus rapides d'abord. Auparavant, toutes les unités voisines étaient verrouillées : à l'échelle historique, des armées entières auraient été immobilisées.
- Commandant conjoint (`BattleSystem.joint_commander`) calculé sur l'effectif réel des unités (`soldiers_of`), et non plus sur le seul champ de l'armée.
- Historique des batailles tactiques affiché correctement dans l'onglet Armée. L'ancien code lisait un champ `resolution` absent des batailles tactiques.
- Journal logistique : une entrée par armée coupée, et non plus une par unité.
