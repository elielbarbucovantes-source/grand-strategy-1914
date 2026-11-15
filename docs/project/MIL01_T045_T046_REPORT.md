# Rapport de mission — T-045, T-046 et MIL-01 (effectifs historiques de 1914)

- **Date :** 15/11/2026.
- **Branche :** `dev/historical-forces`, créée depuis `dev/combat-system` (`f505a23`, conservée intacte).
- **`main` :** inchangée. Aucune fusion, aucune branche supprimée, aucune décision validée modifiée.

**Légende des statuts :**
- **Recherché** : sources consultées.
- **Sourcé** : valeur rattachée à une source, une page et une définition.
- **Intégré** : présent dans le jeu.
- **Testé** : vérifié par un test automatique exécuté.
- **Fonctionnel** : utilisable en jeu.
- **Provisoire** : valeur ou règle proposée, non décidée.

## 1. Audit initial (constats)

- **Campagne :** une armée « emplacement » par État, effectifs `null`. Tout affrontement y était clos sans issue par le repli neutre.
- **Mobilisation et recrutement :** **aucun système** n'existait (MIL-02 ouvert ; message « non fonctionnel » dans l'interface).
- **T-045 :** le résolveur appliquait déjà les mouvements simultanément et n'évaluait les contacts que sur les positions finales. Un échange A ↔ B ne créait donc pas de bataille. En revanche, deux départages dépendaient de l'ordre technique :
  - l'attaquant d'une rencontre en territoire tiers (premier identifiant de formation) ;
  - l'occupation conjointe (premier pays dans l'ordre des nations).
- **T-046 :** la politique proposée (non validée) effaçait les ordres en cours (« tenir »), retirait le joueur de la liste des humains et ne prévoyait aucune reconnexion. Elle contredisait la décision.
- **Défauts trouvés en plus :**
  - le commandant conjoint (`BattleSystem.joint_commander`) lisait l'effectif de l'armée et non celui de ses unités ;
  - l'onglet Armée plantait sur l'historique d'une bataille tactique (champ `resolution` absent) ;
  - le journal logistique écrivait une entrée par unité coupée ;
  - tous les renforts voisins étaient verrouillés à la création d'une bataille.
- **Contradictions documentaires :** aucune contradiction majeure avec une décision validée. Deux points à noter :
  - `docs/military/OVERVIEW.md` §3 subordonnait la distinction actifs/réserves à une validation : c'est désormais fait par le directeur (note ajoutée) ;
  - le mois de départ (R-13) reste ouvert. Les effectifs sont ceux du temps de paix, quel que soit le mois choisi.
- **Git au départ :**
  - `dev/combat-system` à `f505a23` ;
  - `main` locale à `4ffdb8a`, `origin/main` à `1ec985f`, toutes deux inchangées pendant la mission.

## 2. Données historiques par puissance (sourcées)

Détail complet, divergences et districts : `docs/history/fiches/<pays>.md`.

