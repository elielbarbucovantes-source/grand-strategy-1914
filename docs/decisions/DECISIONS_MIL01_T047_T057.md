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
| T-051 | Plafond de mobilisation | **C** : mobilisation progressive par échelons | Audit K-1 | D ; non implémentée |
| T-052 | Mobilisation de l'IA | **D** : doctrine nationale et réaction au contexte stratégique | Audit K-3 | D ; non implémentée |
| T-053 | Influence du joueur | **C** : posture générale et allocation de moyens | Audit K-2 | D ; non implémentée |
| T-054 | Territorial Force : emploi | **B** : déploiement outre-mer volontaire | Audit K-4 | D ; non implémentée |
| T-055 | Type d'engagement | **C** : choix de l'attaquant, posture du défenseur, combinés aux circonstances | Audit K-5 (en partie) | D ; non implémentée |
| T-056 | Mobilisation en temps de paix | **A** : libre, sans pénalité diplomatique automatique, publiquement visible | Audit K-6 (1re question) | D ; partielle (libre et sans pénalité ; **pas de visibilité publique**) |
| T-056 bis | Réservistes en territoire occupé | **B** : rejoignent leur armée si une voie de communication reste accessible, sinon bloqués | Audit K-6 (2e question) | D ; partielle (blocage seulement) |
| T-057 | Début de campagne | **A** : janvier 1914 | **Tranche R-13** ; audit K-7 | D ; non appliquée (le mois reste au choix du joueur dans le code et les données) |

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

**Points non tranchés :** conduite à tenir pour une puissance dont un échelon reste introuvable dans les sources.

### T-052 — Mobilisation de l'IA (choix D)

**Décision.** Chaque pays possède une doctrine de mobilisation, des seuils de menace, des réactions aux mobilisations étrangères, et prend en compte alliances et tensions diplomatiques. **L'IA ne dispose d'aucune information secrète à laquelle elle ne devrait pas avoir accès.**

**Points non tranchés :** contenu des doctrines nationales et valeurs des seuils (seront PROPOSÉS et, autant que possible, sourcés).

### T-053 — Influence du joueur (choix C)

**Décision.** Le joueur choisit une posture de mobilisation, puis répartit ses moyens administratifs, ferroviaires et logistiques. Les conséquences économiques et diplomatiques doivent être cohérentes avec ses choix.

**Points non tranchés :**
- liste des postures ;
- nature des coûts : le modèle économique (R-03, ECO-01, ECO-02, ECO-05) n'est pas défini.

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
- le code (`src/ui/main.gd`, `src/core/game_calendar.gd`), les données (`data/rules/game_rules.json`, `data/scenarios/*.json`), les tests (`tests/unit/test_world_and_state.gd`) et la documentation (`docs/history/MIL01_METHODE.md` §8) indiquent encore « R-13 ouvert ». Ils seront mis à jour dans la phase concernée, pas par ce registre.

**Points non tranchés :** le bac à sable fictif doit-il garder un mois au choix ?

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
