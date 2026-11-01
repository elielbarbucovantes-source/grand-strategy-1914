# Atlas cartographique — décisions et préparation technique

**Statut :** les décisions du §1 sont **VALIDÉES par le directeur le 2026-11-01**. La conception détaillée de l’atlas continue dans une autre conversation. Cette spécification prépare les données et leur flux de travail ; elle ne crée aucune région et ne prend aucune décision géographique supplémentaire.

## 1. Décisions cartographiques validées

| ID | Décision VALIDÉE |
|---|---|
| MAP-DEC-01 | Maximum de 100 régions terrestres. |
| MAP-DEC-02 | Découpage hybride privilégiant les frontières historiques de 1914. |
| MAP-DEC-03 | Europe géographique complète, de l’Atlantique à l’Oural, Scandinavie et Balkans compris. |
| MAP-DEC-04 | Les petits États importants conservent leurs propres régions ; les micro-États sont simplifiés. |
| MAP-DEC-05 | Villes stratégiques seulement : capitales, grands ports, centres industriels, forteresses et nœuds ferroviaires. |
| MAP-DEC-06 | Relief intermédiaire : plaines, forêts, montagnes, collines, marais et grands fleuves. |
| MAP-DEC-07 | Réseau ferroviaire visible et infrastructures régionales. |
| MAP-DEC-08 | Réseau routier visible. |
| MAP-DEC-09 | Les fleuves sont des obstacles et des voies de transport. |
| MAP-DEC-10 | Fortifications historiques et évolutives. |
| MAP-DEC-11 | Découpage maritime intermédiaire. |
| MAP-DEC-12 | Brouillard de guerre dynamique. |
| MAP-DEC-13 | Occupation militaire distincte de la souveraineté ; victoire territoriale par contrôle militaire de 90 % de la carte. |
| MAP-DEC-14 | Résistance locale abstraite dans les régions occupées. |
| MAP-DEC-15 | Taille des régions adaptée à leur importance démographique, industrielle et stratégique. |
| MAP-DEC-16 | Détroits contrôlables. |
| MAP-DEC-17 | Seuls les ports majeurs sont représentés individuellement. |
| MAP-DEC-18 | Frontières historiques prioritaires, avec adaptations géographiques pertinentes. |
| MAP-DEC-19 | Débarquements possibles sur les côtes accessibles ; les ports facilitent les opérations. |
| MAP-DEC-20 | Grandes îles et petites îles stratégiques distinctes ; autres îles simplifiées. |
| MAP-DEC-21 | Régions reliées par leurs frontières terrestres ; routes et chemins de fer facilitent les déplacements. |
| MAP-DEC-22 | Montagnes comme caractéristiques régionales et obstacles frontaliers. |
| MAP-DEC-23 | Ponts et passages existants facilitent le franchissement des fleuves. |
| MAP-DEC-24 | Frontières politiques visuellement inchangées pendant l’occupation. |
| MAP-DEC-25 | Occupation figurée par des hachures aux couleurs de l’occupant. |
| MAP-DEC-26 | Style hybride : atlas historique et interface stratégique moderne. |

Ces décisions ne fixent pas une liste de lieux, une frontière particulière, le nombre final sous le plafond, ni des formules de déplacement, résistance ou visibilité.

## 2. Modèle de données proposé

Les identifiants sont permanents et indépendants des noms affichés. Géométrie, données historiques et état de campagne sont séparés. Provenance et licence accompagnent chaque lot de données. Le plafond de 100 est contrôlé sur la couche des régions terrestres. Les frontières de souveraineté restent distinctes du contrôle et de l’occupation.

