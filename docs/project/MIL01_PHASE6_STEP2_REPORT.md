# MIL-01 — Phase 6, étape 2 : types d'engagement, largeur du front, blessés légers

**Branche :** `dev/mil01-finalisation`. **Date :** 16/11/2026.

**Mandat :** système d'engagements tactiques cohérent, différencié et fonctionnel, **sans équilibrage définitif des pertes** (étape 3, non commencée).

**Légende :**
- D : documenté ;
- I : implémenté ;
- T : testé (tests automatiques) ;
- F : fonctionnel, vu à l'écran ou testé par l'interface ;
- P : provisoire, paramètre de conception à valider.

**Toutes les valeurs numériques introduites sont des paramètres de CONCEPTION.** Aucune n'est une donnée historique sourcée. Elles sont dans `data/rules/combat_rules.json`, bloc `engagement`.

---

## 1. Changements architecturaux

| Élément | Changement | État |
|---|---|---|
| `src/domains/combat/engagement.gd` | **Nouveau module.** Il regroupe : choix des camps, classification, largeur du front et rotations, rupture du combat, seuil de déroute selon la posture, capacité opérationnelle. | D, I, T |
| `tactical_sim.gd` | Le pas de simulation appelle le module à deux endroits : répartition du front au début du tir, rupture du combat après les objectifs. Le feu et la mêlée utilisent les soldats opérationnels en ligne. L'exposition tient compte de la place de l'unité. Le seuil de déroute dépend de la posture. Nouveau statut `withdrawing` (repli en ordre). | I, T |
| `battle_manager.gd` | **Création :** approche et posture, classification, part engagée d'emblée, durée plafonnée par le type. **Clôture :** classification réalisée ; règle de la reconnaissance (pas d'occupation sans effondrement, renseignement conservé) ; blessés légers inscrits dans les unités. | I, T |
| `combat_data.gd`, `battle_result.gd` | Statut `withdrawing` ; normalisation JSON des nouveaux champs. L'état des forces (T-037) est calculé sur la capacité opérationnelle. | I, T |
| `orders.gd`, `military_system.gd`, `turn_resolver.gd`, `game_session.gd` | **Approche :** champ facultatif de l'ordre de déplacement, transmis à l'affrontement. **Posture :** nouvel ordre `set_defensive_posture`, permanent par armée, appliqué avant les batailles du mois. | I, T |
| `tactical_ai.gd` | L'IA respecte l'approche (charges, objectif, avance, réserves) et la posture (retranchement, repli volontaire). Posture par défaut d'une armée IA. | I, T |
| `force_ledger.gd` | `heal_lightly_wounded` : guérison mensuelle des blessés légers restés dans les unités. | I, T |
| `game_ui.gd`, `battle_view.gd` | **Interface stratégique :** sélecteur d'approche et sélecteur de posture par armée. **Interface tactique :** panneau d'engagement, place de l'unité sur le front, bouton « Rompre le combat », résultat. | I, T, F |

**Systèmes existants conservés :**
- trois formations ; moral individuel et d'armée ; déroute et ralliement ;
- renforts progressifs et réserves ; tranchées et installations ; artillerie ; terrain ;
- retraites, encerclement, destruction des unités, durée variable ;
- sauvegardes, brouillard, comptabilité de l'étape 1.

**Compatibilité des sauvegardes :**
- Le format n'est pas modifié : les nouveaux champs ont des valeurs par défaut.
- Une bataille en cours sans type d'engagement (sauvegarde antérieure) se termine avec les anciennes règles (test `test_legacy_battle_without_engagement`).

## 2. Nouvelles mécaniques

1. **Choix offensif et défensif.** L'attaquant choisit son approche dans l'ordre de déplacement ; le défenseur, sa posture, ordre permanent de chaque armée.
2. **Classification** en quatre types : prévue à la création, réévaluée à l'arrivée des renforts et à la clôture.
3. **Largeur du front.** Un secteur de combat (km) limite la place sur la ligne de feu. Les unités au contact sans place attendent, peu exposées, et relèvent les unités épuisées.
4. **Rupture du combat en ordre.** Selon un seuil de l'approche ou de la posture, sur ordre du commandant, ou quand toutes les unités sont épuisées, les unités se replient sans déroute.
5. **Capacité opérationnelle.** Elle est distincte de l'effectif administratif : les blessés légers restés dans leur unité combattent à 50 %.

