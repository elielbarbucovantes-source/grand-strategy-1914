# MIL-01 — Rapport de la phase 3 : mobilisation autonome de l'IA

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

**Mandat :** validation de la phase 2 et décisions MIL01-P2-D1 à D3 (registre `docs/decisions/DECISIONS_MIL01_T047_T057.md` §6) ; vérification visuelle de l'onglet Armée ; phase 3 (T-052).

**Garanties respectées :**
- travail sur `dev/mil01-finalisation` seulement ;
- aucune fusion ; aucune autre branche modifiée ;
- différences nationales et paramètres provisoires de la phase 2 conservés ;
- aucun travail de la phase 4 commencé.

**Légende :** D = documenté, I = implémenté, T = testé, F = fonctionnel en jeu, P = provisoire ou incomplet.

---

## 1. Décisions de la phase 2 appliquées avant la phase 3

| Décision | Application | D | I | T |
|---|---|---|---|---|
| MIL01-P2-D1 : retard ferroviaire à zéro | Inchangé (`rail_gap_months = 0`). `MOBILISATION.md` §7 distingue ce qui fonctionne (allocation ferroviaire sous 15 %) de ce qui dépend de la carte (délai des districts sans liaison). | oui | oui | oui (phase 2) |
| MIL01-P2-D2 : survivants d'une armée anéantie | Commit `d312488`. Retraite sûre : les services **rejoignent le territoire** et restent présents. Sans retraite ni capture établie : **pertes** (sort inconnu). Prisonniers **seulement** à la capitulation. | oui | oui | oui (`test_annihilated_army_survivors`) |
| MIL01-P2-D3 : tués et blessés | Recherche de proportions documentées prévue en phase 5 ; système actuel provisoire | oui | — | — |

---

## 2. Vérification visuelle de l'onglet Armée

**Méthode :**
- vrai rendu à l'écran (Godot 4.7.2 avec affichage, fenêtre de 1 214 × 955 sur ce poste) ;
- script reproductible `tests/army_tab_capture.gd` ;
- captures inspectées une à une, puis versées dans `docs/project/captures_mil01/` :
  - France au départ ;
  - France après deux mois de posture générale ;
  - France après une bataille ;
  - Allemagne avec ses deux échelons.

**Problèmes constatés et corrigés** (`src/ui/game_ui.gd`) :

| # | Problème vu à l'écran | Cause mesurée | Correction |
|---|---|---|---|
| 1 | **Texte coupé à droite** et barre de défilement horizontale ; données illisibles (« hors ca… », « 21954… ») | Rangée d'allocation de trois champs côte à côte, plus large que le panneau de 440 px | Allocation sur trois lignes |
| 2 | Même défaut, persistant | Libellés des lignes de formations sans retour à la ligne (614 px) | Libellés à retour à la ligne automatique |
| 3 | Même défaut pour l'Allemagne (panneau de 545 px, débordant de l'écran) | Boutons « Préparer les défenses de Poméranie, Mecklembourg et Brandebourg » (537 px) | Libellé tronqué, texte complet en infobulle. Largeur minimale du panneau vérifiée pour les 7 puissances : 342 px, inférieure à 440. |
| 4 | Nombres illisibles (2603864) | Aucun séparateur | Séparateur de milliers (2 603 864) |
| 5 | « Approximation non documentée » répétée trois fois, long paragraphe en italique | Texte redondant | Une seule mention, en rouge |
| 6 | Bouton « Appeler l'échelon suivant » affiché pour une puissance en bloc unique, où il est toujours refusé | Absence de condition | Bouton masqué pour le bloc unique |
| 7 | Aucune indication que l'allocation doit totaliser 100 % | — | Titre « Répartition des moyens (total : 100 %) » |

**Vérifié après correction, à l'écran :**
- texte entièrement visible ;
- catégories 1 à 7 lisibles ;
- échelons allemands détaillés ;
- avertissement du bloc unique ;
- boutons de posture (le vrai bouton a été pressé) ;
- champs d'allocation ;
- liste des mobilisations publiques ;
- données cohérentes avec l'état : mai 1914, 2 195 454 incorporés, 1 507 pertes après la bataille.

**Limites de la vérification :**
- Un seul format de fenêtre a été vu : 1 214 × 955, l'écran de ce poste. Le format nominal du projet (1 600 × 900) n'a pas été vu.
- La barre d'onglets du panneau (10 onglets) défile horizontalement. Ce comportement est antérieur et non modifié.
- Le panneau exige un défilement vertical pour atteindre la liste des mobilisations publiques et les formations.
- Les autres onglets n'ont pas été inspectés. Le défilement horizontal n'a été coupé que pour l'onglet Armée.
- Les flèches des champs numériques sont petites (style Godot par défaut).

Une erreur de **mon script de capture**, pas du jeu, a été corrigée : les premières captures précédaient parfois le dernier rendu, d'où l'attente de `frame_post_draw`.

---

## 3. Phase 3 : ce qui a été réalisé