| Couche / type | Géométrie ou clé | Champs conceptuels proposés | Limites connues |
|---|---|---|---|
| `land_regions.geojson` | Polygon/MultiPolygon | ID stable, libellés, relief régional, dimensions d’importance démographique/industrielle/stratégique, souveraineté de départ une fois sourcée, classe d’île le cas échéant, provenance | Aucun ID ou attribut historique concret n’est inventé ici. Max 100 features. |
| Frontières terrestres | Arêtes communes dérivées des polygones ; lignes exceptionnelles reliées à deux IDs | régions adjacentes, obstacle (fleuve/montagne) ou passage/pont documenté | Le graphe initial découle des frontières ; les obstacles/ouvrages sont à cartographier. |
| `strategic_sites.geojson` | Points | ID, type : capitale / grand port / centre industriel / forteresse / nœud ferroviaire, région liée, nom et source | Les localités et critères exacts de sélection restent ouverts. |
| `transport_network.geojson` | Lignes et points | ID, type : rail / route / fleuve / pont / passage, liens région/site, source | Tracés, hiérarchie et capacités non spécifiés. |
| `relief.geojson` | Surfaces/lignes si séparées des polygones régionaux | ID, catégorie de relief, région(s) ou relation topologique, source | Catégories validées ; emplacements et effets ouverts. |
| `fortifications.geojson` | Points/lignes/surfaces selon les sources | ID, région, catégorie sourcée, état et date historique | Caractère historique et évolutif validé ; inventaire et niveaux ouverts. |
| `maritime_zones.geojson` | Polygon/MultiPolygon | ID, libellé, connexions/adjacences et détroits associés après conception | Découpage intermédiaire validé ; nombre et limites ouverts. |
| `regional_infrastructure.json` | Enregistrement indexé par `region_id` | infrastructures régionales avec source, date et unité | Ne pas créer de niveaux ou valeurs non validés. |
| `territorial_state` (runtime) | `region_id` | souveraineté, occupant/contrôleur et temps de campagne | Occupation distincte validée ; transitions ouvertes. Souveraineté détermine la frontière visuelle. |
| `visibility_state` (runtime) | pays + région/zone | vue connue et fraîcheur/temps, selon règles futures | Brouillard dynamique validé ; modèle de visibilité ouvert. |
| `resistance_state` (runtime) | `region_id` occupée | état abstrait et références de source/règle | Principe validé ; formule, déclencheurs et conséquences ouverts. |

Ces enregistrements décrivent des frontières techniques. Ils ne valident aucune règle de gameplay. Les réseaux et géométries ne contiennent pas de calcul de mouvement, combat, résistance ou brouillard.

### Topologie

- Les régions terrestres sont adjacentes si leurs frontières partagent un segment ; l’import construit et vérifie un graphe d’adjacence à partir des polygones.
- Routes et chemins de fer sont des graphes visibles séparés de l’adjacence territoriale. Ils facilitent les déplacements ; coûts, capacités et délais restent à définir.
- Les fleuves sont des lignes pouvant séparer des régions et servir au transport. Ponts et passages sont des objets cartographiques reliés aux régions/rives concernées, une fois documentés.
- Les montagnes se décrivent comme relief régional et obstacles frontaliers lorsque l’atlas les identifie.
- Détroits relient les régions/zones concernées ; « contrôlable » est validé, les règles de contrôle et d’effets ne le sont pas.
- Côtes accessibles et ports sont des faits géographiques sourcés. Le test d’accès et les effets d’un port sur un débarquement appartiennent aux règles à définir.
- Les grandes îles et petites îles stratégiques ont leurs entités distinctes conformément au découpage ; les autres peuvent être généralisées. Classification précise à établir.

## 3. Formats et organisation des fichiers

### Choix technique proposé

