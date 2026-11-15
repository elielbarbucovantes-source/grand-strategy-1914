# Empire allemand — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (répartition estimée)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **806 016** |
| Date de référence | 1914 (« conditions in July, 1914 ») |
| Définition | Effectif total du temps de paix, officiers et hommes sous les drapeaux ; hors volontaires d'un an (10 000 à 12 000 selon la source) et hors troupes coloniales. |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (tableau) et p. 28 (« The total peace strength amounts to 806,016 officers and men ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | moyenne |
| Justification du choix | US_WD_1916, pour l'homogénéité avec les autres puissances. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 734 000 | `BUNDESARCHIV` | — | « Juli 1914 734.000 Mann » (armée prussienne ; périmètre non précisé) | Inférieur de 9 % ; périmètre probablement plus étroit. |
| 800 000 | `US_WD_1916` | p. 29-30 | Arrondi utilisé dans le même document (« Peace strength, 31,459 officers; 768,540 noncommissioned officers and men, approximately » = 799 999) | Incohérence interne mineure du document (0,8 %). |
| 661 176 | `BERNHARDI_1914` | — | Hommes du rang (Gemeine) prévus par la loi de 1913, sans officiers ni sous-officiers | Définition différente : non comparable. |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **4 000 000** |
| Date de référence | estimation de 1911 publiée en 1916 |
| Définition | Réservistes entièrement instruits disponibles pour le passage au pied de guerre |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (second tableau) |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible à moyenne |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 4 610 000 | `US_WD_1916` | p. 28 | « sum total of trained men which she is able to mobilize » (actifs compris) |  |
| 3 800 000 | `BUNDESARCHIV` | — | « August 1914 3,8 Mio. Mann mobil gemacht » (actifs compris) | Contrôle : 3,8 M mobilisés − 0,8 M actifs ≈ 3,0 M réservistes effectivement rappelés en août 1914, inférieur au réservoir de 4,0 M : cohérent. |

Part des réserves sur la carte : 1/1 — Aucun district hors carte (US_WD_1916 p. 28).

### Ventilation par arme

Source : `US_WD_1916` p. 9

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 507 231 | 85 792 | 91 368 | 38 357 | **inconnu** | 30 403 | 12 600 | 6 615 | 806 016 |

Artillerie côtière « (?) » dans la source (en partie tenue par la marine).

### Forces hors de la carte

**0** (sourcé) — « No German troops of the army proper serve outside the home country in time of peace » (US_WD_1916, p. 28).

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 25 — US_WD_1916 p. 30 (« Germany has at present 25 ») ; WO_HANDBOOK_DE_1914 (« there are 25 Army-Corps in all »)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Corps de la Garde | Berlin | vérifié (WO_HANDBOOK_DE_1914 (« The Prussian Guard Corps is stationed in Berlin »)) | region_028 (Poméranie, Mecklembourg et Brandebourg) |
| Ier corps | Königsberg | à vérifier | region_026 (Prusse-Orientale) |
| IIe corps | Stettin | à vérifier | region_028 (Poméranie, Mecklembourg et Brandebourg) |
| IIIe corps | Berlin | à vérifier | region_028 (Poméranie, Mecklembourg et Brandebourg) |
| IVe corps | Magdebourg | à vérifier | region_031 (Saxe et Thuringe) |
| Ve corps | Posen | à vérifier | region_027 (Prusse-Occidentale et Posnanie) |
| VIe corps | Breslau | à vérifier | region_030 (Silésie) |
| VIIe corps | Münster | à vérifier | region_032 (Rhénanie-Westphalie) |
| VIIIe corps | Coblence | à vérifier | region_032 (Rhénanie-Westphalie) |
| IXe corps | Altona | à vérifier | region_029 (Allemagne du Nord-Ouest) |
| Xe corps | Hanovre | à vérifier | region_029 (Allemagne du Nord-Ouest) |
| XIe corps | Cassel | à vérifier | region_033 (Allemagne du Sud-Ouest) |
| XIIe corps (1er saxon) | Dresde | à vérifier | region_031 (Saxe et Thuringe) |
| XIIIe corps (wurtembergeois) | Stuttgart | à vérifier | region_033 (Allemagne du Sud-Ouest) |
| XIVe corps (badois) | Karlsruhe | à vérifier | region_033 (Allemagne du Sud-Ouest) |
| XVe corps | Strasbourg | vérifié (WO_HANDBOOK_DE_1914 (XVe et XVIe corps « stationed in Alsace-Lorraine »)) | region_035 (Alsace-Lorraine) |
| XVIe corps | Metz | vérifié (WO_HANDBOOK_DE_1914 (XVe et XVIe corps « stationed in Alsace-Lorraine »)) | region_035 (Alsace-Lorraine) |
| XVIIe corps | Dantzig | à vérifier | region_027 (Prusse-Occidentale et Posnanie) |
| XVIIIe corps | Francfort-sur-le-Main | à vérifier | region_033 (Allemagne du Sud-Ouest) |
| XIXe corps (2e saxon) | Leipzig | à vérifier | region_031 (Saxe et Thuringe) |
| XXe corps | Allenstein | vérifié (BERNHARDI_1914 (« Das 20. Korps wurde in Allenstein [...] errichtet »)) | region_026 (Prusse-Orientale) |
| XXIe corps | Sarrebruck | vérifié (BERNHARDI_1914 (« das 21. in Saarbrücken errichtet »)) | region_032 (Rhénanie-Westphalie) |
| Ier corps bavarois | Munich | à vérifier | region_034 (Bavière) |
| IIe corps bavarois | Wurtzbourg | à vérifier | region_034 (Bavière) |
| IIIe corps bavarois | Nuremberg | à vérifier | region_034 (Bavière) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 806 016 ; sur la carte : 806 016 (unités combattantes 722 741 + services 83 275).
- Réserves sur la carte (non incorporées) : 4 000 000 ; hors carte : 0.
- Unités : 100.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_026 (Prusse-Orientale) | 40 578 | 6 863 | 10 378 |
| region_027 (Prusse-Occidentale et Posnanie) | 40 578 | 6 863 | 10 378 |
| region_028 (Poméranie, Mecklembourg et Brandebourg) | 60 867 | 10 296 | 15 567 |
| region_029 (Allemagne du Nord-Ouest) | 40 578 | 6 864 | 10 378 |
| region_030 (Silésie) | 20 289 | 3 432 | 5 189 |
| region_031 (Saxe et Thuringe) | 60 867 | 10 295 | 15 567 |
| region_032 (Rhénanie-Westphalie) | 60 867 | 10 295 | 15 567 |
| region_033 (Allemagne du Sud-Ouest) | 81 156 | 13 727 | 20 756 |
| region_034 (Bavière) | 60 867 | 10 293 | 15 567 |
| region_035 (Alsace-Lorraine) | 40 578 | 6 863 | 10 378 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
