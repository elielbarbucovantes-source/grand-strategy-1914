# Audit historique et technique de MIL-01

**Branche :** `audit/mil01-review`, créée depuis `dev/historical-forces` (`a46d8e9`).

**Date :** 15/11/2026.

**Nature :** audit seulement.
- Aucun fichier de code, aucune donnée de jeu, aucun paramètre ni aucune décision n'a été modifié.
- Ce rapport est le seul fichier ajouté.
- Les mesures ont été faites avec une sonde hors dépôt (dans le dossier temporaire de session), qui appelle le code du jeu sans le modifier.

**État du dépôt au départ :**
- `dev/historical-forces` était propre (aucune modification non validée) et identique à `origin/dev/historical-forces`.
- `main` (`4ffdb8a`), `origin/main` (`1ec985f`) et `dev/combat-system` (`f505a23`) sont inchangés.

**Légende des niveaux de certitude :**
- **établi** : vérifié dans le code, par exécution ou dans la source ;
- **probable** : indices convergents, non démontré ;
- **hypothèse** : piste à vérifier.

---

## A. Synthèse générale

MIL-01 est une **base sérieuse mais pas encore fiable pour une campagne historique complète**.

**Ce qui est solide (établi) :**
1. Chaque chiffre national est rattaché à une source primaire identifiable, avec page, définition et divergences. La source américaine de 1916 a été relue pour cet audit.
2. La mécanique de mobilisation conserve exactement les effectifs : ni création, ni double comptage, ni dépassement du réservoir. Les tests le vérifient, en temps de paix.
3. Les 54 tests unitaires et les deux tests d'interface passent, sur ce poste comme sur GitHub Actions (exécution `43718120689`).

**Principaux risques :**

| # | Risque | Gravité |
|---|---|---|
| 1 | **L'IA stratégique ne mobilise jamais.** Seul un joueur humain peut décréter la mobilisation : un pays de l'IA reste à son effectif de paix pendant que l'humain peut multiplier le sien par 4 à 6 (P0-1). | P0 |
| 2 | **Les 4,8 millions d'hommes allemands dépassent la propre source du projet** : le document américain donne, page 28, **4 610 000** hommes instruits mobilisables au total, actifs compris. Le jeu additionne un actif de 1914 et un réservoir estimé en 1911 (P0-2). | P0 |
| 3 | **Les décisions T-047 à T-050 ne sont pas appliquées dans le code.** T-049 (rythme national, influence du joueur, coûts), T-050 (Territorial Force) et T-048 (intensité variable) ne le sont pas. T-047 l'est en grande partie, sans compter les pertes. Les quatre décisions sont **absentes des registres** du dépôt. | P1 |
| 4 | **Les pertes de combat sont systématiquement très lourdes, pas exceptionnelles.** Sur 36 batailles frontalières tirées de la campagne, 28 voient un camp perdre au moins 40 % de ses hommes et 20 au moins 60 % ; 30 atteignent le plafond de 30 minutes. Le « 66 % contre 4 % » de Lorraine vient surtout d'un rapport de forces de 1 contre 2,2, puis 3,9 avec les renforts. | P1 |
| 5 | **La répartition régionale est entièrement estimée.** 6 sièges seulement sur 113 portent une vérification, dont 2 au seul niveau de la province. Deux placements sont probablement erronés (VIe corps russe ; IIe et IIIe corps ottomans). | P1 |
| 6 | **Aucune comptabilité nationale des pertes.** Après une bataille, les cinq catégories ne se réconcilient plus, et aucun test ne couvre la conservation des effectifs en temps de guerre. | P1 |

**Verdict.** MIL-01 doit rester « **non terminé** », comme le rapport précédent l'indiquait. Ce statut est désormais **aggravé** sur trois points : P0-1, P0-2 et la non-conformité à T-049 et T-050.

---

## B. Tableau historique des sept puissances

### B.1 Vérification des chiffres retenus

Les pages citées du document américain (*US War Department, Strength and Organization of the Armies…, 1916*) ont été recontrôlées dans le texte intégral (archive.org `strengthorganiza00unit`).

| Puissance | Actif retenu (source, date, définition) | Réserves retenues | Contrôle d'audit | Fiabilité réelle | Problèmes | Recommandation |
|---|---|---|---|---|---|---|
| **Allemagne** | **806 016** : US WD 1916 p. 9 et p. 28, « conditions in July 1914 », officiers et hommes sous les drapeaux | **4 000 000** : US WD p. 9, « fully trained reserves », **estimation de 1911** | p. 28 : « The sum total of trained men which she is able to mobilize amounts to **4,610,000** », actifs compris. Donc **806 016 + 4 000 000 = 4 806 016 > 4 610 000** (+196 016, +4,3 %). Bundesarchiv : 3,8 M mobilisés en août 1914, actifs compris. | Actif : moyenne. Réserves : **faible**, car incohérentes avec la page 28 du même document. | Mélange de dates (actif 1914, réserves 1911) et de tableaux. Une partie des réservistes estimés en 1911 a pu passer dans l'actif agrandi par la loi de 1913 (**hypothèse**, non démontrable avec cette source). | Retenir comme plafond total **4 610 000 − 806 016 = 3 803 984** réservistes (p. 28, même document, même date). Garder 4 000 000 comme divergence. **Correction factuelle, sans décision de conception.** |
| **France** | **844 188** : p. 9 (818 532) + coloniaux en France (25 656, p. 20) ; budget 1914 | **2 300 000** : p. 9, estimation de 1911 | p. 20 : « sum total of trained men… about **3,800,000** », actifs compris. Jeu : 0,844 + 2,3 = **3,14 M**, soit **0,66 M de moins** que la p. 20. p. 15 : réserves + territoriale = 2 869 000. | Moyenne (actif) ; faible à moyenne (réserves). | Écart interne du document de 620 420 à 818 532 pour l'actif. Le réservoir de 2,3 M **exclut** vraisemblablement l'armée territoriale, alors que celui de l'Allemagne inclut les instruits de la Landwehr : **comparabilité douteuse** (probable). | Documenter la composition par catégorie (active, réserve, territoriale, réserve de la territoriale), ou aligner toutes les puissances sur la ligne « total des instruits » des fiches nationales du même document. |
| **Autriche-Hongrie** | **472 715** : p. 37 à 39, armée commune + Landwehr + Honvéd + Bosniaques | **2 000 000** : p. 37-38, « fully trained men subject to call » | p. 9 : 1 600 000 pour l'armée commune seule. Le document juge les données de la Landwehr « little more than an incomplete guess » (p. 38). | Moyenne (actif) ; **faible** (réserves). | Ventilation par arme de l'armée commune appliquée à la Landwehr et au Honvéd (estimation). | Compléter par l'histoire officielle autrichienne (voir B.3). |
| **Russie** | **1 284 000** : p. 9 et p. 45, tout l'empire | **3 800 000** : p. 9, estimation de 1911 | p. 46 : « other trained men available » = 2 970 429 (total de guerre 5 962 306). Jeu : 1,284 + 3,8 = 5,08 M. | Faible à moyenne (actif) ; **faible** (réserves). | Part européenne des réserves fixée à 27 corps sur 37, au prorata des corps. Or les réservistes proviennent de la population, majoritairement européenne : le réservoir sur la carte est **probablement sous-estimé** (direction établie, ampleur inconnue). | Remplacer la clé « nombre de corps » par une clé sourcée par circonscription militaire, ou la signaler comme « minimum ». |
| **Royaume-Uni** | **247 432** : War Office 1922, p. 30, armée régulière au 1er août 1914 | **209 280** : War Office 1922, p. 30 (Army Reserve 145 347 + Special Reserve 63 933) | Cohérent. Hors carte : 121 123 (p. 157). La Territorial Force (268 777) est exclue (voir E). | **Haute.** | La ventilation par arme reprend les proportions américaines (p. 9, 255 438) appliquées au chiffre du War Office : estimation. | Conserver. |
| **Italie** | **305 033** : p. 9 et p. 66, budget, hors Afrique | **1 250 000** : p. 9, estimation de 1911 | p. 66 : « conservative estimate… 1,300,000 fully trained ». L'effectif présent est inférieur au budget de « several thousand » (p. 63). | Faible à moyenne. | Forces métropolitaines détachées en Libye : **inconnues**, l'actif sur la carte est donc probablement surévalué. Neutralité d'août 1914 et entrée en guerre en 1915 : dépend de R-13. | Rechercher les effectifs en Libye en 1914 (voir B.3). |
| **Empire ottoman** | **208 000** : Erickson 2000 (blog, **sans page**), « about 200,000 men and 8,000 officers » | **1 000 000** : Erickson 2000, « easily available for recall » | Source secondaire unique, reprise sur un blog, sans pagination. Potentiel total : 2 000 000. | **Faible à moyenne.** La base indique « moyenne » pour l'actif : c'est surévalué tant que *Ordered to Die* (2001) n'est pas consulté. | Ventilation par arme inconnue (infanterie générique). Part sur la carte : 3 corps sur 13, estimation. | Consulter Erickson 2001 (voir B.3) ; abaisser la fiabilité affichée en attendant. |

