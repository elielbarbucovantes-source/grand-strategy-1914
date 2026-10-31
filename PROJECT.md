# PROJECT.md — Document de référence du projet

> **Version :** 0.2.3
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source :** fiche maîtresse v0.1 et dossier des puissances jouables fournis par le propriétaire du projet le 2026-10-31 ; nom du jeu arrêté par le propriétaire le 2026-10-31.
> **Statut global :** Phase 1 — conception. Aucun code de jeu n'existe. Aucune mécanique définitive n'est développée avant validation du cahier des charges.
> **Nom du jeu :** **Grand Strategy-1914** **[VALIDÉ]** (D-030, 2026-10-31). Le nom du répertoire Git reste `GrandStrategy` ; il ne conditionne pas le nom du produit.
> **Propriétaire :** autorité finale du projet ; identité formelle et canal d'arbitrage **à documenter** (voir § 20.4, Q-025).

---

## Objet et autorité de ce document

Ce document est la **fiche maîtresse** du jeu : il définit ce que le projet doit devenir. Les documents de `docs/` détaillent *comment* chaque système fonctionne.

**[VALIDÉ]** Le contenu de fond est celui de la fiche maîtresse remise par le propriétaire. Sa transposition dans ce fichier n'a ajouté que : la mise en forme, la numérotation continue, les étiquettes de statut, les renvois vers la documentation et les sections de gouvernance.

**[VALIDÉ]** En cas de contradiction, l'ordre de priorité est celui d'[AGENTS.md](AGENTS.md) § 1. Une décision du propriétaire consignée ici ou dans un ADR accepté prime sur tout document thématique.

**[À DÉFINIR]** Le cahier des charges détaillé qui autorisera le développement des mécaniques définitives. Tant qu'il n'existe pas, la conception peut avancer, l'implémentation non (voir § 19).

---

## Légende des statuts

Chaque affirmation importante de ce document est étiquetée :

| Étiquette | Signification |
|---|---|
| **[VALIDÉ]** | Décision explicite du propriétaire du projet. Ne peut être changée que par lui. |
| **[PROPOSITION]** | Recommandation d'un agent. **Non validée.** Peut être acceptée, modifiée ou rejetée. |
| **[HYPOTHÈSE]** | Supposition à vérifier par une étude, un prototype ou une décision ultérieure. |
| **[À DÉFINIR]** | Question ouverte. Aucune valeur par défaut ne doit être supposée. |

Règle : une proposition ou une hypothèse ne devient jamais une décision par simple répétition dans un autre document. Seul le propriétaire valide, et la validation est tracée ici ou dans un ADR accepté.

---

## 1. Vision générale

### 1.1 Concept

**[VALIDÉ]** Créer un jeu de grande stratégie géopolitique et militaire se déroulant à partir de l'**Europe de 1914**.

**[VALIDÉ]** Le joueur incarne le dirigeant suprême d'une nation. Il dispose d'une autorité étendue sur les décisions politiques, diplomatiques, économiques, scientifiques et militaires de son pays.

**[VALIDÉ]** Le monde est composé de nations indépendantes, dirigées soit par des joueurs humains, soit par des intelligences artificielles autonomes.

**[VALIDÉ]** Le jeu doit permettre de construire une **histoire alternative crédible** : les événements historiques constituent un point de départ, et non un scénario obligatoire.

### 1.2 Inspirations principales

**[VALIDÉ]** Le projet réunit plusieurs philosophies de jeu :

- **Diplomacy / webDiplomacy** : négociations, alliances, trahisons et ordres simultanés.
- **Hearts of Iron IV** : carte stratégique, production industrielle, recherche, armées et gestion nationale.
- **Lines of Battle** : affrontements tactiques indépendants, avec unités contrôlables, terrain et préparation simultanée des ordres.
- **Jeu de stratégie avec agents IA autonomes** : dirigeants capables de réfléchir, négocier, mémoriser, prendre des initiatives et poursuivre leurs propres objectifs.

**[VALIDÉ]** L'objectif n'est pas de reproduire intégralement ces jeux, mais d'en combiner les meilleures idées dans une expérience cohérente.

**[À DÉFINIR]** La relation juridique et mécanique exacte avec ces jeux : inspiration libre, adaptation, ou reprise partielle. Aucune œuvre protégée (règles, carte, assets) ne doit être copiée sans vérification de licence (voir § 20.4, Q-003).

---

## 2. Principes fondamentaux

**[VALIDÉ]** Le développement doit respecter les principes suivants :

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

## 3. Cadre historique et géographique

### 3.1 Date de départ

**[VALIDÉ]** Le jeu commence en **1914**.

**[VALIDÉ]** Toutes les nations débutent avec leurs caractéristiques historiques de cette période : capacités industrielles, population, ressources, armée, technologie, situation diplomatique et organisation politique.

### 3.2 Nations jouables au lancement

**[VALIDÉ]** Le jeu proposera initialement **sept grandes puissances européennes** jouables :

1. Empire allemand
2. Empire britannique
3. France
4. Empire russe
5. Autriche-Hongrie
6. Italie
7. Empire ottoman

**[VALIDÉ]** Les autres pays européens existent indépendamment sur la carte, mais ne sont pas jouables dans la première version.

**[VALIDÉ]** Leur poids historique doit rester cohérent : une petite puissance ne doit pas pouvoir devenir artificiellement l'équivalent d'une grande puissance simplement grâce à une bonne stratégie. Elle peut néanmoins jouer un rôle diplomatique ou militaire important dans certaines circonstances.

**[VALIDÉ]** Le dossier des puissances jouables ([docs/nations/nations.md](docs/nations/nations.md)) fixe les profils initiaux des sept grandes puissances : identité, douze caractéristiques nationales, forces, faiblesses, armée, marine, économie, diplomatie, ambitions initiales et possessions. Il est la référence de départ pour les statistiques nationales (D-027 à D-029).

**[À DÉFINIR]** Les caractéristiques des petites puissances restent à définir, ainsi que les règles chiffrées d'évolution des douze caractéristiques (voir § 18 et § 20.4, Q-027 à Q-031).

