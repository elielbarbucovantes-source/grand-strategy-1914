# POST_MIL01_PHASE3_REPORT — Phase III : diplomatie active et relations internationales

> **Date :** 2026-11-18
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État initial :** `99db68a` (audit post-Phase II), dépôt propre et synchronisé.
> **Périmètre :** sous-étapes A à I de la mission. Phase IV non commencée.

---

## 1. État initial et protection du projet

Contrôles effectués avant modification : branche `dev/mil01-finalisation`, arbre propre,
`HEAD` local = distant = `99db68a`, `ahead/behind = 0/0`. Les rapports Phase 0, Phase II et
d'audit ont été lus ; le système diplomatique existant (`diplomacy_system.gd`, traités enregistrés
sans effet sauf passage) a été examiné avant toute extension. Aucune branche fusionnée ou
supprimée, aucun historique réécrit, aucun push forcé.

## 2. Systèmes développés

| Sous-étape | Système | Fichier |
|---|---|---|
| A | Relations bilatérales à 7 dimensions, historique, réputation | `src/domains/diplomacy/relations_system.gd` |
| B | Propositions avec émetteur, destinataires multiples, contenu, date, validité, statut, conditions, contre-propositions, retrait, expiration ; canaux public/privé/groupe | `negotiation_system.gd` |
| C | Alliances et coalitions : membres, engagements (défensif/offensif/passage), adhésion, sortie, dissolution, expiration, obligations conditionnées | `alliance_system.gd` |
| D | Crises : motif, enjeu, tension, escalade, réponses (protestation, négociation, concession, garantie, sanctions, mobilisation), médiation, règlement ou guerre | `crisis_system.gd` |
| E | Traités de paix : paix blanche, conditions négociables, fin réelle des hostilités, cohérence des ordres et territoires, pacte universel distinct | `peace_system.gd` |
| F | Prisonniers de guerre : intégration au `ForceLedger` MIL-01, échange, rapatriement, journalisation, sans double comptage | `pow_system.gd` |
| H | Conférences internationales : participants, sujets multiples, production d'accords réels | `conference_system.gd` |
| G | IA diplomatique : personnalités, mémoire des trahisons, initiatives et réponses bornées, déterminisme | `src/ai/diplomatic_ai.gd` |
| — | Point d'entrée unique, migration, règles, vue IA, ordres et interface | `diplomacy_system.gd`, `save_repository.gd`, `diplomacy_rules.json`, `intel_system.gd`, `orders.gd`, `game_ui.gd` |

## 3. Règles implémentées

`data/rules/diplomacy_rules.json` (format_version 1, valeurs PROPOSÉES) : valeurs initiales et
dérive mensuelle des relations, bonus/malus de réputation, durée de validité des propositions,
limites (3 propositions/État/tour, 2 contre-propositions, **2 alliances/État**), engagements par
type d'accord, seuils d'escalade et de règlement des crises, conditions de paix, ratio d'échange
des prisonniers, 7 personnalités diplomatiques et plafonds d'initiatives IA.

Décision technique documentée : la limite de 2 alliances par État a été ajoutée après une
simulation ayant produit 47 alliances en 6 tours (comportement absurde). Ce n'est pas une règle
de conception validée par le directeur, mais un paramètre PROPOSÉ de équilibrage.

## 4. Fichiers modifiés et changements d'architecture

- État sérialisable **v5** (`GameState`) : `relations`, `reputation`, `personalities`, `diplomacy`
  (alliances, crises, conférences, traités de paix, prisonniers, négociations, historique).
- Migration **v4 → v5** (`SaveRepository._load_v4`) : empreinte calculée sur l'état d'origine,
  champs absents initialisés à vide, traités/messages/mémoire conservés. Les formats 1, 2 et 3
  restent refusés ou migrés selon les règles antérieures.
- Résolution de tour : la diplomatie est résolue avant les mouvements, puis un appel mensuel
  gère expiration, relations, crises et alliances.
