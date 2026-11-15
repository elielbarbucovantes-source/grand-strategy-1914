# MIL-01 — Phase 1 : documentation et correction des données historiques

**Branche :** `dev/mil01-finalisation`, créée depuis `dev/historical-forces` (`a46d8e9`).

**Date :** 15/11/2026.

**Mission :** finalisation de MIL-01, phase 1, autorisée par le directeur avec cinq précisions (sources en ligne, échelons introuvables, T-057, coûts de T-053, fourchettes de pertes).

**Référence :** audit `docs/project/MIL01_AUDIT_REPORT.md` (branche `audit/mil01-review`, commit `bc4b4ac`, non copié ici).

**Périmètre respecté :**
- aucun mécanisme de mobilisation, de combat ou d'IA n'a été modifié ;
- les seuls changements de code concernent T-057 (mois de départ) et le générateur de fiches ;
- `main`, `dev/combat-system` et `dev/historical-forces` sont inchangés, et rien n'a été fusionné.

**Certitude :**
- **établi** : vérifié dans la source, le code ou par exécution ;
- **probable** : indices convergents, non démontré ;
- **hypothèse** : piste à vérifier.

---

## 1. Synthèse

| Point | Résultat | Certitude |
|---|---|---|
| Registres T-047 à T-057 | Consignés (commit `7be5a2c`), avec les précisions du directeur | Établi |
| Cas allemand | Total ramené de 4 806 016 à **4 610 000**, le total de la source. Réservoir : 3 803 984. | La lecture « actifs compris » est **probable** |
| Même règle, Italie | Total ramené de 1 555 033 à **1 300 000**. Réservoir : 994 967. **Nouveau constat**, absent de l'audit. | Probable |
| Échelons (T-051) | Documentés pour **2 puissances sur 7** (Allemagne, Autriche-Hongrie). Les 5 autres sont « introuvables ». | Établi (état des sources consultées) |
| Sièges de corps | **33 sur 113** vérifiés (27 corps russes ajoutés). Deux corrections : VIe corps russe à Białystok (région 057), VIIe à Simferopol (région 063). | Établi (source primaire russe) |
| IIe et IIIe corps ottomans | **Non déplacés** : indices secondaires seulement | Probable (Thrace), non démontré |
| Territorial Force | 268 777 hommes recontrôlés sur le fac-similé ; aucun double comptage ; catégorie distincte créée dans la base | Établi (chiffre) ; probable (personnel permanent, voir §7) |
| T-057 | Campagne fixée en janvier 1914 ; mois libre dans le bac à sable | Établi (tests) |
| Tests | **55 sur 55** (54 existants et 1 nouveau), interfaces validées ; intégration continue : voir §11 | Établi |

---

## 2. Registres

- Le registre `docs/decisions/DECISIONS_MIL01_T047_T057.md` existe déjà (commit `7be5a2c`).
- Il reçoit les **précisions du directeur** de la mission de phase 1 :
  - T-051 : échelon introuvable sans répartition arbitraire ;
  - T-057 : mois libre dans le bac à sable ;
  - T-053 : pas de système économique parallèle ;
  - T-048 : fourchettes proposées, non appliquées.
- L'état de T-051 et de T-057 y est mis à jour.

---

## 3. Grille de cohérence des sept puissances

Les valeurs viennent de la base après correction. La colonne « Total de la source » est le total des instruits mobilisables donné par la fiche nationale de la source, lu comme incluant l'armée active.

| Puissance | Actif | Réserves | Actif + réserves | Total de la source | 1er échelon | Échelons suivants | Résiduel | Hors carte (actif) |
|---|---|---|---|---|---|---|---|---|
| Allemagne | 806 016 | **3 803 984** (au lieu de 4 000 000) | 4 610 000 | 4 610 000 (US WD p. 28) | 2 993 984 (dérivé) | 810 000 (dérivé) | introuvable | 0 (sourcé) |
| France | 844 188 | 2 300 000 | 3 144 188 | 3 800 000 (p. 20) | introuvable | introuvable | introuvable | 82 368 (dérivé) |
| Autriche-Hongrie | 472 715 | 2 000 000 | 2 472 715 | sans objet (le total *est* le réservoir, p. 38) | 1 347 285 (dérivé) | 652 715 (dérivé) | introuvable | 0 |
| Russie | 1 284 000 | 3 800 000 | 5 084 000 | 6 000 000 (p. 45) | introuvable | introuvable | introuvable | 347 027 (estimé) |
| Royaume-Uni | 247 432 | 209 280 | 456 712 | sans objet (somme exacte des lignes, WO 1922 p. 30) | introuvable | introuvable | introuvable | 121 123 (sourcé) |
| Italie | 305 033 | **994 967** (au lieu de 1 250 000) | 1 300 000 | 1 300 000 (p. 66) | introuvable | introuvable | introuvable | 0 (Libye inconnue) |
| Empire ottoman | 208 000 | 1 000 000 | 1 208 000 | 2 000 000 (Erickson, potentiel) | introuvable | introuvable | introuvable | 160 000 (estimé) |

