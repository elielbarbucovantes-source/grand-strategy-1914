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

- Exclu : **Territorial Force** (268 777, WO_1922 p. 30) : Force volontaire à temps partiel de défense intérieure, distincte des réserves de l'armée régulière ; non comptée dans le réservoir (catégorie à modéliser si le directeur le décide).
- Exclu : **National Reserve (1er octobre 1913)** (215 451, WO_1922 p. 30) : Registre d'anciens soldats sans obligation de rappel.

Part des réserves sur la carte : 1/1 — Les réservistes (Army Reserve, Special Reserve) sont rappelés au Royaume-Uni ; les garnisons d'Inde et des colonies ne concernent que l'armée active.

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
