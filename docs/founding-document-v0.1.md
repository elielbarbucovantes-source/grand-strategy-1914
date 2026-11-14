# Document fondateur du projet — version 0.1

> **Source :** document fourni par le propriétaire du projet le 2026-10-31.
> **Statut :** document de cadrage initial du propriétaire. Il fait autorité sur les intentions de conception. Les éléments marqués « à définir » restent ouverts et la validation finale du cahier des charges n'est pas acquise.
> **Conservation :** repris **intégralement**, sans modification de fond. Ce fichier est une source historique ; les documents thématiques peuvent le synthétiser mais ne doivent pas le contredire silencieusement.
> **Empreinte SHA-256 :** à consigner dans [`design-review-v0.1.md`](design-review-v0.1.md) après gel du fichier.

---

# GRAND STRATEGY — DOCUMENT FONDATEUR DU PROJET

Version : 0.1 — Document de cadrage initial
Statut : Conception du jeu — aucun développement des mécaniques définitives avant validation du cahier des charges.

---

# 1. VISION GÉNÉRALE

## 1.1. Concept

Créer un jeu de grande stratégie géopolitique et militaire se déroulant à partir de l'Europe de 1914.

Le joueur incarne le dirigeant suprême d'une nation. Il dispose d'une autorité étendue sur les décisions politiques, diplomatiques, économiques, scientifiques et militaires de son pays.

Le monde est composé de nations indépendantes, dirigées soit par des joueurs humains, soit par des intelligences artificielles autonomes.

Le jeu doit permettre de construire une histoire alternative crédible : les événements historiques constituent un point de départ, et non un scénario obligatoire.

## 1.2. Inspirations principales

Le projet cherche à réunir plusieurs philosophies de jeu :

- **Diplomacy / webDiplomacy** : négociations, alliances, trahisons et ordres simultanés.
- **Hearts of Iron IV** : carte stratégique, production industrielle, recherche, armées et gestion nationale.
- **Lines of Battle** : inspiration pour les affrontements tactiques indépendants, avec unités contrôlables, terrain et préparation simultanée des ordres.
- **Jeu de stratégie avec agents IA autonomes** : dirigeants capables de réfléchir, négocier, mémoriser, prendre des initiatives et poursuivre leurs propres objectifs.

L'objectif n'est pas de reproduire intégralement ces jeux, mais d'en combiner les meilleures idées dans une expérience cohérente.

---

# 2. PRINCIPES FONDAMENTAUX

Le développement doit respecter les principes suivants :

1. La diplomatie et la stratégie militaire constituent les deux piliers principaux.
2. Les nations doivent agir de manière autonome et crédible.
3. Les décisions diplomatiques doivent avoir des conséquences durables.
4. Les affrontements militaires doivent dépendre des forces réellement mobilisées sur la carte stratégique.
5. L'économie et la recherche doivent soutenir les choix stratégiques sans devenir inutilement complexes.
6. Les nations doivent conserver des caractéristiques historiques distinctes.
7. Le joueur doit disposer d'une grande liberté de décision.
8. L'histoire doit pouvoir diverger de la réalité.
9. Les mécaniques doivent rester compréhensibles malgré la profondeur du jeu.

---

# 3. CADRE HISTORIQUE ET GÉOGRAPHIQUE

## 3.1. Date de départ

Le jeu commence en 1914.

Toutes les nations débutent avec leurs caractéristiques historiques de cette période : capacités industrielles, population, ressources, armée, technologie, situation diplomatique et organisation politique.

## 3.2. Nations jouables au lancement

Le jeu proposera initialement sept grandes puissances européennes :

1. Empire allemand
2. Empire britannique
3. France
4. Empire russe
5. Autriche-Hongrie
6. Italie
7. Empire ottoman

Les autres pays européens existent indépendamment sur la carte, mais ne sont pas jouables dans la première version.

Leur poids historique doit rester cohérent : une petite puissance ne doit pas pouvoir devenir artificiellement l'équivalent d'une grande puissance simplement grâce à une bonne stratégie.

