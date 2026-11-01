# AGENTS.md — règles de travail du projet

## Autorité et état

Le directeur de conception est l’autorité finale sur l’identité et les règles de Grand Strategy-1914. L’agent conseille et exécute le travail technique autorisé ; il ne valide pas de mécanique.

Le projet est en conception. **Il est interdit de commencer le développement du gameplay avant une autorisation explicite du directeur.** Cela inclut les règles, données de jeu, système de tours fonctionnel, simulation, IA, carte jouable, économie, diplomatie, politique, armées, batailles, interface de jeu ou contenu. La préparation documentaire et l’architecture sont autorisées. Des outils purement techniques sans comportement de gameplay peuvent être proposés, mais doivent rester séparés et ne pas préremplir de règles.

## Source de vérité et ordre de priorité

Avant chaque tâche, lire `PROJECT.md`, `PROGRESS.md`, ce fichier et les documents spécialisés concernés. Le corpus de conception fait foi. En cas de contradiction, signaler le conflit ; les interdictions explicites de gameplay et décisions validées du directeur priment sur les consignes génériques ou anciennes demandant d’implémenter.

Les consignes finales du dossier initial qui demandaient de commencer immédiatement une partie jouable sont annulées par le directeur. Elles ne doivent pas être reprises dans un prompt ou document opérationnel.

## Statuts obligatoires

- **VALIDÉ** : décision de conception explicitement confirmée.
- **PROPOSITION** : recommandation non approuvée, notamment choix techniques.
- **HYPOTHÈSE À VALIDER** : hypothèse temporaire nécessaire à une analyse ou un prototype isolé.
- **À DÉFINIR** : décision ou précision de conception manquante.
- **BLOQUÉ** : dépend d’une décision ou d’une ressource externe.
- **IMPLÉMENTÉ** : présent dans le code.
- **TESTÉ** : vérifié par tests exécutés et rapportés.

Une proposition ou hypothèse ne devient jamais une règle validée sans décision explicite du directeur. Ne pas inventer de statistiques, formules, coûts, unités, technologies, frontières, événements, comportement diplomatique, victoire ou interaction d’interface avec un impact sur le gameplay.

## Principes de conception à préserver

La formule du jeu est : **« Le joueur dirige son pays, mais ne dirige pas le monde. »** Toute proposition respecte les trois piliers d’égale importance : profondeur stratégique, autonomie convaincante de l’IA, réalisme historique. Respecter également la simultanéité mensuelle, l’information limitée, le périmètre solo initial, les exclusions de la V1 et tous les principes VALIDÉS dans `PROJECT.md` et les documents spécialisés.

La conception cartographique continue dans un travail distinct. `docs/map/TECHNICAL_SPEC.md` contient désormais les décisions explicitement validées MAP-DEC-01 à MAP-DEC-69 et des contrats techniques de données/présentation. Le plafond est de 100 régions terrestres ; leur nombre final, géométrie, frontières, contenu et projection de rendu restent à définir. Ne pas créer de régions ou données historiques ni arbitrer les points du registre sans décision du directeur. La mission explicite du directeur autorise l’intégration documentaire de décisions cartographiques, sans ouvrir le développement du gameplay.

Règles cartographiques résolues à préserver : le zoom libre continental-régional, l’affichage adaptatif des noms, le regroupement automatique des unités selon le zoom et les flottes au centre de leur zone sont validés ; les noms ordinaires peuvent être masqués, mais les noms de capitales restent toujours visibles. Les revendications territoriales contestées n’ont pas de marquage dédié et la couleur de souveraineté officielle reste affichée. Garder les seuils, algorithmes et calcul détaillé des cas particuliers de victoire à 90 % comme points ouverts ; ne pas les confondre avec les principes visuels décidés.

## Architecture technique approuvée pour préparation

La pile proposée pour la préparation est Godot 4.7.2 stable et GDScript typé. Vérifier l’export pour les plateformes ciblées au moyen d’un prototype technique neutre avant la production. Garder le noyau de simulation indépendant de l’affichage et du réseau, domaines indépendants, identifiants stables, données historiques séparées de l’état, commandes simultanées, état sauvegardable et journal explicable. Multijoueur différé après le solo ; préparer des interfaces sans développer réseau en V1.

Consulter `docs/architecture/TECHNICAL_ARCHITECTURE.md` pour les contrats et frontières. Toute évolution de la pile passe par une décision d’architecture documentée ; elle ne peut modifier les règles.

## Méthode de travail

1. Reformuler le périmètre et identifier l’autorisation applicable.
2. Lire les sources pertinentes et les modifications existantes.
3. Distinguer VALIDÉ, PROPOSITION, HYPOTHÈSE À VALIDER et À DÉFINIR.
4. Pour une tâche documentaire/architecture, effectuer les changements demandés sans solliciter de choix technique ordinaire.
5. Ne pas coder le gameplay sans autorisation explicite, même si une instruction héritée le demande.
6. Vérifier les fichiers et les références croisées ; exécuter seulement les vérifications pertinentes autorisées.
7. Mettre à jour `PROGRESS.md` et `CHANGELOG.md` pour les changements substantiels.
8. Rapporter les fichiers, vérifications réellement exécutées, limites et décisions restantes.

## Git, données et sécurité

- Ne pas supprimer ou écraser de travaux sans inspection ; ne pas réécrire l’historique, pousser, publier ou déployer sans autorisation.
- Aucun secret dans le dépôt.
- Préférer des changements lisibles, localisés et réversibles.
- Distinguer clairement données historiques sourcées, valeurs de conception validées et paramètres provisoires.

## Tests et honnêteté

Ne jamais prétendre qu’un test a réussi s’il n’a pas été exécuté. Rapporter la commande et le résultat, ainsi que les vérifications non exécutées. Les tests de règles ne doivent être écrits qu’à partir de règles validées. Pour l’IA, contrôler ses limites d’information et l’absence d’accès aux ordres secrets.

## Compte rendu

À la fin d’une tâche, résumer : objectif, travail effectué, fichiers créés/modifiés, décisions de conception en attente, tests/vérifications et résultats, risques/limites, prochaine étape.
