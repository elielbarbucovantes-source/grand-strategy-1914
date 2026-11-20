# POST_MIL01_GLOBAL_AUDIT — Audit général du jeu

> **Date :** 2026-11-20
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **Nature :** AUDIT uniquement. Aucun code source, paramètre, donnée historique ou fichier du
> dépôt n'a été modifié, à l'exception du présent rapport. Aucun problème découvert n'a été corrigé.
> **Outils temporaires :** scripts d'inspection créés dans `/tmp/opencode/`, hors du dépôt.

---

## 1. Résumé exécutif

Le projet est une **simulation stratégique fonctionnelle mais incomplète** (catégorie B). Les sept
phases livrent des systèmes réellement exécutables et cohérents entre eux : 213 tests automatisés
réussis, 66 scénarios de phase × 3 graines réussis, campagnes de 12 à 120 tours sans erreur,
aucun stock négatif détecté, sauvegardes déterministes.

Cependant, trois problèmes majeurs empêchent de le classer comme « jeu complet techniquement
jouable » : (1) la **victoire diplomatique n'est pas atteignable par l'interface**, (2) les
**personnalités IA sont définies mais non différenciées en pratique**, (3) le **multijoueur réseau
n'est pas implémenté** — seul un socle local déterministe existe, comme documenté. Des textes
d'interface obsolètes présentent en outre des fonctionnalités opérationnelles comme « NON
FONCTIONNEL ».

Le classement ne repose pas sur le nombre de tests réussis, mais sur ces écarts fonctionnels
observés.

## 2. État du dépôt et de la branche

| Contrôle | Résultat |
|---|---|
| Branche active | `dev/mil01-finalisation` |
| Arbre de travail avant audit | propre |
| `HEAD` local | `0758b4b23fa588433a5bd9db71744119a2a006ea` |
| `HEAD` distant | identique (`ahead/behind 0/0`) |
| Commits dans l'historique | 95 |
| Fichiers GDScript / lignes | 59 / 12 067 |
| Tests unitaires | 22 fichiers `test_*.gd` |
| Fichiers de données JSON | 37 |

Aucune modification de code pendant l'audit. Le seul fichier créé est ce rapport.

## 3. Architecture générale

La séparation simulation/interface est globalement respectée : `src/domains/` contient les
systèmes (military, diplomacy, economy, politics, victory, technology, transport, intelligence),
`src/simulation/` l'état et la résolution, `src/app/` les façades de session, `src/ui/` l'interface.
`GameState` est sérialisable et ne dépend pas de l'interface.

Cartographie simplifiée des dépendances :

```
TurnResolver ──▶ DiplomacySystem ──▶ Negotiation / Alliance / Crisis / Peace / POW / Conference
             ──▶ MilitarySystem / BattleManager ──▶ ForceLedger
             ──▶ EconomySystem ──▶ Demography / Resource / Industry / Market / MilitaryEconomy
             ──▶ TechSystem / AirSystem / NavalSystem / PoliticalSystem
             ──▶ LogisticsSystem ──▶ TransportNetwork / TransportRouter / CrossingSystem
             ──▶ VictorySystem ──▶ PoliticalSystem / PeaceSystem / IndustrySystem
GameSession ──▶ toutes les façades + vues filtrées (IntelSystem, MultiplayerSystem)
```

Risques identifiés : `VictorySystem` dépend de quatre sous-systèmes (large couplage) ; les
références en mémoire (`transport_network`, `tech_tree`) sont injectées dans `rules` et non
sérialisées — correct pour la sauvegarde, mais toute nouvelle façade doit les réinjecter.
Aucune dépendance circulaire détectée. Aucune duplication fonctionnelle majeure, sauf deux
inventaires de personnalités qui ne sont pas reliés à la simulation (§6).

## 4. Audit des sept phases

| Phase | État observé | Preuve |
|---|---|---|
| MIL-01 | Opérationnel, non modifié | tests dédiés + `bash tests/run.sh` 213/213 |
| Phase I (IA/renseignement) | Opérationnel ; brouillard respecté | tests `test_ai_view_is_not_omniscient`, `test_intelligence_phase1` |
| Phase II (22 États) | Opérationnel ; données les plus faibles : Albanie, Monténégro, Luxembourg, Empire ottoman (niveaux C/D documentés) | `military_forces_1914.json`, rapport d'audit historique |
| Phase III (diplomatie) | Opérationnelle ; **pacte universel uniquement via API/ordre**, pas d'action UI | `grep UNIVERSAL_PACT` : aucune référence dans `src/ui/` |
| Phase IV (transport) | Opérationnelle ; some capacités estimées | 367 liaisons, 84 ports, validateurs PASS |
| Phase V (économie) | Opérationnelle ; **catégories déclarées en double avec incohérence** | `game_rules.economy.resource_categories = []` vs `economy_rules.resources` (6) |
| Phase VI (tech/air/naval) | Opérationnelle ; personnalités non attribuées | `state.tech["personalities"]` vide |
| Phase VII (politique/victoire/MP) | Opérationnelle en local ; **réseau absent**, victoire diplomatique non exposée | `multiplayer_system.gd`, rapport Phase VII |