### 3.3 Évolution des nations

**[VALIDÉ]** Les caractéristiques nationales ne sont pas totalement figées. Elles peuvent évoluer grâce :

- aux investissements ;
- aux réformes ;
- aux changements de régime ;
- aux décisions politiques et économiques.

**[VALIDÉ]** Les caractéristiques historiques constituent un cadre de départ important, mais les événements historiques ne doivent pas imposer automatiquement une évolution aux pays.

---

## 4. Carte stratégique

### 4.1 Présentation

**[VALIDÉ]** La carte principale représente l'**Europe de 1914**.

**[VALIDÉ]** Elle adopte une présentation stratégique en deux dimensions, inspirée de Hearts of Iron IV.

### 4.2 Provinces

**[VALIDÉ]** Le territoire est divisé en **provinces conquérables**. Chaque province possède notamment :

- une nation propriétaire ;
- des caractéristiques géographiques ;
- des ressources ;
- une importance stratégique ;
- des infrastructures éventuelles ;
- des fortifications éventuelles.

**[VALIDÉ]** La géographie doit avoir une influence réelle sur les décisions économiques et militaires.

**[VALIDÉ]** Le niveau de détail doit rester raisonnable : une carte suffisamment précise pour permettre des stratégies intéressantes, sans multiplier inutilement les territoires.

**[À DÉFINIR]** Liste définitive des provinces, frontières et territoires jouables (voir § 18).

### 4.3 Indépendance des nations

**[VALIDÉ]** Chaque pays est une entité indépendante, contrôlée soit par un joueur humain, soit par une IA.

**[VALIDÉ]** Les nations ne doivent pas être de simples extensions des grandes puissances.

---

## 5. Temps et organisation des tours

### 5.1 Durée

**[VALIDÉ]** Un tour représente **un mois**.

### 5.2 Résolution simultanée

**[VALIDÉ]** Tous les pays préparent leurs ordres pendant la même phase. Une fois les ordres validés, le monde entier les résout simultanément.

**[VALIDÉ]** Cela concerne notamment :

- les déplacements militaires ;
- les offensives ;
- les décisions économiques ;
- les décisions politiques ;
- les recherches ;
- les négociations et engagements diplomatiques.

**[VALIDÉ]** Le système doit éviter qu'une nation puisse systématiquement agir après avoir observé les décisions des autres pendant le même tour.

**[À DÉFINIR]** Les modalités exactes de résolution des conflits entre ordres simultanés (priorités, égalités, ordre de résolution interne).

---

## 6. Diplomatie

**[VALIDÉ]** La diplomatie est l'un des deux piliers majeurs du jeu. Elle doit être vivante, libre et imprévisible.

### 6.1 Communications

**[VALIDÉ]** Le joueur doit pouvoir communiquer librement avec les autres dirigeants, sous deux formes.

**Communication libre :** messages écrits, discussions, menaces, promesses, arguments, tentatives de persuasion, négociations.

**Propositions officielles :** alliances, traités, accords commerciaux, accords militaires, engagements diplomatiques et autres accords à définir.

### 6.2 Canaux diplomatiques

**[VALIDÉ]** Plusieurs canaux doivent exister :

- communications publiques ;
- communications privées ;
- conversations de groupe ;
- communications officielles ;
- communications secrètes.

**[VALIDÉ]** Les communications diplomatiques sont confidentielles par défaut. Elles ne deviennent accessibles à un tiers que si une interception réussit (voir § 11).

### 6.3 Accords

**[VALIDÉ]** Deux catégories d'accords coexistent :

- les accords **juridiquement contraignants** dans les règles du jeu ;
- les accords **fondés sur la confiance**, dont le respect dépend de la volonté des dirigeants.

**[VALIDÉ]** Les conséquences d'une violation doivent être cohérentes avec la nature de l'accord.

### 6.4 Relations diplomatiques

**[VALIDÉ]** Le système initial de relations doit rester relativement simple : **amitié**, **neutralité**, **hostilité**.

**[VALIDÉ]** Ces relations peuvent évoluer en fonction des actions, des négociations, des promesses et des conflits.

### 6.5 Diplomatie des IA

**[VALIDÉ]** Les IA peuvent : prendre contact spontanément, proposer des alliances, former des coalitions, négocier des accords secrets, menacer d'autres nations, mentir, manipuler, trahir leurs partenaires et modifier leurs relations diplomatiques.

**[VALIDÉ]** Elles ne doivent pas attendre passivement les propositions du joueur.

**[À DÉFINIR]** Modèle exact des traités, conditions de rupture, sanctions diplomatiques, conséquences des trahisons, gestion des crises internationales (voir § 18).

---

## 7. Intelligence artificielle des dirigeants

**[VALIDÉ]** Les IA doivent être considérées comme de véritables acteurs politiques autonomes.

### 7.1 Personnalités

**[VALIDÉ]** Chaque dirigeant possède quelques traits de personnalité, par exemple : agressif, prudent, expansionniste, diplomate, opportuniste.

**[VALIDÉ]** Ces traits influencent ses décisions sans déterminer mécaniquement toutes ses actions.

### 7.2 Objectifs

**[VALIDÉ]** Chaque IA combine :

- ses ambitions personnelles ;
- les intérêts de son pays ;
- sa volonté de survivre ;
- son adaptation à la situation internationale ;
- son objectif de victoire.

### 7.3 Mémoire

**[VALIDÉ]** Les IA doivent disposer d'une **mémoire à long terme**. Elles doivent se souvenir des conversations, des promesses, des trahisons, des alliances, des conflits, des erreurs stratégiques et des événements importants.

**[VALIDÉ]** Une IA trahie doit pouvoir en tenir compte longtemps après les faits.

### 7.4 Comportement

**[VALIDÉ]** Les IA peuvent mentir volontairement, faire des erreurs, manipuler, désinformer, changer d'avis, prendre des initiatives et déclencher des crises diplomatiques.

