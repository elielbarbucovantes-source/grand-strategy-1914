# Décisions T-047 à T-057 — effectifs, mobilisation, Territorial Force, engagements, date de départ

**Statut du document :** registre. Il consigne des décisions **VALIDÉES par le directeur** (15/11/2026). Il ne crée aucune décision nouvelle.

**Source :** missions du directeur du 15/11/2026.
- T-047 à T-050 : décisions validées avant l'audit MIL-01. Jusqu'ici, elles n'étaient consignées dans aucun registre (audit, constat P1-8).
- T-051 à T-057 : réponses aux questions K-1 à K-7 de l'audit (`docs/project/MIL01_AUDIT_REPORT.md`, branche `audit/mil01-review`, commit `bc4b4ac`), mission « Finalisation de MIL-01 ».

**Règles de lecture :**
- Le **texte de la décision** reprend le directeur. Seule la forme a été adaptée : aucun contenu n'a été ajouté.
- La rubrique **« Points non tranchés »** liste ce que la décision ne fixe pas. Ces points ne sont **pas** des décisions : les valeurs que l'implémentation proposera seront marquées PROPOSÉES.
- **État** : D = documentée, I = implémentée, T = testée, F = fonctionnelle en jeu. Un état n'est coché que s'il est vérifié.
- Une décision ultérieure ne supprime pas celle-ci : elle la remplace explicitement.

## 1. Tableau de synthèse

| ID | Objet | Choix | Remplace ou tranche | État au 15/11/2026 |
|---|---|---|---|---|
| T-047 | Effectifs historiques | Armées actives de 1914 au départ ; réserves mobilisables progressivement ; cinq catégories distinctes | Complète MIL-01 et MIL-02 | D, I, T (phases 1 et 2 : catégories séparées, pertes et prisonniers, conservation testée) |
| T-048 | Intensité des combats | **D** : intensité variable selon le type d'engagement | Précise MIL-06 et T-042 | D ; non implémentée |
| T-049 | Vitesse de mobilisation | **B** : réaliste et flexible | Précise MIL-02 | D, I, T (phase 2) : paramètres nationaux ; seul le rythme allemand est dérivé, les autres sont PROVISOIRES |
| T-050 | Territorial Force britannique | **B** : catégorie militaire distincte | — | D, I, T (phase 4) ; délais et part de volontaires PROVISOIRES ; répartition ESTIMÉE ; voir `docs/military/TERRITORIAL_FORCE.md` |
| T-051 | Plafond de mobilisation | **C** : mobilisation progressive par échelons | Audit K-1 | D, I, T (phase 2) : échelons pour 2 puissances sur 7, bloc unique pour les autres (MIL01-P1-D1) |
| T-052 | Mobilisation de l'IA | **D** : doctrine nationale et réaction au contexte stratégique | Audit K-3 | D, I, T (phase 3) ; doctrines PROPOSÉES ; voir `docs/military/MOBILISATION_IA.md` |
| T-053 | Influence du joueur | **C** : posture générale et allocation de moyens | Audit K-2 | D, I, T (phase 2) : postures et allocation, sans coût économique (Q1, Q2) |
| T-054 | Territorial Force : emploi | **B** : déploiement outre-mer volontaire | Audit K-4 | D, I, T (phase 4) ; délais et part de volontaires PROVISOIRES ; répartition ESTIMÉE ; voir `docs/military/TERRITORIAL_FORCE.md` |
| T-055 | Type d'engagement | **C** : choix de l'attaquant, posture du défenseur, combinés aux circonstances | Audit K-5 (en partie) | D ; non implémentée |
| T-056 | Mobilisation en temps de paix | **A** : libre, sans pénalité diplomatique automatique, publiquement visible | Audit K-6 (1re question) | D, I, T (phase 2) : posture et échelons publics, volumes confidentiels |
| T-056 bis | Réservistes en territoire occupé | **B** : rejoignent leur armée si une voie de communication reste accessible, sinon bloqués | Audit K-6 (2e question) | D, I, T (phase 2) : communications terrestres, alliés compris, mer exclue |
| T-057 | Début de campagne | **A** : janvier 1914 | **Tranche R-13** ; audit K-7 | D, I, T (phase 1) ; F : menu (sélecteur réservé au bac à sable), non vérifié à l'écran |

