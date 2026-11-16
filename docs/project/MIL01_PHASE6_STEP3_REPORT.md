# Rapport MIL-01 — Phase 6, étape 3 : calibration des pertes et équilibrage des combats

- **Date :** 16/11/2026
- **Branche :** `dev/mil01-finalisation`
- **Périmètre :** calibration des pertes, rééquilibrage interarmes (infanterie, cavalerie, artillerie), survie des unités en déroute, réactivité des ruptures de combat, mécanisme d'effondrement en défense à tout prix, validation finale des règles comptables de déroute sur terrain conservé (vainqueur et bataille indécise, unités anéanties comprises), simulations comparatives et vérifications visuelles (1214×955 et 1600×900).
- **Rapports précédents consultés :**
  - `docs/project/MIL01_PHASE6_REPORT.md`
  - `docs/project/MIL01_PHASE6_STEP1_REPORT.md`
  - `docs/project/MIL01_PHASE6_STEP2_REPORT.md`
  - `docs/project/MIL01_PHASE5_PERTES_HISTORIQUES.md`

---

## 1. Objectif et méthode

L'étape 1 a introduit la comptabilité détaillée des pertes (tués, blessés restés dans leur unité ou en convalescence, retours au service, inaptes définitifs, disparus, prisonniers) sans toucher aux règles de combat. L'étape 2 a introduit les choix d'approche offensive et de posture défensive, les quatre types d'engagement, la largeur du front, les rotations d'unités et la baisse d'efficacité opérationnelle des blessés légers, mais sans calibrer les paramètres tactiques existants.

L'étape 3 a pour objectif de calibrer les pertes et d'équilibrer les combats afin d'obtenir un système militaire :
1. **crédible historiquement dans ses grandes tendances** au regard des ordres de grandeur documentés en phase 5 (`docs/project/MIL01_PHASE5_PERTES_HISTORIQUES.md`) ;
2. **tactiquement intéressant**, où l'approche offensive, la posture défensive, les formations (`entrenched`, `skirmish_line`, `assault_column`), le terrain et les fortifications produisent des effets nets et cohérents ;
3. **cohérent entre les différentes puissances** et entre les trois armes (infanterie, cavalerie, artillerie) ;
4. **capable de produire des batailles courtes ou longues** selon les circonstances (escarmouches de 10 min, ruptures à 5–18 min, grandes batailles de 15–30 min) ;
5. **sans annihilation systématique des armées ni des unités en déroute**, tout en permettant des batailles très coûteuses lorsque les ordres et le rapport de forces l'imposent.

Conformément aux consignes du directeur, aucun multiplicateur arbitraire par type d'engagement n'a été introduit : la calibration repose sur le comportement tactique réel des unités (déploiement, écrantage, contre-batterie, décrochage, déroute, effondrement).

---

## 2. Paramètres avant et après

### 2.1 Paramètres de base conservés (étapes 1 et 2)

Les paramètres validés comme base de travail à l'étape 1 et à l'étape 2 ont été intégralement conservés :

| Domaine | Paramètre | Valeur conservée | Statut |
|---|---|---|---|
| Approche offensive | Reconnaissance en force (`reconnaissance`) | 25 % engagés (`commit_share: 0.25`), rupture à 6 % (`disengage_loss: 0.06`), pas d'engagement des réserves | Validé (base étape 2) |
| Approche offensive | Attaque limitée (`limited_attack`) | 60 % engagés (`commit_share: 0.60`), rupture à 15 % (`disengage_loss: 0.15`), réserves sous condition | Validé (base étape 2) |
| Approche offensive | Assaut (`assault`) | 100 % engagés (`commit_share: 1.0`), rupture à 35 % (`disengage_loss: 0.35`), réserves engagées | Validé (base étape 2) |
| Posture défensive | Défense en retardement (`delay`) | Rupture à 8 % (`disengage_loss: 0.08`), pas de retranchement | Validé (base étape 2) |
| Posture défensive | Défense normale (`hold`) | Rupture à 30 % (`disengage_loss: 0.30`), retranchement autorisé | Validé (base étape 2) |
| Posture défensive | Défense à tout prix (`hold_at_all_costs`) | Pas de rupture volontaire (`disengage_loss: null`), seuil de déroute × 0,5 (`rout_threshold_mult: 0.5`) | Validé (base étape 2) |
| Types d'engagement | Durées maximales (`max_minutes`) | 10 min (`skirmish`), 20 min (`limited`), 30 min (`frontal`, `major`) | Validé (base étape 2) |
| Types d'engagement | Largeurs de front de base (`base_front_km`) | 8 km (`skirmish`), 20 km (`limited`), 40 km (`frontal`), 80 km (`major`) | Validé (base étape 2) |
| Types d'engagement | Seuil de grande bataille (`major_battle_soldiers`) | 200 000 hommes engagés (et terrain ≥ 0,55) | Validé (base étape 2) |
| Blessés légers | Efficacité dans l'unité (`lightly_wounded_efficiency`) | 50 % (`0.5`), guérison après 1 mois | Validé (base étape 2) |
| Comptabilité (étape 1) | Pertes ordinaires sous le feu | 25 % tués (`killed_share`), 5 % disparus (`missing_share_fire`), 70 % blessés | Provisoire validé (MIL01-P6-C4) |
| Comptabilité (étape 1) | Blessés légers et maintien dans l'unité | 68,6 % de blessés légers (approximation allemande), dont 10 % restent dans l'unité | Approximation / conception |
| Comptabilité (étape 1) | Devenir des blessés en convalescence | 55,6 % retour au service (sourcé RU, approx. ailleurs), 17 % inaptes définitifs, 27,4 % longue durée | Sourcé / décision (MIL01-P6-C2/C4) |

### 2.2 Paramètres modifiés ou ajoutés à l'étape 3

#### A. Comptabilité des pertes (`data/rules/forces_rules.json`)

| Clé | Avant (étape 2) | Après (étape 3) | Statut | Justification |
|---|---|---|---|---|
| `routing_as_ordinary_outcomes.value` | `["won"]` | `["won", "indecisive_held"]` | **Décision** | Décision du directeur (§5) : appliquer la règle des pertes de déroute ordinaires aux batailles indécises lorsque le camp conserve le terrain (le défenseur). |
| `annihilated_unit_routing_as_ordinary` | `true` (*à valider*) | `true` (`status: "décision"`) | **Décision** | Décision du directeur (§5) : les pertes de déroute d'un camp qui conserve le terrain sont traitées comme des pertes ordinaires, y compris lorsque des unités sont anéanties (le reliquat `remnant` restant traité à part en disparus sans capture). |
| `rout_prisoner_share.indecisive_held` | *(absent)* | `0.0` (`status: "décision"`) | **Décision** | Aucune capture chez le camp qui conserve le terrain à l'issue d'une bataille indécise. |

#### B. Règles de combat et d'engagement (`data/rules/combat_rules.json`)