**Aucune de ces mécaniques n'est un multiplicateur de pertes.** Elles changent qui combat, combien de temps, avec quels objectifs et quand le combat s'arrête. Les pertes en découlent.

## 3. Paramètres ajoutés (`combat_rules.json`, bloc `engagement`)

| Paramètre | Valeur | Justification (conception) |
|---|---|---|
| Part engagée d'emblée : reconnaissance / attaque limitée / assaut | 25 % / 60 % / 100 % | Ampleur croissante des trois approches ; le reste en réserve |
| Rupture de l'attaquant : reconnaissance / limitée / assaut | 6 % / 15 % / 35 % de l'effectif engagé perdu **ou en déroute** | Une reconnaissance cesse vite, un assaut insiste |
| Rupture du défenseur : retarder / tenir / à tout prix | 8 % / 30 % / jamais | Retarder = préserver les forces ; à tout prix = aucune rupture |
| Seuil de déroute « à tout prix » | × 0,5 (moral 10 au lieu de 20) | Les unités tiennent plus longtemps sous le feu |
| Type : durée maximale / secteur | Escarmouche 10 min, 8 km ; limité 20 min, 20 km ; frontal 30 min, 40 km ; grande bataille 30 min, 80 km | Durée et ampleur croissantes ; 30 min reste le maximum validé (T-036) |
| Grande bataille | 200 000 hommes engagés | Seuil proposé par le directeur, vérifié contre le moteur (§6) |
| Terrain minimal pour une grande bataille | facteur 0,6 | Un terrain cloisonné empêche le déploiement d'une grande bataille |
| Plafond des petites batailles | moins de 20 000 hommes : engagement limité au plus | — |
| Moral minimal pour un assaut frontal | 40 (moral d'armée de l'attaquant) | — |
| Position fortifiée | tranchées de niveau 2 | — |
| Densités en ligne | 1 000 fantassins et 250 artilleurs par km | Ordre de grandeur de conception, **non sourcé** |
| Facteur de terrain | plaines 1 ; collines 0,8 ; forêts 0,6 ; marais 0,5 ; montagnes 0,4 | — |
| Place par soldat selon la formation | tirailleurs 1,3 ; colonne 0,7 ; retranchée 1 | — |
| Tranchée achevée | ÷ 1,4 | Un soldat retranché tient plus de front |
| Unités en attente | exposition × 0,3 | — |
| Rotation | moral < 40 ou fatigue < 0,85 ; récupération de 2 pas de fatigue par pas | — |
| Rupture du combat | 30 pas (1 min) de repli ; aussi quand toutes les unités actives ont un moral < 30 | — |
| Blessés légers | efficacité 0,5 ; guérison après la convalescence légère (1 mois, décision de l'étape 1) | « Suffisamment importante », configurable |

Je n'ai ajouté aucune nouvelle formule de pertes, et je n'ai modifié aucune valeur existante de `combat_rules.json`.

## 4. Les trois approches offensives

| Approche | Règles appliquées |
|---|---|
| **Reconnaissance en force** | 25 % des unités engagées (par type), le reste en réserve, **non engagée par l'IA**. Aucune charge. Arrêt au contact. Objectif le plus proche. Rupture à 6 %. La région n'est **prise que si la défense s'effondre** ; sinon l'issue est indécise et l'attaquant se retire. **Renseignement :** unités repérées, estimation des effectifs et niveau des tranchées, conservés dans la région (`recon_reports`), journal et écran de résultat. |
| **Attaque limitée** | 60 % engagés, le reste en réserve (engagée si le front faiblit). Objectif le plus proche, quel que soit son poids. Charges seulement contre un ennemi en déroute. Rupture à 15 %. |
| **Assaut** | Tout engagé. Objectif principal. Charges autorisées, comme avant. Rupture à 35 %. |

## 5. Les trois postures défensives

| Posture | Règles appliquées |
|---|---|
| **Retarder** | Ni tranchée ni position retranchée : l'IA se bat en tirailleurs. Rupture dès 8 % : la région est cédée et les forces sont préservées. |
| **Tenir** | Comportement défensif antérieur (retranchement), plus une rupture à 30 %. |
| **Tenir à tout prix** | Aucune rupture ni aucun repli volontaire d'unité. Seuil de déroute abaissé de moitié. |

- **Posture par défaut :**
  - une armée sans posture choisie tient ;
  - une armée IA dans la région de sa capitale tient à tout prix (proposition) ;
  - un défenseur encerclé ne peut pas retarder.

## 6. Classification des engagements

**1. Matrice des choix :**

| Attaquant \ Défenseur | Retarder | Tenir | Tenir à tout prix |
|---|---|---|---|
| Reconnaissance en force | Escarmouche | Escarmouche | Escarmouche |
| Attaque limitée | Escarmouche | Engagement limité | Engagement limité |
| Assaut | Engagement limité | Assaut frontal | Assaut frontal |

**2. Circonstances, à la création :**
- défenseur encerclé : il tient au lieu de retarder ;
- attaque limitée contre une position fortifiée (tranchées de niveau 2 ou plus) : assaut frontal ;
- moral d'armée de l'attaquant inférieur à 40 : l'assaut frontal devient un engagement limité ;
- **effectif engagé d'au moins 200 000 hommes** : l'assaut frontal devient une **grande bataille**, sauf en terrain trop cloisonné (facteur inférieur à 0,6) ;
- moins de 20 000 hommes : engagement limité au plus.

**3. En cours de bataille :** l'arrivée de renforts qui porte l'effectif sur le terrain au-delà de 200 000 hommes fait passer un assaut frontal en grande bataille, avec un secteur élargi.

**4. À la clôture (type réalisé) :**
- un camp qui rompt le combat avant le premier tiers de la durée ramène l'engagement d'un cran ;
- moins de 20 000 hommes réellement entrés sur le terrain : engagement limité au plus.

**5. Traçabilité :** les critères retenus sont consignés dans `engagement.reasons`.

**Seuil de 200 000 hommes : vérification contre le moteur.**
- Dans la campagne de janvier 1914, une armée compte 45 000 à 190 000 hommes, et une bataille de 100 000 à 250 000 hommes pour les deux camps, auxquels s'ajoutent jusqu'à 96 000 renforts par camp.
- Le seuil n'est atteint que par une bataille de plusieurs armées, renforcée ou après mobilisation : secteur synthétique de la Somme, 249 000 hommes ; Lorraine après trois mois de mobilisation.
- Il est donc **cohérent**, et il distingue bien l'ampleur.

## 7. Largeur du front

**Secteur (km)** = min(largeur du type, largeur de la région perpendiculairement à l'axe d'attaque) × facteur de terrain moyen des reliefs de la région.
- La largeur de la région est mesurée sur sa géométrie : 213 à 513 km dans les cas testés. Elle ne limite que les petites régions.
- Le secteur varie avec le type, la géométrie et le terrain : il n'est jamais une limite fixe.
- Exemples : Lorraine, 5,6 km en escarmouche et 28 km en assaut frontal ; Vénétie en montagne, 24 km ; France du Nord en plaine, 72 km pour une grande bataille.

**À chaque pas, pour chaque camp :**
1. Les unités **au contact** (un ennemi repéré à portée) se partagent la place :
   - infanterie et cavalerie d'un côté, artillerie de l'autre ;
   - en priorité les unités déjà en ligne et fraîches, puis les plus proches de l'ennemi ;
   - une unité épuisée (moral inférieur à 40 ou fatigue) passe derrière si une unité fraîche attend : c'est la **rotation**.
2. **Place occupée** = soldats × place par soldat de la formation, divisée par 1,4 en tranchée achevée. Une unité peut n'être qu'en partie en ligne.
3. **Seuls les soldats en ligne tirent** : feu ∝ soldats opérationnels × part en ligne. **Une unité en attente** ne tire pas, est exposée à 30 % et récupère de sa fatigue.
4. Les tireurs visent d'abord les unités adverses en ligne.

**Brouillard :** le panneau tactique n'affiche que vos propres soldats en ligne, en attente et en réserve.

## 8. Réserves et renforts

- **Réserves :**
  - la part non engagée d'une reconnaissance ou d'une attaque limitée devient une réserve, comme celles que le joueur désigne ;
  - leur engagement garde le **délai existant** (1,5 min) ;
  - l'IA n'engage pas les réserves d'une reconnaissance ;
  - le joueur peut toujours les engager.
- **Renforts :** délai existant inchangé (distance, terrain, rail, détroit) ; plafond de 12 unités par camp.
- **Aucun double emploi :** une unité engagée ou réservée comme renfort est verrouillée pour sa bataille. Un test vérifie qu'elle n'apparaît pas dans une autre bataille.
- **Rupture du combat :** les réserves non engagées et les renforts en route se retirent sans combattre.

## 9. Blessés légers

- **Effectif administratif** (`soldiers`) : inchangé, il inclut les blessés légers restés dans l'unité (étape 1).
- **Capacité opérationnelle** = soldiers − blessés légers × (1 − 0,5).
  - Elle sert au feu, à la mêlée, aux travaux et à l'état des forces de fin de bataille.
  - Elle est affichée dans l'onglet Armée et dans la vue tactique.
- **Pas de double comptage :**
  - les blessés légers sont un **sous-ensemble** des présents ;
  - quand l'unité subit des pertes, ils en font partie au prorata ;
  - à la guérison, la capacité est rétablie sans changer les présents ni le registre ;
  - la conservation des effectifs est vérifiée.
- **Guérison :** après la convalescence légère, soit un mois (`ForceLedger.heal_lightly_wounded`).
- **Effet mesuré :** dans une première bataille de Lorraine, 593 blessés légers restent dans les unités des deux camps, soit moins de 0,2 % de la capacité (0,5 × 593 sur environ 185 000 hommes). L'effet existe, mais il est faible, puisque seuls 10 % des blessés légers restent dans leur unité (décision de l'étape 1).

