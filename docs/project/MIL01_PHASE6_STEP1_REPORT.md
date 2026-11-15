# MIL-01 — Phase 6, étape 1 : refonte de la comptabilité des pertes

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

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
| Pertes en déroute et reliquat d'unité anéantie | Prisonniers selon l'issue : 0 % si le camp tient le terrain ou si l'issue est indécise ; 30 % en défaite avec retraite sûre ; 80 % sans retraite. Le reste en disparus. | `rout_prisoner_share` (**PROVISOIRE** : proposition Q6, **non validée explicitement**) |
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

## 7. Problème constaté : beaucoup de disparus

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

## 8. Décisions qui vous reviennent

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