**Constats :**
- Après correction, **aucune puissance ne dépasse le total de sa source**. C'est vérifié par le nouveau test `test_database_totals_coherent_with_sources`.
- La France reste **en dessous** de sa source de 0,66 M, ce qui est cohérent avec une définition étroite des réserves (p. 9), probablement sans l'armée territoriale. Le plafond ne remonte jamais une valeur : la comparabilité des réserves entre puissances reste **douteuse** (audit P1-7). Une harmonisation vers le haut est une décision ; elle n'est pas appliquée.
- La Russie reste en dessous de son total (6,0 M). La part des réserves sur la carte (27 corps sur 37) n'a pas été revue (audit P2-6).

---

## 4. Cas allemand

### 4.1 Les trois grandeurs de la même source

Toutes ont été relues dans le texte intégral (archive.org `strengthorganiza00unit`), avec les en-têtes de page de l'OCR.

| Page | Texte | Définition |
|---|---|---|
| p. 9, second tableau (1911) | 4 000 000 « Fully trained reserves available for passing from peace to war footing » | Réservistes, hors actifs. Le tableau précise que les chiffres datent de 1911 et que les augmentations ne sont pas publiées. |
| p. 28, rubrique « TOTAL WAR STRENGTH » | « The sum total of trained men which she is able to mobilize amounts to 4,610,000 » | Total des instruits mobilisables. **La phrase ne dit pas si l'armée active est comprise.** La rubrique (effectif de guerre) et le sens de « mobiliser » plaident pour l'inclusion : **probable**. |
| p. 29-30 (estimation de 1913, citée) | « real military resources, 7,000,000 men, of whom 4,000,000 have had military training » ; guerre offensive : active, réserve, réserve d'Ersatz, 1er ban de Landwehr, « about 3,000,000 » | Total des instruits, actifs compris ; premier échelon offensif |
| Bundesarchiv (rubrique Personalumfang) | « August 1914 3,8 Mio. Mann mobil gemacht » | Mobilisés effectifs d'août 1914, actifs compris |

### 4.2 Calcul et choix

1. Le modèle exige actif + réserves ≤ total des instruits.
   - Ancienne base : 806 016 + 4 000 000 = 4 806 016 > 4 610 000. **Incohérence établie** si le total p. 28 inclut l'actif.
   - Avec la lecture inverse (actifs non compris), le total serait de 5 416 016, encore plus loin des 3,8 M de 1914. Cette lecture n'est donc pas retenue.
2. **Réservoir retenu : 4 610 000 − 806 016 = 3 803 984.**
   - Même document, même date de référence (« conditions in July, 1914 ») et même actif (p. 28).
   - La valeur de 4 000 000 est conservée comme divergence.
3. **Valeur de l'audit examinée.** 3 803 984 est bien le résultat de cette soustraction. Il **dépend** de la lecture « actifs compris », qui est probable mais non certaine ; c'est indiqué dans la base (`reliability_note`).
4. Le chiffre de 1913 (4 000 000 instruits, soit environ 3 200 000 réservistes) est une autre estimation du même document, plus basse. Il est conservé comme divergence, non retenu.

### 4.3 Échelons allemands (T-051)

