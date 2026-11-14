# Nations et puissances jouables — situation initiale 1914

> **Statut :** Spécifié (contenu fourni par le propriétaire, intégré par un agent)
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source :** dossier « Puissances jouables — situation initiale 1914 » remis par le propriétaire du projet le 2026-10-31.
> **Documents liés :** [PROJECT.md](../../PROJECT.md) § 3, § 7, § 18, § 20 · [gameplay/rules.md](../gameplay/rules.md) · [gameplay/map-system.md](../gameplay/map-system.md) · [economy/economy-system.md](../economy/economy-system.md) · [military/strategic-warfare.md](../military/strategic-warfare.md) · [technology/research-system.md](../technology/research-system.md) · [ai/personalities.md](../ai/personalities.md) · [diplomacy/treaties.md](../diplomacy/treaties.md) · [design-review-v0.1.md](../design-review-v0.1.md)

---

## Objet et autorité de ce document

Ce document fixe les **profils initiaux des sept puissances jouables** en 1914 : identité, douze caractéristiques nationales, forces, faiblesses, armée, marine, économie, diplomatie, ambitions initiales et possessions.

- Le **contenu de fond** (valeurs, textes nationaux, ambitions) provient du propriétaire du projet. Il est repris sans modification de valeur ; seules la mise en forme, la numérotation, les renvois et l'annexe d'intégration ont été ajoutés par l'agent.
- Les étiquettes **[VALIDÉ]**, **[PROPOSITION]**, **[HYPOTHÈSE]** et **[À DÉFINIR]** ont la même signification que dans [PROJECT.md](../../PROJECT.md).
- Les **douze caractéristiques** sont une couche de simulation nationale. Leur articulation chiffrée avec les attributs de province, la production, le budget et la recherche n'est **pas** encore définie : voir § XII et [PROJECT.md](../../PROJECT.md) § 20.4.
- Les profils ne sont pas des destins : les ambitions initiales peuvent être abandonnées, les caractéristiques peuvent évoluer (PROJECT.md § 3.3, D-004).

### Ce que ce document ne définit pas

- La liste des provinces et le tracé des frontières.
- Les caractéristiques des petites puissances non jouables.
- Les valeurs chiffrées des relations diplomatiques initiales (amitié / neutralité / hostilité) et la liste exacte des traités de départ.
- Les coûts, seuils et durées d'évolution des caractéristiques.
- Le rendu chiffré des colonies dans l'économie et la mobilisation.
- La date exacte de début de partie dans l'année 1914.

---

## Sommaire