| Puissance | Actifs (définition commune) | Source, page | Fiabilité | Réserves mobilisables | Source, page | Hors carte |
|---|---|---|---|---|---|---|
| Empire allemand | **806 016** (juillet 1914) | US War Dept 1916, p. 9 et 28 | moyenne | **4 000 000** (estimation 1911) | US WD 1916, p. 9 | 0 (sourcé) |
| France | **844 188** = 818 532 (armée métropolitaine) + 25 656 coloniaux stationnés en France | US WD 1916, p. 9 et 20 | moyenne | **2 300 000** | p. 9 | 82 368 en Afrique du Nord (dérivé) |
| Autriche-Hongrie | **472 715** (armée commune + Landwehr + Honvéd + Bosniaques) | US WD 1916, p. 37-39 | moyenne | **2 000 000** | p. 37-38 | 0 |
| Empire russe | **1 284 000** (tout l'empire) | US WD 1916, p. 9 et 45 | faible à moyenne | **3 800 000** | p. 9 | 347 027 (estimation : 10 corps sur 37 hors d'Europe) |
| Royaume-Uni | **247 432** (armée régulière, 1er août 1914) | War Office 1922, p. 30 | **haute** | **209 280** (Army Reserve + Special Reserve) | WO 1922, p. 30 | 121 123 (Inde, colonies, Égypte : sourcé, p. 157) |
| Italie | **305 033** (hors troupes d'Afrique) | US WD 1916, p. 9 et 66 | faible à moyenne | **1 250 000** | p. 9 | 0 (troupes métropolitaines en Libye : **inconnu**) |
| Empire ottoman | **208 000** (≈ 200 000 hommes + 8 000 officiers, été 1914) | Erickson 2000 | moyenne | **1 000 000** (« easily available for recall ») | Erickson 2000 | 160 000 (estimation : 10 corps sur 13 hors de Thrace) |

**Ventilation par arme :**
- sourcée (US WD 1916, p. 9) pour six puissances ; appliquée en proportion là où le périmètre diffère (estimation) ;
- **inconnue pour l'Empire ottoman** (`null`).

**Principales divergences conservées :**
- Allemagne : 734 000 (Bundesarchiv, juillet 1914) et 661 176 hommes du rang (Bernhardi, loi de 1913).
- France : de 620 420 à 818 532 dans le même document, selon le périmètre.
- Autriche-Hongrie : 370 725 pour l'armée commune seule.
- Royaume-Uni : 255 438 (US WD).
- Italie : 250 860 (budget 1912).
- Contrôle de vraisemblance : mobilisés en août 1914, Allemagne 3,8 M (Bundesarchiv).

## 3. Sources et fiabilité

Bibliographie complète : `docs/history/BIBLIOGRAPHIE.md`.

- **US War Department 1916** (*Strength and Organization of the Armies…, Showing Conditions in July, 1914*) :
  - publication officielle contemporaine, homogène pour six armées ;
  - **fiabilité moyenne** : ce sont des estimations de renseignement, et la source le dit elle-même ;
  - le tableau principal a été contrôlé sur le fac-similé.
- **War Office 1922** (*Statistics of the Military Effort…*) : statistique officielle nationale, **fiabilité haute**. Tableaux contrôlés sur les images des pages 30 et 156-157.
- **Erickson 2000** : historien spécialiste, lu dans une reprise en ligne sans pagination. **Fiabilité moyenne.**
- **Contrôle :** Bundesarchiv, Bernhardi 1914, Handbook of the German Army 1912/1914.
- **Non accessibles pendant la mission** : *1914-1918-online* et GenWiki (blocage anti-robot). Ils sont à consulter manuellement.

## 4. Données manquantes ou incertaines

1. **Effectifs par région ou garnison :** aucune source consultée ne les donne. La répartition est **estimée**.
2. **Sièges de corps :** 6 sont vérifiés par une source consultée ; les autres sont marqués « à vérifier » (connaissance encyclopédique).
3. **Empire ottoman :**
   - ventilation par arme inconnue (infanterie générique signalée sur chaque unité) ;
   - nombre total de corps (13) et rattachement des corps II et III à vérifier.
4. **Italie :** forces métropolitaines détachées en Libye inconnues.
5. **Réserves :** les estimations datent de 1911 (minimums probables). Les définitions diffèrent pour l'Autriche-Hongrie (1,6 M pour l'armée commune contre 2,0 M) et la Russie (2,97 M dans une autre ligne).
6. **Royaume-Uni :**
   - Territorial Force (268 777) exclue du réservoir : force volontaire de défense intérieure ; à modéliser sur décision ;
   - répartition par commandement estimée.
7. **États non jouables :** hors du périmètre MIL-01, effectifs inconnus. Le jeu le signale et n'invente rien.

**Verdict : MIL-01 n'est PAS déclaré terminé.**
- Les sept puissances ont des effectifs actifs et des réserves **sourcés**, suffisants pour le modèle retenu et pour jouer.
- En revanche, la répartition territoriale reste une **estimation**, la ventilation ottomane manque et plusieurs sièges sont à vérifier.

## 5. Méthode de répartition territoriale

Voir `docs/history/MIL01_METHODE.md` §3. En résumé :
1. Chaque armée est répartie **à parts égales entre ses districts de corps du temps de paix**. Le nombre de corps est sourcé :
   - Allemagne 25 ; France 21 + corps colonial ; Autriche-Hongrie 16 ; Italie 12 ; Russie d'Europe 27/37 ;
   - Royaume-Uni : 8 commandements ; Empire ottoman : 3 corps en Thrace.
2. Chaque district est placé dans la région qui contient son siège. Calcul par point dans polygone, sur la géométrie du jeu en EPSG:3035.
3. Forces hors carte comptées à part, non placées.
4. Ce n'est pas une règle de population : les armées frontalières en ressortent concentrées.
   - Exemples (soldats des unités combattantes) : Alsace-Lorraine 57 819 ; Allemagne du Sud-Ouest 115 639 ; Silésie 28 910.

Dans le jeu, chaque région de garnison reçoit une armée « Forces du temps de paix — région ». Chaque district y devient une « division », groupement de jeu portant le nom du corps et son siège. Les unités font environ 10 000 hommes : taille **technique**, non historique.

## 6. Mobilisation progressive

Voir `docs/military/MOBILISATION.md`. Le cycle :
1. Ordre secret `mobilize`, une fois par partie.
2. Chaque mois, appel de 50 % du réservoir initial sur la carte (PROPOSÉ).
3. Un mois de transit (PROPOSÉ).
4. Incorporation, seulement si la région du district est contrôlée et reliée à la capitale :
   - part des services ;
   - unités du district complétées jusqu'à 2 fois leur effectif de paix (PROPOSÉ) ;
   - puis nouvelles unités de réserve de 20 000 hommes (PROPOSÉ).

