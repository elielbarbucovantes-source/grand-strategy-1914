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
| MAP-DEC-13 | Occupation militaire distincte de la souveraineté ; victoire territoriale par contrôle militaire de 90 % des régions. |
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

| MAP-DEC-27 | Zoom libre, du niveau continental au niveau régional détaillé. |
| MAP-DEC-28 | La carte principale montre l’essentiel ; couches économie/industrie, rail/routes, relief, diplomatie, renseignement et infrastructures militaires activables. |
| MAP-DEC-29 | Couleurs nationales historiques par défaut, personnalisables dans les réglages ; hachures d’occupation distinctes. |
| MAP-DEC-30 | Noms ordinaires de régions et villes adaptés au zoom et à l’importance stratégique ; le joueur peut masquer ces noms ordinaires. Les noms de capitales restent toujours visibles selon MAP-DEC-41, décision spécifique prioritaire. |
| MAP-DEC-31 | Sélection d’une région par clic ou recherche de nom dans un panneau latéral. |
| MAP-DEC-32 | La sélection ouvre un panneau latéral extensible avec fiche détaillée de région. |
| MAP-DEC-33 | Limites régionales discrètes à faible zoom et plus lisibles à fort zoom. |
| MAP-DEC-34 | Armées terrestres représentées par figurines/icônes ; les symboles OTAN ne sont pas la représentation principale. |
| MAP-DEC-35 | Regroupement automatique selon le zoom : unités proches individuelles, groupes partiels, puis regroupement continental ; clic pour voir la composition. |
| MAP-DEC-36 | Les ordres de déplacement sont indiqués par des flèches entre origine et destination ; pas d’animation de déplacement des figurines. |
| MAP-DEC-37 | Les flèches indiquent destination, durée estimée, distance et difficultés (terrain, infrastructure, frontière, autorisations requises). |
| MAP-DEC-38 | Couleur des flèches différenciée par type d’ordre (déplacement, attaque, retraite, renfort) et état (planifié, en cours, bloqué, terminé). |
| MAP-DEC-39 | Frontières nationales plus épaisses que régionales ; couleur adaptée aux pays voisins. |
| MAP-DEC-40 | Transfert territorial éventuellement animé progressivement ; option pour désactiver les animations et appliquer immédiatement. |
| MAP-DEC-41 | Chaque capitale a une étoile distinctive, son nom toujours visible et une fiche accessible au clic ; cette règle spécifique prévaut sur l’option générale de masquage des noms ordinaires de MAP-DEC-30. |
| MAP-DEC-42 | Autres villes importantes : point simple, nom et fiche ; aucun pictogramme différent par fonction. |
| MAP-DEC-43 | Un seul symbole de port ; catégorie et importance consultables dans la fiche. |
| MAP-DEC-44 | Grandes lignes ferroviaires visibles sur la carte ; détails régionaux dans une couche. |
| MAP-DEC-45 | Axes routiers principaux visibles ; routes secondaires dans une couche. |
| MAP-DEC-46 | Un seul symbole pour les fortifications ; niveau, type et détails dans la fiche. |
| MAP-DEC-47 | Avions en déplacement figurés par avions ; avions basés représentés sur leurs bases ; clic sur l’escadrille pour composition/informations. |
| MAP-DEC-48 | Une flotte est représentée par une icône par zone maritime ; clic pour la composition des navires ; pas d’icône par navire. |
| MAP-DEC-49 | Bataille terrestre en cours : icône et indicateur d’intensité. |
| MAP-DEC-50 | Événement historique important : marqueur temporaire sur la carte et entrée permanente au journal. |
| MAP-DEC-51 | Revendications territoriales sans marqueur cartographique dédié ; la couleur du territoire représente uniquement la souveraineté officielle. |
| MAP-DEC-52 | Ressources naturelles signalées sur les régions ; quantité et production consultables dans la fiche. |
| MAP-DEC-53 | Usines et installations économiques visibles dans une couche économique activable. |
| MAP-DEC-54 | Lignes d’approvisionnement entre armées et sources ; difficultés visibles dans les données militaires. |
| MAP-DEC-55 | Brouillard dynamique : géographie visible ; informations militaires inconnues cachées selon le renseignement. |
| MAP-DEC-56 | Les renseignements militaires anciens perdent progressivement en précision puis disparaissent ; rythme/formule à définir. |
| MAP-DEC-57 | Limites maritimes discrètes, comme les limites régionales terrestres. |
| MAP-DEC-58 | Flotte placée au centre de sa zone maritime. |
| MAP-DEC-59 | Blocus indiqué par ligne barrée et intensité ; routes commerciales affectées identifiables. |
| MAP-DEC-60 | Bataille navale : icône, drapeaux des participants et intensité. |
| MAP-DEC-61 | Routes commerciales maritimes entre ports majeurs ; épaisseur uniforme indépendante du volume commercial. |
| MAP-DEC-62 | Indicateurs d’influence discrets autour des capitales ; pas de recoloration de territoires ni de couche territoriale additionnelle colorée. |
| MAP-DEC-63 | Les alliances ne changent pas la carte ; elles se consultent dans le menu diplomatique. |
| MAP-DEC-64 | Crise importante : marqueur persistant jusqu’à résolution, notification et entrée au journal diplomatique. |
| MAP-DEC-65 | Date de dernière mise à jour du renseignement militaire affichée au survol des unités/positions ennemies, jamais en permanence. |
| MAP-DEC-66 | La légende contextuelle s’adapte aux couches actives. |
| MAP-DEC-67 | Réglages essentiels seulement : couleurs nationales, noms, animations, couches principales ; éviter les préférences secondaires nombreuses. |
| MAP-DEC-68 | Qualité graphique ajustée automatiquement à l’ordinateur, avec modification manuelle possible. |
| MAP-DEC-69 | La carte occupe presque tout l’écran ; panneaux latéraux discrets et rétractables, priorité visuelle à la carte. |