## 10. Résultats des simulations

Commande : `godot --headless --path . --script tests/engagement_report.gd`.
- IA contre IA, campagne de janvier 1914, entièrement déterministe.
- Pertes en % de l'effectif réellement entré sur le terrain.
- **Ces chiffres sont exploratoires. Ils ne sont pas calibrés (étape 3).**

**Lecture de la colonne « Pic en ligne » :** les nombres peuvent dépasser la capacité de référence (km × 1 000 + km × 250), car une colonne d'assaut fait tenir plus de soldats par km. La place occupée, elle, ne dépasse jamais le secteur (test `test_front_width_limits_simultaneous_combatants`).

### 10.1 Les neuf combinaisons : Lorraine (Allemagne 035 → France 011 ; défenseur plus nombreux)

| Approche / posture | Type prévu → réalisé | Front | Pic en ligne A / D | Durée | Fin | Pertes A / D | Vainqueur |
|---|---|---|---|---|---|---|---|
| reconnaissance / retarder | Escarmouche → Escarmouche | 5,6 km | 5 385 / 1 077 | 10,0 min | durée max. | 2,9 % / 0,1 % | indécise |
| reconnaissance / tenir | Escarmouche → Escarmouche | 5,6 | 5 385 / 1 400 | 10,0 | durée max. | 3,4 % / 0,1 % | indécise |
| reconnaissance / à tout prix | Escarmouche → Escarmouche | 5,6 | 5 385 / 1 400 | 10,0 | durée max. | 3,4 % / 0,1 % | indécise |
| limitée / retarder | Escarmouche → Escarmouche | 5,6 | 5 385 / 1 077 | 10,0 | durée max. | 1,2 % / 0,1 % | indécise |
| limitée / tenir | Limité → Limité | 14,0 | 13 461 / 3 500 | 20,0 | durée max. | 10,3 % / 0,5 % | défenseurs |
| limitée / à tout prix | Limité → Limité | 14,0 | 13 461 / 3 500 | 20,0 | durée max. | 10,3 % / 0,5 % | défenseurs |
| assaut / retarder | Limité → Escarmouche | 14,0 | 22 692 / 22 692 | 6,4 | rupture du défenseur | 6,9 % / 8,2 % | attaquants |
| assaut / tenir | Frontal → Frontal | 28,0 | 45 385 / 47 000 | 11,0 | rupture de l'attaquant | 39,6 % / 13,0 % | défenseurs |
| assaut / à tout prix | Frontal → Frontal | 28,0 | 45 385 / 47 000 | 11,1 | rupture de l'attaquant | 39,9 % / 12,9 % | défenseurs |