**[VALIDÉ]** Elles ne sont **pas omniscientes** : elles ne connaissent pas automatiquement les intentions secrètes des autres nations.

### 7.5 Autonomie

**[VALIDÉ]** Les IA doivent pouvoir déclencher indépendamment des crises, des guerres, des alliances, des ruptures diplomatiques et des changements de stratégie.

**[VALIDÉ]** Le monde doit continuer à évoluer même lorsque le joueur ne prend aucune initiative diplomatique.

**[À DÉFINIR]** Architecture des personnalités, système de mémoire, objectifs nationaux, gestion des négociations, des crises et de la décision militaire, limites de connaissance et d'information (voir § 18).

---

## 8. Stratégie militaire

**[VALIDÉ]** La stratégie militaire est le second pilier majeur du jeu.

### 8.1 Organisation des armées

**[VALIDÉ]** Les armées sont représentées sur la carte stratégique, organisées en unités militaires telles que régiments, divisions et formations militaires.

**[VALIDÉ]** Le joueur doit pouvoir organiser, déplacer et commander ses forces.

**[VALIDÉ]** Les effectifs et équipements réellement mobilisés déterminent les capacités militaires disponibles.

### 8.2 Fronts et offensives

**[VALIDÉ]** Les affrontements statiques sur un front ne déclenchent pas automatiquement une bataille tactique indépendante. Les échanges de tirs et les pertes éventuelles sont représentés sur la carte stratégique et consomment des ressources.

**[VALIDÉ]** En revanche, lorsqu'une offensive est lancée et que des armées se rencontrent, une **bataille tactique indépendante** commence.

### 8.3 Batailles tactiques

**[VALIDÉ]** Les batailles tactiques s'inspirent de la philosophie de **Lines of Battle**. Elles se déroulent sur un terrain distinct de la carte stratégique, et le joueur contrôle directement ses unités.

**[VALIDÉ]** Principes retenus :

- unités sélectionnables individuellement ou en groupes ;
- préparation simultanée des ordres ;
- résolution des ordres ;
- déplacements et formations ;
- influence du terrain ;
- prise en compte des effectifs et des équipements ;
- durée maximale de **30 minutes**.

**[VALIDÉ]** Les effectifs présents dans la bataille doivent être proportionnels aux forces engagées sur la carte stratégique. Exemple : une province défendue par trois régiments d'infanterie, une division aéroportée et une division blindée doit présenter une force correspondante dans la bataille tactique.

**[VALIDÉ]** Une petite armée affrontant une force nettement supérieure doit être désavantagée, sauf circonstances particulières.

### 8.4 Terrain

**[VALIDÉ]** Le terrain influence directement les combats : il procure des avantages aux unités adaptées et des difficultés aux unités désavantagées.

**[VALIDÉ]** Les caractéristiques géographiques des provinces doivent être cohérentes avec les terrains des batailles tactiques.

### 8.5 Résolution des batailles

**[VALIDÉ]** Après la bataille :

- le vainqueur occupe automatiquement la province ;
- les pertes sont définitives ;
- les soldats et équipements détruits sont perdus ;
- les unités survivantes conservent les conséquences de leurs pertes et de leur état.

**[VALIDÉ]** Après une offensive échouée, le joueur peut immédiatement tenter une nouvelle offensive ; les pertes et l'état des unités rendent toutefois les tentatives successives plus difficiles.

### 8.6 Éléments non retenus

**[VALIDÉ]** Pour le moment, ne sont **pas** retenus :

- un système de moral des troupes ;
- des généraux à recruter ou à commander ;
- une chaîne de commandement intermédiaire : le joueur commande directement ses unités.

**[VALIDÉ]** Ces éléments ne doivent pas être ajoutés sans validation du propriétaire.

### 8.7 Fortifications

**[VALIDÉ]** Les fortifications sont construites sur la carte stratégique et apparaissent également dans les batailles tactiques. Elles peuvent :

- être améliorées par niveaux ;
- nécessiter des ressources ;
- être améliorées grâce aux technologies ;
- modifier les conditions d'une bataille.

**[À DÉFINIR]** Liste des unités, coûts de recrutement et de production, organisation des régiments et divisions, ravitaillement, gestion des pertes et du remplacement, règles précises des batailles tactiques, durée et fonctionnement des offensives, construction et amélioration des fortifications (voir § 18).

---

## 9. Économie et industrie

**[VALIDÉ]** L'économie doit être suffisamment développée pour permettre une véritable stratégie nationale, mais sans devenir excessivement complexe.

### 9.1 Ressources territoriales

**[VALIDÉ]** Chaque territoire produit **trois ressources**. Leur production suit un principe inspiré de Catan :

- une ressource produite en faible quantité ;
- une ressource produite en quantité moyenne ;
- une ressource produite en grande quantité.

**[VALIDÉ]** Les provinces doivent donc avoir des profils économiques différents.

**[À DÉFINIR]** La liste définitive des ressources (voir § 18).

### 9.2 Gestion économique

**[VALIDÉ]** Le joueur doit pouvoir gérer : les revenus, les dépenses, les investissements, le financement militaire, la production industrielle et la recherche scientifique.

**[VALIDÉ]** La gestion financière doit rester lisible et éviter une comptabilité inutilement détaillée.

### 9.3 Industrie militaire

**[VALIDÉ]** L'industrie constitue un élément stratégique important. Le joueur peut développer des usines, des infrastructures, des chaînes de production, des capacités de mobilisation industrielle et une économie de guerre.

**[VALIDÉ]** Il doit être possible de réorienter une partie de l'économie civile vers la production militaire.

**[VALIDÉ]** Les capacités industrielles influencent directement la puissance nationale.

**[À DÉFINIR]** Coûts de construction, production industrielle, commerce international, budget national, gestion de la population et du niveau de vie (voir § 18).

---

## 10. Recherche et technologies

### 10.1 Progression technologique

**[VALIDÉ]** Toutes les nations commencent en 1914. Grâce à des investissements importants, elles peuvent atteindre un niveau technologique allant jusqu'à **1945**.

