
# CHANGELOG

Toutes les évolutions importantes du projet sont consignées ici.

## [1.7] — Audit approfondi (14/11/2026)

- Livrables `docs/project/audit-2026-11/` : état général, registre des contradictions R-01 à R-14 et des décisions D-001 à D-030, plan cartographique de la phase 2, comparaison technologique et protocole des prototypes neutres, feuille de route, audit de l'alignement de `main`, audit documentaire, questionnaire au directeur.
- Scripts d'audit en lecture seule : `tools/audit/map_audit.py`, `tools/audit/link_check.py`.
- Corrections documentaires : erratum R-06 (contradiction apparente) ; bandeaux « obsolète » ou « historique » sur les documents d'état périmés ; erratum au §10 de `TECHNICAL_SPEC.md` (les MAP-DEC sont inchangées) ; `docs/map/audit/ISSUES_STATUS.md` ; index `docs/README.md` ; `docs/legacy/oct31/LINK_MAP.md`.
- Aucune donnée cartographique, aucune décision ni aucun statut officiel modifiés. Aucune fusion.

## [1.6] — Phase 1 : consolidation technique et documentaire (14/11/2026)

- Environnement GIS durable (`~/.venvs/gs1914-gis`), `tools/map/validate_all.sh`, empreintes de référence et CI GitHub Actions (géométrie et topologie reproduites octet pour octet).
- `AGENTS.md` et `CONTRIBUTING.md` mis à jour sur la lignée cartographique validée.
- Rapatriement octet pour octet de T-029, des ADR 0000 à 0006 et du document fondateur, statuts inchangés.
- Archivage des répertoires obsolètes ; inventaire du prototype Python ; plan d'alignement de `main`.
- Rapport : `docs/project/PHASE_1_CONSOLIDATION_REPORT.md`.

## [1.5] — Sécurisation des acquis et base géographique consolidée

- Sauvegarde locale complète : bundle Git de toutes les branches et worktrees, archive de l’arbre de travail (fichiers suivis et non suivis) et copie des sources externes non versionnées (≈ 373 Mo) ; intégrité vérifiée (bundle restauré par `git clone`, SHA-256 origine ↔ copie identiques).
- Environnement GIS persistant créé dans le projet (`<dépôt>/.venv`) avec versions figées dans `tools/map/requirements.lock` ; `.gitignore` complété (`.venv/`, bytecode, `.consolidation-stage/`, `/backups/`).
- Première base géographique consolidée et versionnée des 90 régions de 1914 : BLK-001 (Saray), BLK-002 (micro-chevauchements) et MAJ-004 (quatre lacunes de couture) reproduites dans le dépôt.
- Extraction de sources minimales versionnées sous `data/world/map/sources/derived/` (Saray, pays 1914, provinces finlandaises RISTAT 1897), vérifiées géométriquement identiques aux originaux, pour rendre la reconstruction autonome sans committer les sources lourdes.
- Ajout de `tools/map/build_source_extracts.py`, `tools/map/consolidate_geometry.sh` et `tools/map/requirements.lock` ; `build_geometry.py` et `close_geometry_gaps.py` restent inchangés.
- Validateurs : 90/90 régions, 90/90 géométries valides, 0 chevauchement > 1e-10 deg², 0/4 lacune MAJ-004, Saray correcte ; reproduction déterministe (artefacts identiques octet pour octet). Strumica (MAJ-003) reste non corrigée (hors périmètre).
- Ajout de `docs/map/audit/DATA_RECOVERY_REPORT.md`, `docs/map/audit/GEOMETRY_CONSOLIDATION_REPORT.md` et `docs/map/corrections/geometry_gaps_report.json`.
- Aucune branche fusionnée, `main` non modifié, aucune source supprimée, aucune donnée thématique modifiée, aucun remote configuré, aucun push. Aucun gameplay créé ou modifié.

## [1.4] — Inventaire et recherche initiale de l’atlas à 90 régions

- Inscription de la répartition cible de 90 régions et des identifiants de travail dans `data/world/map/tables/region_plan.csv`; le pays de Galles est distinct selon clarification du directeur.
- Documentation des sources historiques candidates, périodes, licences connues et limites; aucune donnée externe n’a été intégrée aux fichiers de carte.
- Ajout d’un statut de construction qui distingue l’index éditorial de l’atlas géométrique incomplet et décrit les livrables restants.
- Ajout d’un validateur de l’index et du futur GeoJSON; l’exécution confirme les 90 entrées mais signale que les géométries sont absentes.
- Mise à jour de `PROJECT.md`, `PROGRESS.md`, `AGENTS.md`, du registre et de la spécification cartographique. Aucun gameplay créé ou modifié.

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