Elle peut néanmoins jouer un rôle diplomatique ou militaire important dans certaines circonstances.

## 3.3. Évolution des nations

Les caractéristiques nationales ne sont pas totalement figées.

Elles peuvent évoluer grâce :
- Aux investissements.
- Aux réformes.
- Aux changements de régime.
- Aux décisions politiques et économiques.

En revanche, les caractéristiques historiques constituent un cadre de départ important.

Les événements historiques ne doivent pas imposer automatiquement une évolution aux pays.

---

# 4. CARTE STRATÉGIQUE

## 4.1. Présentation

La carte principale représente l'Europe de 1914.

Elle adopte une présentation stratégique en deux dimensions, inspirée de Hearts of Iron IV.

## 4.2. Provinces

Le territoire est divisé en provinces conquérables.

Chaque province possède notamment :
- Une nation propriétaire.
- Des caractéristiques géographiques.
- Des ressources.
- Une importance stratégique.
- Des infrastructures éventuelles.
- Des fortifications éventuelles.

La géographie doit avoir une influence réelle sur les décisions économiques et militaires.

Le niveau de détail doit rester raisonnable : il faut obtenir une carte suffisamment précise pour permettre des stratégies intéressantes, sans multiplier inutilement les territoires.

## 4.3. Indépendance des nations

Chaque pays est une entité indépendante.

Il est contrôlé soit par un joueur humain, soit par une IA.

Les nations ne doivent pas être de simples extensions des grandes puissances.

---

# 5. TEMPS ET ORGANISATION DES TOURS

## 5.1. Durée

Un tour représente un mois.

## 5.2. Résolution simultanée

Tous les pays préparent leurs ordres pendant la même phase.

Une fois les ordres validés, le monde entier les résout simultanément.

Cela concerne notamment :
- Les déplacements militaires.
- Les offensives.
- Les décisions économiques.
- Les décisions politiques.
- Les recherches.
- Les négociations et engagements diplomatiques.

Le système doit éviter qu'une nation puisse systématiquement agir après avoir observé les décisions des autres pendant le même tour.

Les modalités exactes de résolution des conflits entre ordres simultanés restent à définir.

---

# 6. DIPLOMATIE

La diplomatie est l'un des deux piliers majeurs du jeu.

Elle doit être vivante, libre et imprévisible.

## 6.1. Communications

Le joueur doit pouvoir communiquer librement avec les autres dirigeants.

Deux formes de communication sont prévues :

**Communication libre :**
- Messages écrits.
- Discussions.
- Menaces.
- Promesses.
- Arguments.
- Tentatives de persuasion.
- Négociations.

**Propositions officielles :**
- Alliances.
- Traités.
- Accords commerciaux.
- Accords militaires.
- Engagements diplomatiques.
- Autres accords à définir.

## 6.2. Canaux diplomatiques

Plusieurs canaux doivent exister :
- Communications publiques.
- Communications privées.
- Conversations de groupe.
- Communications officielles.
- Communications secrètes.

Les communications diplomatiques sont confidentielles par défaut.

Elles ne deviennent accessibles à un tiers que si une interception réussit.

## 6.3. Accords

Deux catégories d'accords sont envisagées :

- Accords juridiquement contraignants dans les règles du jeu.
- Accords fondés sur la confiance, dont le respect dépend de la volonté des dirigeants.

Les conséquences d'une violation doivent être cohérentes avec la nature de l'accord.

## 6.4. Relations diplomatiques

Le système initial de relations doit rester relativement simple :

- Amitié.
- Neutralité.
- Hostilité.

Ces relations peuvent évoluer en fonction des actions, des négociations, des promesses et des conflits.

## 6.5. Diplomatie des IA

Les IA peuvent :
- Prendre contact spontanément.
- Proposer des alliances.
- Former des coalitions.
- Négocier des accords secrets.
- Menacer d'autres nations.
- Mentir.
- Manipuler.
- Trahir leurs partenaires.
- Modifier leurs relations diplomatiques.

Elles ne doivent pas attendre passivement les propositions du joueur.

---

# 7. INTELLIGENCE ARTIFICIELLE DES DIRIGEANTS