## 5. Cohérence entre les systèmes

Script d'audit externe (`/tmp/opencode/gs1914-audit.gd`), exécuté avec les graines 1914, 7, 2026 :

| Interaction | Attendu | Observé | Résultat |
|---|---|---|---|
| Mobilisation → main-d'œuvre | réduction | agriculture non augmentée | OK |
| Accord de transit → accès Belgique | ouverture | `accessible() = true` | OK |
| Recherche → ressources | consommation charbon | stock en baisse | OK |
| Message privé → tiers | invisible | tiers ne voit que 0 message | OK |
| Changement de régime → réputation | baisse | réputation dégradée | OK |
| Pont interrompu → difficulté | hausse | difficulté et facteur logistique dégradés | OK |
| Sauvegarde → rejeu | empreinte identique | identique avant et après un tour | OK |
| Stocks | jamais négatifs | 0 anomalie sur 5 campagnes × 3 graines | OK |

**Aucune incohérence fonctionnelle confirmée** dans ces interactions. Les écarts relevés sont des
problèmes d'exposition (UI) ou de paramétrage (personnalités), pas des cassages de calcul.

## 6. Audit de l'IA

Quatre jeux de personnalités sont définis : diplomatiques (7), économiques (4), technologiques (4),
politiques (4). Vérification sur une partie neuve :

| Jeu | État réel | Effet |
|---|---|---|
| Diplomatique | tous les États = `cautious` | aucune différenciation |
| Économique | tous = `stability` (valeur par défaut) | aucune différenciation |
| Technologique | dictionnaire vide | `Phase6AI.personality()` retourne `{}` → pondérations par défaut |
| Politique | champ absent | `PoliticalAI` retombe sur `pragmatic` |

**Problème MAJEUR confirmé** : 19 profils sont documentés mais les IA utilisent effectivement 4
valeurs par défaut identiques pour tous les États. Les décisions sont déterministes et bornées
(vérifié), mais « chaque personnalité conserve une logique cohérente » n'est pas démontré en
campagne : il n'existe qu'une seule logique active par domaine.

Campagnes longues : guerre déclarée se termine par un traité vers le tour 12 ; ensuite 0 attaque
sur 108 tours malgré ~20 ordres/tour. Ce n'est pas une inactivité technique (les ordres existent),
mais une **convergence rapide vers la paix** qui rend les systèmes militaires oisifs dans les
simulations longues non forcées.

## 7. Audit historique

- Cartographie 90 régions, 22 États, frontières 1914 : cohérente, validée par 224 contrôles.
- Forces MIL-01 et Phase II : sources et niveaux A–D conservés ; données les plus incertaines
  explicitement signalées (Albanie, Monténégro, Luxembourg, Ottoman).
- Économie : populations nationales niveau B, répartition régionale **estimation de modèle** (C).
- Ponts : 146 points générés depuis 59 rivières, **estimation de modèle** — aucun inventaire
  historique certifié de ponts n'est prétendu.
- Technologie 1914–1945 : jalons historiques identifiés ; effets et coûts = propositions de modèle.
- Aucune donnée historique modifiée pendant l'audit ; aucune anomalie bloquante confirmée.

## 8. Audit de l'équilibrage

- Victoire militaire à 90 % : atteinte dans le scénario dédié, sans confondre occupation et
  souveraineté (test confirmé).
- Victoire IDH : ratio observé 1,07 au départ contre seuil 1,25 ; **non atteinte** dans les
  campagnes de 120 tours. Non prouvée impossible, mais **non démontrée fonctionnelle en jeu réel**.
- Victoire diplomatique : `PeaceSystem.universal_pact()` est appelable immédiatement (retour `ok`)
  mais exige la liste des membres et un contrôle souverain de 90 % — déjà vrai au départ ; aucun
  mécanisme d'acceptation État par État n'est implémenté, et aucune commande UI n'existe.
- Ressources : aucune création gratuite détectée ; industrie et recherche consomment bien les
  stocks.
