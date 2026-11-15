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
| T-047 | Effectifs historiques | Armées actives de 1914 au départ ; réserves mobilisables progressivement ; cinq catégories distinctes | Complète MIL-01 et MIL-02 | D, I partielle (la sixième grandeur, les pertes, manque), T en temps de paix |
| T-048 | Intensité des combats | **D** : intensité variable selon le type d'engagement | Précise MIL-06 et T-042 | D ; non implémentée |
| T-049 | Vitesse de mobilisation | **B** : réaliste et flexible | Précise MIL-02 | D ; non implémentée (rythme identique pour tous) |
| T-050 | Territorial Force britannique | **B** : catégorie militaire distincte | — | D ; non implémentée |
| T-051 | Plafond de mobilisation | **C** : mobilisation progressive par échelons | Audit K-1 | D ; données d'échelons en base (phase 1, partielles : 2 puissances sur 7) ; moteur non implémenté |
| T-052 | Mobilisation de l'IA | **D** : doctrine nationale et réaction au contexte stratégique | Audit K-3 | D ; non implémentée |
| T-053 | Influence du joueur | **C** : posture générale et allocation de moyens | Audit K-2 | D ; non implémentée |
| T-054 | Territorial Force : emploi | **B** : déploiement outre-mer volontaire | Audit K-4 | D ; non implémentée |
| T-055 | Type d'engagement | **C** : choix de l'attaquant, posture du défenseur, combinés aux circonstances | Audit K-5 (en partie) | D ; non implémentée |
| T-056 | Mobilisation en temps de paix | **A** : libre, sans pénalité diplomatique automatique, publiquement visible | Audit K-6 (1re question) | D ; partielle (libre et sans pénalité ; **pas de visibilité publique**) |
| T-056 bis | Réservistes en territoire occupé | **B** : rejoignent leur armée si une voie de communication reste accessible, sinon bloqués | Audit K-6 (2e question) | D ; partielle (blocage seulement) |
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
