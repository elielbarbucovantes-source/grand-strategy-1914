# Architecture technique cible

**Statut : PROPOSITION technique pour fondations ; aucun gameplay autorisé.**
**Version :** 1.0 — à confirmer par prototype technique avant production.

## 1. Objectifs et contraintes

L’architecture doit soutenir le périmètre VALIDÉ du projet sans anticiper les règles À DÉFINIR : campagne solo européenne de 1914, nations autonomes, tours mensuels avec ordres secrets simultanés, résolution contextuelle, carte stratégique et bataille tactique distincte pour les offensives. Elle doit permettre aux systèmes économiques, diplomatiques, militaires, politiques, technologiques et de renseignement d’évoluer séparément. Le multijoueur est hors V1, mais ne doit pas être rendu impossible.

### Recommandation de pile

- **Moteur : Godot 4.7.2 stable (standard, sans .NET) comme version de départ recommandée.** Godot fournit scènes, rendu 2D, UI, ressources et export multiplateforme. Le jeu est dominé par carte, panneaux et simulation plutôt que par rendu 3D. Confirmer l’export des plateformes ciblées pendant le prototype technique, puis épingler la version et les modèles d’export dans la documentation d’environnement.
- **Langage : GDScript typé** pour l’application, les scènes et la simulation initiale : intégration native, cycle d’itération simple et un seul runtime au départ. N’envisager C# qu’après mesure d’un besoin réel (performance, outillage ou recrutement).
- **Dépendances :** aucune bibliothèque de gameplay tierce à ce stade. Employer les capacités natives ; choisir séparément un runner de tests, outils SIG ou transport réseau uniquement si les besoins confirmés l’exigent.
- **Données :** formats lisibles et schématisés pour les référentiels et sauvegardes ; JSON est la recommandation initiale pour les contrats/fixtures. Le format géométrique de la carte reste ouvert et dépendra du travail de conception cartographique.
- **Tests :** tests de logique hors scènes lorsque possible, complétés par tests d’intégration des contrats. L’outil exact sera figé après prototype technique.

