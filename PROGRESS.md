# PROGRESS — État du projet

Dernière mise à jour : intégration documentaire et architecture technique 1.1
Statut général : **CONCEPTION EN COURS — GAMEPLAY INTERDIT SANS AUTORISATION EXPLICITE**

## 1. État général

| Domaine | État | Commentaire |
|---|---|---|
| Vision et piliers | VALIDÉ | Profondeur stratégique, autonomie de l’IA, réalisme historique |
| Campagne et puissances | Principes VALIDÉS | Europe 1914, sept puissances jouables, autres États IA |
| Boucle et temps | VALIDÉ | Mois par tour, ordres secrets simultanés, résolution simultanée |
| Carte | 26 décisions VALIDÉES ; atlas en cours | Modèle et schéma structurel avec plafond 100 ; aucune géométrie ni inventaire de lieux créé |
| Diplomatie | Principes VALIDÉS ; règles À DÉFINIR | Accords, confiance, acceptation, sanctions, confidentialité |
| Économie / industrie | Principes VALIDÉS ; valeurs À DÉFINIR | Trois ressources, stock national centralisé, cinq industries |
| Armée / logistique | Principes VALIDÉS ; modèle À DÉFINIR | Hiérarchie, mouvement/logistique et batailles d’offensive ; détails ouverts |
| Politique, recherche, renseignement | Périmètres VALIDÉS ; règles À DÉFINIR | Pas de formules ni de catalogues complets |
| IA autonome | Vision VALIDÉE ; architecture technique proposée | IA limitée à ses informations, non omnisciente ; objectifs et cognition à définir |
| Architecture logicielle | PROPOSITION TECHNIQUE DOCUMENTÉE | Godot 4.7.2 stable + GDScript typé ; simulation pure et domaines modulaires |
| Multijoueur | Orientation VALIDÉE | Après le solo ; interfaces préparées, aucun réseau en V1 |
| Code de gameplay | INTERDIT | Attendre l’autorisation explicite du directeur |
| Dépôt Git | ABSENT dans l’environnement fourni | Le dossier de projet est organisé, mais il ne s’agit pas d’un dépôt Git initialisé |

## 2. Documentation intégrée

Le corpus du dossier initial a été extrait dans ses chemins logiques : documents maîtres à la racine, spécifications dans `docs/`, prompt dans `prompts/`. Les règles de gouvernance ont été harmonisées : la demande ancienne de commencer une partie jouable ne prévaut plus sur l’interdiction explicite du gameplay.

Documents techniques ajoutés :

- `docs/architecture/TECHNICAL_ARCHITECTURE.md` — architecture cible, contrats, domaines, tours, sauvegarde, IA et multijoueur futur.
- `docs/map/TECHNICAL_SPEC.md` — modèle de données et pipeline cartographique provisoires, sans fixer la géométrie ou le contenu de l’atlas.
- `docs/decisions/DECISIONS_PENDING.md` — registre des décisions de conception restant nécessaires.

## 3. Prochaines tâches de conception

### Priorité 1 — Carte (travail de conception en cours)

- Définir emprise et projection, puis les provinces, frontières et identifiants stables.
- Définir terrains, villes, ports, forteresses, voies ferrées, routes, zones maritimes et passages.
- Valider l’atlas et les règles d’occupation/transfert. La spécification technique ne tranche pas ces choix.

### Priorité 2 — Économie chiffrée

- Définir unités, productions/consommations, stocks, pénuries, marché, budgets, coûts/rendements industriels et contribution des territoires abstraits.

### Priorité 3 — Forces armées, logistique et combat

- Définir unités, échelons, effectifs, recrutement, mobilité, ravitaillement, défense stratégique, bataille tactique, pertes, retraite et occupation.

### Priorité 4 — Diplomatie et IA

- Définir catalogue et règles des accords, confidentialité, négociation, confiance, rupture, crise, paix ; objectifs/mémoire/risque de l’IA et critères de test.

### Priorité 5 — Politique, technologie, renseignement, histoire et victoire

- Formaliser réformes, révoltes, technologies, renseignement et fiabilité, événements, formule socio-économique et conditions détaillées de victoire.

### Priorité 6 — Interface et contraintes produit

- Définir plateformes, résolution, parcours d’interface, accessibilité, options, langues et exigences de performance.

### Après validation de la conception — Préparation puis développement

- Revue de l’architecture technique et validation des contrats.
- Prototype technique non-gameplay, si nécessaire et autorisé.
- Attendre le feu vert explicite du directeur avant toute implémentation de gameplay.

## 4. Décisions de conception ouvertes

Le registre détaillé est dans `docs/decisions/DECISIONS_PENDING.md`. Les principaux groupes sont :

- atlas et géographie, frontières, occupation et contrôle ;
- douze statistiques et données de départ ;
- unités économiques, production, prix, budget et industrie ;
- unités militaires, effectifs, résolution, logistique, tactique, mer et aviation ;
- diplomatie, accords, confiance, guerre, paix et information ;
- objectifs, mémoire, personnalité, apprentissage et perception de l’IA ;
- arbre technologique et effets ;
- renseignement, interception, décryptage et fiabilité ;
- politique intérieure, événements historiques, victoire socio-économique ;
- plateformes et expérience utilisateur.

Les valeurs historiques indicatives et évaluations provisoires des fiches nationales ne sont pas des valeurs de gameplay validées.

## 5. Jalons de préparation vérifiables

- [x] Corpus joint intégré dans une arborescence propre.
- [x] Contradiction entre demande de partie jouable et interdiction de gameplay supprimée des consignes opératoires.
- [x] Architecture modulaire proposée avec système de tours, ordres simultanés, domaines, IA, sauvegarde et multijoueur futur.
- [x] Spécification cartographique technique provisoire préparée, sans figer l’atlas.
- [x] 26 décisions cartographiques transmises le 2026-11-01 ajoutées comme VALIDÉES ; aucune région définie.
- [x] Modèle de données et schéma structural avec plafond de 100 régions préparés.
- [x] Flux éditorial/import et inventaire des données géographiques/historiques documentés.
- [x] Difficultés techniques du plafond de 100 régions consignées.
- [x] Registre des décisions ouvertes créé.
- [x] Huit spécifications de domaine comparées aux sources jointes ; contenu identique.
- [ ] Conception de l’atlas cartographique validée par le directeur.
- [ ] Spécifications de gameplay détaillées et conception validées.
- [ ] Plateformes cibles confirmées et prototype technique autorisé/évalué.
- [ ] Autorisation explicite de développer les systèmes de jeu.

## 6. Vérification et limites

Vérification effectuée : JSON schema parseable, liens Markdown relatifs valides, 26 décisions reportées, huit documents de domaine comparés au texte source, absence de nouvelles régions. Un squelette `project.godot` et `.gitignore` sont présents ; aucune scène ni logique de jeu n’est créée. Godot n’est pas installé dans cet environnement ; le projet n’a pas pu être ouvert dans l’éditeur. Aucun test de gameplay n’a été exécuté. Le dépôt source antérieur n’était pas fourni ; le dépôt courant a été initialisé dans le dossier de projet.
