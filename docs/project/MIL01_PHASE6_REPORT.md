# MIL-01 — Phase 6 : conception du système de pertes militaires (PROPOSITIONS)

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

**Statut : CONCEPTION.**
- **Aucune** modification du code de combat, des règles de bataille ni des paramètres.
- Les valeurs marquées **[JEU]** sont des **paramètres de jeu proposés**, non des données historiques.
- Les valeurs marquées **[HIST]** viennent des sources consultées en phase 5 (`MIL01_PHASE5_PERTES_HISTORIQUES.md`).
- Les valeurs marquées **[CALC]** sont calculées par moi à partir de valeurs [HIST].

**Décisions du directeur appliquées à cette conception :**
- retour des blessés : 1 sur 1,8 (britannique, documenté), appliqué provisoirement aux autres puissances et modifiable par pays ;
- disparus : catégorie distincte ;
- cas historiques : Somme, Isonzo, Caporetto, retraite russe de 1915 et offensive Kerenski, comme **points de comparaison**, pas comme modèles.

---

## 1. Analyse du système actuel

### 1.1 Calcul des pertes (`src/domains/combat/tactical_sim.gd`)

| Élément | Fonctionnement actuel | Effet |
|---|---|---|
| Feu | `létalité × soldats du tireur × feu de formation × efficacité × bonus × atténuation × dt × exposition de la cible` (`_fire_and_melee`, `exposure`) | Pertes proportionnelles à **tout** l'effectif, sans largeur de front : dynamique de Lanchester « carrée » (audit G.3) |
| Mêlée et charge | `charge_melee_lethality`, choc moral | Pertes supplémentaires au contact |
| Déroute (T-039) | Seuil de moral 20 ; l'unité recule vers son point de repli, vulnérabilité × 1,8 | Pertes accrues, **aucune capture** |
| Anéantissement | Sous 50 hommes (`min_unit_soldiers`), le reliquat passe à 0 (`_apply_losses`) | Reliquat compté en pertes, sans distinction |
| Fatigue d'engagement | −0,0004 d'efficacité par pas engagé, plancher 0,7 | Seule non-linéarité dans le temps |
| Durée (T-036) | 10 min + 4 min par 10 000 hommes, bornée à [8, 30] | Saturée à 30 min dès environ 50 000 hommes |
| Fin de bataille | Durée maximale ou camp brisé (`_side_broken`) | Aucune règle de désengagement selon le type de combat |
| Types d'engagement (T-048, T-055) | **Inexistants** | Tous les combats sont des batailles totales |

**Mesures existantes** (audit MIL-01, échantillon de 36 batailles frontalières) :
- pertes médianes : attaquant 40,5 %, défenseur 33 % ;
- à effectifs égaux : 58 % contre 27,5 % ;
- 30 batailles sur 36 atteignent 30 minutes.
- Le banc d'essai d'équilibrage a une variante inopérante : l'IA réimpose sa formation.

### 1.2 Enregistrement (`force_ledger.gd`, `battle_manager.gd`, phases 2 à 4)

| Élément | Existant | Réutilisable |
|---|---|---|
| Pertes de combat | Une seule catégorie « non ventilée » (tués, blessés, disparus confondus) : différence d'effectif avant et après la bataille | Oui : point d'entrée unique, à ventiler |
| Prisonniers | Seulement à la **capitulation** d'une armée encerclée ; comptés chez l'origine et chez le détenteur | Oui |
| Survivants d'une armée anéantie | Rejoignent le territoire (retraite sûre) ou pertes (MIL01-P2-D2) | Oui |
| Attrition d'encerclement | Cause propre | Oui |
| Blessés, disparus, retours | `null`, non modélisés | À créer |
| Libération et rapatriement | Compteurs à 0, aucun mécanisme | À créer plus tard (diplomatie) |
| Conservation | Deux invariants testés (réserves ; personnel) | Oui, à étendre |
| Sauvegardes | Format 3 | Passage au format 4 nécessaire |
| Interfaces | Onglet Armée, lignes 6 et 7 ; écran de bataille : pertes totales par camp | À compléter |

### 1.3 Ce qui doit évoluer