Les 69 décisions sont des décisions de conception VALIDÉES, mais ne fixent pas une liste de lieux, une frontière particulière, le nombre final sous le plafond ni des formules de déplacement, résistance ou visibilité. Les détails visuels nommés (intensité, catégorie, durée estimée) sont des données à afficher lorsqu’elles existent ; leur calcul reste hors de cette spécification. Les revendications territoriales contestées n’ont aucun marquage cartographique : la couleur officielle reste celle de l’État souverain (MAP-DEC-51). Cette présentation est décidée ; elle ne tranche pas le calcul du contrôle militaire de 90 % (MAP-DEC-13).

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
| `regional_resources.json` | Enregistrement indexé par région | référence de ressource, quantité, production, unités et provenance | Types, unités, quantités et règles de production restent à définir. |
| `countries.json` (style) | Identifiant de pays | couleur historique par défaut et surcharge de préférence utilisateur | Palette exacte et règles de contraste ouvertes. |
| `map_presentation.json` | Configuration de rendu | visibilité des couches, noms ordinaires, animations, qualité auto/manuelle et légende contextuelle | Le masquage ne s’applique pas aux noms des capitales ; paramètres de rendu à définir. |
| `map_overlays` (runtime, par observateur) | Enregistrements typés référant aux IDs statiques | occupation/hachures, armées et regroupements, flèches d’ordres, avions, flottes, batailles, événements, ravitaillement, blocus, commerce, influence, crises | Contenu visible soumis au brouillard et aux règles futures ; le schéma ne calcule aucun état. |
| `intelligence_state` (runtime, par observateur) | Observateur + cible + type d’information | date de collecte, dernière mise à jour, précision/référence de statut | Décroissance et seuil de disparition ouverts ; pas de formule imposée. |
| `territorial_state` (runtime) | `region_id` | souveraineté, occupant/contrôleur et temps de campagne | Occupation distincte validée ; transitions ouvertes. Souveraineté détermine la frontière visuelle. |
| `visibility_state` (runtime) | pays + région/zone | vue connue et fraîcheur/temps, selon règles futures | Brouillard dynamique validé ; modèle de visibilité ouvert. |
| `resistance_state` (runtime) | `region_id` occupée | état abstrait et références de source/règle | Principe validé ; formule, déclencheurs et conséquences ouverts. |

Ces enregistrements décrivent des frontières techniques. Ils ne valident aucune règle de gameplay. Les réseaux et géométries ne contiennent pas de calcul de mouvement, combat, résistance ou brouillard.

### Présentation et états dynamiques

Les données géographiques statiques (régions, sites, relief, réseaux, fortifications, ports et zones maritimes) sont chargées indépendamment de l’état de campagne. Les vues runtime sont des projections filtrées par joueur/IA et ne modifient jamais la souveraineté officielle. La souveraineté colore le territoire ; le contrôle militaire se superpose en hachures aux couleurs de l’occupant. Les revendications n’ont pas de rendu cartographique dédié.