### 10.2 Les neuf combinaisons : Lorraine inversée (France → Allemagne ; défenseur plus faible)

| Approche / posture | Type prévu → réalisé | Durée | Fin | Pertes A / D | Vainqueur |
|---|---|---|---|---|---|
| reconnaissance / retarder | Escarmouche → Escarmouche | 2,8 min | rupture de l'attaquant | 1,2 % / 0,2 % | défenseurs |
| reconnaissance / tenir | Escarmouche → Escarmouche | 10,0 | durée max. | 3,2 % / 1,8 % | défenseurs |
| reconnaissance / à tout prix | Escarmouche → Escarmouche | 10,0 | durée max. | 3,2 % / 1,8 % | défenseurs |
| limitée / retarder | Escarmouche → Escarmouche | 10,0 | durée max. | 1,8 % / 2,2 % | défenseurs |
| limitée / tenir | Limité → Limité | 20,0 | durée max. | 8,0 % / 9,4 % | défenseurs |
| limitée / à tout prix | Limité → Limité | 20,0 | durée max. | 8,0 % / 9,4 % | défenseurs |
| assaut / retarder | Limité → Escarmouche | 3,5 | rupture du défenseur | 1,9 % / 9,7 % | attaquants |
| assaut / tenir | Frontal → Limité | 5,6 | rupture du défenseur | 5,5 % / 35,1 % | attaquants |
| assaut / à tout prix | Frontal → Frontal | 30,0 | durée max. | 29,9 % / **87,8 %** | attaquants |