| Élément | D | I | T | F | P |
|---|---|---|---|---|---|
| Agent de mobilisation (`src/ai/mobilization_agent.gd`), appelé pour chaque puissance conduite par l'IA | oui | oui | oui | oui (fin de tour) | — |
| Doctrines nationales (`data/rules/ai_doctrines.json`), 7 profils, 7 différents | oui | oui | oui | oui | **toutes PROPOSÉES, non sourcées** |
| Perception limitée à la vue du gouvernement ; propres effectifs ajoutés à la vue (`own_forces`) | oui | oui | oui | — | — |
| Réaction aux postures publiques étrangères (frontalières ou lointaines, alliés exclus) | oui | oui | oui | oui | — |
| Guerre, allié en guerre, armées ennemies visibles, occupation, tension générale | oui | oui | oui | oui | Poids PROPOSÉS |
| Escalade immédiate, désescalade d'un niveau après une période calme (hors guerre) | oui | oui | oui | oui | Spirale entre blocs (§5) |
| Échelon suivant selon la doctrine | oui | oui | oui | oui | — |
| Allocation situationnelle (logistique si districts occupés ou réservistes bloqués) | oui | oui | indirect | oui | Identique pour tous |
| Aucune information secrète utilisée | oui | oui | oui | — | — |
| Facteurs « situation économique » et « calendrier historique » | oui (absents, motivés) | non | — | — | ECO non défini ; HIS-01 non scripté |

**Modifications du code existant :**
- `NationAgent.decide` ajoute les ordres de mobilisation ;
- `IntelSystem.view_for` ajoute `own_forces` ;
- `GameSession.create` charge les doctrines ;
- `MobilizationSystem.summary` renvoie le journal public propre et parcourt les formations sans tri (même résultat).

---

## 4. Comportements de chaque puissance (exécution réelle de `tests/ai_mobilization_report.gd`)

Joueur observateur, sans aucun ordre. Pa = paix, Pr = préparatoire, Gé = générale ; entre parenthèses, le score de menace perçu.

| Scénario | Allemagne | France | Russie | Autriche-Hongrie | Italie | Empire ottoman | Royaume-Uni |
|---|---|---|---|---|---|---|---|
| **A.** Europe calme, 8 mois | Pa | Pa | Pa | Pa | Pa | Pa | (observateur) |
| **B.** Mobilisation générale russe au mois 1, retour de la Russie à la paix au mois 2 | Gé dès le mois 1 (30), maintenue (60) | Gé au mois 2 (26) | **remobilise** : Gé (40) | Gé dès le mois 1 (24) | Pa (13) | Pa (24) | (observateur) |
| **C.** Guerres franco-allemande et austro-russe au mois 1, paix au mois 4 | Gé, échelon 2 au mois 2 ; reste Gé après la paix (60) | Gé ; reste Gé (26) | Gé ; reste Gé (40) | Gé, échelon 2 au mois 3 ; reste Gé (31) | **Pr** pendant la guerre (78) ; **Pa** 1 mois après la paix | **Pr** (47) ; **Pa** 2 mois après la paix | (observateur) Pa (30) |
| **D.** Guerre anglo-allemande seule (observateur : France) | Gé (114), échelon 2 au mois 2 | (observateur) | Gé au mois 2 (51) | Gé dès le mois 1 (42 : allié en guerre) | Pa (36 à 40) | Pr au mois 3 (34) | **Gé** (100) |

- **Conservation des effectifs** vérifiée pour les 7 puissances à la fin de chaque scénario.
- **Durée :** A, 8 mois en 4,9 s ; B, 8 mois en 12,3 s ; C, 12 mois en 19,4 s ; D, 6 mois en 6,7 s. Ces durées incluent les calculs de diagnostic du rapport.
- **Un tour seul** (scénario C, mesuré à part) : 0,33 s au mois 1, 1,2 à 1,6 s après mobilisation (plus de 1 100 formations).

**Lecture :**
- La guerre et les mobilisations frontalières déclenchent des réponses rapides, différenciées par doctrine.
- L'Italie reste en paix face aux crises et ne passe en posture préparatoire que dans une guerre générale.
- Le Royaume-Uni ne mobilise qu'en guerre.
- L'Empire ottoman réagit à la tension générale.
- **Spirale :** après une mobilisation entre blocs rivaux, aucun belligérant ne désescalade. Même la Russie, initiatrice, remobilise en réponse à l'Allemagne (§5).

---

## 5. Limites restantes