Le catalogue technique des calques comprend les calques explicitement validés : économie/industrie, rail/routes, relief, diplomatie et infrastructures militaires, plus le renseignement. La couche diplomatique ne dessine que les indicateurs d’influence convenus ; alliances restent consultables dans le menu diplomatique. La légende suit les calques actifs. Les villes, sites, unités, ordres, événements et marqueurs maritimes sont des annotations rendues au-dessus des géométries, filtrées selon le joueur et le zoom.

Les données d’ordres peuvent porter catégorie (déplacement/attaque/retraite/renfort), état (planifié/en cours/bloqué/terminé), destination, durée estimée, distance et références de difficultés (terrain, infrastructure, frontière, autorisation). Le rendu associe des styles distincts aux types et états, sans couleur officielle présumée dans le schéma. Les données d’unités distinguent armées terrestres, avions en déplacement ou basés, et flottes rattachées à une zone maritime. Les combats terrestres/navals portent intensité et participants ; blocus portent intensité et routes touchées ; routes commerciales relient les ports majeurs avec une épaisseur visuelle uniforme. Les lignes de ravitaillement relient armées et sources. Les événements temporaires et crises persistantes référencent leur entrée de journal. Les ports partagent un symbole ; les villes importantes non capitales ont un point simple sans symbole propre à leur fonction ; fortifications partagent un symbole et exposent leurs détails en fiche. Ces champs ne signifient pas que ces systèmes sont implémentés.

Les principes d’affichage validés comprennent le zoom libre du niveau continental au niveau régional détaillé (MAP-DEC-27), l’adaptation des noms ordinaires au zoom et à l’importance (MAP-DEC-30), le regroupement automatique des unités selon le zoom (MAP-DEC-35) et une flotte placée au centre de sa zone maritime (MAP-DEC-58). Le nom de chaque capitale reste visible, même si le joueur masque les noms ordinaires (MAP-DEC-41). Ces règles de conception sont acquises. Les seuils exacts de zoom, distances d’affichage, priorités et algorithmes de regroupement sont des détails d’implémentation restant à préciser.

Les réglages ne contiennent que les préférences validées : palette nationale, affichage des noms ordinaires, animations, couches principales et qualité graphique automatique/manuelle.

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
- La palette précise, les motifs, seuils de zoom, distances/conditions d’affichage des labels, algorithmes de regroupement et adaptations d’accessibilité restent à préciser lors de l’implémentation. Les principes et exceptions décidés ci-dessus ne sont pas ouverts. Couleur et hachure ne doivent pas être l’unique encodage d’information importante.

## 6. Difficultés techniques du plafond de 100 régions

- **Le plafond d’entités n’est pas un plafond de géométrie.** Cent MultiPolygons avec îles, détroits et frontières détaillées peuvent contenir beaucoup de sommets et trous ; mémoire, taille des fichiers, import, rendu et hit-testing dépendent de ce détail.
- **Taille et importance varient fortement.** Les régions des petits États importants et les régions très peuplées/industrielles/stratégiques coexistent avec de grands espaces. Au zoom global, petites régions et détroits deviennent invisibles ; au zoom local, grandes régions dominent. Les principes de zoom et de labels sont validés ; seuils de sélection et distances exactes restent à concevoir.
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
- Cible de 90 régions et répartition zonale fixées; géométries, frontières exactes, appariement aux unités historiques et vérification complète des noms/IDs restent à réaliser. Définition opérationnelle de « petit État important » et « micro-État » à préciser.
- Méthode de dimensionnement démographique/industriel/stratégique, données et arbitrage de déformation.
- Classification détaillée des îles et traitement des micro-États, régions transcontinentales et territoires coloniaux abstraits.
- Relief : affectation régionale, coexistence de catégories, seuil d’un grand fleuve, et emplacement des obstacles montagneux.
- Liste des villes et définition de « grand port »/« centre industriel »/« nœud ferroviaire ».
- Tracés, hiérarchie et niveau de détail des routes, rails, voies fluviales, ponts et passages.
- Inventaire/type/niveau/date des fortifications et évolution au fil de la partie.
- Nombre, limites, adjacences des zones maritimes ; contrôle des détroits ; critère d’accessibilité côtière et effet des ports pour les débarquements.
- Brouillard : champs visibles, niveaux, portée, fraîcheur, infrastructures révélées et interaction avec le renseignement.
- Résistance locale : représentation, déclencheurs, durée et effets.
- Victoire par contrôle militaire d’au moins 90 % des régions : modalités exactes du décompte, notamment contrôle partiel, occupation, contestation militaire ou autres situations particulières. MAP-DEC-51 fixe déjà l’absence de marqueur des revendications et le maintien de la couleur de souveraineté ; ce choix visuel ne détermine pas le calcul de victoire.
- Labels et interaction : distances d’affichage, seuils de zoom et priorité des labels ordinaires selon importance ; les noms de capitales restent toujours visibles. Contenu, dimensions et comportement technique de recherche/fiche régionale restent à préciser.
- Rendu et interface : seuils exacts de zoom, algorithmes de regroupement des unités, priorités entre symboles, styles/couleurs exacts des flèches et frontières, détails de légende contextuelle, qualité graphique et comportements des panneaux. Le principe de regroupement automatique par zoom, le zoom libre et le placement central des flottes sont validés.
- Sources, licences et attribution des données géographiques/historiques.
- Palette, motifs et exigences d’accessibilité ; seuils et distances exacts d’affichage des labels et des éléments au zoom.

