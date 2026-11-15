# Italie — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (répartition estimée ; troupes d'Afrique exclues)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **305 033** |
| Date de référence | 1914 |
| Définition | Armée régulière, effectif budgétaire, hors troupes d'Afrique |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (« Exclusive of troops in Africa ») et p. 66 (« The total peace strength of the regular army is 305,000 ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible à moyenne |
| Remarque | Le document précise que l'effectif présent est toujours inférieur de « several thousand » au budget (congés illimités, p. 63). |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 250 860 | `US_WD_1916` | p. 67 | « Peace strength » rapporté à la population (budget de 1912) | Année et définition différentes. |
| 252 340 | `US_WD_1916` | p. 67 (tableau, budget de 1912) | « Peace » (budget strength, 1912) |  |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **994 967** |
| Date de référence | non précisée ; document daté « conditions in July, 1914 » |
| Définition | Instruits mobilisables hors armée active : estimation prudente des hommes entièrement instruits (rubrique « TOTAL WAR STRENGTH »), moins l'armée active. |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 66 (« A conservative estimate would seem to be 1,300,000 fully trained men ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible |
| Calcul | 1 300 000 (instruits, actifs compris) − 305 033 (armée active, p. 9) = 994 967. |
| Remarque | Correction de phase 1 (15/11/2026), même règle que pour l'Allemagne : le total des instruits de la rubrique « Total war strength » est lu comme incluant l'armée active (PROBABLE). L'ancienne valeur (1 250 000, tableau p. 9 de 1911) donnait un total de 1 555 033, supérieur au total p. 66. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 1 250 000 | `US_WD_1916` | p. 9 (second tableau) | « Fully trained reserves available for passing from peace to war footing », estimation de 1911 | Valeur retenue jusqu'au 15/11/2026 ; abandonnée car actif + réserves dépassait le total p. 66. |
| 3 500 000 | `US_WD_1916` | p. 66 | « On paper she could mobilize 3,500,000 men » | Théorique, non retenu. |

Part des réserves sur la carte : 1/1 — Tous les districts sont sur la carte.

**Contrôle de cohérence avec la source :** total des instruits, actifs compris : 1 300 000 (`US_WD_1916` p. 66) ; actif + réserves = 1 300 000. « A conservative estimate would seem to be 1,300,000 fully trained men » (rubrique « Total war strength ») Contrôle de phase 1 : armée active + réserves ≤ ce total (testé par test_forces_mil01.gd).

### Échelons de mobilisation (T-051)

T-051 (VALIDÉ) : mobilisation par échelons historiquement documentés. Un échelon sans donnée fiable vaut null (« introuvable ») ; aucun total n'est réparti arbitrairement. Données de phase 1 : le moteur ne les utilise pas encore (phase 2).

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|
| Premier échelon : appel prévu par le plan de mobilisation de 1914 | ****inconnu**** | introuvable | — | Source attendue : Ufficio Storico, L'Esercito italiano nella Grande Guerra, vol. I (non consulté). US_WD_1916 p. 66 ne donne que le total des instruits. |
| Échelons suivants | ****inconnu**** | introuvable | — | Même lacune documentaire. |
| Réserves résiduelles | ****inconnu**** | introuvable | — | « On paper she could mobilize 3,500,000 men » (p. 66) : total théorique incluant des non-instruits ; non utilisable. |

### Ventilation par arme

Source : `US_WD_1916` p. 9

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 193 514 | 27 410 | 41 493 | 7 000 | 5 000 | 15 836 | 5 940 | 5 666 | 305 033 |

### Forces hors de la carte

**0** (partiel) — L'effectif retenu exclut déjà les troupes d'Afrique (US_WD_1916 p. 9, note 5 ; 132 officiers et 4 530 hommes de troupes coloniales, p. 66). Les forces métropolitaines détachées en Libye en 1914 ne sont pas chiffrées par la source : INCONNU.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 12 — US_WD_1916 p. 63 (« There are 12 army corps, 25 divisions, and 3 cavalry divisions organized in peace »).

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Ier corps | Turin | à vérifier | region_080 (Italie — Nord-Ouest) |
| IIe corps | Alexandrie | à vérifier | region_080 (Italie — Nord-Ouest) |
| IIIe corps | Milan | à vérifier | region_080 (Italie — Nord-Ouest) |
| IVe corps | Gênes | à vérifier | region_080 (Italie — Nord-Ouest) |
| Ve corps | Vérone | à vérifier | region_081 (Italie — Nord-Est) |
| VIe corps | Bologne | à vérifier | region_081 (Italie — Nord-Est) |
| VIIe corps | Ancône | à vérifier | region_083 (Italie — Centre-Est) |
| VIIIe corps | Florence | à vérifier | region_082 (Italie — Centre-Ouest) |
| IXe corps | Rome | à vérifier | region_082 (Italie — Centre-Ouest) |
| Xe corps | Naples | à vérifier | region_084 (Italie — Sud) |
| XIe corps | Bari | à vérifier | region_084 (Italie — Sud) |
| XIIe corps | Palerme | à vérifier | region_085 (Sicile) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 305 033 ; sur la carte : 305 033 (unités combattantes 274 421 + services 30 612).
- Réserves sur la carte (non incorporées) : 994 967 ; hors carte : 0.
- Unités : 48.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_080 (Italie — Nord-Ouest) | 64 508 | 9 136 | 17 832 |
| region_081 (Italie — Nord-Est) | 32 253 | 4 568 | 8 916 |
| region_082 (Italie — Centre-Ouest) | 32 252 | 4 568 | 8 916 |
| region_083 (Italie — Centre-Est) | 16 126 | 2 284 | 4 458 |
| region_084 (Italie — Sud) | 32 252 | 4 568 | 8 916 |
| region_085 (Sicile) | 16 126 | 2 284 | 4 458 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
