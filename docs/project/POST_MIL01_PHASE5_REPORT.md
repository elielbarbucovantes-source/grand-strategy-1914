# POST_MIL01_PHASE5_REPORT — Phase V : démographie, économie, industrie et logistique

> **Date :** 2026-11-19
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État initial :** `c1251a6`, dépôt propre et synchronisé (`0/0`). Phases I–IV préservées.
> **Collaboration :** CHORUS a réussi **2 tâches sur 3** (audit économique et recherche historique) ;
> la conception de modèle a expiré. Les livrables réussis sont versionnés dans `docs/project/phase5/`.
> **Phase VI non commencée.**

---

## 1. Audit initial

Le modèle C (production régionale, stocks nationaux, accessibilité logistique) et les catégories
industrielles françaises validées existaient, mais `delivered` restait `null`, les populations,
ressources et capacités étaient absentes, l'allocation était enregistrée sans effet et aucun
commerce ni ravitaillement militaire n'était calculé. Aucun système opérationnel n'a été reconstruit :
`EconomySystem` a été étendu comme orchestrateur et les anciennes fonctions conservées pour
compatibilité.

## 2. Modèle démographique

`DemographySystem` : population par région, taux de natalité/mortalité ajustés par la disponibilité
alimentaire, croissance mensuelle plafonnée, main-d'œuvre = 52 % de la population avec répartition
en 6 secteurs (agriculture, industrie, mines, transports, services, administration). La mobilisation
réduit la main-d'œuvre via un facteur documenté. Les transferts sectoriels ont un coût : plus
d'industrie signifie moins d'agriculture disponible.

## 3. Données historiques

