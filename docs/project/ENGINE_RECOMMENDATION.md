# Recommandation de moteur (15/11/2026) — soumise au directeur

**Statut :** PROPOSITION. Le moteur n'est pas encore validé (R-01, U6). Aucun code de jeu dépendant du moteur n'est écrit avant la décision.

## Mesures sur ce poste
- **Godot 4.7.2 stable** : installé depuis la publication officielle (empreinte SHA-512 vérifiée) ; exécution sans interface opérationnelle.
- **Prototype neutre** (`prototypes/engine-benchmarks/godot/np_headless.gd`, GDScript typé, sans interface, sans règle de jeu) :
  - chargement de `data/game/world_map.json` (NP-0, 1,1 Mo) : **40 ms** ;
  - Dijkstra naïf sur le graphe réel (184 arêtes et 10 détroits) : **0,41 ms par requête** (10 000 requêtes) ;
  - 9 776 trajets sur 10 000 aboutis : les échecs sont les paires impliquant la région 051, isolée ;
  - rejeu déterministe à graine identique : **vérifié**.
- **Prototype Python** (`cdd3ab1`) : 0,13 s par tour (22 nations), 24/24 tests (mesures de phase 1).

## Recommandation
**Godot 4.7.2 avec GDScript typé pour tout le jeu (simulation et interface), et Python pour la seule chaîne de données hors ligne** (GIS, export NP-0, validateurs).
- La simulation est écrite en classes GDScript pures (`RefCounted`), sans dépendance aux nœuds de scène. Elle est testée sans interface (`godot --headless`) dans la CI.
- Les ordres et l'état sont des dictionnaires sérialisables en JSON, ce qui assure le déterminisme et prépare le multijoueur.
- **Motifs :**
  - la carte riche et la bataille tactique en temps réel (D-013, D-014, T-029) relèvent nativement d'un moteur de jeu ;
  - un seul runtime de jeu ;
  - les performances mesurées suffisent largement ;
  - le prototype Python n'est pas réutilisable en l'état (contradictions P-01 à P-09).
- **Alternatives écartées :**
  - **hybride** (simulation Python et client Godot) : deux runtimes et une frontière de processus ;
  - **Python web complet** : bataille temps réel et carte riche coûteuses à écrire.