- Utiliser **GeoJSON RFC 7946** pour couches géographiques et **JSON** pour tables liées et manifeste. RFC 7946 définit GeoJSON comme format d’échange géographique fondé sur JSON et spécifie les coordonnées WGS 84 longitude/latitude en degrés décimaux ([RFC 7946](https://www.rfc-editor.org/info/rfc7946/)). Ceci fixe le format d’échange, pas la projection de rendu du jeu.
- **QGIS** est recommandé pour modifier les géométries et attributs, sauvegarder les couches et exporter en GeoJSON ; sa documentation décrit l’édition, l’annulation/rétablissement et la sauvegarde des modifications ([guide d’édition QGIS 3.44](https://docs.qgis.org/3.44/en/docs/user_manual/working_with_vector/editing_geometry_attributes.html)). Le fichier de projet QGIS sera ajouté lorsque l’atlas existera.
- Garder les sources éditables séparées des données préparées au runtime. Le futur import convertira les sources vers une représentation optimisée et reproductible ; ne pas retoucher les sources depuis le rendu du jeu.
- Préserver les IDs lors d’une correction de frontière. Toute fusion/scission de régions doit avoir une décision de conception et une migration de références/sauvegardes.

### Arborescence cible

```text
data/world/map/
├── README.md
├── manifest.json
├── source/
│   ├── land_regions.geojson
│   ├── strategic_sites.geojson
│   ├── transport_network.geojson
│   ├── relief.geojson
│   ├── fortifications.geojson
│   └── maritime_zones.geojson
├── tables/regional_infrastructure.json
└── project/                 # futur projet QGIS, si retenu
```

Les couches de données réelles ne sont pas créées dans cette mission. Le schéma technique vide est dans `data/schemas/map.schema.json`.

## 4. Méthode d’import et de modification

1. **Éditer** les couches dans QGIS selon l’atlas de conception, une couche par catégorie. Attribuer un ID stable à chaque objet dès sa création.
2. **Sourcer** chaque attribut historique avec référence, date et licence ; n’utiliser que les décisions validées. Les valeurs provisoires sont étiquetées et exclues des exports approuvés.
3. **Exporter** en GeoJSON RFC 7946 pour les couches spatiales et JSON UTF-8 déterministe pour les tables. Toute projection d’affichage reste une transformation séparée.
4. **Valider le schéma** : parse JSON, type de géométrie, IDs uniques, maximum de 100 régions, catégories permises, références régionales existantes, sources/licences et bornes de coordonnées.
5. **Valider la topologie** : validité des polygones, pas d’auto-intersection, audit visuel des trous/recouvrements, adjacency dérivée, continuité des réseaux et rattachements ponts/passages/fleuves. Toute exception est documentée, aucune correction de frontière automatique.
6. **Prévisualiser** les couches et revoir avec le concepteur : cohérence historique, lisibilité des réseaux, hachures d’occupation, frontières politiques inchangées, relief, brouillard et style hybride.
7. **Versionner** les données avec manifeste (version, source, licence, outil, changements et date), diff des fichiers et validation du concepteur pour toute évolution d’atlas.
8. **Générer plus tard** les données runtime de façon reproductible avec version d’outil, paramètres et empreinte des sources. Aucun importeur runtime n’est écrit ici.

Pour des diffs propres, ordonner les features par ID, normaliser l’ordre des propriétés, garder une précision suffisante sans sur-précision, UTF-8 et une indentation constante. Si les polygones rendent les diffs textuels trop lourds, garder un format de travail GIS puis exporter des GeoJSON canoniques versionnés.

## 5. Représentation visuelle

- Fond et contours de l’atlas historique ; contrôles, panneaux et surcouches de l’interface stratégique moderne.
- Frontières politiques issues de la souveraineté, sans modification visuelle liée à l’occupation.
- Hachures superposées aux couleurs de l’occupant, dans une couche dynamique distincte.
- Brouillard dynamique calculé par vue d’acteur ; ne pas exposer dans l’image des informations cachées à ce joueur/à cette IA.
- Relief, fleuves, rail, routes, ponts, passages, sites, fortifications et zones maritimes surcouchés indépendamment.
- Palette, motifs, échelle de zoom, règles de labels et mode accessible restent à préciser. Couleur et hachure ne doivent pas être l’unique encodage d’information importante.

## 6. Difficultés techniques du plafond de 100 régions

- **Le plafond d’entités n’est pas un plafond de géométrie.** Cent MultiPolygons avec îles, détroits et frontières détaillées peuvent contenir beaucoup de sommets et trous ; mémoire, taille des fichiers, import, rendu et hit-testing dépendent de ce détail.
- **Taille et importance varient fortement.** Les régions des petits États importants et les régions très peuplées/industrielles/stratégiques coexistent avec de grands espaces. Au zoom global, petites régions et détroits deviennent invisibles ; au zoom local, grandes régions dominent. Un seuil de sélection et une hiérarchie de labels seront à concevoir.
- **Déformation stratégique/historique.** Adapter la taille aux trois dimensions d’importance peut déformer la géographie et les frontières historiques. Aucun poids ou algorithme n’est validé ; le contrôle reste cartographique humain.
- **Topologie fragile à simplifier.** Simplifier les polygones indépendamment peut créer trous, chevauchements ou faux voisins et rompre le graphe terrestre. Les contours communs doivent partager une même topologie ou être revalidés après chaque niveau de détail.
- **Réseaux nombreux malgré peu de régions.** Routes, rails, fleuves, ponts, fortifications, sites et zones maritimes peuvent dépasser le coût des polygones. Il faudra filtrer et simplifier les couches par zoom sans altérer la carte de simulation.
- **Accessibilité de sélection.** Petites régions, îles et détroits ont une faible surface cliquable. La sélection devra prévoir une tolérance/UI adaptée qui ne modifie pas les géométries ni l’adjacence du gameplay.
- **Occupation et brouillard superposés.** Hachures occupant, frontières souveraines, relief et visibilité peuvent rendre la carte illisible. Tester contraste, motifs et vues daltoniennes.
- **Côtes, îles et débarquements.** Même avec moins de 100 régions, la topologie terre-mer exige des côtes accessibles, ports, îles et zones de mer suffisamment détaillés.
- **Évolution d’atlas.** Fusion/scission ou changement d’ID casse historiques, ordres, sites attachés et sauvegardes. Geler IDs et prévoir migrations avant les données de campagne.

À mesurer sur l’atlas réel : nombre de sommets, taille de source, import, dessin, sélection, lisibilité à différents zooms et cohérence d’adjacence. Aucun budget de performance n’est présumé.

## 7. Données nécessaires pour construire l’atlas

1. Emprise et référence temporelle de la carte, frontières européennes et littoral de 1914.
2. Frontières politiques/souverainetés et statut des petits États et micro-États.
3. Démographie régionale sourcée pour évaluer les tailles, avec année, unité et couverture.
4. Centres industriels/localisation de l’industrie et indicateurs compatibles avec le découpage, sans les confondre avec les valeurs de jeu.
5. Critères descriptifs d’importance stratégique et inventaire des passages/axes.
6. Relief et hydrographie : plaines, forêts, montagnes, collines, marais, grands fleuves, îles, côtes et détroits.
7. Transports historiques : réseaux ferrés, gares/nœuds, routes à l’échelle retenue, ponts et passages, navigation fluviale si retenue.
8. Sites stratégiques : capitales, grands ports, centres industriels, forteresses et nœuds ferroviaires.
9. Fortifications : emplacement, type, état et datation sourcés.
10. Découpage et connexions des zones maritimes, ports majeurs et détroits.
11. Territoires abstraits/colonies et leur relation aux pays, selon les documents de conception concernés.
12. Pour chaque jeu de données : organisme/auteur, référence/URL, licence, attribution, date et transformations.

Les sources candidates restent à sélectionner après comparaison de leur couverture 1914, précision, cohérence transfrontalière, droits d’usage et possibilité de correction manuelle.

## 8. Points encore ouverts

- Projection de rendu, emprise cartographique exacte et conventions de noms.
- Nombre final (maximum 100), géométrie, noms, IDs et frontières de chaque région ; définition opérationnelle de « petit État important » et « micro-État ».
- Méthode de dimensionnement démographique/industriel/stratégique, données et arbitrage de déformation.
- Classification détaillée des îles et traitement des micro-États, régions transcontinentales et territoires coloniaux abstraits.
- Relief : affectation régionale, coexistence de catégories, seuil d’un grand fleuve, et emplacement des obstacles montagneux.
- Liste des villes et définition de « grand port »/« centre industriel »/« nœud ferroviaire ».
- Tracés, hiérarchie et niveau de détail des routes, rails, voies fluviales, ponts et passages.
- Inventaire/type/niveau/date des fortifications et évolution au fil de la partie.
- Nombre, limites, adjacences des zones maritimes ; contrôle des détroits ; critère d’accessibilité côtière et effet des ports pour les débarquements.
- Brouillard : champs visibles, niveaux, portée, fraîcheur, infrastructures révélées et interaction avec le renseignement.
- Résistance locale : représentation, déclencheurs, durée et effets.
- Victoire par contrôle de 90 % : dénominateur exact de « carte » (régions terrestres uniquement ou autre), mesure des régions contestées/non attribuées et place des zones maritimes.
- Sources, licences et attribution des données géographiques/historiques.
- Palette, motifs, labels, zoom et exigences d’accessibilité.

## 9. Limite de portée

Aucune région, frontière, ville, route, ligne ferroviaire, fortification ou zone maritime n’a été créée. Aucun importeur runtime ni gameplay n’a été développé.