## 2. Texte des décisions

### T-047 — Effectifs historiques

**Décision.**
- La campagne commence avec les armées actives de 1914.
- Les réserves sont mobilisables progressivement.
- Il faut distinguer : armée active ; réserves disponibles ; hommes en mobilisation ; hommes incorporés ; hommes effectivement présents dans les unités.

**Points non tranchés :** catégorie des pertes, prisonniers et disparus (nécessaire pour réconcilier les cinq catégories en guerre ; audit F).

### T-048 — Intensité des combats (choix D)

**Décision.** L'intensité varie selon le type d'engagement. Les pertes dépendent notamment du type d'engagement, des formations, du terrain, des fortifications, du moral, ainsi que de la durée et de l'intensité du combat.

**Points non tranchés :**
- liste des types d'engagement : l'audit cite à titre d'exemple escarmouche, combat limité, assaut et grande bataille ;
- **fourchettes de pertes visées par type** (audit K-5).

**Précision du directeur (15/11/2026) :** préparer des propositions de fourchettes et des simulations comparatives, sans les appliquer avant validation.

### T-049 — Vitesse de mobilisation (choix B)

**Décision.** Mobilisation réaliste et flexible. Le rythme dépend des capacités administratives, des infrastructures ferroviaires, des capacités logistiques et des réserves disponibles.

**Points non tranchés :** valeurs nationales, qui doivent être sourcées ; mesure des capacités.

### T-050 — Territorial Force britannique (choix B)

**Décision.** Catégorie militaire distincte, avec ses propres effectifs et délais de mobilisation.

**Données existantes :** 268 777 hommes au 1er août 1914 (War Office 1922, p. 30), exclus aujourd'hui du réservoir (`data/history/military_forces_1914.json`, bloc `excluded`).

### T-051 — Plafond de mobilisation (choix C)

**Décision.** Mobilisation progressive par échelons :
- premier échelon : effectifs prévus par les plans de mobilisation de 1914 ;
- échelons suivants : classes supplémentaires, plus âgées ou moins immédiatement disponibles ;
- réserves résiduelles : mobilisation éventuelle à plus long terme.

**Les échelons doivent être historiquement documentés. Aucun chiffre arbitraire.**

**Précision du directeur (15/11/2026) :** un échelon sans données historiques suffisamment fiables reste « introuvable ». Un total global n'est jamais réparti arbitrairement entre échelons. Les échelons documentés restent utilisables indépendamment.

### T-052 — Mobilisation de l'IA (choix D)

**Décision.** Chaque pays possède une doctrine de mobilisation, des seuils de menace, des réactions aux mobilisations étrangères, et prend en compte alliances et tensions diplomatiques. **L'IA ne dispose d'aucune information secrète à laquelle elle ne devrait pas avoir accès.**

**Points non tranchés :** contenu des doctrines nationales et valeurs des seuils (seront PROPOSÉS et, autant que possible, sourcés).

### T-053 — Influence du joueur (choix C)

**Décision.** Le joueur choisit une posture de mobilisation, puis répartit ses moyens administratifs, ferroviaires et logistiques. Les conséquences économiques et diplomatiques doivent être cohérentes avec ses choix.

**Points non tranchés :**
- liste des postures ;
- nature des coûts : le modèle économique (R-03, ECO-01, ECO-02, ECO-05) n'est pas défini.

**Précision du directeur (15/11/2026) :** aucun système économique parallèle ne doit être créé. Il faut identifier les besoins et les dépendances, puis attendre si nécessaire la définition des mécanismes économiques concernés.

### T-054 — Territorial Force : déploiement (choix B)

**Décision.** Déploiement outre-mer volontaire. La Territorial Force participe d'abord à la défense intérieure ; elle peut être envoyée à l'étranger sous certaines conditions.

