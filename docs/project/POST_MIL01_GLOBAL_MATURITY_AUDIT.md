# POST_MIL01_GLOBAL_MATURITY_AUDIT — Audit transversal de maturité

> **Date :** 2026-11-23
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation` — **aucune modification de gameplay**
> **Commit audité :** `acab75a584840ad8fe8599b0eeec476b7c1a7b76` (« feat(gameplay03): interfaces
> commerce, technologie et historique diplomatique », 2026-11-23 17:30:33 +0100)
> **État initial :** arbre propre, local = distant (`0/0`). **État final :** arbre propre, commit inchangé.
> **Nature :** audit strict. Aucun fichier source, paramètre, donnée, test ou sauvegarde du jeu
> n'a été modifié. Seul le présent rapport est créé.

---

## 1. Résumé exécutif

Le projet dispose désormais de boucles de jeu réellement actives : investissement et fiscalité,
recherche et diffusion technologique, commerce payant et tracé, classement dynamique, guerres
et trahisons autonomes, interface joueur pour trois domaines. Une campagne passive de 120 tours
produit ~300 technologies, 7 guerres, 10 livraisons, 10 transferts et un classement qui change
de leader selon la graine.

Cependant, l'audit met en évidence **quatre problèmes critiques ou majeurs** qui empêchent de
considérer le jeu comme mature :

1. **Contournement du consentement commercial** : une ordre forgé peut débiter le stock d'un
   État tiers sans son accord (confirmé par exécution).
2. **Décalage de règles de victoire** : la victoire militaire est automatique alors que les
   règles validées disent « affichée, sans fin de partie automatique » ; le vainqueur du pacte
   universel est le premier participant, pas le proposant.
3. **Bonus technologiques massivement inertes** : `industry_mult` et ~22 effets militaires ou
   logistiques ne sont jamais appliqués ; les quatre profils technologiques produisent des
   ordres de recherche identiques (confirmé par exécution).
4. **Dégradation de performance et croissance non bornée** : temps moyen par tour multiplié par
   ~14 entre T1–12 et T121–240, avec un pic isolé à **133 s pour un seul tour** ; mémoire et
   journaux croissent linéairement sans plafond.

Le verdict global est **B** : jeu fonctionnel, mais avec des défauts importants encore présents.

---

## 2. Méthodologie

- **Audit statique** : parcours exhaustif de `src/`, `data/`, `docs/` et `tests/` avec recherche
  des définitions de règles et de leurs lecteurs ; deux explorations indépendantes (cohérence ;
  IA/équilibrage/victoire).
- **Sondes reproductibles** (scripts hors dépôt, `/tmp/opencode/`) : reproduction de quatre
  problèmes, mesure HDI, vérification des indicateurs de victoire, reproductibilité par graine,
  sauvegardes, textes UI.
- **Campagnes longues** : `gp_audit_long.gd`, graines 1914 / 7 / 2026, 120 / 240 / 480 tours,
  contextes 0 (paix), 1 (rivalité), 2 (crise économique), 6 (instabilité) ; mesures par tranche
  de tours, compteurs d'événements, mémoire statique et empreinte finale.
- **Tests existants** : `tests/run.sh` (254 tests + 3 suites UI) exécuté sans modification.
- **Aucune inspection graphique réelle** n'a été effectuée : l'environnement est headless. Les
  vérifications d'interface sont textuelles et structurelles uniquement.

---

## 3. Résultats par système

### 3.1 Économie, commerce et logistique

| Constat | Gravité | Statut | Preuve |
|---|---|---|---|
| Fiscalité générée indépendamment de la consommation d'intrants | MAJEUR | confirmé | `industry_system.gd:37-45` : recette = workers + capacité, ajoutée avant consommation ; une nation sans charbon/fer gagne de l'argent. |
| `industry_mult` jamais appliqué | MAJEUR | confirmé + reproduit | `technology_tree.json:13…` vs aucun lecteur ; sonde : capacité France 1,2793 avant et après acquisition de `electrification`. |
| Contournement du consentement vendeur | **CRITIQUE** | confirmé + reproduit | `market_system.gd:62-89` ne compare pas `order["nation"]` et `order["from"]` ; sonde : `Orders.trade("france","german_empire","france","coal",20)` validé (`validate=""`) après établissement d'un passage. |
| Route recalculée sans contrôle du résultat | MAJEUR | confirmé | `market_system.gd:109-121` ignore `r["ok"]` et le retour de `commit()` ; une expédition peut partir avec `path=[]` et `capacity_committed=0`. |
| Quota d'importation mal compté | MODÉRÉ | confirmé | `_arrived_this_turn()` compte les ordres créés (`t["turn"]`), pas les livraisons reçues. |
| Mauvais chemin de règle pour l'investissement | MODÉRÉ | confirmé | `resource_system.gd:57-58` lit `rules["resources_model"]` alors que les appelants passent `rules["economy_model"]` ; valeurs par défaut identiques aujourd'hui. |
| Investissement joueur appliqué hors résolution et silencieux | MAJEUR | confirmé | `game_session.gd:163-170` : retour `""` même si `invest()` échoue ; aucun plafond `max_investments` pour le joueur. |
| Ports non persistés | MODÉRÉ | confirmé | `transport_system.gd:53-57` modifie `net.ports` en mémoire, absent de `state.transport`. |
| `prices` d'état fantôme, `transport_rules.limits` ignorés | MINEUR | confirmé | champs initialisés mais jamais lus. |

### 3.2 Recherche et diffusion

| Constat | Gravité | Statut | Preuve |
|---|---|---|---|
| Profils technologiques inertes | MAJEUR | confirmé + reproduit | `phase6_ai.gd:30,45` lit `p.get(domain)` avec des domaines français (`energie`, `aviation`…) alors que les profils définissent `research/air/naval/comms` ; sonde : `scientist` et `naval` produisent les mêmes ordres `["submarine_design","rail_mobilization"]`. |
| ~22 effets technologiques sans effet | MAJEUR | confirmé | `armor_bonus`, `munitions_mult`, `road_speed`, `naval_combat`, `artillery_bonus`, `casualty_recovery`, `logistics_efficiency`, etc. : aucun lecteur dans `src/`. |
| `capture_cost_factor`, `max_intercepts`, `advance_decryption`, `max_route_length` morts | MODÉRÉ | confirmé | définis dans les règles, jamais consommés. |
| `tech.duration` affichée mais non consommée | MODÉRÉ | confirmé | `game_ui.gd:941` vs `tech_system.gd:176-227` (progression par `cost` uniquement). |
| Diffusion technologique opérationnelle | — | confirmé | 10 transferts livrés à T120, 22 à T240 ; coût réduit et délai respectés. |

### 3.3 Diplomatie, confiance et engagements

| Constat | Gravité | Statut | Preuve |
|---|---|---|---|
| `join_requires_consent` inversé | MAJEUR | confirmé | `alliance_system.gd:80-92` : `if not bool(cfg.get("join_requires_consent", true)): return "consentement requis"` → avec `true`, le contrôle ne s'exécute jamais. |
| Sortie d'alliance laisse le traité legacy actif | MAJEUR | confirmé + reproduit | sonde : après `AllianceSystem.leave()`, `active_treaties_between("france","german_empire","trade")` reste non vide → prix préférentiel et transit persistent. |
| Dérive relationnelle positive non compensée | MAJEUR | confirmé (code), effet à mesurer | `diplomacy_rules.json:10` : `tensions +0,5`, `hostility +0,1`, `rivalry +0,1` par mois pour toutes les paires ; à T240, 9 guerres actives. |
| `dependence`/`interests` figés et non lus | MODÉRÉ | confirmé | initialisés une fois, jamais mis à jour ni consommés. |
| `initiative`, `stocks` (éco), `military` (pol), `level` (attributions) non lus | MODÉRÉ | confirmé | profils incomplètement câblés. |
| `memory_window_turns` non utilisé | MAJEUR | confirmé | `relations_system.gd:51-54` accumule sans purge ; 6 435 événements à T240. |
| `proposal_sent`, `crisis_response`, `SEND_MESSAGE` sans effet de règle | MODÉRÉ | confirmé | journal seulement. |
| Changements de gouvernement illimités | MAJEUR | confirmé | `negotiated` sans crise ni coût ni cooldown ; 20 clics → stabilité 0, réputation −100. |
| Trahisons et garde-fous opérationnels | — | confirmé | 5 ruptures à T120, 9 à T240 ; cinq motifs déterministes et personnalités différenciées. |

### 3.4 Politique, démographie et MIL-01

- Stabilité initiale identique (65) pour les 22 États ; tensions sociales et confiance
  identiques : aucune différenciation politique de départ (`phase7_rules.json:6-11`).
- `crisis.chance_per_turn` non lu : le système est purement déterministe par seuils.
- MIL-01 fonctionne quand un conflit est sollicité : 135 batailles cumulées à T120, 262
  mouvements ; aucun crash du résolveur neutre depuis la correction R01 (0 erreur GDScript sur
  toutes les campagnes).
- Aucune régression détectée dans la suite de tests (254 verts).

---

## 4. Résultats des campagnes longues

| Graine | Tours | Guerres | Technologies | Livraisons | Transferts | Trahisons | 1re puissance | Victoire |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1914 | 120 | 7 | 297 | 10 | 10 | 5 | Italie (70,26) | ongoing |
| 7 | 120 | 7 | 302 | 26 | 8 | 6 | Russie (69,33) | ongoing |
| 2026 | 120 | 7 | 308 | 25 | 18 | 5 | Espagne (71,20) | ongoing |
| 1914 | 240 | 9 | 488 | 10 | 22 | 9 | Espagne (73,72) | ongoing |
| 1914 | 480 | **136** | 640 | 14 | 22 | 13 | Russie (75,69) | ongoing |

- Aucun blocage de simulation : toutes les campagnes atteignent le tour demandé, y compris
  480 tours (batailles tactiques résolues automatiquement par la sonde). Le récapitulatif final
  de la campagne 480 tours n'a toutefois pas été produit dans la limite de 3 600 s.
- **Cascade de guerres tardive** : 9 guerres actives à T240, **136 à T480** — effet combiné de
  la dérive relationnelle positive et des seuils de `war_decision` (hypothèse H1 confirmée par
  simulation).
- Le classement change réellement : Russie → Italie → Espagne selon la graine et la durée.
- Les trois graines produisent des trajectoires et des classements différents.
- Contextes à 120 tours (graine 1914) : rivalité forcée → 149 batailles, 27 transferts,
  Allemagne 1re ; crise économique → identique à la paix (résilience) ; instabilité → 1 guerre,
  20 batailles, 2 trahisons, Allemagne 1re (la faible stabilité bloque l'initiative de guerre).
- Reproductibilité : deux campagnes même graine, mêmes conditions → `checksum()` identique ;
  graine différente → empreinte différente.

---

## 5. Audit de l'intelligence artificielle

- **Activité** : les 22 États instruisent des ordres chaque tour ; économie, diplomatie,
  recherche, politique et mobilisation sont réévaluées mensuellement.
- **Personnalités** : les profils diplomatiques et économiques produisent des différences
  mesurables (alliances 15-18 vs 2 ; profil autarkique sans commerce). Les profils
  technologiques sont **inertes** (cf. §3.2). Champs non lus : `initiative` (diplo), `stocks`
  (éco), `military` (politique), `level` (attributions).
- **Asymétries** : l'IA peut investir en ressources, le joueur non (aucun bouton) ; le joueur
  peut déclencher des crises, intercepter, négocier le pacte universel, conclure des
  conférences et interrompre des liaisons — l'IA ne le fait jamais. `BUILD_AIRBASE`,
  `PRODUCE_AIRCRAFT` et `CREATE_FLEET` ne sont utilisés ni par l'IA ni par l'UI.
- **Stratégie dominante** : rester passif reste viable — aucun État n'a atteint une condition
  de victoire en 240 tours, et le joueur peut observer sans agir.
- **Décisions répétitives** : propositions diplomatiques encore nombreuses (1 050 en 240 tours,
  256 en 120), malgré les cooldowns ; le classement n'est pas lu par l'IA (décisions fondées sur
  la perception locale uniquement).

---

## 6. Équilibrage des 22 États

- **Sept grandes puissances** : l'Allemagne a la plus forte capacité industrielle (1,535) et
  3,8 M de réserves ; le Royaume-Uni 282 unités de charbon mais seulement ~126 000 soldats sur
  carte (le reste outre-mer) ; la Russie 175 M d'habitants avec l'industrie par habitant la plus
  faible ; l'Empire ottoman est structurellement faible (0,232 d'industrie, quasi sans
  charbon/fer) ; l'Italie manque d'intrants (0,5/0,5).
- **Quinze secondaires** : la Belgique (0,987 d'industrie pour 7,5 M) et la Suisse (0,788 pour
  3,9 M, sans gisements) disposent d'une industrie « gratuite » ; l'Albanie et le Luxembourg ont
  0 réserve → mobilisation impossible ; Norvège, Suède et Serbie ont des réserves disproportionnées
  sans coût économique (`economy_constraint_status = OUVERT`).
- **Stabilité identique** pour les 22 États ; 286 champs `stats` du scénario sont `null` et
  servent uniquement à l'affichage (« À DÉFINIR »), jamais à la simulation.
- 9 rivalités et 4 amitiés initiales ne couvrent que 11 États ; les 11 autres restent aux
  valeurs par défaut.

---

## 7. Conditions de victoire

| Condition | Accessibilité | Constat |
|---|---|---|
| Militaire ≥ 90 % | atteinte mais non observée en 240 tours | **Décalage de règle** : `game_rules.json:66` dit « sans fin de partie automatique », mais `game_session.gd:217` appelle `check_victory()` qui termine la partie. Occupation comptée comme contrôle malgré `require_controlled_not_occupied: true` non lu. Branche départage morte. |
| HDI ≥ 1,25× médiane / 6 mois | non atteinte en 240 tours | Score maximal 0,549 contre médiane 0,536 (ratio 1,025) à T24. `avg_food` biaisé : `food_ratio` absent de la baseline, initialisé à 1,0 puis moyenné avec un 1,0 supplémentaire → ~+0,15 de score artificiel. `food` calculé puis ignoré. HDI fondé sur la souveraineté, pas sur le contrôle. |
| Pacte universel | théoriquement accessible, jamais réalisé | 21 acceptations requises ; l'IA ne propose jamais et `tick_universal` saute le joueur. **Vainqueur erroné** : `members[0]` est le premier participant, pas le proposant. Condition de 90 % de régions souveraines rendue impossible par toute occupation en cours. Paramètre lu avec les mauvaises règles (`phase6` au lieu de `diplomacy`). |

Aucune victoire prématurée ni impossible à déclarer n'a été observée dans les campagnes tests ;
mais deux conditions sont effectivement **inatteignables en pratique** (HDI, pacte).

---

## 8. Performances et stabilité

| Période | Temps moyen / tour (graine 1914, 240 tours) |
|---|---:|
| T1–12 | 1 386 ms |
| T13–24 | 2 260 ms |
| T25–60 | 1 498 ms |
| T61–120 | 2 658 ms |
| T121–240 | **7 406 ms** (pic maximal **133 045 ms** sur un tour) |
| T241+ | **11 100 ms** (pic 130 240 ms) |

- La campagne 480 tours a atteint le tour 480 mais n'a pas pu produire son récapitulatif dans
  le délai de 3 600 s : **les campagnes de 40 ans ne sont pas praticables** dans l'état actuel.
- Mémoire statique : 56 Mo au départ → 76 Mo à T120 → 126 Mo à T240 → **310 Mo à T480**.
- Journaux : 6 056 événements / 6 435 mémoires / 1 050 propositions à T240 ; **18 339 événements
  et 23 121 mémoires à T480**.
- 240 historiques d'ordres, 240 entrées de classement (ce dernier borné).
- Croissance non bornée confirmée pour `events`, `memory`, `proposals`, `orders_history`,
  `trade`, `transfers`, `intercepts`, `naval.operations` et `politics.*`.
- `RelationsSystem.reputation()` parcourt toute la mémoire 22 fois par tour ;
  `IntelSystem.view_for()` la duplique pour chaque IA. Coût quadraticité confirmé par la
  dégradation du temps par tour.
- Aucune fuite au sens Godot (mémoire statique croît avec les données sérialisées, pas de
  création d'objets non libérés détectée), mais accumulation structurelle.

---

## 9. Interface et expérience joueur

- 13 onglets accessibles ; sections R03 (commerce, technologie, historique) intégrées sans
  doublon de navigation.
- **Textes trompeurs confirmés** : page Industrie — « Les capacités sont inconnues (données à
  sourcer) … sans effet de production mesurable » alors que `IndustrySystem` produit réellement
  1,2793 pour la France ; prix commercial étiquetés « PROPOSÉS » bien qu'ils soient réellement
  débités ; durée technologique affichée mais non consommée.
- `national_balance()` affiche des valeurs `null` en campagne (données « À DÉFINIR »).
- Libellé « les 10 onglets » dans `tests/ui_smoke.gd:60` alors qu'il y en a 13.
- **Aucune inspection graphique réelle** n'a été effectuée (environnement headless) ; seules la
  construction des pages, la largeur de panneau (520/460 px) et l'absence d'erreurs GDScript ont
  été vérifiées. Aucune affirmation de validation visuelle n'est faite ici.

---

## 10. Sauvegardes

- Sauvegarde/chargement en cours d'accord commercial et scientifique : succès, `checksum()`
  identique, expéditions/coopérations/transferts conservés.
- Campagne de 24 tours sauvegardée puis rechargée : `checksum()` identique, `migrated_from = 0`.
- Formats 3 → 9 : tests de migration existants conservés et verts.
- Aucune sauvegarde existante n'a été écrasée : tous les essais utilisent `user://test_saves/`.
- Risque identifié : les structures non bornées (§8) sont toutes sérialisées et incluses dans
  `checksum()`, donc le coût de sauvegarde croît avec la durée de campagne.

