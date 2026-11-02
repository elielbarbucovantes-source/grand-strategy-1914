# Audit des données thématiques — atlas européen du 1er janvier 1914

- **Périmètre** : lots `agent_1` (50 régions) et `agent_2` (40 régions), sous `data/world/map/build/`.
- **Référence historique visée** : 1er janvier 1914.
- **Nature du livrable** : audit documentaire et structurel, sans modification des données sources, des géométries, de la topologie ni de l’adjacence.
- **Branche d’audit** : `audit/map-thematic-data`, worktree indépendant.
- **Conclusion** : les lots constituent un inventaire thématique utile, mais ne sont pas prêts à l’intégration canonique. Les absences de ressources et de routes, plusieurs points historiques et l’harmonisation des données restent à résoudre. Aucun point de cet audit ne vaut validation finale des géométries.

## 1. Résumé des constats

| Thème | État constaté | Décision d’audit |
|---|---|---|
| Régions et métadonnées | 50 + 40 enregistrements, couvrant les identifiants 001–090. Les lots déclarent la date `1914-01-01`; leurs dates et méthodes de provenance ne sont pas homogènes. | Inventaire thématique présent; validation géométrique distincte et préalable à toute intégration. |
| Villes et capitales | 103 + 72 = 175 entrées; identifiants et noms uniques dans l’échantillon comparé; 22 capitales signalées; chaque région référence des villes et les références testées existent dans son catalogue. | Bonne couverture structurelle; vérifier noms historiques et statut 1914 des sites sensibles. |
| Ports | 47 + 37 = 84 entrées, références présentes. Les ports réutilisent le catalogue de villes/sites. | Couverture livrée, sélection et statut de « port majeur » à sourcer et contrôler historiquement. |
| Fortifications | 32 + 33 = 65 entités; références présentes et année de référence 1914 dans le schéma des entités. | Inventaire documenté, mais une revue historique site par site reste requise. |
| Relief et terrains | 5 catégories autorisées et profils présents pour 90 régions; 29 + 32 entrées de fleuves et 11 + 11 massifs. Références de sources présentes. | Données livrées; harmonisation transfrontalière, valeurs nulles de classe insulaire et précision des classements à régler. |
| Chemins de fer | 76 + 53 = 129 axes, références présentes et sites d’extrémité connus dans les catalogues locaux. | Réseau partiel à l’échelle européenne : aucun axe entre lots, et au moins un axe grec comprend une section indiquée en travaux/achèvement 1914–1916. |
| Routes | Aucune couche, aucun axe ni inventaire routier dans les deux fichiers d’infrastructure examinés. | Donnée manquante par rapport à MAP-DEC-08; ne pas compléter sans inventaire historique sourcé et décisions de niveau de détail. |
| Ressources naturelles | Aucun champ `resources` renseigné dans les 90 fiches; aucune couche/collection de ressources dans les lots. | Donnée absente; le schéma prévoit un champ, mais types, unités, quantités et règles restent à définir. |
| Fleuves et reliefs stratégiques | Catalogues de fleuves, massifs et façades côtières disponibles; six fleuves et deux ensembles montagneux traversant la couture des lots sont scindés ou doublonnés d’après `ISSUES.json`. | Conserver la provenance, décider d’identifiants communs et vérifier le parcours/rattachement sans fusion automatique. |

## 2. Méthode et limites

J’ai examiné les structures JSON/GeoJSON, les métadonnées, les catalogues et les rapports de sources des deux lots, ainsi que `GLOBAL_AUDIT.md`, `ISSUES.json`, `INTEGRATION_CHECKLIST.md`, le schéma `data/schemas/map.schema.json` et les décisions de `docs/map/TECHNICAL_SPEC.md`. Des contrôles programmatiques non géométriques ont compté les entités, les identifiants, les références et les champs manquants. Les deux validateurs de lot ont été tentés, mais interrompus avant les tests en raison de l’absence de `shapely` dans l’environnement (`ModuleNotFoundError`).

Les mesures et anomalies géométriques reprises ci-dessous sont donc attribuées au rapport global et à son registre structuré, pas à une reproduction indépendante dans ce worktree. La validation des polygones, frontières, trous, chevauchements et coordonnées de sites doit être rejouée dans un environnement GIS conforme avant toute intégration. La présence d’une citation dans un catalogue ne prouve pas à elle seule chaque attribut individuel ni son exactitude historique.

