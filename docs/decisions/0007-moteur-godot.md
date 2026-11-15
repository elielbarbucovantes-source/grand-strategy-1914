# ADR-0007 — Moteur du jeu : Godot 4.7.2 stable, GDScript typé

> **Statut :** Accepté
> **Date :** 2026-11-15
> **Décideur :** directeur du projet (réponse au questionnaire du 15/11/2026)
> **Auteur :** Claude Code
> **Remplace :** ADR-0003 (report du choix de pile) et ADR-0006 (pile technique du MVP Python)

## Contexte
Le choix du moteur était ouvert (R-01, U6). Mesures du prototype neutre (`docs/project/ENGINE_RECOMMENDATION.md`) :
- Godot 4.7.2 s'exécute sans interface sur le poste de développement ;
- chargement de la carte en 40 ms ;
- calcul de chemin en 0,41 ms ;
- rejeu déterministe vérifié.

## Décision
- **Godot 4.7.2 stable** avec **GDScript typé**, pour la simulation et pour l'interface.
- La simulation est écrite en classes pures (`RefCounted`), sans dépendance aux nœuds de scène, et testée sans interface (`godot --headless`) en CI.
- Ordres et état sérialisables en JSON, pour le déterminisme et l'évolution multijoueur.
- **Python** reste l'outil de la chaîne de données hors ligne : GIS, validateurs, export `data/game/`.

## Conséquences
- ADR-0003 et ADR-0006 passent au statut « remplacé ». Le prototype Python (`archive/oct31-mvp-playable`) reste une référence d'étude archivée.
- La version exacte du moteur est épinglée : 4.7.2-stable, binaire officiel vérifié par SHA-512.