**Points non tranchés :** conditions exactes (part des volontaires, délai, décision du joueur) ; elles seront sourcées si possible, sinon PROPOSÉES.

### T-055 — Type d'engagement (choix C)

**Décision.**
- L'attaquant choisit son approche.
- Le défenseur choisit sa posture défensive.
- Le système combine ces décisions avec les circonstances de la bataille.

### T-056 — Mobilisation en temps de paix (choix A)

**Décision.** Mobilisation libre en temps de paix, sans pénalité diplomatique automatique, et publiquement visible par les autres puissances.

**Points non tranchés :** contenu exact de l'information publique (décret, posture, échelon, volumes).

### T-056 bis — Réservistes en territoire occupé (choix B)

**Décision.** Les réservistes peuvent rejoindre leur armée nationale si une voie de communication reste accessible ; sinon, ils restent bloqués.

**Points non tranchés :** définition d'une « voie de communication accessible » (graphe terrestre ami ou allié, détroits, voie maritime) ; délai supplémentaire éventuel.

### T-057 — Début de campagne (choix A)

**Décision.** La campagne historique commence en **janvier 1914**. Cette date doit rester cohérente avec les événements historiques, les calendriers de tours et les événements diplomatiques.

**Conséquences documentaires :**
- **R-13 est tranchée** pour la campagne historique ;
- **Appliquée en phase 1** (15/11/2026) : scénario de campagne `start.month = 1`, refus d'un autre mois par `GameSession.new_game`, sélecteur de mois réservé au bac à sable dans le menu, tests mis à jour.

**Précision du directeur (15/11/2026) :** le bac à sable fictif conserve un mois de départ librement configurable.

## 3. Correspondance avec l'audit MIL-01

| Question de l'audit | Décision |
|---|---|
| K-1 Plafond de mobilisation | T-051 |
| K-2 Influence du joueur | T-053 |
| K-3 Mobilisation de l'IA | T-052 |
| K-4 Territorial Force | T-054 |
| K-5 Type d'engagement et cibles de pertes | T-055 (qui choisit). **Les fourchettes de pertes restent à fixer.** |
| K-6 Mobilisation et diplomatie ; réservistes occupés | T-056, T-056 bis |
| K-7 Date de départ (R-13) | T-057 |

## 4. Décisions de direction sur la phase 1 (15/11/2026)

Réponses du directeur aux questions D-1 à D-4 du rapport `docs/project/MIL01_PHASE1_HISTORICAL_CORRECTIONS.md`.

| ID | Objet | Décision | État |
|---|---|---|---|
| **MIL01-P1-D1** | Puissances sans échelon documenté (France, Russie, Royaume-Uni, Italie, Empire ottoman) | **Appel en bloc unique autorisé.** Il doit être explicitement identifié comme une **approximation non documentée historiquement**. **Aucun sous-échelon ne doit être inventé.** | D (base : `mobilization_echelons.fallback`) ; implémentation en phase 2 |
| **MIL01-P1-D2** | Plafonds de l'Allemagne (4 610 000) et de l'Italie (1 300 000) | **Conservés provisoirement.** On considère que ces totaux incluent **probablement** l'armée active. L'incertitude reste explicite dans les données et la documentation ; la lecture n'est jamais présentée comme établie. | D, I (données, phase 1) |
| **MIL01-P1-D3** | Réserves de la France et de la Russie | **Conservées** (tableau p. 9). Aucun relèvement sans nouvelle source fiable. | D, I (aucun changement) |
| **MIL01-P1-D4** | Sources inaccessibles | Poursuivre les recherches de versions consultables. Si elles restent inaccessibles, ne pas bloquer le développement. Ne tirer **aucune conclusion de leur seule présence bibliographique**. Signaler les documents qui exigent une consultation manuelle. | D : liste dans `docs/history/BIBLIOGRAPHIE.md`, section « Consultation manuelle nécessaire » |

