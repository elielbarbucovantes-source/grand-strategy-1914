# Données de carte

Les jeux de données réels ne sont pas encore ajoutés : la conception de l’atlas continue. Ne pas créer de régions, frontières, sites ou tracés par anticipation.

Sources éditables futures : couches GeoJSON décrites dans [`TECHNICAL_SPEC.md`](../../../docs/map/TECHNICAL_SPEC.md). Le schéma structurel se trouve dans [`data/schemas/map.schema.json`](../../schemas/map.schema.json). Le manifeste, une fois les sources choisies, enregistrera la version des données, références, licences, date et provenance.

Convention proposée : IDs stables en minuscules ASCII ; WGS 84/longitude-latitude pour l’échange RFC 7946 ; fichiers UTF-8, features triées par ID ; les couches de géométrie restent séparées de l’état de partie. Les valeurs de gameplay et les frontières initiales exigent une source validée.

Le plafond de 100 s’applique à `land_regions.geojson` uniquement. Il n’y a actuellement aucun fichier de données géographiques dans ce répertoire.

La spécification couvre 69 décisions validées. Les contrats décrivent également les futurs attributs possibles de présentation et d’état dynamique : couleur historique/préférence utilisateur, calques activables, flèches d’ordres, unités/agrégats, renseignements datés, batailles, événements, blocus, commerce maritime, influence, crises et ravitaillement. Ils ne sont ni des données de campagne ni des règles. Toute donnée dynamique doit être construite pour une vue d’observateur et respecter le brouillard ; ne jamais stocker ces marqueurs dans la source géographique statique.

Flux éditorial prévu : sources géographiques versionnées dans `source/`, tables de référence dans `tables/`, configuration visuelle séparée des données historiques, et éventuels états runtime séparés de ces deux familles. Les modifications de données géographiques nécessiteront provenance, licence, identifiants stables et validation topologique ; aucun processus d’import automatisé n’est encore implémenté.
