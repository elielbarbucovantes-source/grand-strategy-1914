# Livrable 2 — Audit des licences et de la provenance des données

- **Date :** 14/11/2026. **Diffusion :** publié avec l'autorisation du directeur (14/11/2026).
- **Décision du directeur (14/11/2026, U1 et U8) :** jeu gratuit et open source au départ, sans commercialisation prévue ; données REGIS conservées (pas de reconstruction des 69 régions) ; attributions autorisées et publiées (`DATA_LICENSES.md`, `NOTICE`) ; avis juridique indépendant avant toute éventuelle commercialisation. Cela correspond à l'orientation **A** (§3) avec avis juridique différé. **Les attributions ne valent pas autorisation commerciale.**
- **Avertissement :** il s'agit d'une analyse technique, **pas d'une certification juridique**. Les points marqués **[AVIS JURIDIQUE]** doivent être soumis à un juriste.
- **Méthode :**
  - inventaire des sources citées dans toutes les branches (registres de sources, `source_refs` et `source_layer` des 90 régions, `SOURCE_EXTRACTS.json`, rapports) ;
  - inspection des fichiers bruts (`~/backups/gs1914-2026-11-13/sources/external/regis/`, 51 fichiers) ;
  - vérification des licences **sur les pages officielles** le 14/11/2026.
- **Distinction appliquée :** pour chaque source, cinq droits sont examinés séparément : (1) utiliser, (2) modifier, (3) redistribuer l'original, (4) redistribuer une version transformée, (5) intégrer dans un produit commercial.

## 1. Constats décisifs

1. **REGIS / REThM : les données sont sous CC BY-NC 4.0**, et non sous CC BY 4.0 comme l'écrivent les documents du projet.
   - Le **livre** (Springer, 2026, DOI 10.1007/978-3-032-14932-9) est sous CC BY 4.0.
   - Son **annexe** distingue pourtant les données. Citation du PDF officiel :
     > « The REGIS/REThM dataset is released under the terms of the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0). »
     > « Any use of the dataset for commercial purposes (e.g., in for-profit products, consultancy services, or monetized platforms) is explicitly prohibited without prior written consent from the authors or the hosting institution. »
   - L'annexe impose aussi : « Any modifications, derivatives, or secondary outputs clearly indicate how the original dataset has been altered ».
   - Elle précise que l'Eurostat 1990 utilisé n'était autorisé qu'à des fins non commerciales, et que certaines cartes sources ne sont utilisables qu'à titre « academic, non-commercial ».
   - **Exposition :** 69 des 90 régions (`source_refs` = `regis_2026_v1` ; `source_layer` `REGIS_*`), l'arc nord de Strumica (`gs1914_strumica_1913_salient.geojson`), et les lignes de côte qui découpent les zones maritimes.
2. **geoBoundaries TUR ADM2 est sous ODbL 1.0**, et dérive d'OpenStreetMap.
   - API officielle : `boundaryID TUR-ADM2-54988432`, `boundarySource` « OpenStreetMap, OSM Boundaries », `boundaryLicense` « Open Data Commons Open Database License 1.0 », `boundaryYearRepresented` 2021.
   - Les documents du projet indiquent CC BY 4.0, sauf `docs/map/corrections/AGENT_1_GEOMETRY_REPORT.md:15`, qui mentionnait déjà l'ODbL.
   - **Exposition :** régions 087 à 090 et `gs1914_saray_tekirdag.geojson`.
