# MIL-01 — Phase 6, étape 1 : refonte de la comptabilité des pertes

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026 ; **corrections ciblées : 16/11/2026** (§10 à §15).

> **Mise à jour du 16/11/2026.** Le directeur a validé l'étape 1 et demandé des corrections ciblées : solution A pour l'excès de disparus, maintien de la convalescence de longue durée, examen du chiffre de 68,6 %, validation provisoire des taux. Elles sont décrites aux §10 à §15. Les §1 à §9 décrivent l'état du 15/11 ; les passages devenus inexacts y sont signalés par « *[corrigé le 16/11, voir §…]* ».

**Mandat :** étape 1 seulement : comptabilité en quatre catégories.

**Garanties respectées :**
- volume des pertes et règles de combat **inchangés** (vérifiés, §5) ;
- types d'engagement, approches, largeur de front et fourchettes **non touchés** ;
- aucune fusion ; aucune autre branche modifiée ;
- étapes 2 et 3 non commencées.

**Légende :** D = documenté, I = implémenté, T = testé, F = fonctionnel en jeu (vu à l'écran ou testé par l'interface), P = provisoire.

---

## 1. Ce qui a été fait

### 1.1 Ventilation à la clôture de chaque bataille (`battle_manager.gd`, `force_ledger.gd`)

La perte d'effectif de chaque unité est celle que le combat produit déjà : différence avant et après la bataille, **inchangée**. Elle est répartie selon son origine :

| Origine (comptée pendant le combat, sans effet sur le calcul) | Ventilation | Paramètres et statut |
|---|---|---|
| Pertes au feu et en mêlée, hors déroute | Tués 25 % ; disparus 5 % ; blessés 70 % | `killed_share` 0,25 (**PROVISOIRE**, ancré sur 24 à 28 % dans les sources) ; `missing_share_fire` 0,05 (**PROVISOIRE**) |
| Pertes en déroute et reliquat d'unité anéantie *[corrigé le 16/11, voir §10 : la déroute d'un camp vainqueur est ventilée comme des pertes ordinaires]* | Prisonniers selon l'issue : 0 % si le camp tient le terrain ou si l'issue est indécise ; 30 % en défaite avec retraite sûre ; 80 % sans retraite. Le reste en disparus. | `rout_prisoner_share` (**PROVISOIRE** : proposition Q6, **non validée explicitement**) |
| Blessés | Légers 68,6 % (« dérivé » des listes allemandes, WO 1922 p. 354), dont **10 % restent dans leur unité** (décision). Les autres légers : convalescence d'**1 mois** ; tous les autres : **3 mois** (décision). | — |

- **Détenteur des prisonniers :** le commandant du camp adverse, sinon sa première nation.
- **Restitution :** les blessés légers restés dans leur unité lui sont rendus si elle existe encore ; sinon ils passent en convalescence.

**Instrumentation du combat** (`tactical_sim.gd`, 4 lignes) : chaque unité compte `loss_fire`, `loss_routing` et `loss_remnant`. Le calcul des pertes n'est pas modifié : empreintes tactiques identiques (§5).

### 1.2 Convalescence et retour (`ForceLedger.monthly_recovery`, appelé chaque mois après la mobilisation)

À l'échéance d'une cohorte :
- **55,6 % sont rendus au service.** Ils rejoignent une unité par le chemin d'incorporation existant (unités du district, sinon nouvelles unités de réserve ; voies de communication ; règle Q8). Ils **ne sont pas** comptés comme de nouveaux incorporés.
- **17 % deviennent définitivement inaptes.**
- **Le reste, 27,4 %, demeure en convalescence de longue durée.** Vos taux (56 % + 17 %) ne couvrent pas 100 % des blessés : je n'ai inventé ni retour ni décès pour ce reste. C'est la question D2 (§8).

Sans région d'accueil (capitale perdue, pas de voie) ou si une bataille est en cours, la convalescence se prolonge. Le bac à sable fictif ne rend pas ses convalescents, faute de réserves modélisées.

### 1.3 Disparus et prisonniers

- **Disparus :** catégorie distincte, avec sa cause : bataille, **attrition d'encerclement** ou **services d'une armée anéantie sans retraite**. Les deux dernières étaient des « pertes non ventilées » ; ce sont maintenant des disparus (sort inconnu). Aucune conversion automatique.
- **Prisonniers :** comptés chez l'origine (perdus) et chez le détenteur (détenus). Ils ne sont **jamais** ajoutés aux présents du détenteur. Capitulation inchangée. Pas de libération (évolution ultérieure).

### 1.4 Paramètres (`data/rules/forces_rules.json`, bloc `casualties`)

