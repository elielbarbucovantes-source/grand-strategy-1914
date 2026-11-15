# MIL-01 — Rapport de la phase 4 : Territorial Force britannique

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

**Mandat :** validation de la phase 3 et décisions MIL01-P3-D1 à D3 (travaux futurs) ; phase 4 consacrée à la Territorial Force (T-050, T-054).

**Garanties respectées :**
- travail sur `dev/mil01-finalisation` seulement ;
- aucune fusion ; aucune autre branche modifiée ;
- système diplomatique non modifié ;
- phase 5 non commencée.

**Légende :** D = documenté, I = implémenté, T = testé, F = fonctionnel en jeu (vérifié à l'écran ou par le test d'interface), P = provisoire ou incomplet.

---

## 1. Décisions de la phase 3

Registre `docs/decisions/DECISIONS_MIL01_T047_T057.md` §7.

| Décision | Traitement |
|---|---|
| MIL01-P3-D1 : la spirale d'escalade n'est pas acceptable ; désescalade diplomatique future ; pas de démobilisation automatique à la paix | Documentée et inscrite pour une phase « diplomatie et IA stratégique ». Comportement actuel inchangé et signalé dans `MOBILISATION_IA.md` §5. |
| MIL01-P3-D2 : réaction graduée à la guerre d'un allié | Inscrite dans la même phase future : elle dépend des relations et engagements diplomatiques. **Non intégrée** en phase 4. |
| MIL01-P3-D3 : doctrines fondées sur des sources | Plan de recherche préparé (`docs/history/RECHERCHE_DOCTRINES_1914.md`), avec le classement « documenté / interprétation / paramètre de jeu ». Aucune source consultée à ce stade. |

---

## 2. Phase 4 : Territorial Force

