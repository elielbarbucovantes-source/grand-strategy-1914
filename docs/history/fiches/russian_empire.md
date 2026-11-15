# Empire russe — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : suffisant (part sur la carte et répartition estimées)**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **1 284 000** |
| Date de référence | 1914 (données antérieures à la mobilisation) |
| Définition | Effectif total du temps de paix, « active troops » et troupes de forteresse, tout l'empire (Europe, Caucase, Asie centrale, Sibérie) |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 et p. 45 (« The total peace strength amounts all told to about 1,284,000 ») |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible à moyenne |
| Remarque | Le document juge difficile un résumé fiable de l'armée russe (p. 42) ; plusieurs catégories y sont marquées « (?) ». |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 1 000 000 | `US_WD_1916` | p. 46 | « Army strength, 1909, 1,000,000 » (année 1909) | Antérieur aux augmentations : non retenu. |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **3 800 000** |
| Date de référence | estimation de 1911 publiée en 1916 |
| Définition | Réservistes entièrement instruits disponibles pour le passage au pied de guerre (tout l'empire) |
| Source | `US_WD_1916` — United States War Department, Office of the Chief of Staff, War College Division, General Staff, No. 22 : Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914). Washington, Government Printing Office, 1916 (War Department Document No. 499). |
| Page / passage | p. 9 (second tableau) |
| Lien | https://archive.org/details/strengthorganiza00unit |
| Fiabilité | faible |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 2 970 429 | `US_WD_1916` | p. 46 | « Other trained men available » dans l'estimation de guerre (5 962 306 au total) | Autre ligne du même document. |

Part des réserves sur la carte : 27/37 — ESTIMATION : 27 des 37 corps sont en Russie d'Europe (carte du jeu).

**Contrôle de cohérence avec la source :** total des instruits, actifs compris : 6 000 000 (`US_WD_1916` p. 45) ; actif + réserves = 5 084 000. « The total number of trained men subject to call amounts to about 6,000,000 » (rubrique « Total war strength ») Contrôle de phase 1 : armée active + réserves ≤ ce total (testé par test_forces_mil01.gd).

### Échelons de mobilisation (T-051)

T-051 (VALIDÉ) : mobilisation par échelons historiquement documentés. Un échelon sans donnée fiable vaut null (« introuvable ») ; aucun total n'est réparti arbitrairement. Données de phase 1 : le moteur ne les utilise pas encore (phase 2).

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|
| Premier échelon : appel prévu par le plan de mobilisation de 1914 | ****inconnu**** | introuvable | — | Aucune source consultée ne donne l'effectif prévu par le plan russe (Расписание n° 19). US_WD_1916 p. 46 estime ce que la Russie pourrait mobiliser « upon her European frontiers » (2 000 000), ce qui est une capacité de déploiement, pas un plan. |
| Échelons suivants | ****inconnu**** | introuvable | — | Même lacune documentaire. |
| Réserves résiduelles | ****inconnu**** | introuvable | — | Même lacune documentaire. |

### Ventilation par arme

Source : `US_WD_1916` p. 9

| Infanterie | Cavalerie | Art. de campagne | Art. à pied | Art. côtière | Technique | Train | Santé | Total |
|---|---|---|---|---|---|---|---|---|
| 815 000 | 138 000 | 153 792 | 18 056 | 14 152 | 37 448 | **inconnu** | **inconnu** | 1 284 000 |

Technique « includes miscellaneous organizations, staffs, school detachments » ; train et service de santé inconnus « (?) ».

### Forces hors de la carte