Les dossiers sources se trouvent dans le worktree `fix/map-geometry-v2`, dont les ajouts étaient déjà indexés avant l’audit. Je les ai consultés en lecture seule; je n’ai modifié ni index, ni branche, ni contenu de ces lots.

## 3. Données validées au niveau documentaire et structurel

Ces points sont « validés » uniquement dans la portée des contrôles nommés ci-dessus, non comme validation géométrique définitive.

### Couverture des régions et métadonnées

- Les deux lots couvrent **90 identifiants distincts** : `agent_1` en contient 50 (`region_001`–`region_043`, `region_080`–`region_086`) et `agent_2` 40 (`region_044`–`region_079`, `region_087`–`region_090`). La répartition zonale concorde avec le plan dans le rapport global.
- Les deux fichiers `regions.json` indiquent `reference_date: 1914-01-01`, des sources par région et des unités historiques associées. Les productions ne sont toutefois pas équivalentes à une source administrative uniforme de 1914 : voir les réserves au §4.
- Les rapports des lots et les contrôles croisés disponibles documentent correctement plusieurs affectations majeures du 1er janvier 1914 : Alsace-Lorraine allemande, Trentin/Tyrol du Sud/Trieste/Istrie austro-hongrois, Irlande entière britannique avec Ulster géographique à neuf comtés, Islande danoise, et Danemark–Norvège indépendants depuis 1905. Voir les références historiques et les limites au §7.

### Villes, capitales et ports

- Comptage des catalogues : **175 villes/sites** (103 et 72), **22 entrées capitales** (11 par lot). Aucun identifiant ni nom français dupliqué entre lots n’a été observé lors du contrôle.
- Chaque fiche régionale possède au moins un `city_id`; tous les identifiants de villes testés existent dans le catalogue de leur lot. Les villes comportent des coordonnées et `source_refs`; les 22 capitales indiquent `capital_names_always_visible: true`, conformément à MAP-DEC-41.
- Les catalogues comptent **84 ports majeurs** (47 et 37); leurs références de site renvoient à des villes existantes dans le lot, et les entrées ont des références de sources.
- Réserve de portée : les listes représentent des sites sélectionnés, non un recensement exhaustif de toutes les localités ou installations portuaires. Le critère d’inclusion des « grands ports » et la sélection par région doivent être relus avant intégration.

### Relief, fleuves et massifs

- Les deux lots utilisent les cinq catégories prévues (`plains`, `forests`, `mountains`, `hills`, `marshes`) et contiennent un profil de terrain pour chacune des 90 régions.
- Les profils observés et les objets de fleuve/massif comportent des références de sources. Les catalogues contiennent ensemble 61 objets de fleuve et 22 objets de massif avant harmonisation; ce total n’implique pas 83 entités géographiques distinctes.
- Les références d’identifiants de région des cours d’eau contrôlées pointent vers des régions existantes dans leur lot. Les noms, étendues et classifications de relief ne sont pas certifiés au mètre ou par comparaison exhaustive à une base hydrographique historique.

### Chemins de fer, ports et fortifications

- Comptage : **129 axes ferroviaires**, **84 ports** et **65 fortifications**; aucun identifiant dupliqué parmi les axes et fortifications testés entre lots.
- Les axes ferroviaires disposent de `source_refs`; les identifiants de sites aux extrémités contrôlés existent dans les catalogues locaux. Ports et fortifications contrôlés disposent aussi de références.
- Les références déclarées comprennent notamment Bradshaw/Baedeker et des catalogues ferroviaires spécialisés cités par les README de lot. La compatibilité juridique et l’attribution de chaque source doivent rester liées à la version concrètement utilisée; ne pas déduire une licence d’un titre seul.

## 4. Erreurs, incohérences et données manquantes

### Blocages à traiter avant l’intégration de données canoniques