- `IntelSystem.view_for` expose une **vue diplomatique filtrée** (relations propres, réputation
  publique, engagements, crises concernant l'État) sans révéler de volumes militaires étrangers.
- `NationAgent` délègue à `DiplomaticAI` et évite les doubles réponses avec la couche niveau 1.
- Interface : onglet Diplomatie étendu sans nouveau onglet (10 onglets conservés).
- Aucun système militaire MIL-01, de mobilisation Phase II ou de combat n'a été modifié.

## 5. Fonctionnement des IA — démonstré, pas supposé

Les IA ne se contentent pas de posséder une fonction de négociation : les simulations montrent
qu'elles **prennent l'initiative** (propositions d'alliance), **répondent**, **contrent**,
**refusent** un partenaire hostile malgré un avantage apparent (score −59), **se souviennent**
des trahisons (score dégradé), **médient** les crises, **quitent une alliance** devenue toxique
et **échangent des prisonniers**. Leur personnalité (prudente, expansionniste, conciliante,
opportuniste, méfiante, ambitieuse, attachée à l'honneur) modifie les seuils de confiance et
la probabilité de guerre. Les décisions sont déterministes ; la désescalade et la confiance
empêchent les boucles infinies (0 à 13 propositions en attente selon la graine).

## 6. Tests réellement exécutés

| Commande | Résultat |
|---|---|
| `bash tests/run.sh` | **167 tests réussis, 0 échec** ; `RÉSULTAT UI : VALIDÉ` ; `RÉSULTAT UI BATAILLE : VALIDÉ` ; exit 0 |
| `python3 tools/export/build_game_data.py --check` | PASS |
| `python3 tools/export/build_scenario.py --check` | PASS |
| `python3 tools/history/render_fiches.py --check` | PASS |
| `bash tools/map/validate_all.sh` | VALIDÉ (94 + 96 + 34 contrôles, 0 échec) |

Les 15 nouveaux tests couvrent : dimensions relationnelles et évolution, trahison/réputation,
proposition-acceptation-refus, contre-proposition/retrait/expiration, messages privés vs publics,
cycle de vie des alliances et obligations, escalade/médiation/règlement/guerre des crises,
paix blanche sans téléportation, refus de paix, pacte universel, prisonniers sans double
comptage, initiatives et personnalités IA, mémoire/déterminisme IA, persistance complète,
migration v4, et conférences produisant de vrais accords.

## 7. Simulations réalisées

`tools/simulate_phase3.gd` exécute les **10 situations imposées** (alliance multilatérale,
rupture, crise pacifique, crise → guerre, paix négociée avec refus puis acceptation, échange de
prisonniers, diplomatie multi-IA, trahison d'IA, refus rationnel, stabilité sur 24 tours).
Exécuté avec les graines **1914, 7 et 2026** : **10/10 situations réussies à chaque graine**,
0 échec. Durée : ~8,4 s pour l'ensemble des 10 situations.

Observations notables : la médiation fait retomber la tension de 35 à 10 ; une crise sans
réponse atteint 85 et déclenche une guerre ; la paix blanche met fin aux hostilités sans
déplacer la moindre formation ; les relations restent bornées [0,100] après 24 tours.

## 8. Résultats observés

- Les engagements ont des conséquences : une coalition crée une obligation défensive ; une
  rupture abaisse la confiance de 50 à ~15 et alimente la mémoire de la victime.
- Une alliance n'entraîne **pas** automatiquement une entrée en guerre : l'obligation dépend du
  type d'accord et d'un seuil de confiance.
- La paix blanche ne modifie ni les formations ni les territoires ; elle rapatrie les prisonniers
  et purge les ordres devenus invalides.
- Le pacte universel est un objet distinct, conditionné au contrôle de 90 % des régions, et ne
  doit pas être confondu avec un traité bilatéral.

## 9. Problèmes identifiés et corrections apportées

1. **Division par zéro / références de classe** : corrections de compilation lors de
   l'intégration (méthode `get()` renommée `between()`, `or {}` supprimé).
2. **Déterminisme après sauvegarde** : deux divergences détectées par les tests existants —
   sélection IA dépendante de l'ordre d'itération d'un dictionnaire et accumulation flottante
   de la réputation. Corrigées par tri explicite des candidats et arrondi à 4 décimales.
3. **Passage allié** : les accords de transit créés via la Phase III ne mettaient pas à jour
   `GameState.has_transit`. Corrigé (consultation des alliances avec engagement de passage).
4. **47 alliances en 6 tours** : limite de 2 alliances par État ajoutée aux règles.
5. **Traçabilité** : les alliances sont aussi enregistrées dans `state.treaties` pour que
   `break_treaty` et les outils existants restent compatibles.

## 10. Limitations restantes

- Aucun mécanisme de **changement de gouvernement** ne modifie encore les relations (facteur
  listé dans la mission mais non implémenté). Les événements internationaux sont couverts via
  crises et traités, pas via un calendrier d'événements scripté.
- Les **compensations économiques** de paix ne sont pas implémentées : le système économique
  (ECO-01/07) reste ouvert ; seul le terme `reparations` est enregistré sans effet.
- L'IA ne **propose pas encore de conférence** de façon autonome : elle propose des médiations ;
  la conférence reste disponible pour le joueur et via ordres.
- Les personnalités sont stockées dans l'état mais ne sont pas encore éditables depuis l'interface
  (aucun écran de gouvernement dédié).
- Les transferts territoriaux de paix sont bornés à 3 régions et exigent que la région soit
  contrôlée par le vainqueur ; aucune annexe automatique.
- L'historique diplomatique est conservé dans la sauvegarde, mais les échanges privés ne sont
  interceptables que par les mécanismes de renseignement existants (aucun espionnage diplomatique
  dédié).

## 11. Performances

Banc versionné `tools/bench_phase1.gd -- guerre 900 5` : `descendants` 0,0 ms, `view_for`
13,8 ms / 5, `resolve` 22,0 ms. Aucune régression mesurée par rapport aux repères Phase I/II
(les valeurs étaient 37,7 ms et 50,1 ms lors de l'audit précédent, la différence tenant au
contexte de mesure). Simulation complète 10 situations : 8,4 s.

## 12. Commits créés

- `259ed485e28158e668acd3e0b79019ed5ac1c9d5` — `feat(diplomatie): relations, negociations, alliances, crises, paix et conferences`
- `0b6d675bb1fdeab50c269097887091a4f3b6b266` — `feat(diplomatie): IA autonome, migration v5 et suite Phase III`
- rapport final — `docs(phase3): consigner la validation et les simulations`

## 13. État final du dépôt

Branche `dev/mil01-finalisation`. Publication sur `origin/dev/mil01-finalisation` uniquement.
Aucun merge vers `main`, aucune suppression de branche, aucun push forcé, aucun secret versionné.
Arbre de travail propre, `HEAD` local = `HEAD` distant à l'issue de la publication.

| Niveau | État |
|---|---|
| Conçu | OUI — architecture en 7 sous-systèmes + règles dédiées |
| Documenté | OUI — ce rapport, règles commentées, limitations explicites |
| Implémenté | OUI — systèmes, ordres, état v5, migration, interface, IA |
| Testé | OUI — 167 tests + 4 contrôles d'export + validation cartographique |
| Fonctionnel | OUI — démontré par 10 simulations × 3 graines, pas seulement par l'existence de fonctions |

**La Phase IV n'a pas été commencée.**