| Échelon | Valeur | Calcul | Limites |
|---|---|---|---|
| 1er : rappel d'août 1914 | 2 993 984 | 3 800 000 (Bundesarchiv) − 806 016 | Source arrondie à 0,1 M (± 50 000). Actif d'une autre source : le Bundesarchiv donne 734 000, périmètre non précisé. Divergence : environ 2 200 000 d'après l'estimation de 1913 (p. 29). |
| Suivants : instruits non rappelés en août | 810 000 | 4 610 000 − 3 800 000 (indépendant de l'actif) | Composition **non documentée** (classes âgées de la Landwehr et Landsturm instruit : hypothèse). Délais introuvables. |
| Résiduel | introuvable | — | Ce sont des non-instruits, hors du réservoir de T-047 |

**Pourquoi 4,8 M contre 3,8 M (question de l'audit) :**
- 0,196 M venaient de l'incohérence des données, désormais corrigée ;
- 0,81 M viennent de ce que le jeu appelle **tous** les instruits, et pas seulement l'échelon d'août 1914. Cela sera corrigé en phase 2, par le moteur d'échelons.

---

## 5. Italie (nouveau constat)

- La même règle donne : 305 033 + 1 250 000 = 1 555 033 > 1 300 000. Le total p. 66 est « a conservative estimate […] 1,300,000 fully trained men », sous la rubrique « TOTAL WAR STRENGTH ».
- Réservoir corrigé : **994 967**. La valeur de 1 250 000 est conservée comme divergence.
- **Certitude : probable**, pour la même raison qu'en Allemagne.
- L'effectif métropolitain en Libye reste inconnu ; l'actif italien sur la carte est probablement surévalué (audit P3-3, non traité).

**Autriche-Hongrie : règle non appliquée.**
- Le chiffre « Austria has 2,000,000 fully trained men subject to call » (p. 38) désigne des hommes **à rappeler**, donc hors actifs.
- Le premier échelon (1 347 285) est dérivé du même passage : « latest estimate of war strength ». Le texte donne armée commune 1 360 000, Landwehr autrichienne 240 000 et Landwehr hongroise 220 000. L'OCR lit « 2-10,000 » pour la Landwehr autrichienne ; 240 000 est confirmé par le total du passage (4 320 000).
- Le Landsturm (2 000 000) et la réserve d'Ersatz (500 000) mêlent instruits et non-instruits : ils ne sont pas utilisés comme échelons.

---

## 6. Répartition régionale

### 6.1 Statut des 113 sièges

| Puissance | Sièges | Vérifiés | À vérifier | Changement en phase 1 |
|---|---|---|---|---|
| Allemagne | 25 | 5, dont XV et XVI au niveau de la **province seulement** | 20 | XV et XVI : niveau de vérification précisé (audit P3-2) |
| France | 22 | 0 | 22 | Gallica refuse l'accès automatisé (Annuaire officiel de 1914) |
| Autriche-Hongrie | 16 | 0 | 16 | Aucune source primaire en ligne trouvée |
| **Russie** | 27 | **27** | 0 | **Source primaire** : état officiel abrégé des troupes au 1er mars 1914 |
| Royaume-Uni | 8 | 1 (Aldershot) | 7 | — |
| Italie | 12 | 0 | 12 | — |
| Empire ottoman | 3 | 0 | 3 (dont 2 « indice contraire ») | Statut précisé |
| **Total** | **113** | **33** | **80** | |

### 6.2 Russie

- **Source :** Главный штаб, *Краткое расписание сухопутных войск*, corrigé au 1er mars 1914 (archive.org `kratkoeraspisaniesuhoputnyhvojskpogo93`), p. 214-226.
- Chaque notice de corps se termine par « Штабъ г. … ». Les 25 autres sièges de la base concordent.

| Corps | Base avant | Source | Effet dans le jeu |
|---|---|---|---|
| **VIe** | Łomża (région 056) | « Штабъ г. Бѣлостокъ » : **Białystok** | Passe en **région 057** (Biélorussie) |
| **VIIe** | Iekaterinoslav | « Штабъ г. Симферополь, Таврической губ. » : **Simferopol** | Passe en **région 063** (Crimée) |

- **Date :** l'état est au 1er mars 1914, la campagne commence en janvier 1914 (T-057). L'audit avait aussi relevé que le VIe corps est à Białystok depuis 1909 (indice secondaire), ce qui va dans le même sens. **Un changement entre janvier et mars 1914 n'est pas exclu, mais aucun n'est connu.**
- **Effet de bord :** la région 056 (Pologne du Nord) ne garde qu'un corps. Dans le rapport d'équilibrage, le cas « Prusse-Orientale : RU 056 → DE 026 » oppose désormais 30 784 attaquants (au lieu de 61 568) à 57 819 défenseurs. Les pertes passent de 55 % / 44 % à 79 % / 9 %.

### 6.3 Empire ottoman (régions 087, 088, 089)

- Les IIe et IIIe corps sont placés en Thrace par des indices secondaires (articles encyclopédiques citant Erickson, versions divergentes : Edirne et Kırk Kilise en région 089, Tekirdağ en région 088).
- **Aucune source primaire n'a été trouvée en ligne.** Un « Turkish army » de 1907 existe sur archive.org, mais il est antérieur à la réorganisation de 1914, donc non pertinent.
- Les sièges ne sont **pas déplacés**. Statut : « à vérifier — indice contraire », avec une note dans la base.

### 6.4 Ce qui reste estimé

- La répartition **à parts égales par corps** est inchangée (audit P1-6) : aucune source d'effectif par corps n'a été trouvée.
- Les autres choix restent des **estimations** :
  - le corps colonial français ;
  - la clé hors carte de l'Algérie ;
  - la part russe hors carte (10/37) ;
  - la part ottomane hors carte (10/13).

---

## 7. Territorial Force (T-050)

**Recontrôle sur l'image du fac-similé** (WO 1922, p. 30, tableau (i)(b), archive.org page n39) :

| Ligne au 1er août 1914 | Effectif théorique | Effectif réel |
|---|---|---|
| Regular Army | 256 798 | 247 432 |
| Army Reserve | 145 000 | 145 347 |
| Special Reserve | 80 120 | 63 933 |
| Channel Islands etc., Militia | 5 742 | 5 613 |
| **Territorial Force** | 316 094 | **268 777 †** (10 684 officiers, 258 093 hommes) |
| Territorial Force Reserve | — | 2 082 |
| Bermuda and Isle of Man Volunteers | 445 | 330 |
| **Total** | 804 199 | 733 514 |

**Note † :** « Includes permanent staff of the Territorial Force ».

**Vérification du double comptage :**
1. **Réservoir britannique.** 209 280 = 145 347 + 63 933. La Territorial Force n'y figure pas (établi, testé).
2. **Armée régulière.** 247 432 est la ligne « Regular Army ». La somme des sept lignes égale exactement le total (733 514) : la source traite donc ces catégories comme disjointes.
   - Le personnel permanent de la Territorial Force (des militaires de carrière) pourrait aussi figurer dans « Regular Army ». La page ne le dit pas ; le total additif indique que non (**probable**).
3. **Territorial Force Reserve (2 082).** C'est une ligne distincte, non incluse.
4. **Divergence.** La source américaine donne « Territorial force, British Isles, numbers 315,408 » (p. 9, note 4, sans date). Ce chiffre est proche de l'effectif **théorique** (316 094), pas de l'effectif réel. Il n'est pas retenu.

**Données ajoutées :**
- Bloc `united_kingdom.territorial_force` dans la base : valeur, date, définition, effectif théorique, ligne non incluse, contrôle de double comptage, règle d'emploi de T-054.
- Une section dans la fiche britannique.
- **Le moteur ne l'utilise pas encore** : c'est la phase 4.
- **Pistes de délais** (non exploitées) :
  - WO 1922, Section 8 : Territorial Force servant à l'étranger, par mois ;
  - WO 1922, Section 2a : engagements volontaires.

---

## 8. T-057 : départ en janvier 1914

| Élément | Changement |
|---|---|
| `data/scenarios/campaign_1914.json` (généré) | `start.month = 1`, statut « VALIDÉ (T-057) » |
| `data/scenarios/sandbox_fictif.json` (généré) | `start.month = null`, « librement configurable » |
| `GameSession.new_game` | Refuse un autre mois que celui fixé par le scénario, avec un message clair. Le bac à sable accepte les mois 1 à 12. |
| Menu (`src/ui/main.gd`) | Sélecteur de mois désactivé pour la campagne, actif pour le bac à sable |
| `data/rules/game_rules.json`, `game_calendar.gd`, `PROTOTYPE_STATUS.md`, `MIL01_METHODE.md` §8 | Mentions « R-13 ouvert » remplacées |
| `tests/demo_campaign.gd` (démonstration non probatoire) | Départ en janvier au lieu de juillet |

**Non fait :** le contrôle visuel du menu à l'écran. Le test d'interface `ui_smoke` (départ en janvier) passe.

---

## 9. Propositions préparées pour plus tard (non appliquées)

- **T-048 et T-055.** Fourchettes de pertes et simulations comparatives : préparation prévue en phase 4, conformément à la précision du directeur. Rien n'est appliqué.
- **T-053.** Coûts économiques. Besoins identifiés :
  - un budget (ECO-05) ;
  - une ressource pour l'administration et le matériel ferroviaire (ECO-01) ;
  - l'effet du retrait des travailleurs sur la production (ECO-02 et ECO-06).
  - Ces mécanismes ne sont pas définis. **Aucun système parallèle n'est créé** ; la phase 2 signalera les branchements en attente.

---

## 10. Effets mesurés (`tests/balance_report.gd`, relancé)

| Mesure | Avant (audit) | Après la phase 1 |
|---|---|---|
| Allemagne mobilisée (4 mois) | 4 806 016 présents | **4 610 000** |
| Italie mobilisée | 1 555 033 | **1 300 000** |
| Unités sur la carte après mobilisation des sept puissances | 974 | **963** |
| Lorraine après mobilisation | 344 749 / 496 178 ; 65 unités ; 5,8 s | 330 699 / 496 178 ; 64 unités ; 4,6 s |
| Lorraine (temps de paix) | 66 % / 4 % | Identique |
| Prusse-Orientale | 61 568 contre 57 819 ; 55 % / 44 % | 30 784 contre 57 819 ; 79 % / 9 % (effet du VIe corps) |
| Variante « tirailleurs » | Identique au cas par défaut (défaut du banc, audit G.1) | **Toujours identique** : non corrigé, prévu en phase 4 |

Les temps de calcul varient d'une exécution à l'autre ; ils ne sont pas probants.

---

## 11. Tests et intégration continue

| Test | Résultat |
|---|---|
| `python tools/export/build_game_data.py --check` | PASS |
| `python tools/export/build_scenario.py --check` | PASS (scénarios régénérés) |
| `python tools/history/render_fiches.py --check` | PASS (fiches régénérées) |
| `bash tests/run.sh`, Godot 4.7.2 sans interface, sur ce poste | **55 réussis, 0 échec** ; interface stratégique VALIDÉE ; interface de bataille VALIDÉE |
| Nouveau test `test_database_totals_coherent_with_sources` | Réussi. Il vérifie : actif + réserves ≤ total de la source ; échelons sourcés, dérivés avec calcul ou introuvables avec motif ; somme des échelons ≤ réservoir ; Territorial Force distincte ; sièges russes ; placement du VIe corps en région 057 ; réservoir allemand dans la campagne. |
| Test modifié `test_new_game_territories_and_unknown_values` | Réussi. Il vérifie : campagne en janvier ; autre mois refusé ; bac à sable en juin accepté ; mois 13 refusé. |
| Intégration continue GitHub | Résultat inscrit dans le compte rendu de fin de phase. Il n'était pas connu à la rédaction de ce rapport, puisque l'exécution suit la publication. |

Le message « Parse JSON failed » de la sortie vient du test volontaire de sauvegarde tronquée. Il était déjà présent lors de l'audit.

---

## 12. Fichiers modifiés

- **Données :**
  - `data/history/military_forces_1914.json` : réserves allemandes et italiennes ; échelons ; contrôles de total ; Territorial Force ; sièges russes ; statuts ottomans ; nouvelle source `RU_RASPISANIE_1914` ;
  - `data/rules/game_rules.json`.
- **Données générées :**
  - `data/scenarios/campaign_1914.json` et `sandbox_fictif.json` ;
  - `docs/history/fiches/*.md` (7 fiches).
- **Outils :**
  - `tools/export/build_scenario.py` (T-057) ;
  - `tools/history/render_fiches.py` (sections échelons, contrôle du total, Territorial Force, notes de siège).
- **Code :** `src/app/game_session.gd`, `src/ui/main.gd`, `src/core/game_calendar.gd` (T-057 seulement).
- **Tests :** `tests/unit/test_forces_mil01.gd` (nouveau test), `tests/unit/test_world_and_state.gd`, `tests/demo_campaign.gd`.
- **Documentation :**
  - `docs/decisions/DECISIONS_MIL01_T047_T057.md`, `docs/decisions/README.md`, `docs/decisions/DECISIONS_PENDING.md` (commit `7be5a2c`, plus des compléments) ;
  - `docs/history/MIL01_METHODE.md`, `docs/history/BIBLIOGRAPHIE.md` ;
  - `docs/military/MOBILISATION.md`, `docs/project/PROTOTYPE_STATUS.md` ;
  - ce rapport.

---

## 13. Références historiques

**Sources effectivement consultées pendant la phase 1 :**

| Source | Passages | Accès |
|---|---|---|
| US War Department, *Strength and Organization of the Armies…* (1916) | p. 9 (tableaux et note 4), 20-21, 28, 29-30, 37-38, 45-46, 66 : texte intégral OCR | https://archive.org/details/strengthorganiza00unit |
| War Office, *Statistics of the Military Effort of the British Empire…* (1922) | p. 30, tableau (i)(b), **sur l'image du fac-similé** ; recherche dans le texte intégral (Section 8, Section 2a repérées) | https://archive.org/details/statisticsofmili00grea |
| Главный штаб, *Краткое расписание сухопутных войск*, corrigé au 1er mars 1914 | p. 214-226 (corps) : texte OCR | https://archive.org/details/kratkoeraspisaniesuhoputnyhvojskpogo93 |
| Même série, édition d'août 1913 (`…pogo24`) | Parcourue ; section des corps incomplète dans l'OCR. **Non utilisée.** | https://archive.org/details/kratkoeraspisaniesuhoputnyhvojskpogo24 |
| War Office, *Handbook of the German Army*, 1912/1914 | Recherche des villes de garnison dans le texte OCR : pas de tableau de stationnement exploitable | https://archive.org/details/hndbk-german-army-1914 |
| Bundesarchiv, « Preußische und deutsche Streitkräfte 1867 bis 1918 » | Consulté pendant MIL-01, **non relu** en phase 1 | https://www.bundesarchiv.de/im-archiv-recherchieren/archivgut-recherchieren/nach-themen/preussische-und-deutsche-streitkraefte-1867-bis-1918/ |

**Tentatives sans résultat :**
- Gallica, *Annuaire officiel de l'armée française* 1914 (`ark:/12148/bpt6k176446d`) : accès automatisé refusé (Cloudflare). À consulter manuellement.
- *Rangliste der Königlich Preußischen Armee* 1914 : exemplaire numérisé repéré, sous droits.
- Reichsarchiv, *Der Weltkrieg*, t. I : aucun texte intégral trouvé.

**Indices secondaires (non probants, repris de l'audit) :**
- Wikipédia, [6th Army Corps (Russian Empire)](https://en.wikipedia.org/wiki/6th_Army_Corps_(Russian_Empire)) ;
- Wikipédia, [II Corps](https://en.wikipedia.org/wiki/II_Corps_(Ottoman_Empire)) et [III Corps (Ottoman Empire)](https://en.wikipedia.org/wiki/III_Corps_(Ottoman_Empire)).

**Références seulement, non consultées :**
- Reichsarchiv, *Kriegsrüstung und Kriegswirtschaft*, Anlagen ;
- *Les Armées françaises dans la Grande Guerre*, t. I ;
- *Österreich-Ungarns letzter Krieg*, t. I ;
- Ufficio Storico, *L'Esercito italiano nella Grande Guerra*, vol. I ;
- E. J. Erickson, *Ordered to Die* (2001).

---

## 14. Problèmes encore ouverts

1. **Échelons introuvables pour 5 puissances sur 7.** La phase 2 doit définir ce que le moteur fait d'une puissance sans échelon documenté. Voir la décision D-1.
2. La lecture « total des instruits = actifs compris » (Allemagne, Italie) est **probable**, non certaine.
3. La comparabilité des réserves reste douteuse : France sous sa source, Russie sous la sienne.
4. 80 sièges sur 113 restent « à vérifier » ; la répartition à parts égales par corps est inchangée.
5. Les IIe et IIIe corps ottomans ne sont pas déplacés, faute de source primaire.
6. La Territorial Force est documentée mais non jouable : phase 4.
7. Les effectifs italiens en Libye restent inconnus.
8. Le banc d'essai d'équilibrage a toujours une variante inopérante : phase 4.

---

## 15. Décisions nécessaires

- **D-1. Puissances sans échelon documenté** (France, Russie, Royaume-Uni, Italie, Empire ottoman). En phase 2, que fait le moteur ?
  - (a) Le réservoir entier reste appelable comme un seul bloc, signalé « échelon non documenté ».
  - (b) Rien n'est appelable tant que l'échelon n'est pas documenté.
  - (c) Autre règle.
  - La précision n° 2 exclut de découper le total, mais ne dit pas si le total reste utilisable. Sans décision, la phase 2 proposera (a), marquée PROPOSÉE.
- **D-2. Plafond Allemagne et Italie.** Faut-il confirmer la lecture « actifs compris », ou demander une recherche complémentaire avant de la considérer comme acquise ?
- **D-3. Harmonisation des réserves vers le haut** (France, Russie, vers les totaux de la source) : faut-il l'appliquer ? Elle n'est pas faite.
- **D-4. Sources inaccessibles en ligne** (Gallica, Erickson 2001, Reichsarchiv) : pouvez-vous en fournir des extraits ou un accès ?
