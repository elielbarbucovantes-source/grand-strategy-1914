# Revue de conception — document fondateur v0.1

> **Statut :** Cadrage — revue critique, non validée par le propriétaire
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source analysée :** [founding-document-v0.1.md](founding-document-v0.1.md)
> **Documents liés :** [PROJECT.md](../PROJECT.md) · [PROGRESS.md](../PROGRESS.md) · [ADR-0004](decisions/0004-adoption-du-document-fondateur.md) · [ADR-0005](decisions/0005-integration-strategique-tactique.md) · [architecture/overview.md](architecture/overview.md)

---

## 1. Objet et portée

Ce document **gèle** le document fondateur v0.1 du propriétaire, en consigne l'empreinte, puis relève les **tensions internes** et les **manques de définition** qu'il contient.

Il ne tranche aucune règle de jeu. Chaque tension est :

- décrite factuellement ;
- qualifiée (contradiction, imprécision, dépendance, risque) ;
- accompagnée d'options et, éventuellement, d'une **proposition d'agent** explicitement non validée ;
- reliée à une question ou à une tâche de [PROGRESS.md](../PROGRESS.md).

**Règle :** une tension non signalée est un défaut. Une tension signalée mais tranchée par un agent seul est une violation d'[AGENTS.md](../AGENTS.md) § 14.

## 2. Empreinte et gel du document source

| Élément | Valeur |
|---|---|
| Fichier | `docs/founding-document-v0.1.md` |
| Version | 0.1 |
| Date de remise | 2026-10-31 |
| Taille | 24 850 octets au moment du gel |
| Empreinte SHA-256 | `6de617ca12d9b9028b72ddae6ec85a41b394f1875a4b6af0cabfeb553e1a25ce` |
| Statut du gel | **Gelé pour analyse.** Toute correction doit créer une version distincte (v0.2, etc.), pas modifier ce fichier. |

Vérification de l'empreinte :

```bash
sha256sum docs/founding-document-v0.1.md
```

L'empreinte ci-dessus a été calculée le 2026-10-31 avec cette commande. Si le fichier est modifié, le script de vérification doit signaler l'écart.

## 3. Ce que le document fondateur tranche explicitement