---

## 11. Liste exhaustive des problèmes

| # | Description | Gravité | Système | Reproduction | Preuve | Conséquence | Correction recommandée | Difficulté | Dépendances |
|---|---|---|---|---|---|---|---|---|---|
| P-01 | `validate()` accepte `nation ≠ from` (consentement vendeur contourné) | **CRITIQUE** | Commerce | `Orders.trade("france","german_empire","france","coal",20)` avec passage | `validate=""` | Débit d'un tiers sans accord | Exiger `nation == from` ou consentement explicite | Faible | Aucune |
| P-02 | Victoire militaire automatique contre règle validée | **CRITIQUE** | Victoire | Atteindre 90 % de contrôle | `game_session.gd:217` vs `game_rules.json:66` | Fin de partie non consentie | Retirer l'appel ou corriger la règle | Faible | Docs |
| P-03 | Vainqueur du pacte universel = premier participant | **CRITIQUE** | Victoire | Signer le pacte avec la France comme proposante | `peace_system.gd:125-133`, `victory_system.gd:91` | Mauvais vainqueur | Inclure le proposant dans `members` | Faible | Aucune |
| P-04 | `industry_mult` et ~22 effets technologiques inertes | **MAJEUR** | Tech/Économie/MIL | Capacité France avant/après `electrification` | 1,2793 → 1,2793 | Technologies sans valeur stratégique réelle | Câbler les effets ou les retirer | Élevée | Équilibrage |
| P-05 | Profils technologiques identiques | **MAJEUR** | IA | Comparer `scientist` et `naval` | ordres identiques | Personnalités 2 sur 4 inertes | Mapper domaines ↔ profils | Faible | Aucune |
| P-06 | Dérive relationnelle sans désescalade | **MAJEUR** | Diplomatie | 480 tours | 136 guerres actives à T480 | Cascade de guerres tardive | Ajouter facteur de désescalade | Moyenne | Équilibrage |
| P-07 | Croissance non bornée + pics > 130 s/tour | **CRITIQUE** | Performance | Campagnes 240/480 tours | 11,1 s/tour après T240, 310 Mo à T480, dépassement du délai 3 600 s | Partie injouable à long terme | Borner listes, indexer mémoire | Élevée | P-08 |
| P-08 | `memory_window_turns` non utilisé | **MAJEUR** | Diplomatie | T240 | 6 435 événements | `reputation()` O(n) par IA | Appliquer fenêtre glissante | Faible | P-07 |
| P-09 | Traitée legacy active après sortie d'alliance | **MAJEUR** | Diplomatie | `AllianceSystem.leave()` | sonde : `true` | Transit/prix préférentiel persistants | Synchroniser cycle de vie | Moyenne | Aucune |
| P-10 | `join_requires_consent` inversé | **MAJEUR** | Diplomatie | Rejoindre sans accord | `alliance_system.gd:80-92` | Adhésion forcée | Inverser condition | Faible | Aucune |
| P-11 | Investissement joueur silencieux et hors plafond | **MAJEUR** | Économie | Fonds insuffisants via UI | `game_session.gd:163-170` | Faux succès, contournement budget | Retour d'erreur + plafond | Faible | Aucune |
| P-12 | HDI inatteignable et biaisé | **MAJEUR** | Victoire | T24 | ratio 1,025 ; `avg_food` > 1 | Condition de victoire morte | Corriger moyenne et seuil | Moyenne | Équilibrage |
| P-13 | Pacte universel bloqué et mal attribué | **MAJEUR** | Victoire | Guerre en cours | 90 % souveraineté requise | Condition morte | Réconcilier conditions | Moyenne | P-03 |
| P-14 | Route commerciale recalculée sans contrôle | **MAJEUR** | Commerce/Logistique | Deux ordres sur liaison saturée | `market_system.gd:109-121` | Expédition sans réseau | Vérifier `ok` et `commit()` | Faible | Aucune |
| P-15 | Fiscalité sans contrepartie productive | **MAJEUR** | Économie | Nation sans charbon/fer | `industry_system.gd:37-45` | Revenu gratuit | Subordonner aux intrants | Moyenne | Équilibrage |
| P-16 | Textes UI trompeurs | MODÉRÉ | Interface | Page Industrie | « capacités inconnues » | Compréhension erronée | Mettre à jour | Faible | Aucune |
| P-17 | `national_balance()` affiché à `null` | MODÉRÉ | Interface | Page Économie | valeurs `À DÉFINIR` | Information vide | Utiliser données réelles | Faible | Aucune |
| P-18 | Profils `initiative`/`stocks`/`military`/`level` non lus | MODÉRÉ | IA | Lecture code | champs définis | Différenciation réduite | Câbler ou retirer | Faible | Aucune |
| P-19 | Stabilité initiale identique pour 22 États | MODÉRÉ | Équilibrage | `phase7_rules.json:6-11` | 65 partout | Peu de relief politique | Différencier avec sources | Moyenne | Données |
| P-20 | 286 champs `stats` nuls (affichage seul) | MODÉRÉ | Données | `campaign_1914.json` | `À DÉFINIR` | Interface peu informative | Sourcer ou masquer | Moyenne | Données |
| P-21 | Champs de règles morts (capture_cost_factor, max_intercepts, limits…) | MODÉRÉ | Multi | grep | jamais lus | Règles trompeuses | Nettoyer | Faible | Aucune |
| P-22 | Ports non persistés | MODÉRÉ | Logistique | `SET_PORT_STATUS` + recharge | état perdu | Incohérence sauvegarde | Sérialiser | Faible | Aucune |
| P-23 | IA ne propose pas crise/pacte/conférence | MODÉRÉ | IA | grep ordres | asymétrie joueur/IA | Monde moins dynamique | Ajouter initiatives IA | Moyenne | Aucune |
| P-24 | Classement non lu par l'IA | MODÉRÉ | IA | `power_rank_system.gd` | aucun lecteur | Pas de stratégie globale | Exposer dans vue filtrée | Moyenne | Secret |
| P-25 | Graine d'interception indépendante de `seed_value` | MODÉRÉ | Renseignement | `turn_resolver.gd:53-56` | formule sans graine| Variabilité réduite | Inclure graine | Faible | Aucune |
| P-26 | Itérations de Dictionary non triées | MINEUR | Determinism | `diplomatic_ai.gd:178` etc. | ordre d'insertion | Fragilité après sérialisation | Trier explicitement | Faible | Aucune |
| P-27 | Libellé « les 10 onglets » | MINEUR | Test/UI | `ui_smoke.gd:60` | 13 onglets | Documentation fausse | Corriger texte | Faible | Aucune |
| P-28 | Joueur ne peut pas investir en ressources | MINEUR | Interface/IA | aucun bouton | asymétrie | Action IA inaccessible | Ajouter bouton | Faible | P-11 |
| P-29 | `proposal_sent`/messages sans effet | MINEUR | Diplomatie | `negotiation_system.gd:85,139` | journal seul | Actions cosmétiques | Ajouter effets ou retirer | Faible | Aucune |