- Chaque valeur porte son statut (sourcé, dérivé, décision, PROVISOIRE) et sa justification.
- `national_overrides` : le Royaume-Uni a un taux de retour « sourcé » (WO 1922 p. 246). Pour les autres pays, c'est une **approximation britannique** signalée.
- **`combat_rules.json` n'est pas modifié.**

### 1.5 Conservation (contrôle existant, étendu)

```
présents (unités + services) + tués + convalescence (y compris longue durée) + inaptes + disparus
  + prisonniers perdus + pertes non ventilées héritées
= actifs sur la carte + réservistes incorporés + Territorial Force incorporée
```

Les catégories sont exclusives (`ForceLedger.out_of_ranks`).
- Un blessé rendu quitte la convalescence et redevient présent, sans incrément des incorporés.
- Un blessé resté dans son unité est présent, jamais en convalescence.

### 1.6 Sauvegardes

- **Format 4.**
- **Format 3 migré :** l'intégrité est contrôlée sur l'état d'origine (empreinte calculée avec le format 3).
  - Les anciennes pertes « non ventilées » sont **conservées telles quelles** (`legacy_unventilated`) : aucune ventilation après coup n'est possible.
  - Attrition et services perdus deviennent des disparus.
  - Une sauvegarde de format 3 altérée est refusée.
- **Formats 1 et 2 :** toujours refusés.
- **Bataille en cours** d'une sauvegarde de format 3 : ses pertes antérieures, faute de comptage d'origine, seront ventilées comme des pertes au feu. C'est une approximation signalée.

### 1.7 Interfaces

- **Onglet Armée.** La ligne 6 devient « Hors des rangs » : tués ; blessés en convalescence (dont longue durée) ; inaptes ; disparus ; blessés rendus et restés dans leur unité. La ligne 7 donne les prisonniers. La mention « ventilation provisoire » est affichée.
- **Écran de fin de bataille :** « Vos pertes : tués, blessés (dont restés), disparus, prisonniers ».
- **Journal :** la ventilation figure dans le résumé de bataille.

---

## 2. Fichiers modifiés

| Fichier | Changement |
|---|---|
| `src/domains/military/force_ledger.gd` | Réécrit : catégories, ventilation, convalescence, retours, migration |
| `src/domains/combat/battle_manager.gd` | Ventilation à la clôture (issue par armée, détenteur), journal ; attrition et armées anéantie en disparus |
| `src/domains/combat/tactical_sim.gd` | **4 lignes de comptage** de l'origine des pertes, sans effet sur le calcul |
| `src/domains/combat/combat_data.gd` | Normalisation des trois compteurs |
| `src/domains/military/mobilization_system.gd` | `incorporate(…, count_incorporated)` ; résumé et conservation |
| `src/simulation/turn_resolver.gd` | Étape mensuelle de convalescence |
| `src/app/game_session.gd` | Chargement des paramètres de ventilation |
| `src/adapters/save_repository.gd`, `src/simulation/game_state.gd` | Format 4, migration du format 3 |
| `src/ui/game_ui.gd`, `src/ui/battle_view.gd` | Affichage des catégories |
| `data/rules/forces_rules.json` | Bloc `casualties` |
| `tests/unit/test_casualty_accounting.gd` | **Nouveau** (10 fonctions) |
| `tests/unit/test_combat.gd`, `test_mobilization_phase2.gd`, `tests/ui_smoke.gd` | Adaptés aux nouvelles catégories (§4) |
| `docs/…` | Ce rapport, registre (§8), `PERTES_ET_PRISONNIERS.md`, captures 07 et 08 |

---

## 3. Tests exécutés

| Commande (sur ce poste) | Résultat |
|---|---|
| `bash tests/run.sh` | **94 réussis, 0 échec** ; interface stratégique VALIDÉE ; interface de bataille VALIDÉE |
| GitHub Actions | 1re exécution (`42d3086`) : **ÉCHEC** au contrôle « scénarios à jour ». Le scénario contient l'empreinte de `forces_rules.json`, que je n'avais pas régénérée après l'ajout du bloc `casualties` ; les tests locaux ne contrôlent pas cette empreinte. Corrigé par régénération : seule la ligne d'empreinte change. Résultat après correction : voir le compte rendu de fin d'étape. |

**Couverture des 16 tests demandés** (`test_casualty_accounting.gd`, sauf mention) :