**Consignes associées :**
- ne pas créer de coûts économiques fictifs tant que le système économique correspondant n'est pas défini ;
- ne pas modifier les mécanismes du jeu avant la validation de la proposition de phase 2 (`docs/project/MIL01_PHASE2_PROPOSAL.md`).

## 5. Décisions de direction sur la proposition de phase 2 (15/11/2026)

Réponses du directeur aux questions Q1 à Q10 de `docs/project/MIL01_PHASE2_PROPOSAL.md`.

| ID | Décision | État (phase 2) |
|---|---|---|
| **Q1** | Posture accélérée **reportée**. Elle devra être liée à un coût économique réel. | D ; posture absente du jeu (testé) |
| **Q2** | Trois postures (Paix, Préparatoire, Générale) et trois allocations (administration, chemins de fer, logistique) **validées**. Les effets doivent être clairement définis, sans coût économique fictif. | D, I, T |
| **Q3** | Information publique : posture et ouverture des échelons. Les volumes restent confidentiels, accessibles seulement par le renseignement. | D, I, T. Aucun mécanisme de renseignement ne révèle encore les volumes (INT-01/02 ouverts). |
| **Q4** | Un district occupé sans communication accessible avec le territoire national **ne fournit pas** ses réservistes. | D, I, T |
| **Q5** | Les territoires alliés servent de voie terrestre s'il existe une liaison continue. Communications maritimes exclues pour le moment. | D, I, T |
| **Q6** | Suivi national des pertes et des prisonniers **dès la phase 2**, rigoureux et cohérent avec les effectifs. | D, I, T. Voir `docs/military/PERTES_ET_PRISONNIERS.md`. |
| **Q7** | Le délai d'un mois est un **repère allemand**, non une règle universelle. Paramètres nationaux différenciables ; valeurs provisoires signalées. | D, I, T |
| **Q8** | Aucune nouvelle armée de réserve dans une région où une bataille est en cours. | D, I, T |
| **Q9** | Anciennes sauvegardes refusées avec un message explicite si aucune migration fiable n'est possible ; migration préférée si elle est sûre. | D, I, T. Refus : migration jugée non fiable (voir le rapport de phase 2). |
| **Q10** | Délai minimal provisoire d'un mois entre deux échelons, réglable. | D, I, T |

**Précisions associées :**
- paramètres nationaux configurables : capacité administrative, organisation des réserves, capacités ferroviaires, logistique, rythme ;
- les lacunes documentaires ne deviennent pas des certitudes ;
- aucune capacité ferroviaire historique n'est calculée, puisque la carte indique seulement la présence d'une liaison ;
- catégories de suivi : actifs, réservistes non appelés, en cours, incorporés, présents, morts, blessés, prisonniers ;
- les prisonniers ne sont pas des morts, et les blessés ne disparaissent pas définitivement ;
- aucun système médical ou de captivité complexe en phase 2 : comptabilité fiable, puis évolutions documentées.

## 6. Décisions de direction sur la phase 2 (15/11/2026)

Réponses du directeur aux trois questions du rapport `docs/project/MIL01_PHASE2_REPORT.md` §9. La phase 2 est **validée**.

| ID | Décision | État |
|---|---|---|
| **MIL01-P2-D1** | **Retard ferroviaire à zéro** tant que les données ferroviaires de la carte ne sont pas vérifiées et complétées. L'allocation ferroviaire reste dans l'interface et le système, sans pénalité artificielle fondée sur des lacunes cartographiques. Il faut documenter ce qui fonctionne et ce qui dépend de l'amélioration de la carte. | D, I (`rail_gap_months = 0`) |
| **MIL01-P2-D2** | **Survivants d'une armée anéantie.** Ils sont prisonniers **seulement si une capture effective est établie**, notamment à la capitulation d'une armée encerclée. Les effectifs disparus d'une armée anéantie ne deviennent pas automatiquement des prisonniers. Il faut distinguer les **pertes**, les **prisonniers** et les **soldats qui ont rejoint leur territoire**. | D, I, T (phase 3, correctif préalable ; voir `docs/military/PERTES_ET_PRISONNIERS.md`) |
| **MIL01-P2-D3** | **Blessés et tués** : recherches historiques prévues en **phase 5**. Il faut rechercher des proportions documentées de tués, blessés et disparus, en tenant compte autant que possible des périodes, des types d'engagement et des puissances. Aucune proportion prétendument historique sans sources suffisantes ; le système actuel reste provisoire d'ici là. | D (planifié en phase 5) |