`data/game/economic_baseline_sources.json` donne les populations des 22 États (niveau B pour les
recensements, C/D pour les États incertains comme l'Empire ottoman, la Serbie, le Monténégro et
l'Albanie) et des indications de ressources classées C/D. `tools/economy/build_economic_baseline.py`
répartit ces valeurs sur les 90 régions selon la surface, les villes, les axes ferroviaires et les
gisements identifiés (Ruhr, Lorraine, Pays de Galles, Donbass, Bakou, Ploiești, Silésie). La
répartition régionale est explicitement une **estimation de modèle** ; aucun chiffre de recensement
régional n'a été fabriqué.

## 4. Ressources

`ResourceSystem` : dépôts, taux d'exploitation, investissement, main-d'œuvre minière et
infrastructure limitent l'extraction mensuelle (plafond 2 % du dépôt). L'extraction retranche le
dépôt et crédite le stock national : ressource **présente ≠ exploitée ≠ disponible**.

## 5. Industrie et production

`IndustrySystem` : capacité régionale issue de la baseline, budget = min(capacité, main-d'œuvre/120),
consommation réelle de charbon/fer/grain/bois selon la catégorie, production réduite
proportionnellement si un intrant manque, entretien de 5 %. Aucune production gratuite.

## 6. Stocks, commerce et logistique

`MarketSystem` : les ordres de commerce sont validés par le réseau de Phase IV (itinéraire, accès,
transit). Le stock exportateur est débité à l'expédition, le stock importateur crédité seulement
après le délai de transport. `dependencies()` mesure la dépendance aux importations. Les priorités
logistiques existentvia le ravitaillement (armées en premier) et les stocks ne peuvent pas être négatifs.

## 7. Ravitaillement militaire et remplacement

`MilitaryEconomySystem.monthly_supply` calcule un `supply_ratio` par formation à partir des besoins
en grain/charbon et des stocks nationaux, avec conséquence **modérée** sur le moral (`-2` si tendu,
`-5` si pénurie) — jamais de modification des règles de combat MIL-01.
`monthly_replacement` prélève progressivement (4 %/mois) sur les réserves historiques, consomme
fer/charbon/biens militaires et main-d'œuvre, sans toucher au registre des pertes ni créer de
doublon.

## 8. IA économique

`EconomicAI` : 4 personnalités (industrielle, stabilité, commerciale, autarkique), réaction aux
pénuries de grain, priorisation des productions, recherche d'un fournisseur non belligérant pour
les ressources déficientes. Les ordres sont bornés (1 changement d'allocation, 2 ordres de commerce
par mois), déterministes et validés avant résolution.

## 9. Interface

Vue Économie enrichie : démographie, main-d'œuvre, capacité industrielle, stocks, dépendances,
remplacement et boutons de priorités par catégorie validée. Cinq couches cartographiques
ressources, industrie, population, agriculture et stocks s'ajoutent aux couches de la Phase IV.

## 10. Tests exécutés

| Commande | Résultat |
|---|---|
| `bash tests/run.sh` | **190 tests réussis, 0 échec** ; UI et UI bataille validées ; exit 0 |
| `python3 tools/economy/build_economic_baseline.py --check` | PASS |
| `python3 tools/map/build_transport_network.py --check` | PASS |
| `python3 tools/export/build_game_data.py --check` | PASS |
| `python3 tools/export/build_scenario.py --check` | PASS |
| `python3 tools/history/render_fiches.py --check` | PASS |
| `bash tools/map/validate_all.sh` | VALIDÉ (94 + 96 + 34 contrôles, 0 échec) |

13 nouveaux tests couvrent la baseline, la démographie, la mobilisation, l'extraction, l'industrie
avec et sans intrants, le commerce sans duplication, le ravitaillement, le remplacement, l'IA et
les sauvegardes. Les anciens tests de migration ont été mis à jour pour les champs v6/v7.

## 11. Simulations

`tools/simulate_phase5.gd` exécute les **12 situations imposées** avec les graines **1914, 7, 2026** :
**12/12 réussies à chaque graine, 0 échec**. Observations : population évolue en paix, main-d'œuvre
non gonflée par la mobilisation, production militaire nulle sans charbon/fer, crise alimentaire
dégradant la démographie, remplacement ~4 %/mois (4 518 hommes en 4 mois sur 30 000), ravitaillement
dégradé en cas de pénurie, aucun stock négatif après 18 tours de guerre.

## 12. Performances

Le cycle économique tourne une fois par mois, sur 90 régions et 22 nations. Les opérations
dépendantes de l'ordre d'itération ont été triées et les flottants arrondis (supply_ratio) pour
garantir un rejeu identique après sauvegarde. La suite complète et les 12 simulations restent de
l'ordre de la dizaine de secondes.

## 13. Anomalies corrigées

- `mini()` (entière) utilisée sur des flux flottants → production nulle ; remplacée par `minf()`.
- Catégories industrielles françaises validées écrasées par le nouveau fichier de règles → modèle
  déplacé sous `rules.economy_model`, catégories d'origine restaurées.
- `last_extracted` dépendant de l'ordre des clés JSON → remplacé par un dictionnaire par ressource.
- `supply_ratio` divergent d'un ULP après rechargement → calcul trié et arrondi.
- Constante `FORMAT_VERSION` restée à 6 → passée à 7, migrations v3–v6 ajustées.

## 14. Limitations restantes

- Les chiffres économiques sont des **estimations de modèle** (niveaux B/C/D), pas des statistiques
  vérifiées région par région.
- Aucun marché à prix dynamique : les échanges sont des transferts planifiés avec délai.
- Pas de sous-types d'unités ni de production navale/aéronautique dédiée (catégories enregistrées
  mais effets agrégés).
- Les priorités logistiques sont implicites (armées servies en premier) et non éditables finement.
- Aucune migration économique depuis les formats v1 à v5 : ces sauvegardes sont initialisées à vide
  puis réamorcées depuis la baseline.
- 2 livrables CHORUS sur 3 ; la conception de modèle a expiré et n'a pas été utilisée.

## 15. Paramètres : proposés vs validés

| Nature | Statut |
|---|---|
| Modèle C (production régionale, stocks nationaux, accessibilité logistique) | **VALIDÉ** (directeur) |
| Catégories industrielles françaises (5 catégories) | **VALIDÉES** (directeur) |
| Populations, ressources, capacités et répartition régionale | Estimations **PROPOSÉES** (niveaux B/C/D) |
| Taux démographiques, rendements, besoins militaires, ratios de remplacement, personnalités IA | Paramètres **PROPOSÉS** et configurables |

## 16. Commits publiés

- `8066a4019d9f1dfbed9fb906f98ddd3200c1bd03` — `feat(economie): demographie, ressources, industrie, commerce et soutien militaire`
- `1e837159c80ceb60068c29edefa129be7aae066b` — `test(economie): suite Phase V et 12 simulations sur 3 graines`
- rapport final — `docs(phase5): consigner le rapport de validation et les limitations`

## 17. État final du dépôt

Branche `dev/mil01-finalisation`, publication uniquement sur `origin/dev/mil01-finalisation`.
Aucun merge vers `main`, aucune suppression de branche, aucun push forcé, aucun secret versionné.
Arbre propre, `HEAD` local = `HEAD` distant à l'issue de la publication.

| Niveau | État |
|---|---|
| Conçu | OUI — modèle à flux bornés et déterministe |
| Documenté | OUI — sources, niveaux de fiabilité, limitations |
| Implémenté | OUI — 6 sous-systèmes, état v7, migration, UI |
| Testé | OUI — 190 tests + exports + cartographie |
| Fonctionnel | OUI — démontré par 12 simulations × 3 graines |

**La Phase VI n'a pas été commencée.**