**[VALIDÉ]** La progression technologique doit permettre une histoire alternative.

### 10.2 Arbre technologique

**[VALIDÉ]** Le système repose sur un arbre de recherche inspiré de Hearts of Iron IV. Les branches envisagées comprennent :

- infanterie et armement ;
- artillerie ;
- blindés ;
- aviation ;
- marine ;
- industrie ;
- communications et électronique ;
- médecine ;
- logistique.

**[À DÉFINIR]** La structure définitive de l'arbre.

### 10.3 Prérequis chronologiques

**[VALIDÉ]** Les technologies avancées nécessitent normalement des technologies préalables.

**[VALIDÉ]** Il reste possible de tenter une recherche en avance sur son époque, avec une augmentation considérable du coût et du temps nécessaires.

### 10.4 Financement

**[VALIDÉ]** La recherche nécessite un budget scientifique et des ressources matérielles. Le joueur répartit ses investissements entre les branches.

### 10.5 Spécialisations nationales

**[VALIDÉ]** Chaque pays possède des spécialisations scientifiques historiques, qui peuvent évoluer avec le temps grâce aux investissements.

**[À DÉFINIR]** Arbre complet, coûts et durées, prérequis, spécialisations nationales, évolution technologique de 1914 à 1945 (voir § 18).

---

## 11. Renseignement et espionnage

**[VALIDÉ]** Le renseignement doit apporter un avantage stratégique sans rendre les nations omniscientes.

### 11.1 Missions retenues

**[VALIDÉ]** Pour la première version, les services secrets sont principalement consacrés au renseignement classique : informations militaires, économiques et technologiques.

**[VALIDÉ]** Les opérations de sabotage, de contre-espionnage et d'action politique ne sont **pas** retenues à ce stade.

### 11.2 Interception des communications

**[VALIDÉ]** Les communications diplomatiques sont confidentielles par défaut. Une nation peut tenter d'intercepter les communications d'une autre.

**[VALIDÉ]** La capacité à lire les messages dépend de ses compétences et de ses investissements technologiques. Exemple : des compétences en lecture du Morse ou en décryptage permettent de comprendre des communications adverses.

### 11.3 Recherche cryptographique

**[VALIDÉ]** Le décryptage nécessite des investissements importants. Une nation peut développer ses capacités en cryptographie et en renseignement pour accéder aux communications adverses.

### 11.4 Espionnage industriel

**[VALIDÉ]** Un investissement financier important, associé à une recherche adaptée, peut permettre d'obtenir des secrets industriels ou technologiques adverses.

### 11.5 Fiabilité

**[VALIDÉ]** Une interception réussie fournit des informations exactes. Il n'existe **pas** de faux messages interceptés dans le système actuellement retenu.

### 11.6 Rapports

**[VALIDÉ]** Le renseignement fonctionne selon un système hybride : accès immédiat aux interceptions réussies, et rapports périodiques sur les informations recueillies.

**[À DÉFINIR]** Méthodes et portée des interceptions, coûts, compétences cryptographiques, fréquence des rapports, fonctionnement de l'espionnage industriel (voir § 18).

---

## 12. Politique intérieure et régimes

**[VALIDÉ]** La politique intérieure est secondaire par rapport à la diplomatie et à la stratégie militaire, mais elle ne doit pas être absente.

### 12.1 Changements de régime

**[VALIDÉ]** Un pays peut changer de régime si certaines conditions sont réunies. Ces changements entraînent des conséquences positives et négatives.

**[VALIDÉ]** Exemple : l'Empire russe peut évoluer vers un régime communiste.

**[VALIDÉ]** Un changement de régime ne doit pas être uniquement esthétique : il doit avoir des conséquences concrètes sur le fonctionnement du pays, ses relations et ses capacités.

**[À DÉFINIR]** Les conditions exactes de ces transformations.

---

## 13. Conditions de victoire et de défaite

### 13.1 Élimination

**[VALIDÉ]** Lorsqu'un pays est entièrement conquis, son joueur est éliminé.

### 13.2 Victoires possibles

**[VALIDÉ]** Trois voies de victoire sont prévues :

1. **Victoire territoriale** : conquérir l'Europe.
2. **Victoire diplomatique** : dominer politiquement le continent grâce aux alliances, à l'influence et aux relations internationales.
3. **Victoire économique et sociale** : atteindre un niveau de vie exceptionnellement élevé par rapport aux autres nations.

**[À DÉFINIR]** Les conditions précises et les seuils de victoire, la durée maximale d'une partie et la gestion des joueurs éliminés (voir § 18).

---

## 14. Événements et histoire alternative

**[VALIDÉ]** Le jeu commence dans un contexte historique réel.

**[VALIDÉ]** Les événements historiques ne doivent jamais être obligatoires. Les nations peuvent prendre des décisions différentes de celles de leurs dirigeants historiques.

**[VALIDÉ]** Les guerres, alliances, révolutions et crises peuvent donc évoluer de manière imprévisible.

**[VALIDÉ]** L'objectif est de produire une **histoire alternative crédible**, et non de rejouer mécaniquement la Première Guerre mondiale.

---

## 15. Interface et expérience utilisateur

### 15.1 Carte principale

**[VALIDÉ]** La carte stratégique est une carte 2D détaillée, inspirée de Hearts of Iron IV. Elle doit permettre de visualiser : frontières, provinces, armées, infrastructures, fortifications, ressources et fronts.

### 15.2 Diplomatie

**[VALIDÉ]** L'interface diplomatique doit permettre de discuter librement avec les dirigeants. Les différents canaux de communication doivent être facilement accessibles. Le joueur doit pouvoir suivre les négociations, les propositions officielles, les accords et les relations internationales.

### 15.3 Batailles

**[VALIDÉ]** Une bataille tactique ouvre une interface indépendante de la carte stratégique, dans laquelle le joueur contrôle directement ses unités.

### 15.4 Modes de jeu

**[VALIDÉ]** Deux modes principaux sont prévus :

