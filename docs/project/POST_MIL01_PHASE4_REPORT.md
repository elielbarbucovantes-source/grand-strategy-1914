# POST_MIL01_PHASE4_REPORT — Phase IV : carte, infrastructures et réseaux de transport

> **Date :** 2026-11-19
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État initial :** `c9401cd`, dépôt propre et synchronisé (`ahead/behind 0/0`).
> **Travail collaboratif :** 3 agents CHORUS/OpenCode ont réussi leurs tâches (audit, recherche
> historique, conception de routeur) ; leurs livrables sont versionnés dans `docs/project/phase4/`.
> **Phase V non commencée.**

---

## 1. État initial du projet

Branche et synchronisation vérifiées, 5 derniers commits lus, rapports des phases précédents
consultés. Le système géographique existant a été audité : 90 régions, 184 arêtes terrestres,
10+3 détroits, 16 zones maritimes, 175 villes, 129 axes ferroviaires, 84 ports, 65 fortifications,
59 rivières, 20 massifs montagneux. `LogisticsSystem` ne calculait que la continuité territoriale
et exposait `delivered = null` avec le statut « OUVERT : capacités non définies ». `WorldMap`
ne connaissait que des booléens `a|b` pour le rail et un `shortest_path` non pondéré.

Diagnostic : **existant** = géométrie, topologie, axes et ports ; **partiel** = présence sans
capacité/état/propriétaire, continuité sans livraison ; **absent** = routes, graphes pondérés,
multimodal, capacités, interruptions, couches cartographiques et usage par l'IA.

## 2. Modèle géographique retenu

Un réseau de **367 liaisons** typées (92 rail, 184 route, 81 rivière, 10 maritime) reliant des
régions, plus **84 ports** et **80 passages de massifs**. Chaque liaison porte : régions aux extrémités,
mode, distance (km), capacité, état, propriétaire/contrôleur, vulnérabilité, source et statut de
la capacité. Les distances ferroviaires sont calculées par haversine sur les coordonnées des axes ;
les distances routières reprennent les `shared_border_km` mesurés en EPSG:3035 par l'atlas.

## 3. Infrastructures intégrées et sources

Générées par `tools/map/build_transport_network.py` (reproductible, `--check`) à partir de fichiers
**déjà versionnés** : `infrastructure.json` (axes), `adjacency.json` (arêtes et détroits),
`terrain.json` (rivières, relief, cols) et `cities.json` (ports). Aucun tracé précis n'a été
inventé. Les **capacités** (train 60–120, route 12–40, fleuve 50, détroit 80, port 80–120) sont
explicitement marquées `ESTIMATION DE MODELE`, pas des faits historiques. La recherche historique
(CHORUS, `TRANSPORT_HISTORICAL_RESEARCH.json`) classe les grandes lignes (étoile de Paris,
nœuds de Berlin/Vienne/Budapest), ports et cols en niveaux A–D sans URL fabriquée.

## 4. Graphes et calcul d'itinéraires

`TransportRouter` implémente un Dijkstra déterministe pondéré : temps par mode (rail 0,25 /
route 1 / rivière 0,7 / mer 0,5), difficulté du relief, pénalité de changement de mode (0,6),
multiplicateur 1,8 si dégradé. Le contrôle territorial, l'appartenance à une alliance et les
accords de transit de la Phase III conditionnent l'accès à chaque région. Un port est requis
pour une liaison maritime. Le résultat fournit chemin, modes, temps, goulot d'étranglement
et motif d'échec. Le cache d'état est porté par l'instance réseau, non sérialisé.

## 5. Capacités, goulets et interruptions

