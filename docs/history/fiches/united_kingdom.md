# Royaume-Uni — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (répartition intérieure estimée)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **247 432** |
| Date de référence | 1er août 1914 |
| Définition | Armée régulière (« Regular Army ») : 10 800 officiers et 236 632 hommes, état-major, services et établissements divers compris ; troupes indigènes de l'armée des Indes exclues. |
| Source | `WO_1922` — War Office, Statistics of the Military Effort of the British Empire during the Great War, 1914-1920. Londres, HMSO, mars 1922. |
| Page / passage | p. 30, tableau (i)(b) ; détail p. 156-157 |
| Lien | https://archive.org/details/statisticsofmili00grea |
| Fiabilité | haute |
| Justification du choix | WO_1922 : statistique officielle nationale à la date du 1er août 1914 ; même définition (armée régulière sous les drapeaux). |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 255 438 | `US_WD_1916` | p. 9 | Armée régulière seule | +3 % ; date et périmètre (états-majors) légèrement différents. |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **209 280** |
| Date de référence | 1er août 1914 |
| Définition | Army Reserve (145 347) + Special Reserve (63 933) : anciens soldats et réservistes rappelés à la mobilisation pour compléter et alimenter l'armée régulière. |
| Source | `WO_1922` — War Office, Statistics of the Military Effort of the British Empire during the Great War, 1914-1920. Londres, HMSO, mars 1922. |
| Page / passage | p. 30, tableau (i)(b) |
| Lien | https://archive.org/details/statisticsofmili00grea |
| Fiabilité | haute |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 215 000 | `US_WD_1916` | p. 9 | Réserves instruites (« Regulars only ») |  |

- Exclu : **Territorial Force** (268 777, WO_1922 p. 30) : Catégorie militaire DISTINCTE (T-050, VALIDÉ) : non comptée dans le réservoir ; voir le bloc `territorial_force`.
- Exclu : **National Reserve (1er octobre 1913)** (215 451, WO_1922 p. 30) : Registre d'anciens soldats sans obligation de rappel.

Part des réserves sur la carte : 1/1 — Les réservistes (Army Reserve, Special Reserve) sont rappelés au Royaume-Uni ; les garnisons d'Inde et des colonies ne concernent que l'armée active.

**Contrôle de cohérence avec la source :** Réservoir = Army Reserve 145 347 + Special Reserve 63 933 (lignes du tableau du 1er août 1914). Contrôle : la valeur égale exactement la somme des deux lignes (testé).

### Échelons de mobilisation (T-051)

T-051 (VALIDÉ) : mobilisation par échelons historiquement documentés. Un échelon sans donnée fiable vaut null (« introuvable ») ; aucun total n'est réparti arbitrairement. Données de phase 1 : le moteur ne les utilise pas encore (phase 2).

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|
| Premier échelon : rappel des réserves de l'armée régulière | ****inconnu**** | introuvable | — | Les effectifs sont sourcés (Army Reserve 145 347, Special Reserve 63 933 au 1er août 1914, WO_1922 p. 30), mais aucune source consultée ne dit quelle part était appelée par le plan de 1914. Le rappel intégral est probable, mais il n'est pas documenté ici. La Territorial Force relève d'une catégorie distincte (T-050), voir `territorial_force`. |
| Échelons suivants | ****inconnu**** | introuvable | — | Même lacune documentaire. |
| Réserves résiduelles | ****inconnu**** | introuvable | — | La National Reserve (215 451) est un registre sans obligation de rappel : exclue (WO_1922 p. 30). |

**Appel en bloc unique (approximation non documentée, décision MIL01-P1-D1) :** 209 280. Décision MIL01-P1-D1 (15/11/2026) : en l'absence d'échelon documenté, le réservoir peut être appelé EN BLOC UNIQUE. C'est une APPROXIMATION NON DOCUMENTÉE HISTORIQUEMENT (ni le volume ni le rythme d'un premier échelon ne sont connus) ; aucun sous-échelon n'est inventé.

### Territorial Force (catégorie distincte, T-050 et T-054)