Cette pile est un choix technique réversible. Le type de jeu convient à Godot : UI 2D, visualisation de carte, données de simulation et scènes de bataille isolables. Les inconnues (plateformes, taille/format de l’atlas, volume de l’état, performance de l’IA, rendu des batailles, accessibilité et expérience de l’équipe) se vérifieront avec un prototype technique neutre. Si elles révèlent une incompatibilité majeure, documenter une ADR comparative avant tout changement de pile. Pas de code gameplay pendant cette vérification. La version est retenue à partir de la [page officielle des versions Godot](https://godotengine.org/download/archive/) ; les préversions ne sont pas la base du projet.

## 2. Vue en couches

```text
┌───────────────────────────────────────────────────┐
│ UI Godot : carte, panneaux, rapports, vues tactiques│
└───────────────────────┬───────────────────────────┘
                        │ commandes / vues autorisées
┌───────────────────────▼───────────────────────────┐
│ Application : session, phase, commandes, saves    │
└───────────────────────┬───────────────────────────┘
                        │
┌───────────────────────▼───────────────────────────┐
│ Orchestrateur de tour : collecte, verrouillage,    │
│ résolution, événements, journal                    │
└──────────────┬────────┴────────────┬──────────────┘
               │                     │
       ┌───────▼────────┐    ┌───────▼─────────┐
       │ Systèmes métier │    │ IA par nation   │
       │ indépendants    │    │ vue limitée     │
       └───────┬────────┘    └───────┬─────────┘
               └────────────┬────────┘
                            ▼
          État sérialisable + journal d’événements
                            │
                 Adaptateurs stockage local
                 (réseau futur derrière contrat)
```

### Règle de dépendance

Les systèmes métier dépendent du noyau de contrats, jamais de l’interface, du stockage concret ou du transport. Aucun module métier n’appelle directement un autre domaine. Il émet des changements déclaratifs/événements ; l’orchestrateur gère les interactions. Les dépendances entre domaines sont ainsi visibles, testables et décidées sans créer de dépendances circulaires.

## 3. Moteur de tours mensuels

Le cycle mensuel doit refléter la séquence VALIDÉE : produire les informations accessibles → préparer commandes du joueur et décisions IA en parallèle logique → verrouiller → résoudre simultanément et contextuellement → appliquer les conséquences → présenter rapports et événements → ouvrir le mois suivant.

L’architecture propose ces états d’application : `PLANNING`, `LOCKED`, `RESOLVING`, `REPORTING` et `PAUSED`. Ce sont des états techniques d’orchestration, pas de nouvelles phases de règles ; leur granularité reste à confronter aux règles finales.

- Les commandes sont validées à la saisie puis revalidées contre l’état verrouillé.
- L’IA reçoit une `NationView` dérivée des informations accessibles à cette nation ; elle prépare avec la même API de commandes que le joueur.
- La fonction de résolution reçoit état initial, commandes verrouillées, données/règles versionnées et éventuellement une graine déterministe. Elle retourne un nouvel état et un journal ; éviter les effets partiels visibles pendant la résolution.
- L’ordre interne des sous-systèmes est **À DÉFINIR** par le concepteur. Les dépendances (p. ex. accord de transit vs mouvement, occupation vs production) sont enregistrées comme conflits d’ordre et résolues selon règles validées, pas par un ordre arbitraire de code.
- À résolution égale, départ et commandes égaux doivent produire le même résultat autant que possible. Toute source de hasard doit être injectée et enregistrée ; aucune dépendance à l’heure système ou à l’ordre non spécifié d’une collection.
- En solo, le joueur peut rester en planification sans limite de temps. Les délais configurables ne s’ajoutent qu’avec une spécification multijoueur.

## 4. Modèle des pays et des données

Séparer trois catégories :

1. **Référentiel historique (`WorldDefinition`)** : identifiants stables, noms localisés, données de départ sourcées, associations pays/provinces/réseaux et catalogues approuvés. Immuable pendant une partie sauf changement de frontière prévu par les règles.
2. **État courant (`GameState`)** : données mutables de campagne, horloge, possession/contrôle, stocks, unités, accords, recherches, état politique, mémoire/ordres IA et métadonnées de sauvegarde, mais uniquement quand les systèmes sont spécifiés.
3. **Vues nationales (`NationView`)** : projection filtrée d’informations connues par chaque acteur. Ne jamais passer l’état complet à l’IA ou à l’interface d’un pays si les règles ne l’autorisent pas.

Tous les objets métier utilisent un `id` stable, indépendant du nom affiché. Utiliser des dictionnaires indexés par identifiant pour accéder aux entités et une liste triée/ordre explicite lors des résolutions. Ne pas coder en dur des noms ou chiffres comme identifiants.

Les douze statistiques nationales existent dans le design, mais leurs définitions calculables, échelles et champs ne sont pas définies. Le contrat peut réserver un espace extensible sans fixer leur type/unité avant décision. Les données provisoires et historiques doivent porter provenance, statut et unité.

## 5. Architecture cartographique

Le modèle logique distingue carte statique et état de campagne :

- `MapDefinition` : géométries et topologie ; province, zone maritime, nœud, arête, terrain, ville et infrastructure lorsqu’ils sont définis.
- `TerritorialState` : souveraineté/propriété, contrôle militaire, occupation et changements par tour. Propriété et contrôle sont des concepts distincts selon le gameplay validé.
- `MapView` : rendu découplé ; sélection, zoom, surbrillance des chemins et surcouches d’information ne modifient pas les règles.
- `Pathfinding` : service pur recevant topologie et contraintes fournies par les systèmes ; les règles de déplacement, transit, coût et durée restent dans les modules métier et attendent validation.
- Les mers sont des zones intermédiaires selon le concept validé ; leur géométrie, quantité, adjacence et règles restent ouvertes.

La spécification technique séparée `docs/map/TECHNICAL_SPEC.md` prépare l’import, validation, rendu et stockage tout en protégeant l’espace de conception cartographique.

## 6. Modules métier indépendants

| Module | Possède | Échanges par contrats | Non inclus avant spécification |
|---|---|---|---|
| Économie | stock national, production, marché, contrats et budget | commandes, demandes de coûts, événements de production/échange | unités, prix, formules, pénuries |
| Industrie | usines localisées et capacités agrégées | économie, provinces, production militaire/recherche | coûts, rendements, délais |
| Diplomatie | relations et accords | transit, commerce, guerre/paix, journal | acceptation, sanctions, confiance et secrets |
| Militaire | hiérarchie de forces, ordres, combats | carte, logistique, économie, diplomatie | catalogue, effectifs, formules et combat |
| Logistique | réseau d’acheminement et résultat d’accès | carte, unités, ressources et contrôle | capacités, portées, consommation |
| Politique | état institutionnel et intérieur | événements, unité, ressources et réformes | types de régime, réformes, révoltes |
| Recherche | progrès et état de technologie | budget, industrie, forces | arbre, coûts, durées, effets |
| Renseignement | informations collectées et rapports | vues nationales, événements et rapports | fiabilité, délais, coûts, interceptions |
| IA | objectifs et mémoire propres au pays | `NationView` en entrée, commandes communes en sortie | objectifs, poids, apprentissage et personnalités |
| Histoire | catalogue de propositions d’événements | commandes d’acceptation/refus/influence et journal | dates et conséquences finales |

Chaque module peut livrer ses règles et tests séparément lorsque la conception du système correspondant est validée. Les contrats partagés se modifient par ADR/versionnement et tests d’intégration.

## 7. IA autonome et limites d’information

Une IA par pays implémente une interface commune `NationAgent`. Sa boucle technique est : recevoir la vue permise → mettre à jour les croyances sans accéder aux secrets → classer objectifs selon paramètres approuvés → produire zéro ou plusieurs commandes → fournir des raisons structurées pour journal/diagnostic. Le découpage en perception, objectifs, évaluateur et planificateur est une proposition d’architecture ; les modèles d’intérêt et de personnalité restent à définir.

Tous les acteurs IA réutilisent le même cadre d’autonomie, avec données de capacité et objectifs différenciés quand ils seront validés. Les tests futurs doivent vérifier non-omniscience, absence de lecture des ordres secrets, contraintes matérielles, capacité à refuser/négocier/changer de stratégie et diversité des trajectoires sans comportements suicidaires systématiques. L’apprentissage entre parties ne doit jamais être introduit implicitement ; persistance et sens de « apprend de ses expériences » demandent une définition produit.

## 8. Sauvegarde, journal et relecture

Un `SaveRepository` abstrait fournit sauvegarder/charger/lister ; l’adaptateur initial est local. Enveloppe minimale proposée : identifiant de sauvegarde, version de schéma, version des règles, version des données, mois/phase, état sérialisé et métadonnées de reproductibilité (graine si utilisée). Ne pas lier les sauvegardes aux nœuds de scènes Godot.

Le journal append-only des commandes verrouillées, décisions IA explicables, événements et résultats doit permettre diagnostic, inspection et reprise. La rétention détaillée et la relecture utilisateur restent à spécifier. Écrire migrations explicites lors de changements de schéma ; garder fixtures d’anciennes versions et tester chargement/sauvegarde sans perte.

## 9. Multijoueur futur

Version initiale locale/solo. Les contrats de commandes, vues nationales et résultats sont compatibles avec un futur serveur faisant autorité : clients soumettent leurs commandes ; serveur les valide, verrouille selon délai configuré et résout ; il distribue des vues filtrées. N’implémenter maintenant ni serveur, ni transport, ni authentification, ni lobby.

À préciser avant réseau : nombre de joueurs, rythme asynchrone ou synchrone, échéances, abandon/reconnexion, serveur persistant, visibilité des ordres, diplomatie privée, sécurité, plateforme et hébergement. L’architecture n’implique pas une résolution par client ni une synchronisation temps réel.

## 10. Arborescence cible au premier développement autorisé

```text
project.godot
docs/{design,architecture,decisions,testing}/
data/{world,scenarios,rules,schemas}/
src/app/                 # session et machine d’états
src/core/                # contrats et identifiants
src/simulation/          # orchestration et journal
src/domains/{economy,industry,diplomacy,military,logistics,politics,technology,intelligence}/
src/ai/                  # vues nationales et agents
src/history/             # événements historiques
src/map/                 # modèle, chemins et rendu
src/ui/                  # scènes sans règles métier
src/adapters/            # sauvegarde ; réseau futur
tests/{unit,integration,scenarios,fixtures}/
tools/                   # import et validation de données
```

Les dossiers `src/`, `data/` et `tests/` sont une cible d’architecture, pas une invitation à les implémenter avant autorisation. À ce stade, seul le dossier documentaire est préparé.

## 11. Prototype de validation technique (non-gameplay)

Après confirmation des plateformes, un prototype isolé pourra mesurer : lancement/export Godot, rendu d’une géométrie fictive sans frontière/donnée historique de gameplay, chargement d’un petit JSON synthétique, sérialisation d’un objet technique neutre et coût d’une simulation factice. Aucune mécanique ou valeur de Grand Strategy-1914 ne sera incluse. Le prototype ne commence qu’après autorisation de ce travail technique et demeure supprimable sans perte de conception.

## 12. Décisions d’architecture à figer avant production

- plateformes et résolutions minimales ; version stable exacte de Godot ;
- format et origine/licence des géométries cartographiques ;
- schémas de données, localisation et validation ;
- méthode de tests et intégration continue ;
- déterminisme requis, algorithme/graine et granularité de relecture ;
- objectifs de performance de simulation/IA/carte ;
- durée de vie, migrations et export des sauvegardes ;
- accessibilité et exigences de rendu des batailles tactiques.

Ces décisions techniques peuvent être prises sans altérer les règles, après inspection des exigences et prototype technique ciblé.
