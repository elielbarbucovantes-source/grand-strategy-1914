# Livrable 1 — État général du projet (audit approfondi du 14/11/2026)

- **Base auditée :** `consolidate/phase-1` (`f81c3d9`), construite sur la cartographie validée `40a3117` ; lignée du 31/10 (`1ec985f`, `2a341d1`, `cdd3ab1`) ; sauvegardes locales.
- **Méthode :** lecture des deux historiques, exécution des validateurs et des scripts `tools/audit/*.py` (lecture seule), tests et simulation du prototype sur une extraction jetable, vérification des sources officielles en ligne.
- **Statut :** constat technique. **Aucune décision de conception n'est prise ici.**

## 1. Classement

| Catégorie | Éléments | Preuves |
|---|---|---|
| **Validé** (directeur) | 69 décisions cartographiques MAP-DEC-01 à 69 ; vision, piliers, 7 puissances jouables ; tour mensuel à ordres secrets simultanés ; gel du gameplay (GATE-01) ; principe des pertes définitives ; ADR 0001 à 0004 « acceptées » (lignée du 31/10) | `docs/decisions/DECISIONS_PENDING.md` §A, C, E, J ; `PROJECT.md` §18 ; `docs/decisions/README.md` |
| **Fonctionnel et testé** | Géométrie des 90 régions (BLK-001, BLK-002, MAJ-003 Strumica, MAJ-004) et topologie (184 arêtes, 10 + 3 détroits) ; reconstruction octet pour octet sur deux machines | `tools/map/validate_all.sh --full` ; CI runs `43603312538` et `43603309751` |
| **Fonctionnel hors périmètre** | Prototype Python : 24/24 tests, déterministe ; **non conforme** à la conception actuelle | `docs/project/PYTHON_PROTOTYPE_INVENTORY.md` |
| **Documenté seulement** | Architecture Godot 4.7.2 / GDScript (proposition) ; tous les systèmes de jeu (vues d'ensemble par domaine) ; T-029 (document de travail) | `docs/architecture/TECHNICAL_ARCHITECTURE.md`, `docs/*/OVERVIEW.md` |
| **Incomplet** | Réseau maritime (voir §2) ; couches thématiques non consolidées (villes hors lignée de référence, terrain et infrastructures restés dans les lots) ; attributs dérivés obsolètes dans 20 régions | Livrable 4 |
| **Contradictoire** | R-01 à R-14 (deux contradictions nouvelles : R-13 date de départ, R-14 piliers) | Livrable 3 |
| **Non commencé** | Données historiques (démographie, économie, armées) ; code de jeu ; prototypes techniques neutres ; licence du projet | — |
| **Bloqué par une décision** | Distribution des données (audit des licences remis au directeur ; décision U1) ; découpage maritime occidental (MAP-OPEN-08) ; T-029 ; moteur ; R-03, R-05, R-13 avant la phase de données | `QUESTIONS_DIRECTEUR.md` |

## 2. Faits majeurs établis pendant l'audit

1. **Le réseau maritime n'existe que pour le Nord et le Sud-Est.**
   - Les 16 zones forment **trois composantes disjointes** : (a) Atlantique Nord, Norvège, Barents, mer du Nord orientale, Skagerrak, Baltique et golfes ; (b) Otrante, Ionienne, Égée, Marmara, mer Noire et Azov ; (c) Caspienne.
   - Aucune zone ne couvre la Manche, la mer du Nord occidentale et méridionale, la mer d'Irlande, l'Atlantique (Gascogne, Ibérie), Gibraltar, la Méditerranée occidentale, la Ligurie, la Tyrrhénienne ni l'Adriatique Nord.
   - C'est la cause des **26 façades orphelines** : pour chacune, la zone la plus proche est à plus de 145 km. Il ne s'agit pas d'oublis isolés.
2. **`mz_norwegian_sea` n'est pas invalide dans sa source.**
   - Elle est valide en WGS 84. L'auto-intersection apparaît seulement après reprojection en EPSG:3035 d'arêtes longues et rectilignes (point 4,67°E et 61,02°N).
   - Une densification à 0,25° la rend valide sans changer le tracé.
   - Effet testé sur une copie : aucun lien ajouté ni retiré.
3. **La région 051 (Islande) est reliée géométriquement** à `mz_north_atlantic_iceland`. Son « isolement » ne concerne que le graphe terre et détroits. C'est une question de modèle (le mouvement naval fait-il partie du graphe jouable ?), pas une erreur de données.
4. **Les 175 villes (`4dbf4f8`) sont toutes correctement rattachées** sur la géométrie validée : 0 changement, 0 ville hors région, 0 doublon. Huit capitales portent un **nom composite** (par exemple « Bucarest (Ploiești) ») qui mélange plusieurs sites.
5. **Le mois de départ de la campagne n'est fixé nulle part.** Le fondateur dit « 1914 », l'atlas photographie le 1/1/1914 et le prototype commence en juin 1914 (R-13).
6. **Les notes de recherche sur les ressources** (hors Git, `~/backups/gs1914-2026-11-13/sources/research_notes/`) emploient une numérotation provisoire des régions **incompatible** avec `region_plan.csv` (leur « 001 » est l'Écosse). Elles ne sont pas exploitables sans table de correspondance.
7. **Godot 4.7.2 stable existe** (sortie le 18/08/2026, godotengine.org). Il n'est pas installé sur le poste.

## 3. Erreurs relevées dans la documentation existante

| Document | Erreur | Traitement (lot 1) |
|---|---|---|
| `PROJECT_HANDOVER_AUDIT.md`, dossier de reprise | « Auto-intersection » de `mz_norwegian_sea` présentée comme un défaut de la source | Explication au livrable 4 |
| `RAPATRIEMENT_LIGNEE_OCT31.md` §6 (phase 1) | R-06 classée contradiction ; or `PLAYABLE_POWERS.md:44` reprend D-028 | Erratum ajouté |
| `docs/map/ATLAS_BUILD_STATUS.md`, `data/world/map/README.md` | « Atlas non construit » | En-tête « obsolète » |
| `docs/map/TECHNICAL_SPEC.md` §10 | « Archive REGIS… non importée » | Note d'erratum (les MAP-DEC sont intactes) |
| `PROGRESS.md` | « Hors Strumica » ; état antérieur à la topologie | Mis à jour |
| `CHANGELOG.md` | Aucune entrée pour la phase 1 | Mis à jour |
| `docs/map/audit/ISSUES.json` | Aucun champ de statut | `docs/map/audit/ISSUES_STATUS.md` |
| `docs/map/corrections/STRUMICA_FINAL_RESOLUTION.md` | 6 liens `file://` et `conversation://` (artefacts d'agent) | Note d'erratum (le rapport validé n'est pas réécrit) |

## 4. Reproduire

```bash
tools/map/validate_all.sh --full
~/.venvs/gs1914-gis/bin/python tools/audit/map_audit.py --cities-ref 4dbf4f8
python3 tools/audit/link_check.py
```