- [I. Principes généraux](#i-principes-généraux)
- [II. Empire allemand](#ii-empire-allemand)
- [III. Empire britannique](#iii-empire-britannique)
- [IV. République française](#iv-république-française)
- [V. Empire russe](#v-empire-russe)
- [VI. Empire austro-hongrois](#vi-empire-austro-hongrois)
- [VII. Royaume d'Italie](#vii-royaume-ditalie)
- [VIII. Empire ottoman](#viii-empire-ottoman)
- [IX. Comparaison générale](#ix-comparaison-générale)
- [X. Identité de jeu de chaque puissance](#x-identité-de-jeu-de-chaque-puissance)
- [XI. Règles communes de comportement des IA nationales](#xi-règles-communes-de-comportement-des-ia-nationales)
- [XII. Intégration au projet et questions ouvertes](#xii-intégration-au-projet-et-questions-ouvertes)

---

# I. Principes généraux

## 1. Les sept puissances

Le jeu commence avec sept nations jouables :

1. Empire allemand
2. Empire britannique
3. République française
4. Empire russe
5. Empire austro-hongrois
6. Royaume d'Italie
7. Empire ottoman

Les autres États existent sur la carte, possèdent leurs propres territoires, intérêts et gouvernements, mais ne sont pas directement jouables dans la première version (D-005).

## 2. Échelle des statistiques

Chaque nation possède douze caractéristiques nationales, notées de 1 à 10.

Les notes sont relatives aux sept puissances jouables :

| Note | Signification |
|---:|---|
| 10 | Niveau exceptionnel parmi les sept puissances. |
| 8-9 | Niveau très élevé. |
| 6-7 | Niveau intermédiaire à élevé. |
| 4-5 | Niveau limité. |
| 1-3 | Faiblesse majeure. |

Les statistiques représentent la situation initiale de 1914. Elles peuvent évoluer au cours de la partie grâce aux investissements, aux réformes, aux découvertes technologiques, aux conquêtes et aux changements de régime.

## 3. Les douze caractéristiques

| # | Caractéristique | Définition |
|---:|---|---|
| 1 | Population | Nombre total d'habitants du territoire national principal. |
| 2 | Puissance démographique | Capacité à mobiliser la population, renouveler les effectifs et soutenir l'effort national. |
| 3 | Industrie | Capacité de production industrielle. |
| 4 | Économie | Richesse, finances publiques, commerce et capacité de financement. |
| 5 | Ressources naturelles | Disponibilité des matières premières et ressources stratégiques. |
| 6 | Armée terrestre | Puissance militaire terrestre initiale. |
| 7 | Marine | Capacité navale et maîtrise des espaces maritimes. |
| 8 | Technologie | Niveau scientifique et technique. |
| 9 | Infrastructures | Chemins de fer, routes, ports et réseaux de communication. |
| 10 | Diplomatie | Capacité à négocier, influencer et construire des relations internationales. |
| 11 | Prestige international | Réputation et statut de la nation dans le monde. |
| 12 | Unité nationale | Cohésion politique et stabilité intérieure. |

L'unité nationale constitue une seule statistique générale. Elle ne simule pas individuellement les différentes nationalités.

Une faible unité nationale augmente les risques de contestation, de révolte et de déstabilisation.

> **Attention :** ces douze indicateurs nationaux ne remplacent pas les attributs de province (géographie, ressources, infrastructures, fortifications) définis dans [gameplay/map-system.md](../gameplay/map-system.md). Leur articulation est une question ouverte (§ XII, Q-028).

## 4. Les colonies et territoires impériaux

Les possessions coloniales sont représentées de manière simplifiée.

Elles prennent la forme de grands territoires stratégiques pouvant apporter :

- des ressources naturelles ;
- des revenus ;
- une profondeur stratégique ;
- une influence diplomatique ;
- des possibilités de recrutement et de mobilisation, selon les capacités du pays.

Il n'est pas nécessaire de gérer individuellement chaque colonie.

L'Empire russe constitue un cas particulier : ses territoires impériaux sont principalement contigus et ne doivent pas être assimilés à un empire colonial maritime.

> **Simplification assumée :** l'Empire allemand est considéré comme ne possédant **pas d'empire colonial exploitable** dans le jeu, alors qu'il possédait historiquement des colonies en Afrique et dans le Pacifique. Cette décision est volontaire (D-028).

---

# II. Empire allemand

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Empire allemand |
| Capitale | Berlin |
| Régime | Monarchie fédérale constitutionnelle |
| Souverain | Guillaume II |
| Population | environ 67 millions d'habitants |
| Identité stratégique | Puissance continentale |
| Situation géographique | Europe centrale |
| Note globale | **9/10** |

L'Allemagne est l'une des principales puissances industrielles, militaires et scientifiques du monde en 1914.

Son développement industriel rapide lui permet de rivaliser avec le Royaume-Uni et de dépasser progressivement la France dans plusieurs domaines économiques.

Sa situation géographique constitue cependant une faiblesse majeure : elle se trouve entre plusieurs grandes puissances potentiellement hostiles.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 8 |
| Puissance démographique | 8 |
| Industrie | 10 |
| Économie | 9 |
| Ressources naturelles | 7 |
| Armée terrestre | 10 |
| Marine | 8 |
| Technologie | 10 |
| Infrastructures | 10 |
| Diplomatie | 7 |
| Prestige international | 9 |
| Unité nationale | 8 |

Note globale : **9/10**.

## 3. Forces nationales

- Industrie extrêmement développée.
- Armée terrestre parmi les plus puissantes du monde.
- Recherche scientifique et ingénierie de premier plan.
- Réseau ferroviaire très performant.
- Population importante et en croissance.
- Capacité élevée de production militaire.
- Administration et organisation étatiques relativement efficaces.

## 4. Faiblesses nationales

- Position géographique exposée à plusieurs fronts.
- Dépendance à certaines importations alimentaires et matières premières.
- Rivalité navale avec le Royaume-Uni.
- Risque d'encerclement diplomatique.
- Difficultés à soutenir simultanément plusieurs fronts.
- Tensions politiques et sociales internes.

## 5. Armée

L'Allemagne possède une armée terrestre particulièrement puissante.

Son système militaire repose sur :

- une armée permanente importante ;
- un système de réserves ;
- une mobilisation organisée ;
- un réseau ferroviaire permettant des déplacements stratégiques rapides ;
- une industrie capable de produire des équipements en grande quantité.

La mobilisation doit néanmoins avoir un coût économique et diplomatique.

## 6. Économie et industrie

L'économie allemande est fortement industrialisée.

Ses secteurs importants comprennent :

- la sidérurgie ;
- la chimie ;
- la mécanique ;
- l'industrie électrique ;
- la construction ferroviaire ;
- la production d'équipements industriels.

L'Allemagne dispose de ressources importantes, notamment du charbon, mais reste dépendante de certaines importations.

Une guerre maritime prolongée pourrait donc fragiliser son économie.

## 7. Marine

L'Allemagne possède une marine moderne et ambitieuse.

Elle constitue une puissance navale importante, mais reste confrontée à la supériorité britannique.

La marine représente un investissement stratégique majeur, mais elle ne doit pas détourner excessivement les ressources nécessaires à l'armée terrestre.

## 8. Diplomatie et alliances

Situation initiale :

- Alliance avec l'Autriche-Hongrie.
- Appartenance à la Triple Alliance avec l'Italie.
- Relations tendues avec la France.
- Relations tendues avec la Russie.
- Rivalité navale et diplomatique avec le Royaume-Uni.

L'Italie conserve son indépendance diplomatique et reste historiquement neutre au début de la guerre en 1914.

L'Allemagne doit chercher à éviter une coalition hostile réunissant ses principaux adversaires.

## 9. Ambitions initiales

L'IA allemande commence avec les ambitions suivantes :

1. Préserver son statut de grande puissance.
2. Maintenir son influence en Europe centrale.
3. Conserver l'alliance austro-hongroise.
4. Éviter l'encerclement diplomatique.
5. Préserver ses intérêts économiques et commerciaux.
6. Maintenir une marine suffisamment puissante pour protéger ses intérêts.

Ces ambitions ne sont pas des objectifs obligatoires. L'IA peut les abandonner si la situation évolue (D-029).

## 10. Colonies

Pour les besoins du gameplay, l'Allemagne est considérée comme ne possédant pas d'empire colonial exploitable.

Il s'agit d'une simplification volontaire : historiquement, l'Empire allemand possédait bien plusieurs colonies en Afrique et dans le Pacifique (D-028).

---

# III. Empire britannique

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Empire britannique |
| Capitale | Londres |
| Régime | Monarchie constitutionnelle et parlementaire |
| Souverain | George V |
| Population métropolitaine | environ 46 millions d'habitants |
| Identité stratégique | Puissance diplomatique et maritime |
| Situation géographique | Îles Britanniques et empire mondial |
| Note globale | **8,5/10** |

Le Royaume-Uni constitue la principale puissance maritime mondiale en 1914.

Son influence dépasse largement son territoire métropolitain grâce à son immense empire colonial, son commerce international et sa puissance financière.

Sa stratégie repose sur le maintien de l'équilibre européen et la protection de ses intérêts maritimes.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 6 |
| Puissance démographique | 9 |
| Industrie | 9 |
| Économie | 10 |
| Ressources naturelles | 9 |
| Armée terrestre | 7 |
| Marine | 10 |
| Technologie | 9 |
| Infrastructures | 9 |
| Diplomatie | 10 |
| Prestige international | 10 |
| Unité nationale | 8 |

Note globale : **8,5/10**.

La puissance démographique tient compte du potentiel impérial, mais les populations coloniales ne sont pas immédiatement mobilisables comme celles de la métropole.

## 3. Forces nationales

- Première puissance navale mondiale.
- Empire colonial immense.
- Réseau commercial international.
- Place financière de premier plan.
- Forte influence diplomatique.
- Marine marchande considérable.
- Infrastructures maritimes et portuaires développées.
- Capacité à projeter des forces sur plusieurs continents.

## 4. Faiblesses nationales

- Dépendance aux importations alimentaires.
- Dépendance aux routes maritimes.
- Armée terrestre métropolitaine relativement réduite.
- Mobilisation terrestre de grande ampleur progressive.
- Coût élevé de la défense impériale.
- Difficulté à protéger simultanément toutes les possessions.

## 5. Armée

Le Royaume-Uni possède une armée professionnelle relativement réduite par rapport aux grandes puissances continentales.

Son système militaire repose principalement sur :

- une armée professionnelle ;
- des réserves ;
- des forces stationnées dans différentes parties de l'Empire ;
- une capacité de mobilisation progressive ;
- le transport maritime des troupes.

L'armée britannique peut devenir considérablement plus importante, mais cette transformation demande du temps et des ressources.

## 6. Marine

La marine constitue le principal instrument de puissance britannique.

Elle permet :

- de protéger les routes commerciales ;
- de défendre les possessions impériales ;
- de transporter des troupes ;
- de maintenir une présence internationale ;
- de limiter les possibilités d'expansion maritime des puissances rivales.

Le Royaume-Uni doit conserver une supériorité navale suffisante pour protéger son empire.

## 7. Économie

L'économie britannique repose particulièrement sur :

- le commerce international ;
- la finance ;
- les assurances ;
- la marine marchande ;
- l'industrie ;
- les investissements internationaux.

L'industrie britannique reste importante, même si l'Allemagne la concurrence fortement dans certains secteurs.

## 8. Diplomatie et alliances

Situation initiale :

- Entente cordiale avec la France.
- Rapprochement diplomatique avec la Russie.
- Rivalité stratégique avec l'Allemagne.
- Relations variables avec les autres puissances.

L'Entente cordiale ne constitue pas, à elle seule, une alliance militaire automatique.

Le Royaume-Uni conserve une grande liberté de décision.

## 9. Ambitions initiales

1. Maintenir l'équilibre des puissances européennes.
2. Empêcher une puissance continentale de dominer l'Europe.
3. Protéger l'Empire britannique.
4. Maintenir la supériorité navale.
5. Préserver les routes commerciales.
6. Conserver son influence financière et diplomatique.
7. Éviter une guerre continentale coûteuse lorsque cela est possible.

## 10. Colonies et possessions

L'Empire britannique possède de vastes territoires répartis sur plusieurs continents.

Les possessions sont représentées sous forme de grandes régions impériales.

Elles apportent :

- des ressources ;
- des revenus ;
- des positions stratégiques ;
- des possibilités de mobilisation ;
- une influence internationale.

Leur défense constitue toutefois une charge permanente.

---

# IV. République française

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | République française |
| Capitale | Paris |
| Régime | République parlementaire |
| Président | Raymond Poincaré |
| Population métropolitaine | environ 40 millions d'habitants |
| Identité stratégique | Puissance diplomatique et militaire |
| Situation géographique | Europe occidentale |
| Note globale | **8/10** |

La France demeure une grande puissance européenne.

Elle possède une économie diversifiée, une armée importante et un vaste empire colonial.

Cependant, sa population augmente beaucoup moins rapidement que celle de l'Allemagne.

La récupération de l'Alsace-Lorraine, perdue en 1871, reste un élément majeur de la politique française.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 6 |
| Puissance démographique | 5 |
| Industrie | 8 |
| Économie | 8 |
| Ressources naturelles | 7 |
| Armée terrestre | 9 |
| Marine | 8 |
| Technologie | 9 |
| Infrastructures | 9 |
| Diplomatie | 9 |
| Prestige international | 9 |
| Unité nationale | 8 |

Note globale : **8/10**.

## 3. Forces nationales

- Armée terrestre importante.
- Réseau d'alliances diplomatiques.
- Économie diversifiée.
- Industrie développée.
- Empire colonial considérable.
- Réseau ferroviaire efficace.
- Forte influence culturelle et diplomatique.
- Recherche scientifique avancée.

## 4. Faiblesses nationales

- Population inférieure à celle de l'Allemagne.
- Croissance démographique relativement faible.
- Retard industriel relatif face à l'Allemagne.
- Dépendance stratégique envers ses alliances.
- Nécessité de défendre plusieurs possessions coloniales.
- Tensions politiques intérieures.

## 5. Armée

La France possède une armée terrestre importante et un système de réserves.

Elle dispose :

- d'une armée permanente ;
- de réserves mobilisables ;
- d'une artillerie importante ;
- de fortifications orientales ;
- de capacités militaires coloniales.

Les fortifications de Verdun, Toul, Épinal et Belfort constituent des éléments importants de sa défense orientale.

Il ne faut pas représenter la ligne Maginot dans le scénario de 1914 : elle n'existe pas encore.

La doctrine française initiale privilégie une approche offensive, même si elle peut évoluer au cours de la partie.

## 6. Économie et industrie

L'économie française repose sur plusieurs secteurs :

- l'agriculture ;
- l'industrie métallurgique ;
- le textile ;
- la production mécanique ;
- la finance ;
- le commerce international.

L'industrie française est développée, mais sa capacité de production est inférieure à celle de l'Allemagne.

## 7. Marine

La France possède une marine importante.

Elle doit protéger :

- les côtes métropolitaines ;
- les routes commerciales ;
- les possessions coloniales ;
- les intérêts français en Méditerranée.

La marine française constitue un complément à sa puissance terrestre.

## 8. Diplomatie et alliances

Situation initiale :

- Alliance militaire avec la Russie.
- Entente cordiale avec le Royaume-Uni.
- Relations hostiles avec l'Allemagne.
- Relations prudentes avec l'Italie.

L'alliance franco-russe constitue un pilier essentiel de la sécurité française.

L'Entente cordiale avec le Royaume-Uni repose sur une coopération diplomatique étroite, mais ne doit pas être assimilée automatiquement à une alliance militaire irrévocable.

## 9. Ambitions initiales

1. Préserver son statut de grande puissance.
2. Maintenir l'alliance avec la Russie.
3. Conserver la coopération britannique.
4. Contenir la puissance allemande.
5. Défendre ses frontières orientales.
6. Préserver son empire colonial.
7. Maintenir son influence diplomatique en Europe.

La récupération de l'Alsace-Lorraine constitue une ambition historique majeure, mais son degré de priorité peut évoluer selon les décisions du gouvernement.

## 10. Colonies

La France possède un vaste empire colonial, notamment en Afrique et en Asie.

Ces territoires représentent :

- des ressources ;
- des revenus ;
- des positions stratégiques ;
- une profondeur impériale ;
- des possibilités de recrutement.

La gestion reste volontairement simplifiée.

---

# V. Empire russe

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Empire russe |
| Capitale | Saint-Pétersbourg |
| Régime | Monarchie impériale autocratique |
| Souverain | Nicolas II |
| Population | environ 175 millions d'habitants |
| Identité stratégique | Puissance démographique et territoriale |
| Situation géographique | Europe orientale et Asie |
| Note globale | **7,5/10** |

L'Empire russe est la plus grande puissance démographique et territoriale parmi les sept nations jouables.

Il dispose d'un immense potentiel humain, militaire et économique.

Cependant, son développement industriel reste inégal et son régime politique est fragilisé par de profondes tensions intérieures.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 10 |
| Puissance démographique | 10 |
| Industrie | 6 |
| Économie | 6 |
| Ressources naturelles | 10 |
| Armée terrestre | 9 |
| Marine | 6 |
| Technologie | 6 |
| Infrastructures | 4 |
| Diplomatie | 8 |
| Prestige international | 8 |
| Unité nationale | 4 |

Note globale : **7,5/10**.

## 3. Forces nationales

- Population immense.
- Très grandes réserves humaines.
- Territoire considérable.
- Ressources naturelles abondantes.
- Agriculture importante.
- Armée terrestre nombreuse.
- Potentiel industriel en croissance.
- Influence diplomatique dans les Balkans.

## 4. Faiblesses nationales

- Retard industriel relatif.
- Infrastructures insuffisantes.
- Difficultés logistiques.
- Développement économique inégal.
- Instabilité politique.
- Tensions sociales.
- Contestations nationales.
- Administration complexe d'un territoire immense.

## 5. Armée

L'Empire russe possède une armée nombreuse et un potentiel de mobilisation considérable.

Son système militaire repose sur :

- une armée permanente importante ;
- de vastes réserves ;
- une mobilisation massive ;
- une modernisation progressive ;
- une capacité de remplacement des pertes relativement élevée.

Cependant, son équipement, sa formation, ses communications et sa logistique restent inégaux.

L'armée russe doit être puissante par son nombre, mais pas automatiquement efficace dans toutes les situations.

## 6. Économie et industrie

La Russie reste principalement agricole.

Son industrialisation s'accélère néanmoins, notamment dans :

- la région de Saint-Pétersbourg ;
- Moscou ;
- le bassin du Donets ;
- l'Oural.

Son industrie métallurgique et ses infrastructures progressent.

Le pays reste cependant dépendant de capitaux, de technologies et de certains équipements étrangers.

## 7. Marine

La marine russe a été affaiblie par la guerre russo-japonaise de 1904-1905.

Elle conserve néanmoins des capacités importantes dans plusieurs régions maritimes.

Ses principales difficultés concernent :

- la dispersion géographique de ses flottes ;
- les contraintes d'accès aux mers ;
- les infrastructures navales ;
- la modernisation.

## 8. Diplomatie et alliances

Situation initiale :

- Alliance militaire avec la France.
- Convention et rapprochement avec le Royaume-Uni.
- Rivalité stratégique avec l'Autriche-Hongrie.
- Relations hostiles avec l'Allemagne.
- Relations complexes avec l'Empire ottoman.

La Russie cherche à préserver sa position dans les Balkans et à maintenir son statut de grande puissance.

## 9. Ambitions initiales

1. Maintenir son statut de grande puissance.
2. Protéger ses intérêts dans les Balkans.
3. Soutenir son influence auprès des peuples slaves.
4. Maintenir l'alliance avec la France.
5. Préserver le rapprochement avec le Royaume-Uni.
6. Accroître son influence sur les détroits du Bosphore et des Dardanelles.
7. Moderniser son industrie et ses infrastructures.

La question des détroits constitue une ambition stratégique historique, mais sa réalisation dépend des circonstances diplomatiques et militaires.

## 10. Territoires impériaux

L'Empire russe possède d'immenses territoires contigus en Europe et en Asie.

Ils représentent :

- des ressources naturelles ;
- des terres agricoles ;
- des réserves humaines ;
- une profondeur stratégique ;
- des possibilités de développement économique.

L'immensité territoriale est simultanément une force et une faiblesse : elle offre des ressources considérables, mais complique les communications et l'administration.

---

# VI. Empire austro-hongrois

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Empire austro-hongrois |
| Capitale | Vienne |
| Régime | Monarchie dualiste |
| Souverain | François-Joseph Ier |
| Population | environ 52 millions d'habitants |
| Identité stratégique | Puissance impériale multinationale |
| Situation géographique | Europe centrale et Balkans |
| Note globale | **6,5/10** |

L'Autriche-Hongrie est une grande puissance européenne, mais son existence repose sur un équilibre politique fragile.

Elle rassemble de nombreux peuples et nationalités sous une même monarchie.

Sa principale difficulté est de maintenir l'unité de cet ensemble.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 7 |
| Puissance démographique | 7 |
| Industrie | 7 |
| Économie | 7 |
| Ressources naturelles | 7 |
| Armée terrestre | 7 |
| Marine | 4 |
| Technologie | 7 |
| Infrastructures | 7 |
| Diplomatie | 6 |
| Prestige international | 7 |
| Unité nationale | 3 |

Note globale : **6,5/10**.

## 3. Forces nationales

- Population importante.
- Position centrale en Europe.
- Industrie développée en Autriche et en Bohême.
- Ressources agricoles et minières.
- Industrie mécanique et métallurgique.
- Production d'équipements militaires.
- Réseau ferroviaire relativement développé.
- Alliance avec l'Allemagne.

## 4. Faiblesses nationales

- Divisions nationales profondes.
- Tensions politiques internes.
- Difficultés de coordination administrative.
- Diversité linguistique au sein de l'armée.
- Développement économique inégal.
- Marine relativement faible.
- Dépendance stratégique envers l'Allemagne.

## 5. Armée

L'armée austro-hongroise constitue une force importante, mais ses capacités sont limitées par des problèmes structurels.

Elle repose sur :

- une armée permanente ;
- des réserves ;
- une organisation militaire commune ;
- des forces territoriales propres aux différentes parties de la monarchie.

Les difficultés linguistiques, politiques et organisationnelles peuvent ralentir son efficacité.

L'armée doit rester polyvalente, sans être artificiellement aussi efficace que l'armée allemande.

## 6. Économie et industrie

L'Empire possède une économie diversifiée.

Ses principaux centres industriels se trouvent notamment en Autriche et en Bohême.

Ses secteurs importants comprennent :

- la métallurgie ;
- la mécanique ;
- le textile ;
- l'agriculture ;
- l'industrie chimique ;
- la production d'armements.

La Galicie possède également des ressources pétrolières importantes.

Le développement industriel reste cependant très inégal selon les régions.

## 7. Marine

La marine austro-hongroise est essentiellement une marine régionale.

Elle est principalement destinée à défendre les intérêts de l'Empire dans l'Adriatique.

Elle ne peut pas rivaliser avec les grandes marines britannique, allemande ou française.

## 8. Diplomatie et alliances

Situation initiale :

- Alliance avec l'Allemagne.
- Appartenance à la Triple Alliance avec l'Italie.
- Rivalité avec la Russie.
- Tensions importantes avec la Serbie.
- Relations complexes avec les autres puissances balkaniques.

L'Italie reste libre de ses décisions et ne rejoint pas automatiquement l'Autriche-Hongrie en cas de guerre.

## 9. Ambitions initiales

1. Préserver l'intégrité territoriale de l'Empire.
2. Maintenir l'unité de la monarchie.
3. Conserver son statut de grande puissance.
4. Préserver l'alliance allemande.
5. Maintenir son influence dans les Balkans.
6. Contenir les mouvements nationalistes susceptibles de déstabiliser l'Empire.
7. Limiter l'influence russe dans les Balkans.

## 10. Territoires

L'Autriche-Hongrie ne possède pas d'empire colonial outre-mer.

Son territoire européen comprend notamment :

- l'Autriche ;
- la Hongrie ;
- la Bohême ;
- la Moravie ;
- la Galicie ;
- la Croatie-Slavonie ;
- la Bosnie-Herzégovine ;
- plusieurs autres territoires de la monarchie.

Ces régions sont intégrées dans un même ensemble impérial, mais peuvent présenter des différences économiques, politiques et culturelles.

---

# VII. Royaume d'Italie

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Royaume d'Italie |
| Capitale | Rome |
| Régime | Monarchie constitutionnelle |
| Souverain | Victor-Emmanuel III |
| Population | environ 35 millions d'habitants |
| Identité stratégique | Puissance régionale méditerranéenne |
| Situation géographique | Péninsule italienne et Méditerranée |
| Note globale | **6/10** |

L'Italie est un État relativement récent, unifié au XIXe siècle.

Elle cherche à s'affirmer parmi les grandes puissances européennes et à renforcer sa position en Méditerranée.

Elle possède une marine importante et une industrie en développement, mais reste limitée par ses ressources économiques et ses divisions régionales.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 5 |
| Puissance démographique | 5 |
| Industrie | 6 |
| Économie | 6 |
| Ressources naturelles | 4 |
| Armée terrestre | 6 |
| Marine | 7 |
| Technologie | 6 |
| Infrastructures | 6 |
| Diplomatie | 6 |
| Prestige international | 6 |
| Unité nationale | 6 |

Note globale : **6/10**.

## 3. Forces nationales

- Position stratégique en Méditerranée.
- Marine relativement importante.
- Industrie en développement.
- Population suffisante pour soutenir une armée respectable.
- Possessions coloniales.
- Capacité à jouer un rôle diplomatique entre les grandes puissances.
- Potentiel de développement économique.

## 4. Faiblesses nationales

- Fortes inégalités entre le nord et le sud.
- Ressources naturelles limitées.
- Dépendance aux importations de charbon et de matières premières.
- Industrie inférieure à celle des grandes puissances industrielles.
- Armée terrestre perfectible.
- Capacités financières limitées pour une guerre prolongée.

## 5. Armée

L'Italie possède une armée importante, mais dont les capacités sont inférieures à celles des grandes puissances continentales.

Elle dispose :

- d'une armée permanente ;
- de réserves mobilisables ;
- d'une artillerie respectable ;
- de capacités militaires coloniales ;
- d'une marge de modernisation.

La préparation militaire et l'équipement doivent constituer des priorités nationales.

## 6. Marine

La marine italienne constitue un élément essentiel de sa puissance.

Elle doit :

- défendre les côtes italiennes ;
- protéger les possessions méditerranéennes ;
- maintenir une présence en Méditerranée ;
- contester l'influence des puissances rivales dans la région.

Elle représente l'un des principaux atouts stratégiques du pays.

## 7. Économie et industrie

L'Italie connaît une industrialisation progressive, particulièrement dans le nord.

Ses principaux secteurs comprennent :

- la métallurgie ;
- le textile ;
- la mécanique ;
- l'agriculture ;
- la construction navale.

Les différences économiques entre le nord industrialisé et le sud plus agricole constituent un problème structurel.

## 8. Diplomatie et alliances

Situation initiale :

- Appartenance officielle à la Triple Alliance avec l'Allemagne et l'Autriche-Hongrie.
- Neutralité au début de la Première Guerre mondiale.
- Rivalités territoriales avec l'Autriche-Hongrie.
- Intérêts concurrents avec les puissances méditerranéennes.
- Relations diplomatiques susceptibles d'évoluer.

L'Italie ne doit jamais être considérée comme un allié automatique de l'Allemagne ou de l'Autriche-Hongrie.

Elle conserve une véritable liberté diplomatique.

## 9. Ambitions initiales

1. Devenir une grande puissance méditerranéenne.
2. Renforcer son influence dans les Balkans.
3. Revendiquer les territoires de langue italienne encore sous domination austro-hongroise.
4. Développer ses possessions coloniales.
5. Moderniser son industrie.
6. Renforcer sa marine.
7. Préserver son indépendance diplomatique.

## 10. Colonies

L'Italie possède notamment :

- la Libye ;
- l'Érythrée ;
- la Somalie italienne.

Ces territoires constituent des possessions stratégiques, économiques et politiques.

Leur développement peut devenir une priorité pour le gouvernement italien.

---

# VIII. Empire ottoman

## 1. Identité nationale

| Élément | Valeur |
|---|---|
| Nom | Empire ottoman |
| Capitale | Constantinople |
| Régime | Monarchie impériale |
| Souverain | Mehmed V |
| Population | environ 22 millions d'habitants |
| Identité stratégique | Empire en déclin cherchant à préserver son existence |
| Situation géographique | Anatolie, Moyen-Orient et détroits |
| Note globale | **4,5/10** |

L'Empire ottoman traverse une période de crise profonde.

Il a perdu de nombreux territoires au cours des décennies précédentes et doit faire face à des difficultés économiques, militaires et politiques.

Sa position géographique demeure néanmoins exceptionnelle.

Le contrôle du Bosphore et des Dardanelles lui donne une importance stratégique considérable.

## 2. Statistiques nationales

| Caractéristique | Note |
|---|---:|
| Population | 4 |
| Puissance démographique | 5 |
| Industrie | 3 |
| Économie | 4 |
| Ressources naturelles | 6 |
| Armée terrestre | 5 |
| Marine | 4 |
| Technologie | 4 |
| Infrastructures | 3 |
| Diplomatie | 5 |
| Prestige international | 5 |
| Unité nationale | 3 |

Note globale : **4,5/10**.

## 3. Forces nationales

- Position géographique exceptionnelle.
- Contrôle des détroits.
- Territoire étendu.
- Ressources agricoles et naturelles.
- Population importante à l'échelle régionale.
- Potentiel de modernisation.
- Possibilité de jouer un rôle majeur au Moyen-Orient.
- Position stratégique entre plusieurs grandes puissances.

## 4. Faiblesses nationales

- Industrie insuffisamment développée.
- Économie fragile.
- Endettement important.
- Infrastructures limitées.
- Réseau ferroviaire insuffisant.
- Armée inégalement équipée.
- Dépendance technologique envers les puissances étrangères.
- Tensions nationales et politiques.
- Difficultés administratives.

## 5. Armée

L'armée ottomane est en cours de modernisation.

Elle dispose :

- d'une armée permanente ;
- de réserves mobilisables ;
- d'une expérience militaire régionale ;
- d'un potentiel humain important ;
- d'une assistance technique étrangère.

La modernisation militaire constitue une priorité essentielle.

Les difficultés logistiques et industrielles limitent cependant les capacités de l'Empire.

## 6. Marine

La marine ottomane reste relativement faible face aux grandes puissances navales.

Elle doit principalement :

- défendre les côtes ;
- protéger les détroits ;
- préserver les communications maritimes ;
- soutenir la défense du territoire impérial.

Sa modernisation nécessite des investissements importants.

## 7. Économie et industrie

L'économie ottomane demeure principalement agricole.

Ses secteurs importants comprennent :

- l'agriculture ;
- le commerce régional ;
- les activités portuaires ;
- l'exploitation de certaines ressources naturelles ;
- une industrie encore limitée.

L'Empire souffre d'un manque d'infrastructures et d'une forte dépendance financière extérieure.

La modernisation économique constitue une condition essentielle à sa survie.

## 8. Diplomatie et alliances

Situation initiale :

- Relations diplomatiques avec plusieurs grandes puissances européennes.
- Rapprochement stratégique avec l'Allemagne.
- Rivalité avec la Russie.
- Relations complexes avec le Royaume-Uni et la France.
- Intérêts stratégiques dans les Balkans et au Moyen-Orient.

Un accord secret avec l'Allemagne est conclu le 2 août 1914.

L'Empire ottoman reste néanmoins officiellement neutre au début du conflit et ne rejoint la guerre qu'à l'automne 1914.

Le jeu doit distinguer les accords secrets des alliances publiquement déclarées.

## 9. Ambitions initiales

1. Préserver l'intégrité territoriale de l'Empire.
2. Défendre Constantinople.
3. Conserver le contrôle des détroits.
4. Moderniser l'armée.
5. Développer l'industrie et les infrastructures.
6. Maintenir l'influence ottomane au Moyen-Orient.
7. Éviter de nouvelles pertes territoriales.
8. Retrouver son prestige international.

## 10. Territoires impériaux

L'Empire ottoman possède notamment :

- l'Anatolie ;
- la Syrie ;
- la Mésopotamie ;
- la Palestine ;
- le Hedjaz ;
- des territoires dans la péninsule arabique.

Ces régions sont représentées comme de grandes provinces stratégiques.

Elles peuvent fournir :

- des ressources ;
- des revenus ;
- des positions stratégiques ;
- des possibilités de développement.

Leur gestion reste simplifiée, mais leur stabilité politique peut devenir un enjeu majeur.

---

# IX. Comparaison générale

## 1. Tableau des caractéristiques

| Caractéristique | Allemagne | Royaume-Uni | France | Russie | Autriche-Hongrie | Italie | Ottoman |
|---|---:|---:|---:|---:|---:|---:|---:|
| Population | 8 | 6 | 6 | 10 | 7 | 5 | 4 |
| Puissance démographique | 8 | 9 | 5 | 10 | 7 | 5 | 5 |
| Industrie | 10 | 9 | 8 | 6 | 7 | 6 | 3 |
| Économie | 9 | 10 | 8 | 6 | 7 | 6 | 4 |
| Ressources naturelles | 7 | 9 | 7 | 10 | 7 | 4 | 6 |
| Armée terrestre | 10 | 7 | 9 | 9 | 7 | 6 | 5 |
| Marine | 8 | 10 | 8 | 6 | 4 | 7 | 4 |
| Technologie | 10 | 9 | 9 | 6 | 7 | 6 | 4 |
| Infrastructures | 10 | 9 | 9 | 4 | 7 | 6 | 3 |
| Diplomatie | 7 | 10 | 9 | 8 | 6 | 6 | 5 |
| Prestige international | 9 | 10 | 9 | 8 | 7 | 6 | 5 |
| Unité nationale | 8 | 8 | 8 | 4 | 3 | 6 | 3 |

## 2. Notes globales

| Nation | Note globale | Profil |
|---|---:|---|
| Allemagne | 9/10 | Puissance continentale dominante |
| Royaume-Uni | 8,5/10 | Puissance maritime et diplomatique |
| France | 8/10 | Grande puissance militaire et diplomatique |
| Russie | 7,5/10 | Géant démographique et territorial |
| Autriche-Hongrie | 6,5/10 | Empire puissant mais fragile |
| Italie | 6/10 | Puissance régionale ambitieuse |
| Empire ottoman | 4,5/10 | Empire affaibli à moderniser |

Les notes globales constituent une appréciation synthétique de la puissance initiale et du potentiel stratégique. Elles ne sont pas la moyenne mathématique des douze caractéristiques.

---

# X. Identité de jeu de chaque puissance

Chaque nation doit proposer une expérience stratégique distincte.

## Allemagne — Dominer sans être encerclée

L'Allemagne possède les moyens industriels et militaires de devenir la puissance dominante du continent.

Son problème est diplomatique : elle doit éviter de se retrouver simultanément confrontée à plusieurs grandes puissances.

## Royaume-Uni — Préserver l'équilibre mondial

Le Royaume-Uni doit protéger son empire, maintenir sa supériorité maritime et empêcher l'émergence d'une puissance continentale hégémonique.

Sa puissance repose autant sur la diplomatie et l'économie que sur son armée.

## France — Défendre son rang et ses alliances

La France doit préserver son statut de grande puissance, maintenir ses alliances et contenir l'Allemagne.

Elle possède des moyens militaires et économiques importants, mais souffre d'un désavantage démographique.

## Russie — Transformer son potentiel en puissance

La Russie dispose d'immenses réserves humaines et naturelles.

Elle doit moderniser son industrie, améliorer ses infrastructures et éviter une déstabilisation intérieure.

## Autriche-Hongrie — Préserver l'Empire

L'Autriche-Hongrie doit maintenir son unité politique et nationale tout en conservant son influence en Europe centrale et dans les Balkans.

Sa survie intérieure constitue un enjeu permanent.

## Italie — S'imposer en Méditerranée

L'Italie doit développer son industrie, renforcer sa marine et exploiter les rivalités entre les grandes puissances.

Sa liberté diplomatique constitue l'un de ses principaux atouts.

## Empire ottoman — Survivre et se moderniser

L'Empire ottoman doit préserver ses territoires, moderniser son économie et son armée et défendre sa position stratégique.

Il possède un potentiel régional important, mais commence avec des handicaps considérables.

---

# XI. Règles communes de comportement des IA nationales

Les profils nationaux déterminent les préférences initiales des IA, mais ne doivent jamais enfermer leur comportement.

Chaque IA possède :

- des ambitions historiques initiales ;
- des intérêts économiques ;
- des intérêts territoriaux ;
- des préférences diplomatiques ;
- des priorités militaires ;
- une évaluation de ses propres capacités ;
- une mémoire des événements et des relations internationales.

Les ambitions peuvent changer.

Une Allemagne peut rechercher un rapprochement avec la Russie si ses intérêts l'exigent.

Une Italie peut abandonner la Triple Alliance.

Une Russie peut privilégier son développement intérieur plutôt qu'une politique d'influence dans les Balkans.

Une Autriche-Hongrie peut engager des réformes pour préserver son unité.

Un Empire ottoman peut chercher une alliance avec une puissance traditionnellement rivale.

Les nations ne sont donc pas condamnées à reproduire leur histoire réelle.

Les fiches définissent leur situation de départ, leurs avantages, leurs faiblesses et leurs tendances initiales.

**Le joueur dirige son pays, mais ne dirige pas le monde.**

> **Cohérence IA :** ces règles complètent [ai/personalities.md](../ai/personalities.md), [ai/decision-making.md](../ai/decision-making.md) et [ai/memory-system.md](../ai/memory-system.md). Les ambitions initiales doivent être des **données de scénario** évaluées par l'IA, jamais des scripts qui imposent un comportement.

---

# XII. Intégration au projet et questions ouvertes

> **Note de méthode :** cette section est ajoutée par l'agent qui a intégré le dossier. Elle ne modifie aucune valeur fournie par le propriétaire. Les propositions y sont explicitement étiquetées **[PROPOSITION]**.

## 1. Correspondance avec les décisions existantes

| Élément du dossier | Décision ou document concerné | État |
|---|---|---|
| Sept puissances jouables | D-005, PROJECT.md § 3.2 | Cohérent. |
| Caractéristiques nationales évolutives | PROJECT.md § 3.3, D-004 | Cohérent ; les règles d'évolution restent à définir. |
| Douze caractéristiques notées de 1 à 10 | **D-027** (nouvelle) | Intégré dans PROJECT.md. |
| Colonies simplifiées, Allemagne sans colonie exploitable | **D-028** (nouvelle) | Intégré dans PROJECT.md ; simplification assumée. |
| Ambitions initiales non obligatoires | D-011 (IA autonomes), **D-029** (nouvelle) | Cohérent ; les ambitions sont des données, pas des scripts. |
| Relations diplomatiques qualitatives | D-010 (amitié / neutralité / hostilité) | **À DÉFINIR** : valeurs initiales non chiffrées. |
| Accords secrets ottomano-allemands | PROJECT.md § 6.3, D-009 | Cohérent ; le traité de départ doit être modélisé comme secret. |
| Unités, effectifs, fortifications | PROJECT.md § 8, docs/military/ | Les profils donnent une puissance initiale, pas des ordres de bataille. |
| Technologies 1914-1945 | PROJECT.md § 10, docs/technology/ | Les notes de Technologie sont un niveau initial, pas un arbre de recherche. |
| Mémoire et personnalités des IA | PROJECT.md § 7, docs/ai/ | Les ambitions et l'évaluation de soi alimentent la décision. |

## 2. Articulation des douze caractéristiques avec les autres systèmes

**Q-028 — Comment les douze caractéristiques nationales s'articulent-elles avec les attributs de province, la production et le budget ?**

Points à trancher :

- **Industrie** : la note nationale est-elle un multiplicateur de la production des provinces, une capacité autonome, ou les deux ? Éviter de compter deux fois la même capacité.
- **Économie** : la note alimente-t-elle directement le budget, ou seulement la capacité d'emprunt et de commerce ?
- **Ressources naturelles** : la note nationale complète-t-elle les trois ressources par province (D-018) ou représente-t-elle les ressources importées/stratégiques ?
- **Infrastructures** : la note nationale et les infrastructures de province doivent-elles être additionnées, multipliées, ou la note nationale doit-elle être dérivée des provinces ?
- **Armée terrestre / Marine** : les notes représentent-elles une puissance initiale abstraite ou se traduisent-elles en unités et équipements concrets sur la carte ?
- ** population** : la note (1-10) et la population en millions sont deux informations distinctes ; laquelle fait foi pour la mobilisation ?
- **Unité nationale** : une seule jauge, mais des effets régionaux possibles ? Le dossier exclut les nationalités individuelles, pas nécessairement les foyers de crise régionaux.

**[PROPOSITION]** Conserver les douze notes comme **indicateurs macro de départ et de comparaison**, et dériver les capacités concrètes (unités, production, budget) de l'état du monde (provinces, usines, populations). Les notes servent alors de modificateurs et de repères, pas de doublons des attributs de province.

**Q-029 — Comment les colonies sont-elles représentées ?**

**[PROPOSITION]** Représenter les empires coloniaux comme des **régions impériales hors carte européenne**, rattachées à une métropole, avec des modificateurs de ressources, revenus, recrutement et obligations de défense. L'Allemagne n'en possède pas (D-028). La Russie utilise ses territoires contigus, sans traitement colonial maritime.

**Q-030 — Quelles sont les valeurs initiales des relations diplomatiques ?**

**[PROPOSITION]** Traduire la situation décrite en relations D-010 et en traités, sans automatisme :

| Nation | Amitié | Neutralité | Hostilité | Traités de départ |
|---|---|---|---|---|
| Allemagne | Autriche-Hongrie, Italie (Triple Alliance) | Empire ottoman | France, Russie, Royaume-Uni | Alliance avec l'Autriche-Hongrie ; Triple Alliance (Italie libre) |
| Royaume-Uni | France, Russie | Italie, Empire ottoman | Allemagne | Entente cordiale (non contraignante) ; convention avec la Russie |
| France | Russie, Royaume-Uni | Italie | Allemagne, Autriche-Hongrie | Alliance militaire franco-russe ; Entente cordiale |
| Russie | France, Royaume-Uni | Empire ottoman | Allemagne, Autriche-Hongrie | Alliance militaire franco-russe ; convention anglo-russe |
| Autriche-Hongrie | Allemagne, Italie (Triple Alliance) | — | Russie, Serbie | Alliance allemande ; Triple Alliance |
| Italie | — | Allemagne, France, Royaume-Uni | Autriche-Hongrie (rivalité) | Triple Alliance (participation non automatique) ; neutralité initiale |
| Empire ottoman | Allemagne (accord secret) | Royaume-Uni, France | Russie | Accord secret germano-ottoman du 2 août 1914 ; neutralité officielle |

Ces valeurs sont une **proposition de conversion**, pas une décision du propriétaire. Elles devront être validées et chiffrées.

**Q-027 — Quelle est la date exacte de début en 1914 ?**

Le dossier mentionne un accord secret du 2 août 1914 et une neutralité ottomane initiale. La date de départ (mois, jour) n'est pas fixée. Elle conditionne l'état initial des traités, des mobilisations et des crises.

**Q-031 — Comment les caractéristiques évoluent-elles ?**

Le dossier indique qu'elles évoluent par investissements, réformes, technologies, conquêtes et changements de régime. Il ne donne ni coûts, ni seuils, ni durées, ni plafonds. Ces règles doivent être définies avant toute implémentation et ne pas permettre une croissance arbitraire d'une petite puissance (PROJECT.md § 3.2).

## 3. Points de vigilance

- **Ne pas doubler les systèmes.** Une note d'Industrie à 10 ne doit pas produire à elle seule une économie de guerre si les usines et les ressources de province ne suivent pas.
- **Ne pas transformer les notes en destins.** Une note initiale élevée ne garantit pas la victoire ; une note faible n'interdit pas une stratégie habile.
- **Ne pas automatiser les alliances historiques.** L'Italie, l'Empire ottoman et le Royaume-Uni conservent leur liberté de décision (D-011, dossier § VIII.8).
- **Distinguer public et secret.** L'accord germano-ottoman est secret ; la Triple Alliance est officielle mais non automatique.
- **Cohérence des noms.** Le dossier alterne « Empire britannique », « Royaume-Uni » et « France », « République française ». **[PROPOSITION]** Utiliser le nom officiel dans les données et un nom court dans l'interface, sans mélanger les deux dans un même écran.
- **Chiffres démographiques approximatifs.** Les populations sont des ordres de grandeur de 1914. Elles devront être vérifiées si elles alimentent un calcul de mobilisation.
- **Pas de ligne Maginot.** Le dossier le rappelle explicitement ; les fortifications de l'Est existent, la ligne Maginot non.

## 4. Suivi

Les tâches dérivées de cette intégration sont consignées dans [PROGRESS.md](../../PROGRESS.md) section D :

- **T-032** — Modéliser les profils nationaux dans le modèle de données.
- **T-033** — Traduire la situation diplomatique initiale en relations et traités.
- **T-034** — Définir les règles d'évolution chiffrée des douze caractéristiques.

---

## Historique de ce document

| Date | Agent | Modification |
|---|---|---|
| 2026-10-31 | OpenCode | Création : intégration du dossier des puissances jouables fourni par le propriétaire. Ajout de l'en-tête, de la mise en forme, des renvois et de l'annexe d'intégration (§ XII). Aucune valeur nationale modifiée. |