- Résumé : pas de stratégie dominante confirmée, mais deux voies de victoire (IDH, diplomatique)
  insuffisamment accessibles pour être évaluées en conditions réelles.

## 9. Campagnes longues et performances

| Durée | Temps | Mémoire | Événements | Formations | Batailles |
|---:|---:|---:|---:|---:|---:|
| 12 tours | 56,7 s | 149 Mo | 862 | 1 489 | 8 |
| 24 tours | 51,6 s | 152 Mo | 1 207 | 1 489 | 8 |
| 60 tours | 95,0 s | 158 Mo | 2 155 | 1 489 | 8 |
| 120 tours | 239,4 s | 168 Mo | 3 813 | 1 489 | 8 |

Croissance superlinéaire du temps par tour (~1 s à 60 tours, ~2 s à 120 tours), corrélée à la
croissance linéaire du journal d'événements (~30 événements/tour). À 120 tours, aucune erreur,
aucun État bloqué, aucune sauvegarde corrompue. Au-delà de 120 tours, le coût devient prohibitif
pour un usage interactif (une campagne 1914–1945 = ~380 tours).

Benchmarks (`bench_phase1.gd`) : `resolve` 450–560 ms selon la taille, `view_for` 40–52 ms / 5
appels, `descendants` 0 ms (cache efficace). La validation cartographique complète a mis plus de
300 s sous charge (elle passe avec un timeout de 900 s) — variabilité à documenter.

Taille de sauvegarde après 6 tours avec tous les systèmes : ~1,17 Mo.

## 10. Expérience utilisateur

13 onglets : Pays, Diplomatie, Économie, Industrie, Armée, Logistique, Recherche, Renseignement,
Politique, Victoire, Multijoueur, Événements, Ordres. Couches cartographiques : 17 activables.

Problèmes UX confirmés (lecture du code) :
- `src/ui/game_ui.gd:313` : l'économie affiche « catégories de ressources non définies — NON
  FONCTIONNEL » alors que Phase V définit 6 ressources dans `economy_rules.json`. Cause :
  `game_rules.economy.resource_categories` reste vide.
- `src/ui/game_ui.gd:760` : « Interception, décryptage, espionnage industriel : NON FONCTIONNEL »
  alors que Phase VI implémente l'interception et le décryptage.
- `src/ui/game_ui.gd:528` : mention du « repli neutre » pour les États hors MIL-01, alors que la
  Phase II a doté les 22 États d'effectifs.
- Aucun bouton pour proposer/signer le Traité de Paix et d'Unité Internationale.
- Aucune explication affichée pour les refus d'ordres complexes (raison stockée dans
  `orders_history.rejected` mais pas mise en avant).

Ces défauts donnent au joueur l'impression que des systèmes opérationnels n'existent pas.

## 11. État réel de la jouabilité

**Classement retenu : B — simulation stratégique fonctionnelle mais incomplète.**

Justification : la boucle de jeu (ordre → résolution → sauvegarde) fonctionne de façon
déterministe avec 12 systèmes actifs ; les interactions entre systèmes sont correctes ; mais
- une condition de victoire majeure n'est pas exposée à l'UI,
- les personnalités IA ne différencient pas les États,
- le multijoueur réseau n'existe pas,
- l'interface contient des informations fausses sur l'état de fonctionnalités.

Le classement C (« jeu complet techniquement jouable ») est écarté : l'absence de voie UI pour la
victoire diplomatique et les textes erronés empêchent une partie guidée uniquement par l'interface.
Le classement A est exclu : le projet va bien au-delà d'un prototype technique.

## 12. Problèmes classés par gravité