**Conséquences observées des choix :**
- **Approche.** Elle change l'effectif engagé d'emblée (18 766 / 47 675 / 57 819 en Lorraine), la durée, le type et le niveau des pertes.
- **Posture, face à un assaut supérieur.** Pertes du défenseur : retarder 5 621 (la région est cédée en 3,5 min), tenir 20 285 (rupture à 5,6 min), tenir à tout prix 50 783 (combat jusqu'à 30 min, avec l'attaquant à 29,9 %).
- **Postures sans effet dans certains cas.** Quand le défenseur ne subit pas de pression (reconnaissance, attaque limitée contre une défense nombreuse), « tenir » et « tenir à tout prix » donnent le même résultat : la différence n'apparaît qu'au seuil de rupture.

### 10.3 Scénarios demandés, et comparaison avec l'ancien système

« Ancien » : moteur au commit `84340c3`, mêmes données. Il n'avait ni type d'engagement ni largeur de front, et l'attaquant y faisait un assaut implicite. « Nouveau » : approche et posture indiquées.

| Scénario | Nouveau : type prévu → réalisé ; front ; durée ; fin | Nouveau : pertes A / D | Ancien : durée ; fin | Ancien : pertes A / D |
|---|---|---|---|---|
| 1. Reconnaissance contre défense retranchée (tranchées niv. 2) | Escarmouche ; 5,6 km ; 10 min ; durée max. | 3,5 % / 0,1 % ; région conservée | — | — |
| 2. Attaque limitée contre défense normale | Limité ; 14 km ; 20 min ; durée max. | 10,3 % / 0,5 % | — | — |
| 3. Assaut contre position fortifiée (tranchées + 3 nids) | Frontal ; 28 km ; 13,5 min ; rupture de l'attaquant | 43,5 % / 15,2 % | 30 min ; durée max. | 68,7 % / 4,1 % |
| 4. Défense qui retarde (contre assaut) | Limité → escarmouche ; 6,4 min ; rupture du défenseur | 6,9 % / 8,2 % ; région cédée | — | — |
| 5. Défense à tout prix (contre assaut) | Frontal ; 11,1 min ; rupture de l'attaquant | 39,9 % / 12,9 % | — | — |
| Référence : Lorraine, assaut contre tenir | Frontal ; 28 km ; 11,0 min | 39,6 % / 13,0 % | 30 min (combat terminé vers 10 min) | 65,9 % / 4,5 % |
| 6. Terrain ouvert (France du Nord, secteur synthétique) | Grande bataille → frontal ; 72 km ; 5,1 min ; rupture du défenseur | 2,6 % / 43,2 % | 5,1 min ; un camp brisé | 4,2 % / 82,7 % |
| 7. Terrain difficile (Vénétie) | Frontal → limité ; 24 km ; 5,1 min ; rupture du défenseur | 5,2 % / 12,4 % | 30 min ; durée max. | 73,2 % / 40,6 % |
| 8. Grande ampleur (Lorraine après 3 mois de mobilisation) | Grande bataille → frontal ; 56 km ; 8,9 min ; rupture de l'attaquant | 15,2 % / 4,4 % | 30 min ; durée max. | 23,0 % / 0,2 % |
| 9. Renforts progressifs (Galicie) | Frontal → limité ; 28 km ; 7,5 min ; rupture du défenseur | 13,7 % / 13,9 % | 30 min ; durée max. | 78,5 % / 11,0 % |
| 10. Unités éprouvées (seconde bataille le mois suivant) | Frontal → limité ; 7,9 min ; rupture de l'attaquant | 31,3 % / 0,8 % | — | — |