1. **Ventilation des pertes** en tués, blessés, disparus et prisonniers, à la clôture de chaque bataille.
2. **Captures en bataille**, en cas d'effondrement : unités en déroute ou anéanties, champ de bataille perdu.
3. **Blessés en convalescence** avec retour, et inaptes définitifs.
4. **Types d'engagement** combinant l'approche de l'attaquant et la posture du défenseur (T-055).
5. **Intensité non linéaire** : largeur de front, désengagement, fatigue.
6. **Banc d'essai** : variantes réellement prises en compte, assertions de bornes.

---

## 2. Ce que les sources documentent (rappel, phase 5)

| Relation | Valeurs | Source | Confiance |
|---|---|---|---|
| Part des tués dans « tués + blessés » | Somme 1916 : [CALC] 24 %. Isonzo 1915-1917 : [CALC] 27,7 %. Allemagne (listes, fin oct. 1917) : [CALC] 26,7 %. Royaume-Uni en France : [CALC] 24,3 %. Russie : [CALC] 19,5 % (décès en hôpital exclus, sous-estimation selon la source). | WO 1922 p. 324 et 248 ; Mortara p. 36 ; WO p. 354 ; ЦСУ p. 30 | **Bonne** : convergence de quatre sources, de 24 à 28 %, la Russie à part |
| Attaquant en offensive de position (sans effondrement) | Somme : morts 21,8 %, blessés 68,9 %, disparus et prisonniers 9,2 % [CALC]. Vittorio Veneto : 21 / 70 / 9 [CALC]. Isonzo : prisonniers ≈ 10 à 15 % des morts et blessés [CALC]. | WO p. 324 ; Mortara p. 36 | Moyenne : deux armées, une seule échelle (campagne) |
| Défenseur en effondrement | Caporetto : prisonniers [CALC] 72 % des pertes. Russie, août 1915 : prisonniers et disparus [CALC] 69 %. | Mortara p. 36 ; ЦСУ p. 30 | Moyenne (deux cas extrêmes) |
| Défense suivie d'une contre-offensive | Trentin 1916 : morts [CALC] 23 %, blessés 48 %, prisonniers 29 % | Mortara p. 36 | Faible (un cas) |
| Offensive d'une armée désorganisée | Kerenski 1917 : déserteurs [CALC] 6,6 % ; disparus 9,7 % | ЦСУ p. 32 | Faible (un cas, catégorie propre) |
| Rapport attaquant / défenseur sur un front de position | ≈ 3:2 (2 441 673 contre 1 680 396) | WO 1922, section 7, p. 358 | Moyenne : trois ans de guerre de position, un seul front, rôle d'attaquant interprété |
| Retour des blessés | 1 blessé sur 1,8 retourne dans les rangs : [CALC] 55,6 % ; 16,68 % des malades **et** blessés renvoyés au pays restent inaptes | WO p. 246 | Bonne pour le Royaume-Uni ; **inconnue** pour les autres |
| Gravité des blessures (Allemagne) | Grièvement 20,9 % ; blessés 10,5 % ; légèrement 58,5 % ; restés dans leur unité 10,1 % [CALC] | WO p. 354 | Moyenne (listes jusqu'à octobre 1917) |
| Disparus | Disparus non retrouvés comme prisonniers : 1 pour 1,9 tué (autres grades britanniques) | WO p. 246 | Moyenne (Royaume-Uni seulement) |

**Non documenté :**
- pertes par engagement en pourcentage de l'effectif engagé ;
- pertes par heure ou par jour ;
- effet du terrain, de la formation ou de la fortification sur la **composition** des pertes ;
- délais de convalescence.

---

## 3. Propositions de calcul des pertes

### 3.1 Principe

Le **volume** des pertes reste produit par la simulation tactique (feu, mêlée, déroute), avec les mécanismes d'intensité du §4. La **composition** est déterminée à la clôture de la bataille, unité par unité, selon l'**origine** des pertes et l'**issue** :

1. **Pertes au feu et en mêlée** d'une unité qui n'est ni en déroute ni anéantie : tués, blessés et une petite part de disparus.
2. **Pertes subies en déroute** et **reliquat d'une unité anéantie** : disparus, ou prisonniers si une capture est établie (§3.3).
3. **Armée encerclée qui capitule** : prisonniers (inchangé).
4. **Armée anéantie** : survivants qui rejoignent le territoire, ou pertes de sort inconnu (inchangé, MIL01-P2-D2).

Pour cela, la simulation tactique doit enregistrer, par unité, les pertes subies en déroute et les pertes subies hors déroute. C'est un ajout de comptage, sans changement des pertes elles-mêmes.

### 3.2 Composition des pertes au feu [JEU, ancré sur HIST]

| Paramètre | Proposition | Base |
|---|---|---|
| `killed_share` : part des tués (morts de blessures sur place compris) dans les pertes au feu | **0,25** | [HIST] de 24 à 28 % selon quatre sources (§2) |
| `missing_share_fire` : part de disparus dans les pertes au feu | **0,05** | [JEU] ; ordre de grandeur compatible avec la Somme (disparus et prisonniers 9,2 %, prisonniers compris) |
| Blessés | le reste : 0,70 | [CALC] |
| Variation nationale | Paramètre modifiable par pays ; même valeur pour tous au départ | Les écarts nationaux observés (Russie 19,5 %) viennent de **méthodes de comptage** ; ce ne sont pas des différences démontrées |

### 3.3 Disparus et prisonniers en déroute [JEU]

Pour les pertes en déroute et le reliquat d'une unité anéantie, selon l'issue :

| Situation à la fin de la bataille | Prisonniers | Disparus | Base |
|---|---|---|---|
| Le camp de l'unité tient ou gagne le champ de bataille | 0 | 100 % | [JEU] : sans contrôle ennemi du terrain, aucune capture établie |
| Le camp perd ; l'unité dispose d'une retraite sûre | 30 % | 70 % | [JEU] |
| Le camp perd sans retraite sûre (effondrement) | 80 % | 20 % | [JEU] ; ordre de grandeur comparé à Caporetto et à août 1915 (prisonniers dominants) |

- Les prisonniers sont inscrits chez l'origine et chez le **détenteur** : le commandant du camp vainqueur, ou la puissance contrôlant la région.
- Les disparus restent une **catégorie distincte**, sans conversion automatique (décision du directeur). Une éventuelle résolution ultérieure est une question ouverte (§9).

### 3.4 Effet des circonstances sur la composition [JEU]

| Circonstance | Effet proposé | Justification |
|---|---|---|
| Effondrement (déroute générale d'un camp) | Davantage de pertes en déroute, donc de prisonniers et de disparus | [HIST] Caporetto, août 1915 |
| Fortification du défenseur | Réduit le **volume** (existant : couvert, tranchées) ; **aucun effet sur la composition** | Aucune source consultée |
| Terrain, formation | Agissent sur le volume (existant) ; aucun effet sur la composition | idem |
| Moral bas | Augmente le risque de déroute, donc indirectement la part de prisonniers | Mécanisme existant (T-038, T-039) |

---

## 4. Types d'engagement (T-048, T-055)

### 4.1 Choix des deux camps (T-055)

**Attaquant** (ordre de déplacement offensif) :
- **reconnaissance en force** : contact limité, repli rapide ;
- **attaque limitée** : objectifs restreints ;
- **assaut** : prise de la région.

**Défenseur** (posture de la région ou de l'armée) :
- **retardement** : céder le terrain pour préserver les troupes ;
- **tenir** ;
- **tenir à tout prix** : aucun désengagement.

| Attaquant \ Défenseur | Retardement | Tenir | Tenir à tout prix |
|---|---|---|---|
| Reconnaissance en force | Escarmouche | Escarmouche | Escarmouche |
| Attaque limitée | Escarmouche | Engagement limité | Engagement limité |
| Assaut | Engagement limité (le défenseur se retire) | Assaut frontal | Assaut frontal ; **grande bataille** si l'effectif total engagé dépasse un seuil [JEU, 200 000 hommes] |

**Circonstances combinées :**
- l'effectif total, au-delà d'un seuil, élève l'assaut frontal en grande bataille ;
- un défenseur encerclé ne peut pas retarder ;
- une IA qui ne choisit pas reçoit les valeurs par défaut « assaut » et « tenir ».

### 4.2 Paramètres par type [JEU, tous à valider]

| Paramètre | Escarmouche | Engagement limité | Assaut frontal | Grande bataille |
|---|---|---|---|---|
| Durée maximale | 10 min | 20 min | 30 min | 30 min |
| Part de l'effectif au contact (largeur de front) | 15 % | 40 % | 70 % | 100 % |
| Seuil de désengagement de l'attaquant (pertes cumulées) | 3 % | 10 % | 25 % | 40 % |
| Seuil de désengagement du défenseur | 2 % (retardement) | 8 % | 20 % ; aucun si « à tout prix » | aucun si « à tout prix », sinon 35 % |
| Multiplicateur d'intensité du feu | 0,5 | 0,8 | 1,0 | 1,0 |

**Non-linéarité dans le temps** (pas de croissance proportionnelle à la durée) :
1. **Largeur de front** : seule une part de chaque unité tire et s'expose. Elle s'ajoute à la part de l'effectif au contact du tableau. Cela rompt la loi « carrée » : doubler l'effectif ne double plus le feu effectif.
2. **Désengagement automatique** au seuil du type : la bataille s'arrête avant 30 minutes.
3. **Fatigue renforcée** : l'intensité décroît après le contact initial. Mécanisme existant, à recalibrer : par exemple un plancher de 0,5 au lieu de 0,7 [JEU].
4. **Durée** : la formule actuelle est conservée, plafonnée par la durée du type.

### 4.3 Fourchettes de pertes visées par bataille

Elles sont exprimées en pourcentage de l'effectif engagé, toutes catégories confondues. Ce sont des **[JEU]**, à valider. Elles servent de **cibles d'étalonnage** pour le banc d'essai : les résultats simulés doivent tomber dans ces bornes.

| Type | Attaquant | Défenseur (tient) | Défenseur (effondrement) | Composition attendue de l'attaquant | Composition attendue du défenseur |
|---|---|---|---|---|---|
| Escarmouche | 0,5 à 3 % | 0,3 à 2 % | — | tués ≈ 25 % des tués et blessés ; disparus faibles | idem |
| Engagement limité | 3 à 8 % | 2 à 6 % | 5 à 15 % | morts 20 à 25 %, blessés 65 à 75 %, disparus et prisonniers 5 à 10 % | idem si le défenseur tient |
| Assaut frontal | 8 à 20 % | 5 à 12 % | 20 à 50 % | comme la Somme et l'Isonzo : morts ≈ 22 à 25 %, blessés ≈ 65 à 70 %, disparus et prisonniers ≈ 9 à 13 % | tient : semblable ; effondrement : prisonniers et disparus majoritaires |
| Grande bataille | 15 à 35 % | 10 à 25 % | 40 à 80 % | idem | effondrement : prisonniers et disparus 60 à 75 % (Caporetto, août 1915) |

**Hypothèses :**
- **H1.** Une bataille tactique représente la **phase décisive** des combats d'un mois dans une région, et non une journée. C'est une interprétation de jeu (§9, Q1).
- **H2.** Le rapport attaquant / défenseur d'environ 1,5 [HIST, un seul cas] est retenu comme ordre de grandeur pour l'assaut frontal et la grande bataille quand le défenseur tient.
- **H3.** Les compositions viennent des cas historiques de la **colonne de droite** : ce sont des points de comparaison, pas des valeurs imposées.

**Confiance :**
- compositions : **moyenne** (plusieurs sources concordantes) ;
- asymétrie attaquant / défenseur : **faible à moyenne** (un seul cas) ;
- volumes totaux par type : **faible**, entièrement des paramètres de jeu : aucune source consultée ne donne de pertes par engagement en pourcentage de l'effectif engagé.

**Écart avec l'existant :** aujourd'hui, une bataille donne 30 à 90 % de pertes. Les fourchettes proposées impliquent une **baisse forte** du volume par bataille, sauf en cas d'effondrement.

**Limites des comparaisons :**
- les cas historiques sont des **campagnes** de plusieurs mois (Somme : cinq mois), pas des batailles de jeu ;
- les catégories diffèrent selon les pays (phase 5, §1) ;
- les effectifs engagés ne sont pas connus dans les sources consultées ;
- **le joueur doit pouvoir créer d'autres situations** : les fourchettes valent pour l'étalonnage d'ensemble, et chaque bataille doit pouvoir s'en écarter selon les choix et les circonstances.

---

## 5. Les quatre catégories et la conservation

### 5.1 Grandeurs nationales proposées (`ForceLedger`)

| Grandeur | Contenu | Nature |
|---|---|---|
| `killed` | Tués et morts de blessures sur le champ de bataille, plus morts en convalescence | Définitive |
| `wounded_convalescing` | Cohortes de blessés en soins : effectif et mois de sortie | Temporaire |
| `wounded_returned` | Blessés rendus au service (cumul) | Information ; les hommes redeviennent présents |
| `wounded_unfit` | Blessés définitivement inaptes (cumul) | Définitive |
| `missing` | Disparus de sort inconnu | Distincte, définitive tant que rien ne la résout |
| `prisoners_lost` / `prisoners_held` | Prisonniers chez l'origine et chez le détenteur | Définitive pour l'armée, vivants |
| `released`, `repatriated` | À 0 tant qu'aucun mécanisme n'existe | Futur (diplomatie) |
| `rejoined` | Survivants d'armées anéanties ayant rejoint le territoire (existant) | Information |
| Causes non militaires | Attrition d'encerclement (existant) | Définitive |

### 5.2 Invariant de personnel étendu (nation historique, sur la carte)

```
présents (unités + services)
  + tués + blessés en convalescence + blessés inaptes + disparus + prisonniers perdus
  + pertes d'attrition et sorts inconnus déjà inscrits
= actifs sur la carte + réservistes incorporés + Territorial Force incorporée
```

- Un blessé guéri **quitte** la convalescence et **redevient présent** : il est rendu à une unité par le chemin d'incorporation existant. Le total ne change pas, et l'homme n'est jamais compté deux fois.
- Un soldat ne figure **que dans une** catégorie à la fois. Les compteurs d'information (`wounded_returned`, `rejoined`) ne participent pas à l'invariant.

---

## 6. Retour des blessés

| Paramètre | Proposition | Statut | Base |
|---|---|---|---|
| Part rendue au service | **1 / 1,8 ≈ 55,6 %** | Royaume-Uni : **[HIST]** ; autres : **PROVISOIRE**, signalé comme approximation britannique | WO 1922 p. 246 ; décision du directeur |
| Inaptitude définitive | **Option A :** complément, 44,4 % [CALC], qui inclut aussi les hommes encore en soins fin 1918 (borne haute). **Option B :** 16,68 % (malades et blessés renvoyés au pays) + morts de blessures ultérieurs (à fixer). | Décision (§9, Q3) | WO p. 246 ; les définitions ne coïncident pas exactement |
| Délai de convalescence | **2 mois** pour tous, ou bien, par gravité, **1 mois** pour les légèrement blessés (environ 58 %) et **3 mois** pour les autres | **[JEU] PROVISOIRE** : aucune source consultée ne donne de délai | Les parts de gravité sont [HIST] (listes allemandes) ; les délais sont inventés |
| Blessés « restés dans leur unité » (≈ 10 % des blessés allemands) | Option : ne pas les retirer du tout | Décision (§9, Q4) | WO p. 354 |
| Destination au retour | Unités du district d'origine, sinon nouvelles unités de réserve (chemin d'incorporation existant, règle Q8 comprise) | [JEU] | — |
| Modifications par pays | Bloc `national_overrides` (taux, délais), chaque valeur avec son statut | — | Décision du directeur |

---

## 7. Sources historiques et leurs limites

- **Consultées en phase 5 :** War Office 1922 ; ЦСУ 1925 ; Mortara 1925 ; Dumas et Vedel-Petersen 1923. Détail et limites dans `MIL01_PHASE5_PERTES_HISTORIQUES.md`.
- **Recherches complémentaires de cette phase (15/11/2026)** :

| Document | Résultat |
|---|---|
| *Sanitätsbericht über das Deutsche Heer im Weltkriege 1914/1918*, t. III (*Die Krankenbewegung…*) | Notices de bibliothèque trouvées : [AWM](https://www.awm.gov.au/collection/LIB8823), [UNC](https://gwonline.unc.edu/node/6935). **Aucune numérisation accessible** trouvée. |
| Rapport Marin | Référence précise : *Journal officiel*, Documents parlementaires, vol. 2, 1920, p. 32-78, d'après l'[Encyclopédie 1914-1918-online](https://encyclopedia.1914-1918-online.net/bibliography/n6vdx9dv/). Texte non trouvé en ligne ; Gallica bloque l'accès automatisé. |
| Revue internationale de la Croix-Rouge, « Les pertes de l'armée française au cours de la guerre », oct. 1920, p. 1145-1147 | [Notice](https://www.cambridge.org/core/journals/international-review-of-the-red-cross/article/les-pertes-de-larmee-francaise-au-cours-de-la-guerre1/A97A18E88250A468D6119A6A4C58F958) ; texte non accessible |
| Réponse parlementaire britannique du 28 mars 1922 (« War losses, French return ») | [Hansard](https://api.parliament.uk/historic-hansard/written-answers/1922/mar/28/war-losses-french-return) : **aucun chiffre**, simple promesse de renseignement |
| Statistiques austro-hongroises et ottomanes primaires | Aucune nouvelle source accessible ; les tomes de *Österreich-Ungarns letzter Krieg* disponibles en ligne (III, IV, VI) ne contiennent pas l'annexe des pertes recherchée |

---

## 8. Tests prévus (à écrire lors de l'implémentation)

| Test | Vérifie |
|---|---|
| Conservation en bataille, pour chaque type d'engagement | Invariant étendu avant, pendant et après ; somme des quatre catégories égale aux pertes d'effectif de chaque unité |
| Ventilation au feu | Part des tués dans « tués + blessés » égale à `killed_share`, aux arrondis près, sur un grand échantillon |
| Déroute et effondrement | Pertes en déroute ventilées en disparus et prisonniers selon l'issue ; prisonniers inscrits chez le détenteur |
| Disparus | Jamais convertis automatiquement ; jamais comptés deux fois |
| Convalescence | Cohortes créées à la bonne date ; présents inchangés tant qu'elles ne sont pas rendues |
| Retour | À l'échéance : part rendue aux unités, inaptes inscrits ; invariant conservé ; région en bataille (Q8) respectée |
| Taux par pays | Le taux britannique est « sourcé », les autres sont signalés provisoires ; une modification nationale est prise en compte |
| Capitulation et anéantissement | Comportements existants inchangés |
| Libération | Aucun mécanisme : compteurs à 0 ; test à écrire quand la décision diplomatique existera |
| Retraites | Unité en déroute avec retraite sûre : disparus majoritaires ; sans retraite : prisonniers majoritaires |
| Types d'engagement | Les 9 combinaisons du §4.1 donnent le type attendu ; deux choix différents donnent des déroulements différents (durée, pertes) |
| Banc d'essai | Variantes réellement appliquées (formation verrouillée) ; résultats non identiques ; médianes de l'échantillon de 36 batailles **dans les fourchettes** validées |
| Non-linéarité | Doubler la durée maximale ne double pas les pertes |
| Sauvegarde et chargement | Format 4 avec cohortes de convalescence et disparus ; empreinte identique ; format 3 traité (refus ou migration) |
| Interfaces | Onglet Armée : tués, blessés en soins, inaptes, rendus, disparus, prisonniers ; écran de bataille : choix d'approche et de posture ; vérification visuelle réelle |
| Déterminisme | Deux batailles identiques donnent des ventilations identiques |

---

## 9. Modifications de code nécessaires (non faites)

| Fichier | Modification |
|---|---|
| `src/domains/combat/tactical_sim.gd` | Compter par unité les pertes en déroute et hors déroute ; largeur de front ; seuils de désengagement ; intensité par type ; fatigue recalibrée |
| `src/domains/combat/battle_manager.gd` | Type d'engagement à la création ; ventilation à la clôture (§3) ; captures en bataille ; détenteur des prisonniers |
| `src/domains/combat/combat_data.gd` | Nouveaux champs de bataille et d'unité (sérialisés) |
| `src/domains/military/force_ledger.gd` | Catégories du §5 ; cohortes de convalescence ; paramètres nationaux ; normalisation |
| `src/domains/military/mobilization_system.gd` | Étape mensuelle de convalescence (retours par le chemin d'incorporation) ; résumé ; invariant étendu |
| `src/simulation/orders.gd`, `turn_resolver.gd`, `military_system.gd` | Approche de l'attaquant dans l'ordre de déplacement ; posture défensive par armée ou par région |
| `src/ai/tactical_ai.gd`, `nation_agent.gd` | Choix d'approche et de posture par l'IA ; respect des formations imposées dans les variantes du banc d'essai |
| `src/ui/game_ui.gd`, `battle_view.gd` | Nouvelles catégories ; choix d'approche et de posture |
| `data/rules/combat_rules.json` | Blocs `engagement_types`, `casualty_composition`, `wounded_recovery` (avec `national_overrides`), statuts PROPOSÉ ou PROVISOIRE |
| `src/adapters/save_repository.gd`, `game_state.gd` | Format 4 |
| `tests/balance_report.gd` et nouveaux tests | §8 ; banc d'essai avec assertions de bornes |
| Documentation | `docs/project/COMBAT_SYSTEM.md`, `PERTES_ET_PRISONNIERS.md`, registre des décisions |

**Ordre conseillé :**
1. Comptabilité (catégories, convalescence), sans changer les volumes.
2. Types d'engagement et intensité.
3. Étalonnage sur les fourchettes validées.

Chaque étape serait testée et soumise à validation séparément.

---

## 10. Questions qui vous reviennent

| N° | Question | Proposition par défaut |
|---|---|---|
| **Q1** | **Échelle d'une bataille tactique** : que représente-t-elle (la phase décisive du mois dans une région, une journée de combat, autre chose) ? Les fourchettes en dépendent. | Phase décisive du mois dans une région |
| **Q2** | **Fourchettes du §4.3** (volumes par type et par rôle) : les valider, les ajuster ou en demander d'autres ? Elles impliquent une forte baisse des pertes actuelles (30 à 90 % par bataille). | Valider comme cibles d'étalonnage |
| **Q3** | **Inaptitude définitive** : option A (complément du retour, 44,4 %, borne haute) ou option B (16,68 %, plus les décès ultérieurs) ? | A, signalée comme borne haute |
| **Q4** | **Convalescence** : délai unique de 2 mois, ou 1 et 3 mois selon la gravité (parts de gravité allemandes) ? Faut-il ne pas retirer les blessés « restés dans leur unité » ? | 1 et 3 mois ; blessés restés dans l'unité non retirés |
| **Q5** | **Disparus** : catégorie définitive, ou résolution ultérieure (par exemple après N mois, une part reconnue prisonnière, le reste mort) ? | Définitive pour l'instant ; résolution à décider avec la diplomatie |
| **Q6** | **Captures en bataille** (§3.3) : accepter la règle et ses parts provisoires (0 / 30 / 80 % selon l'issue) ? | Accepter, valeurs PROVISOIRES |
| **Q7** | **Choix T-055** : les trois approches (reconnaissance en force, attaque limitée, assaut) et les trois postures (retardement, tenir, tenir à tout prix) vous conviennent-elles ? | Oui |
| **Q8** | **Largeur de front** (rupture de la loi « carrée ») : l'accepter comme principe ? Elle modifie une règle générale de bataille. | Oui |
| **Q9** | **Part des tués** : 0,25 commun à toutes les puissances, la Russie (19,5 % observé) étant expliquée par son mode de comptage ? | Oui |
| **Q10** | **Ordre d'implémentation** : comptabilité, puis types d'engagement, puis étalonnage, avec une validation entre chaque étape ? | Oui |

---

## 11. Synthèse des décisions attendues

1. Ce que représente une bataille tactique (Q1).
2. Les fourchettes de pertes par type et par rôle comme cibles d'étalonnage (Q2).
3. La règle d'inaptitude et les délais de convalescence (Q3, Q4).
4. Le sort ultérieur des disparus (Q5) et la règle de capture en bataille (Q6).
5. Les approches et postures de T-055 (Q7), et la largeur de front (Q8).
6. La part commune des tués (Q9) et l'ordre d'implémentation (Q10).

**État :**

| Élément | État |
|---|---|
| Ce rapport | Documenté |
| Code, paramètres de combat et règles de bataille | **Inchangés** |
| Tests prévus (§8) | Décrits, **non écrits** |
| Suite existante | Relancée sur ce poste, résultat dans le compte rendu de fin de phase |