| N° | Exigence | Test |
|---|---|---|
| 1 | Ventilation sans changement du volume | `test_breakdown_preserves_battle_volume` : tués + blessés + disparus + prisonniers = pertes du combat, pour chaque camp |
| 2 | Tués | `test_unit_breakdown_rules` (25 %) ; `test_breakdown_preserves_battle_volume` |
| 3 | Blessés légers restés dans l'unité | `test_light_wounded_remain_in_unit_not_double_counted` |
| 4 | Convalescence | `test_convalescence_and_returns` (échéances 1 et 3 mois) |
| 5 | Retour après un mois | idem : 240 sur 432 légers ; présents + 240 ; incorporés inchangés |
| 6 | Retour après trois mois | idem : 122 de plus au troisième mois, aucun au deuxième |
| 7 | Inaptes | idem : 73 + 37, définitifs |
| 8 | Disparus | `test_unit_breakdown_rules` ; aucune conversion après 12 mois (`test_convalescence_and_returns`) |
| 9 | Prisonniers | `test_unit_breakdown_rules` : origine et détenteur, jamais ajoutés aux présents du détenteur |
| 10 | Conservation nationale | Contrôle dans **chaque** test (`_conserved`) |
| 11 | Absence de double comptage | Catégories exclusives ; blessés = convalescents + restés ; rendus non comptés comme incorporés |
| 12 | Renforts et mobilisation | `test_mobilization_during_convalescence` |
| 13 | Retraites et encerclements | `test_encirclement_and_surrender_categories` |
| 14 | Capitulation | idem ; et `test_surrender_creates_prisoners_not_deaths` (phase 2, adapté) |
| 15 | Sauvegarde et chargement | `test_save_load_with_convalescence` : identique, et évolution identique sur trois mois avec retours |
| 16 | Anciennes sauvegardes | `test_old_save_migration` : format 3 migré et conservation vérifiée ; format 3 altéré refusé ; format 2 refusé (`test_territorial_force`) |
| + | Taux par pays | `test_national_return_rates` |
| + | Déterminisme ; bac à sable ; paramètres hors des règles de combat | `test_determinism_and_sandbox` |

---

## 4. Tests existants adaptés (changement de sens voulu, signalé)

- **`test_combat.gd::test_destroyed_unit_removed_and_losses_saved`** : l'effectif stratégique après bataille vaut désormais « résultat tactique + blessés légers restés dans l'unité ». C'est l'effet de votre décision sur les 10 %. L'assertion vérifie cette égalité exacte avec le registre.
- **`test_mobilization_phase2.gd`** : les anciennes clés « pertes non ventilées » sont remplacées par les catégories. Les assertions de fond sont inchangées (conservation, prisonniers différents des morts, survivants).
- **`tests/ui_smoke.gd`** : libellés de l'onglet Armée.

---

## 5. Vérification que le combat n'a pas changé

| Vérification | Résultat |
|---|---|
| `data/rules/combat_rules.json` | **Inchangé** (`git diff` vide) |
| Empreinte tactique de 4 batailles réelles (effectifs, statuts, moraux, positions de chaque unité en fin de combat ; pertes ; durée ; vainqueur). Sonde hors dépôt, avant et après. | **Identique** pour les 4. Exemple Lorraine : pertes A 38 101, D 9 996 ; 30 min ; défenseurs vainqueurs. |
| `tests/balance_report.gd`, avant et après | **Identique** hors temps de calcul : 7 batailles, mobilisation, Lorraine après mobilisation |
| Total ventilé = pertes du combat | Égalité exacte (test 1 ; écran de fin de bataille : 1 217 + 3 408 + 5 371 + 0 = 9 996) |

**Effet stratégique, conforme à la décision des 10 %, à connaître :** les blessés légers restés dans leur unité y demeurent. L'effectif après bataille est donc supérieur au résultat tactique : en Lorraine, 200 hommes sur 9 996 pertes françaises, soit 2 %. Le **volume des pertes** est inchangé (ils sont comptés parmi les blessés), mais l'**effectif hors de combat** baisse d'autant.

---

## 6. Vérifications visuelles (affichage réel)

- **`07_resultat_bataille_pertes_ventilees.png`** (écran de fin de bataille, France défendant la Lorraine) : « Vos pertes : tués 1 217 ; blessés 3 408 (dont 200 restés dans leur unité) ; disparus 5 371 ; prisonniers 0 », sous le total inchangé de 9 996. Lisible ; le panneau recouvre le journal, comme avant.
- **`08_armee_pertes_ventilees.png`** (onglet Armée, mai 1914) : 1 439 hors des rangs (357 tués, 932 en convalescence, 150 disparus), 68 blessés légers restés, 8 633 prisonniers allemands détenus. Lisible, sans débordement.

---

## 7. Problème constaté : beaucoup de disparus *[corrigé le 16/11 pour le camp vainqueur, voir §10 et §12]*

