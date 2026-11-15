# Autriche-Hongrie — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (ventilation par arme partielle, répartition estimée)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **472 715** |
| Date de référence | 1914 |
| Définition | Armée commune + Landwehr autrichienne + Honvéd hongroise + troupes bosniaques : 34 069 officiers (dont certains fonctionnaires assimilés) et 438 646 hommes. |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 37 (« The total peace strength is 34,069 officers [...] and 438,646 men ») et p. 38-39 (détail : total 472 716) |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | moyenne |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 370 725 | `US_WD_1916` | p. 9 | Armée commune seule (« Common army only ») | Périmètre plus étroit : non retenu comme actif total. |
| 472 716 | `US_WD_1916` | p. 38-39 | Somme détaillée « Peace strength, 1914 » (armée commune 370 725 ; Landwehr autrichienne 55 191 ; Honvéd 42 800 ; Bosniaques 8 000) | Écart d'une unité avec 34 069 + 438 646. |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **2 000 000** |
| Date de référence | estimation publiée en 1916 |
| Définition | Hommes entièrement instruits rappelables (« fully trained men subject to call ») |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 37-38 |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible |
| Justification du choix | 2 000 000 : seul chiffre couvrant toute la monarchie avec la définition « entièrement instruits » ; le document qualifie les données de la Landwehr de « little more than an incomplete guess » (p. 38). |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 1 600 000 | `US_WD_1916` | p. 9 | Réserves instruites, armée commune seule (« Figures are approximate ») |  |
| 4 320 000 | `US_WD_1916` | p. 38-39 | Effectif de guerre total approximatif, Landsturm (2 000 000) et réserve d'ersatz (500 000) compris | Inclut des catégories peu ou pas instruites. |

Part des réserves sur la carte : 1/1 — Tous les districts sont sur la carte.

### Ventilation par arme

Source : `US_WD_1916` p. 9 ; périmètre : armée commune seule

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 196 957 | 47 151 | 37 069 | 9 934 | **inconnu** | 12 994 | 4 914 | 2 933 | 370 725 |

Ventilation connue pour l'armée commune seulement ; ses proportions sont appliquées à toute l'armée active (ESTIMATION).

### Forces hors de la carte

**0** (constat géographique) — Les sièges des XVe (Sarajevo) et XVIe (Raguse) corps sont dans la région 043 du jeu ; aucune troupe active hors de la carte n'est identifiée.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 16 — US_WD_1916 p. 34 (« In the common army there are 16 army corps with 33 divisions »)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Ier corps | Cracovie | à vérifier | region_040 (Galicie et Bucovine) |
| IIe corps | Vienne | à vérifier | region_036 (Autriche centrale) |
| IIIe corps | Graz | à vérifier | region_036 (Autriche centrale) |
| IVe corps | Budapest | à vérifier | region_041 (Hongrie et Slovaquie) |
| Ve corps | Pozsony (Presbourg) | à vérifier | region_041 (Hongrie et Slovaquie) |
| VIe corps | Kassa (Kaschau) | à vérifier | region_041 (Hongrie et Slovaquie) |
| VIIe corps | Temesvár | à vérifier | region_041 (Hongrie et Slovaquie) |
| VIIIe corps | Prague | à vérifier | region_038 (Bohême) |
| IXe corps | Leitmeritz | à vérifier | region_038 (Bohême) |
| Xe corps | Przemyśl | à vérifier | region_040 (Galicie et Bucovine) |
| XIe corps | Lemberg | à vérifier | region_040 (Galicie et Bucovine) |
| XIIe corps | Hermannstadt | à vérifier | region_042 (Transylvanie) |
| XIIIe corps | Agram (Zagreb) | à vérifier | region_043 (Croatie et territoires méridionaux) |
| XIVe corps | Innsbruck | à vérifier | region_037 (Alpes autrichiennes) |
| XVe corps | Sarajevo | à vérifier | region_043 (Croatie et territoires méridionaux) |
| XVIe corps | Raguse (Dubrovnik) | à vérifier | region_043 (Croatie et territoires méridionaux) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 472 715 ; sur la carte : 472 715 (unités combattantes 371 195 + services 101 520).
- Réserves sur la carte (non incorporées) : 2 000 000 ; hors carte : 0.
- Unités : 64.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_036 (Autriche centrale) | 31 392 | 7 516 | 7 492 |
| region_037 (Alpes autrichiennes) | 15 696 | 3 757 | 3 746 |
| region_038 (Bohême) | 31 392 | 7 516 | 7 492 |
| region_040 (Galicie et Bucovine) | 47 088 | 11 274 | 11 238 |
| region_041 (Hongrie et Slovaquie) | 62 784 | 15 032 | 14 984 |
| region_042 (Transylvanie) | 15 696 | 3 757 | 3 746 |
| region_043 (Croatie et territoires méridionaux) | 47 088 | 11 271 | 11 238 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
