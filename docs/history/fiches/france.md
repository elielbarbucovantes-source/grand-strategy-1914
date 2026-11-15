# France — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (répartition estimée)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **844 188** |
| Date de référence | budget 1914 |
| Définition | Armée métropolitaine (Algérie et Tunisie comprises, gendarmerie et garde républicaine comprises) : 818 532 ; plus les troupes coloniales stationnées en France : 2 083 officiers + 23 573 hommes = 25 656. |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (818 532) et p. 20 (« Of these, 26,368 officers and 709,796 men are stationed in France. There are, in addition, 2,083 officers and 23,573 men of the colonial army stationed in France ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | moyenne |
| Calcul | 818 532 + 25 656 = 844 188 |
| Justification du choix | Total du tableau p. 9 (même définition que les autres puissances) complété par les troupes coloniales stationnées en France, présentes sur la carte. Les écarts internes du document (de 712 000 à 818 532) tiennent au périmètre (gendarmerie, Afrique du Nord, classe supplémentaire) : divergence conservée. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 736 000 | `US_WD_1916` | p. 9, note 1 | « Budget estimates metropolitan army, 1914, 736,000 » |  |
| 792 423 | `US_WD_1916` | p. 15 | « Peace strength » rapporté à la population |  |
| 712 000 | `US_WD_1916` | p. 15, note 2 | « Peace strength Metropolitan Army, 712,000, including an extra class of about 200,000 men » |  |
| 620 420 | `US_WD_1916` | p. 15 (tableau « Peace establishment and approximate war strength ») | Effectif du temps de paix, gendarmerie (21 998) et garde républicaine (2 993) comprises | Périmètre et date de compilation différents ; illustre la dispersion interne du document (620 420 à 818 532). |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **2 300 000** |
| Date de référence | estimation de 1911 publiée en 1916 |
| Définition | Réservistes entièrement instruits disponibles pour le passage au pied de guerre |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (second tableau) |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible à moyenne |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 3 800 000 | `US_WD_1916` | p. 20 | « sum total of trained men which she is able to mobilize amounts to about 3,800,000 men » (actifs compris) |  |
| 2 869 000 | `US_WD_1916` | p. 15, note 3 | Réserves et dépôts 1 600 000 + armée territoriale 818 000 + réserve de la territoriale 451 000 (total de guerre 3 878 000 moins l'actif 1 009 000) | Inclut l'armée territoriale (classes âgées) ; le tableau p. 9 retient 2,3 M. |
| 5 500 000 | `US_WD_1916` | p. 15 | « About 5,500,000 men have had military training (Veltze) » (ressources totales, guerre défensive) | Non retenu : inclut toutes les classes instruites. |

Part des réserves sur la carte : 21/22 — ESTIMATION : 21 des 22 districts (corps territoriaux et colonial) sont sur la carte ; le 19e corps (Algérie) est hors carte.

### Ventilation par arme

Source : `US_WD_1916` p. 9

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 509 456 | 81 556 | 118 302 | 4 446 | 7 246 | 27 866 | 11 202 | 6 123 | 818 532 |

Ventilation de l'armée métropolitaine seule (818 532) ; appliquée en proportion aux 25 656 coloniaux stationnés en France (estimation).

### Forces hors de la carte

**82 368** (dérivé d'une source) — 818 532 − (26 368 + 709 796) stationnés en France = 82 368 en Algérie et Tunisie (US_WD_1916, p. 20). Les ~87 000 troupes coloniales outre-mer (p. 21) sont hors du périmètre « actif ».

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 22 — US_WD_1916 p. 15 (« 20 army corps organized in peace. In addition there is one colonial army corps ») et p. 22 (21 corps dont un en Algérie) : 20 métropolitains numérotés 1 à 18, 20 et 21, plus le 19e en Algérie, plus le corps colonial.

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| 1er corps | Lille | à vérifier | region_007 (France — Nord) |
| 2e corps | Amiens | à vérifier | region_007 (France — Nord) |
| 3e corps | Rouen | à vérifier | region_008 (France — Bassin parisien) |
| 4e corps | Le Mans | à vérifier | region_009 (France — Ouest) |
| 5e corps | Orléans | à vérifier | region_008 (France — Bassin parisien) |
| 6e corps | Châlons-sur-Marne | à vérifier | region_011 (France — Est) |
| 7e corps | Besançon | à vérifier | region_011 (France — Est) |
| 8e corps | Bourges | à vérifier | region_008 (France — Bassin parisien) |
| 9e corps | Tours | à vérifier | region_008 (France — Bassin parisien) |
| 10e corps | Rennes | à vérifier | region_009 (France — Ouest) |
| 11e corps | Nantes | à vérifier | region_009 (France — Ouest) |
| 12e corps | Limoges | à vérifier | region_010 (France — Sud-Ouest) |
| 13e corps | Clermont-Ferrand | à vérifier | region_012 (France — Sud-Est) |
| 14e corps | Lyon | à vérifier | region_012 (France — Sud-Est) |
| 15e corps | Marseille | à vérifier | region_012 (France — Sud-Est) |
| 16e corps | Montpellier | à vérifier | region_012 (France — Sud-Est) |
| 17e corps | Toulouse | à vérifier | region_010 (France — Sud-Ouest) |
| 18e corps | Bordeaux | à vérifier | region_010 (France — Sud-Ouest) |
| 20e corps | Nancy | à vérifier | region_011 (France — Est) |
| 21e corps | Épinal | à vérifier | region_011 (France — Est) |
| Corps d'armée colonial (stationné en France) | Paris | à vérifier | region_008 (France — Bassin parisien) |
| 19e corps (Algérie) | Alger | à vérifier | hors carte |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 844 188 ; sur la carte : 761 820 (unités combattantes 671 058 + services 90 762).
- Réserves sur la carte (non incorporées) : 2 195 454 ; hors carte : 104 546.
- Unités : 84.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_007 (France — Nord) | 45 160 | 7 230 | 11 522 |
| region_008 (France — Bassin parisien) | 112 896 | 18 075 | 28 805 |
| region_009 (France — Ouest) | 67 737 | 10 845 | 17 283 |
| region_010 (France — Sud-Ouest) | 67 737 | 10 845 | 17 283 |
| region_011 (France — Est) | 90 316 | 14 460 | 23 044 |
| region_012 (France — Sud-Est) | 90 316 | 14 460 | 23 044 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