**Garanties testées :**
- conservation exacte : réservoir + en cours + incorporés = réservoir initial ;
- rien n'apparaît le mois du décret ;
- jamais de dépassement ;
- présents = actifs + incorporés ;
- blocage dans un district occupé ;
- refus motivé pour le bac à sable et les États sans données.

**Ouvert :** contraintes économiques et d'équipement, démobilisation, entraînement.

## 7. T-045 et T-046

**T-045 :** voir `docs/gameplay/TOURS_ET_DEPLACEMENTS.md`.
- Un croisement ne crée aucune bataille. Une bataille naît seulement d'une présence ennemie commune à la fin des mouvements.
- Les deux départages dépendants de l'ordre de traitement sont remplacés par :
  - une règle de fond : le camp déjà présent défend ; le plus grand contingent occupe ;
  - à défaut, un tirage neutre et reproductible par graine.

**T-046 :** voir `docs/gameplay/DECONNEXIONS.md`.
- En solo, pause jusqu'au retour.
- En multijoueur, délai de grâce configurable (30 pas, PROPOSÉ) avec les ordres conservés, puis prise de contrôle par l'IA (brouillard de son camp).
- À la reconnexion, le contrôle est restitué.
- La pause unanime est limitée aux humains connectés ; l'IA ne vote pas.
- **Aucune couche réseau** : ce sont des fondations de simulation, testées localement seulement.

## 8. Modifications du système de combat et équilibrage

**Modifications :**
- plafond des renforts candidats (12 par camp, les plus rapides) ;
- commandant conjoint calculé sur les unités ;
- `soldiers_of` renvoie l'effectif déclaré d'une armée sans unité ;
- délai de grâce et votes de pause conformes à T-046 ;
- **aucun paramètre de combat (létalité, moral, formations, etc.) n'a été modifié.**

**Simulations représentatives** (`tests/balance_report.gd`, résultats dans `COMBAT_SYSTEM.md` §6) :

1. **Létalité.**
   - 40 à 90 % de pertes en 30 minutes ; par exemple, attaque allemande en Lorraine : attaquant 66 %, défenseur 4 %.
   - Une bataille peut anéantir une armée, alors que les pertes historiques de 1914 se comptaient en pourcentages par jour.
   - **Recommandation, non appliquée :** que le directeur fixe ce que représente une bataille de 30 minutes (un engagement décisif du mois, ou une journée) et une fourchette cible de pertes. Une seule variable globale (létalité des types) suffirait alors à calibrer.
   - Je ne l'ai pas modifiée : toute valeur serait arbitraire sans cette cible.
2. **Rapports de forces.** Ils restent décisifs : 2,2 contre 1 l'emporte en 8 minutes ; à effectifs égaux, la défense l'emporte.
3. **Formations et fortifications.** En résolution automatique, l'IA choisit les formations et regroupe ses défenseurs sur les objectifs. Des tranchées préparées ailleurs ne sont pas utilisées. C'est une limite de l'IA de niveau 1 ; les effets unitaires sont testés à part.
4. **Renforts.** Ceux du défenseur arrivent (12) ; l'attaquant n'en a pas, faute d'amis voisins hors de sa région d'origine.
5. **Durée.** La formule sature à 30 minutes dès les effectifs de 1914 ; à recalibrer avec la létalité.
6. **Mobilisation.**
   - Tout le réservoir est appelé en 2 mois et incorporé en 3. L'Allemagne passe de 806 016 à 4 806 016 hommes ; 974 unités au total.
   - C'est plus que les 3,8 M mobilisés historiquement en août 1914, car le réservoir compte tous les réservistes instruits.
   - Rythme et plafond d'appel à arbitrer.
7. **Performance.**
   - 0,4 à 4,8 s par bataille résolue automatiquement (32 à 65 unités) ; 4 mois de mobilisation des sept puissances en 1,5 s.
   - La simulation tactique reste quadratique : c'est la raison de la taille d'unité.

## 9. Fichiers créés et modifiés

**Créés :**
- **Données :** `data/history/military_forces_1914.json`, `data/rules/forces_rules.json`.
- **Code :** `src/domains/military/mobilization_system.gd`, `tools/history/render_fiches.py`.
- **Tests :**
  - `tests/unit/test_moves_t045.gd` ;
  - `tests/unit/test_disconnect_t046.gd` ;
  - `tests/unit/test_forces_mil01.gd` ;
  - `tests/unit/test_campaign_integration.gd` ;
  - `tests/balance_report.gd`.
