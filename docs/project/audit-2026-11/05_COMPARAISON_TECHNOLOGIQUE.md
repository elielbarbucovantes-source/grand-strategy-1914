# Livrable 5 — Audit du prototype Python, architecture cible et comparaison des moteurs

- **Statut :** analyse. **Le moteur n'est pas choisi.** Le prototype reste une référence d'étude archivée (orientation du 14/11/2026).
- **Complète** `docs/project/PYTHON_PROTOTYPE_INVENTORY.md` (phase 1). Convention : **[MESURÉ]** pour un résultat obtenu par exécution ou comptage, **[ESTIMÉ]** pour un jugement d'ingénieur.

## 1. Audit technique du prototype (`cdd3ab1`, code lu)

| Domaine | Réalité dans le code | Fonctionnel ou esquissé |
|---|---|---|
| **Architecture** | 15 modules de fonctions (aucune classe de service), état central `GameState` (`model.py` : `Province`, `Army`, `Treaty`, `Nation` en dataclasses avec `to_dict`/`from_dict`) | Fonctionnel |
| **Gestion du temps** | `engine.end_turn()` : (1) événements en attente ; (2) ordres du joueur, puis ordres de l'IA (`ai.ai_orders`) ; (3) économie, construction, recrutement, recherche par nation ; (4) mouvements et batailles (`military.resolve_movement`) ; (5) éliminations ; (6) nouveaux événements ; (7) stabilité et renseignement ; (8) ravitaillement ; (9) victoire ; (10) `next_month()`. Graine `Random(f"{seed}:{turn}")`. | Fonctionnel. **Séquentiel par phases**, pas réellement simultané : les ordres sont collectés puis résolus dans un ordre fixe. |
| **Modèle de données** | Province (propriétaire et contrôleur distincts, terrain, ressource, industrie, fortification, port, agitation) ; armée (infanterie, artillerie, cavalerie, ravitaillement, **moral**, retranchement) ; nation (12 statistiques entières, personnalité, ambitions, colonies, stocks, main-d'œuvre, stabilité, prestige, renseignement, technologies) | Fonctionnel ; valeurs inventées (`config.json` marqué « provisional ») |
| **Économie** | Production provinciale → stock national ; consommation de nourriture par population et par régiment ; entretien ; files de construction et de recrutement | Fonctionnel et simple ; ni marché ni commerce bilatéral |
| **Militaire** | Déplacement d'une province adjacente par tour ; bataille **automatique** (puissance × terrain × fortification × retranchement ; pertes en ratio) ; capture ; retraite ; ravitaillement par connexité ; attrition | Fonctionnel ; **pas de marine** (seul un attribut `navy_quality`), pas de bataille tactique, présence d'un moral (contraire à D-016) |
| **Diplomatie** | Relations numériques de −100 à +100 ; traités (alliance, paix) ; « improve » payant ; cascade d'alliances défensives et offensives | Fonctionnel et simple ; pas de négociation multi-clauses, de mémoire ni de confiance |
| **IA** | Règles et probabilités selon 4 personnalités ; estimation de la menace **sur les provinces visibles** ; plus courts chemins (BFS) | Fonctionnel ; **lit l'état global** pour le reste (diplomatie, économie) ; ni mémoire ni tromperie |
| **Événements** | Catalogue JSON (conditions, cibles, options, effets), choix de l'IA pondéré ; Sarajevo | Fonctionnel |
| **Interface web** | `app.js` (1 040 lignes) : carte SVG hexagonale, panneaux, ordres ; serveur `ThreadingHTTPServer` sur 127.0.0.1 | Fonctionnelle, **non testée** |
| **Tests** | `tests/test_engine.py` : 24 tests, unitaires et de scénario | **[MESURÉ]** 24/24 en 1,6 s. La commande documentée (`discover -s tests`) échoue ; il faut `python3 -m unittest tests.test_engine`. |
| **Dépendances** | Bibliothèque standard uniquement | — |
| **Performances** | **[MESURÉ]** 31 tours en 4,1 s (22 nations, 90 provinces, 67 armées), soit environ 0,13 s par tour | Suffisant à cette échelle |
| **Déterminisme** | **[MESURÉ]** même graine, même état final (SHA-256 `7b19a00a…`) | Fonctionnel |
| **Problèmes** | Partie d'observation terminée au tour 31 (janvier 1917) sur une **victoire économique ottomane** (équilibrage) ; `load_config()` appelé dans chaque fonction ; pas de version de schéma de sauvegarde ; contradictions P-01 à P-09 | — |

**Ce qui est réellement fonctionnel :** une boucle de jeu complète et déterministe, à petite échelle.

**Ce qui est esquissé ou absent :**
- carte réelle ;
- marine ;
- bataille tactique ;
- marché ;
- IA à mémoire et non omnisciente ;
- données sourcées.

## 2. Exigences réelles de l'architecture cible

Sources : `docs/architecture/TECHNICAL_ARCHITECTURE.md`, `PRINCIPLES.md`, dossier §15, MAP-DEC, T-029 (ouvert).

1. Simulation **pure et déterministe**, sans interface, exécutable en CI.
2. Ordres sérialisables, résolution simultanée, **journal de commandes** (rejeu). La forme exacte dépend de T-029, D4.
3. Vue filtrée par observateur (`NationAgent`) : l'IA ne voit que ce que son pays sait.
4. `SaveRepository` avec versions de schéma, de règles et de données.
5. Rendu cartographique de 90 polygones (source de 17 Mo, à **simplifier**), zoom continental à régional, calques, hachures d'occupation, figurines, flèches d'ordres (MAP-DEC-27 à 69).
6. **Bataille tactique en temps réel**, de 30 minutes au plus, dans une interface distincte (D-013, D-014, dossier §8.3).
7. Multijoueur futur : moteur isolé et contrat de session (T-029, D5, proposé).
8. Chaîne de données GIS reproductible, **déjà en Python** et en CI.

## 3. Comparaison

| Critère | Python | Godot 4.7.2 / GDScript typé |
|---|---|---|
| Facilité de développement de la simulation | Élevée **[ESTIMÉ]** | Bonne ; GDScript typé, moins d'écosystème |
| Maintenance | Bonne (typage optionnel, mypy) | Bonne (typage statique de GDScript) ; montées de version de Godot à gérer |
| Performance de la simulation | Suffisante à l'échelle visée **[MESURÉ, prototype]** | Probablement supérieure **[ESTIMÉ]**, à mesurer (NP-3) |
| Gestion des données | Excellente (JSON, GIS, Shapely déjà en place) | JSON natif ; **aucun GIS**, donc import de données prétraitées par Python |
| Interface et carte riche | Navigateur (SVG ou Canvas) : beaucoup de code sur mesure | Rendu 2D, interface, entrées natives |
| Bataille temps réel | Coûteuse (WebGL ou canvas et synchronisation) | Cas d'usage natif |
| Débogage et profilage | Outils Python matures | Débogueur et profileur intégrés à l'éditeur |
| Tests automatisés | `unittest` ou `pytest`, CI déjà opérationnelle | GUT ou gdUnit4 ; mode sans interface en CI, à outiller |
| Architecture de simulation | Facile à isoler | Isolation à **imposer** (le cœur ne doit pas dépendre des nœuds de scène) |
| Évolutivité | Bonne | Bonne |
| Multijoueur | Client-serveur web à construire | API réseau de haut niveau intégrée |
| Coût de développement global | Plus bas pour la simulation, plus haut pour la carte et la bataille **[ESTIMÉ]** | Inverse **[ESTIMÉ]** |
| Dépendances externes | Interpréteur (et navigateur) | Moteur et modèles d'export à épingler (4.7.2 stable, 18/08/2026) |

**Constat certain :** la **chaîne de données restera en Python** quel que soit le moteur. Le choix ne porte que sur le code de jeu et l'interface. Une architecture hybride, avec la simulation dans un langage et l'interface dans l'autre, est possible mais ajoute une frontière de processus.

## 4. Protocole des prototypes techniques neutres

**Règles communes :**
- **aucune règle ni valeur de jeu** ;
- données = géométrie publiée, simplifiée par un script Python commun, plus des jeux synthétiques ;
- même machine, même version de données ;
- résultats dans `docs/project/engine-benchmarks/` ;
- code dans `prototypes/engine-benchmarks/<moteur>/`, supprimable sans perte de conception ;
- autorisation U6 requise.

| ID | Objectif | Protocole | Métriques | Réussite | Temps estimé | Difficultés |
|---|---|---|---|---|---|---|
| NP-0 | Données communes | Script Python : simplification de `regions.geojson` à 1 km et 5 km (topologie préservée), export JSON | Taille, nombre de sommets | Fichiers déterministes | ½ j | Simplification topologique |
| NP-1 | Chargement et affichage de 90 régions | Charger, afficher, zoom continu, sélection au clic, contour de sélection | Temps de chargement, images par seconde au zoom continental et régional, mémoire, lignes de code | < 2 s ; ≥ 60 i/s | 1 à 2 j par moteur | Triangulation des polygones (Godot), performances SVG (web) |
| NP-2 | Calculs de graphe | Dijkstra sur les 184 arêtes et détroits, 10⁴ requêtes | ms par requête | < 1 ms | ½ j | — |
| NP-3 | Simulation d'entités artificielles | 10⁴ entités, mise à jour à pas fixe, sans interface | ms par pas, mémoire | < 16 ms | ½ j | — |
| NP-4 | Sauvegarde, chargement, déterminisme | État synthétique, graine, 100 pas, sauvegarde, rechargement, rejeu | Égalité octet pour octet, durée | Identique | ½ j | Flottants, ordre des dictionnaires |
| NP-5 | Séparation simulation et interface | Cœur exécuté en CI sans affichage ; interface branchée sur une file d'ordres | Tests verts sans interface | Verts | ½ j | Mode sans interface de Godot en CI |
| NP-6 | Scène temps réel | 2 000 figurines de test, déplacement et regroupement par zoom | i/s | ≥ 60 i/s | 1 j | — |

**Total estimé [ESTIMÉ] :** 6 à 8 jours d'agent. **Livrable :** ADR-0007 comparative (mesures, coûts, risques), **soumise** au directeur sans choix pré-rempli.