### B.2 Comparabilité entre puissances

- **Actifs :** la définition est **homogène** pour six puissances (p. 9 du document américain : « Only officers and men with colors »). Le Royaume-Uni utilise une autre source à la même date, avec un écart de 3 %. L'Empire ottoman relève d'une autre source et d'une autre définition, ce qui est acceptable et signalé.
- **Réserves :** la définition affichée est homogène (« fully trained reserves »), mais son **contenu national ne l'est pas** :
  - pour l'Allemagne, elle dépasse le total des instruits de la page 28 ;
  - pour la France, elle est inférieure de 0,66 M au total de la page 20 ;
  - pour l'Autriche-Hongrie, elle vient d'une autre page (p. 37-38) que le tableau p. 9.
- Le document américain avertit lui-même que ces chiffres sont des estimations de 1911 et que les augmentations ultérieures n'ont pas été publiées (p. 9). Conséquence probable : les rapports de force mobilisés entre puissances sont **moins fiables** que les actifs.
- **Aucune erreur de transcription n'a été trouvée** : les valeurs de la base correspondent aux pages citées.

### B.3 Sources fiables recommandées (non consultées pendant cet audit)

Ces ouvrages existent et font autorité. **Aucune page n'est indiquée, car ils n'ont pas été consultés.**

- **Allemagne :**
  - Reichsarchiv, *Der Weltkrieg 1914 bis 1918*, t. I (1925) et volumes annexes sur l'armée et la mobilisation ;
  - General Staff, War Office, *Handbook of the German Army (Home and Colonial)*, 1912, amendé en août 1914 (archive.org `hndbk-german-army-1914`, déjà cité). Son texte OCR téléchargé pour l'audit est trop dégradé pour en extraire la liste des sièges.
- **France :** Ministère de la Guerre, État-major de l'armée, Service historique, *Les Armées françaises dans la Grande Guerre*, tome X (ordres de bataille des grandes unités) et tome I, vol. 1.
- **Autriche-Hongrie :** Bundesministerium für Heerwesen et Kriegsarchiv, *Österreich-Ungarns letzter Krieg 1914-1918*, t. I (1930).
- **Russie :** l'état officiel de stationnement des troupes avant la mobilisation de 1914 (*Роспись войск*). Un fragment trouvé en ligne ne couvre que le Ier corps sibérien, il est inexploitable en l'état. Il existe aussi un *Handbook of the Russian Army* du War Office (1914), qui comporte une section sur la répartition des troupes en temps de paix, repérée mais non consultée.
- **Italie :** Ministero della Guerra, Ufficio Storico, *L'Esercito italiano nella Grande Guerra (1915-1918)*, vol. I.
- **Empire ottoman :** Edward J. Erickson, *Ordered to Die: A History of the Ottoman Army in the First World War*, Greenwood, 2001.

---

## C. Audit de la répartition régionale

### C.1 Méthode actuelle

Code : `tools/export/build_scenario.py`, fonctions `locate_districts` et `_split`.

1. Chaque nation a une liste de districts du temps de paix, en pratique ses corps d'armée.
2. Le siège de chaque district est placé dans une région du jeu par un test de point dans polygone.
3. L'actif sur la carte est réparti **à parts égales** entre les districts sur la carte. Le réservoir l'est aussi, via `district_pool_weights`.

**Conséquence (établi) :** tous les corps d'une nation ont exactement le même effectif.
- Allemagne : 806 016 / 25, soit environ 32 240 hommes, dont 57 819 combattants par région de deux corps.
- France : 761 820 / 21, soit environ 36 277 hommes.
- Russie : 936 973 / 27, soit environ 34 703 hommes.

Cette répartition est **artificiellement uniforme** :
- **Corps de couverture :** les régions frontalières n'ont pas plus de troupes que l'intérieur. Les corps de couverture étaient historiquement renforcés : c'est notoire pour les corps français de l'Est et les corps allemands d'Alsace-Lorraine (probable ; à chiffrer avec les sources de B.3). Par exemple, l'Alsace-Lorraine allemande (région 035) a 57 819 combattants face à 127 820 en Lorraine française (région 011), uniquement parce que la région 011 compte 4 sièges et la région 035 deux.
- **Troupes hors des corps :** les troupes de forteresse, l'artillerie à pied et les garnisons hors des corps sont fondues dans les corps.
- **Corps colonial français :** il reçoit 36 277 hommes alors que la source donne 25 656 coloniaux en France (p. 20).
- **Algérie :** l'actif hors carte (82 368) est chiffré par la source, mais les réserves hors carte sont fixées à 1/22 (district compté). Les deux méthodes sont incohérentes pour la même nation.