**Consigne associée :** faire une vérification visuelle réelle de l'onglet Armée avant la phase 3.

## 7. Décisions de direction sur la phase 3 (15/11/2026)

La phase 3 est **validée**. Ces trois décisions portent sur des **travaux futurs** : aucune n'est intégrée à la phase 4, et le système diplomatique n'est pas modifié.

| ID | Décision | Inscription |
|---|---|---|
| **MIL01-P3-D1** | La **spirale d'escalade** n'est pas acceptable dans la version finale. Il faut un futur mécanisme de **désescalade diplomatique**, qui réduise progressivement la mobilisation quand les menaces disparaissent. **Une paix ne provoque pas automatiquement une démobilisation complète** : chaque gouvernement évalue les risques qui subsistent. | Phase ultérieure « diplomatie et comportement stratégique de l'IA » (DIP-01 à DIP-04, AI-01, AI-02). Lacune documentée dans `docs/military/MOBILISATION_IA.md` §5. |
| **MIL01-P3-D2** | La guerre d'un allié **ne suffit pas** à déclencher une mobilisation générale. Il faut une **réaction graduée** : allié en guerre ou en crise → posture préparatoire possible ; menace directe ou risque sérieux d'implication → mobilisation générale possible ; pas de menace significative → paix. Elle dépend de la doctrine, des relations diplomatiques, de la proximité de la menace et des engagements. Un pays peut soutenir un allié **diplomatiquement** sans mobiliser. | Même phase ultérieure, car elle exige des relations et des engagements diplomatiques (DIP). **Non intégrée en phase 4.** Le comportement actuel (un allié en guerre vaut 30 points, ce qui suffit pour la posture générale de trois puissances) reste en place et documenté. |
| **MIL01-P3-D3** | Améliorer progressivement les doctrines à partir de **sources historiques** : plans de mobilisation de 1914 et chronologies de l'été 1914 pour les sept puissances. Il faut distinguer rigoureusement les comportements **documentés**, les **interprétations** historiques et les **paramètres de jeu**. | Plan de recherche préparé : `docs/history/RECHERCHE_DOCTRINES_1914.md`. Il ne retarde pas la phase 4. |

**Phase 4.** Elle est consacrée à la Territorial Force (T-050, T-054), implémentée. Voir `docs/military/TERRITORIAL_FORCE.md` et `docs/project/MIL01_PHASE4_REPORT.md`.

## 8. Phase 6, étape 1 : comptabilité des pertes (15/11/2026)

