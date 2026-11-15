# Prototype jouable — état (15/11/2026)

- **Branche :** `dev/prototype-foundation`.
- **Moteur :** Godot 4.7.2 stable, GDScript typé (ADR-0007, décision du directeur).
- **Statut global :** **prototype technique jouable.** La boucle de jeu est réelle : carte interactive, ordres, résolution mensuelle simultanée, IA autonome, sauvegarde. En revanche, les valeurs historiques (population, économie, effectifs) et plusieurs règles (combat, effets des traités, recherche) sont **ouvertes**. Le prototype les affiche comme telles et **n'invente rien**.

## 1. Lancer

```bash
GODOT=~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64   # binaire officiel, SHA-512 vérifié
$GODOT --path .                       # lance le jeu (scène src/ui/main.tscn)
bash tests/run.sh                     # 16 tests de simulation et test de fumée de l'interface, sans interface graphique
$GODOT --headless --path . --script tests/demo_campaign.gd   # démonstration reproductible (8 mois)
```

**Jouer un tour :**
1. Au menu, choisir une des 7 puissances et le **mois de départ** (R-13 ouvert), puis « Nouvelle partie ».
2. Naviguer sur la carte : molette pour le zoom, clic droit maintenu pour se déplacer, flèches du clavier.
3. Cliquer une région pour l'onglet **Pays** : souveraineté, contrôle, voisins mis en évidence, villes, zones maritimes.
4. Dans l'onglet **Armée**, sélectionner une formation, puis cliquer une région voisine : l'ordre est préparé (flèche rouge), ou refusé avec son motif.
5. Onglet **Diplomatie** : déclarer la guerre, demander le passage, proposer une alliance, un accord commercial ou la paix, répondre aux propositions, rompre un traité, envoyer un message public.
6. Onglet **Industrie** : priorités entre les 5 catégories.
7. « **Fin du mois** » : les 21 IA décident sur leur vue filtrée, puis tous les ordres sont résolus simultanément. Le résultat apparaît dans les onglets Événements et Ordres.
8. « **Sauvegarder** » écrit dans `user://saves/` ; « **Charger** » restaure la dernière sauvegarde, avec contrôle d'intégrité.

## 2. Architecture

```text
tools/export/build_game_data.py  → data/game/world_map.json   (NP-0 : géométrie simplifiée sans casser les frontières communes, graphe, villes, zones)
tools/export/build_scenario.py   → data/scenarios/campaign_1914.json (États, territoires, capitales, traités de départ ; inconnus = null)
data/rules/game_rules.json         règles avec statut (VALIDÉ, PROPOSÉ, OUVERT)
src/map/        WorldMap (graphe, chemins)
src/core/       GameCalendar
src/simulation/ GameState (sérialisable), Orders (ordres JSON), TurnResolver (résolution simultanée)
src/domains/    military (déplacements, souveraineté, occupation ; BattleSystem T-029), diplomacy, economy (modèle C),
                logistics (continuité territoriale), intelligence (vue filtrée), technology (structure)
src/ai/         NationAgent (niveau 1, sur vue filtrée)
src/adapters/   SaveRepository (enveloppe versionnée et empreinte)
src/app/        GameSession (façade : seul point d'accès de l'interface)
src/ui/         main.gd, map_view.gd, game_ui.gd (aucune règle métier)
tests/          run_tests.gd et unit/*.gd (sans interface), ui_smoke.gd, demo_campaign.gd, screenshot.gd
```

- **Simulation pure** (`RefCounted`), sans dépendance à l'interface.
- **Déterministe** : test sur 6 mois, même empreinte.
- **Ordres JSON** journalisés : rejeu possible et préparation multijoueur.

## 3. État des fonctionnalités

Légende :
- **V** : décision VALIDÉE ;
- **I** : IMPLÉMENTÉE ;
- **T** : TESTÉE ;
- **D** : DOCUMENTÉE ;
- **P** : règle PROPOSÉE (provisoire, configurable) ;
- **O** : OUVERTE ;
- **B** : BLOQUÉE ;
- **A** : ABSENTE.

