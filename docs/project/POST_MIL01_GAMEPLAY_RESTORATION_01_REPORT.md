# POST_MIL01_GAMEPLAY_RESTORATION_01_REPORT — Restauration des boucles stratégiques autonomes

> **Date :** 2026-11-22
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation` (jamais `main`)
> **Référence avant :** `docs/project/POST_MIL01_GAMEPLAY_AUDIT.md`, arbre au commit `5e08928`
> **Nature :** correction et restauration. Aucune nouvelle phase lancée. Aucune fusion, aucune
> réécriture d'historique, aucun push forcé.

---

## 1. Verdict global — **B : gameplay autonome rétabli, avec limitations documentées**

L'audit précédent classait le gameplay « C — incomplet » : chaîne économique coupée, aucune
guerre autonome, quatre personnalités silencieuses, effets politiques ignorés, graines sans
effet et spam diplomatique.

Après restauration, une campagne **passive** de 120 tours produit (graine 1914, contexte paix) :
**276 technologies découvertes, 7 guerres, 134 batailles, 662 investissements, 262 mouvements,
88 propositions d'alliance, 11 alliances actives, 167 propositions de paix** et aucun stock
négatif. Les trois graines produisent désormais des campagnes **différentes mais reproductibles**.

Le grade B est retenu (et non A) parce que plusieurs limitations demeurent : le commerce reste
quasi inexistant, le classement des puissances ne bouge pas, la diffusion technologique n'est
pas opérationnelle, la trahison reste rare et les contextes « crise économique » et « course
technologique » convergent vers le même résultat que la paix à long terme.

---

## 2. Causes précises identifiées

| # | Problème | Cause technique réelle |
|---|---|---|
| 1 | Aucun investissement IA | `EconomicAI.decide()` n'émettait aucun `INVEST_RESOURCE` ; `ResourceSystem.invest()` existait mais n'était appelé que depuis l'UI. |
| 2 | Stocks à zéro permanents | Aucune source de fonds : `stocks[*]["money"]` n'était jamais initialisé ni alimenté. L'investissement était gratuit (pas de coût) et donc jamais budgété. |
| 3 | Recherche bloquée | `phase6_rules.research.resource_cost_per_point = {coal: 0.05, iron: 0.03}` alors que les stocks de charbon/fer restaient à 0 → `affordable = 0`, projets jamais achevés. |
| 4 | Aucune guerre autonome | `Orders.declare_war` n'était produit que par `game_ui.gd`. Aucun IA ne l'émettait. |
| 5 | Tensions initiales nulles | `relations[*]["tensions"] = 0` au 1er janvier 1914 : même une décision de guerre écrite n'aurait eu aucun déclencheur. |
| 6 | Effets politiques absents | `phase7_rules.politics.decisions.costs` utilisait `trust`/`tension` au lieu de `institution_trust`/`social_tension` ; `apply_decision()` ignorait silencieusement ces clés. |
| 7 | 4 profils IA inertes | Seuil `accept_th - 5` trop élevé pour `expansionist`, `opportunist`, `mistrustful`, `ambitious` ; aucun profil n'avait de décision de guerre. |
| 8 | Aucune trahison | Règle `leave_alliance` évaluée **en dernier**, après consommation du budget `max_initiatives_per_turn = 2`. |
| 9 | Graine sans effet | `seed_value` utilisé uniquement pour le départage des batailles ; aucune décision IA, économique ou diplomatique n'en dépendait. |
| 10 | 484 propositions / 120 tours | Cooldown inexistant ; l'IA reproposait chaque tour, y compris à une cible différente pour contourner tout cooldown par cible. |
| 11 | Fausse victoire IDH | `VictorySystem.hdi()` calculait un revenu brut (`industry + money`) sans le rapporter à la population. |
| 12 | Crash MIL-01 en guerre autonome | `BattleSystem._resolve_neutral()` lit `battle["origin"][fid]` ; `origin` ne contenait que les formations ayant **bougé** le tour, pas les armées stationnaires engagées. |
| 13 | Erreur GDScript en paix | `NationAgent._peace_initiatives()` comparait `p["to"]` (un **Array**) à une String dès qu'une paix était proposée. |

---

## 3. Corrections effectuées

### 3.1 Chaîne économique (priorité absolue)
- **`economy_rules.json`** : ajout d'un modèle fiscal (`money_per_worker`, `money_per_industry`,
  `maintenance_share`) et d'un bloc `resources_model.investment` (coût réel de 8 fonds par point
  de taux, plafond 1.0, seuil de gisement).
- **`industry_system.gd`** : recette fiscale dérivée de la main-d'œuvre et de la capacité
  industrielle réellement utilisée, diminuée de la part d'entretien. **Aucune ressource gratuite** :
  sans travail ni industrie, aucun fonds n'est créé (test dédié).
- **`resource_system.gd`** : `invest()` prélève désormais les fonds, plafonne le taux et refuse
  l'investissement si la trésorerie est insuffisante ; nouvelle fonction `best_investment()`
  qui arbitre selon le dépôt, la rareté, le taux restant et le profil économique.
- **`economic_ai.gd`** : l'IA émet un ordre `invest_resource` par tour, avec un taux modulé par
  la prospérité (0,08 si pauvre, 0,15 standard, 0,25 pour un profil industriel lourd).
- **`turn_resolver.gd` / `game_session.gd`** : passage des règles et de la nation aux appels
  d'investissement, avec validation du coût avant acceptation.
- **`phase6_rules.json`** : coût de recherche remplacé par `{"money": 2.0}` — le coût charbon/fer
  bloquait toute progression tant que les stocks étaient vides.

### 3.2 Décisions de guerre autonomes
- **`diplomatic_ai.gd`** : nouvelle fonction `war_decision()` avec garde-fous explicites :
  maturité (aucune guerre avant le tour 7), capacité réelle (forces historiques + effectifs +
  trésorerie), cooldown de 6 tours par État, stabilité minimale, rivalité **stable** ≥ 55,
  seuils de tension/hostilité modulés par `war_likelihood`, risque d'escalade (alliances de la
  cible) et bruit de graine borné. Repli possible vers la médiation pour les profils qui
  valorisent leur réputation.
- **`initial_rivalries.json`** (nouveau) : rivalités et amitiés documentées au 1er janvier 1914
  (Alsace-Lorraine, Bosnie, Triple Alliance, Entente cordiale…). Ce sont un **état initial**,
  pas un script de guerre : la rivalité n'est pas gonflée par les déclarations successives.
- **`game_session.gd`** : chargement de ce contexte au début de campagne, via `RelationsSystem.ensure()`
  avec les règles complètes (correction d'un bug de passage de paramètre qui ne créait que 4
  dimensions au lieu de 7).
- **`intel_system.gd`** : la vue IA expose désormais `seed`, `nation_order`, `proposals`,
  `own_money`, `own_stability` — sans révéler d'information militaire secrète.

### 3.3 Effets politiques
- **`phase7_rules.json`** : `trust` → `institution_trust`, `tension` → `social_tension` dans
  les six décisions. `apply_decision()` applique donc réellement les effets payés.

### 3.4 Personnalités actives
- Seuil de proposition d'alliance assoupli (`accept_th - 15` au lieu de `- 5`).
- `war_likelihood` devient un vrai levier de décision de guerre et de médiation.
- Le profil économique influence désormais le choix de la ressource investie et le taux.

### 3.5 Ordonnancement et trahison
- La rupture d'alliance est évaluée **avant** toutes les autres initiatives, avec un budget
  dédié ; l'ancien bloc en fin de fonction (jamais atteint) a été supprimé.
- Conséquence observée : la confiance chute de 25 par déclaration de guerre (règle existante),
  ce qui rend la trahison atteignable en campagne longue.

### 3.6 Graines significatives
- **`controlled_variation.gd`** (nouveau) : bruit déterministe `sha256(graine|tour|clé|sel)`
  borné à ±1. Même graine + mêmes actions → même résultat ; graines différentes → divergences
  sans loterie.
- Utilisé dans `_score()` (ambiance diplomatique ±1,5), `war_decision()` (±8) et
  `best_investment()` (±25 % relatif). Les intérêts, personnalités et contraintes restent
  les déterminants principaux.

### 3.7 Spam diplomatique
- Cooldown de 6 tours par cible, étendu aux propositions **expirées ou contre-proposées**.
- Cooldown **global** de 6 tours par État : un État ne peut plus proposer chaque tour à une
  cible différente.
- Résultat : 88 propositions en 120 tours contre 484 dans l'audit, pour 11 alliances actives.

### 3.8 Corrections de robustesse révélées par la restauration
- **`military_system.gd`** : `origin` renseigné pour toute formation présente dans une région
  (pas seulement celles qui ont bougé) — corrige le crash du résolveur neutre MIL-01.
- **`nation_agent.gd`** : `p["to"]` traité comme une liste dans `_peace_initiatives()`.
- **`victory_system.gd`** : revenu IDH calculé **par habitant**, supprimant la victoire
  artificielle au tour 8.

---

## 4. Tests ajoutés et adaptations

### 4.1 Nouveau fichier : `tests/unit/test_gameplay_restoration_01.gd` (16 tests)
- investissement payant et refus sans fonds ; extraction démarrée par l'IA ; stocks non
  monétaires modifiés ; recherche achevée avec consommation de fonds ; fiscalité nulle sans
  activité ; effets réels de `social_tension` et `institution_trust` ; absence de guerre avant
  maturité ; garde-fous de capacité ; guerre autonome engageant MIL-01 et les mouvements ;
  trahison émise quand la confiance s'effondre ; les 7 personnalités émettent des ordres ;
  au moins 5 profils donnent des scores distincts ; reproductibilité par graine et divergence
  entre graines ; bruit borné ; bornage des propositions ; absence de fausse victoire IDH.

### 4.2 Tests existants mis à jour **sans affaiblissement d'assertion**
- `test_economy_phase5.gd` : l'investissement vérifie maintenant un coût réel en fonds (l'ancien
  test appelait `invest()` sans règles et ne vérifiait que l'acceptation).
- `test_phase6.gd` : la recherche vérifie la consommation de fonds au lieu de charbon/fer,
  conformément au nouveau coût documenté.
- `test_diplomacy_phase3.gd` : le test de trahison compare **la même cible avant/après**
  (assertion plus directe et plus forte) au lieu de comparer deux paires désormais
  différenciées par les rivalités historiques.
- `test_ai_mobilization.gd` : le test de désescalade désactive explicitement `allow_automatic_war`
  pour isoler la mécanique testée (une nouvelle guerre autonome réintroduirait une tension
  générale et rendrait le scénario incohérent).

**Aucun test supprimé, aucun seuil d'assertion relâché.**

### 4.3 Résultat
`bash tests/run.sh` : **237 tests réussis, 0 échec**, interface et interface de bataille validées,
aucune erreur de script GDScript.

---

## 5. Résultats des simulations et tableau comparatif

Protocole repris de l'audit : graines `1914`, `7`, `2026` ; durées `12`, `24`, `60`, `120` tours ;
contextes 0 (paix), 1 (guerre forcée), 2 (crise économique), 3 (mobilisation), 4 (instabilité),
5 (activité diplomatique), 7 (course technologique). Campagne passive du point de vue du joueur.

### 5.1 Comparatif audit → restauration (graine 1914, 120 tours, contexte paix)

| Métrique | Audit (avant) | Restauration (après) | Statut |
|---|---:|---:|---|
| Technologies découvertes | 0 | **276** | corrigé, observé |
| Ordres de recherche | 42 (sans résultat) | 316 (276 découvertes) | corrigé, observé |
| Investissements exécutés | 0 | **662** | corrigé, observé |
| Guerres déclarées par l'IA | 0 | **7 actives** au T120 (94 déclarations cumulées, nombreuses paix) | corrigé, observé |
| Batailles MIL-01 | 0 | **134** | corrigé, observé |
| Mouvements militaires | 0 | **262** | corrigé, observé |
| Propositions diplomatiques | 484 | **88** | corrigé, observé |
| Propositions de paix | non mesuré | 167 | nouveau, observé |
| Alliances actives | 12 | 11 | stable |
| Trahisons / ruptures | 0 | 0 en paix, **1** en activité diplomatique | partiellement corrigé |
| Crises intérieures | 22 (permanentes) | 0 en paix ; résolues en contexte instabilité | corrigé, observé |
| Commerce (ordres) | 3 | 2 | **non corrigé** |
| Stocks totaux | ~669 | 616 472 | corrigé (échelle monitorée) |
| Stocks négatifs | 0 | 0 | préservé |
| Victoire | IDH fausse possible | `ongoing` à 120 tours | corrigé, observé |
| Différence entre graines | aucune | mesurable (voir §5.2) | corrigé, observé |

### 5.2 Diversité des graines (24 tours, contexte paix)

| Graine | Guerres (T12 / T24) | Alliances (T24) | Propositions | Postures de mobilisation | Commerce | Stock (T12) |
|---|---:|---:|---:|---:|---:|---:|
| 1914 | 2 / 2 | 10 | 34 | 34 | 2 | 44 815 |
| 7 | 2 / 2 | 11 | 30 | 49 | 4 | 44 814 |
| 2026 | 2 / 2 | 11 | 28 | 23 | 3 | 44 822 |

Les divergences portent sur les alliances, le nombre de propositions, la posture de
mobilisation, le commerce et les mouvements (44 / 44 / 42) — pas sur un simple bruit de
bataille.

Reproductibilité vérifiée : deux campagnes avec la même graine et les mêmes actions produisent
des empreintes `checksum()` identiques pour les trois graines (1914, 7, 2026).

### 5.3 Contextes notables (graine 1914, 120 tours)
- **Paix / crise économique / course technologique** : résultats convergents à long terme —
  l'économie se relance seule et les stocks initiaux supplymentaires ne changent pas l'issue.
  Limite documentée.
- **Guerre forcée** : 149 batailles, 1 rupture d'alliance nulle ; le conflit forcé et le conflit
  autonome produisent des dynamiques similaires, ce qui confirme que MIL-01 est bien sollicité.
- **Instabilité** : jusqu'à 1 260 décisions politiques et 1 121 changements de gouvernement
  en 60 tours (graine 7), crises résolues (0 active à 120 tours) — le bug de clé était bien la
  cause du blocage.
- **Activité diplomatique** : 107 propositions pour 10 alliances, **1 trahison observée** à 120 tours.

---

## 6. Personnalités observées

Expérience contrôlée (22 États forcés au même profil, 24 tours, graine 1914) :

| Profil | Propositions | Alliances | Guerres | Découvertes |
|---|---:|---:|---:|---:|
| prudent | 25 | 15 | 10 | 49 |
| conciliant | 64 | 18 | 8 | 49 |
| honorable | 64 | 18 | 8 | 49 |
| expansionniste | 11 | 2 | 3 | 49 |
| opportuniste | 73 | 2 | 2 | 49 |
| méfiant | 12 | 2 | 2 | 49 |
| ambitieux | 73 | 2 | 2 | 49 |

**Aucun profil n'est plus silencieux** (audit : 0 action pour 4 profils). Les différences sont
mesurables : les profils coopératifs forment 15 à 18 alliances, les profils méfiants/agressifs
2 seulement, avec des appétences de guerre distinctes. La personnalité module désormais
également l'investissement (choix de ressource et taux) et la probabilité de médiation.

---

## 7. Nouvelles interactions entre systèmes

- `économie → industrie → recherche` : fiscalité issue du travail, investissement payant,
  extraction accrue, stocks consommés par l'industrie, recherche financée par la trésorerie.
- `diplomatie → militaire` : rivalités historiques + décision de guerre → déclaration →
  mobilisation → mouvements → batailles MIL-01 → logistique.
- `militaire → diplomatie` : chaque déclaration de guerre réduit la confiance de tous les
  observateurs, ce qui rend la trahison et la désescalade possibles.
- `politique → diplomatie` : stabilité intérieure faible bloque l'initiative de guerre ; les
  effets de décisions correctement appliqués résorbent les crises.
- `graine → toutes les décisions` : un seul bruit déterministe, borné, partagé entre diplomatie,
  guerre et investissement.

---

## 8. Régressions et adaptations

- **Régressions fonctionnelles détectées puis corrigées** : crash du résolveur neutre sur armée
  stationnaire, comparaison Array/String dans les initiatives de paix, passage incomplet des
  règles à `RelationsSystem.ensure()`.
- **Adaptations de tests** : deux tests de l'état initial « relations neutres » ont été ajustés
  dans leur **présupposé de configuration** uniquement (voir §4.2), sans modifier leurs assertions
  de comportement.
- **Aucune régression résiduelle** détectée dans la suite complète (237 tests verts).

---

## 9. Limitations restantes

1. **Commerce toujours quasi inexistant** (2 ordres / 120 tours). Le seuil de déficit de
   `EconomicAI.decide()` n'est pas atteint dans une économie où la production est immédiatement
   consommée. Non corrigé : cela demanderait une refonte de la demande industrielle, hors périmètre.
2. **Classement des puissances inchangé** (Russie / Allemagne / Autriche-Hongrie du tour 12 au
   tour 120) : aucun rattrapage dynamique observable.
3. **Diffusion technologique non opérationnelle** : `diffusion_cost_factor` reste défini sans
   effet observable ; non traité (audit §7).
4. **Trahison rare** : 1 occurrence en 120 tours avec contexte diplomatique actif, 0 en paix.
   Possible et testée, pas fréquente.
5. **Convergence des contextes** : crise économique et course technologique rejoignent la paix
   à 120 tours — la résilience économique est peut-être trop forte.
6. **Concentration de richesse** : un État atteint ~230 000 fonds à 120 tours sans seuil
   d'aise économique ; aucune règle de redistribution ou d'inflation.
7. **Rejet résiduel** : 1 ordre `call_next_echelon` rejeté (`échelon en cours non entièrement
   appelé`) — comportement de l'IA de mobilisation préexistant, non bloquant.
8. **Validation d'export Python indisponible** : `tools/export/build_scenario.py --check` échoue
   sur `ModuleNotFoundError: pyproj` (environnement). L'export Godot `--export-release Linux
   x86_64` réussit. Les 40 fichiers JSON sont syntaxiquement valides.

---

## 10. Distinction rigoureuse des états

| Élément | Implémenté | Testé | Observé en simulation | Réellement fonctionnel | Amélioration hypothétique |
|---|---|---|---|---|---|
| Investissement IA payant | ✔ | ✔ | ✔ (662) | ✔ | — |
| Fiscalité sans ressource gratuite | ✔ | ✔ | ✔ | ✔ | — |
| Extraction progressive | ✔ | ✔ | ✔ | ✔ | — |
| Technologies (276 / 120 tours) | ✔ | ✔ | ✔ | ✔ | — |
| Décision de guerre autonome | ✔ | ✔ | ✔ (7 guerres) | ✔ | — |
| Médiation / désescalade | ✔ | partiel | non isolé | partiel | ✔ (fréquence non mesurée) |
| Effets politiques corrigés | ✔ | ✔ | ✔ (crises résolues) | ✔ | — |
| 7 personnalités actives | ✔ | ✔ | ✔ | ✔ | — |
| Trahison | ✔ | ✔ | ✔ (1 en 120 tours) | ✔ (rare) | ✔ (fréquence) |
| Graines significatives | ✔ | ✔ | ✔ | ✔ | — |
| Réduction du spam | ✔ | ✔ | ✔ (88 vs 484) | ✔ | — |
| Victoire IDH honnête | ✔ | ✔ | ✔ | ✔ | — |
| Commerce | inchangé | inchangé | ✘ (2 ordres) | ✘ | ✔ (refonte demande) |
| Diffusion technologique | inchangé | inchangé | ✘ | ✘ | ✔ |
| Rattrapage des puissances | inchangé | inchangé | ✘ | ✘ | ✔ |

---

## 11. Validation technique finale

- `bash tests/run.sh` : **237 / 237**, UI et UI de bataille validées.
- 40 fichiers JSON valides (`data/`).
- Export Godot Linux x86_64 : **succès**.
- Sauvegardes et migrations : tests existants verts (formats 3 à 9).
- Matrice 3 graines × 7 contextes × 4 durées : exécutée sans erreur GDScript.
- Arbre de travail contrôlé avant publication ; commit unique sur `dev/mil01-finalisation` ;
  push uniquement vers `origin/dev/mil01-finalisation`.

---

**Fin de mission. Aucune nouvelle phase lancée. En attente de validation du directeur.**