**Lecture d'ensemble :**
- **Les combats ne vont plus jusqu'à l'anéantissement.** Les ruptures du combat ramènent la durée de 30 min à 5 à 14 min dans les assauts, et les pertes extrêmes de l'ancien système (66 à 92 % pour un camp) disparaissent, sauf choix explicite de tenir à tout prix.
- **La largeur du front rompt la loi « carrée ».** Le camp le plus nombreux ne peut plus mettre tout son effectif au feu : en Lorraine, le défenseur, deux fois plus nombreux, est limité au secteur. L'échange devient moins déséquilibré : le défenseur perd 13,0 % au lieu de 4,5 %, l'attaquant 39,6 % au lieu de 65,9 %.
- **Le volume total change, mais seulement à cause des nouvelles mécaniques** (rupture du combat, front). Aucun multiplicateur n'a été modifié. **Ce n'est pas un étalonnage.**

### 10.4 Vérifications de cohérence

| Vérification | Résultat |
|---|---|
| La largeur du front limite réellement les combattants simultanés | Oui. Place occupée au pic : 28 000 / 28 000 en assaut frontal, jamais au-delà, et des unités attendent. |
| Les réserves interviennent progressivement | Oui : délais d'engagement et d'arrivée inchangés. La Galicie (scénario 9) fait intervenir des renforts. |
| Les unités blessées ont une efficacité réduite | Oui : feu réduit dans le rapport capacité / effectif (0,750 pour 50 % de blessés légers). |
| Comptabilité de l'étape 1 intacte | Oui : tués + blessés + disparus + prisonniers = pertes, pour chaque bataille ; conservation nationale vérifiée dans chaque test. |
| Combats incohérents | Corrigés pendant l'étape : voir §13, points 1 et 2. |

## 11. Tests

| Commande | Résultat |
|---|---|
| `bash tests/run.sh`, sur ce poste | **109 réussis, 0 échec** ; interface stratégique VALIDÉE ; interface de bataille VALIDÉE |
| GitHub Actions | Voir §15 |

**Nouveau fichier `tests/unit/test_engagements.gd` (12 fonctions) :**