## 9. Limite de portée

Aucun polygone de région, frontière, ville, route, ligne ferroviaire, fortification ou zone maritime n’a été créé. Seul l’index éditorial de 90 entrées existe. Aucun importeur runtime ni gameplay n’a été développé.

## 10. Construction de l’atlas à 90 régions

La mission cartographique du directeur fixe une cible de **90 régions terrestres**, avec répartition par zone 6 / 13 / 6 / 18 / 8 / 18 / 10 / 7 / 4 (îles Britanniques, Europe occidentale, péninsule ibérique, Europe centrale, Scandinavie, Europe orientale, Balkans, Italie, territoires ottomans européens). Cette cible est inférieure au plafond validé de 100. La liste des identifiants et souverainetés prévues est dans `data/world/map/tables/region_plan.csv`; le détail de son état et des sources est dans `docs/map/ATLAS_BUILD_STATUS.md`.

Précisions validées dans le dossier de mission : le pays de Galles est distinct (clarification du directeur); Ulster désigne les neuf comtés sans frontière de partition postérieure; l’Islande reste sous souveraineté danoise; Bruxelles est représentée en Flandre comme simplification de jeu; Alsace-Lorraine est allemande; Bosnie-Herzégovine est austro-hongroise; Trentin, Tyrol du Sud, Trieste et Istrie ne sont pas italiens. Ces précisions ne suffisent pas à définir les contours géométriques exacts.

Le registre des sources candidates est `data/world/map/sources/README.md`. Les sources examinées sont complémentaires et incomplètes : frontières nationales « c. 1914 », unités administratives à différentes dates (par ex. 1910/1920), carte russe raster au 1er janvier 1914 et données régionales à d’autres dates. Aucune ne livre seule les 90 géométries. L’archive REGIS obtenue pendant la recherche a échoué au contrôle d’intégrité et n’a pas été importée. Par conséquent, aucune géométrie, frontière partagée, adjacence, ville, infrastructure ou zone maritime n’est déclarée construite.

La table `region_plan.csv` constitue un index éditorial, et non une donnée de carte. Les IDs `region_001`–`region_090` sont réservés dans cet inventaire, mais les polygones et leur topologie restent à produire à partir de sources réutilisables et datées. Ne pas fabriquer de subdivisions pour atteindre le compte. `tools/map/validate_atlas.py` vérifie l’index et, lorsque le GeoJSON existera, les identifiants, attributs minimaux, validité et chevauchements géométriques. Il ne peut pas prouver l’exactitude historique ou l’absence de lacunes de couverture sans emprise de référence appropriée.

## 11. Points de conception / données cartographiques encore ouverts

- Références vectorielles historiques et licence de dérivation pour Russie, Balkans, territoires ottomans européens et autres lacunes nationales.
- Table détaillée d’appariement des unités administratives historiques à chacune des 90 régions; date et arbitrages de toute unité scindée/fusionnée.
- Tracés exacts des 90 frontières, emprise jusqu’à l’Oural et règle de couverture de toutes les îles/territoires visés.
- Liste géoréférencée des villes, reliefs et fleuves; topologie des côtes, routes, chemins de fer, ports, fortifications, ponts et cols.
- Nombre, limites et connexions des zones maritimes.
- Sources au niveau des objets, niveaux de précision, traitement des incertitudes, contrôle des superpositions et des petits écarts.

Le plafond ne dispense pas de ces contrôles : des régions très vastes ou hétérogènes peuvent masquer des incohérences, et les unités historiques ne correspondent pas toujours aux découpages de jeu demandés. Les licences incompatibles (notamment données ferroviaires non commerciales) ne doivent pas être incorporées sans analyse dédiée.