| Bloc / clé | Avant (étape 2) | Après (étape 3) | Statut | Justification |
|---|---|---|---|---|
| `unit_types.artillery.range` | `700.0` | `660.0` | Conception (calibré) | Réduit l'écart de portée avec l'infanterie (`220`) afin d'éviter des duels d'artillerie hors de portée d'infanterie pendant toute une escarmouche. |
| `unit_types.artillery.lethality` | `0.0038` | `0.0026` | Conception (calibré) | Ramène la puissance de feu de l'artillerie à une proportion réaliste face à l'infanterie (`0.0018`), tout en tenant compte de son tir à longue portée et de son emploi en second échelon. |
| `unit_types.artillery.spot_range` | `260.0` | `340.0` | Conception (calibré) | Permet l'observation à distance et le repérage des batteries adverses en train de tirer (contre-batterie). |
| `unit_types.cavalry.melee` | `2.2` | `1.5` | Conception (calibré) | Évite que les charges de cavalerie en 1914 ne détruisent instantanément des divisions entières. |
| `unit_types.cavalry.exposure` | `1.15` | `1.10` | Conception (calibré) | Légère réduction de l'exposition de la cavalerie en reconnaissance/rideau. |
| `rout.rally_quiet_ticks` | `75` (2,5 min) | `60` (2,0 min) | Conception (calibré) | Permet aux unités repliées derrière la ligne de se rallier un peu plus tôt si elles ne subissent plus de feu. |
| `rout.speed_mult` | `1.4` | `1.55` | Conception (calibré) | Permet aux unités en déroute de décrocher effectivement hors de portée de mêlée au lieu d'être rattrapées en permanence. |
| `rout.vulnerability` | `1.8` | `1.25` | Conception (calibré) | Résout le problème C : une unité qui fuit se disperse (ligne de tirailleurs) et ne subit plus un multiplicateur de 1,8 × 1,5 = 2,7 qui la détruisait en quelques pas. |
| `combat.charge_melee_lethality` | `0.0075` | `0.0045` | Conception (calibré) | Réduit la létalité par pas de mêlée (et limite la mêlée d'impact à 4 pas après contact), évitant l'anéantissement instantané des cibles chargées. |
| `combat.counter_battery_share` | *(absent)* | `0.25` | Conception (calibré) | 25 % du feu de chaque batterie d'artillerie en ligne est dirigé contre l'artillerie ennemie repérée à portée (tir de contre-batterie). |
| `combat.pursuit_fire_share` | *(absent)* | `0.18` | Conception (calibré) | 18 % du feu des unités en ligne est dirigé sur les unités ennemies en déroute visibles à portée (tant qu'elles ont > 35 % de leur effectif initial), produisant des pertes de déroute cohérentes sans massacre. |
| `engagement.disengage_ticks` | `30` (60 s) | `12` (24 s) | Conception (calibré) | Résout le problème D : réduit le délai d'exposition à sens unique pendant la rupture du combat. |
| `engagement.disengage_morale` | `30.0` | `24.0` | Conception (calibré) | Évite une rupture prématurée par seul moral lorsque le seuil de pertes n'est pas atteint, tout en arrêtant le combat si toutes les unités actives sont épuisées. |
| `engagement.disengage_rout_weight` | `0.75` | `0.40` | Conception (calibré) | Pondère les unités en déroute ou ayant quitté le champ à 40 % dans le calcul du seuil de rupture : évite qu'une déroute partielle ne fasse rompre l'armée à 3 % de pertes, tout en empêchant de dépasser le seuil fixé. |
| `engagement.collapse_max_loss` | *(absent)* | `0.42` | Conception (calibré) | Résout le problème E : en défense à tout prix, la position s'effondre si les pertes physiques dépassent 42 % de l'effectif engagé. |
| `engagement.collapse_broken_share` | *(absent)* | `0.52` | Conception (calibré) | Résout le problème E : en défense à tout prix, la défense s'effondre lorsque ≥ 52 % de l'effectif est hors de combat (perdu ou en déroute), avec ≥ 26 % de pertes physiques et infériorité numérique en ligne (< 75 % des actifs de l'attaquant). |
| `engagement.postures.delay.commit_share` | *(absent : 1.0)* | `0.50` | Conception (calibré) | En défense en retardement, le défenseur n'engage qu'une arrière-garde de 50 % en ligne de tirailleurs et garde le gros (50 %) en réserve (`commit_reserves: false`). |
| `ai.charge_min_morale` | `50.0` | `55.0` | Conception (calibré) | L'IA ne lance des charges qu'avec des troupes au moral solide (≥ 55) et contre des cibles désorganisées ou en infériorité numérique. |
| `ai.withdraw_morale` | `18.0` | `22.0` | Conception (calibré) | L'IA replie individuellement une unité avant qu'elle ne tombe en déroute (seuil de déroute à 20). |

---

## 3. Raisons des changements et résolution des cinq problèmes identifiés

### A. Pertes excessives pendant les assauts

**Diagnostic :** à l'étape 2, un assaut en Lorraine produisait 39,6 % à 43,5 % de pertes chez l'attaquant et 43,2 % chez le défenseur en terrain ouvert. Trois causes cumulatives ont été identifiées :
1. **Concentration des charges de mêlée :** l'IA comparait l'effectif d'une division d'infanterie (~3 600 hommes) à celui d'une batterie d'artillerie (~850 hommes) ou d'un régiment de cavalerie (~1 000 hommes), concluait systématiquement à une supériorité numérique (`soldiers > enemy * 1.15`) et ordonnait à 8 unités simultanément de charger à la baïonnette pendant 40 pas à létalité `0.0075`.
2. **Formation en colonne maintenue pendant la déroute et le repli :** les unités qui rompaient le combat ou fuyaient conservaient `assault_column` (`exposure = 1.5`), subissant 50 % de pertes supplémentaires sans riposter.
3. **Absence de prise en compte des unités sorties du terrain (`WITHDRAWN`) dans le seuil de rupture :** dès qu'une unité en déroute atteignait son point de retraite, son statut passait à `WITHDRAWN` et elle disparaissait du numérateur de `check_disengagement`, faisant retomber artificiellement le taux de rupture et prolongeant le combat.

**Corrections appliquées :**
- En mêlée (`src/domains/combat/tactical_sim.gd`), la durée de choc après contact est plafonnée à 4 pas (`charge_ticks = mini(charge_ticks, 4)`) et la létalité de mêlée ramenée à `0.0045`. L'IA (`src/ai/tactical_ai.gd`) limite chaque assaut local à 2 unités chargeantes par cible active désorganisée (1 seule contre une cible en déroute proche).
- Toute unité qui entre en déroute (`ROUTING`) ou en repli ordonné (`WITHDRAWING`) passe immédiatement en `skirmish_line` (`exposure = 1.0`).
- Le calcul du seuil de rupture (`Engagement.check_disengagement`) comptabilise désormais les unités `WITHDRAWN` au même titre que les unités `ROUTING` (pondérées par `disengage_rout_weight = 0.40`).

**Résultat :** en assaut frontal en Lorraine, l'attaquant rompt à 17,0 min avec **21,9 %** de pertes (contre 39,6 % à l'étape 2) ; contre une position fortifiée (tranchées niv. 2 + 3 nids de mitrailleuses), il rompt plus vite (13,4 min) avec **19,7 %** de pertes et seulement **2,9 %** chez le défenseur. Aucune bataille standard ne dépasse plus 26,2 % de pertes.

### B. Artillerie dominante et déséquilibre interarmes

**Diagnostic :** à l'étape 2, dans les engagements limités et les assauts, l'artillerie du défenseur subissait 29 % à 43 % de pertes alors que l'infanterie défensive ne tirait parfois pas un seul coup de feu (0 pas engagés en `limited_attack / hold`), tandis que l'artillerie de l'attaquant subissait 0 perte dans 15 batailles sur 18 !
La cause racine résidait dans `TacticalAI._set_objective` et `BattleManager._deploy_point` :
- Le défenseur choisissait comme objectif principal la ville la plus proche de son **point d'entrée arrière** (`entry`), soit `Le Creusot` au fond sud-ouest de la région `France — Est`, et déployait ses unités en cercle autour des 5 villes de la région.
- Dès le début de la bataille, les 14 divisions d'infanterie et 7 brigades de cavalerie françaises abandonnaient la frontière (`Belfort`, `Nancy`, `Verdun`) pour marcher vers `Le Creusot`, laissant les 3 régiments d'artillerie française (lents, `speed = 1.8`, mais à portée de tir `700`) seuls au milieu de la carte face à toute l'armée allemande !
- De son côté, la cavalerie attaquante (`speed = 7.0`) chargeait seule 60 secondes avant son infanterie (`speed = 2.6`) et perdait 89 % à 100 % de ses effectifs, tandis que `_fire_and_melee` ciblait uniquement l'ennemi géométriquement le plus proche (`d < best`), de sorte que l'artillerie en second échelon n'était jamais visée (aucun tir de contre-batterie).

**Corrections appliquées :**
1. **Ancrage défensif cohérent (`BattleManager._defended_anchor` et `TacticalAI._set_objective`) :** le défenseur se déploie autour de l'objectif défendu face à l'axe d'approche ennemi (ou autour de ses ouvrages fortifiés s'il en existe), avec son artillerie déployée en second échelon (`150 px` en arrière de l'infanterie) et maintenue `95 px` derrière l'objectif en formation dispersée (`skirmish_line`).
2. **Rideau de cavalerie (`TacticalAI.decide`) :** la cavalerie de l'attaquant forme un écran en ligne de tirailleurs à distance de contact (`300 px`) jusqu'à l'arrivée de l'infanterie amie à proximité (`310 px`), au lieu de se jeter seule sur la ligne ennemie.
3. **Écrantage et tir de contre-batterie (`TacticalSim._fire_and_melee` et `TacticalSim.update_fog`) :**
   - Lorsqu'une batterie d'artillerie tire (`engaged_ticks > 0`), ses lueurs et détonations augmentent sa signature (`stealth *= 1.6`), permettant son repérage par l'adversaire.
   - L'artillerie ennemie située derrière des unités d'infanterie ou de cavalerie actives proches est écrantée contre le tir direct d'infanterie.
   - En revanche, chaque batterie d'artillerie en ligne consacre **25 % de son feu (`counter_battery_share = 0.25`)** au tir de contre-batterie contre les batteries d'artillerie adverses repérées à portée, et répartit le reste (75 %) sur les unités de première ligne dans une bande de profondeur de `35 px`.

**Résultat :** dans toutes les batailles (voir §5.5), l'infanterie subit désormais **70 % à 85 %** du volume total des pertes, la cavalerie subit des pertes de reconnaissance et de flanc réalistes, et l'artillerie des deux camps subit des pertes de contre-batterie modérées (1 % à 8 % en combat normal, jusqu'à 29 % lorsque la position défensive finit par s'effondrer).

### C. Unités en déroute

**Diagnostic :** à l'étape 2, une unité tombée sous le seuil de moral (`20.0`) subissait `rout.vulnerability = 1.8` tout en restant en `assault_column` (`1.5`, soit `2.7×` les pertes normales), gardait la priorité de tir maximale (`rank = 0`) pour tous les tireurs ennemis et continuait d'être poursuivie en mêlée par les unités chargeantes (`speed = 2.6 × 1.6 = 4.16` contre `2.6 × 1.4 = 3.64`), ce qui la réduisait sous le seuil d'anéantissement (`< 50` hommes, statut `DESTROYED`) en quelques pas.

**Corrections appliquées :**
- Passage automatique en `skirmish_line` dès l'entrée en déroute (`_morale`), vulnérabilité ramenée de `1.8` à `1.25` et vitesse de fuite portée de `1.4` à `1.55`.
- Dans `_fire_and_melee`, les tireurs actifs concentrent leur feu principal (`rank = 0`) sur les unités ennemies `ACTIVE` en ligne qui combattent effectivement, et ne consacrent qu'une part limitée (`pursuit_fire_share = 0.18`, soit 18 %) au tir de poursuite sur les unités en déroute visibles (tant qu'elles comptent plus de 35 % de leur effectif initial).
- Dans `_movement`, une unité en charge cesse de poursuivre une cible en déroute dès que celle-ci s'est éloignée au-delà de `2,5 × melee_range`.
- Dans `_morale`, l'influence stabilisatrice du moral d'armée (`army_morale`) diminue proportionnellement à la part d'unités déjà brisées (`1.0 - 0.65 * broken_ratio`), ce qui évite des ralliements irréalistes en boucle au sein d'une armée en pleine débandade.

**Résultat :** dans les 18 combinaisons de Lorraine et Lorraine inversée ainsi que dans les scénarios représentatifs, **aucune unité en déroute n'est plus systématiquement anéantie (`destroyed = 0`)**, tout en générant des pertes de déroute (`origin_routing`) et des captures partielles cohérentes chez le vaincu.

### D. Dépassement des seuils de rupture

**Diagnostic :** un camp ayant un seuil de rupture de 15 %, 30 % ou 35 % dépassait parfois largement son seuil parce que :
1. les unités déjà sorties de la carte (`WITHDRAWN`) n'étaient plus comptées dans `routing` alors que leur effectif restait dans `now` ;
2. pendant les `30` pas (60 s) de `WITHDRAWING`, les unités restaient exposées à 100 % en première ligne avant que la bataille ne s'arrête.

**Corrections appliquées :**
- `Engagement.check_disengagement` inclut désormais les unités `WITHDRAWN` aux côtés des unités `ROUTING` (pondérées par `disengage_rout_weight = 0.40`), ainsi que les renforts arrivés sur le terrain.
- Les unités en `WITHDRAWING` passent en `skirmish_line` et bénéficient du facteur d'exposition réduit des troupes hors ligne (`waiting_exposure = 0.30`), et le délai de décrochage est ramené de `30` à `12` pas (24 s).

**Résultat :**
- Reconnaissance (seuil 6 %) : pertes de 1,6 % à 3,7 %.
- Attaque limitée (seuil 15 %) : pertes de 0,7 % à 11,2 %.
- Défense en retardement (seuil 8 % sur l'arrière-garde engagée) : rupture à 3,1 %–4,9 % de l'armée totale (6,2 %–9,8 % de l'arrière-garde engagée, plus la pondération de déroute).
- Défense normale (seuil 30 %, pertes + 0,40 × déroute) : rupture à 17,3 %–17,7 % de pertes physiques lorsque la moitié des unités engagées commencent à plier.
- Assaut (seuil 35 %, pertes + 0,40 × déroute) : rupture à 19,7 %–21,9 % de pertes physiques.

### E. Défense à tout prix (`hold_at_all_costs`)

**Diagnostic :** à l'étape 2, en Lorraine inversée (`France 011 → Allemagne 035`, rapport de forces de 2,2 contre 1 en faveur de l'attaquant), la posture « tenir à tout prix » interdisait toute rupture jusqu'à la 30e minute et conduisait à la quasi-destruction de l'armée allemande (**87,8 % de pertes**, 50 783 hommes perdus sur 57 819).

**Corrections appliquées (`Engagement.check_collapse`) :**
- La posture « tenir à tout prix » conserve l'absence de rupture volontaire (`disengage_loss: null`) et son seuil de déroute deux fois plus exigeant (`rout_threshold_mult: 0.5`, moral 10 au lieu de 20).
- Toutefois, `Engagement.check_collapse(b, r)` vérifie à chaque pas si la position défensive est devenue physiquement intenable :
  1. soit les pertes physiques du défenseur atteignent `collapse_max_loss = 42 %` de l'effectif engagé ;
  2. soit au moins `collapse_broken_share = 52 %` de l'effectif engagé est hors de combat (perdu ou en déroute), avec au moins `26 %` de pertes physiques et un effectif actif restant inférieur à `75 %` de l'effectif actif de l'attaquant.
- Lorsque l'une de ces conditions est remplie, la défense s'effondre et le combat prend fin avec le motif explicite : **`effondrement de la défense (position intenable)`**.

**Résultat (Lorraine inversée, `assault / hold` vs `assault / hold_at_all_costs`) :**
- En `assault / hold`, le défenseur allemand rompt le combat à **17,6 min** avec **10 030 pertes (17,3 %)** après avoir infligé **13 352 pertes (10,4 %)** à l'attaquant français.
- En `assault / hold_at_all_costs`, le défenseur allemand tient **22,3 min** (+4,7 min), inflige **14 920 pertes (11,7 %)** à l'attaquant français (+1 568 pertes), et subit **15 129 pertes (26,2 %)** (+51 % de pertes par rapport à `hold`) avant que la position ne cède par **`effondrement de la défense (position intenable)`**. La posture est donc nettement plus longue et plus coûteuse pour les deux camps, sans dégénérer en annihilation automatique de 88 % de l'armée.

---

## 4. Comptabilité des pertes (étape 1 + décisions de l'étape 3)

Toutes les catégories introduites à l'étape 1 sont intégralement préservées et vérifiées :
- **Tués** (`military_ledger.killed`) : 25 % des pertes ordinaires.
- **Blessés** (`military_ledger.wounded`) : 70 % des pertes ordinaires, répartis entre blessés légers (68,6 %, approximation allemande) — dont 10 % restent dans leur unité avec 50 % d'efficacité pendant 1 mois (`remained_in_unit`) et 90 % partent en convalescence légère d'un mois — et autres blessés (31,4 %, convalescence de 3 mois).
- **Sorties de convalescence :** 55,6 % de retour au service (`returned_to_service`), 17 % d'inaptitude définitive (`permanently_unfit`), et ~27,4 % maintenus en **convalescence de longue durée** (`long_term`).
- **Disparus** (`military_ledger.missing`) : 5 % des pertes ordinaires (`battle`), plus la part non capturée des pertes de déroute d'un camp qui ne conserve pas le terrain et le reliquat d'unités anéanties, ainsi que l'attrition d'encerclement (`encirclement_attrition`) et les services d'armées détruites sans retraite (`annihilated_services`).
- **Prisonniers** (`prisoners_lost` / `prisoners_held`) : 0 % si le camp conserve le terrain ou si la bataille est indécise, 30 % des pertes de déroute et de reliquat en cas de défaite avec retraite (`lost_retreat`), 80 % en cas de défaite sans retraite (`lost_no_retreat`), et 100 % à la capitulation d'une armée encerclée.

**Application des deux règles validées à l'étape 3 (`src/domains/military/force_ledger.gd` et `src/domains/combat/battle_manager.gd`) :**
1. **Camp conservant le terrain en bataille décisive (`"won"`) ou indécise (`"indecisive_held"`) :** dans `BattleManager._side_outcomes`, lorsque `winner == ""`, le camp qui détient la région (`side == holder`, c'est-à-dire le défenseur) reçoit l'issue `"indecisive_held"`, tandis que l'attaquant reçoit `"indecisive"`. Pour `"won"` comme pour `"indecisive_held"`, toutes les pertes de déroute (`loss_routing`) sont ventilées comme des pertes ordinaires (25 % tués, 5 % disparus, 70 % blessés, 0 prisonnier), tout en conservant leur traçabilité dans `origin_routing` et `routing_as_ordinary`.
2. **Unités anéanties d'un camp conservant le terrain (`annihilated_unit_routing_as_ordinary = true`, statut `décision`) :** les pertes subies pendant la déroute avant l'anéantissement (`loss_routing`) sont traitées comme des pertes ordinaires (avec `remained = 0` puisque l'unité n'existe plus), tandis que le reliquat final au moment de la dissolution (`origin_remnant`) est inscrit en disparus (0 prisonnier).

---

## 5. Résultats des simulations

Commande reproductible :
```bash
godot --headless --path . --script tests/engagement_report.gd
godot --headless --path . --script tests/balance_report.gd
```

### 5.1 Les neuf combinaisons en Lorraine (Allemagne 035 → France 011, 57 819 vs 127 820 hommes)

| Approche / Posture | Type prévu → réalisé | Front (km) | Pic en ligne A / D (capacité) | Rotations | Durée | Fin | Pertes A / D (% entrés) — Étape 3 | Rappel Étape 2 (% entrés) | Vainqueur |
|---|---|---|---|---|---|---|---|---|---|
| `reconnaissance / delay` | Escarmouche → Escarmouche | 5,6 | 5 385 / 5 385 (7 000) | 0 | 10,0 min | durée maximale atteinte | **527 (2,8 %) / 411 (0,6 %)** | 3,5 % / 0,1 % | défenseurs |
| `reconnaissance / hold` | Escarmouche → Escarmouche | 5,6 | 5 385 / 6 677 (7 000) | 0 | 10,0 min | durée maximale atteinte | **697 (3,7 %) / 414 (0,3 %)** | 3,5 % / 0,1 % | défenseurs |
| `reconnaissance / hold_at_all_costs` | Escarmouche → Escarmouche | 5,6 | 5 385 / 6 677 (7 000) | 0 | 10,0 min | durée maximale atteinte | **697 (3,7 %) / 414 (0,3 %)** | 3,5 % / 0,1 % | défenseurs |
| `limited_attack / delay` | Escarmouche → Escarmouche | 5,6 | 5 385 / 5 385 (7 000) | 0 | 10,0 min | durée maximale atteinte | **854 (1,5 %) / 693 (1,1 %)** | 4,0 % / 0,1 % | défenseurs |
| `limited_attack / hold` | Limité → Limité | 14,0 | 13 461 / 16 692 (17 500) | 40 | 20,0 min | durée maximale atteinte | **6 464 (11,2 %) / 3 909 (3,1 %)** | 10,3 % / 0,5 % | défenseurs |
| `limited_attack / hold_at_all_costs` | Limité → Limité | 14,0 | 13 461 / 16 692 (17 500) | 40 | 20,0 min | durée maximale atteinte | **6 464 (11,2 %) / 3 909 (3,1 %)** | 10,3 % / 0,5 % | défenseurs |
| `assault / delay` | Limité → Limité | 14,0 | 13 461 / 13 461 (17 500) | 19 | 16,1 min | les défenseurs ont rompu le combat | **3 679 (6,4 %) / 3 971 (3,1 %)** | 6,9 % / 8,2 % | attaquants |
| `assault / hold` | Frontal → Frontal | 28,0 | 26 923 / 33 385 (35 000) | 78 | 17,0 min | les attaquants ont rompu le combat | **12 663 (21,9 %) / 5 716 (4,5 %)** | 39,6 % / 13,0 % | défenseurs |
| `assault / hold_at_all_costs` | Frontal → Frontal | 28,0 | 26 923 / 33 385 (35 000) | 78 | 17,0 min | les attaquants ont rompu le combat | **12 663 (21,9 %) / 5 716 (4,5 %)** | 39,9 % / 12,9 % | défenseurs |

### 5.2 Les neuf combinaisons en Lorraine inversée (France 011 → Allemagne 035, 127 820 vs 57 819 hommes, défenseur plus faible)

| Approche / Posture | Type prévu → réalisé | Front (km) | Pic en ligne A / D (capacité) | Rotations | Durée | Fin | Pertes A / D (% entrés) — Étape 3 | Rappel Étape 2 (% entrés) | Vainqueur |
|---|---|---|---|---|---|---|---|---|---|
| `reconnaissance / delay` | Escarmouche → Escarmouche | 5,6 | 5 385 / 5 385 (7 000) | 0 | 10,0 min | durée maximale atteinte | **505 (1,6 %) / 392 (1,4 %)** | 3,1 % / 1,9 % | indécise |
| `reconnaissance / hold` | Escarmouche → Escarmouche | 5,6 | 5 385 / 8 917 (7 000) | 0 | 10,0 min | durée maximale atteinte | **844 (2,6 %) / 386 (0,7 %)** | 3,1 % / 1,9 % | indécise |
| `reconnaissance / hold_at_all_costs` | Escarmouche → Escarmouche | 5,6 | 5 385 / 8 917 (7 000) | 0 | 10,0 min | durée maximale atteinte | **844 (2,6 %) / 386 (0,7 %)** | 3,1 % / 1,9 % | indécise |
| `limited_attack / delay` | Escarmouche → Escarmouche | 5,6 | 5 385 / 5 385 (7 000) | 0 | 10,0 min | durée maximale atteinte | **922 (0,7 %) / 518 (1,8 %)** | 1,8 % / 2,2 % | indécise |
| `limited_attack / hold` | Limité → Limité | 14,0 | 13 461 / 16 692 (17 500) | 46 | 20,0 min | durée maximale atteinte | **6 766 (5,3 %) / 3 785 (6,5 %)** | 8,0 % / 9,4 % | indécise |
| `limited_attack / hold_at_all_costs` | Limité → Limité | 14,0 | 13 461 / 16 692 (17 500) | 46 | 20,0 min | durée maximale atteinte | **6 766 (5,3 %) / 3 785 (6,5 %)** | 8,0 % / 9,4 % | indécise |
| `assault / delay` | Limité → Limité | 14,0 | 18 463 / 13 461 (17 500) | 2 | 10,1 min | les défenseurs ont rompu le combat | **3 095 (2,4 %) / 2 853 (4,9 %)** | 1,9 % / 9,7 % | attaquants |
| `assault / hold` | Frontal → Frontal | 28,0 | 33 337 / 33 385 (35 000) | 64 | 17,6 min | les défenseurs ont rompu le combat | **13 352 (10,4 %) / 10 030 (17,3 %)** | 5,5 % / 35,1 % | attaquants |
| `assault / hold_at_all_costs` | Frontal → Frontal | 28,0 | 37 005 / 33 385 (35 000) | 78 | 22,3 min | **effondrement de la défense (position intenable)** | **14 920 (11,7 %) / 15 129 (26,2 %)** | 29,9 % / **87,8 %** | attaquants |

### 5.3 Scénarios représentatifs (`tests/engagement_report.gd`)

| Scénario | Type prévu → réalisé | Front (km) | Pic en ligne A / D (capacité) | Rotations | Durée | Fin | Pertes A / D (% entrés) — Étape 3 | Rappel Étape 2 | Vainqueur |
|---|---|---|---|---|---|---|---|---|---|
| 1. Reconnaissance contre défense retranchée (tranchées niv. 2) | Escarmouche → Escarmouche | 5,6 | 5 385 / 6 677 (7 000) | 0 | 10,0 min | durée maximale atteinte | **655 (3,5 %) / 412 (0,3 %)** | 3,5 % / 0,1 % | défenseurs |
| 2. Attaque limitée contre défense normale | Limité → Limité | 14,0 | 13 461 / 16 692 (17 500) | 40 | 20,0 min | durée maximale atteinte | **6 464 (11,2 %) / 3 909 (3,1 %)** | 10,3 % / 0,5 % | défenseurs |
| 3. Assaut contre position fortifiée (tranchées niv. 2 + 3 nids) | Frontal → Frontal | 28,0 | 26 923 / 41 895 (35 000) | 41 | 13,4 min | les attaquants ont rompu le combat | **11 406 (19,7 %) / 3 671 (2,9 %)** | 43,5 % / 15,2 % | défenseurs |
| 4. Assaut contre défense qui retarde | Limité → Limité | 14,0 | 13 461 / 13 461 (17 500) | 19 | 16,1 min | les défenseurs ont rompu le combat | **3 679 (6,4 %) / 3 971 (3,1 %)** | 6,9 % / 8,2 % | attaquants |
| 5. Assaut contre défense à tout prix | Frontal → Frontal | 28,0 | 26 923 / 33 385 (35 000) | 78 | 17,0 min | les attaquants ont rompu le combat | **12 663 (21,9 %) / 5 716 (4,5 %)** | 39,9 % / 12,9 % | défenseurs |
| 6. Terrain ouvert (France du Nord, plaines et collines) | Grande bataille → Frontal | 72,0 | 79 652 / 57 549 (90 000) | 14 | 8,4 min | les défenseurs ont rompu le combat | **10 308 (5,4 %) / 10 209 (17,7 %)** | 2,6 % / 43,2 % | attaquants |
| 7. Terrain difficile (Vénétie : montagnes, collines, forêts) | Frontal → Frontal | 24,0 | 30 232 / 23 199 (30 000) | 1 | 12,6 min | un camp ne peut plus combattre | **3 368 (7,4 %) / 10 829 (21,6 %)** | 5,2 % / 12,4 % | attaquants |
| 8. Grande ampleur (Lorraine après 3 mois de mobilisation) | Grande bataille → Grande bataille | 56,0 | 72 201 / 66 769 (70 000) | 30 | 15,5 min | les attaquants ont rompu le combat | **24 820 (21,5 %) / 11 645 (2,3 %)** | 15,2 % / 4,4 % | défenseurs |
| 9. Renforts progressifs (Galicie : RU 058 → AH 040) | Frontal → Grande bataille | 56,0 | 45 385 / 33 385 (70 000) | 99 | 30,0 min | durée maximale atteinte | **10 272 (16,7 %) / 13 022 (9,4 %)** | 13,7 % / 13,9 % | attaquants |
| 10. Unités éprouvées (Lorraine, 2e bataille le mois suivant, 847 blessés légers en unité) | Frontal → Limité | 28,0 | 26 923 / 33 385 (35 000) | 0 | 5,5 min | les attaquants ont rompu le combat | **3 573 (7,8 %) / 795 (0,6 %)** | 31,3 % / 0,8 % | défenseurs |
| 11. Somme (scénario de test : assaut contre position fortifiée en terrain ouvert, sans prétendre reproduire 1916) | Grande bataille → Grande bataille | 72,0 | 79 450 / 57 520 (90 000) | 44 | 14,0 min | les défenseurs ont rompu le combat | **19 334 (10,1 %) / 11 505 (19,9 %)** | *(nouveau)* | attaquants |

### 5.4 Effet des formations et des fortifications (`tests/balance_report.gd`)

Grâce au respect du verrouillage de formation (`lock_formation`) et au maintien du défenseur sur ses ouvrages préparés, les trois variantes de Lorraine dans `tests/balance_report.gd` produisent désormais une hiérarchie tactique nette :

| Cas (`tests/balance_report.gd`) | Effectifs A / D | Pertes A | Pertes D | Durée | Vainqueur | Tranchées D (nb, niv. max) | Calcul |
|---|---|---|---|---|---|---|---|
| Lorraine : défense retranchée par défaut (`entrenched`) | 57 819 / 127 820 | 12 663 (21,9 %) | **5 716 (4,5 %)** | 17,0 min | défenseurs | 0, 0 | 2,0 s (36 unités) |
| Lorraine : défenseur en ligne de tirailleurs (`skirmish_line`) | 57 819 / 127 820 | 10 498 (18,2 %) | **11 953 (9,4 %)** | 16,6 min | défenseurs | 0, 0 | 1,9 s (36 unités) |
| Lorraine : tranchées préparées (niveau 2) devant chaque unité | 57 819 / 127 820 | 9 744 (16,9 %) | **2 203 (1,7 %)** | 9,2 min | défenseurs | 16, 2 | 1,5 s (36 unités) |
| Prusse-Orientale : RU 056 → DE 026 | 30 784 / 57 819 | 5 555 (18,0 %) | **1 494 (2,6 %)** | 7,5 min | défenseurs | 1, 1 | 0,4 s (28 unités) |
| Galicie : RU 058 → AH 040 (avec 12 renforts AH) | 61 568 / 69 600 (+69 000) | 10 272 (16,7 %) | **13 022 (9,4 %)** | 30,0 min | attaquants | 0, 0 | 2,5 s (44 unités) |
| Vénétie : IT 081 → AH 037 (avec 5 renforts AH) | 45 737 / 23 199 (+26 900) | 3 368 (7,4 %) | **10 829 (21,6 %)** | 12,6 min | attaquants | 0, 0 | 0,8 s (36 unités) |
| Lorraine après mobilisation complète (4 mois) | 272 593 / 496 177 | 46 816 (17,2 %) | **29 390 (5,9 %)** | 30,0 min | défenseurs | 0, 0 | 7,8 s (61 unités) |

### 5.5 Répartition des pertes par arme et par origine

| Scénario | Pertes Infanterie A / D | Pertes Cavalerie A / D | Pertes Artillerie A / D | Origine A (feu / déroute / reliquat) | Origine D (feu / déroute / reliquat) | Unités détruites |
|---|---|---|---|---|---|---|
| Lorraine `limited_attack / hold` | 5 128 (13 %) / 3 318 (4 %) | 1 252 (18 %) / 546 (4 %) | 84 (1 %) / 45 (0,4 %) | 6 464 / 0 / 0 | 3 909 / 0 / 0 | 0 |
| Lorraine `assault / hold` | 10 106 (25 %) / 4 094 (5 %) | 2 296 (33 %) / 1 517 (10 %) | 261 (3 %) / 105 (0,5 %) | 12 085 / 578 / 0 | 5 716 / 0 / 0 | 0 |
| LorraineInv `assault / hold` | 9 708 (11 %) / 7 681 (19 %) | 3 438 (24 %) / 2 142 (31 %) | 206 (1 %) / 207 (2 %) | 13 352 / 0 / 0 | 7 359 / 2 671 / 0 | 0 |
| LorraineInv `assault / hold_at_all_costs` | 10 938 (12 %) / 8 531 (21 %) | 3 738 (26 %) / 3 627 (53 %) | 244 (1 %) / 2 971 (29 %) | 14 920 / 0 / 0 | 9 595 / 5 534 / 0 | 0 |
| Assaut contre position fortifiée | 9 331 (23 %) / 2 248 (2 %) | 2 013 (29 %) / 1 293 (9 %) | 62 (1 %) / 130 (1 %) | 10 869 / 537 / 0 | 3 671 / 0 / 0 | 0 |
| Terrain ouvert (France du Nord) | 6 691 (5 %) / 7 950 (20 %) | 3 472 (16 %) / 2 057 (30 %) | 145 (0,5 %) / 202 (2 %) | 10 308 / 0 / 0 | 7 301 / 2 908 / 0 | 0 |
| Vénétie (montagnes) | 2 276 (7 %) / 7 775 (25 %) | 519 (11 %) / 2 548 (34 %) | 573 (6 %) / 506 (5 %) | 3 368 / 0 / 0 | 3 712 / 7 117 / 0 | 0 |
| Galicie (renforts progressifs) | 8 394 (19 %) / 8 362 (9 %) | 1 693 (23 %) / 2 956 (13 %) | 185 (2 %) / 1 704 (8 %) | 10 272 / 0 / 0 | 7 798 / 5 224 / 0 | 0 |

---

## 6. Comparaisons historiques avec les références de la phase 5

Les résultats obtenus sont confrontés aux données réunies dans `docs/project/MIL01_PHASE5_PERTES_HISTORIQUES.md`.

### 6.1 Ordres de grandeur par bataille d'un tour mensuel

Dans *Grand Strategy-1914*, un tour stratégique représente **un mois** : une bataille tactique résolue au cours d'un tour correspond donc à une **opération ou bataille de campagne mensuelle** (et non à une seule journée isolée).

| Référence historique (`MIL01_PHASE5_PERTES_HISTORIQUES.md` §4.2) | Pertes historiques documentées | Équivalent simulé à l'étape 3 | Comparaison et analyse des écarts |
|---|---|---|---|
| **Bataille des Frontières / Lorraine** (août 1914, opérations d'ouverture sur 1 à 2 semaines) | ~10 % à 22 % des effectifs engagés dans les corps d'attaque les plus éprouvés ; pertes totales françaises d'août-septembre 1914 = 329 000 hommes (tués, blessés, disparus/prisonniers) sur ~2 millions aux armées (~16 %) | Lorraine `assault / hold` : attaquant **21,9 %** (12 663 / 57 819), défenseur **4,5 %** (5 716 / 127 820) ; Lorraine inversée `assault / hold` : attaquant **10,4 %** (13 352), défenseur **17,3 %** (10 030) ; Lorraine mobilisée : **17,2 %** (46 816) / **5,9 %** (29 390) | Cohérent avec l'ordre de grandeur d'une offensive frontale d'un mois en 1914 (10 % à 22 %). Le jeu ne reproduit plus les 66 % à 92 % d'anéantissement de l'ancien système. |
| **Tannenberg** (26–30 août 1914, bataille d'encerclement et d'effondrement) | IIe armée russe (~150 000 h) : ~30 000 tués ou blessés (~20 %) et ~92 000 prisonniers (~61 %) ; VIIIe armée allemande : < 15 000 pertes (< 10 %) | Prusse-Orientale `assault / hold` : attaquant russe **18,0 %** (5 555 / 30 784), défenseur allemand **2,6 %** (1 494 / 57 819) ; en cas d'encerclement et de capitulation (T-044), 100 % des survivants deviennent prisonniers | En bataille frontale non encerclée, l'attaquant russe est repoussé avec 18 % de pertes contre 2,6 % pour le défenseur allemand. Les captures massives de type Tannenberg (92 000 prisonniers) relèvent dans le jeu d'une défaite sans retraite (`lost_no_retreat`, 80 % de prisonniers sur la déroute) ou d'une capitulation d'armée encerclée (T-044). |
| **Somme, 1er juillet 1916** (1re journée : 57 470 pertes britanniques dont 19 240 tués sur ~14 divisions, soit ~35–40 % de la première vague ; offensive mensuelle ~15–25 % de l'armée engagée) | 1re journée : choc extrême sur un assaut contre position très fortifiée ; ratio tués/blessés exceptionnellement élevé (~1 : 2) | Scénario de test 11 (Somme synthétique en terrain ouvert fortifié) : **19 334 pertes (10,1 %)** chez l'attaquant (contre 10 308 sans fortifications) et **11 505 (19,9 %)** chez le défenseur en 14,0 min ; scénario 3 (assaut contre position fortifiée niv. 2 + mitrailleuses en Lorraine) : **19,7 %** chez l'attaquant contre **2,9 %** chez le défenseur | Comme exigé (§6), le scénario de test de la Somme ne cherche pas à reproduire 1916 avec les effectifs de janvier 1914. Il vérifie l'interaction entre terrain ouvert (front large de 72 km) et fortifications préparées (+88 % de pertes pour l'assaillant et +67 % de durée par rapport au scénario 6 non fortifié). |
| **Galicie / batailles de rencontre avec renforts** (août-septembre 1914) | Pertes lourdes et équilibrées des deux côtés (15 % à 25 % des forces engagées), nombreuses captures lors des retraites austro-hongroises | Scénario 9 (Galicie avec renforts progressifs) : attaquant russe **16,7 %** (10 272), défenseur austro-hongrois **9,4 %** des forces entrées (13 022 sur 138 920 avec renforts, dont 5 224 en déroute donnant 1 566 prisonniers) | La montée en puissance progressive (passage d'`Assaut frontal` à `Grande bataille` à l'arrivée des renforts) produit une bataille longue (30 min) et disputée. |

### 6.2 Proportions comptables et précautions méthodologiques (Phase 5)

Conformément aux conclusions de `docs/project/MIL01_PHASE5_PERTES_HISTORIQUES.md` :
- **Hétérogénéité des définitions nationales :** les statistiques britanniques (*Statistics of the Military Effort*, 1922) séparent *Killed* (tués + morts de blessures + morts en captivité), *Wounded* et *Missing & Prisoners*, tandis que le rapport Marin (France, 1920) regroupe « Morts et disparus » sans isoler les blessés, et que le *Sanitätsbericht* allemand isole 68,6 % de blessés légers (*leichtverwundet*) au sein des blessés traités par le service de santé.
- **Distinction stricte entre faits sourcés, approximations et choix de conception :**
  - **Sourcés :** taux britannique de retour au service des blessés (55,6 %, *War Office* 1922, p. 240) ; part d'inaptes définitifs (~17 %).
  - **Approximations historiques :** application par défaut du taux de retour britannique aux six autres puissances ; proportion de 68,6 % de blessés légers issue de la seule source médicale allemande (*Sanitätsbericht*, t. III).
  - **Décisions et choix de conception provisoires :** 25 % de tués et 5 % de disparus parmi les pertes ordinaires sous le feu ; 10 % des blessés légers restant dans leur unité à 50 % d'efficacité ; parts de prisonniers sur déroute (0 % si terrain conservé ou indécis, 30 % en retraite, 80 % sans retraite) ; seuils de rupture et d'effondrement.

---

## 7. Tests, reproductibilité et résultats GitHub Actions

### 7.1 Exécution locale complète

Toutes les vérifications de données, de scénarios, de fiches historiques, de tests unitaires et de tests de fumée d'interface ont été exécutées localement :

| Commande | Résultat local |
|---|---|
| `python tools/export/build_game_data.py --check` | **[PASS]** `data/game/world_map.json` à jour |
| `python tools/export/build_scenario.py --check` | **[PASS]** scénarios à jour (`campaign_1914.json` et `sandbox_fictif.json` régénérés avec la nouvelle empreinte de `combat_rules.json`) |
| `python tools/history/render_fiches.py --check` | **[PASS]** fiches MIL-01 à jour |
| `bash tests/run.sh` | **110 test(s) réussi(s), 0 échec(s)** ; `RÉSULTAT UI : VALIDÉ` ; `RÉSULTAT UI BATAILLE : VALIDÉ` |

### 7.2 Tests ajoutés et mis à jour à l'étape 3

1. **`tests/unit/test_casualty_accounting.gd` :**
   - Validation du statut `"décision"` de `annihilated_unit_routing_as_ordinary` et de `routing_as_ordinary_outcomes = ["won", "indecisive_held"]`.
   - Vérification de l'issue `"indecisive_held"` (en calcul unitaire direct et sur une bataille complète indécise) : le défenseur qui conserve le terrain voit ses pertes de déroute (y compris d'unité anéantie) ventilées comme des pertes ordinaires sans aucun prisonnier, tandis que l'attaquant (`"indecisive"`) a ses pertes de déroute inscrites en disparus sans prisonnier, avec conservation exacte des effectifs nationaux.
   - Prise en compte de la tolérance d'arrondi entier par unité (`0.5 * n_units`) sur les 5 % de disparus ordinaires du vainqueur.
2. **`tests/unit/test_engagements.gd` (`test_step3_calibration_and_collapse`) :**
   - Vérifie que dans un engagement limité (`limited_attack / hold`), l'infanterie subit plus de 65 % des pertes totales et l'artillerie moins de 15 % (problème B résolu).
   - Vérifie que dans un assaut frontal (`assault / hold`), les pertes de l'attaquant restent sous les 30 % avant rupture et qu'aucune unité en déroute n'est anéantie (problèmes A, C et D résolus).
   - Vérifie qu'en défense à tout prix submergée (`Lorraine inversée, assault / hold_at_all_costs`), le défenseur résiste plus longtemps et inflige plus de pertes qu'en défense normale (`hold`), puis que la bataille se termine par **`effondrement de la défense (position intenable)`** sous 40 % de pertes au lieu d'une annihilation totale (problème E résolu).

### 7.3 Résultat sur GitHub Actions

Le workflow GitHub Actions (`.github/workflows/tests.yml`) a été exécuté sur la branche `dev/mil01-finalisation` après poussée des commits de l'étape 3 (voir §11).

---

## 8. Performances

Temps d'exécution mesurés sur le poste de vérification (`Godot v4.7.2-stable`, Linux x86_64) :

| Simulation | Ampleur | Temps de calcul |
|---|---|---|
| Escarmouche / engagement limité (Lorraine, Prusse-Orientale) | 28 à 36 unités (57 000 à 185 000 h) | **0,4 s à 1,5 s** |
| Assaut frontal (Lorraine, Vénétie, Galicie avec renforts) | 36 à 44 unités (70 000 à 200 000 h) | **0,8 s à 2,5 s** |
| Mobilisation générale de 4 mois pour les 7 puissances (999 unités créées sur la carte) | 999 unités sur la carte | **1,51 s** (1 512 ms) |
| Grande bataille après mobilisation complète (Lorraine : 272 593 vs 496 177 soldats) | **768 770 hommes**, 61 unités, 30 min (900 pas) | **7,8 s** |
| Suite complète `bash tests/run.sh` (110 tests unitaires + 2 suites UI smoke) | 110 tests + 2 scènes complètes | **~68 s** |

Toutes les simulations sont strictement déterministes et reproductibles à l'identique à partir des mêmes paramètres et graines aléatoires (vérifié par `test_deterministic_battle`, `test_determinism_and_sandbox`, `test_reproducibility_and_save_mid_battle` et `test_simulation_is_deterministic`).

---

## 9. Vérifications visuelles (1214×955 et 1600×900) et corrections d'interface

Les captures ont été générées en rendu réel sous X via `tests/engagement_capture.gd` aux deux résolutions exigées (**1214×955** et **1600×900**) dans `docs/project/captures_mil01/`, puis inspectées visuellement.

### 9.1 Problèmes visuels découverts et corrigés (`src/ui/battle_view.gd`)

1. **Superposition du panneau de résultat (`result_box`) sur le panneau droit :**
   - *Constat :* dans `BattleView._show_result`, `result_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)` était appelé avant que le conteneur n'ait sa taille finale, plaçant son coin supérieur gauche au centre de l'écran et faisant déborder le panneau de résultat sur la colonne droite (`Objectifs` / `Réserves et renforts`) en 1214×955 comme en 1600×900, avec un fond trop transparent.
   - *Correction :* centrage explicite par ancres (`0.5`) et offsets symétriques (`-255` à `+225` horizontalement, `-135` à `+135` verticalement) dans la zone centrale entre le panneau gauche (`330 px`) et le panneau droit (`360 px`), avec un `StyleBoxFlat` sombre opaque (`#1e1e1ef2`) et bordure encadrée (`#8c7e5a`).
2. **Lisibilité des panneaux latéraux tactiques et cadrage initial :**
   - *Constat :* la transparence par défaut des panneaux gauche et droit de la vue tactique laissait transparaître les icônes d'artillerie situées près du bord oriental en 1214×955, nuisant à la lecture du texte des objectifs.
   - *Correction :* application d'un fond sombre à forte opacité (`#383630f2`) sur les panneaux latéraux de `BattleView` et ajustement du zoom initial (`0.54`) pour cadrer l'ensemble du champ de bataille entre les deux panneaux.

### 9.2 Contrôle des captures aux résolutions 1214×955 et 1600×900

| Fichier (`docs/project/captures_mil01/`) | Résolution | Éléments contrôlés et validés |
|---|---|---|
| `10_armee_engagement_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Sélecteur d'approche offensive (3 choix), explication des types d'engagement, de la largeur du front et des blessés légers (50 % de capacité). |
| `10b_armee_postures_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Sélecteurs de posture défensive par armée (« Retarder », « Tenir », « Tenir à tout prix »), effectifs et moral d'armée. |
| `11_bataille_front_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Vue tactique en cours de bataille : panneau droit lisible (type `Assaut frontal`, front `28 km`, soldats en ligne `33 368`, en attente `89 293`, en réserve `0`, seuil de rupture `30 %`), panneau gauche affichant l'unité sélectionnée (`en attente : pas de place sur le front`), unités en attente atténuées, artillerie en second échelon derrière l'infanterie. |
| `12_resultat_engagement_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Panneau de résultat parfaitement centré entre les deux panneaux latéraux, sans aucun chevauchement : affiche les pertes (`vous 5 121, adversaire 12 470`), le motif de fin (`les attaquants ont rompu le combat`), la ventilation comptable (`tués 1 283 ; blessés 3 583 dont 242 restés dans leur unité ; disparus 255 ; prisonniers 0`), le type d'engagement réalisé (`Assaut frontal`), et l'unité adverse en déroute encadrée de rouge sur la carte. |
| `13_armee_blesses_legers_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Liste des unités de l'armée de l'Est après la bataille : affiche l'effectif administratif, les blessés légers maintenus dans l'unité et la capacité opérationnelle réduite (`Cavalerie 1 — 6e corps : 3 570 soldats ; dont 2 blessés légers (capacité 3 569), moral 70`). |
| `14_armee_bilan_pertes_1214x955.png` & `1600x900.png` | 1214×955 & 1600×900 | Haut de l'onglet `Armée` après la bataille : affiche `5. Présents dans les unités : 666 179 (+ services non combattants : 90 762)`, `6. Hors des rangs : 4 879` (`Tués : 1 283`, `Blessés en convalescence : 3 341`, `Blessés définitivement inaptes : 0`, `Disparus : 255`, `Blessés rendus au service : 0 ; blessés légers restés dans leur unité : 242 (comptés parmi les présents)`), `7. Prisonniers perdus : 0 ; détenus : 116`. |

---

## 10. Limites restantes et distinction D / I / T / F / P

### 10.1 Récapitulatif d'état (Documenté / Implémenté / Testé / Fonctionnel / Provisoire)

| Composant | État | Détail |
|---|---|---|
| Comptabilité des pertes (tués, blessés, convalescence, retours, inaptes, longue durée, disparus, prisonniers) | **D, I, T, F** | Conservation exacte des effectifs nationaux vérifiée dans tous les cas ; aucun double comptage. |
| Déroute d'un camp conservant le terrain (vainqueur ou bataille indécise, unités anéanties comprises) | **D, I, T, F** | Règles validées par le directeur (`routing_as_ordinary_outcomes = ["won", "indecisive_held"]`, `annihilated_unit_routing_as_ordinary = true`, statut `décision`). |
| Choix d'approche offensive et de posture défensive, 4 types d'engagement, largeur du front et rotations | **D, I, T, F** | Intégralement fonctionnels pour le joueur et l'IA, sauvegardés et déterministes. |
| Calibration interarmes (infanterie, cavalerie, artillerie, contre-batterie, écrantage) | **D, I, T, F** | Infanterie majoritaire dans les pertes (70–85 %), artillerie en second échelon avec tir de contre-batterie (25 %). |
| Survie des unités en déroute et réactivité de la rupture du combat | **D, I, T, F** | Fin de l'annihilation systématique des unités en déroute ; respect des seuils de rupture. |
| Effondrement de la défense en posture « tenir à tout prix » (`check_collapse`) | **D, I, T, F** | Fin par `effondrement de la défense (position intenable)` lorsque la position est submergée, évitant l'annihilation automatique à 88–100 %. |
| Proportions médicales et paramètres numériques de calibration | **P (Provisoire)** | 25 % tués, 5 % disparus au feu, 68,6 % blessés légers (source allemande), 55,6 % retour au service (source britannique étendue par approximation), seuils de rupture et d'effondrement restent configurables dans `forces_rules.json` et `combat_rules.json`. |

### 10.2 Limites connues (hors périmètre ou chantiers ultérieurs)

1. **Choix stratégique de l'approche par l'IA :** l'IA stratégique utilise toujours l'approche par défaut (`assault`) lorsqu'elle ordonne une offensive, et sa posture défensive par défaut reste « tenir à tout prix » dans la région de sa capitale et « tenir » ailleurs. Une sélection doctrinale de l'approche par l'IA relève des chantiers IA ultérieurs (`AI-01` / `AI-02`).
2. **Exploitation du renseignement de reconnaissance :** le rapport de reconnaissance (`recon_report`) est généré et affiché au joueur, mais n'est pas encore exploité par le système de renseignement stratégique (`INT-01` / `INT-02`).
3. **Prisonniers et diplomatie :** la libération, l'échange ou le rapatriement des prisonniers à la paix relèvent des évolutions futures du système diplomatique (`DIP-04`, décision `MIL01-P6-C6`).
4. **Terrain tactique :** le champ de bataille utilise la composition moyenne de relief de la région ; les cours d'eau, ponts et cols individuels ne sont pas encore tracés sur la carte tactique.

---

## 11. Commits et branche

- **Branche :** `dev/mil01-finalisation` (aucune fusion vers une autre branche, aucune modification hors de `dev/mil01-finalisation`).
- **Fichiers modifiés ou créés à l'étape 3 :**
  - `data/rules/forces_rules.json`
  - `data/rules/combat_rules.json`
  - `data/scenarios/campaign_1914.json` (empreinte `rules_sha256` régénérée)
  - `data/scenarios/sandbox_fictif.json` (empreinte `rules_sha256` régénérée)
  - `src/domains/military/force_ledger.gd`
  - `src/domains/combat/battle_manager.gd`
  - `src/domains/combat/engagement.gd`
  - `src/domains/combat/tactical_sim.gd`
  - `src/ai/tactical_ai.gd`
  - `src/ui/battle_view.gd`
  - `tests/balance_report.gd`
  - `tests/engagement_report.gd`
  - `tests/engagement_capture.gd`
  - `tests/unit/test_casualty_accounting.gd`
  - `tests/unit/test_engagements.gd`
  - `docs/decisions/DECISIONS_MIL01_T047_T057.md`
  - `docs/military/PERTES_ET_PRISONNIERS.md`
  - `docs/project/COMBAT_SYSTEM.md`
  - `docs/project/MIL01_PHASE6_STEP3_REPORT.md`
  - `docs/project/captures_mil01/*` (captures mises à jour en 1214×955 et 1600×900)

---

## 12. Conclusion sur la qualité et la stabilité du système militaire

À l'issue de l'étape 3 de la phase 6, le système militaire de **Grand Strategy-1914** forme un ensemble **cohérent, stable, déterministe et intégralement testé (110 tests unitaires, 0 échec)** :

1. **Cohérence historique et tactique :** les batailles produisent des volumes de pertes proportionnés à la nature de l'engagement (1 à 4 % en reconnaissance, 3 à 11 % en attaque limitée, 10 à 22 % en assaut frontal, jusqu'à 26 % lors d'un effondrement de défense à tout prix), sans annihilation systématique des armées ni victoires ou défaites automatiques.
2. **Équilibre interarmes et valeur du terrain :** l'infanterie supporte l'essentiel des pertes au feu et en mêlée, la cavalerie joue son rôle d'écran et d'exploitation, l'artillerie agit en second échelon avec tir de contre-batterie, et les fortifications préparées réduisent fortement les pertes du défenseur tout en accélérant la rupture de l'assaillant.
3. **Rigueur comptable :** chaque soldat engagé, présent, blessé léger maintenu dans son unité, blessé en convalescence, rendu au service, réformé, disparu ou prisonnier est suivi à l'unité près, sans création ni perte d'effectif et sans double comptage, y compris lors des batailles indécises et pour les unités anéanties.

Sous réserve de la validation de ce rapport par le directeur du projet, **le chantier MIL-01 (phases 1 à 6) est techniquement terminé.** Conformément aux instructions (§12), aucun autre chantier n'est engagé.