T-050 et T-054 (VALIDÉS) : catégorie distincte, d'abord défense intérieure, déploiement outre-mer volontaire. Données de phase 1 : le moteur ne l'utilise pas encore (phase 4).

| Champ | Contenu |
|---|---|
| Effectif réel | **268 777** |
| Date | 1er août 1914 |
| Définition | Effectif réel (strength) de la Territorial Force au 1er août 1914 : 10 684 officiers et 258 093 hommes, personnel permanent compris. |
| Source | `WO_1922` — War Office, Statistics of the Military Effort of the British Empire during the Great War, 1914-1920. Londres, HMSO, mars 1922. |
| Page | p. 30, tableau (i)(b), note † « Includes permanent staff of the Territorial Force » |
| Effectif théorique | 316 094 (Effectif théorique (establishment) à la même date : 12 700 officiers et 303 394 hommes) |
| Double comptage | Le total du tableau (733 514) est la somme exacte des sept lignes, dont l'armée régulière (247 432), l'Army Reserve, la Special Reserve et la Territorial Force (268 777) : la source les traite comme des catégories disjointes. La présence éventuelle du personnel permanent (militaires de carrière) aussi dans la ligne « Regular Army » n'est pas tranchée par cette page ; le total additif indique que non (PROBABLE). |
| Emploi | Service intérieur au départ ; envoi outre-mer seulement par engagement volontaire (T-054). Pistes de source pour les délais : WO_1922 Section 8 (Territorial Force servant à l'étranger, par mois) et Section 2a (engagements volontaires) — non exploitées en phase 1. |

- Non inclus : **Territorial Force Reserve** (2 082, p. 30) : Ligne distincte du même tableau ; non incluse.
- Divergence : 315 408 (`US_WD_1916` p. 9, note 4) — « Territorial force, British Isles, numbers 315,408 » (date non précisée) Proche de l'effectif théorique (316 094) et non de l'effectif réel ; date et définition non précisées : non retenu.

### Ventilation par arme

Source : `US_WD_1916` p. 9

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 151 261 | 20 716 | 34 694 | 628 | 14 965 | 9 096 | 6 772 | 5 069 | 255 438 |

Proportions du document américain appliquées à l'effectif WO_1922 (ESTIMATION de ventilation).

### Forces hors de la carte

**121 123** (sourcé) — WO_1922 p. 157 (Section 10, « Strength, 1st August, 1914 ») : Inde 75 000 ; colonies et Égypte 43 486 ; postes divers et dépôts 2 637 (247 432 − 126 309 au Royaume-Uni − 75 000 − 43 486). Métropole : 126 309.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 8 — US_WD_1916 p. 60 : commandements « Aldershot, south, east, north, west, Scotland, Ireland, and London ».

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Commandement d'Aldershot | Aldershot | vérifié (US_WD_1916 p. 60 (« Aldershot is the station of the expeditionary force »)) | region_001 (Angleterre du Sud) |
| Commandement du Sud | Salisbury | à vérifier | region_001 (Angleterre du Sud) |
| Commandement de l'Est | Londres | à vérifier | region_001 (Angleterre du Sud) |
| District de Londres | Londres | à vérifier | region_001 (Angleterre du Sud) |
| Commandement du Nord | York | à vérifier | region_002 (Angleterre du Nord) |
| Commandement de l'Ouest | Chester | à vérifier | region_002 (Angleterre du Nord) |
| Commandement d'Écosse | Édimbourg | à vérifier | region_003 (Écosse) |
| Commandement d'Irlande | Dublin | à vérifier | region_006 (Irlande hors Ulster) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 247 432 ; sur la carte : 126 309 (unités combattantes 109 904 + services 16 405).
- Réserves sur la carte (non incorporées) : 209 280 ; hors carte : 0.
- Unités : 24.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_001 (Angleterre du Sud) | 37 400 | 5 120 | 12 432 |
| region_002 (Angleterre du Nord) | 18 699 | 2 561 | 6 216 |
| region_003 (Écosse) | 9 349 | 1 281 | 3 108 |
| region_006 (Irlande hors Ulster) | 9 349 | 1 281 | 3 108 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