Les décisions ci-dessous sont reprises dans [PROJECT.md § 20.1](../PROJECT.md#201-décisions-du-propriétaire-issues-de-la-fiche-maîtresse) sous les identifiants D-001 à D-026. Elles sont considérées comme **[VALIDÉ]** dans le périmètre du document fondateur, sans que cela valide le cahier des charges détaillé.

| Domaine | Décision de cadrage |
|---|---|
| Cadre | Europe de 1914, histoire alternative crédible. |
| Nations | Sept grandes puissances jouables ; les autres pays existent comme entités indépendantes non jouables en v1. |
| Temps | Un tour = un mois ; préparation puis résolution simultanée. |
| Carte | Carte stratégique 2D de l'Europe, provinces conquérables avec attributs. |
| Diplomatie | Canaux publics/privés/groupes/officiels/secrets ; confidentialité par défaut ; accords contraignants ou de confiance ; relations amitié/neutralité/hostilité. |
| IA | Dirigeants autonomes, personnalités, mémoire longue, mensonge et trahison, non-omniscience, initiatives. |
| Militaire | Armées stratégiques ; fronts statiques résolus sur la carte ; offensives donnant lieu à des batailles tactiques indépendantes de 30 minutes maximum. |
| Économie | Trois ressources par territoire (faible/moyenne/forte), industrie, économie de guerre, budget. |
| Recherche | Arbre 1914-1945, prérequis, recherche en avance plus coûteuse, spécialisations nationales. |
| Renseignement | Renseignement classique et interception ; pas de sabotage ni d'action politique en v1 ; interceptions exactes, pas de faux messages. |
| Politique intérieure | Secondaire mais présente ; changements de régime aux conséquences concrètes. |
| Victoire | Trois voies : territoriale, diplomatique, économique et sociale. |
| Multijoueur | Non indispensable en v1, mais architecture anticipée. |

## 4. Méthode de revue

1. Lire le document intégralement, sans le corriger.
2. Distinguer ce qui est **décidé**, ce qui est **esquissé**, ce qui est **laissé ouvert**.
3. Chercher les propositions qui ne peuvent pas être vraies ensemble, ou qui exigent une règle absente.
4. Pour chaque tension : décrire le conflit, estimer l'impact, proposer des options, nommer le décideur.
5. Ne jamais présenter une option d'agent comme une décision.

## 5. Registre des tensions

### Synthèse

| ID | Tension | Type | Gravité | Décision requise |
|---|---|---|---|---|
| C-01 | Tours mensuels simultanés vs batailles tactiques de 30 minutes en temps réel | Contradiction temporelle | **Critique** | Propriétaire |
| C-02 | Plusieurs batailles simultanées et contrôle direct par un seul joueur | Contradiction d'attention | **Critique** | Propriétaire |
| C-03 | Conversion des forces stratégiques en effectifs tactiques | Imprécision | Haute | Propriétaire + agent |
| C-04 | « Nouvelle offensive immédiate » vs calendrier mensuel | Contradiction temporelle | Haute | Propriétaire |
| C-05 | Interception exacte des messages vs confidentialité et équité | Risque d'équilibre | **Critique** | Propriétaire |
| C-06 | Niveau de fog of war stratégique non défini | Manque | Haute | Propriétaire |
| C-07 | Victoire économique et sociale sans modèle de niveau de vie | Manque de modèle | Haute | Propriétaire + agent |
| C-08 | Conditions, seuils et fin de partie non définis | Manque | Haute | Propriétaire |
| C-09 | Changement de régime sans conditions ni conséquences chiffrées | Manque | Moyenne | Propriétaire + agent |
| C-10 | « Pas de moral » vs « les unités conservent leur état » | Ambiguïté | Moyenne | Propriétaire |
| C-11 | Portée et coût de l'interception, détection, contre-mesures | Manque | Haute | Propriétaire + agent |
| C-12 | Recherche 1914-1945 : rythme, coûts, technologies sensibles | Manque | Moyenne | Propriétaire |
| C-13 | Inspiration HoI4 / Lines of Battle : licences, carte, assets, données historiques | Risque juridique | **Critique** avant publication | Propriétaire |
| C-14 | Prise de contrôle d'une nation en cours de partie | Manque de règles | Moyenne | Propriétaire |
| C-15 | Sauvegarde, pause et rejouabilité des batailles temps réel | Contradiction technique | Haute | Propriétaire + agent |
| C-16 | Diplomatie pendant le mois vs verrouillage des ordres | Manque | Haute | Propriétaire |
| C-17 | Multijoueur anticipé vs batailles temps réel synchrones | Risque d'architecture | Haute | Propriétaire + agent |
| C-18 | Population et niveau de vie absents du modèle économique | Manque | Moyenne | Propriétaire + agent |

### C-01 — Tours mensuels simultanés et batailles tactiques en temps réel

**Constat.** Le document impose un tour mensuel à résolution simultanée (§ 5) et des batailles tactiques indépendantes pouvant durer jusqu'à 30 minutes (§ 8.3). Il ne dit pas **quand**, dans le calendrier du tour, ces 30 minutes se déroulent, ni si le monde stratégique est figé pendant la bataille.

**Pourquoi c'est une tension.** Un tour mensuel est un temps abstrait et asynchrone ; une bataille de 30 minutes est un temps réel et synchrone. Mélanger les deux exige de définir :

- le moment d'ouverture de la bataille (avant résolution, pendant, après ?) ;
- si les autres nations peuvent agir pendant la bataille ;
- si la bataille peut être résolue instantanément côté calendrier (le résultat s'applique au mois en cours) ;
- ce qui se passe si un joueur ne peut pas être présent pendant 30 minutes.

**Options envisagées (non validées).**

| Option | Description | Avantage | Risque |
|---|---|---|---|
| A — Bataille « hors temps » | La bataille est une instance séparée ouverte après validation des ordres ; le calendrier stratégique est suspendu pour les participants, mais le résultat s'impute au tour courant. | Sépare clairement les deux échelles. | Blocage si un joueur est absent ; questions de synchronisation. |
| B — Bataille asynchrone par rounds | La bataille est découpée en rounds tour par tour, avec minuterie longue ; 30 minutes devient un budget de temps de décision cumulé. | Compatible avec les parties asynchrones. | Perd le temps réel ; change la philosophie Lines of Battle. |
| C — Bataille temps réel planifiée | La bataille a lieu à un créneau fixé ; le tour ne se résout pas avant. | Lisibilité, tension dramatique. | Contrainte d'horaire forte ; mauvais pour le solo. |
| D — Résolution instantanée optionnelle | Le joueur peut déléguer la bataille à une résolution automatique ; le temps réel est optionnel. | Souple. | Nécessite une IA tactique et un modèle de résolution automatique. |

**Proposition d'agent (non validée).** Option A pour le solo, avec un mode « résolution automatique » (option D) si le joueur est absent, et un budget de temps explicite. Voir [ADR-0005](decisions/0005-integration-strategique-tactique.md), à l'état `proposé`.

**Décideur :** propriétaire. **Tâche :** T-029.

### C-02 — Plusieurs batailles simultanées, un seul joueur

**Constat.** Une offensive peut rencontrer des armées sur plusieurs provinces dans le même mois. Le document ne limite pas le nombre de batailles simultanées. Or un joueur humain ne peut pas commander directement deux batailles temps réel de 30 minutes en parallèle.

**Pourquoi c'est une tension.** Le § 8.6 exclut les généraux et la chaîne de commandement intermédiaire, mais le § 8.3 exige un contrôle direct des unités. Avec plusieurs batailles, le contrôle direct devient matériellement impossible sans :

- file d'attente des batailles ;
- résolution automatique des batailles secondaires ;
- délégation à une IA tactique ;
- limite d'une bataille active par joueur.

**Options (non validées).** Bataille active unique + file d'attente ; résolution automatique des batailles non supervisées ; IA tactique de subordination (contredit § 8.6 si elle commande) ; limitation du nombre d'offensives par mois.

**Proposition d'agent (non validée).** File d'attente + résolution automatique explicite, sans créer de généraux ni de moral. L'IA tactique éventuelle devrait être un **outil de résolution**, pas un personnage.

**Décideur :** propriétaire. **Tâche :** T-024 / T-029.

### C-03 — Conversion des forces stratégiques en effectifs tactiques

**Constat.** Le § 8.3 affirme que les effectifs tactiques doivent être « proportionnels » aux forces stratégiques, avec un exemple (trois régiments, une division aéroportée, une division blindée). Aucun coefficient, aucune échelle, aucune règle de perte ne sont définis.

**Questions.** Un régiment vaut-il un nombre fixe de figurines ? Les équipements ont-ils un coût tactique ? Les pertes tactiques se convertissent-elles en pertes stratégiques selon un ratio ? Une unité stratégique détruite à 100 % est-elle retirée de la carte ? Les blessés sont-ils comptés ?

**Proposition d'agent (non validée).** Définir une **unité de conversion** unique (par exemple « point de force ») et une table explicite stratégique → tactique → stratégique, testable par simulation. Ne pas choisir de chiffres avant validation.

**Décideur :** propriétaire. **Tâche :** T-024.

### C-04 — « Nouvelle offensive immédiate » et calendrier mensuel

**Constat.** Le § 8.5 autorise, après un échec, à « immédiatement tenter une nouvelle offensive ». Le § 5 impose un tour d'un mois avec résolution simultanée.

**Pourquoi c'est une tension.** « Immédiatement » peut signifier : dans la même bataille, dans le même mois, au tour suivant, sans limite. Chaque interprétation change l'équilibre et peut créer une boucle infinie d'offensives.

**Options.** Une seule offensive par province et par mois ; une nouvelle offensive possible au tour suivant ; une relance dans la même bataille avec un coût croissant ; une relance immédiate mais limitée par un budget d'action.

**Proposition d'agent (non validée).** Une offensive par province et par mois, avec possibilité de relance au tour suivant, et consommation accrue de ressources. À valider.

**Décideur :** propriétaire. **Tâche :** T-024.

### C-05 — Interception exacte et confidentialité

**Constat.** Le § 6.2 rend les communications confidentielles par défaut. Le § 11.5 affirme qu'une interception réussie fournit des informations **exactes** et qu'il n'existe **pas de faux messages interceptés**. Le § 11.2 lie la capacité à des compétences et investissements technologiques.

**Pourquoi c'est une tension.** Une interception exacte peut :

- vider la diplomatie de son incertitude ;
- donner un avantage décisif à la nation qui investit ;
- rendre la trahison détectable à coût quasi nul ;
- poser des questions de vie privée si des messages de joueurs humains sont lus ;
- créer un déséquilibre si une IA intercepte mieux qu'un humain.

**Points à trancher.** Qui peut tenter d'intercepter qui ? À quelle fréquence ? Y a-t-il une détection de l'interception ? L'intercepteur voit-il le message complet ou un fragment ? Les messages interceptés peuvent-ils être réutilisés publiquement ? Les interceptions sont-elles visibles dans le replay ? Les joueurs humains consentent-ils à ce que leurs messages soient lisibles par d'autres ?

**Options.** Interception partielle (métadonnées, extrait, message complet selon le niveau technologique) ; faux messages **non** retenus pour l'instant (conforme au document) ; détection et contre-espionnage reportés ; consentement et politique de confidentialité à définir (Q-024).

**Proposition d'agent (non validée).** Conserver l'exactitude décidée, mais ajouter un **coût, une portée et une détection** ; ne pas ajouter de faux messages sans validation. Documenter explicitement la politique de confidentialité.

**Décideur :** propriétaire. **Tâche :** T-025 / T-029.

### C-06 — Fog of war stratégique non défini

**Constat.** Le § 7.4 dit que les IA ne sont pas omniscientes et ne connaissent pas les intentions secrètes. Le § 15.1 veut afficher les armées sur la carte. Le document ne dit pas si les positions et effectifs adverses sont visibles.

**Options.** Positions publiques (modèle proche de Diplomacy) ; positions visibles mais effectifs masqués ; visibilité par province observée ; renseignement nécessaire pour connaître les effectifs.

**Proposition d'agent (non validée).** Position des armées visible (lisibilité stratégique), effectifs et intentions filtrés par le renseignement. À valider.

**Décideur :** propriétaire. **Tâche :** T-026.

### C-07 — Victoire économique et sociale sans modèle

**Constat.** Le § 13.2 définit une victoire par « niveau de vie exceptionnellement élevé par rapport aux autres nations ». Le § 9 ne modélise ni population, ni niveau de vie, ni indicateur social. Le § 18 mentionne pourtant « gestion de la population et du niveau de vie ».

**Pourquoi c'est une tension.** On ne peut pas gagner selon un indicateur qui n'existe pas. Il faut définir :

- l'indicateur (PIB par habitant ? consommation ? espérance de vie ? bonheur ?) ;
- la population et sa croissance ;
- les effets de la guerre sur le niveau de vie ;
- le lien avec les ressources et l'industrie ;
- le seuil et la durée.

**Proposition d'agent (non validée).** Un indicateur composite simple, lisible, calculé à partir de la production, de la consommation et des dépenses sociales ; ne pas ajouter de simulation démographique lourde avant validation. À trancher par le propriétaire.

**Décideur :** propriétaire. **Tâche :** T-021 / T-026.

### C-08 — Seuils de victoire, durée et fin de partie

**Constat.** Les trois voies de victoire sont décidées, mais aucun seuil, aucune durée maximale, aucune condition de match nul, aucune règle de victoire partagée ne sont définies. L'élimination est définie (« pays entièrement conquis »), mais la conquête totale de l'Europe est une condition extrême.

**Questions.** Combien de provinces pour la victoire territoriale ? Quel seuil d'influence pour la victoire diplomatique ? Quel seuil économique ? Une alliance peut-elle gagner collectivement ? Que se passe-t-il à la date de fin (1945 ?) ? Les joueurs éliminés peuvent-ils revenir ?

**Décideur :** propriétaire. **Tâche :** T-026.

### C-09 — Changements de régime

**Constat.** Le § 12 affirme qu'un pays peut changer de régime « si certaines conditions sont réunies », avec des conséquences positives et négatives, mais ne définit ni les conditions, ni les conséquences.

**Risque.** Un changement de régime peut devenir un événement arbitraire ou, à l'inverse, purement cosmétique, ce que le document interdit.

**Proposition d'agent (non validée).** Conditions déclenchées par des facteurs observables (défaite, crise économique, occupation, influence étrangère) et conséquences explicites sur les relations, la production et la stabilité. À valider.

**Décideur :** propriétaire. **Tâche :** T-020.

### C-10 — « Pas de moral » et « état des unités »

**Constat.** Le § 8.6 exclut le moral des troupes. Le § 8.5 dit que les unités survivantes « conservent les conséquences de leurs pertes et de leur état ».

**Ambiguïté.** Que contient cet « état » si ce n'est pas du moral ? Effectifs, équipement, fatigue, cohésion, expérience ? Chaque choix influence les batailles suivantes.

**Proposition d'agent (non validée).** Définir un état **matériel** (effectifs, équipement, approvisionnement) sans moral. Ne pas introduire de moral déguisé sous un autre nom sans validation.

**Décideur :** propriétaire. **Tâche :** T-024.

### C-11 — Portée, coût et détection de l'interception

**Constat.** Le document décrit l'intention (compétences, investissements) mais pas les règles opérationnelles : qui intercepte, combien de messages, à quelle distance, avec quelle détection, quelles contre-mesures.

**Risque.** Sans limites, l'interception devient une lecture globale ; avec trop de limites, elle devient inutile.

**Décideur :** propriétaire. **Tâche :** T-025.

### C-12 — Recherche 1914-1945

**Constat.** L'arbre va de 1914 à 1945 et permet la recherche en avance. Le document ne définit ni le nombre de technologies, ni les coûts, ni la vitesse, ni le traitement des technologies historiquement sensibles (nucléaire, armes chimiques, etc.).

**Questions.** Une partie dure-t-elle jusqu'en 1945 ? Peut-on rechercher le nucléaire ? Les technologies sont-elles datées historiquement ou seulement ordonnées par prérequis ? Les spécialisations nationales sont-elles des bonus fixes ou évolutifs ?

**Décideur :** propriétaire. **Tâche :** T-025.

### C-13 — Licences, carte, assets et données historiques

**Constat.** Le document cite HoI4 et Lines of Battle comme inspirations. Il ne dit pas si la carte, les noms de provinces, les statistiques historiques, les icônes ou les assets proviennent de sources protégées.

**Risque.** Un projet inspiré peut être légal ; une copie de carte, d'assets ou de textes ne l'est pas forcément. La licence du projet n'est pas définie (Q-020).

**Règle.** Aucune œuvre protégée ne doit être copiée sans vérification. Les sources de données historiques doivent être documentées avec leur licence. Voir [AGENTS.md § 10](../AGENTS.md#10-dépendances-et-licences).

**Décideur :** propriétaire. **Tâche :** T-028 / Q-026.

### C-14 — Prise de contrôle d'une nation en cours de partie

**Constat.** Le § 15.4 permet au joueur de prendre le contrôle d'une nation en cours de partie. Le document ne dit pas :

- si l'IA précédente transmet sa mémoire et ses engagements ;
- si le joueur peut voir les secrets de l'IA ;
- si les autres nations sont informées du changement ;
- si cette prise de contrôle est possible en multijoueur.

**Risque.** Un joueur pourrait « prendre » une nation pour lire ses secrets, ou hériter d'engagements invisibles.

**Proposition d'agent (non validée).** Transfert d'un **état public** de la nation (engagements connus, réputation, situation), sans donner accès à la mémoire privée de l'IA ; les traités secrets restent secrets. À valider.

**Décideur :** propriétaire. **Tâche :** T-027.

### C-15 — Sauvegarde, pause et rejouabilité des batailles temps réel

**Constat.** Le projet exige la sauvegarde/reprise et la rejouabilité. Une bataille temps réel de 30 minutes est difficile à sauvegarder, à mettre en pause et à rejouer de façon déterministe, surtout si elle dépend d'actions humaines en temps réel.

**Options.** Enregistrer les commandes horodatées et rejouer la bataille ; considérer la bataille comme non rejouable mais conserver son résultat ; utiliser un moteur déterministe à pas fixes ; autoriser la pause.

**Décideur :** propriétaire. **Tâche :** T-028 / T-029.

### C-16 — Diplomatie pendant le mois et verrouillage des ordres

**Constat.** Le § 5.2 veut que tous les pays préparent leurs ordres pendant la même phase et que la résolution soit simultanée, pour éviter qu'une nation agisse après avoir vu les ordres des autres. Le § 6.1 veut une diplomatie libre. Le document ne dit pas si les négociations se poursuivent après le verrouillage des ordres, ni si un accord conclu juste avant la résolution s'applique immédiatement.

**Questions.** Y a-t-il une phase de négociation distincte ? Les ordres sont-ils verrouillés à une heure fixe ? Un traité signé après le verrouillage s'applique-t-il au tour suivant ? Peut-on modifier ses ordres après un accord ?

**Décideur :** propriétaire. **Tâche :** T-022 / T-026.

### C-17 — Multijoueur et batailles temps réel

**Constat.** Le § 16 demande d'anticiper le multijoueur ; le § 8.3 impose des batailles temps réel. Plusieurs joueurs humains dans des batailles simultanées exigent une synchronisation, des timers communs, une gestion des déconnexions et une politique de pause.

**Risque.** Une architecture pensée pour le solo pourrait rendre le multijoueur très coûteux à ajouter, contrairement à l'exigence du document.

**Proposition d'agent (non validée).** Séparer dès la conception le **moteur de bataille** du **calendrier stratégique**, avec un contrat de session de bataille. Ne pas choisir de technologie avant l'étude de pile (ADR-0003).

**Décideur :** propriétaire + étude technique. **Tâche :** T-028.

### C-18 — Population et niveau de vie

**Constat.** Le § 9 ne mentionne pas la population comme ressource, mais le § 13.2 et le § 18 parlent de niveau de vie et de population. Sans population, la victoire économique et sociale et la conscription n'ont pas de support.

**Proposition d'agent (non validée).** Ajouter un indicateur de population par province ou par nation, distinct des trois ressources, et un indicateur de niveau de vie dérivé. À valider ; ne pas l'implémenter avant.

**Décideur :** propriétaire. **Tâche :** T-021.

## 6. Points de vigilance transverses

| ID | Point | Description |
|---|---|---|
| V-01 | Lisibilité | La combinaison diplomatie + économie + recherche + renseignement + tactique peut dépasser la charge cognitive. Le document exige pourtant des mécaniques compréhensibles. |
| V-02 | Équilibre des puissances | Les caractéristiques historiques rendent certaines nations plus fortes. Le document veut éviter qu'une petite puissance devienne artificiellement égale à une grande, sans définir de mécanisme d'équilibrage. |
| V-03 | IA et économie | Les IA doivent gérer trois ressources, un budget, une industrie et un arbre technologique. La charge de décision et le coût LLM ne sont pas estimés. |
| V-04 | Temps de développement | Chaque système (carte, tactique, IA, économie) est un projet en soi. Aucun ordre de priorité technique n'est encore validé. |
| V-05 | Determinisme et temps réel | Le noyau déterministe et les batailles temps réel ont des exigences différentes ; il faut définir la frontière. |
| V-06 | Données de joueurs | L'interception de messages humains et la mémoire des IA posent des questions RGPD (Q-024). |
| V-07 | Accessibilité | Les batailles de 30 minutes et la diplomatie en temps réel peuvent exclure certains joueurs ; l'accessibilité est une question ouverte (Q-021). |
| V-08 | Modding | La carte, les règles et l'arbre technologique devraient-ils être moddables (Q-018) ? Cela influence les formats. |

## 7. Ce que cette revue ne fait pas

- Elle ne valide aucune mécanique.
- Elle ne remplace pas le cahier des charges détaillé.
- Elle ne choisit pas la pile technique.
- Elle ne tranche pas les tensions : elle les rend visibles et les confie au propriétaire.
- Elle ne prétend pas que le document fondateur est incohérent dans son intention ; elle montre que son **niveau de détail** laisse des choix ouverts qui changent l'expérience.

## 8. Prochaines étapes recommandées

1. Le propriétaire arbitre en priorité C-01, C-02, C-05, C-08 et C-13.
2. Les agents documentent les options sans les présenter comme validées.
3. [ADR-0005](decisions/0005-integration-strategique-tactique.md) reste `proposé` jusqu'à l'arbitrage de C-01/C-02.
4. Les documents thématiques signalent chaque tension qui les concerne.
5. Le cahier des charges détaillé n'est déclaré valide qu'après levée explicite des tensions critiques.

## 9. Historique

| Date | Agent | Modification |
|---|---|---|
| 2026-10-31 | OpenCode | Création de la revue, gel du document fondateur v0.1, registre C-01 à C-18. |