1. **Spirale d'escalade** entre blocs rivaux, testée (`test_escalation_spiral_between_rival_blocs`). Aucun mécanisme de détente n'existe (DIP-01 à DIP-04).
2. **Doctrines non sourcées.** Elles s'inspirent de 1914 (connaissance générale), avec des seuils et des poids de jeu PROPOSÉS.
3. **Solidarité d'alliance forte.** Un allié en guerre vaut 30 points, ce qui suffit pour la posture générale de l'Allemagne, de la France et de l'Autriche-Hongrie (seuil 20). L'Autriche-Hongrie mobilise donc dès qu'un allié est en guerre. À ajuster si ce n'est pas souhaité.
4. **Ni économie ni calendrier** dans les décisions (ECO non défini ; HIS-01).
5. **Pas de renseignement sur les volumes** (INT-01/02).
6. **L'IA mobilise mais n'attaque pas** les régions défendues (phase 6).
7. **Performance.** Les vues nationales coûtent jusqu'à 0,9 s par tour après mobilisation : effectif de chaque armée recalculé en parcourant toutes les formations, code antérieur, coût quadratique. À traiter en phase 6.
8. **Allocation situationnelle** identique pour toutes les puissances : aucune différence nationale n'est sourcée.

---

## 6. Tests

### 6.1 Exécutés sur ce poste (Godot 4.7.2)

| Commande | Résultat |
|---|---|
| `python tools/export/build_game_data.py --check`, `build_scenario.py --check`, `render_fiches.py --check` | Voir le compte rendu de fin de phase (relancés avant publication) |
| `bash tests/run.sh` | Voir le compte rendu de fin de phase |
| Tests unitaires, avant publication | **77 réussis, 0 échec** |
| `tests/ui_smoke.gd` (après les corrections d'interface) | **VALIDÉ** |
| `tests/ai_mobilization_report.gd` | Exécuté (§4) ; non probatoire |
| `tests/army_tab_capture.gd` (avec affichage) | Exécuté ; 4 captures inspectées (§2) |

### 6.2 Nouveaux tests

**`tests/unit/test_ai_mobilization.gd`, 8 fonctions :**

| Test | Ce qu'il vérifie |
|---|---|
| `test_doctrines_are_national_and_flagged` | 7 doctrines PROPOSÉES, non présentées comme sourcées, différenciées |
| `test_no_mobilization_without_tension` | 6 mois sans tension : aucune mobilisation |
| `test_reaction_to_public_foreign_mobilization` | Réponses de l'Allemagne, de l'Autriche-Hongrie, puis de la France ; Italie et Royaume-Uni en paix ; Russie (IA) maintenue |
| `test_war_triggers_mobilization_and_next_echelon` | Guerre : posture générale, échelon suivant allemand, Russie alliée mobilisée, Italie en paix, conservation |
| `test_ai_uses_only_accessible_information` | Volumes français et ordre secret russe sans effet sur la décision allemande ; aucun volume ni effectif étranger dans la vue |
| `test_escalation_spiral_between_rival_blocs` | Limite documentée |
| `test_stand_down_when_threat_disappears` | Empire ottoman : mobilisation sous tension, retour à la paix après la paix, menace sous le seuil, conservation |
| `test_ai_campaign_is_deterministic` | Deux campagnes identiques |

**`test_mobilization_phase2.gd`, un test ajouté :** `test_annihilated_army_survivors` (MIL01-P2-D2).

### 6.3 Non couvert

- Rendu au format 1 600 × 900.
- Autres onglets de l'interface.
- Mobilisation de l'IA combinée à des offensives (l'IA n'attaque pas).
- Plus de 12 mois de campagne entre IA.

---

## 7. Fichiers

- **Nouveaux :**
  - `src/ai/mobilization_agent.gd` ;
  - `data/rules/ai_doctrines.json` ;
  - `tests/unit/test_ai_mobilization.gd`, `tests/ai_mobilization_report.gd`, `tests/army_tab_capture.gd` ;
  - `docs/military/MOBILISATION_IA.md` ;
  - `docs/project/captures_mil01/` (4 captures) ;
  - ce rapport.
- **Code modifié :**
  - `src/ai/nation_agent.gd`, `src/domains/intelligence/intel_system.gd`, `src/app/game_session.gd` ;
  - `src/domains/military/mobilization_system.gd`, `force_ledger.gd` ;
  - `src/domains/combat/battle_manager.gd` (survivants, commit `d312488`) ;
  - `src/ui/game_ui.gd`.
- **Tests modifiés :** `tests/ui_smoke.gd`, `tests/unit/test_mobilization_phase2.gd`.
- **Documentation :**
  - `docs/military/MOBILISATION.md`, `PERTES_ET_PRISONNIERS.md` ;
  - `docs/decisions/DECISIONS_MIL01_T047_T057.md` (§6, tableau d'état mis à jour), `DECISIONS_PENDING.md` (AI-01).

---

## 8. Décisions qui pourraient être utiles avant les phases suivantes

1. **Spirale d'escalade.** Est-elle acceptable comme comportement de 1914 ? Faut-il prévoir, plus tard, une détente diplomatique (DIP) permettant aux blocs de désescalader ?
2. **Solidarité d'alliance.** Un allié en guerre suffit-il à déclencher la posture générale (cas de l'Autriche-Hongrie) ?
3. **Doctrines.** Faut-il chercher des sources (plans de mobilisation, chronologie de juillet-août 1914) pour remplacer leurs valeurs PROPOSÉES ?
