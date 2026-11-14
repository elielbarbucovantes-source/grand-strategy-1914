# Inventaire technique du prototype Python (`archive/oct31-mvp-playable`)

- **Date :** 14 novembre 2026 (phase 1, section 5 de la mission)
- **Objet :** `cdd3ab1` (branche `archive/oct31-mvp-playable`), construit le 31/10 et le 01/11/2026, avant le gel du gameplay (GATE-01).
- **Statut du prototype :** **référence d'étude archivée** (orientation du directeur du 14/11/2026). Il n'est ni supprimé, ni converti, ni fusionné, ni poursuivi. ADR-0006 conserve son statut historique.
- **Méthode :** extraction par `git archive cdd3ab1` dans un répertoire jetable, hors du dépôt. Lecture du code, exécution des tests, simulation sans interface. **Aucune ligne du prototype n'a été modifiée ni copiée dans la lignée de référence.**
- **Convention :** **[MESURÉ]** signale un résultat obtenu par exécution ou comptage. **[ESTIMÉ]** signale un jugement d'ingénieur, non mesuré.

---

## 1. Architecture réelle

**Pile [MESURÉ] :**
- Python 3.12, **bibliothèque standard uniquement** : `json`, `random`, `http.server`, `unittest`… Aucune dépendance externe.
- Interface web servie par le même processus (`ThreadingHTTPServer` sur `127.0.0.1:8765` par défaut), en SVG et JavaScript natif.

**Volume [MESURÉ] :** le chiffre de « ~11 000 lignes » du dossier compte le diff complet, documentation et données comprises. Le code en représente une partie :

| Partie | Fichiers | Lignes |
|---|---|---|
| Moteur Python (`game/*.py`) | 15 | ≈ 3 300 |
| Interface web (`app.js`, `style.css`, `index.html`) | 3 | 1 760 |
| Tests (`tests/test_engine.py`) | 1 | 282 |
| Outil (`tools/generate_map.py`) | 1 | 397 |
| Données (`game/data/*.json` : carte, nations, technologies, événements, config) | 5 | 108 Ko (≈ 5 000 lignes) |
| Documentation modifiée ou ajoutée | 24 | le reste du diff |

**Organisation des modules :** des fonctions pures sur un état sérialisable.

```
__main__ → server (HTTP + JSON) → engine.end_turn / build_view
engine → economy, military, diplomacy, research, events, ai, effects
scenario (chargement des données JSON) → model (GameState, Nation, Province, Army, Treaty : dataclasses + to_dict/from_dict)
storage (sauvegardes JSON locales)
```

**Propriétés notables :**
- Séparation nette entre simulation et interface : `engine` ne connaît pas le serveur.
- Paramètres numériques externalisés dans `config.json`, marqué `provisional`.
- Hasard **dérivé d'une graine** : `random.Random(f"{seed}:{turn}")` à chaque tour.
- Vue filtrée par nation (`build_view`).

## 2. Systèmes effectivement fonctionnels

Une fonction est dite « présente » quand le code existe et qu'il est exercé par un test ou par la simulation sans interface. Cela n'en fait pas une mécanique validée.

| Système | État constaté | Remarque |
|---|---|---|
| Tour mensuel, ordres simultanés | Présent | Résolution séquentielle par phases dans `end_turn` |
| Carte | Présente, **synthétique** | **90 provinces hexagonales** (grille 38 × 26) générées par `tools/generate_map.py`, avec des noms propres au prototype (« Tirana », « Bohême »…). Elle **n'utilise pas** l'atlas validé (`regions.geojson`, `adjacency.json`). |
| Économie | Présente | Nourriture, matières premières, richesse, main-d'œuvre ; construction et recrutement en file d'attente |
| Militaire | Présent | Infanterie, artillerie, cavalerie ; bataille **résolue automatiquement** ; terrain, fortifications, retranchement, ravitaillement et attrition |
| Batailles tactiques | **Absentes** | Aucun mode tactique |
| Diplomatie | Présente, simple | Relations numériques, traités, alliances défensives et offensives en cascade, guerre et paix |
| Mémoire, confiance, tromperie de l'IA | **Absentes** | Aucune trace de mémoire, de réputation ou de mensonge dans le code |
| IA | Présente, simple | Règles et probabilités selon une `personality` ; estime la force ennemie **uniquement sur les provinces visibles** (respect du brouillard pour cette estimation) |
| Brouillard de guerre | Présent | `visible_provinces`, testé |
| Recherche | Présente | Prérequis, limite d'année, coût ajusté |
| Événements historiques | Présents | Sarajevo avec choix ; chaînes pouvant déclencher une guerre |
| Victoire | Présente | Territoriale (90 %), « diplomatique » (70 %), économique (meilleur indice pendant 18 tours) |
| Sauvegarde et chargement | Présents | JSON, aller-retour testé |
| Mode observation, prise de contrôle | Présents | `take_control` |

