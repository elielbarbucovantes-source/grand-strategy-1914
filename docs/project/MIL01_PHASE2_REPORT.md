# MIL-01 — Rapport de la phase 2 : refonte de la mobilisation, pertes et prisonniers

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

**Mandat :** proposition `MIL01_PHASE2_PROPOSAL.md`, validée avec les décisions Q1 à Q10 et les précisions du directeur (registre `docs/decisions/DECISIONS_MIL01_T047_T057.md` §5).

**Garanties respectées :**
- travail sur `dev/mil01-finalisation` seulement ;
- aucune fusion ; aucune autre branche modifiée ;
- aucun travail existant supprimé ;
- IA, Territorial Force et combat non modifiés. Les seules exceptions sont des **branchements comptables** dans `battle_manager.gd`, sans effet sur l'issue des batailles (voir §4).

**Légende :**

| Abréviation | Signification |
|---|---|
| **D** | Documenté |
| **I** | Implémenté |
| **T** | Testé (test qui passe) |
| **F** | Fonctionnel en jeu (utilisable dans l'interface, vérifié par le test d'interface ou par la campagne) |
| **P** | Provisoire ou incomplet |

---

## 1. Synthèse par exigence

| Exigence | D | I | T | F | Provisoire ou incomplet |
|---|---|---|---|---|---|
| Échelons (T-051) : 2 échelons dérivés pour l'Allemagne et l'Autriche-Hongrie, aucun échelon introuvable créé | oui | oui | oui | oui (affichés dans l'onglet Armée) | Valeurs « dérivées » (phase 1) ; lecture « actifs compris » provisoire (D2) |
| Bloc unique (MIL01-P1-D1), signalé comme approximation | oui | oui | oui | oui (avertissement affiché) | **Approximation non documentée historiquement** pour 5 puissances sur 7 |
| Postures Paix, Préparatoire, Générale (Q2) ; posture accélérée reportée (Q1) | oui | oui | oui | oui (boutons, test d'interface) | Facteurs de posture PROPOSÉS |
| Allocation administration, chemins de fer, logistique (Q2), effets définis, sans coût | oui | oui | oui | oui (champs et bouton, test d'interface) | Seuils et facteurs PROPOSÉS ; aucun coût, l'économie n'étant pas définie |
| Échelon suivant : délai d'un mois (Q10), posture générale, échelon épuisé | oui | oui | oui | oui (bouton) | Délai PROVISOIRE |
| Rythme national (T-049, Q7) : paramètres par puissance, statut explicite | oui | oui | oui | oui | Seule l'Allemagne a un rythme **dérivé** ; toutes les autres valeurs sont **PROVISOIRES** et identiques |
| Chemins de fer : présence seulement, aucune capacité calculée | oui | oui | oui | oui | **Délai ferroviaire désactivé (0)** : couche de l'atlas incomplète (§3) |
| Information publique (T-056, Q3) : posture et échelons ; volumes confidentiels | oui | oui | oui | oui (liste « Mobilisations publiques ») | Le renseignement sur les volumes n'existe pas (INT-01/02 ouverts) |
| Communications (T-056 bis, Q4, Q5) : district sans voie non appelé ; voie par allié ; mer exclue | oui | oui | oui | oui (effets en fin de tour) | Une voie par détroit est considérée comme terrestre (convention du graphe) |
| Réservistes bloqués puis libérés | oui | oui | oui | oui | — |
| Pas de nouvelle armée de réserve dans une région en bataille (Q8) | oui | oui | oui | oui | — |
| Pertes nationales (Q6), par cause | oui | oui | oui | oui (onglet Armée, catégorie 6) | **Tués et blessés non distingués** (aucun ratio inventé) ; les blessés ne reviennent pas |
| Prisonniers perdus et détenus (Q6) | oui | oui | oui | oui (catégorie 7) | Seule la capitulation d'une armée encerclée en produit ; ni libération ni rapatriement |
| Conservation (réserves et personnel) | oui | oui | oui (paix, mobilisation, bataille, capitulation, sauvegarde) | — | — |
| Sauvegardes (Q9) : format 2 ; format 1 refusé avec message explicite | oui | oui | oui | oui | Pas de migration (§5) |
| Déterminisme | oui | oui | oui | — | Le journal suit l'ordre de saisie (état militaire indépendant) |

---

## 2. Ce qui a été implémenté

### 2.1 Modèle et moteur (`src/domains/military/mobilization_system.gd`, réécrit)

- **Échelons par district :**
  - `forces.echelons[]` (`pool_initial_by_region`, `pool_by_region`, `opened_turn`) est généré par `tools/export/build_scenario.py` depuis la base historique ;
  - la somme des échelons est contrôlée : elle doit égaler le réservoir sur la carte, sinon la génération échoue.
- **Ordres :** `set_mobilization_posture`, `set_mobilization_allocation`, `call_next_echelon`. L'ordre `mobilize` est conservé comme alias de la posture générale.
- **Validation et application :** la validation a lieu à la saisie (`GameSession.queue_order`, un ordre par type et par mois) et à la résolution (`TurnResolver`). L'application se fait à la résolution, après la diplomatie.
- **Étape mensuelle :** cohortes bloquées réexaminées, puis incorporation, puis appel.
- **Communications :** `communication()` fait un parcours en largeur trié, donc déterministe. Les régions de la nation et des alliés sont franchissables, la mer est exclue.
- **Information publique :** `public_view()` et `IntelSystem.view_for(...)["public_mobilization"]`. Le journal des événements « mobilisation publique » est visible de toutes les puissances ; les volumes restent dans le journal du seul pays concerné.
- **Contrôles :** `summary()` couvre toutes les catégories ; `conservation()` vérifie les deux invariants.

### 2.2 Comptabilité des pertes et des prisonniers (`src/domains/military/force_ledger.gd`, nouveau)

Elle est détaillée dans `docs/military/PERTES_ET_PRISONNIERS.md`. Un soldat qui quitte une unité est inscrit **une seule fois**, selon le cas :
- perte de combat (différence avant et après la bataille) ;
- attrition d'encerclement ;
- services d'une armée anéantie ;
- prisonnier, compté chez l'origine et chez le détenteur.

### 2.3 Paramètres (`data/rules/forces_rules.json`)

- Postures, effets de l'allocation et seuils.
- `defaults` : base technique commune.
- `national_parameters` : pour **chacune** des 7 puissances, `call_share_per_month`, `transit_months`, `administrative_capacity`, `rail_gap_months` et `detour_months`, chacun avec son statut (`dérivé` ou `PROVISOIRE`) et sa justification.
- **Organisation des réserves :** les échelons de la base historique.

### 2.4 Interface (`src/ui/game_ui.gd`, onglet Armée)

- **Sept catégories :**
  - actifs ;
  - réservistes non appelés, par échelon, avec le statut et l'avertissement « approximation non documentée » ;
  - en cours, dont bloqués ;
  - incorporés ;
  - présents ;
  - pertes, « non ventilées », avec la mention « tués et blessés : non modélisé » ;
  - prisonniers perdus et détenus.
- **Commandes :** boutons de posture, bouton « échelon suivant », trois champs d'allocation.
- **Liste des mobilisations publiques** des autres puissances, sans volumes.
- **Non vérifié :** le contrôle visuel à l'écran. Le test d'interface sans affichage (`ui_smoke`) vérifie les textes, les boutons et l'effet réel d'une fin de tour.

### 2.5 Sauvegardes

- `SaveRepository.FORMAT_VERSION` et `GameState.FORMAT_VERSION` passent à **2**.
- Une sauvegarde de version 1 est refusée : « migration impossible de façon fiable (réservoirs non échelonnés, données historiques corrigées, pertes non comptabilisées). Commencez une nouvelle partie. »
- **Pourquoi pas de migration (Q9)** :
  1. les sauvegardes de version 1 ont été produites avec l'ancienne base : réservoir allemand de 4 000 000, italien de 1 250 000, VIe corps russe à Łomża ;
  2. un réservoir partiellement appelé ne peut pas être réparti entre échelons et districts sans hypothèse arbitraire ;
  3. les pertes antérieures n'ont pas été inscrites, donc l'invariant de personnel ne serait pas vérifiable.

---

## 3. Décisions d'implémentation à signaler (écarts avec la proposition)

1. **Délai ferroviaire désactivé (`rail_gap_months = 0`).**
   - Le mécanisme est implémenté et réglable. Mais dans l'atlas, ces districts n'ont aucun chemin ferroviaire vers leur capitale :
     - Prusse-Orientale (026) ;
     - Pologne russe (055, 056) ;
     - Ukraine occidentale (058) ;
     - Crimée (063) ;
     - Irlande hors Ulster (006) ;
     - Italie 083 à 085.
   - Ces absences viennent très probablement de la couverture de l'atlas (MAJ-006 ouverte), pas de l'histoire.
   - Avec un délai d'un mois, la mesure montrait 8 % du premier échelon allemand retardé à cause de la seule Prusse-Orientale. Ce serait faire d'une lacune de données une certitude historique (précision n° 2 du directeur).
   - Conséquence : l'allocation « chemins de fer » n'a aujourd'hui qu'un effet actif, le transit +1 mois sous 15 %.
2. **Comptabilité des pertes plus large que les « compteurs » proposés :** registre par cause, prisonniers des deux côtés, invariant de personnel (Q6).
3. **Réservistes en détour.** Ils forment de nouvelles unités dans la région d'accueil et ne complètent pas les unités d'un autre district (choix PROPOSÉ).
4. **Déterminisme.** Le journal des événements suit l'ordre de saisie des ordres. L'état militaire et territorial n'en dépend pas, et c'est ce qui est testé.

---

## 4. Modifications hors du domaine de la mobilisation (correction technique strictement nécessaire)

| Fichier | Modification | Effet sur le combat |
|---|---|---|
| `src/domains/combat/battle_manager.gd` | Inscription des pertes à la clôture de bataille et à l'attrition. Les armées anéanties ou capitulées sont retirées par `ForceLedger.remove_formation_booked` au lieu de `remove_formation`. | **Aucun** : mêmes effectifs, mêmes retraits ; seule l'inscription est ajoutée. Les tests de combat existants passent sans modification. |
| `src/simulation/game_state.gd` | Format 2 ; normalisation des nouveaux champs au chargement | — |
| `src/domains/intelligence/intel_system.gd` | Vue nationale : `public_mobilization` | — |

---

## 5. Tests

### 5.1 Exécutés sur ce poste (Godot 4.7.2 sans interface)

| Commande | Résultat |
|---|---|
| `python tools/export/build_game_data.py --check` | PASS |
| `python tools/export/build_scenario.py --check` | PASS (scénarios régénérés) |
| `python tools/history/render_fiches.py --check` | PASS |
| `bash tests/run.sh` | **68 réussis, 0 échec** ; interface stratégique **VALIDÉE** ; interface de bataille **VALIDÉE** |

### 5.2 Nouveaux tests (`tests/unit/test_mobilization_phase2.gd`, 13 fonctions)

| Test | Ce qu'il vérifie |
|---|---|
| `test_echelons_match_historical_database` | Cohérence entre la base et le jeu : échelons repris tels quels, somme égale au réservoir, répartition exacte par district, bloc unique signalé |
| `test_national_parameters_are_explicit` | 7 puissances × 5 paramètres avec statut et justification ; Allemagne « dérivé », France « PROVISOIRE » ; posture accélérée absente |
| `test_postures_and_national_rhythm` | Paix : aucun appel. Préparatoire : environ un quart du bloc français. Repère allemand : premier échelon en un mois. Baisse de posture sans démobilisation. |
| `test_next_echelon_rules` | Refus en paix, en préparatoire, avant le délai et avant l'épuisement de l'échelon ; ouverture puis appel ; pas d'échelon introuvable ; bloc unique sans sous-échelon |
| `test_allocation_effects_without_cost` | Effet de l'administration, transit si chemins de fer < 15 %, pas de délai en priorité ferroviaire, aucun coût, refus des allocations invalides |
| `test_public_information_without_volumes` | Ordre secret avant la résolution ; posture et échelon publics ensuite ; aucun volume dans l'information publique ni dans le journal d'autrui ; aucune conséquence diplomatique |
| `test_occupied_district_with_route_and_blocking` | Détour vers une région française ; voie coupée : bloqués ; libération : reprise ; conservation |
| `test_allied_territory_route` | Bavière (034) isolée : voie par l'Autriche-Hongrie (Double Alliance) ; sans alliance, aucune voie |
| `test_no_reserve_army_in_battle_region` | Q8 : incorporation reportée, puis effectuée |
| `test_war_losses_are_accounted` | Conservation pendant et après une bataille réelle (mobilisation, guerre, bataille de Lorraine) ; pertes non ventilées ; aucune unité détruite comptée comme opérationnelle |
| `test_surrender_creates_prisoners_not_deaths` | Capitulation : personnel = prisonniers + attrition ; prisonniers chez les deux camps ; aucun « mort » |
| `test_save_load_and_determinism` | Deux exécutions identiques ; indépendance de l'ordre des ordres ; rechargement identique et évolution identique ; conservation après rechargement ; refus du format 1 avec message |
| `test_full_mobilization_conservation_all_powers` | 7 puissances, 8 mois : invariants ; réservoir entièrement incorporé, jamais dépassé ; Allemagne à 4 610 000 |

**Tests adaptés :**
- `test_forces_mil01.gd` : invariant avec les bloqués ; district occupé sans voie conforme à Q4 ;
- `test_campaign_integration.gd` : la posture remplace `declared` ;
- `ui_smoke.gd` : catégories 6 et 7, bloc unique, boutons d'allocation et de posture, effet réel d'une fin de tour.

### 5.3 Intégration continue GitHub

Le résultat de l'exécution est donné dans le compte rendu de fin de phase : il n'est connu qu'après la publication.

### 5.4 Non couvert par les tests

- Rendu visuel de l'onglet Armée.
- Mobilisation par l'IA (phase 3) : les puissances de l'IA restent en posture de paix.
- Batailles entre IA : l'IA n'attaque pas les régions défendues (phase 6). La conservation en bataille est testée sur une bataille provoquée par le test.

---

## 6. Mesures (`tests/balance_report.gd`, posture générale des 7 puissances en janvier 1914)

| Puissance | Mois 1 (en cours / incorporés) | Mois 2 | Mois 3 | Mois 4 | Présents au mois 4 |
|---|---|---|---|---|---|
| Royaume-Uni | 106 735 / 0 | 102 545 / 106 735 | 0 / 209 280 | 0 / 209 280 | 335 589 |
| France | 1 119 694 / 0 | 1 075 760 / 1 119 694 | 0 / 2 195 454 | idem | 2 957 274 |
| Allemagne | 2 993 984 / 0 | 304 / 2 993 680 | 810 272 / 2 993 712 | 0 / 3 803 984 | **4 610 000** |
| Autriche-Hongrie | 687 125 / 0 | 660 160 / 687 125 | 334 807 / 1 345 369 | 319 824 / 1 680 176 | 2 152 891 |
| Russie | 1 414 239 / 0 | 1 358 733 / 1 414 239 | 0 / 2 772 972 | idem | 3 709 945 |
| Italie | 507 443 / 0 | 487 524 / 507 443 | 0 / 994 967 | idem | 1 300 000 |
| Empire ottoman | 117 694 / 0 | 113 075 / 117 694 | 0 / 230 769 | idem | 278 769 |

- **Unités après mobilisation :** 980 (contre 963 en phase 1). Le rythme et la constitution des unités de réserve diffèrent.
- **Calcul de 4 mois de mobilisation :** environ 1,9 s pour 7 puissances (1,5 s en phase 1 ; le calcul des communications s'ajoute).
- **Lorraine après mobilisation** (situation différente du fait du rythme des échelons) : 272 593 contre 496 177 ; pertes 60 % contre 12 % ; 5,1 s de calcul.
- **Batailles du temps de paix** (Lorraine, Prusse-Orientale, Galicie, Vénétie) : **identiques** à la phase 1. Le combat n'a pas changé.

---

## 7. Fichiers

- **Nouveaux :**
  - `src/domains/military/force_ledger.gd` ;
  - `tests/unit/test_mobilization_phase2.gd` ;
  - `docs/military/PERTES_ET_PRISONNIERS.md` ;
  - ce rapport.
- **Code modifié :**
  - `src/domains/military/mobilization_system.gd` (réécrit) ;
  - `src/simulation/orders.gd`, `turn_resolver.gd`, `game_state.gd` ;
  - `src/app/game_session.gd` ;
  - `src/adapters/save_repository.gd` ;
  - `src/domains/combat/battle_manager.gd` (branchements comptables) ;
  - `src/domains/intelligence/intel_system.gd` ;
  - `src/ui/game_ui.gd`.
- **Données :** `data/rules/forces_rules.json`, `data/scenarios/campaign_1914.json` (régénéré).
- **Outils :** `tools/export/build_scenario.py`.
- **Tests modifiés :** `tests/unit/test_forces_mil01.gd`, `tests/unit/test_campaign_integration.gd`, `tests/ui_smoke.gd`, `tests/balance_report.gd`.
- **Documentation :**
  - `docs/military/MOBILISATION.md` (réécrit) ;
  - `docs/decisions/DECISIONS_MIL01_T047_T057.md` (§5) et `DECISIONS_PENDING.md` (MIL-07) ;
  - `docs/project/MIL01_PHASE2_PROPOSAL.md` (statut).

---

## 8. Ce qui reste provisoire ou incomplet

1. **Rythmes nationaux.** Seul le rythme allemand est dérivé d'une source. Les six autres utilisent la valeur provisoire commune 0,5 ; aucune différence nationale n'est inventée. La lenteur ottomane, notamment, n'est pas représentée.
2. **Bloc unique pour 5 puissances sur 7.** C'est une approximation affichée : ces puissances peuvent mobiliser tout leur réservoir en 3 mois, au-delà de ce qu'un plan de 1914 permettait probablement.
3. **Délai ferroviaire désactivé** tant que la couche ferroviaire de l'atlas n'est pas consolidée (MAJ-006).
4. **Tués, blessés, disparus non distingués ; aucun retour de blessés ; pas de libération ni de rapatriement.** Il faut des ratios sourcés et des mécanismes à décider (voir `PERTES_ET_PRISONNIERS.md` §3).
5. **Aucun coût économique** (Q1, Q2). Besoins en attente : ECO-01, 02, 05, 06.
6. **Le renseignement ne révèle pas les volumes** : INT-01/02 ouverts.
7. **Asymétrie avec l'IA** : elle ne mobilise toujours pas (P0-1, phase 3).
8. **Démobilisation** : MIL-02 ouvert.

---

## 9. Décisions qui pourraient être utiles (sans bloquer la phase 3)

1. **Délai ferroviaire.** Faut-il garder 0 jusqu'à la consolidation de la couche ferroviaire (MAJ-006), ou réactiver le mécanisme avec la couche actuelle ?
2. **Services d'une armée anéantie** : comptés en pertes (proposé) ou en prisonniers ?
3. **Blessés.** Faut-il chercher des ratios nationaux sourcés (tués, blessés, disparus) pour une phase ultérieure (phase 5) ?