Les IA doivent être considérées comme de véritables acteurs politiques autonomes.

## 7.1. Personnalités

Chaque dirigeant possède quelques traits de personnalité, par exemple :
- Agressif.
- Prudent.
- Expansionniste.
- Diplomate.
- Opportuniste.

Ces traits influencent ses décisions sans déterminer mécaniquement toutes ses actions.

## 7.2. Objectifs

Chaque IA combine :
- Ses ambitions personnelles.
- Les intérêts de son pays.
- Sa volonté de survivre.
- Son adaptation à la situation internationale.
- Son objectif de victoire.

## 7.3. Mémoire

Les IA doivent disposer d'une mémoire à long terme.

Elles doivent se souvenir :
- Des conversations.
- Des promesses.
- Des trahisons.
- Des alliances.
- Des conflits.
- Des erreurs stratégiques.
- Des événements importants.

Une IA trahie doit pouvoir en tenir compte longtemps après les faits.

## 7.4. Comportement

Les IA peuvent :
- Mentir volontairement.
- Faire des erreurs.
- Manipuler.
- Désinformer.
- Changer d'avis.
- Prendre des initiatives.
- Déclencher des crises diplomatiques.

Elles ne sont pas omniscientes.

Elles ne connaissent pas automatiquement les intentions secrètes des autres nations.

## 7.5. Autonomie

Les IA doivent pouvoir déclencher indépendamment :
- Des crises.
- Des guerres.
- Des alliances.
- Des ruptures diplomatiques.
- Des changements de stratégie.

Le monde doit continuer à évoluer même lorsque le joueur ne prend aucune initiative diplomatique.

---

# 8. STRATÉGIE MILITAIRE

La stratégie militaire est le second pilier majeur du jeu.

## 8.1. Organisation des armées

Les armées sont représentées sur la carte stratégique.

Elles sont organisées en unités militaires telles que :
- Régiments.
- Divisions.
- Formations militaires.

Le joueur doit pouvoir organiser, déplacer et commander ses forces.

Les effectifs et équipements réellement mobilisés doivent déterminer les capacités militaires disponibles.

## 8.2. Fronts et offensives

Les affrontements statiques sur un front ne déclenchent pas automatiquement une bataille tactique indépendante.

Les échanges de tirs et les pertes éventuelles sont représentés sur la carte stratégique et consomment des ressources.

En revanche, lorsqu'une offensive est lancée et que des armées se rencontrent, une bataille tactique indépendante commence.

## 8.3. Batailles tactiques

Les batailles tactiques s'inspirent de la philosophie de Lines of Battle.

Elles se déroulent sur un terrain distinct de la carte stratégique.

Le joueur contrôle directement ses unités.

Principes retenus :
- Unités sélectionnables individuellement ou en groupes.
- Préparation simultanée des ordres.
- Résolution des ordres.
- Déplacements et formations.
- Influence du terrain.
- Prise en compte des effectifs et des équipements.
- Durée maximale de 30 minutes.

Les effectifs présents dans la bataille doivent être proportionnels aux forces engagées sur la carte stratégique.

Exemple : une province défendue par trois régiments d'infanterie, une division aéroportée et une division blindée doit présenter une force correspondante dans la bataille tactique.

Une petite armée affrontant une force nettement supérieure doit être désavantagée, sauf circonstances particulières.

## 8.4. Terrain

Le terrain influence directement les combats.

Il doit procurer des avantages aux unités adaptées et des difficultés aux unités désavantagées.

Les caractéristiques géographiques des provinces doivent être cohérentes avec les terrains des batailles tactiques.

## 8.5. Résolution des batailles

Après la bataille :
- Le vainqueur occupe automatiquement la province.
- Les pertes sont définitives.
- Les soldats et équipements détruits sont perdus.
- Les unités survivantes conservent les conséquences de leurs pertes et de leur état.

Après une offensive échouée, le joueur peut immédiatement tenter une nouvelle offensive.

Cependant, les pertes et l'état des unités rendent les tentatives successives plus difficiles.

