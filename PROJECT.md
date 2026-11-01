
# GRAND STRATEGY-1914 --- Document maître du projet

Version : 1.1\
Statut : conception en cours ; architecture et fondations documentaires préparées ; gameplay interdit jusqu’à autorisation explicite du directeur\
Langue de référence : français

## 1. Identité du jeu

**Grand Strategy-1914** est un jeu de grande stratégie géopolitique et
militaire prenant pour point de départ l'Europe de 1914. Le joueur
dirige un pays en tant que chef de l'État. Les autres pays sont dirigés
par des intelligences artificielles autonomes.

La formule directrice du projet est :

> Le joueur dirige son pays, mais ne dirige pas le monde.

Le joueur peut décider de la politique de son pays, organiser son
économie, commander ses forces, négocier et prendre des risques. Il ne
peut pas imposer aux autres nations leurs décisions. Les autres États
poursuivent leurs propres intérêts, peuvent coopérer, refuser, se
tromper, mentir, changer d'orientation ou entrer en guerre.

## 2. Les trois piliers

Le jeu doit équilibrer trois priorités de même importance :

1.  **Profondeur stratégique** : des décisions nationales ayant des
    conséquences durables et interdépendantes.
2.  **IA autonome convaincante** : les pays non contrôlés doivent agir
    comme des acteurs politiques indépendants, pas comme des figurants
    attendant le joueur.
3.  **Réalisme historique** : les situations de départ, les capacités
    nationales, les contraintes géographiques et les rapports de force
    doivent être crédibles.

Le réalisme recherché est un réalisme stratégique, pas une simulation
exhaustive de chaque individu, entreprise ou administration.

## 3. Périmètre

### Inclus dans la première version

-   Une campagne historique commençant en 1914.
-   L'Europe comme espace de jeu.
-   Sept grandes puissances jouables.
-   Les autres États européens contrôlés par l'IA.
-   Une carte divisée en provinces intermédiaires.
-   Des tours mensuels à résolution simultanée.
-   Diplomatie, économie, industrie, recherche, renseignement, politique
    intérieure.
-   Armées organisées hiérarchiquement.
-   Batailles tactiques distinctes déclenchées uniquement par les
    offensives.
-   Mode solo initial.
-   Mode observation permettant de suivre une partie entièrement gérée
    par l'IA et de prendre le contrôle d'un pays en cours de partie.

### Hors périmètre initial

-   Gestion détaillée des populations individuelles.
-   Simulation parlementaire détaillée.
-   Gestion provinciale de stocks économiques autonomes.
-   Opérations clandestines complexes, sabotage et coups d'État pilotés
    par le joueur.
-   Carte jouable mondiale complète.
-   Campagnes historiques multiples.
-   Multijoueur dans la première version.
-   Technologies au-delà de 1945.

Les colonies sont représentées de manière abstraite comme des
territoires apportant ressources, revenus et profondeur stratégique.
Elles ne constituent pas une carte coloniale détaillée dans la première
version.

## 4. Pays jouables

Les sept puissances jouables sont : - Empire allemand - Royaume-Uni /
Empire britannique - France - Empire russe - Autriche-Hongrie - Italie -
Empire ottoman

Les autres États européens sont autonomes et contrôlés par l'IA. Leur
puissance demeure contrainte par leurs capacités historiques : un petit
État ne doit pas devenir une superpuissance uniquement grâce à une
stratégie artificiellement optimale.

Les caractéristiques nationales ne sont pas figées. Elles peuvent
évoluer avec les investissements, les réformes, les changements de
régime et les événements.

## 5. Les douze statistiques nationales

Chaque pays possède douze indicateurs : 1. Population totale 2.
Puissance démographique 3. Industrie 4. Économie 5. Ressources
naturelles 6. Armée de terre 7. Marine 8. Technologie 9. Infrastructures
10. Diplomatie 11. Prestige international 12. Unité nationale

Les valeurs doivent être lisibles, arrondies et comparables entre les
puissances. Les méthodes de calcul, échelles et pondérations restent à
formaliser. Il faut notamment préciser si les statistiques de population
se rapportent à la métropole, à l'empire ou à une population totale
abstraite.

L'unité nationale est un indicateur synthétique unique. La première
version ne simule pas en détail chaque communauté ethnique, linguistique
ou nationale.

## 6. Carte et géographie

-   Carte limitée à l'Europe.
-   Provinces de taille intermédiaire, inspirées de régions historiques.
-   Les provinces sont indivisibles dans la première version.
-   Les frontières commencent dans leur configuration de 1914 et peuvent
    évoluer par guerre, traité ou négociation.
-   Les terrains stratégiques comprennent notamment plaines, forêts,
    montagnes, marais, fleuves, littoraux, détroits et passages.
-   Les villes importantes sont sélectionnées : capitales, centres
    industriels, ports, nœuds ferroviaires et forteresses.
-   Les autres localités ne sont pas toutes représentées
    individuellement.
-   Les espaces maritimes sont divisés en zones intermédiaires,
    suffisamment nombreuses pour gérer routes, passages, patrouilles,
    blocus et escortes sans microgestion excessive.