La capacité est un **flux mensuel** (`release_month` la réinitialise). Les états sont
`operational`, `degraded` (capacité ÷2, coût ×1,8), `interrupted` (infranchissable) et `repairing`
(infranchissable jusqu'à la date de réparation). Les ordres `DISRUPT_LINK`, `REPAIR_LINK` et
`SET_PORT_STATUS` sont validés par contrôle territorial (une extrémité de liaison, ou la région
du port). Aucune destruction tactique détaillée n'a été ajoutée.

## 6. Intégrations

- **Militaire** : `LogisticsSystem.update_supply` conserve la continuité territoriale et ajoute
  `delivered`, `route_time` et `route_bottleneck` pour chaque formation, calculés depuis la capitale.
  Les mécaniques de combat MIL-01 n'ont pas été modifiées.
- **Diplomatique** : un accord de transit ouvre réellement les régions concernées au routeur ;
  sa révocation les referme (simulations S8/S9).
- **Renseignement** : aucune donnée d'infrastructure ennemie n'est révélée à l'état complet ;
  l'IA route à partir de sa vue filtrée et du contrôle connu.
- **IA** : `TransportRouter.accessible` et le routage pondéré remplacent le « plus court chemin »
  non pondéré pour les décisions logistiques.

## 7. Interface cartographique

Sept couches activables dans une barre compacte : rail, route, rivières, maritime, ports,
interruptions et capacités. Le dessin passe sous les figurines, conserve frontières, couleurs
nationales, capitales et hachures d'occupation. La page Logistique affiche les régions livrées
et permet d'interrompre/réparer jusqu'à 12 liaisons contrôlées.

## 8. Tests exécutés

| Commande | Résultat |
|---|---|
| `bash tests/run.sh` | **178 tests réussis, 0 échec** ; UI et UI bataille validées ; exit 0 |
| `python3 tools/map/build_transport_network.py --check` | PASS |
| `python3 tools/export/build_game_data.py --check` | PASS |
| `python3 tools/export/build_scenario.py --check` | PASS |
| `python3 tools/history/render_fiches.py --check` | PASS |
| `bash tools/map/validate_all.sh` | VALIDÉ (94 + 96 + 34 contrôles, 0 échec) |

Les 11 nouveaux tests couvrent : chargement et cohérence du graphe, distances, itinéraires rail/
route/multimodaux, capacité et goulot, interruption/dégradation/réparation, ports, transit et
révocation, contournement par l'IA, persistance v6 et migration v5.

## 9. Simulations

`tools/simulate_phase4.gd` exécute les **11 situations imposées**. Graines **1914, 7, 2026** :
**11/11 réussies à chaque graine, 0 échec**. Résultats notables : rail 007→008 en 1,31 ; trajet
multimodal 007→011 utilisant `["rail","river"]` ; région 051 confirmée inaccessible par rail ;
transit belge `avant=false, après=true` puis `accès fermé` après révocation ; capacité
ferroviaire consommée puis réinitialisée au mois suivant ; aucun flux négatif après 24 tours.

## 10. Performances

Le routeur parcourt 367 liaisons avec un Dijkstra borné ; la complexité reste proportionnelle
au nombre de liaisons et aucun itinéraire n'est recalculé globalement à chaque lecture. La charge
de la suite de tests et des 11 simulations reste de l'ordre de la dizaine de secondes. Aucune
régression de performance observée par rapport à la Phase III.

## 11. Anomalies et corrections

- Erreur de compilation GDScript (fonction statique accédant aux liaisons de l'instance) :
  signatures corrigées pour recevoir le réseau explicitement.
- `links`/`ports` JSON sont des tableaux convertis en dictionnaires indexés au chargement.
- Ancien test `delivered == null` mis à jour vers la sémantique Phase IV (compteur).
- Typage Variant dans le dessin des couches corrigé.

## 12. Limitations restantes

- Les routes sont **dérivées de l'adjacency et du relief**, pas d'un inventaire historique de
  routes numérotées (aucune source versionnée ne le permettait) ; qualité estimée documentée.
- Les capacités sont des estimations de modèle, pas des chiffres historiques vérifiés.
- Les liaisons maritimes se limitent aux 10 détroits de l'atlas : pas de lignes de navigation
  océaniques ni de système naval (phase ultérieure).
- Aucune pénalité de ravitaillement n'est appliquée au combat : `delivered` est calculé et
  affiché, les conséquences MIL-01 restent hors périmètre.
- Le cache d'invalidation est manuel (changement d'état/contrôle/transit) ; pas de versionnement
  automatique du graphe.
- Les 17 composantes ferroviaires historiques restent fragmentées ; les connexions inter-lots
  (MAJ-002) non sourcées ne sont pas inventées.

## 13. Migration de sauvegarde

Format **v6**. Migration **v5 → v6** sans perte : le champ `transport` absent est initialisé à
vide ; traités, alliances, crises, relations et historiques de la Phase III sont conservés.
Les formats antérieurs restent refusés ou migrés selon les règles existantes.

## 14. Commits créés

- `e7f90e87764a6ea993aa2bea93dd5f126396bf0c` — `feat(transport): reseau multimodal, capacites et couches cartographiques`
- `d570eefe7422e3ff5a78712b07df289457281b6d` — `test(transport): suite Phase IV, simulateur 11 situations et livrables CHORUS`
- rapport final — `docs(phase4): consigner le rapport de validation et les limitations`

## 15. État final du dépôt

Branche `dev/mil01-finalisation`, publication uniquement sur `origin/dev/mil01-finalisation`.
Aucun merge vers `main`, aucune suppression de branche, aucun push forcé, aucun secret versionné.
Arbre propre, `HEAD` local = `HEAD` distant à l'issue de la publication.

| Niveau | État |
|---|---|
| Conçu | OUI — modèle à 4 modes, capacités et états documentés |
| Documenté | OUI — rapport, sources, livrables CHORUS, limitations |
| Implémenté | OUI — générateur, réseau, routeur, états, ordres, UI, migration |
| Testé | OUI — 178 tests + exports + cartographie |
| Fonctionnel | OUI — démontré par 11 simulations × 3 graines |

**La Phase V n'a pas été commencée.**
