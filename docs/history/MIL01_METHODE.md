# MIL-01 — Méthode : normalisation, répartition territoriale, estimations

- **Base de données :** `data/history/military_forces_1914.json`.
- **Bibliographie :** [`BIBLIOGRAPHIE.md`](BIBLIOGRAPHIE.md).
- **Fiches par puissance :** [`fiches/`](fiches/).

Ce document explique comment les chiffres sont choisis, comparés et placés sur la carte. Il distingue ce qui est **sourcé** de ce qui est **estimé**.

## 1. Modèle (validé par le directeur, mission du 15/11/2026)

| N° | Catégorie | Nature | Où dans le jeu |
|---|---|---|---|
| A | **Effectifs actifs au démarrage** | Donnée historique | `forces.active_start` (constante) |
| B | **Réserves mobilisables** | Donnée historique | `forces.reserve_pool_initial` |
| 3 | Effectifs mobilisés progressivement (en cours) | État de jeu | `forces.mobilizing` (cohortes) |
| 4 | Effectifs effectivement incorporés | État de jeu (cumul) | `forces.incorporated` |
| 5 | Effectifs réellement présents dans les unités | État de jeu (après pertes) | somme des unités + services |

Ces catégories ne sont jamais additionnées entre elles.

Invariant vérifié par les tests : réserves restantes + en cours + incorporés = réservoir initial sur la carte.

## 2. Normalisation : une définition par catégorie

Les historiens et les états-majors comptent des choses différentes. Exemples :
- effectif budgétaire ou effectif présent ;
- hommes du rang seulement (la *Friedenspräsenzstärke* allemande exclut officiers et sous-officiers) ;
- armée métropolitaine avec ou sans l'Algérie ;
- armée commune austro-hongroise sans les deux Landwehr ;
- réservistes instruits ou totaux de mobilisation incluant l'armée active.

Comparer ces chiffres tels quels serait une erreur. La règle retenue :

1. **Actifs** : « officiers et hommes sous les drapeaux » de l'armée de terre régulière, en temps de paix, juillet 1914 ou budget 1914.
   - Source commune : US War Department 1916, tableau p. 9, qui applique la même définition à six des sept puissances.
   - Exclus : réserves, milices non présentes, troupes coloniales et indigènes hors d'Europe.