Décisions cartographiques complémentaires validées le 1er novembre 2026 :
plafond de 100 régions terrestres ; découpage hybride privilégiant les
frontières historiques de 1914 ; Europe de l’Atlantique à l’Oural,
Scandinavie et Balkans compris ; petits États importants préservés et
micro-États simplifiés ; réseaux ferroviaire et routier visibles ; relief
intermédiaire ; fleuves comme obstacles et voies de transport ; ports
majeurs seuls individualisés ; fortifications évolutives ; zones maritimes
intermédiaires et détroits contrôlables ; débarquements sur les côtes
accessibles, facilités par les ports ; traitement différencié des îles ;
résistance locale abstraite ; occupation figurée par hachures de l’occupant
sans déplacement visuel des frontières souveraines. Le style combine atlas
historique et interface stratégique moderne. La spécification technique et
les points restant à définir sont suivis dans `docs/map/TECHNICAL_SPEC.md`.

Les positions exactes des provinces, leur nombre, leurs frontières et
les données cartographiques restent à définir dans un atlas de
conception dédié.

## 7. Temps et résolution

-   Un tour représente un mois.
-   Les joueurs humains et les IA préparent leurs ordres simultanément
    et secrètement.
-   Les ordres sont ensuite résolus ensemble.
-   En solo, le temps de réflexion peut être illimité.
-   En multijoueur futur, la limite de préparation des ordres doit être
    configurable.

Les règles de priorité et de résolution des ordres contradictoires
doivent tenir compte du contexte : diplomatie, alliances, accords,
forces engagées, ordres reçus et statut des provinces.

## 8. Déplacements et logistique

Le joueur choisit une destination. Le jeu calcule le trajet et sa durée
en fonction de la géographie, des infrastructures et des conditions
stratégiques.

Le transit par un territoire étranger nécessite une autorisation. Une
alliance ou un accord peut prévoir le passage ou le stationnement. Une
entrée non autorisée constitue une violation de souveraineté et peut
provoquer une crise ou une guerre.

La logistique repose sur des réseaux : routes, voies ferrées, ports et
continuité territoriale. Une armée mal approvisionnée voit son
efficacité au combat diminuer, ses déplacements ralentir et son
rétablissement devenir plus difficile. Un isolement prolongé peut
entraîner des pertes et la désagrégation de la force.

La centralisation des stocks économiques nationaux ne signifie pas que
les armées peuvent recevoir instantanément les ressources :
l'acheminement militaire reste soumis au réseau logistique.

## 9. Diplomatie

La diplomatie est un système d'interaction entre États autonomes. Les
accords et engagements ont des conséquences. Les pays peuvent négocier,
refuser, conclure des accords, former des coalitions, modifier leurs
relations ou trahir leurs engagements.

Les relations historiques ne sont pas des scripts obligatoires. Elles
constituent le contexte de départ et influencent les décisions
initiales.

Exemples de situations de départ : - Alliance franco-russe. - Entente
cordiale entre la France et le Royaume-Uni, sans obligation automatique
d'entrée en guerre britannique. - Alliance allemande avec
l'Autriche-Hongrie. - Italie membre de la Triple Alliance mais neutre au
début de la campagne. - Rivalité russo-austro-hongroise dans les
Balkans. - Rapprochement ottoman-allemand, sans automatisme historique
imposé.

Les catégories d'accords, les règles de négociation, la confiance et les
sanctions doivent être détaillées avant implémentation.

## 10. Économie

Trois ressources principales : - Nourriture - Matières premières
(catégorie regroupant notamment charbon, acier, pétrole et minerais) -
Richesse

Chaque pays possède un stock national centralisé. La production
provinciale alimente ce stock national ; les provinces ne conservent pas
de stocks économiques indépendants dans la première version.

Le commerce international est hybride : - marché avec prix variables ; -
contrats bilatéraux négociables (quantité, prix, durée) ; - embargos et
restrictions ; - conséquences en cas de rupture d'engagement.

Le budget national est simplifié et mensuel. Les recettes proviennent
notamment de la production de richesse, du commerce et des territoires.
Les dépenses couvrent armée, marine, industrie, recherche et
administration. La première version ne simule pas en détail l'impôt ou
la dette publique.

## 11. Industrie

Les usines sont localisées dans les provinces, mais contribuent à une
capacité industrielle nationale. Leur rendement dépend notamment des
ressources et infrastructures. Elles peuvent être capturées ou
détruites.

Cinq catégories : 1. Industrie militaire terrestre 2. Industrie
aéronautique 3. Industrie navale 4. Industrie civile 5. Munitions et
équipements

Le joueur peut construire des usines, les améliorer, convertir de
l'industrie civile et mobiliser la main-d'œuvre. La mobilisation
industrielle a des conséquences économiques et sociales.

Les coûts, temps de construction, rendements et formules ne sont pas
encore validés.

## 12. Forces armées et batailles

L'organisation militaire est hiérarchique :

**Soldats et équipements → unités → régiments → divisions → armées.**