1. **Ressources naturelles absentes (90 régions).** Aucune fiche n’a de champ `resources`, aucune couche n’inventorie les ressources naturelles. Le schéma technique prévoit `resources`, mais le corpus indique que types, unités et quantités restent à définir. **Recommandation :** décider du périmètre (occurrence historique, réserve, production ou simple présence), choisir une source datée et une unité, puis documenter couverture et incertitude; ne pas inférer une ressource de la seule industrie ou d’un nom de lieu.
2. **Réseau routier absent.** Aucun axe de route ou fichier routier n’est livré malgré MAP-DEC-08 (réseau visible). **Recommandation :** décider d’abord l’échelle et la définition d’axe majeur, puis chercher une source historique datée et documenter explicitement les tronçons indisponibles. Ne pas fabriquer des routes pour relier les villes.
3. **Rail incomplet à l’échelle inter-lots.** Il existe 129 axes, mais aucun axe ne relie un site d’`agent_1` à un site d’`agent_2` (MAJ-002). Le graphe global est donc fragmenté au raccord des lots; la checklist propose dix corridors, qui sont des propositions à vérifier et non des segments à ajouter sans source. En outre, l’axe grec `rail_gr_athens_larissa_salonika` mentionne dans son libellé une jonction Papapouli–Platy « en travaux/achèvement 1914–1916 » : la partie non ouverte au 1er janvier 1914 ne doit pas être représentée comme une liaison en service à cette date. **Recommandation :** confronter chaque segment et sa date d’ouverture à Bradshaw 1913/1914, Baedeker ou aux horaires/archives ferroviaires; scinder ou dater les tronçons si nécessaire.
4. **Fleuves/massifs transfrontaliers non harmonisés.** MAJ-006 de l’audit recense Danube, Vistule, Dniestr, Niémen, Save et Drina séparés ou répétés d’un lot à l’autre, ainsi que Carpates et Alpes dinariques sous identifiants différents. Les deux listes consultées ont des IDs uniques à l’intérieur de chaque lot, mais aucun identifiant commun entre lots pour ces entités. **Recommandation :** faire arbitrer une identité stable et les segments/régions concernés, puis unifier seulement à partir d’une géométrie ou d’une source cohérente; distinguer les cours amont/aval si la géométrie des segments ne permet pas une entité continue.
5. **Anomalies historiques de frontières ayant un effet sur les rattachements thématiques.** Le rapport global signale Strumica (dans `region_074` Serbie plutôt que `region_072` Bulgarie au 1er janvier 1914) et le district de Saray dans `region_088` (exclave de Van et trou en Thrace). Ces erreurs touchent les géométries, que cet audit n’a pas corrigées; elles invalident les rattachements thématiques qui en dépendent jusqu’à validation géométrique. **Recommandation :** conserver les constats dans le registre d’intégration et recalculer/contrôler les rattachements des villes, reliefs, ports, voies ferrées et forts après correction autorisée de la géométrie.

### Incohérences d’harmonisation et documentation

- **Clé `island_class` nulle.** Les profils terrain utilisent `island_class: null` pour 54 régions (30 dans `agent_1`, 24 dans `agent_2`). Le schéma `map.schema.json` énumère des chaînes et n’autorise pas `null`; le rapport global recommande d’omettre la clé pour les régions continentales. **Recommandation :** à l’assemblage, omettre la clé lorsqu’elle n’a pas de valeur insulaire validée; ne pas inventer de classe.
- **Zones maritimes asymétriques.** `agent_2` fournit 16 zones et des références à `maritime_zone_ids`; `agent_1` n’a pas de fichier équivalent et ses 39 régions côtières n’ont pas de rattachement maritime. MAJ-001. **Recommandation :** attendre une décision sur les limites/connexions des zones maritimes, puis étendre la couverture à l’ouest et harmoniser les références. Ne pas dessiner de polygones de mer par simple extrapolation.
- **Métadonnées externes hétérogènes.** `agent_2` ajoute des clés `external_*` et `maritime_zone_ids`; les modèles d’adjacence ne sont pas unifiés. Voir BLK-003/MAJ-005. Les listes de voisins des lots ne sont pas une vérité canonique de graphe combiné.
- **Détroits et arêtes.** L’audit global relève une arête terrestre omise (`region_033`–`region_037`, 1,43 km), trois détroits en auto-boucle dans `agent_2` et quatre passages occidentaux manquants dans `agent_1` (MAJ-007). La vérification doit partir des géométries validées et définir si les détroits intra-régionaux sont des entités de passage internes, pas des auto-adjacences.
- **Toponymie/anachronismes.** `city_ekaterinoslav` est libellée « Ekaterinoslav (Dniepropetrovsk) » alors que le nom entre parenthèses est postérieur à 1914; la région 045 emploie « Oslofjord » quand l’audit propose le nom d’époque Kristianiafjord; les `historical_admin_units` ottomans utilisent des districts administratifs turcs modernes. OPT-001. **Recommandation :** privilégier les noms 1914 et déplacer les formes modernes dans une note de provenance si elles sont utiles à l’identification.
- **Incohérence documentaire de livraison.** Les HANDOFFs déclarent les lots « 100 % validés / 0 erreur », tandis que le rapport global consigne anomalies bloquantes et importantes; le HANDOFF d’`agent_1` annonce 14 interfaces externes alors que 16 y sont listées et que 17 sont rapportées géométriquement. `ATLAS_BUILD_STATUS.md` du dépôt principal décrit toujours un atlas non construit. **Recommandation :** distinguer validation locale de lot, audit global et statut canonique; ne déclarer aucun lot sans réserve « validé ».