- campagnes historiques ;
- parties libres personnalisables.

**[VALIDÉ]** Le joueur doit également pouvoir observer une partie entièrement contrôlée par les IA, et prendre le contrôle d'une nation en cours de partie.

**[À DÉFINIR]** Support, ergonomie, informations visibles, accessibilité et paramètres des campagnes et des parties libres.

---

## 16. Multijoueur

**[VALIDÉ]** Le multijoueur humain **n'est pas indispensable** pour la première version.

**[VALIDÉ]** L'architecture du jeu doit toutefois anticiper une éventuelle évolution vers le multijoueur, sans rendre cette possibilité inutilement difficile à intégrer ensuite.

**[À DÉFINIR]** Nombre de joueurs humains simultanés, synchronisation, gestion des déconnexions, modération.

---

## 17. Principes de conception des IA

**[VALIDÉ]** Les agents IA qui participent au développement doivent respecter les principes suivants :

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

---

## Priorité de développement

**[VALIDÉ]** Le projet doit avancer par étapes :

1. Finaliser la vision globale. — *fait par la fiche maîtresse v0.1.*
2. **Définir précisément les nations et leurs caractéristiques.** — *dossier initial des sept puissances intégré ([docs/nations/nations.md](docs/nations/nations.md)) ; petites puissances et règles d'évolution à définir.*
3. Définir les ressources, l'économie et l'industrie.
4. Définir les règles diplomatiques.
5. Définir le fonctionnement des IA dirigeantes.
6. Définir les règles militaires et les batailles tactiques.
7. Définir les technologies et le renseignement.
8. Définir les tours, les résolutions et les conditions de victoire.
9. Concevoir l'interface.
10. Définir l'architecture technique.
11. Commencer le développement.

**[VALIDÉ]** Aucune mécanique majeure ne doit être codée avant d'avoir été suffisamment définie et documentée.

---

## 18. Éléments restant à définir

**[À DÉFINIR]** Cette liste doit être mise à jour au fur et à mesure de la conception. Elle reprend celle de la fiche maîtresse v0.1 ; les identifiants de tâches correspondants sont dans [PROGRESS.md](PROGRESS.md) section D.

### Nations et carte

- Liste définitive des provinces.
- Frontières et territoires jouables.
- Caractéristiques des petites puissances.
- Règles chiffrées d'évolution des douze caractéristiques nationales.
- Modèle des colonies et territoires impériaux (régions hors carte, revenus, ressources, mobilisation).
- Valeurs initiales chiffrées des relations diplomatiques et liste des traités de départ.
- Date exacte de début de partie dans l'année 1914.
- Ressources initiales et production territoriale.

### Diplomatie

- Modèle exact des traités.
- Conditions de rupture des accords.
- Sanctions diplomatiques.
- Conséquences des trahisons.
- Gestion des crises internationales.

### Économie

- Liste définitive des ressources.
- Coûts de construction.
- Production industrielle.
- Commerce international.
- Budget national.
- Gestion de la population et du niveau de vie.

### Armée

- Liste des unités.
- Coûts de recrutement et de production.
- Organisation des régiments et divisions.
- Système de ravitaillement.
- Gestion des pertes et du remplacement.
- Règles précises des batailles tactiques.
- Durée et fonctionnement des offensives.
- Construction et amélioration des fortifications.

### Recherche

- Arbre technologique complet.
- Coûts et durées.
- Prérequis.
- Spécialisations nationales.
- Évolution technologique de 1914 à 1945.

### Renseignement

- Méthodes d'interception.
- Portée des interceptions.
- Coûts.
- Compétences cryptographiques.
- Fréquence des rapports.
- Fonctionnement de l'espionnage industriel.

### IA

- Architecture des personnalités.
- Système de mémoire.
- Objectifs nationaux.
- Gestion des négociations.
- Gestion des crises.
- Prise de décision militaire.
- Limites de connaissance et d'information.

### Partie et victoire

- Conditions précises de victoire.
- Durée maximale d'une partie.
- Gestion des joueurs éliminés.
- Paramètres des campagnes.
- Personnalisation des parties libres.

---

## 19. Objectif final

**[VALIDÉ]** Créer un jeu de grande stratégie dans lequel **le monde ne tourne pas autour du joueur**.

**[VALIDÉ]** Chaque nation doit avoir ses propres intérêts, ses propres ambitions, ses propres moyens et sa propre vision du monde.

**[VALIDÉ]** Les dirigeants doivent pouvoir négocier, coopérer, mentir, trahir, anticiper et prendre des décisions indépendantes.

**[VALIDÉ]** Le joueur ne doit pas simplement affronter une IA qui réagit à ses actions : il doit évoluer dans un système international vivant, où les autres nations poursuivent leurs propres stratégies.

**[VALIDÉ]** La diplomatie doit être aussi importante que la guerre. La guerre doit être le prolongement de décisions politiques et stratégiques, et non un simple système de conquête.

**[VALIDÉ]** Le résultat recherché est une simulation géopolitique profonde, crédible et imprévisible, permettant de construire une histoire alternative de l'Europe à partir de 1914.

**[VALIDÉ]** Principe directeur : *le joueur dirige son pays, mais ne dirige pas le monde.*

---

## 20. Gouvernance, décisions et questions ouvertes

### 20.1 Décisions du propriétaire issues de la fiche maîtresse et du dossier des nations

