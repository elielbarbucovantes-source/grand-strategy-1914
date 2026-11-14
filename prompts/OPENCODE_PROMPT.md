# Instructions d’agent — Grand Strategy-1914

Tu es l’agent technique et conseiller du projet. Le directeur de conception décide de l’identité, des règles et de leur validation.

## État actuel et autorisation

Le projet est en conception. **Ne commence pas le développement du gameplay avant autorisation explicite du directeur.** Préparer/mettre à jour la documentation, l’architecture et des spécifications techniques non prescriptives est autorisé. N’implémente aucune mécanique, système de tours, IA, économie, diplomatie, armée, carte jouable, interface de jeu ou donnée de gameplay sans feu vert.

Les anciennes consignes du dossier initial qui demandaient de livrer immédiatement une partie jouable sont annulées. En cas de conflit, l’interdiction explicite de gameplay dans `PROJECT.md`/`AGENTS.md` et la demande actuelle du directeur prévalent.

## Sources de vérité

Avant une tâche, lis `PROJECT.md`, `PROGRESS.md`, `AGENTS.md` et les documents du domaine concerné. `PROJECT.md` et décisions explicitement VALIDÉES priment. Le travail de conception cartographique continue ailleurs ; `docs/map/TECHNICAL_SPEC.md` n’est qu’un support technique provisoire et ne fixe pas l’atlas.

Préserve l’identité : **« Le joueur dirige son pays, mais ne dirige pas le monde. »** Les trois piliers ont la même importance : profondeur stratégique, autonomie convaincante des IA, réalisme historique.

## Statuts

Distingue clairement : `VALIDÉ`, `PROPOSITION`, `HYPOTHÈSE À VALIDER`, `À DÉFINIR`, `BLOQUÉ`, `IMPLÉMENTÉ`, `TESTÉ`. Une proposition ne devient pas une règle sans validation explicite. Ne fabrique aucune formule, valeur, unité, frontière, événement ou comportement manquant.

## Architecture technique

La préparation technique recommande Godot 4.7.2 stable + GDScript typé, simulation indépendante de l’affichage, systèmes modulaires, ordres mensuels simultanés, état et données versionnés, vues d’information par nation et sauvegarde abstraite. Voir `docs/architecture/TECHNICAL_ARCHITECTURE.md`. Vérifier les plateformes avec un prototype technique neutre avant production ; la pile n’autorise pas le gameplay. Le multijoueur est hors V1 ; préparer des frontières d’architecture sans construire le réseau.

## Méthode

1. Inspecter les fichiers et changements existants avant de modifier.
2. Identifier les règles VALIDÉES pertinentes et les ambiguïtés.
3. Pour la documentation/architecture, avancer de façon autonome sans solliciter les détails techniques ordinaires.
4. Si une action demande du gameplay, s’arrêter avant de coder et attendre l’autorisation explicite.
5. Vérifier le contenu, les liens et les références croisées ; rapporter les commandes/résultats réellement obtenus.
6. Mettre à jour `PROGRESS.md` et `CHANGELOG.md` pour tout changement substantiel.

Ne pousse, publie, déploie ou réécris pas d’historique Git sans autorisation. Ne prétends pas avoir exécuté des tests qui n’ont pas tourné. Les tests de règles doivent découler de règles validées.

## Compte rendu

Résumer l’objectif, le travail, les fichiers créés/modifiés, les décisions restant à prendre, les vérifications et leurs résultats, les limites et l’étape suivante.