### Données insuffisamment documentées ou à recontrôler

- **Villes et capitales :** les sites sont sourcés, mais certains noms sont anachroniques ou comportent des formes modernes. Vérifier en particulier les capitales et centres administratifs d’États ayant changé de frontière en 1913 (Balkans, Thrace) et les lieux de rattachement proches des frontières.
- **Ports :** une présence dans `major_ports` ne documente pas toujours dans la fiche elle-même la date d’existence, le statut de port commercial/naval ou le critère de « majeur ». Les références constituent une piste, pas une démonstration du statut au jour exact.
- **Fortifications :** 65 objets sont référencés; vérifier statut opérationnel, type et périmètre de chaque système en 1914, notamment les ouvrages en construction, modernisés ou regroupés sous une seule entrée.
- **Relief régional :** les classes sont qualitatives et non quantifiées; seuil de dominance, méthode d’agrégation et emprise des obstacles transfrontaliers ne sont pas définis. Les 54 `null` insulaires et 8 entités orographiques/hydrographiques inter-lots exigent harmonisation.
- **Réseau ferré :** vérifier les lignes dont le nom regroupe plusieurs itinéraires ou dont l’ouverture est postérieure/partielle; un axe schématique doit séparer tronçon attesté, géométrie indicative et statut d’exploitation.
- **Ressources :** aucune couverture ne permet de conclure à « absence de ressource » dans une région : données manquantes ne signifie pas zéro.

## 5. Cohérence historique au 1er janvier 1914

### Points concordants dans les sources consultées

Les notes des deux lots, l’audit global et les références évoquées (traités de 1913, couches administratives historiques REGIS/RISTAT et carte de contrôle Kavanagh) concordent sur plusieurs affectations importantes :

- frontières balkaniques à contrôler après les traités de Londres (mai 1913), Bucarest (10 août 1913) et Constantinople (29 septembre 1913);
- Strumica bulgare en 1914, non yougoslave (cession de 1919);
- Dobroudja du Sud roumaine après 1913; Thrace occidentale égéenne bulgare; Edirne ottomane après 1913;
- territoires austro-hongrois du Trentin, Tyrol du Sud, Trieste et Istrie distincts du Royaume d’Italie;
- Schleswig du Nord encore allemand en 1914; Islande danoise; Norvège indépendante depuis 1905; Alsace-Lorraine allemande;
- Karaağaç encore ottomane au 1er janvier 1914 selon les notes du lot, avant la convention de 1915.

Ces vérifications sont des contrôles d’affectation ponctuels, pas la certification complète des 175 villes ni de tous les objets.

### Réserves et défauts historiques identifiés