**347 027** (estimation) — ESTIMATION : 10 des 37 corps (3 caucasiens, 2 turkestanais, 5 sibériens) sont hors de la carte européenne du jeu ; part retenue 10/37 de l'actif, à défaut de chiffres par district. 37 corps : US_WD_1916 p. 42.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 27 — 37 corps au total (US_WD_1916 p. 42) moins 10 corps asiatiques et caucasiens hors carte (connaissance générale, à vérifier). ; RU_RASPISANIE_1914 (27 corps européens, p. 214-226)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Corps de la Garde (district de Saint-Pétersbourg) | Saint-Pétersbourg | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_064 (Russie du Nord-Ouest) |
| Ier corps (Saint-Pétersbourg) | Saint-Pétersbourg | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_064 (Russie du Nord-Ouest) |
| XVIIIe corps (Saint-Pétersbourg) | Saint-Pétersbourg | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_064 (Russie du Nord-Ouest) |
| XXIIe corps (Finlande) | Helsingfors | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_052 (Finlande) |
| IIe corps (Vilna) | Grodno | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_057 (Biélorussie) |
| IIIe corps (Vilna) | Vilna | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_057 (Biélorussie) |
| IVe corps (Vilna) | Minsk | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_057 (Biélorussie) |
| XXe corps (Vilna) | Riga | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_053 (Pays baltes du Nord) |
| VIe corps (Varsovie) | Białystok | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) — Corrigé le 15/11/2026 : la base indiquait Łomża ; la source (« Штабъ г. Бѣлостокъ ») donne Białystok. | region_057 (Biélorussie) |
| XIVe corps (Varsovie) | Lublin | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_056 (Pologne russe orientale) |
| XVe corps (Varsovie) | Varsovie | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_055 (Pologne russe occidentale) |
| XIXe corps (Varsovie) | Brest-Litovsk | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_057 (Biélorussie) |
| XXIIIe corps (Varsovie) | Varsovie | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_055 (Pologne russe occidentale) |
| IXe corps (Kiev) | Kiev | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_059 (Ukraine centrale) |
| Xe corps (Kiev) | Kharkov | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_059 (Ukraine centrale) |
| XIe corps (Kiev) | Rovno | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_058 (Ukraine occidentale) |
| XIIe corps (Kiev) | Vinnitsa | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_058 (Ukraine occidentale) |
| XXIe corps (Kiev) | Kiev | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_059 (Ukraine centrale) |
| VIIe corps (Odessa) | Simferopol | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) — Corrigé le 15/11/2026 : la base indiquait Iekaterinoslav ; la source (« Штабъ г. Симферополь, Таврической губ. ») donne Simferopol. | region_063 (Crimée) |
| VIIIe corps (Odessa) | Odessa | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_060 (Ukraine méridionale) |
| Corps des grenadiers (Moscou) | Moscou | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_066 (Russie centrale) |
| Ve corps (Moscou) | Voronej | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_066 (Russie centrale) |
| XIIIe corps (Moscou) | Smolensk | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_066 (Russie centrale) |
| XVIIe corps (Moscou) | Moscou | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_066 (Russie centrale) |
| XXVe corps (Moscou) | Moscou | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_066 (Russie centrale) |
| XVIe corps (Kazan) | Kazan | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_067 (Volga moyenne) |
| XXIVe corps (Kazan) | Samara | vérifié (RU_RASPISANIE_1914, p. 214-226 (« Штабъ г. … »)) | region_068 (Volga inférieure) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 1 284 000 ; sur la carte : 936 973 (unités combattantes 831 160 + services 105 813).
- Réserves sur la carte (non incorporées) : 2 772 972 ; hors carte : 1 027 028.
- Unités : 108.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_052 (Finlande) | 22 027 | 3 730 | 5 027 |
| region_053 (Pays baltes du Nord) | 22 027 | 3 730 | 5 027 |
| region_055 (Pologne russe occidentale) | 44 054 | 7 460 | 10 054 |
| region_056 (Pologne russe orientale) | 22 027 | 3 730 | 5 027 |
| region_057 (Biélorussie) | 110 135 | 18 650 | 25 135 |
| region_058 (Ukraine occidentale) | 44 054 | 7 460 | 10 054 |
| region_059 (Ukraine centrale) | 66 081 | 11 190 | 15 081 |
| region_060 (Ukraine méridionale) | 22 026 | 3 730 | 5 027 |
| region_063 (Crimée) | 22 027 | 3 730 | 5 027 |
| region_064 (Russie du Nord-Ouest) | 66 081 | 11 190 | 15 081 |
| region_066 (Russie centrale) | 110 130 | 18 650 | 25 135 |
| region_067 (Volga moyenne) | 22 026 | 3 730 | 5 027 |
| region_068 (Volga inférieure) | 22 026 | 3 730 | 5 027 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