| Exigence | Test et ce qu'il démontre |
|---|---|
| Neuf combinaisons | `test_nine_combinations_rules` : type conforme à la matrice, durée plafonnée, nombre exact d'unités en réserve, seuil de rupture du défenseur (aucun à tout prix) ; `test_choices_have_consequences` : 6 batailles jouées montrent des effets mesurés (§10.2) |
| Classification | `test_classification_circumstances` : ampleur, terrain cloisonné, faibles effectifs, moral, encerclement, fortifications ; `test_realized_classification` : renforts → grande bataille, rupture précoce → un cran de moins |
| Largeur du front | `test_front_width_limits_simultaneous_combatants` : place occupée ≤ secteur à **chaque pas** d'une bataille complète, secteur réellement occupé, unités en attente, secteur variable selon le type, la région et la formation |
| Soldats en réserve, rotations et renforts | `test_waiting_units_and_rotation` : l'unité en attente ne tire pas, est moins exposée et relève l'unité épuisée ; `test_reserves_and_reinforcements` : les réserves de reconnaissance ne combattent pas, les délais sont conservés, pas d'unité sur deux fronts |
| Blessés légers | `test_lightly_wounded_reduce_capacity` : capacité, feu réduit, prorata des pertes, inscription après bataille, guérison, présents inchangés, état des forces |
| Conservation des effectifs | `_conserved` dans 5 tests, toutes postures et approches |
| Reproductibilité ; sauvegarde | `test_reproducibility_and_save_mid_battle` : résultats identiques ; sauvegarde en pleine bataille puis suite identique ; `test_legacy_battle_without_engagement` : bataille d'une ancienne sauvegarde |
| Formations, moral, fortifications | `test_compatibility_morale_formations_fortifications` : seuil de déroute selon la posture, tranchées et place sur le front, pas de retranchement en retardement |
| Ordres et IA | `test_orders_and_ai_defaults` : validation des ordres, posture appliquée, postures par défaut de l'IA |

**Tests d'interface :**
- `tests/ui_smoke.gd` : texte explicatif ; sélecteur d'approche avec effet réel sur l'ordre de déplacement ; sélecteur de posture avec effet réel sur l'ordre préparé.
- `tests/battle_ui_smoke.gd` : panneau d'engagement, place de l'unité, bouton « Rompre le combat » avec effet réel, type affiché au résultat.

**Tests anciens adaptés, avec explication :**
- **`test_casualty_accounting.gd::test_battle_winner_and_loser_routing`.** Avec les nouvelles mécaniques, l'attaquant vainqueur en Vénétie n'a plus aucune perte de déroute. L'assertion « pertes de déroute > 0 » est retirée ; la règle elle-même (déroute du vainqueur ventilée comme ordinaire, sans prisonnier) reste vérifiée sur la bataille et par le calcul exact de `test_winner_routing_booked_as_ordinary`.
- **Aucun autre test ancien n'a été modifié.** Deux tests de combat appelaient l'étape de tir directement ; j'ai déplacé la répartition du front dans cette étape plutôt que d'adapter les tests.

## 12. Vérifications visuelles

**Méthode :**
- Rendu réel, sous X (`tests/engagement_capture.gd`), dans `docs/project/captures_mil01/`.
- Les deux résolutions sont rendues dans une zone de rendu aux dimensions exactes. L'écran du poste fait 1 280 × 1 024 : une fenêtre de 1 600 × 900 y est impossible, et le gestionnaire de fenêtres ramène toute fenêtre à 1 214 × 955.

| Capture (1214×955 et 1600×900) | Constat |
|---|---|
| `10_armee_engagement_*` | Sélecteur « Approche offensive » et explication des types, du front et des blessés légers : lisible, sans débordement |
| `10b_armee_postures_*` | Sélecteur « Posture défensive » sous chaque armée : lisible |
| `11_bataille_front_*` | Panneau : type, choix, front (28 km, région 443 km, terrain 70 %), soldats en ligne, en attente et en réserve, seuil de rupture. L'unité sélectionnée affiche « en attente : pas de place sur le front ». Les unités en attente sont dessinées atténuées. |
| `12_resultat_engagement_*` | Résultat : « Type d'engagement : Engagement limité (prévu : Assaut frontal) », ventilation de l'étape 1 |
| `13_armee_blesses_legers_*` | Ligne d'unité : « dont 2 blessés légers (capacité 5 717) » |

**Défauts trouvés à l'écran et corrigés :**
1. **Panneau droit de la vue tactique, en 1214×955.** Les libellés longs des renforts élargissaient le panneau, ce qui coupait les lignes (défilement horizontal). C'était un défaut antérieur, révélé par les nouvelles lignes. Correction : libellés repliés et défilement horizontal désactivé.
2. **Avertissement de rupture du combat**, rouge foncé sur fond gris, peu lisible : couleur éclaircie.

**Limite connue, antérieure :** le panneau de résultat recouvre le journal.

## 13. Problèmes rencontrés et limites restantes