- La frontière de Strumica est bâtie en partie sur une couche yougoslave de 1948–1954 : elle incorpore un saillant postérieur à 1914 dans la région serbe. Une source d’époque ou une limite documentée du traité de Bucarest est nécessaire à la correction.
- Le polygone de `region_088` est affecté par l’homonymie de Saray entre Tekirdağ et Van; la bbox rapportée s’étend jusqu’à 44,33°E et le polygone contient une partie anatolienne. C’est incompatible avec une région de Thrace au 1er janvier 1914.
- Les sources de frontière ne sont pas toutes de 1914 : RISTAT décrit 1897, REGIS utilise des périodes pluriannuelles variables, les frontières administratives contemporaines de Turquie servent de proxy et certaines unités balkaniques sont des couches postérieures. Ces limites peuvent servir de supports, mais leurs écarts et corrections doivent être identifiés objet par objet.
- L’axe grec avec un segment annoncé en travaux/achèvement 1914–1916 ne peut être pris comme entièrement en exploitation au 1er janvier. Dater et valider le tronçon.
- Les dénominations Ekaterinoslav/Dniepropetrovsk et Kristianiafjord/Oslofjord doivent distinguer noms d’époque et alias modernes.

## 6. Corrections recommandées et ordre de traitement

1. **Geler l’intégration canonique des données thématiques** jusqu’à la validation indépendante des géométries, selon la contrainte du mandat. Ce rapport n’autorise ni la fusion ni la correction de polygones.
2. **Traiter d’abord les deux erreurs historiques/géométriques structurantes** Saray (`BLK-001`) et Strumica (`MAJ-003`) dans le processus autorisé de géométrie, puis refaire les contrôles de rattachement des objets proches.
3. **Résoudre la couture et l’adjacence** : traiter les 4 lacunes inter-sources (`MAJ-004`), les 15 micro-chevauchements (`BLK-002`) si le validateur canonique les considère bloquants, les 17 interfaces inter-lots et l’arête manquante. Ne pas combler automatiquement le lac Ladoga, Sivach ou le lac de Ratzebourg, documentés comme plans d’eau.
4. **Harmoniser les schémas sans déduire de contenu** : supprimer les clés nulles incompatibles, convenir du format commun de `regions`, `terrain`, `adjacency` et des zones maritimes, unifier les IDs des fleuves/massifs après revue de leurs courses.
5. **Réexaminer chaque axe ferroviaire** à la date de référence et ajouter uniquement les raccords vérifiés par une source d’époque. La liste de dix axes de la checklist est à instruire, pas à importer telle quelle.
6. **Décider les spécifications des lacunes thématiques** : inventaire de routes et ressources naturelles, critères de sélection des ports, niveaux de preuve requis pour les forts et les classes de terrain. Si aucune source fiable n’est disponible, garder explicitement le statut « non documenté ».
7. **Rejouer les validateurs géométriques et référentiels** dans l’environnement GIS requis, puis produire un compte-rendu des tests et de leurs versions. Mettre à jour les HANDOFFs et le statut canonique uniquement après validation et décision compétente.

## 7. Sources historiques et documentaires citées

Les sources ci-dessous sont celles citées dans les README de lots, les données et le rapport d’audit. Elles doivent accompagner les objets dérivés avec version, licence et référence complète; leur citation ici n’implique pas que toutes aient été vérifiées directement pendant cet audit.