## 3. Tests

**[MESURÉ]** `python3 -m unittest tests.test_engine -v` : **24 tests, 0 échec, 1,6 s**, couvrant :
- le scénario ;
- l'économie ;
- le militaire (dont le brouillard et le ravitaillement) ;
- la diplomatie ;
- la recherche ;
- les événements ;
- l'IA (légalité des ordres, longue partie) ;
- la victoire ;
- la sauvegarde.

**[MESURÉ]** La commande documentée dans `tests/README.md` (`python3 -m unittest discover -s tests -v`) **échoue** (`Start directory is not importable`), car `tests/` ne contient pas de `__init__.py`. Défaut de documentation mineur.

**[MESURÉ]** Déterminisme : deux parties d'observation avec la graine 1914 donnent un état final **identique** (SHA-256 de l'état sérialisé `7b19a00a…`). Une autre graine donne un état différent. Il faut environ 4,1 s pour 31 tours sans interface.

**[MESURÉ]** Équilibrage : la partie d'observation (graine 1914) s'achève **au tour 31 (janvier 1917) sur une victoire économique de l'Empire ottoman**. Ce résultat est peu crédible historiquement. Il illustre le caractère provisoire des paramètres et n'est pas un défaut de code.

Aucun test ne couvre :
- l'interface web ;
- le serveur HTTP ;
- les propriétés de non-omniscience de l'IA au-delà de l'estimation de force ;
- la conformité aux données historiques.

## 4. Qualité générale du code [ESTIMÉ, sur lecture]

**Points forts :**
- Code lisible, typé (annotations, `from __future__ import annotations`), modules courts (moins de 550 lignes).
- Fonctions sans effet de bord caché, état sérialisable, paramètres hors du code.
- Aucun `TODO`, et une seule capture d'exception large (serveur).
- Serveur limité à `127.0.0.1` par défaut.

**Limites :**
- Logique concentrée dans des fonctions procédurales sans interfaces : il n'y a pas d'équivalent de `NationAgent` ni de `SaveRepository`.
- Couplage par accès direct au `GameState` global : l'IA peut lire tout l'état. Seule l'estimation de force passe par le brouillard.
- Pas de versionnement des schémas de sauvegarde, au-delà d'un champ `version`.
- `config.json` est chargé à de multiples endroits (`load_config()` dans les fonctions).
- Interface en un seul fichier JavaScript de 1 040 lignes.

**Verdict :** un prototype propre et cohérent pour sa taille, adapté à l'exploration. Ce n'est **pas** une base d'architecture pour le jeu cible tel que décrit dans `TECHNICAL_ARCHITECTURE.md`.

## 5. Éléments conformes à la vision actuelle

- Tour mensuel et ordres simultanés (D-006, TURN-02).
- Sept puissances jouables et États IA autonomes (D-005).
- Trois ressources nourriture, matières premières et richesse, stock national (PROJECT.md §10).
- Brouillard de guerre ; IA qui estime la menace sur ce qu'elle voit.
- Seuil de victoire territoriale à 90 % (MAP-DEC-13).
- Mode observation et prise de contrôle (PROJECT.md §18).
- Hasard reproductible par graine (orientation D4 de T-029, non validée).
- Séparation entre simulation et interface.

## 6. Éléments en contradiction avec les décisions actuelles

| # | Prototype | Décision ou référence | Gravité |
|---|---|---|---|
| P-01 | **Moral des armées** (`morale`, `morale_loss_defeat`, `morale_gain_victory`) | D-016 : moral **non retenu** ; dossier §8.6 : pas de moral sans décision explicite | Contradiction directe |
| P-02 | Début en **juin 1914** (`config.start`) | Situation de référence au **1er janvier 1914** (atlas, MAP-DEC) | Contradiction |
| P-03 | Carte hexagonale synthétique de 90 provinces | Atlas validé de 90 régions (géométrie, topologie, 69 MAP-DEC) | Incompatible : à remplacer, pas à adapter |
| P-04 | Batailles **automatiques uniquement** | D-013/D-014 : offensives → bataille tactique (30 min max) ; T-029 ouvert | Fonction centrale absente |
| P-05 | Victoire « **diplomatique** » à 70 % | PROJECT.md §17 : victoire **collective** (traité signé par tous) ; tension R-04 | Contradiction |
| P-06 | Victoire économique : meilleur « indice » pendant 18 tours | Victoire socio-économique par IDH relatif, formule À DÉFINIR | Choix arbitraire non validé |
| P-07 | IA sans mémoire, sans mensonge ni manipulation | D-011, PROJECT.md §16 : mémoire longue, tromperie, trahison | Pilier « IA crédible » non couvert |
| P-08 | Valeurs numériques (`config.json`) | NAT, ECO et MIL À DÉFINIR ; « ne pas inventer de statistiques » | Données provisoires non sourcées |
| P-09 | 22 nations avec statistiques, ambitions et personnalités | NAT-01 à 05 À DÉFINIR ; tension R-05 (échelle de 1 à 10) | Données non validées |