### C.2 Statut des 113 sièges de district (Allemagne 25, France 22, Autriche-Hongrie 16, Russie 27, Royaume-Uni 8, Italie 12, Empire ottoman 3)

| Catégorie | Nombre | Détail |
|---|---|---|
| 1. Vérifiés dans une source citée | **6** | Garde à Berlin (Handbook) ; XX Allenstein et XXI Sarrebruck (Bernhardi 1914) ; Aldershot (US WD p. 60) ; XV et XVI : le Handbook dit seulement « stationed in Alsace-Lorraine ». **La province est vérifiée, pas les villes de Strasbourg et Metz.** Cela suffit pour le jeu, puisque les deux villes sont dans la région 035. |
| 2. Estimés à partir de sources indirectes | 3 (comptés aussi en 4) | Ottomans I, II et III, rattachés au siège de la Ire armée, d'après un article encyclopédique citant Erickson. |
| 3. Répartition choisie faute de données | Tous | Parts égales par corps (C.1) ; Landwehr autrichienne et Honvéd rattachés aux corps (estimation) ; part européenne russe et ottomane des réserves au prorata des corps. |
| 4. Encore « à vérifier » | **107** | Allemagne 20, France 22, Autriche-Hongrie 16, Russie 27, Royaume-Uni 7, Italie 12, Empire ottoman 3. |

**Liste précise des sièges à vérifier :**
- **Allemagne :**
  - I Königsberg, II Stettin, III Berlin, IV Magdebourg, V Posen, VI Breslau, VII Münster, VIII Coblence ;
  - IX Altona, X Hanovre, XI Cassel, XII Dresde, XIII Stuttgart, XIV Karlsruhe ;
  - XVII Dantzig, XVIII Francfort, XIX Leipzig ;
  - corps bavarois : I Munich, II Wurtzbourg, III Nuremberg.
- **France :**
  - 1er Lille, 2e Amiens, 3e Rouen, 4e Le Mans, 5e Orléans, 6e Châlons-sur-Marne, 7e Besançon, 8e Bourges, 9e Tours ;
  - 10e Rennes, 11e Nantes, 12e Limoges, 13e Clermont-Ferrand, 14e Lyon, 15e Marseille, 16e Montpellier, 17e Toulouse, 18e Bordeaux ;
  - 20e Nancy, 21e Épinal, corps colonial à Paris, 19e Alger (hors carte).
- **Autriche-Hongrie :** I Cracovie, II Vienne, III Graz, IV Budapest, V Pozsony, VI Kassa, VII Temesvár, VIII Prague, IX Leitmeritz, X Przemyśl, XI Lemberg, XII Hermannstadt, XIII Agram, XIV Innsbruck, XV Sarajevo, XVI Raguse.
- **Russie :**
  - Garde, I et XVIII Saint-Pétersbourg ; XXII Helsingfors ;
  - II Grodno, III Vilna, IV Minsk, XX Riga ;
  - VI Łomża, XIV Lublin, XV et XXIII Varsovie, XIX Brest-Litovsk ;
  - IX et XXI Kiev, X Kharkov, XI Rovno, XII Vinnitsa, VII Iekaterinoslav, VIII Odessa ;
  - Grenadiers, XVII et XXV Moscou ; V Voronej ; XIII Smolensk ; XVI Kazan ; XXIV Samara.
- **Royaume-Uni :** Southern (Salisbury), Eastern (Londres), London (Londres), Northern (York), Western (Chester), Scottish (Édimbourg), Irish (Dublin).
- **Italie :** I Turin, II Alexandrie, III Milan, IV Gênes, V Vérone, VI Bologne, VII Ancône, VIII Florence, IX Rome, X Naples, XI Bari, XII Palerme.
- **Empire ottoman :** I, II, III, tous placés à Constantinople.

**Recherches faites pendant l'audit.** Ces sources sont **secondaires** : elles ne suffisent pas à marquer un siège « vérifié », mais elles signalent deux probables erreurs.

| Siège | Valeur de la base | Indice contraire | Effet dans le jeu (vérifié par point dans polygone) | Certitude |
|---|---|---|---|---|
| VIe corps russe | Łomża (région 056) | Article encyclopédique : siège à Łomża **jusqu'en 1909**, puis Białystok. L'article demande des citations. | Białystok est dans la **région 057** (Biélorussie), pas dans la 056. | Probable |
| IIe et IIIe corps ottomans | Constantinople (région 087) | Articles encyclopédiques citant Erickson : garnisons en Thrace, à Edirne, Tekirdağ et Kırk Kilise, avec des versions divergentes. | Edirne et Kırklareli sont dans la **région 089**, Tekirdağ dans la **région 088**. Aujourd'hui, les 48 000 Ottomans sont tous dans la région 087 et les régions 088 à 090 sont vides. | Probable, mais les villes exactes restent incertaines |

Les autres sièges concordent avec la connaissance encyclopédique courante. Cela n'établit rien : ils doivent rester « à vérifier » jusqu'à la consultation des sources de B.3.

### C.3 Hors carte, garnisons et forces coloniales

| Puissance | Hors carte (actif) | Statut | Remarque d'audit |
|---|---|---|---|
| Royaume-Uni | 121 123 | Sourcé (War Office 1922, p. 157) | Correct |
| France | 82 368 (Algérie et Tunisie) | Dérivé d'une source (p. 20) | Correct ; les réserves hors carte sont calculées autrement (C.1) |
| Russie | 347 027 | **Estimation** (10 corps sur 37) | Les corps sibériens et turkestanais avaient des effectifs différents : estimation grossière |
| Empire ottoman | 160 000 | **Estimation** (10 corps sur 13) | À reprendre avec Erickson 2001 |
| Italie | 0 | Partiel | Les détachements métropolitains en Libye sont **inconnus**. L'actif sur la carte est probablement surévalué. |
| Allemagne et Autriche-Hongrie | 0 | Sourcé ou constat | Les troupes coloniales allemandes (plus de 10 000, p. 28) sont hors du périmètre actif : correct |

**Cohérence entre national et régional (vérifiée par le test `test_territorial_distribution` et recalculée) :** la somme des unités et des services sur la carte égale l'actif sur la carte pour chaque nation. Aucun soldat n'est perdu ni créé par la répartition.

---

## D. Audit de la mobilisation

### D.1 Fonctionnement réel (code lu : `src/domains/military/mobilization_system.gd`)