## 8.6. Éléments non retenus

Pour le moment :
- Pas de système de moral des troupes.
- Pas de généraux à recruter ou à commander.
- Le joueur commande directement ses unités.

Ces éléments ne doivent pas être ajoutés sans validation.

## 8.7. Fortifications

Les fortifications sont construites sur la carte stratégique.

Elles apparaissent également dans les batailles tactiques.

Elles peuvent :
- Être améliorées par niveaux.
- Nécessiter des ressources.
- Être améliorées grâce aux technologies.
- Modifier les conditions d'une bataille.

---

# 9. ÉCONOMIE ET INDUSTRIE

L'économie doit être suffisamment développée pour permettre une véritable stratégie nationale, mais sans devenir excessivement complexe.

## 9.1. Ressources territoriales

Chaque territoire produit trois ressources.

Leur production suit un principe inspiré de Catan :
- Une ressource produite en faible quantité.
- Une ressource produite en quantité moyenne.
- Une ressource produite en grande quantité.

Les provinces doivent donc avoir des profils économiques différents.

La liste définitive des ressources reste à définir.

## 9.2. Gestion économique

Le joueur doit pouvoir gérer :
- Les revenus.
- Les dépenses.
- Les investissements.
- Le financement militaire.
- La production industrielle.
- La recherche scientifique.

La gestion financière doit rester lisible et éviter une comptabilité inutilement détaillée.

## 9.3. Industrie militaire

L'industrie constitue un élément stratégique important.

Le joueur peut développer :
- Des usines.
- Des infrastructures.
- Des chaînes de production.
- Des capacités de mobilisation industrielle.
- Une économie de guerre.

Il doit être possible de réorienter une partie de l'économie civile vers la production militaire.

Les capacités industrielles influencent directement la puissance nationale.

---

# 10. RECHERCHE ET TECHNOLOGIES

## 10.1. Progression technologique

Toutes les nations commencent en 1914.

Grâce à des investissements importants, elles peuvent atteindre un niveau technologique allant jusqu'à 1945.

La progression technologique doit permettre une histoire alternative.

## 10.2. Arbre technologique

Le système repose sur un arbre de recherche inspiré de Hearts of Iron IV.

Les branches envisagées comprennent :
- Infanterie et armement.
- Artillerie.
- Blindés.
- Aviation.
- Marine.
- Industrie.
- Communications et électronique.
- Médecine.
- Logistique.

La structure définitive reste à concevoir.

## 10.3. Prérequis chronologiques

Les technologies avancées nécessitent normalement des technologies préalables.

Il reste toutefois possible de tenter une recherche en avance sur son époque.

Cela entraîne une augmentation considérable du coût et du temps nécessaires.

## 10.4. Financement

La recherche nécessite :
- Un budget scientifique.
- Des ressources matérielles.

Le joueur doit répartir ses investissements entre les différentes branches.

## 10.5. Spécialisations nationales

Chaque pays possède des spécialisations scientifiques historiques.

Ces spécialisations peuvent évoluer avec le temps grâce aux investissements.

---

# 11. RENSEIGNEMENT ET ESPIONNAGE

Le renseignement doit apporter un avantage stratégique sans rendre les nations omniscientes.

## 11.1. Missions retenues

Pour la première version, les services secrets sont principalement consacrés au renseignement classique :

- Informations militaires.
- Informations économiques.
- Informations technologiques.

Les opérations de sabotage, de contre-espionnage et d'action politique ne sont pas retenues à ce stade.

## 11.2. Interception des communications

Les communications diplomatiques sont confidentielles par défaut.

Une nation peut tenter d'intercepter les communications d'une autre.

La capacité à lire les messages dépend de ses compétences et de ses investissements technologiques.

Exemple : une nation ayant développé des compétences en lecture du Morse ou en décryptage peut parvenir à comprendre des communications adverses.

## 11.3. Recherche cryptographique

Le décryptage nécessite des investissements importants.

Une nation peut développer ses capacités en cryptographie et en renseignement pour accéder aux communications adverses.

## 11.4. Espionnage industriel

