# Tours mensuels et déplacements simultanés

**Statut :**
- tour mensuel, ordres secrets et résolution simultanée : **VALIDÉS** (D-006, TURN-02) ;
- **T-045 VALIDÉ** (directeur, 15/11/2026) ;
- ordre interne des phases : PROPOSÉ (TURN-01 ouvert).

**Code :**
- `src/simulation/turn_resolver.gd` ;
- `src/domains/military/military_system.gd` (`resolve_moves`, `neutral_pick`).

**Tests :** `tests/unit/test_moves_t045.gd`.

## 1. Phases d'un mois (PROPOSÉ)

1. Validation de tous les ordres. Les ordres invalides sont rejetés avec leur motif.
2. Diplomatie : déclarations, traités. Une déclaration du même mois peut autoriser une entrée.
3. Industrie, ouvrages défensifs, décret de mobilisation.
4. **Déplacements simultanés**, revalidés après la diplomatie.
5. Batailles :
   - création des batailles tactiques (et sièges d'armées encerclées) ;
   - repli neutre si les effectifs d'un camp sont inconnus ;
   - les batailles sans joueur humain sont résolues immédiatement ;
   - celles d'un humain doivent être jouées avant le mois suivant (T-029 A).
6. Travaux défensifs, encerclement, moral.
7. Mobilisation : incorporation des rappelés arrivés, puis nouvel appel.
8. Logistique (liaison avec la capitale), puis calendrier.

## 2. T-045 — Armées qui se croisent

**Décision.** Deux armées ennemies qui échangent leurs positions pendant le même tour (A → B et B → A) se croisent **sans bataille**. Une bataille ne se déclenche que si les conditions normales d'affrontement sont réunies : des armées ennemies dans une même région.

**Mise en œuvre :**
- Tous les mouvements valides sont appliqués **en même temps**. Les contacts sont évalués **uniquement sur les positions finales**.
- Aucune bataille n'est créée « en chemin » ni sur une frontière.
- La règle territoriale normale s'applique ensuite. Une région ennemie qu'aucune armée adverse n'occupe à la fin des mouvements passe sous le contrôle de l'entrant (occupation ≠ souveraineté).
  - Lors d'un échange, chaque armée occupe donc la région que l'autre a quittée.
- Une armée ennemie qui reste dans la région d'arrivée (ou qui y entre aussi) provoque une bataille normale.

## 3. Absence d'avantage lié à l'ordre de traitement (TURN-03)

Deux situations symétriques dépendaient auparavant de l'ordre technique (ordre des pays, identifiants). Elles sont désormais neutres.

| Situation | Règle |
|---|---|
| Rencontre dans une région tenue par un tiers | Le camp **déjà présent** défend. Si tous viennent d'entrer, le défenseur est tiré par `neutral_pick`. |
| Plusieurs co-belligérants entrent dans la même région ennemie vide | Le contrôle revient à celui qui y amène **le plus de soldats**. Égalité ou effectifs inconnus : `neutral_pick`. |

`neutral_pick` est un tirage **reproductible** : SHA-256 de « graine | tour | contexte ».
- Il ne dépend ni de l'ordre des pays, ni de celui des ordres, ni des identifiants.
- Les tests inversent l'ordre des pays et des ordres et vérifient un résultat identique.
- Ils vérifient aussi que, selon la graine, chaque pays peut obtenir l'issue favorable.

Le départage final du commandant (T-029 G, identifiant croissant) est une décision distincte. Elle n'est pas modifiée.

## 4. Configurations testées

| Configuration | Résultat attendu | Test |
|---|---|---|
| Échange simple A ↔ B | Aucune bataille, positions échangées, aucune perte, occupations normales | `test_swap_positions_without_battle` |
| Échange, mais un ennemi reste dans la région d'arrivée | Une bataille, dans cette région seulement | `test_swap_with_stationary_enemy_triggers_normal_battle` |
| Plusieurs armées en chaîne (035 → 032 → 033) et une entrée adverse | Aucun contact final, aucune bataille | `test_multiple_enemy_armies_moving` |
| Convergence de deux ennemis dans la même région | Bataille, défenseur indépendant de l'ordre | `test_convergence_and_no_order_bias` |
| Occupation conjointe par deux alliés | Plus grand contingent, sinon tirage neutre | `test_joint_occupation_is_order_independent` |

## 5. Limites

- La portée de déplacement est d'une région par mois (PROPOSÉ, MIL-03 ouvert). Un déplacement ne traverse donc aucune région intermédiaire : la question de l'interception en route ne se pose pas encore. Elle devra être tranchée si la portée augmente.
- Il n'existe pas d'interception navale (réseau maritime incomplet, U3).