3. **geoBoundaries TUR ADM1 est sous CC BY-SA 2.0** (source OSM, selon l'API). Le registre du lot 2 le cite comme utilisé. Que ADM1 ait réellement servi au découpage final n'est pas prouvé : seul un extrait ADM2 est versionné.
4. **Le dépôt public ne contient aucune attribution conforme.** Il n'y a ni mention REGIS avec la licence BY-NC et l'indication des modifications, ni attribution OpenStreetMap avec l'indication ODbL, ni fichier `LICENSE` ou `NOTICE`. **Non-conformité actuelle probable [AVIS JURIDIQUE]**, réparable par l'ajout d'attributions.

## 2. Matrice des sources

| Élément | REGIS / REThM | geoBoundaries TUR ADM2 | geoBoundaries TUR ADM1 | Kavanagh, *Map of Europe c. 1914* | RISTAT 1897 | Natural Earth 10 m | Baedeker, Bradshaw, EB 1911, BGS | Gorkin et Motylev (David Rumsey) | Chemins de fer (Esteban-Oliver ; Ciccarelli) | RShapes, CShapes 2.0 |
|---|---|---|---|---|---|---|---|---|---|---|
| **Organisme** | Schweikart, Martí-Henneberg, Pieper, Morillas-Torné, Schulte ; Springer Nature | William & Mary geoLab ; données OSM | idem | J. Kavanagh, University College Dublin (Zenodo) | Kessler et Markevich, IISH (DataverseNL) | Natural Earth | Éditeurs de 1909 à 1914 ; British Geological Survey | Atlas soviétique de 1937 ; David Rumsey Map Collection | CSUC Dataverse ; Mendeley Data | ETH Zurich |
| **Fichiers du dépôt** | `regions.geojson` (69 régions), `regions.json`, `build/agent_1/*`, `build/agent_2/*` (hors 053 à 069 et 087 à 090), `sources/derived/gs1914_strumica_1913_salient.geojson`, trous côtiers de `maritime_zones.json` | `regions.geojson` (087 à 090), `build/agent_2/*`, `sources/derived/gs1914_saray_tekirdag.geojson` | Selon le registre `agent_2` §3 ; non prouvé | `sources/derived/gs1914_kavanagh_1914_countries.gpkg` ; contrôle (`source_refs` des 90 régions) | `regions.geojson` (053 à 069), `sources/derived/gs1914_ristat_1897_finland_provinces.gpkg` | `maritime_zones.json`, fleuves (`terrain.json` des lots), villes (indirect) | `cities.json` (`4dbf4f8`), `infrastructure.json`, notes hors Git | Aucun (cité comme référence) | Aucun (« pas encore importé ») | Aucun (déclaré exclu) |
| **Version** | GeoPackages téléchargés le 01/11/2026 (pas d'URL ni de version enregistrées) ; livre 2026 | v6, construit le 12/12/2023 | v6 | v1.0, 13/07/2026, DOI 10.5281/zenodo.21341486 ; `europe_1914_low_res.geojson` (17 107 420 o, taille identique à l'original) | v3.3 (20/01/2026), DOI 10.34894/NQOASN | 5.1.2 selon les lots | 1909 à 1914 | — | — | — |
| **Licence** | **CC BY-NC 4.0**, avec clause non commerciale explicite | **ODbL 1.0** | **CC BY-SA 2.0** | **CC BY 4.0** | **CC0**, avec des « conditions additionnelles » annoncées mais non affichées ; citation demandée | **Domaine public** | Domaine public (œuvres anciennes) ; les faits ne sont pas protégés | Conditions de la collection Rumsey | CC BY 4.0 (Esteban-Oliver) ; non vérifiée (Ciccarelli) | NC selon le projet ; non vérifiée pour CShapes 2.0 |
| **(1) Utiliser** | Oui | Oui | Oui | Oui | Oui | Oui | Oui | Consultation | — | — |
| **(2) Modifier** | Oui (en indiquant les modifications) | Oui | Oui | Oui | Oui | Oui | Oui | — | — | — |
| **(3) Redistribuer l'original** | Non commercial seulement, avec attribution | Oui, sous ODbL | Oui, sous CC BY-SA | Oui, avec attribution | Oui | Oui | Oui | Non | — | — |
| **(4) Redistribuer une version transformée** | Non commercial seulement, avec attribution et indication des modifications | **Base dérivée sous ODbL** (partage à l'identique) ; une « œuvre produite » (carte rendue) peut porter une autre licence, avec attribution **[AVIS JURIDIQUE]** | Partage à l'identique (CC BY-SA 2.0) | Oui, avec attribution | Oui | Oui | Oui | — | — | — |
| **(5) Produit commercial** | **Interdit sans accord écrit** | Permis (sous ODbL) | Permis (sous BY-SA) | Permis | Permis | Permis | Permis | — | — | — |
| **Attribution requise** | Citer la publication (citation recommandée dans l'annexe) et indiquer les modifications | « © OpenStreetMap contributors », mention de l'ODbL et lien vers openstreetmap.org/copyright, plus geoBoundaries | idem | « Jack Kavanagh, Map of Europe, c. 1914, UCD, Zenodo, DOI… » | Citation DataverseNL | Facultative | — | — | — | — |
| **Incertitudes** | Statut d'une base « substantiellement transformée » ; portée de la clause NC sur un jeu gratuit ou un dépôt public **[AVIS JURIDIQUE]** | Coexistence ODbL et BY-NC dans `regions.geojson` **[AVIS JURIDIQUE]** | Usage réel d'ADM1 | Le registre `agent_2` l'attribue à tort à « Aoife Kavanagh 2023, dérivé de CShapes 2.0 » ; la page Zenodo ne cite aucune source | Texte des conditions additionnelles | — | Provenance des coordonnées modernes non tracée | — | — | Absence réelle dans la chaîne à confirmer |
| **Risque** | **ÉLEVÉ** (distribution commerciale) ; MOYEN (dépôt public non commercial sans attribution) | **MOYEN** | **INCONNU** | **FAIBLE** | **FAIBLE** | **NUL** | **FAIBLE** | NUL (non utilisé) | NUL (non importés) | NUL si l'absence est confirmée |

**Fichiers copiés depuis d'anciennes branches et provenance insuffisante :**
- `cities.json` (`4dbf4f8`) : les coordonnées sont des valeurs modernes, sans source par point.
- Prototype (`cdd3ab1`, `game/data/*.json`) : données générées, sans source externe.
- Notes sur les ressources (hors Git) : sources textuelles citées par affirmation.
- Les URL de téléchargement ne sont enregistrées nulle part, et les GeoPackages ne contiennent aucune métadonnée de licence (`gpkg_metadata` QGIS vide).

## 3. Scénarios de résolution

| | **A.** Public tel quel, avec attributions | **B.** Code public, données restreintes externalisées | **C.** Dépôt de données privé séparé | **D.** Gel temporaire avec attributions | **E.** Levée de la restriction (accord des auteurs ou re-dérivation) |
|---|---|---|---|---|---|
| **Opérations** | `NOTICE` et `DATA_LICENSES.md` ; licence par répertoire de données ; mention « données géographiques : usage non commercial » ; attribution OSM ; correction des registres | Retirer les fichiers dérivés de REGIS de la branche par défaut ; script de reconstruction depuis les sources téléchargées par l'utilisateur | Nouveau dépôt privé ; sous-module ou artefact ; CI avec secret | A immédiatement, puis aucune nouvelle publication dérivée de REGIS ou d'OSM avant vérification | (1) demande écrite d'autorisation commerciale aux auteurs de REGIS ; (2) à défaut, re-dérivation des 69 régions depuis des sources réutilisables commercialement (Kavanagh CC BY, RISTAT CC0, cartes du domaine public, numérisation propre), puis nouvel audit |
| **Avantages** | Simple, immédiat, conforme pour un usage non commercial **[AVIS JURIDIQUE]** | Le code devient libre de restrictions | Contrôle de la diffusion | Réduit le risque sans décision irréversible | Seule voie vers un produit commercial complet |
| **Inconvénients** | Commercialisation impossible en l'état | **L'historique Git public contient déjà les fichiers** : les retirer exigerait une réécriture, interdite | Même problème d'historique ; complexité | Décision repoussée | Délai ; (2) coût élevé |
| **Risques** | Partage à l'identique ODbL dans un fichier mixte | Disparition des sources ; reproductibilité | Accès des contributeurs | Faibles | (2) régression géométrique et historique : il faudrait refaire l'audit Strumica, les lacunes, etc. |
| **Reproductibilité** | Intacte | Dépend des téléchargements | Dépend de l'accès | Intacte | (1) intacte ; (2) nouvelle chaîne |
| **Contributeurs** | Inchangé | Doivent obtenir les sources | Doivent obtenir un accès | Nouvelles données suspendues | — |
| **Distribution future du jeu** | Non commerciale uniquement | Non résolue | Non résolue | En attente | **Commerciale possible** |

**Recommandation (proposition) :**
1. **D tout de suite.** Ajouter les attributions et les avis de licence (fichier `NOTICE` ci-dessous) et corriger les registres de sources.
2. **E(1) :** demande d'autorisation aux auteurs de REGIS, par le directeur. C'est l'action la moins coûteuse.
3. Obtenir un **avis juridique** sur la coexistence ODbL et BY-NC, et sur la portée de la clause NC.
4. Préparer **E(2)** comme plan de repli, chiffré une fois l'avis rendu.

B et C n'apportent presque rien, puisque l'historique public contient déjà les données.

## 4. Projet de fichier `NOTICE` (non ajouté, en attente de U1.a)

```text
Grand Strategy-1914 — avis sur les données tierces

Les données géographiques de data/world/map/ sont dérivées notamment de :

1. REGIS/REThM — Schweikart, J., Martí-Henneberg, J., Pieper, J., Morillas-Torné, M. & Schulte, B.
   (2026). Regional European Geographic Information System (REGIS), 1870–2020. Springer Nature.
   https://doi.org/10.1007/978-3-032-14932-9 — données sous CC BY-NC 4.0 (usage non commercial).
   Modifications : agrégation d'unités administratives en 90 régions de jeu, corrections
   topologiques et historiques (voir docs/map/).
2. geoBoundaries (William & Mary geoLab), TUR ADM2 v6, d'après OpenStreetMap.
   © OpenStreetMap contributors — Open Database License (ODbL) 1.0,
   https://www.openstreetmap.org/copyright
3. Kavanagh, J. (2026). Map of Europe, c. 1914. University College Dublin. Zenodo.
   https://doi.org/10.5281/zenodo.21341486 — CC BY 4.0.
4. Kessler, G. & Markevich, A. (2026). Russian Empire Historical GIS Maps (1897), RISTAT.
   https://doi.org/10.34894/NQOASN — CC0.
5. Natural Earth — domaine public.

Le statut de licence de la base dérivée (regions.geojson) fait l'objet d'une vérification.
```

## 5. Licence du code original (aucune choisie)

| Option | Droits des utilisateurs | Obligations de redistribution | Usage commercial par des tiers | Interaction avec les données externes | Contributions futures |
|---|---|---|---|---|---|
| Tous droits réservés (*source-available*) | Lecture seule | — | Interdit | Indépendante (les données gardent leurs licences) | Accord de contribution (CLA) indispensable pour accepter des contributions |
| MIT | Très larges | Conserver l'avis de licence | Permis | Indépendante | Simple |
| Apache-2.0 | Très larges, avec licence de brevets explicite | Avis de licence et indication des modifications | Permis | Indépendante | Simple ; clause de brevets protectrice |
| MPL-2.0 | Copyleft au niveau du fichier | Publier les fichiers modifiés | Permis | Indépendante | Moyen |
| GPL-3.0 / AGPL-3.0 | Copyleft fort (AGPL : y compris en réseau) | Publier l'œuvre dérivée entière | Permis sous copyleft | Indépendante | Double licence future : CLA nécessaire |
| PolyForm Noncommercial | Usage non commercial | — | Interdit | Cohérente avec BY-NC | CLA |

**Recommandation argumentée :**
1. **Séparer** strictement les licences du code et celles des données (`LICENSE` à la racine pour le code ; `DATA_LICENSES.md` et une licence par répertoire de données).
2. Le choix du code dépend de la question **U8 : vente ou gratuité.**
   - Projet libre : **Apache-2.0**, protection en matière de brevets et compatibilité large.
   - Vente envisagée avec contributions externes : **tous droits réservés avec CLA**, ou Apache-2.0 avec CLA.
3. Aucune licence de code ne lève la restriction BY-NC des données.

## 6. Sources vérifiées (14/11/2026)

- REGIS, livre et annexe « License and Terms of Use » : https://doi.org/10.1007/978-3-032-14932-9 (PDF en accès libre, annexe p. 86–87).
- geoBoundaries : https://www.geoboundaries.org/api/current/gbOpen/TUR/ADM2/ et `…/ADM1/`.
- Kavanagh : https://zenodo.org/records/21341486.
- RISTAT : https://doi.org/10.34894/NQOASN (DataverseNL, onglet *Terms*).
- Natural Earth : https://www.naturalearthdata.com/about/terms-of-use/.
- OpenStreetMap : https://www.openstreetmap.org/copyright.