1. **Décret** : ordre `mobilize`, une seule fois par partie, irréversible. Il est accepté en temps de paix, **sans aucune conséquence diplomatique ni coût**.
2. **Appel** : à la fin du même mois, 50 % du réservoir **initial** est appelé, réparti par district.
3. **Transit** : un mois, quelle que soit la nation.
4. **Incorporation**, à condition que la région du district soit contrôlée et reliée à la capitale. Les unités du district sont d'abord complétées jusqu'à deux fois leur effectif de paix ; le reste forme des unités de 20 000 hommes.

**Chronologie de l'Allemagne** (relancée avec `tests/balance_report.gd` pendant l'audit, reproductible) :

| Fin du mois | En cours de mobilisation | Incorporés | Présents |
|---|---|---|---|
| M (décret) | 2 000 000 | 0 | 806 016 |
| M+1 | 2 001 000 | 1 999 000 | ≈ 2,8 M |
| M+2 | 0 | 4 000 000 | **4 806 016** |

### D.2 Pourquoi 4,8 millions contre 3,8 millions historiques ?

**Diagnostic (établi pour les points 1 à 3, probable pour le point 4) : la cause est une combinaison, et l'excès ne vient pas d'une erreur de comptabilité.**

1. **Chiffres de départ, principale cause de l'excès.** Le réservoir de 4,0 M (tableau p. 9, 1911) additionné à l'actif de 1914 dépasse de 196 016 hommes le total de la même source (4,61 M, p. 28). Même avec ce plafond, 4,61 M dépassent encore les 3,8 M d'août 1914.
2. **Définition des réserves.** Le réservoir représente **tous les instruits rappelables**. Or le chiffre de 3,8 M du Bundesarchiv mesure **ce qui a été effectivement mobilisé en août 1914**, après l'appel prévu par le plan de mobilisation. Les deux ne mesurent pas la même chose. Les classes plus âgées du Landsturm et une partie des instruits n'ont été appelées que plus tard. Le modèle ne distingue pas ces catégories (réserve, Landwehr, Landsturm, Ersatz) et appelle donc **tout** le réservoir.
3. **Délais et rythme.** 50 % du réservoir initial par mois, plus un mois de transit, identiques pour toutes les nations. Paradoxalement, le jeu est **plus lent** que l'histoire au début (rien d'incorporé avant M+1), mais il n'a **aucun plafond** propre au plan de mobilisation et dépasse donc ce qui a été effectivement mobilisé.
4. **Logique d'incorporation : pas en cause.** Elle ne crée rien. L'invariant « réservoir + en cours + incorporés = initial » est vérifié chaque mois. L'effet d'échelle (974 unités) découle des points 1 à 3.
5. **Comptabilisation : pas d'erreur trouvée.** Présents = actifs + incorporés, exactement, en temps de paix.

**Correction proposée, sans ralentissement arbitraire :**
- (a) **Correction factuelle** : plafonner le total allemand au chiffre de la page 28 (réservoir 3 803 984) ; vérifier la même relation pour les autres puissances (B.1).
- (b) **Modèle** : scinder le réservoir en **échelons sourcés**. Le premier échelon correspond à l'appel prévu par le plan de mobilisation ; les échelons suivants (classes âgées) ne sont appelables que plus tard ou par un ordre distinct. Les chiffres viendraient des sources de B.3.
- (c) **T-049** : le rythme national viendrait des capacités sourcées (D.4).

### D.3 Autres constats

| Point | Constat | Certitude |
|---|---|---|
| Délai entre l'ordre et l'arrivée | Un mois fixe, quels que soient le pays, la distance et le réseau ferré | Établi |
| Transport | Aucun calcul de transport. La seule condition est d'être relié à la capitale (`LogisticsSystem`), sans capacité ferroviaire. | Établi |
| Contrôle de la garnison | Respecté pour l'incorporation. **Mais l'appel est réparti même vers un district déjà occupé** : ces réservistes restent bloqués « en cours de mobilisation » **indéfiniment**, sans pertes, fuite ni redirection. | Établi (lecture de `_call_up`) |
| Capacités administratives | Non modélisées | Établi |
| Double comptage | Aucun trouvé : un actif n'entre jamais dans le réservoir, et une cohorte sort de la liste « en cours » dès son incorporation | Établi (code et tests) |
| Dépassement artificiel du réservoir | Impossible par la mécanique. Seule la donnée de départ (Allemagne) dépasse sa source. | Établi |
| Différences entre puissances | Aucune, hormis les données : `national_overrides` est vide | Établi |
| **IA** | `NationAgent` n'émet **jamais** l'ordre `mobilize`. Il ne propose que des déplacements, des traités de paix et des réponses. | **Établi** (`src/ai/nation_agent.gd`) |
| Mobilisation en temps de paix | Permise, gratuite, sans effet diplomatique (la mobilisation de 1914 valait déclaration de guerre de fait) | Établi ; question de conception |

### D.4 Conformité aux décisions validées

| Décision | Exigence | État du code | Écart |
|---|---|---|---|
| T-047 | Départ avec les actifs, réserves progressives, cinq catégories | Conforme pour l'actif et les réserves | Il manque une sixième grandeur : **pertes, prisonniers et disparus**. Sans elle, les catégories ne se réconcilient pas après un combat (F). |
| T-049 | Rythme national (capacités administratives, ferroviaires, logistiques) | **Non conforme** : rythme identique pour tous | Paramètres nationaux sourcés à créer |
| T-049 | Le joueur peut influencer le rythme | **Non conforme** : un seul ordre, tout ou rien | Ordre de mobilisation partielle ou accélérée à créer |
| T-049 | Une accélération entraîne contraintes et coûts | **Non conforme** : aucun coût (l'économie, R-03, n'est pas définie) | Dépend d'ECO-01/02 |
| T-050 | La Territorial Force est une catégorie distincte | **Non conforme** (E) | — |
| Registres | T-047 à T-050 consignés | **Absents** de `docs/decisions/` et de `DECISIONS_PENDING.md`. `MOBILISATION.md` et la base indiquent encore « Territorial Force : si le directeur le décide ». | Mise à jour documentaire |

---

## E. Cas britannique : la Territorial Force (T-050)

| Vérification | Résultat | Certitude |
|---|---|---|
| Effectifs non confondus avec l'armée professionnelle | Oui : l'actif (247 432) est l'armée régulière seule (War Office 1922, p. 30) | Établi |
| Non comptés dans les réserves classiques | Oui : 209 280 = Army Reserve + Special Reserve ; la Territorial Force (268 777, p. 30) figure dans `excluded` | Établi |
| Délais distincts | **Sans objet : la catégorie n'existe pas dans le jeu** | Établi |
| Incorporation progressive | **Non implémentée** | Établi |
| Distinction dans l'interface | **Absente** : aucune mention dans `src/ui/` | Établi (recherche dans le code) |
| Chiffre de 1914 | 268 777 au 1er août 1914 (War Office 1922, p. 30). Source officielle de haute fiabilité, même tableau que l'actif. | Établi |