## 7. Concepts réutilisables indépendamment du langage

Ces concepts sont réutilisables **comme idées**. Aucun code n'est à reprendre en l'état.

1. **Graine par tour** (`Random(f"{seed}:{turn}")`) : reproductibilité sans état de générateur à sauvegarder. Elle est compatible avec un journal de commandes.
2. **État entièrement sérialisable** (`to_dict`/`from_dict`) et **vue filtrée par nation** (`build_view`) : préfigure le contrat « simulation pure + vue par observateur ».
3. **Paramètres externalisés et marqués `provisional`**, avec renvoi à des hypothèses H-xxx : bonne pratique de traçabilité.
4. **Ordres validés avant application** (`validate_move`, `can_enter`, test « ordres IA légaux ») : base du futur contrat d'ordres.
5. **Cascade d'alliances défensives et offensives** : schéma de résolution simple à confronter aux règles DIP.
6. **Événements à conditions, cibles et options**, avec choix IA pondéré : format de données réutilisable pour le catalogue d'événements.
7. **Batterie de tests de scénario** (longue partie IA, aller-retour de sauvegarde, victoire) : catalogue de cas de test à reproduire.

## 8. Coût relatif : poursuite en Python ou reconstruction sous Godot [ESTIMÉ]

**Avertissement :** il ne s'agit **pas** d'une mesure. Aucun prototype Godot n'existe et Godot n'est pas installé. Les comparaisons sont qualitatives et relatives. Elles servent à éclairer la décision, pas à la justifier.

| Critère | Poursuite en Python (prototype) | Reconstruction sous Godot 4.7.2 / GDScript |
|---|---|---|
| Code réutilisable pour le jeu cible | **Faible**. P-01 à P-09 imposent de refaire la carte, la bataille, l'IA (mémoire) et les données. Le moteur de tour est réutilisable en partie, en idées. | Nul en code, mais les concepts du §7 se transposent |
| Atlas validé (géométrie de 17 Mo, 90 régions) | Rendu SVG du GeoJSON dans le navigateur à construire ; faisable, performances à vérifier | Import par un outil (GeoJSON → polygones ou ressources) à construire ; rendu 2D natif |
| Batailles tactiques en temps réel (D-014) | **Coût élevé** : moteur temps réel à écrire dans le navigateur (canvas/WebGL) et synchronisation avec le serveur Python | Cas d'usage naturel d'un moteur de jeu (scènes, physique, rendu, entrées) |
| Interface riche (zoom, calques, figurines, flèches) | Faisable en web, avec beaucoup de code sur mesure | Outils d'interface et de rendu intégrés |
| Tests automatisés sans interface | **Facile** (`unittest`, CI déjà maîtrisée) | Possible (GUT/gdUnit4, mode sans interface), outillage à mettre en place |
| Multijoueur futur | Architecture client-serveur web déjà esquissée | API réseau de haut niveau ; séparation de la simulation à imposer |
| Distribution | Navigateur + processus Python (installation de Python) | Exports natifs multiplateformes |
| Compétences et outillage actuels du dépôt | Python déjà utilisé (outils GIS, CI) | Nouveau runtime à installer et épingler |

**Lecture [ESTIMÉ] :**
- Le prototype démontre la boucle de jeu, mais il n'en fixe ni les règles ni les données.
- Dans les deux voies, l'essentiel du travail futur (atlas jouable, batailles tactiques, IA à mémoire, données sourcées) est **à construire**. L'avantage de départ du prototype porte donc surtout sur le moteur de tour.
- Le facteur le plus discriminant semble être la **bataille tactique en temps réel** et l'interface cartographique riche, qui favorisent un moteur de jeu.
- La **testabilité sans interface** et la proximité avec l'outillage Python actuel favorisent Python.
- Une architecture hybride (simulation Python sans interface et client Godot) est concevable, mais elle ajoute une frontière de processus et deux runtimes.

**Ce qui permettrait de mesurer plutôt qu'estimer** (sur autorisation, sans aucune règle de jeu) :
1. un prototype technique neutre Godot : chargement et rendu de `regions.geojson`, zoom, sélection, temps de chargement et mémoire ;
2. le même essai en SVG/Canvas dans un navigateur ;
3. une bataille fictive en temps réel minimale, dans les deux environnements.

Les mesures comparables (temps de développement, images par seconde, mémoire, lignes de code) alimenteraient une ADR comparative 0007.

## 9. Reproduire cet inventaire

```bash
mkdir -p /chemin/jetable/proto && git archive cdd3ab1 | tar -x -C /chemin/jetable/proto
cd /chemin/jetable/proto
python3 -m unittest tests.test_engine -v          # 24 tests
python3 -m game --help                            # interface : http://127.0.0.1:8765/
```