**Distinction** : P-01 à P-15 sont **confirmés** (code et/ou exécution). P-07 dépend des
mesures de performance (confirmées). Aucun problème de cette liste n'est une simple hypothèse,
sauf l'exploitabilité de P-01 **depuis l'interface actuelle** (la faille d'API est confirmée,
aucun bouton ne la déclenche aujourd'hui).

---

## 12. Limites de l'audit

- Aucune inspection graphique réelle (environnement headless) : lisibilité et ergonomie à
  1600×900 et 1280×720 non vérifiées visuellement.
- La campagne 480 tours a produit ses snapshots mais pas son récapitulatif final (délai de
  3 600 s atteint) ; les données 120/240 tours sont complètes.
- Les effets de l'équilibrage initial (réserves disproportionnées, stabilité identique) n'ont pas
  fait l'objet de simulations comparatives dédiées.
- L'accessibilité réelle du pacte universel n'a pas été testée avec 21 acceptations forcées ;
  l'analyse est statique.
- Aucune optimisation ni correction n'a été appliquée, conformément à la mission.

---

## 13. Verdict général — **B**

**Jeu fonctionnel avec des défauts importants encore présents.**

Les systèmes forment un ensemble cohérent et réellement interconnecté : les boucles économique,
technologique, diplomatique et militaire produisent des effets observables et les interfaces R03
les rendent accessibles. La stabilité technique est bonne (0 erreur GDScript, sauvegardes
fiables, reproductibilité par graine).

Le grade A est écarté à cause de trois familles de défauts : (1) des failles de validation
permettant de contourner des coûts ou le consentement (P-01, P-11, P-14) ; (2) des règles de
victoire partiellement contradictoires ou inatteignables (P-02, P-03, P-12, P-13) ; (3) une
dégradation de performance et une accumulation de données non bornées qui rendent les campagnes
très longues coûteuses (P-07, P-08).

Le grade C est écarté : aucun système majeur n'est inexistant, et les tests de non-régression
sont tous verts.

---

## 14. Feuille de route priorisée (non implémentée)

- **P0 — bloquants** : P-01 (consentement commercial), P-02/P-03 (victoire militaire et pacte),
  P-11 (investissement joueur), P-14 (route commerciale).
- **P1 — majeurs** : P-04/P-05 (effets et profils technologiques), P-06/P-08 (dérive et mémoire
  diplomatique), P-07 (bornage des historiques et performance), P-09/P-10 (cohérence des
  engagements), P-12/P-13 (conditions de victoire), P-15 (fiscalité).
- **P2 — importants** : P-16/P-17/P-27 (textes et données UI), P-18/P-23/P-24 (IA), P-19/P-20
  (équilibrage initial), P-21/P-22/P-25.
- **P3 — secondaires** : P-26, P-28, P-29, et la documentation des zones non sourcées.

**Cette feuille de route n'est pas commencée.** Le rapport est livré sans correction de gameplay,
sans commit de jeu et sans push ; il attend la validation du directeur.
