
# CHANGELOG

Toutes les évolutions importantes du projet sont consignées ici.

## [1.3] — Intégration des décisions cartographiques et contrats d’affichage

- Intégration individuelle des décisions validées MAP-DEC-27 à MAP-DEC-69, en complément des 26 décisions déjà documentées.
- Audit des contradictions et précisions ouvertes : masquage des noms vs capitales toujours nommées (MAP-OPEN-15), dénominateur de victoire (MAP-OPEN-16), visibilité selon l’observateur et agrégation/présentation (MAP-OPEN-17 à 19).
- Extension du modèle et du schéma structurel aux ressources et infrastructures régionales, préférences d’affichage, flèches d’ordres, unités, renseignement daté, combats, marqueurs d’événements et états maritimes/diplomatiques/logistiques.
- Mise à jour du document maître, de l’état d’avancement, des règles de contribution et du guide des données cartographiques.
- Aucun atlas, région, géométrie, donnée historique ou gameplay créé.

## [1.2] — Décisions cartographiques et préparation de l’atlas

- Intégration des 26 décisions cartographiques validées le 2026-11-01 dans la spécification dédiée et le document maître.
- Clarification de la victoire territoriale : contrôle militaire de 90 % de la carte ; dénominateur exact laissé en attente.
- Ajout d’un modèle de couches pour régions, frontières/topologie, relief, sites, réseaux, fortifications, zones maritimes et états dynamiques.
- Choix de GeoJSON RFC 7946 comme format géographique d’échange et QGIS comme outil recommandé d’édition ; projection de rendu et données sources restent ouvertes.
- Ajout du schéma structurel avec plafond de 100 régions terrestres, sans données ni géométries d’exemple.
- Ajout du flux d’import/édition, de l’inventaire des données nécessaires et de l’analyse des risques du plafond de 100 régions.
- Aucun gameplay et aucune région concrète créés.

## [1.1] — Documentation intégrée et préparation technique

- Intégration du corpus 1.0 dans une arborescence de projet cohérente.
- Harmonisation de `PROJECT.md`, `PROGRESS.md` et `AGENTS.md` avec l’instruction du directeur : aucun développement gameplay avant autorisation explicite.
- Suppression de la contradiction issue des consignes finales demandant une partie jouable immédiatement.
- Ajout de l’architecture technique proposée Godot 4/GDScript, incluant tours simultanés, modules indépendants, données, IA, sauvegarde et multijoueur futur.
- Ajout d’une spécification technique cartographique provisoire qui laisse l’atlas de conception ouvert.
- Création du registre des décisions restant à définir.
- Initialisation d’un dépôt Git local sur `main` et ajout d’une coquille `project.godot` sans scène ni logique de jeu, ainsi que `.gitignore` et des répertoires techniques vides.
- Aucun code de jeu ou mécanique de gameplay modifiés/implémentés.

## \[1.0\] --- Documentation initiale

-   Création du document maître `PROJECT.md`.
-   Formalisation des trois piliers : profondeur stratégique, IA
    autonome, réalisme historique.
-   Définition du périmètre européen et des sept puissances jouables.
-   Formalisation des douze statistiques nationales.
-   Documentation des principes de carte, provinces, zones maritimes et
    villes stratégiques.
-   Validation du tour mensuel et de la résolution simultanée.
-   Formalisation des principes de déplacement, transit et logistique.
-   Formalisation du modèle économique à trois ressources et du stock
    national centralisé.
-   Définition des cinq catégories industrielles.
-   Formalisation de l'organisation militaire hiérarchique et des
    batailles tactiques déclenchées par les offensives.
-   Définition des principes de politique intérieure, recherche,
    renseignement et événements historiques.
-   Formalisation de l'autonomie maximale des États contrôlés par l'IA.
-   Définition des conditions de victoire et des modes de jeu.
-   Ajout des règles de gouvernance et d'utilisation des agents.
-   Ajout des documents de domaine et du prompt OpenCode.

## Convention de version

-   **MAJOR** : modification importante de la vision ou d'une règle
    structurante.
-   **MINOR** : ajout ou modification substantielle d'un système.
-   **PATCH** : correction, clarification ou amélioration documentaire
    sans changement de règle.
