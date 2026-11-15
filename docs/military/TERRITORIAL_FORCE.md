# Territorial Force britannique (T-050, T-054) — MIL-01, phase 4

- **Code :** `src/domains/military/territorial_force.gd`. Branchements :
  - `MobilizationSystem` : étape mensuelle, résumé, conservation ;
  - `MilitarySystem.validate_move` : service intérieur ;
  - `TurnResolver`, `GameSession` : ordre de volontariat ;
  - `IntelSystem` (indicateur propre au gouvernement) et `NationAgent` (l'IA n'envoie pas la Territorial Force à l'étranger) ;
  - `game_ui.gd` (onglet Armée).
- **Données :** `data/history/military_forces_1914.json` (`united_kingdom.territorial_force`) ; paramètres : `data/rules/forces_rules.json` (`territorial_force`).
- **Tests :** `tests/unit/test_territorial_force.gd` (7 fonctions).
- **Décisions :** T-050 (catégorie distincte), T-054 (service intérieur, outre-mer par volontariat).

## 1. Données

| Élément | Valeur | Statut | Source |
|---|---|---|---|
| Effectif au 1er août 1914 | **268 777** (10 684 officiers, 258 093 hommes), personnel permanent compris | Sourcé | WO 1922, p. 30, vérifié sur le fac-similé |
| Effectif théorique | 316 094 | Sourcé (information) | idem |
| Territorial Force Reserve | 2 082 | **Exclue** (ligne distincte) | idem |
| Répartition | 14 divisions à parts égales. Région 001 : 6 divisions (115 190 hommes) ; 002 : 5 (95 992) ; 003 : 2 (38 397) ; 004 : 1 (19 198). Aucune en Irlande. | **ESTIMATION** | Commandements de rattachement des divisions, WO 1922 p. 25-26, situation d'**avril 1920** |
| Ventilation par arme | Proportions de l'armée régulière | **ESTIMATION** | US WD 1916 p. 9 (armée régulière) |
| Repère de déploiement | 69 218 à l'étranger au début de décembre 1914 (France, Égypte, Inde, Gibraltar, Malte) | Sourcé (repère seulement) | WO 1922 p. 153, Section 8, fac-similé |

## 2. Règles de jeu

1. **Catégorie distincte.** L'effectif est dans `forces.territorial_force`, hors de l'armée active et hors du réservoir (échelons). Les compteurs sont séparés (`territorial_force.incorporated` ≠ `incorporated`). Les unités et armées sont propres (`category = "territorial_force"`).
2. **Incorporation** (« embodiment »).
   - Elle a lieu quand le Royaume-Uni adopte la **posture générale**, jamais en posture préparatoire.
   - L'appel est **intégral**. Les hommes sont incorporés après un transit de **1 mois (PROVISOIRE)**.
   - Les règles communes s'appliquent : voies de communication (T-056 bis), report en cas de bataille (Q8), cohortes bloquées.
   - L'incorporation est **publique** ; les volumes sont confidentiels.
3. **Service intérieur.** Une armée territoriale en service intérieur ne peut pas entrer dans une région de souveraineté étrangère, même avec une autorisation de passage ou en guerre.
4. **Service outre-mer (T-054).** L'ordre « Volontaires pour le service outre-mer » porte sur une armée territoriale en service intérieur.
   - Il est possible **3 mois (PROVISOIRE)** après l'incorporation. Ce délai est compatible avec le repère de décembre 1914, sans en être tiré.
   - Les volontaires (part **PROVISOIRE de 1,0** : l'armée part entière) forment une armée « volontaires outre-mer », libre de ses déplacements.
   - Avec une part inférieure, les unités sont scindées ; les non-volontaires restent en service intérieur.
5. **Combat.** Les unités territoriales combattent avec les paramètres communs : aucune donnée de qualité ou d'instruction n'est sourcée. Leurs pertes et prisonniers entrent dans la comptabilité nationale britannique.

## 3. Conservation et double comptage (testés)

- **Invariant propre :** non incorporés + en cours + bloqués + incorporés = 268 777.
- **Invariant de personnel britannique :** présents (unités et services) + pertes + prisonniers = actifs sur la carte + réservistes incorporés + **Territorial Force incorporée**.
- **Après mobilisation complète :** 604 366 présents = 126 309 + 209 280 + 268 777, exactement.
- **Le réservoir** (209 280 = Army Reserve + Special Reserve) ne contient pas la Territorial Force.
- **Le volontariat** déplace des hommes entre unités sans en créer ni en perdre.
- **Personnel permanent :** inclus dans les 268 777 selon la source. Son éventuelle présence aussi dans la ligne « Regular Army » n'est pas tranchée par la page ; le total additif du tableau indique que non (**probable**).

## 4. Ce qui est provisoire ou absent

- Délais (transit, délai avant l'outre-mer) et part de volontaires : **PROVISOIRES**, aucune source consultée.
- Répartition par division et ventilation par arme : **ESTIMATIONS**. La source de la répartition date de 1920.
- **Non modélisé :**
  - instruction ou qualité inférieure à celle de l'armée régulière ;
  - unités de seconde ligne ;
  - recrutement après août 1914 ;
  - remplacement de garnisons outre-mer (Inde, Égypte, Méditerranée), car ces régions ne sont pas sur la carte.
- **L'IA** incorpore la Territorial Force avec la posture générale, mais ne propose jamais de volontariat outre-mer.
- **Repli après une bataille :** une armée territoriale vaincue pourrait se replier vers une région alliée étrangère par la règle commune de retraite (T-043). Le cas est théorique : la Territorial Force reste en Grande-Bretagne, que seul le détroit de Douvres relie au continent. Il n'est pas traité.