**Points de fiabilité à signaler :**
- Le chiffre est un **effectif réel**, inférieur à l'effectif théorique de la force. Ne pas confondre les deux lors de l'intégration.
- Au 1er août 1914, la Territorial Force n'était astreinte qu'au service intérieur. Le service outre-mer reposait sur un engagement volontaire (Imperial Service). Le jeu devra représenter cette contrainte ; c'est une question de conception, voir K.
- **La National Reserve (215 451)** est exclue à juste titre : c'est un registre sans obligation de rappel.

**Proposition :**
- un champ `territorial_force` séparé, avec sa propre source, son propre délai et sa propre règle d'emploi ;
- une ligne distincte dans l'onglet Armée ;
- des tests de non-confusion avec le réservoir.

---

## F. Intégration au système de combat

| Point | Constat | Certitude |
|---|---|---|
| Création des unités | Exacte, par plus forts restes : somme des unités + services = actif sur la carte | Établi (test et recalcul) |
| Conservation pendant la mobilisation | Exacte | Établi (`test_progressive_mobilization_without_double_counting`) |
| Mobilisés et présents dans les unités | Égalité exacte, **en temps de paix seulement** | Établi |
| **Pertes et effectifs nationaux** | `BattleManager.finish` écrit les effectifs restants dans les unités, mais aucun compteur national de pertes, prisonniers (reddition) ou attrition d'encerclement n'existe. `MobilizationSystem.summary` ne peut donc pas expliquer la baisse des présents. | Établi |
| Unités détruites | Retirées (`remove_formation`) ; une armée vide l'est aussi | Établi (`test_destroyed_unit_removed_and_losses_saved`) |
| **Services d'une armée anéantie ou capitulée** | `remove_formation` supprime aussi les divisions, et donc leurs `services_soldiers` : ces non-combattants disparaissent sans être comptés. À l'inverse, une division dont toutes les unités sont détruites mais dont l'armée survit **garde ses services**. | Établi (lecture) ; effet non mesuré |
| Renforts | Limités aux 12 plus rapides par camp ; les unités engagées sont verrouillées | Établi (test) |
| Unités dans plusieurs batailles | Empêché par le verrou `battle_id` ; la mobilisation ne complète jamais une unité engagée | Établi |
| **Mobilisation pendant une bataille humaine en cours** | L'incorporation de fin de mois peut créer une **nouvelle armée de réserve dans la région même de la bataille**, hors de la bataille. Après une défaite, elle reste au contact de l'ennemi. | Établi (lecture) ; **non testé** |
| Réapprovisionnement des pertes | Les réservistes complètent les unités affaiblies jusqu'à leur effectif de guerre, ce qui est conservatif. Une fois le réservoir épuisé, plus rien : MIL-02 ouvert. | Établi |
| Sauvegarde et chargement | Testés en pleine bataille et après mobilisation (`test_save_reload_mid_battle_and_after_mobilization`) | Établi |
| Cohérence entre carte et combat | Les unités tactiques sont construites depuis les unités stratégiques réelles et réécrites à la fin | Établi |
| **Granularité** | 434 unités au départ, 974 après mobilisation complète ; les batailles de 65 unités ou plus coûtent plus de 5 s de calcul (H) | Établi |

**T-045 (croisement sans bataille) et T-046 (déconnexions) :**
- Les 5 et 3 tests annoncés existent et passent.
- Le code correspond à la documentation (`resolve_moves` évalue les positions finales ; `neutral_pick` est reproductible).
- Aucune interaction problématique avec MIL-01 n'a été trouvée. Une seule réserve : T-046 n'a **aucune couche réseau**, ce qui est conforme à ce qui avait été annoncé.

---

## G. Équilibrage des combats

### G.1 Reproductibilité

`tests/balance_report.gd` a été relancé à l'identique. Les résultats sont **identiques au chiffre près** :
- Lorraine : 38 101 pertes attaquantes (66 %) contre 9 996 (4 %) ;
- Lorraine après mobilisation : 53 % contre 11 %.

Les batailles IA contre IA sont **déterministes**.

**Défaut du banc d'essai (établi).** La variante « défenseur en ligne de tirailleurs » donne exactement les mêmes chiffres que la variante par défaut. En effet, l'IA tactique réimpose sa formation dès les premiers pas (`TacticalAI.decide`, `_formation_if`). La variante ne teste donc rien, et le rapport précédent l'a présentée comme un cas distinct sans le signaler.

### G.2 Représentativité : échantillon de 36 batailles

**Méthode :** toutes les paires de régions voisines où deux des sept puissances ont chacune une armée. La plus grande armée de l'une attaque la région de l'autre, en IA contre IA, au mois 1 de la campagne. Une guerre fictive est ajoutée entre les deux ; elle sert seulement à tester la mécanique.

| Mesure | Minimum | Médiane | Maximum |
|---|---|---|---|
| Pertes de l'attaquant | 2 % | 40,5 % | 81 % |
| Pertes du défenseur | 0 % | 33 % | 92 % |
| Durée | 7,6 min | **30 min** | 30 min |
| Calcul | 0,4 s | 1,4 s | 2,9 s |

- 30 batailles sur 36 atteignent le **plafond de 30 minutes**.
- 28 sur 36 voient un camp perdre **au moins 40 %**, et 20 sur 36 **au moins 60 %**.
- Victoires : défenseurs 22, attaquants 13, une indécise.

| Rapport défenseur / attaquant | n | Pertes attaquant (médiane) | Pertes défenseur (médiane) | Victoires de l'attaquant |
|---|---|---|---|---|
| < 0,8 (attaquant supérieur) | 9 | 12 % | 78 % | 8 |
| 0,8 à 1,25 (équilibre) | 9 | 57 % | 44 % | 2 |
| > 1,25 (défenseur supérieur) | 18 | 54,5 % | 12,5 % | 3 |

**Même échantillon, effectifs initiaux égalisés.** Les unités de l'attaquant sont mises à l'échelle de l'effectif du défenseur ; les renforts restent tels quels.

| Mesure | Résultat |
|---|---|
| Pertes de l'attaquant | médiane **58 %** (17 à 78 %) |
| Pertes du défenseur | médiane **27,5 %** (5 à 87 %) |
| Batailles où l'attaquant perd plus que le défenseur | 30 sur 36 (écart médian : 28 points) |
| Victoires | défenseurs 29, attaquants 5, indécises 2 |
| Batailles au plafond de 30 minutes | 34 sur 36 |
| Batailles où un camp perd au moins 40 % | 33 sur 36 |