Sur les 4 batailles de la sonde, **53 à 72 % des pertes** surviennent **pendant une déroute ou par anéantissement d'unité**. Ce comportement vient du simulateur actuel, que je n'ai pas modifié : vulnérabilité × 1,8 en déroute, reliquats sous 50 hommes. La règle provisoire Q6 les range en disparus ou en prisonniers.

| Bataille | Camp | Tués | Blessés | Disparus | Prisonniers |
|---|---|---|---|---|---|
| Lorraine (Allemagne → France) | attaquant battu | 6,5 % | 18,1 % | 53,2 % | 22,2 % |
| | défenseur vainqueur | 12,2 % | 34,1 % | **53,7 %** | 0 % |
| Lorraine inversée | attaquant vainqueur | 22,9 % | 64,2 % | 12,9 % | 0 % |
| | défenseur battu | 5,5 % | 15,4 % | 55,7 % | 23,4 % |
| Galicie | attaquant battu | 5,7 % | 16,0 % | 55,2 % | 23,2 % |
| Vénétie | attaquant vainqueur | 7,4 % | 20,7 % | **72,0 %** | 0 % |

**Comparaison :** Somme 1916, environ 9 % de disparus et prisonniers ; Vittorio Veneto, 9 %. Un **camp vainqueur** avec plus de 50 % de disparus n'a pas de vraisemblance historique.

**Seules les pertes au feu donnent une composition proche des sources** : Lorraine inversée, attaquant, 22,9 % de tués et 64,2 % de blessés.

**Corrections possibles, non appliquées** (décision D1, §8) :
- (a) ventiler les pertes en déroute d'un camp **qui tient le terrain** comme des pertes au feu ; c'est un changement purement comptable ;
- (b) ne réserver disparus et prisonniers qu'au reliquat des unités anéanties ;
- (c) attendre l'étape 2 (types d'engagement, désengagement), qui réduira les déroutes ; cela modifie le combat.

---

## 8. Décisions qui vous reviennent *[tranchées le 16/11, voir §10 et §13]*

| N° | Question | Proposition |
|---|---|---|
| **D1** | Ventilation des pertes en déroute (§7) : (a), (b) ou (c) ? | (a), purement comptable, applicable dans l'étape 1 sur votre accord |
| **D2** | Les 27,4 % de blessés ni rendus ni inaptes : convalescence de longue durée (actuel), retour plus tardif, ou autre ? | Les laisser en longue durée tant qu'aucune source ne tranche |
| **D3** | Paramètres provisoires non validés explicitement : part des tués 0,25 ; disparus au feu 0,05 ; prisonniers en déroute 0 / 0,3 / 0,8 ; blessés légers 0,686 | Les valider ou les ajuster |
| **D4** | « Efficacité réduite » des blessés restés dans leur unité : règle tactique, pour l'étape 2 ? | Étape 2 |
| **D5** | Libération et rapatriement des prisonniers : avec la diplomatie (DIP-04) ? | Oui |

---

## 9. Commits

Voir le compte rendu de fin d'étape (branche `dev/mil01-finalisation`).

**Confirmation :**
- volume des pertes et règles de combat **inchangés** (§5) ;
- aucune fourchette appliquée ;
- étape 2 non commencée.

---

# Corrections ciblées du 16/11/2026

## 10. Correction de l'excès de disparus (solution A)

**Décision du directeur :** solution A. Les pertes de déroute d'un camp qui **remporte** la bataille et conserve le terrain sont des pertes ordinaires ; les prisonniers supposent une capture effective ou un effondrement ; une déroute n'est pas une capture ; les unités anéanties gardent un traitement distinct ; l'origine des pertes est conservée.

### 10.1 Règle appliquée (`ForceLedger.book_battle_losses`)

Les pertes d'une unité sont maintenant transmises en **trois origines distinctes**, au lieu de deux :

| Origine (compteur du simulateur, inchangé) | Camp vainqueur (`won`) | Issue indécise (`indecisive`) | Camp vaincu (`lost_retreat` / `lost_no_retreat`) |
|---|---|---|---|
| Feu et mêlée, hors déroute (`loss_fire`) | Ordinaire : tués 25 %, disparus 5 %, blessés 70 % | Ordinaire | Ordinaire |
| Déroute (`loss_routing`) | **Ordinaire** (nouveau) ; origine inscrite à part | Disparus, aucun prisonnier (inchangé) | Prisonniers 30 % ou 80 %, reste disparus (inchangé) |
| Reliquat d'une unité anéantie (`loss_remnant`, moins de 50 hommes) | Disparus, aucun prisonnier | Disparus | Prisonniers 30 % ou 80 %, reste disparus |

