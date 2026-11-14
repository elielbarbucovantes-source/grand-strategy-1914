# Couches thématiques consolidées (lot 2 : C6 et C7)

- **Date :** 15/11/2026.
- **Outils :** `tools/map/build_thematic_layers.py` (génération et `--check`), `tools/map/validate_thematic.py` (34 contrôles). Les deux sont dans `tools/map/validate_all.sh`.
- **Statut :** consolidation **technique** des lots audités. Aucune donnée historique n'a été ajoutée.

## 1. Villes (`data/world/map/cities.json`)

- Reprise de la logique de `tools/map/unify_thematic_data.py` (`4dbf4f8`). Le résultat est **identique octet pour octet** au `cities.json` de `4dbf4f8` : 175 villes, 22 capitales.
- Contrôles sur la géométrie validée :
  - 175/175 villes dans leur région ;
  - souveraineté cohérente ;
  - une capitale par État ;
  - `city_ids` des régions exacts ;
  - noms des capitales toujours visibles (MAP-DEC-41).
- **Restant (décision C6b) :** noms composites mélangeant plusieurs sites (« Bucarest (Ploiești) », « Sofia (Vidin) », « Cetinje (Antivari/Bar) », « Durrës (Scutari / Vlora) », « Saint-Pétersbourg (Kronstadt) », « Athènes (Le Pirée) »…) ; capitale albanaise de référence.

## 2. Terrain (`data/world/map/terrain.json`)

- 90 profils régionaux repris des lots (clés `external_*`, `island_class: null` et `maritime_zone_ids` retirées ; la source de vérité des liens maritimes est `adjacency.json`).
- **Dédoublonnage MAJ-006**, selon la liste de l'audit global (`docs/map/audit/ISSUES.json`) :
  - `river_danube_lower` → `river_danube` ;
  - `river_vistula_middle` → `river_vistula` ;
  - `mtn_carpathians_east_south` → `mtn_carpathians` ;
  - `mtn_dinaric_prokletije_sar` → `mtn_dinaric_alps`.

  Les identifiants d'origine sont conservés dans `source_ids`. Résultat : 59 fleuves (au lieu de 61) et 20 massifs (au lieu de 22).
- L'audit citait aussi Dniestr, Niémen, Save et Drina comme présents dans les deux lots. Dans les fichiers `terrain.json` actuels, chacun n'existe que dans **un** lot : aucune fusion n'est nécessaire.
- **Restant (OPT-001) :** « Oslofjord » (nom de 1925) dans `region_045`. C'est un toponyme à corriger lors d'une révision sourcée.

## 3. Infrastructures (`data/world/map/infrastructure.json`)

- Union sans ajout : 129 axes ferroviaires (76 + 53), 65 places fortes (32 + 33), 84 grands ports. Les ports sont référencés par identifiant de ville, `cities.json` restant la source unique.
- Contrôles :
  - extrémités ferroviaires = villes existantes, ancrées sur leurs coordonnées et dans les bonnes régions ;
  - places fortes dans leur région (tolérance 5 km) et de la bonne souveraineté ;
  - toutes les références des fiches régionales valides ;
  - tout site au rôle `major_port` est recensé comme port.
- **Les étapes `terrain`, `infrastructure` et `maritime` de `unify_thematic_data.py` ne sont pas utilisées.** Elles injecteraient des zones maritimes occidentales non décidées (`NEW_MARITIME_ZONES`), des écartements de voie et des lignes nouvelles (`build_new_routes`) sans source par élément.

### Anomalie constatée : réseau ferré fragmenté

- Les axes des lots relient **seulement leurs deux villes extrémités**, même quand leur nom cite des villes intermédiaires. Exemple : `rail_ru_stpetersburg_pskov_vilna_warsaw` ne touche ni Pskov ni Vilna.
- Résultat mesuré : **17 composantes connexes**, et **134 villes desservies sur 175**. La plus grande (43 villes) couvre l'Europe occidentale et centrale ; l'Empire russe forme une composante de 23 villes et quatre paires isolées ; la Roumanie, la Grèce, l'Irlande et les Balkans sont séparés.
- MAJ-002 n'avait identifié que la coupure entre lots. Cette fragmentation la complète.
- **Correction non faite**, car elle exige des données ferroviaires **sourcées** : nœuds intermédiaires, liaisons transfrontalières. Les 10 axes internationaux proposés par MAJ-002 (Hambourg–Aarhus, Königsberg–Kaunas, Posen–Varsovie, Breslau–Varsovie, Cracovie–Varsovie, Lemberg–Kiev, Czernowitz–Iași, Brassó–Bucarest, Temesvár–Bucarest, Budapest–Belgrade) restent une **liste de lacunes à sourcer**. Ils ne figurent pas dans les données.
- `validate_thematic.py` fige le constat (17 composantes) pour détecter toute évolution.
- **Effet pour la suite :** le réseau ferré actuel n'est **pas** utilisable tel quel pour la logistique. Les déplacements doivent s'appuyer sur `adjacency.json` (graphe des régions), le réseau ferré n'étant qu'une couche d'information.