| Exigence | D | I | T | F | Provisoire ou estimé |
|---|---|---|---|---|---|
| Effectifs propres : 268 777, catégorie distincte des réguliers et des réserves | oui | oui | oui | oui (section de l'onglet Armée) | — (sourcé) |
| Répartition en Grande-Bretagne (14 divisions, aucune en Irlande) | oui | oui | oui | oui (armées sur la carte) | **ESTIMATION** (source de 1920) |
| Ventilation par arme | oui | oui | indirect | oui | **ESTIMATION** (proportions de l'armée régulière) |
| Incorporation avec la posture générale seulement, appel intégral, transit propre | oui | oui | oui | oui | Transit de 1 mois **PROVISOIRE** |
| Communications, blocage, report en bataille (règles communes) | oui | oui | indirect (code commun testé en phase 2) | — | — |
| Service intérieur : refus de quitter le territoire national | oui | oui | oui | oui (refus motivé) | — |
| Volontariat outre-mer (T-054) : délai, scission, nouvelle armée | oui | oui | oui | bouton présent (vu à l'écran) ; volontariat non exécuté à l'écran | Délai de 3 mois et part de 1,0 **PROVISOIRES** |
| Conservation et absence de double comptage | oui | oui | oui | — | — |
| Sauvegarde (format 3) ; format 2 refusé avec message | oui | oui | oui | — | — |
| IA britannique : incorporation avec la posture générale ; aucun ordre d'envoi à l'étranger | oui | oui | oui | — | L'IA ne propose pas de volontariat |

**Sources consultées en phase 4 :**
- **War Office 1922, p. 25-26.** Commandements territoriaux et divisions, situation d'avril 1920 ; texte OCR.
- **War Office 1922, p. 153, Section 8.** Territorial Force servant à l'étranger, sur l'**image du fac-similé**. Au début de décembre 1914 : 69 218 hommes (France 22 026, Égypte 16 539, Inde 24 356, Gibraltar 2 011, Malte 4 286).
  - Ce chiffre sert de **repère de vraisemblance** pour le délai provisoire de 3 mois avant l'outre-mer.
  - Ce n'est pas un taux de volontariat. Le tableau ne chiffre pas les départs antérieurs.

---

## 3. Vérification de l'absence de double comptage et de la conservation

| Contrôle | Résultat | Test |
|---|---|---|
| Réservoir britannique = Army Reserve + Special Reserve (209 280), sans la Territorial Force | Exact | `test_distinct_category_in_data_and_scenario` |
| Armée active inchangée (247 432) | Exact | idem |
| Les autres puissances n'ont pas de Territorial Force | Exact | idem |
| Pas d'unité territoriale avant l'incorporation | Exact | idem |
| Posture préparatoire : pas d'incorporation | Exact | `test_embodiment_only_with_general_posture` |
| Pas d'apparition instantanée (transit) | Exact | idem |
| Unités + services territoriaux = 268 777 après incorporation | Exact | idem |
| Présents britanniques après mobilisation complète = 126 309 + 209 280 + 268 777 = 604 366 | Exact (aussi dans `balance_report`) | `test_no_double_counting_after_full_mobilization` |
| Volontariat total ou partiel sans création ni perte | Exact | `test_home_service_restriction_and_overseas_volunteers`, `test_partial_volunteering_splits_units` |
| Invariants propre et national, à chaque étape | Exacts | `_conserved` dans chaque test |

---

## 4. Vérification de l'interface (à l'écran)

Les captures `docs/project/captures_mil01/05_royaume_uni_territorial_force.png` et `06_royaume_uni_armees.png` ont été produites par `tests/army_tab_capture.gd` et inspectées.

- **Section « Territorial Force » :**
  - non incorporés : 0 sur 268 777 ;
  - incorporés : 268 777 ;
  - présents : 233 870 en service intérieur et 34 907 en services, soit **268 777** ;
  - mention de la catégorie distincte et des délais provisoires.
- **Ligne 5 « Présents »** : elle précise désormais « dont Territorial Force ». Sans cette précision, le total de 436 646 mélangeait sans le dire réguliers, réservistes et territoriaux.
- **Armées « Territorial Force (service intérieur) n° 1 »**, chacune avec son bouton « Volontaires pour le service outre-mer » (infobulle explicative).
- **Corrigé à l'écran :** le nom des armées territoriales affichait l'identifiant technique (« region_001 »). Le même défaut, présent sur les armées de réserve de la phase 2, est corrigé aussi.
- **Non corrigé, antérieur à cette phase :** « Forces du temps de paix — Angleterre du Sud — Angleterre du Sud » (région répétée).
- **Non vérifié à l'écran :** l'exécution d'un volontariat (testée hors écran) et le format 1 600 × 900.

---

## 5. Tests et intégration continue

| Commande (sur ce poste) | Résultat |
|---|---|
| `build_game_data.py --check`, `build_scenario.py --check`, `render_fiches.py --check` | PASS |
| `bash tests/run.sh` | **84 réussis, 0 échec** ; interface stratégique VALIDÉE ; interface de bataille VALIDÉE |
| `tests/balance_report.gd` | Royaume-Uni à 604 366 présents ; 999 unités après mobilisation complète (980 avant la Territorial Force) ; batailles du temps de paix inchangées |
| `tests/army_tab_capture.gd` (affichage réel) | 6 captures produites et inspectées |
| GitHub Actions | Voir le compte rendu de fin de phase (connu après publication) |

**Nouveau fichier :** `tests/unit/test_territorial_force.gd`, 7 fonctions :
- catégorie distincte ;
- incorporation seulement en posture générale ;
- absence de double comptage ;
- service intérieur et volontariat ;
- volontariat partiel ;
- sauvegarde ;
- IA britannique.

---

## 6. Fichiers

- **Nouveaux :**
  - `src/domains/military/territorial_force.gd` ;
  - `tests/unit/test_territorial_force.gd` ;
  - `docs/military/TERRITORIAL_FORCE.md` ;
  - `docs/history/RECHERCHE_DOCTRINES_1914.md` ;
  - deux captures ;
  - ce rapport.
- **Code modifié :**
  - `mobilization_system.gd` (branchement, résumé, conservation, nom des armées de réserve) ;
  - `military_system.gd` (service intérieur) ;
  - `orders.gd`, `turn_resolver.gd`, `game_session.gd` ;
  - `intel_system.gd`, `nation_agent.gd` ;
  - `save_repository.gd`, `game_state.gd` (format 3) ;
  - `game_ui.gd`.
- **Données :**
  - `data/history/military_forces_1914.json` (répartition, repère de déploiement) ;
  - `data/rules/forces_rules.json` (`territorial_force`) ;
  - `data/scenarios/campaign_1914.json` (régénéré) ;
  - fiche britannique (régénérée).
- **Outils :** `tools/export/build_scenario.py`.
- **Tests :** `tests/army_tab_capture.gd`.
- **Documentation :** registre (§7, état de T-050 et T-054), `MOBILISATION.md`, `MOBILISATION_IA.md`.

---

## 7. Limites et points ouverts

1. **Délais et volontariat PROVISOIRES.** Le transit (1 mois), le délai avant l'outre-mer (3 mois) et la part de volontaires (1,0) ne viennent d'aucune source consultée.
2. **Répartition** estimée à partir d'une source de 1920 ; effectifs par division inconnus.
3. **Qualité et instruction** non modélisées : les unités territoriales combattent comme les autres.
4. **Garnisons outre-mer** (Inde, Égypte, Méditerranée) hors de la carte : le principal emploi de la Territorial Force en 1914 n'est pas représenté.
5. **L'IA** ne propose jamais de volontariat outre-mer.
6. **Sauvegardes de la version 2** (développement des phases 2 et 3) refusées. Une migration ne pourrait pas reconstituer avec certitude l'incorporation si la posture générale était déjà adoptée.
7. **Types d'engagement et intensité (T-048, T-055).** Ils figuraient dans la phase 4 du plan initial, mais la phase 4 autorisée est consacrée à la Territorial Force. Ils ne sont **ni commencés ni planifiés**.

## 8. Décisions qui vous reviennent

1. **T-048 et T-055 (types d'engagement, fourchettes de pertes) :** à quelle phase les rattacher ?
2. **Paramètres provisoires de la Territorial Force** (transit, délai avant l'outre-mer, part de volontaires) : faut-il chercher des sources (règlement de 1907 et 1908, Imperial Service Obligation) ?
3. **Volontariat outre-mer par l'IA :** faut-il le prévoir, par exemple dans la phase consacrée à l'IA stratégique ?