1. **Schweikart et al., REGIS — Regional Historical GIS of Europe / DATA-TOC** (couches nationales à périodes variables, dont 1870–1919 et 1905–1918 selon pays), DOI cité : `10.1007/978-3-032-14932-9_3`; attribution et licence annoncées par le lot : CC BY 4.0. Principal support des unités administratives européennes, avec limites temporelles signalées.
2. **Kessler & Markevich, RISTAT — Administrative boundaries of the Russian Empire, 1897**, DataverseNL, DOI `10.34894/NQOASN`; lot 2 annonce CC0 1.0. Source de subdivisions russes, distincte de la date cible et à contrôler pour les réorganisations jusqu’en 1914.
3. **Aoife Kavanagh / UCD, Europe 1914 GeoJSON / Map of Europe c. 1914**, DOI cité `10.5281/zenodo.21341486`; les lots l’annoncent CC BY 4.0. Référence de contrôle des frontières internationales, pas source complète des 90 subdivisions.
4. **geoBoundaries, frontières administratives de Turquie ADM1/ADM2** (version citée `geoboundaries_tur_v6`), Runfola et al.; les lots annoncent CC BY 4.0. Proxy contemporain utilisé pour la Thrace; il ne remplace pas un tracé ottoman de 1914 et a causé l’erreur d’homonymie Saray décrite dans l’audit global.
5. **Esteban-Oliver & Martí-Henneberg (2023), Historical European Railway Map (1830–1910/1914), COREDEM / Dataverse**, DOI `10.34810/data917`; lot 1 annonce CC BY 4.0. Source de contrôle des chemins de fer, période/segments à valider.
6. **Ciccarelli & Groote (2017), Railway Endowment in Italy’s Provinces, 1839–1913**, Mendeley Data, DOI `10.17632/rjwccjgy7z.1`; lot 1 annonce CC BY 4.0.
7. **Bradshaw, Continental Railway, Steam Transit and General Guide**, éditions 1913–1914; et **Baedeker**, guides régionaux 1911–1914, tels que listés dans les README d’agent. Références contemporaines utiles aux villes, ports, itinéraires et fortifications; chaque édition doit être précisée dans les références objet.
8. **Natural Earth Physical Vectors 1:10m**, version citée 5.1.2 (domaine public/CC0 annoncé par lot 2) : appui de géographie physique moderne, pas preuve suffisante d’un statut historique.
9. **Atlas militaires et ouvrages Séré de Rivières / fortifications européennes** : cités comme sources de fortifications, mais références bibliographiques détaillées à ajouter objet par objet lorsqu’elles fondent le type ou le statut.
10. **Traités de Londres (1913), Bucarest (10 août 1913), Constantinople (29 septembre 1913), convention de Sofia (1915) et traité de Neuilly (27 novembre 1919)** : cadres chronologiques utilisés dans les notes et l’audit pour contrôler Balkans/Thrace. Ajouter les références éditées/archives précises aux corrections de frontière, notamment Strumica et Karaağaç.
11. **Audit du dépôt** : `docs/map/audit/GLOBAL_AUDIT.md`, `docs/map/audit/ISSUES.json` et `docs/map/audit/INTEGRATION_CHECKLIST.md`; références secondaires internes qui consignent résultats et actions proposées. Ne pas confondre leurs recommandations avec des données historiques sources.

## 8. Bilan de préparation à l’intégration

### Prêts à être repris après validation géométrique et harmonisation de schéma

- Inventaire d’identifiants des 90 régions et métadonnées générales, à condition de conserver la provenance, les périodes sources et les approximations.
- Catalogues de villes/sites (175), ports majeurs (84), fortifications (65) et axes ferroviaires (129) comme **candidats documentés**, sous réserve de revalidation historique des éléments signalés et de références conformes au schéma commun.
- Profils qualitatifs de terrain et catalogues de fleuves/massifs comme **brouillons sourcés**; IDs et étendues transfrontalières nécessitent harmonisation.
- Contrôles ponctuels confirmant plusieurs souverainetés et affectations majeures de 1914, tels que listés au §5.

### Nécessitent une décision, une source supplémentaire ou une validation avant intégration

- **Tout fichier canonique et toute géométrie** : bloqués par la validation géométrique explicite; aucune donnée n’a été intégrée par le présent travail.
- Correction de Saray/Van, Strumica, lacunes de couture, micro-chevauchements et complétude du graphe d’adjacence.
- Continuité des voies ferrées, date d’ouverture des tronçons, notamment Papapouli–Platy; routes absentes.
- Ressources naturelles absentes et leur modèle (types, présence/quantité/production, unité, source, date, incertitude).
- Inventaire et limites des zones maritimes à étendre à l’ensemble des côtes; aucun rattachement arbitraire.
- Harmonisation des fleuves et massifs, topologie des détroits, champ `island_class`, alias historiques et unités ottomanes modernes.
- Validation du statut individuel des ports, forts, reliefs et localités, ainsi que des licences/version des sources.

**Verdict :** l’index de régions, les catalogues thématiques et leurs références forment une base de travail, pas un jeu de données prêt à intégrer. Aucun élément géométrique n’est déclaré prêt; les thèmes bien sourcés peuvent être réexaminés après validation des polygones, traitement des anomalies bloquantes et arbitrage des points ouverts ci-dessus.