- **Aucune conversion en « pertes au feu ».** Les pertes de déroute d'un vainqueur prennent les **parts** des pertes ordinaires, mais restent inscrites comme pertes de déroute :
  - par bataille : `casualty_breakdown` → `origin_fire`, `origin_routing`, `origin_remnant`, `routing_as_ordinary` ;
  - par pays, en cumul : `military_ledger.losses_by_origin`.
- **Aucune capture sans défaite.** Le vainqueur et l'issue indécise ont une part de prisonniers nulle. Un camp vaincu n'a de prisonniers que pour ses pertes de déroute et ses unités anéanties, et en partie seulement (30 % avec retraite, 80 % en cas d'effondrement).
- **Unités anéanties :**
  - aucun blessé n'y « reste dans l'unité » ;
  - leur reliquat n'est jamais ventilé comme ordinaire ;
  - l'unité est retirée, comme avant.
- **Paramètres** (`forces_rules.json`, bloc `casualties`) :
  - `routing_as_ordinary_outcomes` = `["won"]` (décision) ;
  - `rout_prisoner_share` : la clé `held` est remplacée par `won` et `indecisive`, toutes deux à 0 (valeurs inchangées) ;
  - `annihilated_unit_routing_as_ordinary` (voir §10.2).
- **Issue par armée** (`BattleManager._side_outcomes`) : `won`, `indecisive`, `lost_retreat` ou `lost_no_retreat`. Elle est calculée avec la règle de retraite existante, avant les conséquences territoriales, comme à l'étape 1.

### 10.2 Point à arbitrer : unités anéanties du camp vainqueur

**Constat mesuré.** Le simulateur use les unités en déroute jusqu'à moins de 50 hommes. Leur « reliquat » est donc presque toujours nul : 38 hommes en Galicie, 36 dans le secteur de la Somme, 0 ailleurs. Dans les batailles comparées, **86 % des pertes de déroute des vainqueurs proviennent d'unités anéanties** (34 874 sur 40 461, cinq batailles cumulées ; de 0 à 99,6 % selon la bataille) :

| Bataille | Vainqueur : unités anéanties / engagées | Pertes de déroute des unités anéanties / pertes de déroute du camp |
|---|---|---|
| Lorraine (Allemagne → France) | 1 / 28 | 5 100 / 5 127 |
| Lorraine inversée | 0 / 16 | 0 / 936 |
| Galicie | 1 / 24 | 6 265 / 8 085 |
| Vénétie | 4 / 8 | 23 509 / 23 600 |
| Somme (secteur synthétique) | 0 / 36 | 0 / 2 713 |

Les deux instructions « déroute du vainqueur ordinaire » et « traitement distinct des unités anéanties » entrent donc en tension. **Choix provisoire, configurable et à valider :** `annihilated_unit_routing_as_ordinary` = `true`. La déroute d'une unité anéantie d'un vainqueur est ordinaire, car le camp tient le terrain et relève ses blessés. Le traitement distinct porte sur le **reliquat** et sur l'absence de blessés restés dans l'unité. Avec `false`, l'excès de disparus du vainqueur reviendrait presque entièrement : Vénétie, environ 70 % de disparus. Le test `test_annihilated_unit_remnant` couvre les deux réglages.

## 11. Blessés en convalescence de longue durée

**Comportement conservé et vérifié.** La part qui n'est ni rendue (55,6 %) ni inapte (17 %), soit environ 27,4 %, reste en convalescence de longue durée :
- aucun délai de retour ;
- pas d'inaptitude ;
- comptée dans les effectifs nationaux, hors des rangs (`out_of_ranks`, conservation).

Le test `test_convalescence_and_returns` vérifie désormais qu'au bout de cinq ans, cette catégorie n'a produit **aucun** retour ni aucune inaptitude, et que la conservation tient. Son évolution relève d'une phase ultérieure.

## 12. Le chiffre de 68,6 % de blessés légers

**Source.** Listes officielles allemandes de pertes jusqu'à fin octobre 1917, armée. Elles sont reproduites dans *Statistics of the Military Effort of the British Empire* (War Office, 1922), p. 354. Consultation par OCR ; la somme des catégories est égale au total imprimé (phase 5, §3.3). Il y a quatre catégories de blessés :

| Catégorie de la source | Effectif | Part des blessés |
|---|---|---|
| Grièvement blessés | 652 021 | 20,9 % |
| Blessés (gravité non précisée) | 328 431 | 10,5 % |
| Légèrement blessés | 1 829 820 | 58,5 % |
| Blessés restés dans leur unité | 315 263 | 10,1 % |
| **Total des blessés** (dénominateur) | **3 125 535** | 100 % |

**Calcul :** (1 829 820 + 315 263) / 3 125 535 = 2 145 083 / 3 125 535 = **0,6863**.

- **Dénominateur :** tous les blessés des quatre catégories. Ce ne sont pas les pertes totales : tués, disparus et prisonniers en sont exclus.
- **Choix de calcul faits en phase 6 (conception, pas dans la source) :**
  1. Les blessés « restés dans leur unité » sont comptés parmi les légers.
  2. Les 328 431 blessés sans gravité précisée sont comptés **hors** des légers. Si on les y comptait en entier, la part serait de 79,1 % ; pour moitié, de 73,9 %.
- **Lien avec les 10 % restés dans l'unité :**
  - Dans la source, les blessés restés dans leur unité représentent **10,1 % de tous les blessés**, soit **14,7 % des « légers »** au sens du calcul ci-dessus.
  - Le jeu applique la décision du directeur, 10 % **des blessés légers**, soit 0,686 × 0,10 = **6,9 % de tous les blessés**.
  - La valeur de 10 % est donc proche de la part de la source rapportée à **tous** les blessés, pas aux seuls blessés légers.
  - Je n'ai **rien modifié**. Options pour le directeur :
    - garder 10 % des légers ;
    - prendre 14,7 % des légers, pour reproduire la source ;
    - appliquer 10 % à tous les blessés.
- **Limites :**
  - une seule puissance ;
  - une période partielle, de 1914 à octobre 1917 ;
  - des listes allemandes jugées incomplètes par la source britannique elle-même ;
  - « légèrement blessé » n'est pas, dans la source, une durée de convalescence : l'équivalence « léger = un mois » est une **décision de conception**.
- **Statut :** **approximation historique**, dérivée d'une source unique et appliquée à toutes les puissances. **Elle n'est pas validée.** Ce n'est pas une donnée historique certaine. Le statut dans `forces_rules.json` passe de « dérivé » à « approximation historique (source allemande unique) ; NON validée ». **La valeur 0,686 n'est pas modifiée.**

## 13. Taux validés provisoirement et statut de chaque valeur

Tous ces paramètres restent configurables dans `forces_rules.json` (bloc `casualties`, dérogations par pays dans `national_overrides`).

| Paramètre | Valeur | Nature | Validation |
|---|---|---|---|
| Tués parmi les pertes ordinaires | 25 % | **Approximation historique** : les sources donnent 24 à 28 % des « tués + blessés » (Somme 1916, Isonzo, listes allemandes, Royaume-Uni en France). La catégorie « pertes ordinaires » est une **construction du jeu**. | Provisoire (16/11) |
| Disparus parmi les pertes ordinaires | 5 % | **Conception** | Provisoire (16/11) |
| Prisonniers : vainqueur ou indécis / défaite avec retraite / effondrement | 0 / 30 / 80 % | **Conception**, ordres de grandeur comparés à Caporetto et à août 1915 (non sourcés comme taux) | Provisoire (16/11) |
| Déroute du vainqueur ventilée comme ordinaire | — | **Décision** (solution A) | Validée (16/11) |
| Déroute des unités anéanties d'un vainqueur ventilée comme ordinaire | oui | **Conception** (§10.2) | **À valider** |
| Blessés légers | 68,6 % | **Approximation historique**, source unique (§12) | **Non validée** |
| Blessés légers restés dans l'unité | 10 % | **Décision**. La source donne 10,1 % de tous les blessés (§12). | Décision du 15/11 |
| Convalescence : légers / autres | 1 / 3 mois | **Décision et conception** | Décision du 15/11 |
| Retour au service | 55,6 % | **Sourcé pour le Royaume-Uni** (1 sur 1,8, WO 1922 p. 246) ; **approximation historique** ailleurs | Provisoire (16/11) |
| Inaptes définitifs | 17 % | **Décision**, proche de 16,68 % (WO 1922 p. 246) | Provisoire (16/11) |
| Convalescence de longue durée | environ 27,4 % | **Résultat arithmétique** (1 − 0,556 − 0,17), sans délai | Validée (16/11) |

**Prisonniers et diplomatie :** aucune libération ni aucun rapatriement implémenté. Les **échanges de prisonniers**, **libérations négociées** et **rapatriements après la paix** sont inscrits parmi les évolutions futures du système diplomatique :
- `docs/decisions/DECISIONS_MIL01_T047_T057.md` §9 ;
- `docs/diplomacy/OVERVIEW.md` §9.

**Blessés légers restés dans les unités :** aucune baisse d'efficacité ; comportement actuel conservé, à étudier à l'étape 2.

## 14. Comparaison avant et après sur des batailles représentatives

**Méthode :**
- sonde hors dépôt, même graine, même situation de janvier 1914, résolution par l'IA tactique ;
- « avant » = `f57b2df` ; « après » = code corrigé ;
- **Somme :** il n'existe pas de bataille de la Somme dans le scénario de janvier 1914. J'ai construit un **secteur synthétique** : l'armée allemande de la région 035 est placée dans la région 007 (France du Nord, qui contient la Somme), la région est déclarée allemande, et l'armée française de la région 011 l'attaque. Ce n'est **pas** une reconstitution de la bataille de 1916.

**Volumes de pertes : identiques pour chaque camp de chaque bataille.**
- Les empreintes tactiques des quatre batailles de référence de l'étape 1 sont inchangées : `52c6252842139ba7`, `7e3f80fe0f0f75f6`, `7e9388ce36b205fd`, `c70cf920da21d566`.
- `combat_rules.json` est inchangé.

Composition en % des pertes du camp, avant / après :

| Bataille | Camp | Pertes (avant = après) | Tués | Blessés | Disparus | Prisonniers | Blessés restés dans l'unité |
|---|---|---|---|---|---|---|---|
| Lorraine (Allemagne → France) | attaquant **vaincu** | 38 101 | 6,5 / 6,5 | 18,1 / 18,1 | 53,2 / 53,2 | 22,2 / 22,2 | 167 / 167 |
| | défenseur **vainqueur** | 9 996 | 12,2 / **25,0** | 34,1 / **70,0** | 53,7 / **5,0** | 0 / 0 | 200 / 201 |
| Lorraine inversée (France → Alsace-Lorraine) | attaquant **vainqueur** | 11 276 | 22,9 / 25,0 | 64,2 / 70,0 | 12,9 / **5,0** | 0 / 0 | 491 / 537 |
| | défenseur **vaincu** | 53 032 | 5,5 / 5,5 | 15,4 / 15,4 | 55,7 / 55,7 | 23,4 / 23,4 | 59 / 59 |
| Galicie (Russie → Autriche-Hongrie) | attaquant **vaincu** | 48 326 | 5,7 / 5,7 | 16,0 / 16,0 | 55,2 / 55,2 | 23,2 / 23,2 | 92 / 92 |
| | défenseur **vainqueur** | 15 263 | 11,8 / 25,0 | 32,9 / 70,0 | 55,3 / **5,0** | 0 / 0 | 265 / 352 |
| Vénétie (Italie → Autriche-Hongrie) | attaquant **vainqueur** | 33 484 | 7,4 / 25,0 | 20,7 / 70,0 | 72,0 / **5,0** | 0 / 0 | 53 / 58 |
| | défenseur **vaincu** | 28 281 | 8,1 / 8,1 | 22,6 / 22,6 | 53,3 / 53,3 | 16,0 / 16,0 | 188 / 188 |
| Somme (secteur synthétique, France → Allemagne) | attaquant **vainqueur** | 7 985 | 16,5 / 25,0 | 46,2 / 70,0 | 37,2 / **5,0** | 0 / 0 | 248 / 376 |
| | défenseur **vaincu**, sans retraite | 47 805 | 5,6 / 5,6 | 15,7 / 15,7 | 16,6 / 16,6 | 62,1 / 62,1 | 120 / 120 |

**Lecture :**
- Les camps **vainqueurs** passent de 13 à 72 % de disparus à 5 %, sans aucun prisonnier.
- Les camps **vaincus** sont inchangés, à un homme près : en Galicie, 26 667 / 11 194 devient 26 668 / 11 193 disparus / prisonniers, parce que la déroute et le reliquat sont désormais arrondis séparément. Le total est identique.
- **Effet stratégique, conséquence de la décision des 10 % :** plus de blessés chez les vainqueurs signifie plus de blessés légers restés dans leur unité. Somme : 248 → 376 ; Galicie : 265 → 352. L'effectif après bataille des vainqueurs augmente d'autant. Le **volume des pertes** est inchangé.

## 15. Problèmes restants et éléments provisoires

1. **Camps vaincus : 69 à 79 % de disparus et de prisonniers.** La solution A ne les concerne pas, et je ne les ai pas modifiés. Historiquement, de telles parts se rencontrent dans des effondrements (Caporetto, Tannenberg), mais elles sont élevées pour une défaite avec retraite ordinaire. Cela tient au simulateur, où la majeure partie des pertes survient pendant une déroute. L'étape 2 (désengagement) pourrait réduire ces déroutes. **Aucune correction sans votre autorisation.**
2. **Issue indécise :** les pertes de déroute des deux camps restent des disparus, sans prisonnier. Le défenseur conserve le terrain, mais ne « remporte » pas la bataille. J'ai appliqué votre formulation à la lettre. **Faut-il étendre la solution A au défenseur d'une bataille indécise ?** Aucune des cinq batailles comparées n'est indécise.
3. **§10.2** : traitement de la déroute des unités anéanties d'un vainqueur, à valider.
4. **§12** : 68,6 % non validé ; écart entre 10 % des légers et 10,1 % de tous les blessés dans la source.
5. **Bataille en cours d'une sauvegarde de format 3** (§1.6) : inchangé, approximation signalée.
6. **Registres de format 4 écrits avant cette correction :** leur origine des pertes n'a pas été enregistrée. Elle est initialisée à zéro au chargement (`ForceLedger.normalize`), sans effet sur les catégories ni sur la conservation.

### Fichiers modifiés par les corrections

| Fichier | Changement |
|---|---|
| `src/domains/military/force_ledger.gd` | Trois origines ; déroute du vainqueur ordinaire ; `losses_by_origin` ; `_split_ordinary` ; paramètre des unités anéanties |
| `src/domains/combat/battle_manager.gd` | Transmission séparée de la déroute et du reliquat ; issues `won` et `indecisive` ; origines dans `casualty_breakdown` |
| `data/rules/forces_rules.json` | `routing_as_ordinary_outcomes`, `annihilated_unit_routing_as_ordinary`, clés `won` et `indecisive` ; statuts reclassés (sourcé, approximation, décision, conception) ; note des 68,6 % ; note de la longue durée |
| `data/scenarios/campaign_1914.json` | Empreinte de `forces_rules.json` régénérée (une ligne) |
| `tests/unit/test_casualty_accounting.gd` | Adapté, plus 3 fonctions : `test_winner_routing_booked_as_ordinary`, `test_annihilated_unit_remnant`, `test_battle_winner_and_loser_routing` ; longue durée vérifiée sur cinq ans |
| `docs/decisions/DECISIONS_MIL01_T047_T057.md` §9 ; `docs/diplomacy/OVERVIEW.md` §9 ; ce rapport | Décisions du 16/11 ; évolutions diplomatiques futures |

**Non modifiés :**
- `combat_rules.json` et `tactical_sim.gd` (règles de combat) ;
- mobilisation (`mobilization_system.gd`, `mobilization_agent.gd`) ;
- diplomatie (code) ;
- interfaces.

### Tests des corrections

| Exigence du directeur | Test (`test_casualty_accounting.gd`) |
|---|---|
| Déroute d'un camp vainqueur qui conserve le terrain | `test_winner_routing_booked_as_ordinary` (calcul exact) ; `test_battle_winner_and_loser_routing` (Lorraine et Vénétie réelles : déroute du vainqueur entièrement ordinaire, aucun prisonnier, disparus ≤ 5 % + reliquat) |
| Déroute d'un camp vaincu | `test_unit_breakdown_rules` (30 % et 80 %) ; `test_battle_winner_and_loser_routing` (captures partielles) |
| Captures effectives | `test_unit_breakdown_rules` ; `test_annihilated_unit_remnant` (effondrement : 80 %) |
| Unités anéanties | `test_annihilated_unit_remnant` : reliquat distinct ; aucun blessé resté ; les deux réglages du §10.2 |
| Aucune capture automatique injustifiée | Vainqueur et issue indécise : 0 prisonnier (`test_winner_routing_booked_as_ordinary`) ; vaincu : prisonniers inférieurs aux pertes de déroute |
| Conservation des effectifs | `_conserved` dans chaque test, dont les batailles réelles |
| Convalescence de longue durée | `test_convalescence_and_returns` : 27 %, sans retour ni inaptitude après cinq ans, comptée dans les effectifs |
| Absence de double comptage | `test_breakdown_preserves_battle_volume`, `test_light_wounded_remain_in_unit_not_double_counted` ; origines = catégories (`test_battle_winner_and_loser_routing`) |
| Reproductibilité | `test_determinism_and_sandbox` ; `test_save_load_with_convalescence` |

**Résultats :**
- `bash tests/run.sh` sur ce poste : **97 réussis, 0 échec** ; interface stratégique VALIDÉE ; interface de bataille VALIDÉE.
- Contrôles de données de la CI exécutés localement : monde, scénarios et fiches à jour.
- GitHub Actions : voir le compte rendu de fin de corrections.

**Commits et branche :** `dev/mil01-finalisation`, voir le compte rendu. **L'étape 2 n'est pas commencée.**