Un investissement financier important, associé à une recherche adaptée, peut permettre d'obtenir des secrets industriels ou technologiques adverses.

## 11.5. Fiabilité

Une interception réussie fournit des informations exactes.

Il n'existe pas de faux messages interceptés dans le système actuellement retenu.

## 11.6. Rapports

Le renseignement fonctionne selon un système hybride :
- Accès immédiat aux interceptions réussies.
- Rapports périodiques sur les informations recueillies.

Les détails des méthodes d'obtention des renseignements restent à définir.

---

# 12. POLITIQUE INTÉRIEURE ET RÉGIMES

La politique intérieure est secondaire par rapport à la diplomatie et à la stratégie militaire.

Elle ne doit toutefois pas être absente.

## 12.1. Changements de régime

Un pays peut changer de régime si certaines conditions sont réunies.

Ces changements entraînent des conséquences positives et négatives.

Exemple : l'Empire russe peut évoluer vers un régime communiste.

Un changement de régime ne doit pas être uniquement esthétique : il doit avoir des conséquences concrètes sur le fonctionnement du pays, ses relations et ses capacités.

Les conditions exactes de ces transformations restent à définir.

---

# 13. CONDITIONS DE VICTOIRE ET DÉFAITE

## 13.1. Élimination

Lorsqu'un pays est entièrement conquis, son joueur est éliminé.

## 13.2. Victoires possibles

Plusieurs voies de victoire sont prévues :

1. **Victoire territoriale** : conquérir l'Europe.
2. **Victoire diplomatique** : dominer politiquement le continent grâce aux alliances, à l'influence et aux relations internationales.
3. **Victoire économique et sociale** : atteindre un niveau de vie exceptionnellement élevé par rapport aux autres nations.

Les conditions précises et les seuils de victoire restent à définir.

---

# 14. ÉVÉNEMENTS ET HISTOIRE ALTERNATIVE

Le jeu commence dans un contexte historique réel.

Cependant, les événements historiques ne doivent jamais être obligatoires.

Les nations peuvent prendre des décisions différentes de celles de leurs dirigeants historiques.

Les guerres, alliances, révolutions et crises peuvent donc évoluer de manière imprévisible.

L'objectif est de produire une histoire alternative crédible, et non de rejouer mécaniquement la Première Guerre mondiale.

---

# 15. INTERFACE ET EXPÉRIENCE UTILISATEUR

## 15.1. Carte principale

La carte stratégique est une carte 2D détaillée, inspirée de Hearts of Iron IV.

Elle doit permettre de visualiser :
- Les frontières.
- Les provinces.
- Les armées.
- Les infrastructures.
- Les fortifications.
- Les ressources.
- Les fronts.

## 15.2. Diplomatie

L'interface diplomatique doit permettre de discuter librement avec les dirigeants.

Les différents canaux de communication doivent être facilement accessibles.

Le joueur doit pouvoir suivre les négociations, les propositions officielles, les accords et les relations internationales.

## 15.3. Batailles

Une bataille tactique ouvre une interface indépendante de la carte stratégique.

Le joueur doit pouvoir contrôler directement ses unités.

## 15.4. Modes de jeu

Deux modes principaux sont prévus :
- Campagnes historiques.
- Parties libres personnalisables.

Le joueur doit également pouvoir observer une partie entièrement contrôlée par les IA.

Il peut prendre le contrôle d'une nation en cours de partie.

---

# 16. MULTIJOUEUR

Le multijoueur humain n'est pas indispensable pour la première version.

Cependant, l'architecture du jeu doit anticiper une éventuelle évolution vers le multijoueur.

Le système ne doit donc pas rendre cette possibilité inutilement difficile à intégrer par la suite.

---

# 17. PRINCIPES DE CONCEPTION DES IA

Les agents IA qui participeront au développement doivent respecter les principes suivants :