**Décisions du directeur** (autorisation de l'étape 1) :
- quatre catégories : tués, blessés, disparus, prisonniers ;
- environ 10 % des blessés légers restent dans leur unité. L'efficacité réduite n'est **pas** appliquée : elle demande une règle tactique ;
- convalescence d'un mois pour les blessures légères, de trois mois pour les autres ;
- retour au service : 1 sur 1,8. Ce taux est sourcé pour le Royaume-Uni ; pour les autres puissances, c'est une approximation signalée ;
- inaptitude définitive : 17 % ;
- disparus sans conversion automatique ;
- prisonniers comptés chez l'origine et chez le détenteur, sans libération pour l'instant ;
- volume des pertes et règles de combat **inchangés**.

**État :** D, I, T. Voir `docs/project/MIL01_PHASE6_STEP1_REPORT.md` et `data/rules/forces_rules.json`, bloc `casualties`.

**Paramètres provisoires appliqués sans validation explicite**, signalés dans le rapport :
- part des tués : 0,25 ;
- disparus au feu : 0,05 ;
- prisonniers en déroute selon l'issue : 0 / 0,3 / 0,8 (proposition Q6) ;
- part des blessés légers : 0,686, dérivée des listes allemandes.

## 9. Phase 6, étape 1 : corrections ciblées (16/11/2026)

L'étape 1 est **validée dans son ensemble**. Décisions du directeur :

| N° | Décision | État |
|---|---|---|
| **MIL01-P6-C1** | **Solution A.** Les pertes de déroute d'un camp qui remporte la bataille et conserve le terrain sont ventilées comme des **pertes ordinaires**, avec leur origine conservée. Prisonniers seulement en cas de capture effective ou d'effondrement ; une déroute n'est pas une capture ; traitement distinct des unités anéanties. | D, I, T. Le traitement de la déroute des unités anéanties d'un vainqueur est **à valider** (rapport §10.2). |
| **MIL01-P6-C2** | Les quelque 27 % de blessés ni rendus ni inaptes restent en **convalescence de longue durée** : pas de délai de retour, pas d'inaptitude, comptés dans les effectifs nationaux. Évolution étudiée ultérieurement. | D, I, T |
| **MIL01-P6-C3** | Le chiffre de **68,6 %** de blessés légers n'est **pas validé**. Il faut l'examiner sans le modifier. | Examiné (rapport §12) : approximation historique, source allemande unique ; valeur inchangée |
| **MIL01-P6-C4** | **Validation provisoire :** 25 % de tués et 5 % de disparus parmi les pertes ordinaires ; 0 / 30 / 80 % de prisonniers ; 55,6 % de retours ; 17 % d'inaptes ; reste en longue durée. Ces valeurs restent configurables. | Statuts reclassés dans `forces_rules.json` (sourcé, approximation historique, décision, conception) |
| **MIL01-P6-C5** | Aucune baisse d'efficacité des blessés légers restés dans leur unité. À étudier à l'**étape 2**. | Comportement inchangé |
| **MIL01-P6-C6** | **Prisonniers et diplomatie :** rien d'implémenté. **Évolutions futures du système diplomatique :** échanges de prisonniers, libérations négociées, rapatriement après la paix. | Inscrit ici et dans `docs/diplomacy/OVERVIEW.md` §9 |


## 10. Phase 6, étape 2 : types d'engagement et largeur du front (16/11/2026)

**Mandat du directeur :** étape 2 autorisée intégralement, sans équilibrage définitif des pertes (étape 3).

| Élément | Contenu | État |
|---|---|---|
| **T-055 (choix C)** | L'attaquant choisit son approche (reconnaissance en force, attaque limitée, assaut) dans l'ordre de déplacement. Le défenseur choisit sa posture (retarder, tenir, tenir à tout prix), ordre permanent par armée. Ces choix changent des règles (part engagée, rupture du combat, déroute, objectifs, charges, retranchement, occupation), jamais un multiplicateur de pertes. | D, I, T, F |
| **T-048 (choix D)** | Quatre types (escarmouche, engagement limité, assaut frontal, grande bataille au-delà de 200 000 hommes) : matrice des choix, corrigée par les circonstances (effectifs, terrain, fortifications, moral, encerclement), puis réévaluée (renforts, rupture précoce). | D, I, T, F |
| **Largeur du front** | Secteur de combat (km) selon le type, la géométrie de la région et le terrain ; seuls les soldats en ligne combattent ; les unités au contact sans place attendent et relèvent les unités épuisées. | D, I, T, F |
| **Blessés légers** (décision de l'étape 1) | Efficacité réduite à 50 % jusqu'à leur guérison (un mois) ; effectif administratif inchangé. | D, I, T, F |
| **Valeurs** | Toutes les valeurs sont des paramètres de CONCEPTION PROVISOIRES (`combat_rules.json`, bloc `engagement`). | P ; questions E1 à E5 du rapport |

Rapport : `docs/project/MIL01_PHASE6_STEP2_REPORT.md`.
