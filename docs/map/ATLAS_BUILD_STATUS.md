# Atlas 90 régions — état de construction

**Statut au 2026-11-01 : inventaire et recherche de sources préparés; atlas géométrique non construit.** Cette mission autorise la définition cartographique, mais ne permet pas de simuler des limites. Les sources identifiées ne donnent pas un jeu cohérent et librement réutilisable des 90 régions au 1er janvier 1914. Les critères de livraison géométrique ne sont donc pas atteints.

## Répartition cible

Le fichier [`region_plan.csv`](../../data/world/map/tables/region_plan.csv) réserve 90 IDs consécutifs (`region_001`–`region_090`) d’après les répartitions du dossier de mission. Cela respecte la cible et le plafond de 100. Le Pays de Galles est une région distincte, conformément à la clarification du directeur. La table est un index éditorial, non une série de polygones. Les souverainetés inscrites expriment le cadre de 1914 et doivent être vérifiées en parallèle des géométries.

Décisions d’affectation explicites reprises du dossier : Ulster correspond aux neuf comtés de la province historique et n’introduit pas la partition irlandaise postérieure; Islande reste sous souveraineté danoise; Bruxelles est incluse dans la Flandre comme simplification de jeu; Alsace-Lorraine est allemande; Bosnie-Herzégovine reste austro-hongroise; territoires italiens excluent Trentin, Tyrol du Sud, Trieste et Istrie. L’île de Man n’a pas de région indépendante. Les détails de contours internes n’ont pas été inventés.

## Sources examinées

Le registre [`data/world/map/sources/README.md`](../../data/world/map/sources/README.md) donne pour chaque source le contenu, la date, la licence connue, les limites et l’usage envisagé. Résumé :

- Kavanagh/UCD : emprises nationales vers 1914, mais pas les 90 subdivisions et date approximative.
- REGIS : unités administratives à des dates repères variables, souvent 1910/1920, couverture inégale à l’Est; l’archive téléchargée a échoué au contrôle d’intégrité et n’a pas été importée.
- Gorkin/Motylev : carte de l’Empire russe au 1er janvier 1914, raster, droits de dérivation à examiner.
- RISTAT : districts russes de 1897, utile en contrôle seulement.
- Réseaux ferroviaires spécialisés : couverture par pays et/ou licence restrictive; non intégrés.

Les frontières modernes ne sont pas utilisées comme si elles étaient celles de 1914. Aucune géométrie de régions ni de zone maritime, aucune ville, infrastructure ou adjacence n’a été dérivée.

## État des livrables

| Livrable | État |
|---|---|
| Inventaire des 90 IDs, noms, zones et souverainetés prévues | Préparé; non géométrique |
| 90 polygones topologiques GeoJSON | Absent — blocage principal |
| Adjacences vérifiées | Absentes |
| Villes, relief, routes, rails, ports, fortifications | Absents |
| Zones maritimes et connectivité des détroits | Absentes |
| Sources et registre de provenance | Recherche documentée; sources non encore importées |
| Validateur | Contrôle automatisé de l’index prêt; contrôles de géométrie et chevauchements prévus pour le futur GeoJSON. Pas encore de validateurs d’adjacence, couverture, villes, infrastructures ou zones maritimes |

**Aucun nombre de zones maritimes, villes, connexions ou infrastructures n’est déclaré**, car aucune de ces entités n’a été construite. La carte n’est pas validée et n’est pas jouable.

## Suite de construction requise

1. Obtenir des données administratives sources complètes et vérifiables pour chaque territoire, avec licences compatibles et date pertinente; résoudre particulièrement l’Empire russe, les Balkans et l’Empire ottoman européen.
2. Établir une table de correspondance des unités historiques vers les 90 régions et régler explicitement les unités coupées ou fusionnées, sans dépasser 100.
3. Construire les polygones par regroupement ou découpe de frontières historiques communes, puis vérifier couverture, trous, chevauchements et souveraineté.
4. Importer par couches les sites et réseaux datés, avec contrôle de licence et d’appartenance régionale.
5. Définir et valider les zones maritimes; les 90 régions terrestres n’en incluent aucune.
6. Exécuter les validations et produire les métriques de livraison après présence de l’ensemble réel des données.

Cette liste ne remplace pas les livrables manquants; elle rend leur état explicite.