1. Ne pas inventer de mécaniques qui n'ont pas été validées.
2. Distinguer clairement les décisions validées, les propositions et les questions ouvertes.
3. Ne pas simplifier les piliers centraux du jeu sans validation.
4. Ne pas développer prématurément des systèmes complexes avant leur conception.
5. Maintenir une cohérence entre diplomatie, économie, recherche, renseignement et stratégie militaire.
6. Préserver la possibilité d'une histoire alternative.
7. Documenter les choix techniques et les décisions de conception.
8. Signaler les contradictions entre différentes mécaniques.
9. Proposer des solutions lorsqu'un problème de conception est identifié.
10. Ne jamais modifier silencieusement une règle validée.

## Priorité de développement

Le projet doit avancer par étapes :

1. Finaliser la vision globale.
2. Définir précisément les nations et leurs caractéristiques.
3. Définir les ressources, l'économie et l'industrie.
4. Définir les règles diplomatiques.
5. Définir le fonctionnement des IA dirigeantes.
6. Définir les règles militaires et les batailles tactiques.
7. Définir les technologies et le renseignement.
8. Définir les tours, les résolutions et les conditions de victoire.
9. Concevoir l'interface.
10. Définir l'architecture technique.
11. Commencer le développement.

Aucune mécanique majeure ne doit être codée avant d'avoir été suffisamment définie et documentée.

---

# 18. ÉLÉMENTS RESTANT À DÉFINIR

Cette liste doit être mise à jour au fur et à mesure de la conception.

## Nations et carte
- Liste définitive des provinces.
- Frontières et territoires jouables.
- Caractéristiques détaillées des sept grandes puissances.
- Caractéristiques des petites puissances.
- Ressources initiales et production territoriale.

## Diplomatie
- Modèle exact des traités.
- Conditions de rupture des accords.
- Sanctions diplomatiques.
- Conséquences des trahisons.
- Gestion des crises internationales.

## Économie
- Liste définitive des ressources.
- Coûts de construction.
- Production industrielle.
- Commerce international.
- Budget national.
- Gestion de la population et du niveau de vie.

## Armée
- Liste des unités.
- Coûts de recrutement et de production.
- Organisation des régiments et divisions.
- Système de ravitaillement.
- Gestion des pertes et du remplacement.
- Règles précises des batailles tactiques.
- Durée et fonctionnement des offensives.
- Construction et amélioration des fortifications.

## Recherche
- Arbre technologique complet.
- Coûts et durées.
- Prérequis.
- Spécialisations nationales.
- Évolution technologique de 1914 à 1945.

## Renseignement
- Méthodes d'interception.
- Portée des interceptions.
- Coûts.
- Compétences cryptographiques.
- Fréquence des rapports.
- Fonctionnement de l'espionnage industriel.

## IA
- Architecture des personnalités.
- Système de mémoire.
- Objectifs nationaux.
- Gestion des négociations.
- Gestion des crises.
- Prise de décision militaire.
- Limites de connaissance et d'information.

## Partie et victoire
- Conditions précises de victoire.
- Durée maximale d'une partie.
- Gestion des joueurs éliminés.
- Paramètres des campagnes.
- Personnalisation des parties libres.

---

# 19. OBJECTIF FINAL

Créer un jeu de grande stratégie dans lequel le monde ne tourne pas autour du joueur.

Chaque nation doit avoir ses propres intérêts, ses propres ambitions, ses propres moyens et sa propre vision du monde.

Les dirigeants doivent pouvoir négocier, coopérer, mentir, trahir, anticiper et prendre des décisions indépendantes.

Le joueur ne doit pas simplement affronter une IA qui réagit à ses actions : il doit évoluer dans un système international vivant, où les autres nations poursuivent leurs propres stratégies.

La diplomatie doit être aussi importante que la guerre.

La guerre doit être le prolongement de décisions politiques et stratégiques, et non un simple système de conquête.

Le résultat recherché est une simulation géopolitique profonde, crédible et imprévisible, permettant de construire une histoire alternative de l'Europe à partir de 1914.

**Principe directeur : le joueur dirige son pays, mais ne dirige pas le monde.**

---

*Fin du document fondateur v0.1. Toute modification de ce fichier doit être justifiée, datée et tracée ; une nouvelle version doit porter un numéro distinct.*
