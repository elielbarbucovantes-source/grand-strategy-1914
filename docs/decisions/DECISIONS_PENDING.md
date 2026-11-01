# Registre des décisions de conception en attente

**Statut :** initialisé à partir de `PROJECT.md`, `PROGRESS.md` et des spécifications du domaine. Aucune ligne ci-dessous ne vaut arbitrage du directeur. Une recommandation technique ne devient pas une règle de gameplay.

Utiliser les statuts `À DÉFINIR`, `PROPOSITION`, `VALIDÉ`, `BLOQUÉ`. Ajouter à chaque décision un identifiant, la source, l’arbitrage, la date et les documents affectés. Ne pas supprimer l’historique des décisions.

## A. Atlas et géographie

Les décisions suivantes sont **VALIDÉES par le directeur le 2026-11-01** ; elles sont consignées individuellement dans `docs/map/TECHNICAL_SPEC.md` :

- **MAP-DEC-01 à 04 : VALIDÉ.** Plafond 100 régions terrestres ; découpage hybride priorisant les frontières de 1914 ; Europe de l’Atlantique à l’Oural incluant Scandinavie/Balkans ; petits États importants gardent leurs régions, micro-États simplifiés.
- **MAP-DEC-05 à 10 : VALIDÉ.** Sites urbains limités aux catégories stratégiques ; relief régional intermédiaire ; rails visibles et infrastructures régionales ; routes visibles ; fleuves obstacles et transport ; fortifications historiques et évolutives.
- **MAP-DEC-11 à 16 : VALIDÉ.** Zones maritimes intermédiaires ; brouillard dynamique ; occupation distincte de souveraineté et victoire par contrôle militaire de 90 % de la carte ; résistance locale abstraite ; taille des régions répond aux trois dimensions d’importance ; détroits contrôlables.
- **MAP-DEC-17 à 21 : VALIDÉ.** Ports majeurs seulement individualisés ; priorités aux frontières historiques avec adaptation géographique ; débarquement sur côtes accessibles et facilité par ports ; grandes/îles stratégiques distinctes et autres simplifiées ; adjacency par frontières terrestres, routes/rails facilitent les déplacements.
- **MAP-DEC-22 à 26 : VALIDÉ.** Montagnes régionales et obstacles frontaliers ; ponts/passages facilitent franchissement des fleuves ; frontières politiques inchangées visuellement pendant occupation ; occupation hachurée aux couleurs de l’occupant ; style atlas historique et interface moderne.

Les choix suivants restent **À DÉFINIR** dans le travail cartographique en cours :

- **MAP-OPEN-01 — Atlas de régions :** nombre final (≤100), géométries, noms, identifiants, frontières précises et date/référence historique.
- **MAP-OPEN-02 — Découpage :** définition opérationnelle de « petit État important » et « micro-État » ; méthode d’arbitrage entre taille et frontières historiques, sans poids présumés.
- **MAP-OPEN-03 — Emprise/représentation :** limites exactes de l’emprise, projection de rendu, toponymie, statut des régions transcontinentales et détails des îles/territoires abstraits.
- **MAP-OPEN-04 — Relief/hydrographie :** affectation des classes aux régions, chevauchements, grands fleuves retenus, obstacles et passages précis.
- **MAP-OPEN-05 — Villes/sites :** liste et critères de grand port, centre industriel, forteresse et nœud ferroviaire ; sources et coordonnées.
- **MAP-OPEN-06 — Réseaux :** routes, chemins de fer, voies navigables, ponts, passages, dates et niveau de détail.
- **MAP-OPEN-07 — Fortifications :** inventaire, catégories, état historique et évolution représentée.
- **MAP-OPEN-08 — Mer/détroits/débarquements :** nombre et limites des zones, relations aux détroits, règle de contrôle, côte accessible et effet des ports.
- **MAP-OPEN-09 — Occupation/résistance :** règles et états de résistance, transition d’occupation et critères visuels de hachures.
- **MAP-OPEN-10 — Brouillard :** niveaux/portée de visibilité, fraîcheur des rapports et champs cartographiques visibles.
- **MAP-OPEN-11 — Victoire territoriale :** dénominateur exact de « 90 % de la carte » (régions terrestres seules ou autre), traitement des régions contestées/non attribuées et zones maritimes.
- **MAP-OPEN-12 — Données :** sources, qualité, licences et attributions des frontières, relief, démographie, industrie, fortifications, villes et réseaux.
- **MAP-OPEN-13 — Affichage :** palette, symboles, hachures, zoom, labels et critères d’accessibilité du style hybride.
- **MAP-OPEN-14 — Terminologie :** préciser si l’unité « région » de l’atlas est exactement l’unité « province » des documents de jeu existants, ou si une correspondance distincte est nécessaire.