| Gravité | Problème | Système | Reproduction | Observé vs attendu | Recommandation |
|---|---|---|---|---|---|
| **MAJEUR** | Victoire diplomatique inaccessible via UI | Victoire / UI | chercher une action « Traité d'Unité » dans l'interface | absent ; seul l'ordre interne `UNIVERSAL_PACT` existe | exposer une action avec liste des signataires et suivre les acceptations |
| **MAJEUR** | Personnalités IA non différenciées | IA (4 domaines) | inspecter `state.personalities`, `economy.personalities`, `tech.personalities`, `politics.*.ai_personality` | valeurs uniques par défaut | attribuer des profils variés selon l'État au démarrage |
| **MAJEUR** | Multijoueur réseau absent | MP | lire `multiplayer_system.gd` et la page UI | socle local uniquement ; documenté comme tel | ne pas annoncer comme fonctionnel ; travaux réseau séparés |
| **MODÉRÉ** | Textes UI « NON FONCTIONNEL » sur des systèmes actifs | UI | ouvrir Économie, Renseignement, Armée | messages obsolètes | synchroniser les textes avec les règles réelles |
| **MODÉRÉ** | Catégories de ressources dupliquées/incohérentes | Économie / UI | comparer `game_rules` et `economy_rules` | `[]` vs 6 | source unique de vérité |
| **MODÉRÉ** | Temps/tour croissant (1→2 s) et journal ~30 év./tour | Perf | campagnes 60/120 tours | confirmé | archiver le journal dans la sauvegarde ou le borner |
| **MODÉRÉ** | Victoire IDH non démontrée en jeu | Victoire | campagnes 120 tours | ratio 1,07 < seuil 1,25 | documenter une trajectoire d'investissement vérifiée |
| **MINEUR** | Interface des simulateurs incohérente | Outils | `simulate_phase1.gd <n>` = tours, les autres = graine | confirmé (a causé un faux positif ici) | uniformiser l'aide/les arguments |
| **AMÉLIORATION** | Validation cartographique > 300 s sous charge | Outils | `validate_all.sh` sous charge | timeout à 300 s, passe à 900 s | documenter le timeout recommandé |

Aucun problème CRITIQUE confirmé : aucune corruption, aucun blocage de partie, aucun stock négatif,
aucune divergence de sauvegarde.

## 13. Fonctionnalités manquantes ou partielles

- Multijoueur réseau (transport, lobby, authentification, arbitrage réseau).
- Acceptation État par État pour le traité universel ; signatures/réserves non modélisées.
- Différenciation réelle des personnalités IA.
- Espionnage industriel distinct de l'interception (Phase VI).
- Production navale/aéronautique dédiée au-delà des catégories agrégées.
- Personnalités éditables depuis l'interface.

## 14. Priorités de correction (feuille de route proposée)

**1. Indispensable avant toute campagne complète**
- Exposer la victoire diplomatique dans l'UI avec suivi des acceptations. Critère : une partie puisse
  se terminer par ce chemin sans toucher au code.

**2. Nécessaire avant une première version jouable**
- Attribuer des personnalités variées aux 22 États. Critère : deux États aient des profils
  différents et des décisions observables différentes.
- Corriger les textes UI erronés et unifier les catégories de ressources. Critère : aucune mention
  « NON FONCTIONNEL » sur un système opérationnel.

**3. Équilibrage et UX**
- Borner/archiver le journal d'événements pour les campagnes >120 tours.
- Documenter et valider une trajectoire IDH atteignable.
- Afficher les motifs de refus d'ordres.

**4. Facultatif**
- Réseau multijoueur réel, espionnage industriel dédié, éditeur de personnalités.

Aucune Phase VIII n'est proposée automatiquement : ces éléments sont des corrections de la
feuille de route existante.

## 15. Verdict final

Le projet est **cohérent, stable et techniquement solide**, avec une couverture de tests et de
simulations rare pour un prototype de cette ampleur. Les systèmes ne se cassent pas lorsqu'ils
interagissent. En revanche, **trois écarts d’exposition et de paramétrage** (victoire diplomatique,
personnalités IA, textes UI) empêchent de le présenter comme un jeu complet jouable. Le
multijoueur doit rester explicitement qualifié de **socle local**, pas de mode en ligne.

La priorité doit être de rendre pleinement accessibles les systèmes déjà implémentés plutôt que
d'en ajouter de nouveaux.

## 16. Limites de l'audit

- Aucune campagne réellement jouée à la souris : les preuves viennent de tests, simulateurs et
  lectures de code ; l'évaluation UX est donc partiellement statique.
- Aucune mesure réseau (aucune infrastructure réseau n'existe à mesurer).
- Le script d'audit temporaire a été créé hors dépôt conformément aux règles ; ses résultats sont
  reproductibles avec `godot --headless --path <projet> --script /tmp/opencode/gs1914-audit.gd <graine>`.
- Aucune correction n'a été appliquée, conformément à la mission.

## 17. Preuves associées

- `bash tests/run.sh` → 213 tests réussis, 0 échec, UI validée.
- Simulateurs de phase (3 graines chacun) → 10 + 11 + 12 + 15 + 18 scénarios, 0 échec.
- Campagnes longues 12/24/60/120 tours → 0 erreur, mémoires et temps consignés §9.
- Audit multi-scénarios externe → `AUDIT ISSUES=0` sur 3 graines.
- Exports et validateurs → tous PASS ; cartographie 224 contrôles VALIDÉS.
- `git status` → seul ce rapport ajouté ; branche et distant identiques après publication.