| ID | Décision | Référence |
|---|---|---|
| D-001 | Le jeu est une grande stratégie géopolitique et militaire à partir de l'Europe de 1914, combinant les inspirations Diplomacy/webDiplomacy, Hearts of Iron IV, Lines of Battle et agents IA autonomes. | § 1 |
| D-002 | Le joueur incarne le dirigeant suprême d'une nation et dispose d'une autorité étendue (politique, diplomatie, économie, science, militaire). | § 1.1 |
| D-003 | Les nations sont indépendantes, contrôlées par un humain ou une IA ; ce ne sont pas des extensions des grandes puissances. | § 4.3 |
| D-004 | Le jeu commence en 1914 ; les nations partent de leurs caractéristiques historiques ; l'Histoire peut diverger. | § 3, § 14 |
| D-005 | Sept grandes puissances sont jouables au lancement : Allemagne, Royaume-Uni, France, Russie, Autriche-Hongrie, Italie, Empire ottoman. Les autres pays existent mais ne sont pas jouables en v1. | § 3.2 |
| D-006 | Un tour représente un mois ; les ordres sont préparés puis résolus simultanément pour le monde entier. | § 5 |
| D-007 | La diplomatie et la stratégie militaire sont les deux piliers principaux. | § 2 |
| D-008 | La diplomatie est libre et confidentielle par défaut, avec plusieurs canaux ; l'interception est possible. | § 6, § 11 |
| D-009 | Deux catégories d'accords : contraignants par les règles, ou fondés sur la confiance. | § 6.3 |
| D-010 | Les relations diplomatiques se limitent initialement à amitié / neutralité / hostilité. | § 6.4 |
| D-011 | Les IA sont des acteurs autonomes, dotés de personnalités, d'une mémoire longue, capables de mentir, manipuler, trahir et prendre l'initiative ; elles ne sont pas omniscientes. | § 7 |
| D-012 | Les armées sont représentées sur la carte stratégique ; les effectifs et équipements mobilisés déterminent les capacités. | § 8.1 |
| D-013 | Les fronts statiques se résolvent sur la carte stratégique ; une offensive qui rencontre des armées déclenche une bataille tactique indépendante. | § 8.2 |
| D-014 | Les batailles tactiques s'inspirent de Lines of Battle, durent 30 minutes maximum, et leurs effectifs sont proportionnels aux forces engagées sur la carte. | § 8.3 |
| D-015 | Le vainqueur occupe automatiquement la province ; les pertes sont définitives ; les unités survivantes conservent leurs pertes et leur état. | § 8.5 |
| D-016 | Ne sont pas retenus : moral des troupes, généraux à recruter ou commander, chaîne de commandement intermédiaire. | § 8.6 |
| D-017 | Les fortifications se construisent sur la carte, apparaissent en bataille et s'améliorent par niveaux, avec ressources et technologies. | § 8.7 |
| D-018 | Chaque territoire produit trois ressources, en quantités faible, moyenne et forte (principe inspiré de Catan) ; la liste des ressources reste à définir. | § 9.1 |
| D-019 | L'économie comprend revenus, dépenses, investissements, financement militaire, industrie et recherche ; elle doit rester lisible. | § 9.2 |
| D-020 | L'industrie (usines, infrastructures, mobilisation, économie de guerre) influence directement la puissance nationale. | § 9.3 |
| D-021 | La recherche progresse de 1914 à 1945, sur un arbre inspiré de HoI4, avec prérequis et recherche en avance sur l'époque plus coûteuse. | § 10 |
| D-022 | Le renseignement de la v1 est classique (militaire, économique, technologique) ; pas de sabotage, contre-espionnage ni action politique à ce stade. | § 11.1 |
| D-023 | Une interception réussie donne des informations exactes ; il n'existe pas de faux messages interceptés. | § 11.5 |
| D-024 | La politique intérieure est secondaire mais réelle ; les changements de régime ont des conséquences concrètes. | § 12 |
| D-025 | Trois voies de victoire : territoriale, diplomatique, économique et sociale ; les seuils restent à définir. | § 13 |
| D-026 | Le multijoueur humain n'est pas indispensable en v1, mais l'architecture doit l'anticiper. | § 16 |
| D-027 | Chaque puissance jouable possède douze caractéristiques nationales notées de 1 à 10, relatives aux sept puissances, représentant la situation initiale de 1914 et pouvant évoluer. | [docs/nations/nations.md](docs/nations/nations.md) § I |
| D-028 | Les possessions coloniales sont représentées de manière simplifiée, sous forme de grandes régions impériales. L'Empire allemand est considéré comme n'ayant pas d'empire colonial exploitable, par simplification volontaire. | [docs/nations/nations.md](docs/nations/nations.md) § I.4, II.10 |
| D-029 | Chaque puissance commence avec des ambitions initiales qui orientent l'IA sans l'enfermer : elles peuvent être abandonnées si la situation évolue. | [docs/nations/nations.md](docs/nations/nations.md) § II-XI |
| D-030 | Le jeu s'appelle **Grand Strategy-1914**. Ce nom est le titre officiel du produit (interface, documentation, communication). Le nom du répertoire Git et des chemins de travail reste `GrandStrategy` par commodité technique. | Décision du propriétaire, 2026-10-31 |

**Révision de D-001 (ancienne version 0.1.x) :** la formulation antérieure « jeu inspiré de webDiplomacy » est remplacée par la présente description, plus large. L'inspiration Diplomacy reste explicite.

### 20.2 Décisions d'infrastructure (délégation limitée, réversibles)

| ID | Décision | ADR | Portée |
|---|---|---|---|
| I-001 | Documentation de référence + Git comme socle de collaboration. | [ADR-0001](docs/decisions/0001-documentation-et-git-comme-socle.md) | Structurante, validée par le brief |
| I-002 | `AGENTS.md` est l'unique constitution ; `CLAUDE.md` n'est qu'un pointeur. | [ADR-0002](docs/decisions/0002-interoperabilite-multi-agents.md) | Réversible |
| I-003 | Report de tout choix de pile technique jusqu'à étude et ADR. | [ADR-0003](docs/decisions/0003-report-du-choix-de-pile-technique.md) | Réversible, contrainte du propriétaire |

### 20.3 Questions tranchées par la fiche maîtresse