| Système | Statut | Ce qui fonctionne réellement | Ce qui manque ou reste ouvert |
|---|---|---|---|
| Carte (90 régions, frontières, villes, capitales, voisinages, détroits, zones) | V I T D | Chargement, rendu, zoom et déplacement, sélection, voisins mis en évidence, étoiles des capitales, noms des capitales toujours visibles | Zones maritimes occidentales (U3) ; relief non dessiné |
| Pays (identité, capitale, territoire) | V I T | 22 États, territoires et capitales de l'atlas | — |
| Population, 12 statistiques, ressources, capacités industrielles | O | Structures présentes, valeurs `null` affichées « inconnues » | Données sourcées (NAT-01 à 03, ECO-01/02) |
| Calendrier mensuel, ordres secrets simultanés | V I T | Préparation, enregistrement, résolution simultanée, historique, mois de départ paramétrable | Ordre exact des phases (TURN-01 : proposition technique) |
| Déplacements | V(principe) P(portée) I T | Graphe terrestre et détroits ; entrée étrangère seulement en guerre ou avec passage ; portée de 1 région par mois (P) | Durée selon terrain et logistique (formule ouverte) ; mouvement naval (U3) |
| Souveraineté, contrôle, occupation | V I T | Occupation hachurée, souveraineté conservée, libération | Résistance locale, annexion par traité (ouvertes) |
| Batailles (T-029) | V(partiel) I T | Création à la rencontre, camps, file (critiques puis chronologique), commandement conjoint (soldats puis prestige, sinon indéterminé), règle de pause, toutes closes avant le tour | **Résolution du combat OUVERTE** : résolveur neutre provisoire (sans issue). Durée, criticité, interface tactique : absentes |
| Diplomatie | V(passage) I T | Traités (alliance, entente, passage, commerce, garantie, coalition, paix), propositions et réponses, rupture, guerre, paix, canaux public, privé, groupe, mémoire | Effets des alliances, garanties et commerce (DIP-02) ; seule l'autorisation de passage a un effet |
| IA | P I T D | Niveau 1 déterministe sur vue filtrée : réponses selon la mémoire, défense, reprise, occupation, proposition de paix, repli | Aucune déclaration de guerre spontanée, coalition ou économie (critères du directeur) ; pas de tromperie |
| Renseignement | P I T | Vue nationale : régions possédées et voisines, effectifs étrangers masqués | Interception, décryptage, espionnage (INT ouverts) |
| Économie (modèle C) | V I(structure) T | Production régionale et bilan national (produit, accessible, livré), valeurs inconnues propagées, formule proposée configurable | Catégories (R-03), données, budget (ECO-05), marché (ECO-04) |
| Industrie (5 catégories) | V I T | Priorités gouvernementales validées et appliquées | Capacités et effets (données) |
| Logistique | V(principe) I T | Continuité territoriale vers la capitale, alliés compris ; formations coupées signalées | Capacités de transport ; réseau ferré fragmenté (17 composantes) ; pénalités ouvertes |
| Recherche | O | Structure de projet | Arbre technologique |
| Victoire | V(seuil) I(affichage) | Part du territoire contrôlé affichée | Modalités (MAP-OPEN-16), voies socio-économique et collective (R-04) |
| Sauvegarde | I T | Enveloppe versionnée, empreinte SHA-256, détection d'une sauvegarde corrompue, tronquée ou incompatible | Migrations entre versions |
| Multijoueur | A (préparé) | Ordres JSON, déterminisme, règle de pause | Réseau |
| Interface tactique | A | — | Règles de combat |

## 4. Tests

- `bash tests/run.sh` :
  - **16 tests de simulation** : carte, scénario, calendrier, sauvegarde et intégrité, déterminisme, souveraineté et passage, occupation, rencontre simultanée et bataille, commandement conjoint et pause, priorité, mémoire diplomatique, non-omniscience de l'IA, réaction de l'IA, logistique, économie ;
  - **test de fumée de l'interface** : scène réelle, clic, ordre, onglets, fin de mois, sauvegarde, chargement.
- La CI `.github/workflows/game-tests.yml` installe Godot 4.7.2 (vérifié par SHA-512), contrôle la reproductibilité des exports et lance les tests.
- Captures de rendu : `tests/screenshot.gd`, qui nécessite un affichage.

## 5. Anomalies découvertes pendant le développement

- `region_040` et `region_071` sont valides en WGS 84 mais **invalides après projection en EPSG:3035** (auto-intersection de surface nulle au tripoint Khotin/Herța). Elles sont corrigées par `make_valid` dans l'export, et la source n'est pas modifiée. Les validateurs cartographiques ne le détectent pas, car ils travaillent avec tolérance.
- La couverture des 90 régions n'est pas « exacte » au sens de GEOS (sommets non appariés sur les frontières communes de 41 régions, sous la tolérance). L'export applique un `coverage_clean` à 50 m, avec un écart d'aire de 0,12 km² au plus.

## 6. Décisions du directeur qui débloqueraient le plus

1. **Règles de combat** (T-029, points ouverts ; MIL-05/06) : sans elles, une offensive contre une région défendue est sans issue.
2. **Données de départ** (R-13 mois de départ, R-05 statistiques, R-03 ressources) : prérequis à toute collecte sourcée.
3. **Effets des traités** (DIP-02), au minimum ceux de l'alliance : l'entrée en guerre des alliés n'est pas automatique aujourd'hui.
4. **Critères de déclaration de guerre de l'IA** : sans eux, les IA ne prennent pas d'initiative belliqueuse.
5. **Mers occidentales** (U3) et intégration du mouvement naval.

## 7. Feuille de route vers une version alpha

| Étape | Contenu | Dépendance |
|---|---|---|
| A1 | Règles de combat stratégique et résolution automatique (remplace le résolveur neutre) ; durée et criticité des batailles | Décision T-029 (points ouverts), MIL-05/06 |
| A2 | Données de départ sourcées : population, 12 statistiques, effectifs (schéma de provenance obligatoire) | R-13, R-05, NAT-01 à 03, MIL-01 |
| A3 | Économie chiffrée : catégories de ressources, potentiels régionaux, budget, marché | R-03, ECO-01 à 05 |
| A4 | Effets des traités (alliances, garanties), critères de guerre de l'IA, IA de niveau 2 (objectifs, coalitions, menaces anticipées) | DIP-02, critères du directeur |
| A5 | Réseau naval occidental, mouvement naval et débarquements ; logistique avec capacités de transport | U3 ; données ferroviaires sourcées |
| A6 | Interface tactique (bataille commandée en temps réel, une à la fois, pause selon T-029) | A1 |
| A7 | Recherche (arbre 1914–1945) et renseignement (interception, décryptage) | Catalogues à valider |
| A8 | Export binaire Linux et Windows, réglages, sauvegardes multiples, localisation | Technique (autonome) |
