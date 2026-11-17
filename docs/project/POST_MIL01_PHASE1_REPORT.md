# Rapport — Phase I post-MIL-01 (renseignement, IA opérationnelle, performance)

- **Date :** 17/11/2026
- **Branche :** `dev/mil01-finalisation` (base : `57e5d25`, rapport d'audit `docs/project/POST_MIL01_ROADMAP_AUDIT.md`)
- **Périmètre :** exploitation du renseignement existant, IA stratégique de niveau 2, stabilisation des performances, tests, simulations, bancs et documentation.
- **Statut normatif :** les blocs `game_rules.json:intelligence` et `ai_doctrines.json:operations` restent **PROPOSÉ**. Aucun paramètre de combat MIL-01 validé n'a été modifié. Aucune décision de conception n'est promue par ce rapport.

Légende : **D** documenté, **I** implémenté, **T** testé, **F** fonctionnel de bout en bout, **P** provisoire / paramètres non validés.

---

## 1. Travail récupéré

Le worktree contenait, à la reprise, un diff non commité de **11 fichiers, +1026 / −116 lignes** (copie intégrale : `~/backups/gs1914-phase1-reprise-2026-11-17/uncommitted.patch`, empreinte identique au diff de l'époque). Les scripts et journaux de la phase précédente sont conservés dans le même dossier (`antigravity-scratch/`, `diag_*.txt`, `cli-20261116_164918.log`).

L'audit T1 (`~/backups/gs1914-phase1-reprise-2026-11-17/T1_AUDIT.md`) avait établi :

- `bash tests/run.sh` dépassait son délai de 900 s (base propre : 207 s, 110 tests verts) ;
- aucun test nouveau ne couvrait le renseignement, l'IA ou l'index ;
- `GameState.descendants()` était réellement accéléré (≈ ×139 sur 20 appels), mais le tour de guerre 4 passait de **794 ms (base)** à **472 479 ms (diff sale)** ;
- le rapport livrable n'existait pas.

Aucun fichier du travail repris n'a été supprimé ni écrasé. Aucun `git reset`, `git checkout --` ni `stash pop` n'a été utilisé.

## 2. Modifications antérieures à la reprise (conservées)

| Fichier | Apport conservé |
|---|---|
| `src/ai/nation_agent.gd` | Refonte `_military` : suppression de l'exclusion `enemy_presence.has(n)`, score multi-objectifs, choix d'approche et de posture, garnisons, concentrations. |
| `src/domains/intelligence/intel_system.gd` | `DEFAULT_CFG`, `cfg()`, `region_intel()`, `view_for(..., rules)` avec `region_intel` et `own_defenses`. |
| `src/domains/combat/battle_manager.gd` | `_record_reconnaissance` réécrit, `_record_post_battle_intel`, `_build_side_intel_report`. |
| `src/simulation/game_state.gd` | Index hiérarchique en mémoire (`register_formation`, `invalidate_hierarchy`, `set_formation_parent`, caches). |
| `src/ui/game_ui.gd` | Affichage du renseignement par région et dans l'onglet « Renseignement ». |
| `src/app/game_session.gd`, `src/domains/combat/combat_data.gd`, `src/domains/military/*` | Propagation de `rules`, normalisation des rapports, créations de formations par l'API d'index. |
| `data/rules/game_rules.json`, `data/rules/ai_doctrines.json` | Blocs **PROPOSÉ** `intelligence` et `operations`. |

Ces apports étaient écrits et partiellement exécutés mais **non validés par des tests**. Les statuts **PROPOSÉ** n'ont pas été modifiés.

## 3. Modifications apportées pendant la reprise (T3, T4 puis T5)

1. **T3 — cause de la régression** : l'IA ordonnait désormais une offensive pour chaque armée disponible. La résolution de très nombreuses batailles automatisées, et non `descendants()`, provoquait l'explosion du tour 4. Ajout des plafonds `PROPOSÉ` `max_offensives_per_turn = 2`, `max_armies_per_offensive = 1`, `max_concentrations_per_turn = 1` (dans `DEFAULT_OPS` et `ai_doctrines.json`). Rejeu : tour 4 **472 479 ms → 2 138 ms** (`diag_rootcause_current.txt` → `diag_rootcause_final.txt`).
2. **T3 — sauvegarde bit-exact** : `SaveRepository` encode les flottants en motif binaire 64 bits (`__gs1914_f64__`) avant `JSON.stringify`, et les décode au chargement. Les sauvegardes v4 existantes (nombres JSON nus) restent lisibles.
3. **T3/T4 — index hiérarchique durci** : garde-fous contre les mutations directes de `formations` (taille, parent, échelon) et API `register_formation` / `set_formation_parent` utilisée par la mobilisation et la Territorial Force.
4. **T3 — tentative d'index spatial abandonnée** : voir §9. Rien de cette tentative ne subsiste dans le code versionné.
5. **T4 — paramètres sans constantes en dur** : `45000`, `65000`, `1.50`, `0.30` (et deux facteurs de prudence associés) déplacés dans `NationAgent.DEFAULT_OPS` **et** `ai_doctrines.json:operations`.
6. **T4 — tests et outils** : 26 nouveaux tests, banc versionné, simulation longue, extension du lanceur de tests aux dossiers d'intégration.
7. **T4 — rapport, `PROGRESS.md`, `CHANGELOG.md`** : le présent document et les deux journaux d'état.
8. **T5 — tests de bout en bout** : 6 scénarios avec vraies batailles, vrai renseignement et deux IA, sans injection de vue ; distinction documentée avec les tests de décision (§11 et §13). Aucun paramètre MIL-01 ni aucune décision validée modifié.

## 4. Architecture

Flux réel d'un tour IA :

```
GameSession.end_turn()
  → IntelSystem.view_for(state, world, nation, rules)   // vue filtrée, jamais l'état complet
  → NationAgent.decide(view, world, rules)              // décisions déterministes
  → Orders (mouvements avec approche, postures, diplomatie défensive, mobilisation)
  → TurnResolver.resolve(state, world, rules, orders)
  → BattleManager.finish() → state.regions[rid].recon_reports[nation]
```

La mémoire de renseignement est **par nation** dans `state.regions[rid]["recon_reports"][nation]` ; `IntelSystem.region_intel()` la convertit en statut daté pour l'UI et l'IA. `GameState` maintient un index hiérarchique non sérialisé, reconstruit au chargement. `SaveRepository` reste le seul point de sérialisation JSON. Aucun système parallèle de renseignement n'a été créé.

## 5. Renseignement

**D, I, T, F — P (seuils PROPOSÉ).**

- Observation directe des régions contrôlées et voisines (terre et détroits) : présence d'armées étrangères visible, **effectifs toujours `null`**.
- Statuts : `confirmed_clear`, `estimated`, `stale`, `unknown` ; fourchette `estimate_min`/`estimate_max`, fiabilité, âge, date, source (`reconnaissance` ou `combat`), fortification, nations identifiées.
- Vieillissement : `fresh_turns = 1`, `stale_turns = 4`, décroissance de fiabilité `0.18`/tour, élargissement d'incertitude `0.12`/tour ; nouvelle observation remplace l'ancienne, y compris lorsqu'une région devient vide.
- Renfort non repéré : une armée supplémentaire observée après un rapport dégrade le statut en `stale` et élargit la fourchette au lieu de révéler un chiffre exact.
- Rapports de combat : `_record_post_battle_intel()` enregistre une estimation pour le camp qui se replie et nettoie le rapport du camp qui tient la région ; les estimations sont arrondies et jamais égales au total administratif exact.
- UI : onglet « Renseignement » et encart régional affichent statut, fourchette, unités repérées, tranchées, fiabilité et ancienneté.
- Services hors périmètre restant explicites dans l'UI : interception, décryptage, espionnage industriel.

## 6. IA offensive

**D, I, T, F — P (seuils PROPOSÉ).**

`NationAgent.evaluate_target()` évalue chaque région ennemie adjacente :

- valeur stratégique (libération du territoire national, capitale, villes, front) ;
- forces amies opérationnelles (blessés légers à efficacité réduite), moral, ravitaillement ;
- estimation ennemie issue de `region_intel`, fiabilité, terrain, fortifications, encerclement, coût d'un échec ;
- approches : `reconnaissance` si renseignement inconnu/ancien, `limited_attack` en rapport intermédiaire ou position fortifiée/montagneuse, `assault` en supériorité nette ;
- abstention et attente de renforts si le rapport de forces estimé est défavorable, ou si un rapport ancien est déjà très défavorable.

Le test anti-fuite vérifie que muter les effectifs ennemis cachés ne change pas la décision : l'IA ne lit que la vue filtrée.

## 7. IA défensive

**D, I, T, F — P (seuils PROPOSÉ).**

- Postures dynamiques `delay` / `hold` / `hold_at_all_costs` selon capitale, fortifications, ravitaillement, retraite possible, moral, menace estimée et appui allié.
- Garnisons conservées pour ne pas découvrir la capitale, couvrir une frontière tenue par une seule armée face à l'inconnu, et ne pas abandonner une position avant l'arrivée d'un renfort adjacent.
- Repli prioritaire des armées coupées de leur ravitaillement vers la capitale.
- Respect des ruptures/retraites et des approches MIL-01 existantes ; aucun paramètre de combat validé n'a été changé.

## 8. Coordination

**D, I, T, F — P (plafonds PROPOSÉ).**

- Deux IA peuvent planifier des opérations successives sur le même front ; les ordres sont émis depuis des vues indépendantes, sans information secrète partagée.
- `assigned` empêche qu'une même armée reçoive deux ordres contradictoires dans un tour ; les cibles sont triées par score puis par identifiant (déterminisme).
- Anti-répétition : une offensive inefficace n'est pas relancée à l'identique sans nouvel élément de renseignement ou renfort (test dédié).
- Non-abandon : une position secondaire n'est pas évacuée avant l'arrivée effective d'un renfort (test dédié).
- Plafonds : 2 offensives, 1 armée par offensive, 1 concentration intérieure par nation et par tour.

## 9. Optimisations

### 9.1 Index hiérarchique (conservé)

`GameState` maintient des listes triées et des caches `parent -> descendants`, `parent -> unités`, `top-level`, reconstruits au chargement. Les mutations passent par `register_formation()` (insertion incrémentale), `set_formation_parent()` et `remove_formation()` (invalidation). `_ensure_hierarchy()` détecte automatiquement et à coût O(1) tout changement de **taille** de `formations` (ajout/suppression direct). En revanche, un changement direct de **parent ou d'échelon** hors API exige un appel explicite à `invalidate_hierarchy()` : une validation O(n) à chaque lecture détruirait le bénéfice du cache (mesuré : `descendants` ×10 0,8 → 35 ms, `view_for` ×10 115 → 941 ms sur 1 224 formations). Les appelants doivent donc privilégier l'API ; le test `test_direct_mutation_of_parent_and_echelon_invalidated` documente ce contrat. Comparaison avec un recalcul naïf après **chaque** mutation API : 8 tests, 0 écart.

### 9.2 Plafonds opérationnels (conservé)

Voir §3 et §8 : ils suppriment la régression de résolution en guerre sans toucher aux règles tactiques.

### 9.3 Sauvegarde bit-exacte (conservé)

Voir §3 : les flottants sont restaurés octet pour octet ; l'empreinte canonique ne peut plus masquer une perte de bits due au parseur décimal.

### 9.4 Tentative d'index spatial — **abandonnée**

Un index spatial a été implémenté puis **reverté** sur instruction du chef. Il préservait l'identité stricte des batailles (`diag_identity` / `diag_all`, diff = 0), mais toutes les variantes testées étaient **plus lentes** que le balayage linéaire : rayons de 660–832 unités couvrant environ 60 % du champ 2000 × 1400, le coût de construction/requête dépassait le gain. Rejeux enregistrés : tour 3 **2 838 ms** (index) contre **2 091 ms** (sans), tour 4 **3 398 ms** contre **2 138 ms** ; une variante « packed » montait à **3 518 ms / 6 172 ms**. Aucun fichier de cette tentative n'est commité ; seul l'index hiérarchique reste en place.

## 10. Benchmarks avant / après

Banc versionné : `tools/bench_phase1.gd`. Avant = arbre extrait de `git archive 57e5d25` (import Godot préalable) ; après = worktree final. Même graine, mêmes états synthétiques, 6 scénarios (paix/guerre × 300/600/1224 formations), 10 répétitions pour `descendants` et `view_for`. Résultats complets : `~/backups/gs1914-phase1-reprise-2026-11-17/bench_phase1_results.txt` (à versionner avec le rapport si le chef le demande ; valeurs reproduites ci-dessous).

| Scénario | `descendants` ×10 av. → apr. | `view_for` ×10 av. → apr. | `resolve` av. → apr. |
|---|---|---|---|
| paix / 300 | 24,7 → 0,1 ms | 287,7 → 44,4 ms | 162,3 → 32,4 ms |
| paix / 600 | 25,4 → 0,1 ms | 356,5 → 39,4 ms | 241,1 → 22,4 ms |
| paix / 1224 | 39,5 → 0,3 ms | 532,5 → 61,1 ms | 491,8 → 31,1 ms |
| guerre / 300 | 22,2 → 0,1 ms | 334,2 → 37,1 ms | 191,4 → 19,4 ms |
| guerre / 600 | 28,7 → 0,1 ms | 351,9 → 48,9 ms | 262,0 → 23,6 ms |
| guerre / 1224 | 39,6 → 0,2 ms | 575,4 → 57,6 ms | 409,2 → 31,4 ms |

Gains observés : `descendants` ≈ ×100–200, `view_for` ≈ ×8–10, `resolve` ≈ ×5–16. `resolve` mesure `TurnResolver.resolve()`, cœur de `end_turn()` ; le temps de `NationAgent.decide()` n'est pas inclus dans cette ligne. Aucun gain non mesuré n'est annoncé. Le banc n'est pas branché sur la CI (il est lent).

## 11. Simulations intégrées

- **Tests de décision (vue injectée)** : `tests/integration/test_ai_phase1_scenarios.gd`, 10 scénarios du brief + anti-répétition + non-abandon. Ils injectent `region_intel` dans la vue pour tester finement les seuils, la décision, les ordres et le brouillard, mais **ne jouent aucune bataille de bout en bout** : ils ne démontrent pas à eux seuls la chaîne mécanique demandée par le brief.
- **Tests de bout en bout (vrais mécanismes)** : `tests/integration/test_ai_phase1_e2e.gd`, 6 scénarios, graine `19140101`. Aucune vue n'est modifiée à la main : les formations ennemies sont réellement placées dans `state`, l'observation est écrite par une reconnaissance résolue (`BattleManager._record_reconnaissance`), les postures et ordres passent par `TurnResolver.resolve()` / `GameSession.end_turn()`, et les issues sont lues dans `state.battles`, `state.regions` et le contrôle territorial.
  - (a) offensive française contre la garnison allemande plus faible : victoire des attaquants, pertes enregistrées, occupation de la région et retraite du défenseur vers une région voisine amie sans ennemi ;
  - (c/7/8) région inconnue → reconnaissance → rapport daté (estimation 129 000 hommes pour 127 820 réels, jamais l'effectif exact) → nouvelle décision au tour suivant refusant l'assaut → statut `stale` puis `unknown` après `stale_turns`, avec retour à la reconnaissance ;
  - (4/5) capitale allemande en `hold_at_all_costs` (le défenseur ne rompt jamais et conserve la région) et position secondaire en `delay` (rupture, occupation adverse et repli MIL-01 vers un territoire ami) ;
  - (6) deux IA (Allemagne + France) sur 4 tours via `end_turn()` : batailles résolues, opérations sur plusieurs tours, aucun ordre contradictoire ou rejeté, brouillard vérifié à chaque tour pour les deux camps (aucun effectif ennemi réel exposé).
- **Simulation longue** : `tools/simulate_phase1.gd`, graine `19140101`, deux IA en guerre sur la Lorraine, 8 tours. Sortie : `SIM seed=19140101 tours=8 formations_initiales=608` … `SIM FIN tour=8 formations=1243 batailles=10 evenements=395`. Journaux par tour : 2 à 9 ordres, approches `assault` / `limited_attack` / `reconnaissance`, postures émises quand nécessaires, 0 à 2 batailles par tour.
- Les résultats sont cohérents avec le modèle : l'IA attaque désormais des positions défendues, hésite face au renseignement ancien, et la boucle reste déterministe à graine fixe.

## 12. Résultats

| Objectif | Résultat |
|---|---|
| A — Renseignement exploité sans système parallèle | atteint (D/I/T/F, paramètres P) |
| B — IA stratégique niveau 2 (attaque / attente / renfort / reconnaissance) | atteint (D/I/T/F, seuils P) |
| C — Performance `GameState` et war-turn | atteint : régression 472 s → 2,1 s ; gains mesurés au §10 |
| C — Directive du chef sur l'index spatial | respectée : tentative abandonnée et documentée |
| Non-régression MIL-01 | suite verte, UI stratégique et tactique validée ; retraite et postures vérifiées en bataille réelle |
| Couverture de bout en bout (vraies batailles, deux IA) | atteinte : 6 scénarios e2e sans injection de vue ; suite complète 144 tests, 0 échec, 375 s (< 400 s) |
| Aucune modification de décision validée | respecté |

## 13. Tests

- `bash tests/run.sh` : **144 tests réussis, 0 échec**, durée totale mesurée **375 s** (limite < 400 s) ; 110 tests de base + 7 renseignement + 8 index + 12 décision + 6 e2e + 1 aller-retour flottants. Fichiers de test ajoutés pendant la reprise :
  - `tests/unit/test_intelligence_phase1.gd` (7 tests) ;
  - `tests/unit/test_hierarchy_index.gd` (8 tests) ;
  - `tests/integration/test_ai_phase1_scenarios.gd` (12 tests de **décision**, vue injectée via `_set_target_intel`) ;
  - `tests/integration/test_ai_phase1_e2e.gd` (6 tests de **bout en bout**, 119 contrôles, aucune vue injectée ; voir §11).
- **Distinction à retenir** : les scénarios de décision vérifient les seuils et la cohérence des ordres sur une vue contrôlée ; les scénarios e2e vérifient la chaîne réelle `formations dans state` → bataille → rapport → `IntelSystem.view_for` → décision → tour résolu. Les deux familles sont conservées : la première est un filet de sécurité fin, la seconde apporte la preuve d'intégration exigée par le brief.
- `tests/run_tests.gd` analyse désormais `tests/unit/` **et** `tests/integration/`.
- Exports reproductibles (workflow `game-tests.yml`) exécutés localement avec l'interpréteur GIS épinglé : `[PASS] data/game/world_map.json à jour`, `[PASS] scénarios à jour`, `[PASS] fiches MIL-01 à jour`.
- Conformément à l'arbitrage T3, `test_world_and_state.gd::test_save_float_roundtrip_is_bit_exact` vérifie `433.90000000000003` (1 ULP), `-0.0`, les structures imbriquées, la lisibilité des anciens nombres JSON nus et un aller-retour disque complet.
- Message connu et antérieur à la reprise : `ERROR: Parse JSON failed. Error at line 0: Unterminated string` pendant `test_world_and_state.gd::test_save_load_roundtrip_and_integrity`. Le test reste réussi et `run.sh` reste vert ; ce diagnostic n'est pas lié au correctif bit-exact et reste à investiguer séparément.

## 14. Vérifications visuelles

`bash tests/run.sh` inclut les deux fumées d'interface :

- `tests/ui_smoke.gd` → **RÉSULTAT UI : VALIDÉ** ;
- `tests/battle_ui_smoke.gd` → **RÉSULTAT UI BATAILLE : VALIDÉ**.

Elles couvrent notamment l'onglet Renseignement, les ordres d'approche et de posture, la vue tactique, la pause, la rupture de combat et le retour à la carte. Aucune capture supplémentaire n'a été générée pendant cette phase.

## 15. Limites

- Pas de déclaration de guerre, d'alliance, de coalition ni de traité offensif initié par l'IA (Phase III, hors périmètre).
- Renseignement limité aux régions contrôlées/voisines et aux rapports de reconnaissance/combat : pas d'interception, décryptage, espionnage, ni renseignement économique ou technologique.
- `fresh_turns`, `stale_turns`, fiabilités, ratios et plafonds sont des valeurs **PROPOSÉ** à faire valider par le directeur ; aucun statut n'a été promu.
- Estimation ennemie volontairement approximative (arrondis, fourchettes) : elle ne prétend pas reproduire une connaissance exacte.
- Index hiérarchique : les changements de taille de `state.formations` sont détectés automatiquement (O(1)) ; un changement direct de parent ou d'échelon hors API exige `invalidate_hierarchy()` (validation O(n) par lecture exclue pour raison de performance, voir §9.1). Les appelants doivent privilégier `register_formation()` / `set_formation_parent()` / `remove_formation()`.
- Banc et simulation ne sont pas intégrés à la CI (coût volontairement exclu du workflow).
- Aucune poussée GitHub n'a été effectuée : la CI du chef reste à exécuter après relecture.

## 16. Rapports de renseignement et anomalies signalées

- Mémoire : `state.regions[rid]["recon_reports"][nation]` contient `turn`, `date`, `source`, `units_seen`, `confirmed_units`, `armies_seen`, `spotted_estimate`, `estimate`, `fortification_level`, `enemy_nations`.
- Normalisation au chargement : `CombatData.normalize_battle()` et `GameState._normalize_numbers()` convertissent ces champs en entiers.
- Statut `stale` : rapport âgé (au-delà de `fresh_turns`), ou nouvelle armée ennemie non couverte par le rapport, ou perte de vue directe ; `unknown` : aucun rapport valide ou rapport expiré au-delà de `stale_turns`.
- Anomalie ouverte : le diagnostic de parseur JSON décrit au §13. Aucune autre anomalie fonctionnelle détectée dans la suite.
- Conflits documentaires : aucun nouveau conflit avec les décisions validées ; les contradictions historiques R-01 à R-14 restent inchangées.

## 17. Commits

Découpage atomique effectué sur `dev/mil01-finalisation` (aucun `push`, aucun merge, aucun `main`) :

| # | Hash | Titre |
|---|---|---|
| 1 | `9dccf81e37a8a51701d0278edd9445891028eeb8` | `perf(gamestate): index hiérarchique sûr et mobilisation par API` |
| 2 | `053725f330ff6950f98fdc4abba2cd3f2351e9c4` | `feat(intelligence): rapports datés, vieillissement et vue filtrée` |
| 3 | `218af2e2126daab43d3c7598ffcf07a5e8aff80d` | `feat(ai): décisions opérationnelles sans constantes en dur` |
| 4 | `cdecd087854fc1233401ebc2e1cad42052362edd` | `fix(save): sérialisation bit-exacte des flottants` |
| 5 | `5b6070563b83fdf97b10d0da97325e480706bbf3` | `test(phase1): renseignement, index, scénarios IA, simulation et banc` |
| 6 | `e61b189da88ffe2028d79de09d294499bc2766ee` | `docs(phase1): rapport final, avancement et changelog` |
| 7 | `1fc1e2e97e076cd364de842d73393b3ff14f0923` | `test(save): aller-retour bit-exacte des flottants` |
| 8 | `59822e0db2f7be40dcd2d40ed0fd68abcb790cd5` | `test(phase1): scénarios de bout en bout (vraies batailles et deux IA)` |
| 9 | *(ce commit)* | `docs(phase1): distingue tests de décision et e2e, durée mesurée` |

Chaque commit porte le trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commits ajoutés ensuite (T5, scénarios de bout en bout) : `59822e0` test(phase1), `05a8122` docs(phase1). L'ensemble (`57e5d25..05a8122`) a été poussé par le chef (Claude Code) sur `origin/dev/mil01-finalisation` le 17/11/2026. Aucun merge, `main` non modifié.

## 18. CI et validation finale

- Commande locale équivalente au workflow `game-tests.yml` : `bash tests/run.sh` → **144 tests réussis, 0 échec, 375 s** ; UI et UI bataille validées.
- Commandes locales équivalentes aux étapes d'export du même workflow : `build_game_data.py --check`, `build_scenario.py --check`, `render_fiches.py --check` → trois `[PASS]`.
- Aucune donnée cartographique n'a été touchée : `tools/map/validate_all.sh --full` n'a pas été relancé (workflow `map-validation.yml` non déclenché par ces fichiers).
- CI GitHub : workflow « Tests du jeu (Godot 4.7.2) », run 44135025673 sur `05a8122` → **succès** (1 min 47 s). Seul avertissement : la dépréciation de Node.js 20 pour `actions/checkout@v4` et `actions/setup-python@v5`. Elle ne concerne pas la Phase I et n'est pas traitée.
- Contre-vérification locale du chef : `bash tests/run.sh` → 138 tests réussis avant T5 ; 144 après T5 (exécution du worker).

---

*Rapport rédigé par l'agent `opencode` (worker) — 17/11/2026. Aucune décision validée modifiée ; blocs PROPOSÉ laissés en l'état.*