| Ancienne question | Réponse retenue | Référence |
|---|---|---|
| Q-003 — relation à Diplomacy | Inspiration combinée (Diplomacy, HoI4, Lines of Battle, IA), pas de reprise intégrale. Le détail juridique reste à vérifier. | § 1.2 |
| Q-004 — nombre de joueurs | 7 nations jouables au lancement ; les autres pays sont des IA. Nombre de joueurs humains simultanés à préciser. | § 3.2, § 16 |
| Q-005 — rythme de partie | Tour par tour : un tour = un mois, résolution simultanée. | § 5 |
| Q-006 — solo / multijoueur | Solo contre IA en priorité ; multijoueur humain non indispensable en v1. | § 16 |
| Q-013 — fog of war | Information incomplète (IA non omniscientes, diplomatie confidentielle, interception) ; règles de visibilité sur la carte à définir. | § 6.2, § 7.4, § 11 |
| Q-014 — conditions de victoire | Trois voies : territoriale, diplomatique, économique et sociale. Seuils à définir. | § 13 |
| Q-015 — économie | Oui : trois ressources par territoire, industrie et budget. | § 9 |
| Q-016 — traités contraignants ? | Deux catégories : contraignants par les règles ou fondés sur la confiance. | § 6.3 |
| Q-001 — nom officiel du projet | **Grand Strategy-1914** (décision du propriétaire, 2026-10-31). | § 20.1, D-030 |

### 20.4 Questions encore ouvertes

| ID | Question | Impact | Statut |
|---|---|---|---|
| Q-002 | Quel est le périmètre exact du MVP ? | Priorisation | **Bloquante** |
| Q-007 | Quelle plateforme (web, desktop, mobile) ? | Stack, UI | Haute |
| Q-008 | Quel langage et quel moteur ? | Tout le développement | **Bloquante** (étude requise) |
| Q-009 | Quel modèle de persistance et de sauvegarde ? | Architecture | Haute |
| Q-010 | Quels fournisseurs de LLM, avec quels coûts et quelles limites ? | IA, budget | Haute |
| Q-011 | Les IA peuvent-elles utiliser des modèles locaux ? | Coût, confidentialité | Moyenne |
| Q-012 | Comment garantir qu'une IA ne triche pas informationnellement ? | Équité, architecture | **Bloquante** pour l'IA |
| Q-017 | Quelle durée de partie cible (nombre de tours) ? | Rythme, équilibrage | Moyenne |
| Q-018 | Le jeu doit-il être moddable ? | Architecture | Basse |
| Q-019 | Quelles langues sont supportées ? | i18n | Basse |
| Q-020 | Quelle licence pour le code et les assets ? | Juridique, dépendances | **Bloquante** avant publication |
| Q-021 | Quel niveau d'accessibilité est visé ? | UI | Basse |
| Q-022 | Comment évaluer objectivement la qualité des IA ? | Tests, produit | Haute |
| Q-023 | Quel est le budget d'infrastructure et d'API ? | Choix techniques | Haute |
| Q-024 | Quelles données de joueurs sont collectées et conservées ? | RGPD, sécurité | Haute |
| Q-025 | Quelle est l'identité formelle du propriétaire et le canal d'arbitrage ? | Gouvernance, validation | Haute |
| Q-026 | Quel est le périmètre juridique de l'inspiration HoI4 / Lines of Battle (mécaniques, assets, carte) ? | Juridique | Haute |
| Q-027 | Quelle est la date exacte de début de partie dans l'année 1914 ? | État initial des traités, mobilisations et crises | Haute |
| Q-028 | Comment les douze caractéristiques nationales s'articulent-elles avec les attributs de province, la production et le budget, sans double comptage ? | Économie, industrie, armée | **Bloquante** pour l'économie |
| Q-029 | Comment les colonies et territoires impériaux sont-ils représentés et chiffrés (régions hors carte, revenus, ressources, mobilisation) ? | Économie, diplomatie, carte | Haute |
| Q-030 | Quelles sont les valeurs initiales des relations diplomatiques et la liste exacte des traités de départ, y compris secrets ? | Diplomatie, IA | Haute |
| Q-031 | Quelles règles, coûts et seuils régissent l'évolution des douze caractéristiques ? | Équilibrage, IA, simulation | Haute |

**[VALIDÉ]** Aucune de ces questions ne doit être tranchée par un agent seul (voir [AGENTS.md](AGENTS.md) § 14).

---

## 21. Architecture technique et technologies

**[À DÉFINIR]** Aucune architecture technique n'est validée. Voir [docs/architecture/overview.md](docs/architecture/overview.md) pour la décomposition logique **proposée** et [docs/architecture/technical-decisions.md](docs/architecture/technical-decisions.md) pour les choix ouverts.

**[PROPOSITION]** Séparation logique en couches :

1. **Noyau de règles** : état du jeu, validation et résolution des ordres ; pur, déterministe, sans IA ni interface.
2. **Modèle de données / persistance** : sauvegarde, rechargement, journal d'événements.
3. **Couche diplomatique** : messages, propositions, traités, réputation.
4. **Couche IA** : perception filtrée, mémoire, décision, génération de messages et d'ordres.
5. **Interface / API** : accès joueurs humains, IA, observateurs.
6. **Outillage** : tests, simulation, évaluation des IA, administration.

**[HYPOTHÈSE]** Un noyau déterministe et un journal d'événements append-only faciliteraient les tests, la rejouabilité et l'audit des IA. À valider par une étude et éventuellement un prototype.

**[À DÉFINIR]** Aucune technologie n'est sélectionnée à ce jour.

| Domaine | État | Décision requise |
|---|---|---|
| Langage principal | Non choisi | Oui |
| Moteur de jeu / rendu | Non choisi | Oui |
| Interface | Non choisie (web, desktop, autre) | Oui |
| Base de données / persistance | Non choisie | Oui |
| Transport temps réel | Non choisi | Oui |
| Intégration LLM | Non choisie | Oui |
| Tests | Non choisis | Oui |
| CI/CD | Non choisi | Oui |
| Hébergement | Non choisi | Oui |

**[VALIDÉ]** Ne pas choisir de framework ou de moteur graphique sans étude préalable (voir ADR-0003).

---

## 22. Correspondance avec la documentation thématique