- **Documentation :**
  - `docs/history/README.md`, `MIL01_METHODE.md`, `BIBLIOGRAPHIE.md`, `fiches/` (7 fiches générées) ;
  - `docs/military/MOBILISATION.md` ;
  - `docs/gameplay/TOURS_ET_DEPLACEMENTS.md`, `docs/gameplay/DECONNEXIONS.md` ;
  - ce rapport.

**Modifiés :**

| Fichier | Modification |
|---|---|
| `tools/export/build_scenario.py` | Campagne générée depuis la base (districts, unités, bloc `forces`, `forces_source` avec empreinte) ; bac à sable construit depuis la base commune, formations identiques à l'octet |
| `data/scenarios/campaign_1914.json`, `sandbox_fictif.json` | Régénérés |
| `data/rules/combat_rules.json` | Bloc `disconnection` conforme à T-046 |
| `src/simulation/{game_state,orders,turn_resolver}.gd` | Normalisation des nouveaux champs, ordre `mobilize`, phase de mobilisation, `soldiers_of` |
| `src/domains/military/{military_system,battle_system}.gd` | T-045 (départages neutres), commandant sur les unités |
| `src/domains/combat/{battle_manager,combat_data}.gd` | T-046, plafond des renforts candidats |
| `src/domains/logistics/logistics_system.gd` | Journal par armée |
| `src/app/game_session.gd` | Règles `forces`, `disconnect_player`, `reconnect_player`, `forces_summary`, validation de la mobilisation |
| `src/ui/{game_ui,main}.gd` | Panneau des effectifs (source et cinq catégories), bouton de mobilisation, historique des batailles corrigé, libellé du scénario |
| `tests/unit/{test_rules,test_world_and_state,test_combat}.gd`, `tests/{ui_smoke,screenshot,demo_campaign}.gd` | Adaptés aux armées historiques (sans affaiblir les contrôles) ; test d'interface de la mobilisation |
| `.github/workflows/game-tests.yml` | Surveille `data/history`, `tools/history` ; contrôle des fiches |
| `docs/project/{COMBAT_SYSTEM,COMBAT_REPORT,PROTOTYPE_STATUS}.md`, `docs/decisions/{README,DECISIONS_PENDING}.md`, `docs/military/OVERVIEW.md` | Mises à jour et décisions consignées (ajouts datés, sans réécrire les décisions existantes) |

## 10. Tests exécutés

`bash tests/run.sh`, exécuté le 15/11/2026 :
- **54 tests de simulation réussis, 0 échec**, dont 17 nouveaux (T-045 : 5 ; T-046 : 3 ; MIL-01 : 6 ; intégration : 3) ;
- **interface stratégique : VALIDÉ**, y compris le bouton de mobilisation et son effet réel ;
- **interface de bataille : VALIDÉ.**

Autres contrôles :
- `build_scenario.py --check`, `build_game_data.py --check` et `render_fiches.py --check` : PASS ;
- `tools/map/validate_all.sh` : VALIDÉ (aucune donnée cartographique touchée) ;
- démonstrations `demo_campaign.gd` et `demo_battle.gd` : exécutées sans erreur.

**Non testés :**
- couche réseau multijoueur : inexistante ;
- rendu graphique de la nouvelle interface : test sans affichage seulement.

## 11. Limites restantes

- MIL-01 non terminé (voir §4).
- Équilibrage à calibrer : létalité, durée, rythme de mobilisation.
- Aucune contrainte économique sur la mobilisation (R-03, ECO).
- Pas de réseau multijoueur (T-046 reste local).
- IA tactique de niveau 1 : n'exploite pas les tranchées préparées en dehors des objectifs.
- IA stratégique : elle déplace toutes ses armées sans doctrine (niveau 1) et ne décrète pas de mobilisation.
- Mois de départ (R-13) : les effectifs du temps de paix sont utilisés quel que soit le mois.
- États non jouables : sans effectifs, repli neutre.

## 12. Lancer et tester

```bash
cd <worktree dev/historical-forces>
GODOT=~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
$GODOT --path .                                                # jouer
bash tests/run.sh                                              # tous les tests (simulation + interfaces)
$GODOT --headless --path . --script tests/balance_report.gd    # simulations d'équilibrage
python3 tools/history/render_fiches.py --check                 # fiches conformes à la base
~/.venvs/gs1914-gis/bin/python tools/export/build_scenario.py --check   # scénarios conformes
```

**Jouer la campagne historique :**
1. Au menu, choisir « Campagne historique 1914 (effectifs sourcés…) ».
2. Onglet **Armée** : source des effectifs et cinq catégories ; bouton « Décréter la mobilisation générale ».
3. Onglet **Diplomatie** : déclarer une guerre.
4. Onglet **Armée** : sélectionner une armée de garnison, puis cliquer une région ennemie voisine occupée.
5. La bataille tactique s'ouvre à la fin du mois.