À effectifs égaux, **l'avantage défensif double à peu près les pertes de l'attaquant**. L'ampleur globale des pertes ne baisse pas.

**Conclusions :**
- Les pertes de 40 à 90 % sont **la norme du système**, pas une exception. Elles ne dépendent pas de l'échelle (pourcentages semblables entre 23 000 et 345 000 hommes).
- Le **rapport de forces** décide presque seul de l'issue (loi « carrée »).
- Le cas de Lorraine (66 % contre 4 %) n'est **pas un cas d'équilibre**. L'attaquant y est à 1 contre 2,2 au départ, puis 1 contre 3,9 après l'arrivée de 12 renforts défenseurs ; il n'en reçoit aucun lui-même.

### G.3 Mécaniques responsables (établi par lecture de `tactical_sim.gd` et `combat_rules.json`)

1. **Feu proportionnel à l'effectif, sans limite de front.**
   - Formule : `pertes = létalité × soldats du tireur × formation × efficacité × atténuation × dt × exposition de la cible`.
   - Une unité de 40 000 hommes tire comme 40 000 fusils à la fois ; aucune largeur de front ni proportion de soldats réellement au contact.
   - D'où des dynamiques de type Lanchester « carré » : la supériorité numérique s'auto-renforce.
2. **Intensité de contact constante.**
   - Calcul : environ 0,0011 × 2 s pour l'infanterie et 0,0042 × 2 s pour l'artillerie, multipliés par l'exposition.
   - Résultat : une armée en contact perd de l'ordre de **4 à 6 % de son effectif par minute**, ordre de grandeur calculé à partir des paramètres et cohérent avec les mesures.
   - Sur 30 minutes, il est impossible de rester sous 30 à 40 % de pertes sans désengagement.
3. **Avantage défensif multiplicatif.**
   - Un défenseur retranché a un feu de 1,15 et une exposition de 0,45. Un attaquant en ligne de tirailleurs a un feu de 1,0 et une exposition de 0,65.
   - Le défenseur inflige donc environ 1,66 fois plus de pertes par soldat, avant tranchées et couvert.
   - Pendant l'approche, la colonne d'assaut (exposition 1,5) est sous le feu de l'artillerie (portée 700) avant que sa propre infanterie (portée 260) puisse répondre.
4. **Durée saturée.**
   - Calcul : 10 min + 4 min par tranche de 10 000 hommes. Dès 50 000 hommes environ, la durée atteint le plafond de 30 min.
   - La durée ne distingue donc plus rien, et c'est elle qui fixe l'ampleur des pertes.
5. **Aucune notion de type d'engagement (T-048 D non implémenté).**
   - Escarmouche, combat limité, assaut et grande bataille n'existent ni dans le code ni dans les règles.
   - L'IA engage toujours tout jusqu'au plafond ou à la rupture.
6. **IA stratégique.**
   - `NationAgent` n'attaque jamais une région défendue : il ne fait qu'occuper des régions vides ou tenir sa position.
   - Mesure : 6 mois de guerre entre blocs IA, sans humain, ne produisent **aucune bataille** (environ 0,4 s par tour).
   - Les batailles naissent donc presque toutes d'un joueur humain ou d'une rencontre fortuite.

### G.4 Pistes d'équilibrage (non appliquées) et méthode de test

- **Pistes (T-048 D) :**
  - un **type d'engagement** choisi par l'attaquant, ou déduit de l'ordre stratégique, qui fixe trois grandeurs : la proportion des forces au contact (front), la durée maximale et un seuil de rupture ou de désengagement ;
  - un **plafond de front** : seule une fraction des soldats d'une unité tire, selon la largeur du champ ;
  - un **désengagement** IA ou automatique sous un seuil de pertes, selon le type d'engagement ;
  - un étalonnage d'**un seul** coefficient global de létalité une fois la cible fixée par le directeur.
- **Méthode :**
  - réparer le banc d'essai (les variantes doivent verrouiller la formation) ;
  - versionner l'échantillon des 36 paires sous forme de test de régression d'équilibre (médianes et dispersion) ;
  - ajouter des duels à effectifs égaux par terrain et par formation ;
  - fixer des bornes cibles par type d'engagement, validées par le directeur ;
  - rejouer après chaque changement et publier les tableaux.

---

## H. Tests et performances

### H.1 Inventaire (établi)

| Catégorie | Contenu |
|---|---|
| **Existants** | 54 fonctions `test_*` dans 7 fichiers : combat 21, règles 11, MIL-01 6, T-045 5, monde et état 5, T-046 3, intégration de campagne 3. S'y ajoutent `ui_smoke.gd` et `battle_ui_smoke.gd`, ainsi que des scripts non probatoires (`balance_report`, démonstrations, captures d'écran). |
| **Exécutés pendant l'audit** | Tous, avec `bash tests/run.sh` sur ce poste, plus `balance_report.gd` et la sonde d'audit |
| **Réussis** | 54 sur 54, interface stratégique et interface de bataille validées. GitHub Actions `43718120689` : **succès** sur `a46d8e9` (vérifié avec `gh run view`). |
| **Non exécutés** | Aucun test existant n'a été omis. `balance_report.gd` n'est **pas un test** : il n'affirme rien et ne peut pas échouer. |

### H.2 Comportements non couverts

1. Conservation des effectifs **en guerre** : mobilisation plus pertes, prisonniers et attrition.
2. Mobilisation par l'IA (elle n'existe pas).
3. Exactitude des valeurs de la base par rapport aux sources : les tests vérifient la **présence** d'une valeur, d'une page et d'une source, pas la **valeur**. Aucun test ne vérifie par exemple que le total allemand ne dépasse pas la page 28.
4. Incorporation créant une armée dans une région en pleine bataille.
5. Cohortes bloquées indéfiniment par un district occupé (seul le blocage est testé).
6. Territorial Force et toutes les exigences de T-049 et T-048 : non implémentées.
7. Balance : aucune borne ; les variantes du banc d'essai sont inopérantes (G.1).
8. Performance : aucun test de temps.

### H.3 Performances

| Mesure | Résultat |
|---|---|
| Bataille de 24 à 44 unités (échantillon) | 0,4 à 2,9 s, médiane 1,4 s |
| Lorraine après mobilisation (65 unités, 841 000 hommes) | 5,8 s |
| Repère antérieur (documenté, non remesuré) | 168 unités, environ 20 s |
| Tour mensuel sans bataille (434 unités) | Environ 0,4 s |
| Mobilisation de 4 mois, 7 puissances | 2,3 s |