## B. Données nationales et équilibre

- **NAT-01 — Douze statistiques : À DÉFINIR.** Formules, unités, échelles, arrondis, comparabilité et interactions.
- **NAT-02 — Population : À DÉFINIR.** Métropole, empire ou population abstraite ; traitement des territoires coloniaux.
- **NAT-03 — Départs historiques : À DÉFINIR.** Valeurs harmonisées des sept puissances et États secondaires, sources et date de référence.
- **NAT-04 — Notes d’équilibre : PROVISOIRE.** Évaluations comparatives existantes explicitement non officielles ; exclure des données runtime.
- **NAT-05 — Capacités des petits États : À DÉFINIR.** Traduction en limites crédibles sans règle arbitraire.

## C. Carte temporelle et résolution

- **TURN-01 — Phases internes : À DÉFINIR.** Ordre exact des systèmes et dépendances en conflit.
- **TURN-02 — Saisie et verrouillage : principe VALIDÉ, détails À DÉFINIR.** Commandes permises, modifications, abandon et rapports.
- **TURN-03 — Conflits simultanés : À DÉFINIR.** Résolution contextuelle sans avantage lié à l’ordre technique.
- **TURN-04 — Hasard et reproductibilité : À DÉFINIR côté conception / PROPOSITION technique.** Besoin d’aléatoire, visibilité et reproduction à partir d’une graine.
- **TURN-05 — Événements simultanés : À DÉFINIR.** Priorités, dépendances et présentation des conséquences.

## D. Économie et industrie

- **ECO-01 — Unités de ressource : À DÉFINIR.** Nourriture, matières premières agrégées et richesse.
- **ECO-02 — Production/consommation : À DÉFINIR.** Formules, départs par province/nation, rendement, réserves et pertes.
- **ECO-03 — Pénuries : À DÉFINIR.** Consommation, priorités et conséquences civiles/militaires.
- **ECO-04 — Commerce : À DÉFINIR.** Prix, marché, volumes, contrats, durée, frais, embargos et sanctions.
- **ECO-05 — Budget : À DÉFINIR.** Catégories, calcul mensuel, déficit et conséquences ; pas de dette détaillée sans validation.
- **ECO-06 — Industrie : À DÉFINIR.** Coûts/délais/rendements, amélioration, conversion, main-d’œuvre et effets sociaux.
- **ECO-07 — Territoires abstraits : À DÉFINIR.** Contribution aux ressources, revenus et profondeur stratégique.

## E. Militaire et logistique

- **MIL-01 — Ordre de bataille : À DÉFINIR.** Types d’unités, équipements, effectifs et correspondance unités/régiments/divisions/armées.
- **MIL-02 — Recrutement/mobilisation : À DÉFINIR.** Réserves, entraînement, équipement, remplacement et démobilisation.
- **MIL-03 — Mouvement : À DÉFINIR.** Coûts/durées, réseau, capacité, transit, ordres et interruptions.
- **MIL-04 — Approvisionnement : À DÉFINIR.** Portée, consommation, capacité, priorités, récupérations et isolement.
- **MIL-05 — Combat défensif stratégique : À DÉFINIR.** Modèle et lien avec offensives tactiques.
- **MIL-06 — Bataille tactique : À DÉFINIR.** Déclenchement, objectifs, durée effective (30 min maximum envisagées), forces engagées, commandes et victoire.
- **MIL-07 — Pertes et suite : principe des pertes définitives VALIDÉ, règles À DÉFINIR.** Retraite, capture, reconstitution, occupation et renouvellement d’offensive.
- **MIL-08 — Fortifications : À DÉFINIR.** Catégories, niveaux, coûts, effets ; ne pas anachroniser la ligne Maginot en 1914.
- **MIL-09 — Marine/aviation : À DÉFINIR.** Classes, ordres, contrôle, transport, patrouille, blocus, escortes et interaction aérienne.