2. **Réserves** : « réservistes entièrement instruits disponibles pour le passage au pied de guerre » (même tableau p. 9, estimation de 1911).
   - **Plafond de cohérence (phase 1, 15/11/2026).** Actif + réserves ne peut dépasser le total des instruits que la même source donne pour la puissance (rubrique « Total war strength » de chaque fiche nationale). Ce total est lu comme incluant l'armée active : c'est une lecture **probable** (la rubrique désigne l'effectif de guerre), que le texte ne dit pas explicitement.
     - Allemagne : 4 610 000 (p. 28) − 806 016 = **3 803 984** (au lieu de 4 000 000).
     - Italie : 1 300 000 (p. 66) − 305 033 = **994 967** (au lieu de 1 250 000).
     - France (3,8 M, p. 20) et Russie (6,0 M, p. 45) : plafond sans effet.
     - Autriche-Hongrie : non appliqué, car le total (« fully trained men subject to call », p. 38) désigne des hommes à rappeler, donc hors actifs.
     - Le contrôle est enregistré dans `reserves.source_total_check` et vérifié par `test_database_totals_coherent_with_sources`.
   - Royaume-Uni : statistique officielle de 1922 (Army Reserve + Special Reserve).
   - Empire ottoman : estimation de l'état-major ottoman rapportée par Erickson.
3. **Exceptions motivées** : une source nationale remplace la source commune seulement si sa définition est identique et sa date plus précise.
   - Royaume-Uni : War Office 1922, au 1er août 1914.
   - Empire ottoman : seule source disponible.
4. **Divergences conservées** : chaque autre chiffre trouvé est gardé dans `divergences`, avec sa définition. Exemples :
   - Bundesarchiv : 734 000 en juillet 1914 ;
   - armée commune austro-hongroise seule : 370 725.
   - Ces chiffres servent de contrôle de vraisemblance, jamais de valeur de jeu.

**Biais connu.** Les réserves de la source commune datent de 1911. La source le dit elle-même : les augmentations ultérieures n'ont pas été publiées. Ce sont probablement des minimums.

## 2 bis. Échelons de mobilisation (T-051)

T-051 (VALIDÉ) demande une mobilisation par échelons **historiquement documentés**. Le bloc `mobilization_echelons` de chaque puissance contient trois échelons : premier échelon (plan de 1914), échelons suivants, réserves résiduelles.

**Règles :**
- un échelon sans donnée fiable vaut `null`, avec le statut « introuvable » et son motif ;
- aucun total n'est réparti arbitrairement entre échelons ;
- un échelon « dérivé » est la différence de deux totaux sourcés, avec son calcul et sa précision ;
- la somme des échelons documentés ne dépasse jamais le réservoir (testé).

| Puissance | 1er échelon | Échelons suivants | Résiduel |
|---|---|---|---|
| Allemagne | 2 993 984 (dérivé : 3,8 M mobilisés en août 1914, Bundesarchiv, moins l'actif) | 810 000 (dérivé : 4 610 000 − 3 800 000 ; composition non documentée) | introuvable (non-instruits) |
| Autriche-Hongrie | 1 347 285 (dérivé : armée commune et Landwehrs au pied de guerre, US WD p. 38, moins l'actif) | 652 715 (dérivé : 2 000 000 − premier échelon) | introuvable |
| France, Russie, Royaume-Uni, Italie, Empire ottoman | introuvable | introuvable | introuvable |

Les sources qui permettraient de documenter les échelons manquants sont listées dans `BIBLIOGRAPHIE.md` (non consultées). Le moteur n'utilise pas encore ces échelons : c'est l'objet de la phase 2.

## 3. Répartition territoriale (ESTIMATION documentée)

Les sources consultées ne donnent **pas** l'effectif présent dans chaque région en juillet 1914. Il fallait donc une règle explicite. La règle de population est exclue, conformément à la mission.

**Méthode : districts de corps d'armée du temps de paix.**

1. Chaque armée continentale était organisée en corps d'armée territoriaux. Chaque corps était stationné et recruté dans son district.
   - Allemagne : 25 corps.
   - France : 21 corps territoriaux et le corps colonial.
   - Autriche-Hongrie : 16 corps.
   - Italie : 12 corps.
   - Russie : 37 corps, dont 27 en Russie d'Europe.
   - Les nombres de corps sont **sourcés** (US War Dept 1916 ; Handbook of the German Army 1912/1914).
2. Royaume-Uni : les 8 commandements territoriaux (US War Dept 1916, p. 60).
3. Empire ottoman : seuls les corps I à III de la Ire armée, en Thrace et à Constantinople.
4. Chaque district est placé dans la région du jeu qui contient la ville de son siège.
   - Calcul géométrique : point dans un polygone, en EPSG:3035, fait par `tools/export/build_scenario.py` (`locate_districts`).
5. L'effectif actif sur la carte est réparti **à parts égales entre districts**. C'est l'**approximation principale** : les corps de 1914 avaient des effectifs voisins, mais non identiques.
6. Le réservoir de réserves est réparti avec la même clé. Les réservistes rejoignent les dépôts de leur district.

**Statut des sièges :**
- Les sièges confirmés par une source consultée portent `hq_verification = "vérifié"`. C'est le cas :
  - de la Garde à Berlin, des XXe (Allenstein) et XXIe (Sarrebruck) corps, et d'Aldershot ;
  - des XVe et XVIe corps, au niveau de la province seulement (« vérifié (province seulement) ») : la source dit « stationed in Alsace-Lorraine », sans les villes ;
  - **des 27 corps russes d'Europe** (phase 1), d'après l'état officiel abrégé des troupes au 1er mars 1914 (`RU_RASPISANIE_1914`). Deux sièges ont été corrigés : **VIe corps à Białystok** (région 057, et non Łomża, région 056) et **VIIe corps à Simferopol** (région 063, et non Iekaterinoslav).
- Les IIe et IIIe corps ottomans restent rattachés à Constantinople, avec le statut « à vérifier — indice contraire » : des indices secondaires les placent en Thrace (régions 088 et 089), mais aucune source primaire n'a été consultée.
- Les autres sièges relèvent de la connaissance encyclopédique courante et sont marqués **« à vérifier »**. Ils n'influent que sur la répartition estimée.

## 4. Forces hors de la carte

La carte du jeu ne couvre que l'Europe. Les forces stationnées ailleurs sont comptées, mais pas placées : `active_off_map` et `reserves_off_map`.

| Puissance | Hors carte | Statut |
|---|---|---|
| Royaume-Uni | 121 123 : Inde 75 000, colonies et Égypte 43 486, divers 2 637 | **sourcé** (War Office 1922, p. 157) |
| France | 82 368 en Algérie et en Tunisie | **dérivé d'une source** (US War Dept 1916, p. 20) |
| Russie | 10/37 de l'actif (Caucase, Turkestan, Sibérie) | **estimation** (part de corps) |
| Empire ottoman | 10/13 de l'actif (corps d'Anatolie et des provinces arabes) | **estimation, à vérifier** |
| Allemagne, Autriche-Hongrie, Italie | 0 | sourcé ou constat géographique. **Italie : forces métropolitaines détachées en Libye INCONNUES.** |

## 5. Ventilation par arme

La part de l'infanterie, de la cavalerie, de l'artillerie et des services provient du tableau p. 9 (US War Dept 1916).
- Elle est appliquée en proportion aux effectifs retenus.
- C'est une **estimation** pour la France (troupes coloniales en France), le Royaume-Uni (proportions américaines appliquées au chiffre du War Office) et l'Autriche-Hongrie (proportions de l'armée commune appliquées aux Landwehr).
- **Empire ottoman : ventilation inconnue.** L'effectif est représenté en infanterie générique, avec un signalement sur chaque unité.

Les « services » (troupes techniques, train, santé, effectifs non ventilés) sont présents mais ne combattent pas dans la bataille tactique.

## 6. Granularité des unités (paramètre technique, non historique)

- Les unités du jeu comptent environ 10 000 hommes au départ (`forces_rules.json`).
- Ce choix vient de la performance mesurée de la simulation tactique : environ 2,5 s pour 40 unités, 20 s pour 170.
- Ce n'est **pas** un échelon historique.
- Un district de corps devient, dans le jeu, une « division » (groupement de jeu) qui porte le nom et le siège du corps, avec ses unités d'infanterie, de cavalerie et d'artillerie.

## 7. Ce qui reste inconnu

- Effectifs par district ou par garnison : aucune source consultée ne les donne pour les sept puissances.
- Ventilation par arme de l'armée ottomane.
- Effectifs métropolitains italiens détachés en Libye en 1914.
- Total des réservistes après 1911, non publié selon la source commune.
- Sièges marqués « à vérifier ».

Pour le reste, les sources primaires recommandées sont :
- *Der Weltkrieg 1914–1918*, *Kriegsrüstung und Kriegswirtschaft*, Anlagen (Reichsarchiv) ;
- *Les Armées françaises dans la Grande Guerre*, tome I (Service historique) ;
- *Österreich-Ungarns letzter Krieg* ;
- Erickson, *Ordered to Die* (2001) ;
- *Rospis' voisk* de 1914 (état-major russe).

## 8. Mois de départ (T-057, VALIDÉ)

- La campagne historique commence en **janvier 1914** (T-057, qui tranche R-13). Le bac à sable fictif garde un mois librement configurable.
- Les effectifs représentent l'armée **du temps de paix**. Les sources sont datées de juillet 1914 (US WD), du 1er août 1914 (War Office) ou du 1er mars 1914 (sièges russes) : l'écart avec janvier 1914 est faible pour les effectifs du temps de paix, mais il n'est pas mesuré.