**Analyse :**
- **Complexité quadratique.** La mise à jour du brouillard compare chaque unité ennemie à chaque unité amie (deux boucles imbriquées). `CombatData.unit_ids()` **retrie** les identifiants à chaque appel, y compris dans la boucle intérieure. Le coût croît donc plus vite que le carré du nombre d'unités (établi par lecture).
- **Taille des batailles.** Après mobilisation, une région peut héberger des dizaines d'unités de 20 000 hommes. Le nombre d'unités au départ d'une bataille n'est pas plafonné ; seuls les renforts le sont (12 par camp).
- **Risque :**
  - **modéré** aujourd'hui, car l'IA ne déclenche presque pas de batailles ;
  - **élevé** dès qu'elle attaquera, ou en multijoueur avec plusieurs batailles simultanées résolues l'une après l'autre. Dix batailles de 65 unités représentent environ une minute de calcul par mois (estimation linéaire, probablement optimiste puisque la croissance est quadratique).
- **Pistes :**
  - mettre en cache la liste triée des unités par pas ;
  - indexer l'espace (grille) pour la détection et la recherche de cible ;
  - éventuellement regrouper les petites unités de réserve.

---

## I. Problèmes classés par priorité

| ID | Priorité | Problème | Fichier ou système | Preuve | Origine probable | Correction proposée | Certitude |
|---|---|---|---|---|---|---|---|
| P0-1 | **P0** | L'IA ne mobilise jamais : asymétrie massive entre humain et IA | `src/ai/nation_agent.gd` | Aucun ordre `mobilize` émis | Mobilisation ajoutée sans volet IA | Règle IA de mobilisation (à la déclaration de guerre ou sous menace), testée | Établi |
| P0-2 | **P0** | Le total allemand (4 806 016) dépasse la source (4 610 000, p. 28) | `military_forces_1914.json` | US WD 1916 p. 9 et p. 28 | Réserves de 1911 ajoutées à l'actif de 1914 | Plafond de la p. 28 ; contrôle analogue pour les sept puissances ; test de cohérence | Établi |
| P1-1 | P1 | T-049 non implémenté (rythme national, influence du joueur, coûts) | `forces_rules.json`, `mobilization_system.gd` | `national_overrides` vide, un seul ordre | Décision postérieure au code | Paramètres nationaux sourcés, ordre de rythme, coûts (après R-03) | Établi |
| P1-2 | P1 | T-050 : la Territorial Force est absente du jeu et de l'interface | Base, scénario, interface | `excluded`, aucune trace dans `src/` | Décision postérieure | Catégorie distincte (E) | Établi |
| P1-3 | P1 | T-048 D : aucun type d'engagement ; pertes de 40 à 90 % systématiques | `tactical_sim.gd`, `combat_rules.json` | Échantillon G.2 | Feu sans plafond de front, durée saturée | G.4, après cibles fixées par le directeur | Établi |
| P1-4 | P1 | Aucune comptabilité nationale des pertes et prisonniers ; services perdus sans trace | `battle_manager.gd`, `mobilization_system.gd` | F | Cinq catégories conçues sans les pertes | Catégorie « pertes, prisonniers et disparus » et invariant de guerre testé | Établi |
| P1-5 | P1 | Réservoir non échelonné : tous les instruits sont appelés | Modèle de mobilisation | D.2 | Définition « tous les instruits » | Échelons sourcés | Établi |
| P1-6 | P1 | Répartition uniforme par corps ; 107 sièges non vérifiés ; deux placements probablement faux (VIe russe, IIe et IIIe ottomans) | Base, `build_scenario.py` | C | Absence de sources par garnison | Vérifier avec les sources de B.3 ; pondérer par effectif réel des corps si sourcé | Établi (uniformité) ; probable (placements) |
| P1-7 | P1 | Comparabilité des réserves douteuse (Allemagne au-dessus de sa source, France en dessous) | Base | B.2 | Tableau p. 9 hétérogène | Grille de composition par catégorie et par nation | Probable |
| P1-8 | P1 | Décisions T-047 à T-050 absentes des registres ; documents encore conditionnels sur la Territorial Force | `docs/decisions/`, `MOBILISATION.md`, base | Recherche dans le dépôt | Décisions récentes | Consigner les décisions | Établi |
| P2-1 | P2 | Réservistes d'un district occupé bloqués indéfiniment ; appel réparti vers des districts déjà occupés | `_call_up`, `_incorporate_ready` | Lecture du code | Cas non spécifié | Règle à définir (perte, report, redirection) | Établi |
| P2-2 | P2 | Mobilisation gratuite et sans effet diplomatique en temps de paix | Ordres, diplomatie | Lecture du code | — | Décision du directeur (K) | Établi |
| P2-3 | P2 | Variantes du banc d'essai inopérantes ; `balance_report` sans assertion | `tests/balance_report.gd` | G.1 | Ordre IA réappliqué | Verrouiller la formation ; tests de bornes | Établi |
| P2-4 | P2 | Performance quadratique ; nombre d'unités au départ non plafonné | `tactical_sim.gd`, `combat_data.gd` | H.3 | — | Cache, index spatial | Établi (complexité) ; probable (impact) |
| P2-5 | P2 | IA stratégique purement défensive : aucune bataille entre IA | `nation_agent.gd` | Sonde : 0 bataille en 6 mois | Niveau 1 | Hors MIL-01, mais rend l'équilibrage non observable | Établi |
| P2-6 | P2 | Réserves russes hors carte au prorata des corps : probablement sous-estimées sur la carte | Base | C.3 | Clé de répartition | Clé sourcée par circonscription | Probable |
| P2-7 | P2 | Fiabilité ottomane surévaluée (« moyenne » pour un blog sans page) | Base | B.1 | — | Abaisser en attendant Erickson 2001 | Établi |
| P2-8 | P2 | Armée de réserve créée dans une région en bataille (non testé) | `_reserve_army` | Lecture du code | — | Test, puis règle | Établi (lecture) |
| P3-1 | P3 | Corps colonial français surdoté (36 277 contre 25 656) ; méthodes différentes pour l'actif et les réserves hors carte de l'Algérie | `build_scenario.py` | C.1 | Parts égales | Pondération par effectif sourcé | Établi |
| P3-2 | P3 | Sièges XV et XVI « vérifiés » au niveau de la province seulement | Base | C.2 | — | Préciser le niveau de vérification | Établi |
| P3-3 | P3 | Effectifs en Libye inconnus ; actif italien sur la carte probablement surévalué | Base | B.1 | — | Recherche (B.3) | Probable |

---

## J. Plan de correction proposé