**[VALIDÉ — état documentaire]** Les documents ci-dessous ont été rédigés avant la fiche maîtresse, puis **alignés** sur elle le 2026-10-31 (tâche T-031). Ils reprennent les décisions D-001 à D-029, signalent les tensions C-01 à C-18 de la [revue de conception](docs/design-review-v0.1.md) et distinguent ce qui reste **[À DÉFINIR]**.

**Limite :** un document « aligné » n'est pas un système « spécifié ». Aucune mécanique détaillée n'est validée ; le cahier des charges reste à écrire et à valider (T-030).

| Système | Document | État après alignement |
|---|---|---|
| Document fondateur | [docs/founding-document-v0.1.md](docs/founding-document-v0.1.md) | **Gelé** par empreinte SHA-256 ; source de conception. |
| Revue critique | [docs/design-review-v0.1.md](docs/design-review-v0.1.md) | Tensions C-01 à C-18 et vigilances V-01 à V-08 consignées ; aucune tranchée. |
| Nations et profils | [docs/nations/nations.md](docs/nations/nations.md) | Intégré (dossier du propriétaire) ; articulation chiffrée à définir (Q-027 à Q-031). |
| Régimes et politique intérieure | [docs/nations/regimes.md](docs/nations/regimes.md) | Aligné (D-024) ; conditions et conséquences à définir (C-09). |
| Règles de base, tours, victoire | [docs/gameplay/rules.md](docs/gameplay/rules.md) | Aligné (D-006, D-025) ; phases, verrouillage et seuils non tranchés (C-01, C-08, C-16). |
| Carte et provinces | [docs/gameplay/map-system.md](docs/gameplay/map-system.md) | Aligné (D-004, D-018) ; liste des provinces et fog of war à définir. |
| Militaire stratégique | [docs/military/strategic-warfare.md](docs/military/strategic-warfare.md) | Aligné (D-012 à D-017) ; unités, fronts et conversion à définir (C-03, C-04, C-10). |
| Batailles tactiques | [docs/military/tactical-battles.md](docs/military/tactical-battles.md) | Aligné (D-014) ; déroulement, timeout et batailles multiples à trancher (C-01, C-02, C-15). |
| Économie | [docs/economy/economy-system.md](docs/economy/economy-system.md) | Aligné (D-018 à D-020) ; ressources, budget et niveau de vie à définir (C-07, C-18). |
| Recherche | [docs/technology/research-system.md](docs/technology/research-system.md) | Aligné (D-021) ; arbre, coûts et technologies sensibles à définir (C-12). |
| Renseignement | [docs/intelligence/intelligence-system.md](docs/intelligence/intelligence-system.md) | Aligné (D-022, D-023) ; portée, coût et détection de l'interception à trancher (C-05, C-11). |
| Traités | [docs/diplomacy/treaties.md](docs/diplomacy/treaties.md) | Aligné (D-009) ; types, clauses contraignantes et sanctions à définir. |
| Négociations | [docs/diplomacy/negotiations.md](docs/diplomacy/negotiations.md) | Aligné (D-008) ; protocole, timeouts et confidentialité à définir. |
| Alliances | [docs/diplomacy/alliances.md](docs/diplomacy/alliances.md) | Aligné (D-007, D-011) ; victoire partagée non tranchée (C-08). |
| Réputation | [docs/diplomacy/reputation.md](docs/diplomacy/reputation.md) | Aligné (D-011) ; modèle de réputation à définir. |
| Architecture IA | [docs/ai/ai-architecture.md](docs/ai/ai-architecture.md) | Aligné (D-011) ; méthode et budget à définir (Q-010, Q-012, Q-023). |
| Personnalités | [docs/ai/personalities.md](docs/ai/personalities.md) | Aligné (D-011) ; nombre et génération des traits à définir. |
| Mémoire | [docs/ai/memory-system.md](docs/ai/memory-system.md) | Aligné (D-011) ; support, rétention et coût à définir. |
| Décision | [docs/ai/decision-making.md](docs/ai/decision-making.md) | Aligné (D-011) ; heuristiques, LLM ou hybride non choisis. |
| Interactions multi-agents | [docs/ai/multi-agent-interactions.md](docs/ai/multi-agent-interactions.md) | Aligné (D-011, D-026) ; protocole et reproductibilité à définir. |
| Architecture technique | [docs/architecture/overview.md](docs/architecture/overview.md) | Aligné (D-006, D-026) ; aucune pile choisie ; ADR-0005 **proposé**. |
| Décisions techniques | [docs/architecture/technical-decisions.md](docs/architecture/technical-decisions.md) | Aligné ; TD-001 à TD-027 ouverts. |
| Modèle de données | [docs/architecture/data-model.md](docs/architecture/data-model.md) | Aligné ; modèle conceptuel seulement, non validé. |

---

## Historique de ce document

| Date | Agent | Modification |
|---|---|---|
| 2026-10-31 | OpenCode | Création initiale à partir du brief du propriétaire. |
| 2026-10-31 | OpenCode | Version 0.2.0 : intégration de la fiche maîtresse v0.1 du propriétaire. Révision de D-001, ajout des décisions D-002 à D-026, des questions tranchées et des questions Q-026 et suivantes. |
| 2026-10-31 | OpenCode | Version 0.2.1 : intégration du dossier des puissances jouables. Ajout de D-027 à D-029, des questions Q-027 à Q-031, renvoi vers `docs/nations/nations.md` et mise à jour des éléments restant à définir. |
| 2026-10-31 | OpenCode | Version 0.2.2 : alignement de la documentation thématique sur la fiche maîtresse (T-031), ajout du document fondateur gelé, de la revue de conception et des ADR-0004/0005 au tableau de correspondance. Aucune décision de jeu ajoutée. |
| 2026-10-31 | OpenCode | Version 0.2.3 : le propriétaire arrête le nom officiel du jeu, **Grand Strategy-1914**. Ajout de D-030, clôture de Q-001, mise à jour de l'en-tête et du `README.md`. Aucune règle de jeu modifiée. |

Toute modification de ce document doit être cohérente avec [PROGRESS.md](PROGRESS.md), [AGENTS.md](AGENTS.md) et les ADR acceptés.