## F. Diplomatie, IA et renseignement

- **DIP-01 — Relations : À DÉFINIR.** Échelles, évolution et pondération des intérêts.
- **DIP-02 — Accords : À DÉFINIR.** Catalogue, parties, durée, obligations, renouvellement, rupture, sanctions et clauses secrètes éventuelles.
- **DIP-03 — Acceptation/négociation : À DÉFINIR.** Options d’offre, refus, contre-offre et facteurs d’acceptation.
- **DIP-04 — Guerre/crise/paix : À DÉFINIR.** Déclaration, escalade, fin de guerre et règlement territorial.
- **DIP-05 — Information diplomatique : À DÉFINIR.** Confidentialité des accords et connaissance par les tiers.
- **AI-01 — Objectifs nationaux : À DÉFINIR.** Priorités, adaptation et réévaluation.
- **AI-02 — Décision : À DÉFINIR.** Architecture cognitive, poids, personnalité et risque.
- **AI-03 — Mémoire/apprentissage : À DÉFINIR.** Contenu, durée, persistance entre parties et effets ; aucun apprentissage implicite.
- **AI-04 — Limites d’information : principe VALIDÉ, détail À DÉFINIR.** Perception, fiabilité et actions anti-omniscience.
- **AI-05 — Évaluation : À DÉFINIR.** Protocoles et critères mesurables pour autonomie, diversité, cohérence, contraintes et erreurs crédibles.
- **INT-01 — Rapports : À DÉFINIR.** Catégories, fréquence, fiabilité, fraîcheur et délais.
- **INT-02 — Interception/décryptage : périmètre VALIDÉ, mécanique À DÉFINIR.** Capacités, coûts, temps et limites historiques.

## G. Politique, technologie, histoire, victoire

- **POL-01 — Institutions/réformes : À DÉFINIR.** Régimes, orientation, conséquences et options.
- **POL-02 — Révoltes/unité : principe d’existence VALIDÉ, formules/déclencheurs À DÉFINIR.**
- **TECH-01 — Arbre : modèle hybride et plafond 1945 VALIDÉS, contenu À DÉFINIR.** Branches, prérequis, coûts, durées, effets, spécialisations et transfert.
- **HIS-01 — Événements : principe non scripté VALIDÉ, catalogue À DÉFINIR.** Dates proposées, choix possibles et conséquences.
- **WIN-01 — Victoire territoriale : seuil de contrôle ≥90 % VALIDÉ, mesure/compte des territoires À DÉFINIR.**
- **WIN-02 — Victoire socio-économique : existence VALIDÉE, formule/mesure et seuil À DÉFINIR.**
- **WIN-03 — Paix collective : accord unanime et titre du traité VALIDÉS, négociation/signature/effets À DÉFINIR.**
- **WIN-04 — Conquête totale éliminant le joueur : principe VALIDÉ, procédure/état de fin À DÉFINIR.**

## I. Expérience produit et décisions techniques

- **UX-01 — Plateformes et cibles matérielles : À DÉFINIR.** Bloque le choix final du moteur/export.
- **UX-02 — Parcours, écrans, résolution, accessibilité et options : À DÉFINIR.**
- **ARCH-01 — Moteur/langage : PROPOSITION Godot 4.7.2 stable + GDScript typé.** Vérifier l’export par prototype non-gameplay après précision des plateformes.
- **ARCH-02 — Format cartographique : À DÉFINIR après atlas.** Garder le modèle séparé de la géométrie et du rendu.
- **ARCH-03 — Sauvegarde : PROPOSITION format versionné et migrations ;** durée de compatibilité et détail à définir.
- **ARCH-04 — Tests/CI : À DÉFINIR techniquement ;** déterminer après prototype, sans codifier des règles non validées.
- **ARCH-05 — Multijoueur : après solo VALIDÉ ;** exigences réseau, délais, reconnexion, confidentialité et hébergement À DÉFINIR.
- **ARCH-06 — Performance : À DÉFINIR.** Cibles de taille de carte, nombre d’États, durée de résolution et consommation mémoire.

## J. Autorisation de développement

- **GATE-01 — Développement gameplay : BLOQUÉ jusqu’à autorisation explicite du directeur.** La documentation et l’architecture peuvent être préparées ; aucun code de règles, simulation, IA, carte jouable ou interface de jeu ne doit être créé avant le feu vert.