| Étape | Contenu | Dépend de | Décision humaine |
|---|---|---|---|
| 1 | Consigner T-047 à T-050 ; mettre à jour `MOBILISATION.md` et le statut de la Territorial Force (P1-8) | — | Non |
| 2 | Corrections factuelles de la base : plafond allemand de la p. 28 (P0-2) ; fiabilité ottomane (P2-7) ; niveau de vérification de XV et XVI (P3-2) ; tests de cohérence des totaux par rapport aux sources | — | Non (vérifications documentaires) |
| 3 | Recherche documentaire : sièges (P1-6), échelons de réserve (P1-5), effectifs par corps, Libye, sources ottomanes | Accès aux sources de B.3 | Non |
| 4 | Catégorie des pertes et invariant de guerre (P1-4), avec tests | — | Non (technique) |
| 5 | IA de mobilisation (P0-1) | Étape 4 recommandée ; règle de déclenchement | **Oui** (K-3) |
| 6 | Modèle d'échelons et paramètres nationaux sourcés (P1-5, P1-1) | Étapes 2 et 3 | **Oui** (K-1, K-2) |
| 7 | Territorial Force (P1-2) | Étape 1 ; règles d'emploi | **Oui** (K-4) |
| 8 | Types d'engagement et plafond de front (P1-3), puis étalonnage | Cibles de pertes | **Oui** (K-5) |
| 9 | Banc d'essai d'équilibre avec assertions (P2-3) ; performance (P2-4) | Étape 8 pour les bornes | Non |
| 10 | Cas limites : districts occupés, mobilisation en temps de paix (P2-1, P2-2, P2-8) | — | **Oui** (K-6) |

---

## K. Éléments nécessitant une décision du directeur

1. **K-1. Plafond de mobilisation :** le jeu doit-il permettre d'appeler **tous les instruits** (potentiel théorique), ou seulement l'échelon prévu par les plans de 1914, les classes âgées n'étant accessibles qu'ensuite et sous conditions ?
2. **K-2. Forme de l'influence du joueur (T-049) :** choix entre plusieurs niveaux de rythme, mobilisation partielle ou par région, et nature des coûts (économie, ordre public, diplomatie) alors que R-03 est ouvert.
3. **K-3. Comportement de l'IA :** quand l'IA mobilise-t-elle ? Sur déclaration de guerre, sur mobilisation d'un voisin, ou selon un calendrier historique ?
4. **K-4. Territorial Force :** règle d'emploi (défense intérieure seulement, ou envoi outre-mer progressif par volontariat), délai et qualité.
5. **K-5. Cibles de pertes par type d'engagement (T-048) :** que représente une bataille de 30 minutes, quelles fourchettes viser pour chaque type, et qui choisit le type (attaquant, ordre stratégique, situation) ?
6. **K-6. Mobilisation et diplomatie :**
   - une mobilisation en temps de paix doit-elle avoir un effet diplomatique ou un coût ?
   - que deviennent les réservistes d'un district occupé ?
7. **K-7. Date de départ (R-13, déjà ouverte) :** elle conditionne la situation italienne et ottomane, et le sens d'une mobilisation dès janvier.

---

## Résumé final

1. **Historiquement fiable :**
   - les effectifs britanniques (War Office 1922), Territorial Force comprise ;
   - les actifs des six puissances tirés du document américain, à définition homogène, avec une fiabilité moyenne ;
   - l'absence de troupes allemandes hors du pays ;
   - les forces britanniques et françaises hors carte.
2. **Estimé ou incertain :**
   - toutes les réserves sauf britanniques (estimations de 1911, comparabilité douteuse, Allemagne au-dessus de sa propre source) ;
   - toute la répartition régionale (parts égales, 107 sièges sur 113 non vérifiés, deux placements probablement faux) ;
   - les parts hors carte russe et ottomane ;
   - les données ottomanes ;
   - la Libye.
3. **Problèmes techniques :**
   - l'IA ne mobilise jamais ;
   - aucune comptabilité des pertes ;
   - T-048, T-049 et T-050 non implémentés ;
   - réservistes bloqués indéfiniment ;
   - banc d'essai d'équilibre inopérant pour une variante ;
   - coût de calcul quadratique.
   - **Aucune erreur de conservation ni de double comptage n'a été trouvée.**
4. **Corrections les plus urgentes :**
   - P0-1, l'IA de mobilisation (après la décision K-3) ;
   - P0-2, le plafond allemand de la p. 28 (correction factuelle) ;
   - puis l'enregistrement des décisions T-047 à T-050 et la comptabilité des pertes.
5. **Décisions humaines :** K-1 à K-7 ci-dessus.

---

## Annexe : méthode et sources de l'audit

**Exécutions** (sur ce poste, Godot 4.7.2, 15/11/2026) :
- `bash tests/run.sh` : 54 sur 54, interfaces validées.
- `godot --headless --path . --script tests/balance_report.gd` : résultats identiques au rapport précédent.
- Sonde d'audit hors dépôt (`audit_probe.gd`, dossier temporaire de session, **non versionnée**), qui produit :
  - l'échantillon des 36 paires frontalières (effectifs historiques, puis égalisés) ;
  - six tours mensuels IA contre IA avec guerre entre blocs : 0 bataille, environ 0,4 s par tour.
  - Elle appelle uniquement des fonctions publiques du jeu, sur des états en mémoire.
- `gh run view 43718120689` : conclusion `success`, commit `a46d8e9`.
- Localisation de Białystok, Edirne, Tekirdağ et Kırklareli dans les régions du jeu : mêmes polygones (EPSG:3035) que `build_scenario.py`.

**Sources relues :**
- US War Department, *Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan*, 1916 : texte intégral archive.org `strengthorganiza00unit`, p. 9, 15, 20, 28, 37-39, 45-46, 63-67.
- War Office, *Statistics of the Military Effort of the British Empire during the Great War*, HMSO, 1922, p. 30 (d'après la base ; tableau déjà vérifié sur le fac-similé lors de MIL-01).

**Sources secondaires consultées en ligne (indices seulement, non probants) :**
- [6th Army Corps (Russian Empire) — Wikipedia](https://en.wikipedia.org/wiki/6th_Army_Corps_(Russian_Empire)) : Łomża jusqu'en 1909, puis Białystok.
- [Warsaw Military District (Russian Empire) — Wikipedia](https://en.wikipedia.com/wiki/Warsaw_Military_District_(Russian_Empire)) : Łomża, sans date.
- [II Corps (Ottoman Empire) — Wikipedia](https://en.wikipedia.org/wiki/II_Corps_(Ottoman_Empire)), [III Corps (Ottoman Empire) — Wikipedia](https://en.wikipedia.org/wiki/III_Corps_(Ottoman_Empire)), [First Army (Ottoman Empire) — Wikipedia](https://EN.wikipedia.com/wiki/First_Army_(Ottoman_Empire)) : garnisons en Thrace, versions divergentes.

**Source primaire repérée mais inexploitable :** War Office, *Handbook of the German Army*, 1912/1914, archive.org `hndbk-german-army-1914`. L'OCR est trop dégradé pour la liste des sièges ; il faut consulter le fac-similé.