1. **Corrigé : dépassement des seuils de rupture.** Première version : un attaquant au seuil de 35 % finissait à 54 %, car les unités déjà en déroute étaient massacrées. Le seuil compte désormais les soldats **perdus ou en déroute**. Il reste des dépassements modérés quand un camp s'effondre en quelques pas (France du Nord : défenseur à 43 % pour un seuil de 30 %).
2. **Corrigé : unités éprouvées immobiles sous l'artillerie.** Dans la seconde bataille, l'attaquant restait 30 min hors de portée de tir mais sous le feu de l'artillerie. Ajout d'une rupture quand toutes les unités actives ont un moral inférieur à 30.
3. **Non corrigé (étape 3) :** les unités en déroute restent très vulnérables (vulnérabilité × 1,8, existante), et l'artillerie domine les engagements limités (attaquant 10,3 % contre 0,5 % en Lorraine). Ce sont des questions d'étalonnage.
4. **« Tenir à tout prix » face à un assaut très supérieur mène à la quasi-destruction** (87,8 %). C'est conforme à la consigne, mais il n'existe ni reddition tactique ni limite. À arbitrer (§14).
5. **L'IA stratégique choisit toujours l'assaut.** Ses postures par défaut sont simples : tenir à tout prix dans la région de la capitale, tenir ailleurs.
6. **Le renseignement de reconnaissance** est conservé et affiché au résultat, mais aucun autre système (IA, carte) ne l'exploite encore.
7. **Approche du joueur :** un seul sélecteur s'applique aux prochains ordres de déplacement, et non un choix ordre par ordre. L'ordre préparé affiche l'approche retenue.
8. **L'IA tactique n'organise pas elle-même les rotations.** Elles sont automatiques : priorité des unités fraîches au contact.

**Finalisé :** les mécaniques (choix, classification, front, rotations, rupture, capacité opérationnelle), leurs tests, l'interface et la compatibilité des sauvegardes.

**Provisoire :** **toutes les valeurs du §3**, les postures par défaut de l'IA et le choix d'approche de l'IA.

## 14. Décisions qui vous reviennent

| N° | Question | Proposition |
|---|---|---|
| **E1** | Valider les paramètres de conception du §3 (parts engagées, seuils de rupture, durées et secteurs, densités, efficacité 0,5 des blessés légers) comme base de l'étape 3 ? | Les valider comme base, à étalonner à l'étape 3 |
| **E2** | « Tenir à tout prix » face à un adversaire très supérieur : accepter la quasi-destruction, ou prévoir une reddition locale ou une limite ? | À traiter avec l'étape 3 |
| **E3** | Reconnaissance en force : pas d'occupation sans effondrement de la défense, issue indécise et renseignement. Convient-il ? Faut-il relier ce renseignement au système de renseignement (INT) ? | Oui ; liaison avec INT plus tard |
| **E4** | IA : postures par défaut (à tout prix dans la région de la capitale) et approche toujours « assaut ». Faut-il une IA d'approche plus fine (selon les forces estimées) ? | Lors des travaux sur l'IA stratégique |
| **E5** | Seuil de la grande bataille, 200 000 hommes : rarement atteint en janvier 1914, atteint dans les batailles de plusieurs armées et après mobilisation. Le confirmer ? | Le confirmer |

**Rappel des questions encore ouvertes de l'étape 1** (rapport de l'étape 1, §15) : déroute des unités anéanties d'un vainqueur (`annihilated_unit_routing_as_ordinary`) ; extension de la solution A aux issues indécises.

## 15. Commits, branche, GitHub Actions

- **Branche :** `dev/mil01-finalisation`.
- **Commits :**
  - `1850792` : feat, mécaniques, paramètres, tests ;
  - `6d0c77d` : docs, ce rapport, registre, documentation du combat, captures ;
  - puis ce complément du §15.
- **GitHub Actions :** exécution `43864330920` sur `6d0c77d`, **réussie**. Monde, scénarios et fiches à jour ; 109 tests réussis, 0 échec ; interfaces stratégique et de bataille VALIDÉES.
- **Aucune fusion.** `main`, `dev/historical-forces`, `dev/combat-system` et `audit/mil01-review` ne sont pas modifiées.
- **L'étape 3 (calibration) n'est pas commencée.**
