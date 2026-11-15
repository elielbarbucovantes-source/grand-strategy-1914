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
| Valeur retenue | **3 803 984** |
| Date de référence | non précisée ; document daté « conditions in July, 1914 » |
| Définition | Instruits mobilisables hors armée active : total des hommes instruits que l'Allemagne peut mobiliser (rubrique « TOTAL WAR STRENGTH »), moins l'armée active. |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 28 (« The sum total of trained men which she is able to mobilize amounts to 4,610,000 ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible à moyenne |
| Calcul | 4 610 000 (total des instruits, actifs compris) − 806 016 (armée active, même document p. 28) = 3 803 984. |
| Remarque | Correction de phase 1 (15/11/2026, audit MIL-01 P0-2). La lecture « actifs compris » est PROBABLE, non certaine : le chiffre figure sous la rubrique « Total war strength » (effectif de guerre, donc armée active comprise), mais la phrase ne le dit pas explicitement. L'ancienne valeur (4 000 000, tableau p. 9 de 1911) donnait un total de 4 806 016, supérieur au total du même document. Plafond CONSERVÉ PROVISOIREMENT par décision du directeur (MIL01-P1-D2, 15/11/2026) : le total inclut PROBABLEMENT l'armée active ; cette lecture n'est pas établie. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 4 000 000 | `US_WD_1916` | p. 9 (second tableau) | « Fully trained reserves available for passing from peace to war footing », estimation de 1911 | Valeur retenue jusqu'au 15/11/2026 ; abandonnée car actif + réserves dépassait le total p. 28. |
| 3 200 000 | `US_WD_1916` | p. 29 | Estimation de 1913 citée par le document : « real military resources, 7,000,000 men, of whom 4,000,000 have had military training » ; 4 000 000 − 800 000 actifs (même passage) ≈ 3 200 000 | Autre estimation du même document, plus basse ; non retenue (estimation de 1913, chiffres ronds). |
| 3 800 000 | `BUNDESARCHIV` | — | « August 1914 3,8 Mio. Mann mobil gemacht » (actifs compris) | Contrôle : 3,8 M mobilisés en août 1914, actifs compris ; voir le premier échelon (mobilization_echelons). |

Part des réserves sur la carte : 1/1 — Aucun district hors carte (US_WD_1916 p. 28).

**Contrôle de cohérence avec la source :** total des instruits, actifs compris : 4 610 000 (`US_WD_1916` p. 28) ; actif + réserves = 4 610 000. « The sum total of trained men which she is able to mobilize amounts to 4,610,000 » (rubrique « Total war strength ») ; lecture « actifs compris » PROBABLE Contrôle de phase 1 : armée active + réserves ≤ ce total (testé par test_forces_mil01.gd).

### Échelons de mobilisation (T-051)

T-051 (VALIDÉ) : mobilisation par échelons historiquement documentés. Un échelon sans donnée fiable vaut null (« introuvable ») ; aucun total n'est réparti arbitrairement. Données de phase 1 : le moteur ne les utilise pas encore (phase 2).

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|
| Premier échelon : rappel d'août 1914 (plan de mobilisation exécuté) | **2 993 984** | dérivé | BUNDESARCHIV | Réservistes rappelés en août 1914 : hommes mobilisés en août 1914, actifs compris, moins l'armée active. 3 800 000 − 806 016 (actif, US_WD_1916 p. 28) = 2 993 984. Source arrondie à 0,1 M (± 50 000) ; l'actif vient d'une autre source (le Bundesarchiv donne 734 000 pour juillet 1914, périmètre non précisé). Délais : août 1914 (source) ; délais détaillés : introuvables dans les sources consultées. Divergence : 2 200 000 (`US_WD_1916` p. 29) — Estimation de 1913 : pour une guerre offensive, armée active, réserve, réserve d'Ersatz et 1er ban de la Landwehr, « a total of about 3,000,000 men » (1 700 000 en première ligne, 1 300 000 en seconde ligne) ; 3 000 000 − 800 000 actifs ≈ 2 200 000. |
| Échelons suivants : instruits non rappelés en août 1914 | **810 000** | dérivé | US_WD_1916, BUNDESARCHIV | Différence entre le total des instruits mobilisables (US_WD_1916 p. 28) et les mobilisés d'août 1914 (BUNDESARCHIV). 4 610 000 − 3 800 000 = 810 000 (indépendant de la valeur de l'actif). NON DOCUMENTÉE : classes plus âgées de la Landwehr et Landsturm instruit (hypothèse). Aucun chiffre par catégorie n'a été trouvé pour 1914. Différence de deux sources de définitions voisines mais non identiques ; incertitude au moins égale à ± 50 000. Délais : introuvable. |
| Réserves résiduelles (mobilisation à long terme) | ****inconnu**** | introuvable | — | Au-delà des instruits, les ressources restantes sont des hommes non instruits (réserve d'Ersatz non instruite, Landsturm non instruit) : hors du réservoir défini par T-047. Indice non utilisable : US_WD_1916 p. 29, « 7,000,000 men, of whom 4,000,000 have had military training » (1913). |

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
| XVe corps | Strasbourg | vérifié (province seulement) (WO_HANDBOOK_DE_1914 (XVe et XVIe corps « stationed in Alsace-Lorraine »)) | region_035 (Alsace-Lorraine) |
| XVIe corps | Metz | vérifié (province seulement) (WO_HANDBOOK_DE_1914 (XVe et XVIe corps « stationed in Alsace-Lorraine »)) | region_035 (Alsace-Lorraine) |
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
- Réserves sur la carte (non incorporées) : 3 803 984 ; hors carte : 0.
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