Le joueur organise les formations et leur composition. Les détails de
l'échelle exacte, des effectifs et des catégories d'unités restent à
définir.

Les échanges défensifs ordinaires sont résolus sur la carte stratégique.
Seules les offensives déclenchent une bataille tactique distincte. La
bataille est directement contrôlable, inspirée de l'approche de *Lines
of Battle*, avec une durée maximale envisagée de 30 minutes. Les forces
tactiques sont proportionnelles à la mobilisation stratégique. Le
terrain et les fortifications influencent la bataille. Les pertes sont
définitives. Une offensive victorieuse permet à l'attaquant d'occuper la
province. Une offensive perdue peut être renouvelée, mais les pertes et
l'état des forces persistent.

Les règles tactiques précises, les conditions de victoire, les limites
d'unités et l'interface restent à concevoir.

## 13. Politique intérieure

Le joueur exerce un contrôle politique direct à l'échelle nationale :
réformes, régime et orientation générale du gouvernement. Le jeu calcule
les conséquences. Il n'y a pas de simulation détaillée des parlements et
partis dans la première version.

Les révoltes, changements de régime et variations d'unité nationale
doivent néanmoins être possibles et significatifs.

## 14. Recherche et technologie

Arbre technologique hybride : - branches de recherche ; - prérequis ; -
investissements ; - possibilité de recherches précoces à coût ou durée
plus élevés ; - plafond technologique fixé à 1945.

Les pays commencent avec des spécialisations scientifiques historiques,
mais celles-ci peuvent évoluer par investissement. Les branches,
technologies, coûts et effets restent à définir.

## 15. Renseignement

Le renseignement initial couvre : - renseignement militaire ; -
renseignement économique ; - renseignement technologique ; -
interception et décryptage ; - rapports immédiats et périodiques.

Les opérations de sabotage, contre-espionnage avancé et opérations
politiques clandestines sont exclues de la première version.

## 16. Intelligence artificielle

L'IA doit être autonome au maximum. Elle définit ses objectifs, négocie,
forme des coalitions, déclare la guerre, peut mentir, manipuler ou
trahir, conserve une mémoire stratégique et apprend de ses expériences.

Elle n'est pas omnisciente et peut se tromper. Elle doit respecter les
limites d'information et de capacité de son pays.

Tous les États non jouables utilisent le même cadre général d'autonomie,
avec des capacités et ambitions adaptées à leur taille et à leur
situation.

## 17. Histoire et victoire

Une seule campagne historique commence en 1914. Les événements
historiques peuvent être proposés à certaines dates, mais le joueur ou
l'IA peut les accepter, les refuser, les influencer ou les éviter.
L'histoire n'est pas une suite de résultats obligatoires.

Trois conditions de victoire : - **Victoire territoriale** : contrôle
militaire d'au moins 90 % de la carte. La portée exacte du dénominateur
(notamment régions terrestres et zones maritimes) reste à préciser dans
la conception cartographique. - **Victoire socio-économique** :
atteindre un niveau exceptionnel de développement humain par rapport aux
autres pays. La formule exacte reste à définir. - **Victoire collective
/ match nul** : accord de tous les pays pour signer le « Traité de paix
et d'unité internationale ».

La conquête totale élimine le joueur.

## 18. Modes de jeu et développement

-   Première version : solo.
-   Architecture conçue pour permettre le multijoueur ultérieur.
-   Mode observation : toutes les nations sont contrôlées par l'IA ; le
    joueur peut suivre les négociations, guerres et événements, puis
    prendre le contrôle d'un pays en cours de partie.

Le projet est actuellement en phase de conception. Aucun agent ne doit
commencer à implémenter les mécaniques de gameplay sans autorisation
explicite du directeur de conception.

L’architecture technique peut être préparée et documentée avant cette
autorisation. La création ou modification de code de jeu (moteur de tours,
simulation, IA, économie, diplomatie, armée, carte jouable ou interface de
jeu) reste interdite jusqu’au feu vert explicite. Un outil purement
technique isolé pourra être proposé séparément, mais ne doit pas contenir
de règle ou donnée de gameplay.

## 19. Règles de gouvernance

-   Les décisions validées dans cette documentation sont la référence.
-   Une proposition d'agent n'est pas une décision validée.
-   Les éléments marqués « À DÉFINIR » ne doivent pas être
    arbitrairement figés.
-   Toute contradiction doit être signalée avant modification.
-   Toute évolution importante doit être proposée avec ses avantages,
    inconvénients et conséquences sur les trois piliers.
-   Les simplifications doivent préserver la profondeur stratégique,
    l'autonomie de l'IA et la crédibilité historique.
-   Les consignes d’exécution du dossier initial qui demandaient une
    première partie jouable sont remplacées par la règle de gel ci-dessus.
    Elles ne constituent plus une autorisation de développer le gameplay.
-   L’architecture technique adoptée est documentée dans
    `docs/architecture/TECHNICAL_ARCHITECTURE.md` ; la spécification de
    carte dans `docs/map/TECHNICAL_SPEC.md` reste provisoire et ne fixe
    aucun atlas de conception.
