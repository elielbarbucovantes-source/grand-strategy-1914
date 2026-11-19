# POST_MIL01_PHASE6_REPORT — Phase VI : technologie, renseignement, aviation et marine

> **Date :** 2026-11-19
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État initial :** `259ec73`, dépôt propre et synchronisé (`0/0`). Phases I–V préservées.
> **Collaboration :** CHORUS a réussi **2 tâches sur 3** (audit et forces aériennes/navales 1914),
> versionnées dans `docs/project/phase6/` ; la recherche d'arbre technologique a expiré.
> **Phase VII non commencée.**

---

## 1. Audit initial

Le squelette `ResearchSystem` n'avait aucun arbre ni coût ; `n.research` était « OUVERT ».
`IntelSystem` gérait le brouillard de guerre terrestre mais pas le renseignement technique,
les communications ni l'interception. L'aviation, la marine, les ports militaires et les zones
maritimes opérationnelles n'existaient pas, malgré 16 zones maritimes dans la carte et 84 ports
dans le réseau Phase IV. Aucun système opérationnel n'a été supprimé.

## 2. Modèle technologique et arbre

`data/game/technology_tree.json` : **33 technologies** de 1900 à 1943 réparties en 11 domaines,
avec identifiant, domaine, année indicative, prérequis, coût, durée, effets et niveau de
fiabilité. Aucune technologie de 1945 n'est accessible en 1914 : les prérequis et l'année sont
vérifiés. Les technologies hypothétiques sont signalées (niveau C/D).

## 3. Recherche et diffusion

`TechSystem` : projets actifs (max 3), points de science calculés depuis la capacité industrielle
et la main-d'œuvre qualifiée, coût réel en charbon/fer prélevé sur les stocks Phase V, progression
plafonnée par tour. Une découverte est un choix : projet, ressources, prérequis et délai. La
diffusion par accord est moins coûteuse que la recherche propre ; la capture/acquisition est
documentée comme mécanisme mais pas encore automatisée (limitation).

## 4. Communications, interception et décryptage

`CommunicationsSystem` : protection croissante par technologie ; quatre niveaux distincts —
**détecté → intercepté → partiellement compris → décrypté** — avec fiabilité croissante (0,1 à 0,9).
L'interception dépend du hasard borné par la graine, de la protection adverse et des technologies.
Le décryptage est **graduel** (progression par tour, jamais instantané) et le renseignement
technique结果 est imparfait et devient obsolète après 3 tours. Aucune instruction réelle de
compromission de communications n'est développée : tout est abstrait.

## 5. Aviation et bases aériennes

`AirSystem` : bases par région contrôlée, production d'appareils (recon/chasse/bombardier/polyvalent)
consommant fer et charbon, catalogue débloqué par les technologies. Les missions de reconnaissance
alimentent `state.tech.intel` avec une précision imparfaite et datée. Maintenance mensuelle
réduisant progressivement les appareils, sans stock négatif.

## 6. Marine et zones maritimes

`NavalSystem` : flottes créées depuis un port contrôlé (6 catégories historiques), composition et
coûts de production réels, autonomie abstraite ravitaillée au port. Opérations stratégiques :
patrouille, reconnaissance, escorte, interception, blocus, transport et débarquement amphibie —
résolues de façon abstraite, sans simulation tactique. L'escorte réduit les pertes commerciales,
le blocus réduit le commerce ; les accords diplomatiques n'entrant pas de contrôle de flotte.

## 7. Production et intégration économique

Les appareils et navires consomment des ressources Phase V via `ResourceSystem.consume`.
Aucune production gratuite : les tests montrent qu'une production est refusée sans intrants et
limitée par les stocks disponibles.

## 8. IA Phase VI

`Phase6AI` : personnalités (scientifique, naval, aérien, équilibré), priorisation de la recherche
selon le domaine, protection des communications, mission de reconnaissance aérienne vers un voisin,
patrouille navale. Décisions **bornées** (recherche, air, marine, interceptions) et déterministes.

## 9. Interface

La page Recherche affiche projets, technologies accessibles, interceptions, résumé aviation/marine
et permet de lancer recherche/écoute. Trois couches cartographiques s'ajoutent : bases aériennes,
flottes et activité de renseignement.

## 10. Tests exécutés

| Commande | Résultat |
|---|---|
| `bash tests/run.sh` | **202 tests réussis, 0 échec** ; UI et UI bataille validées ; exit 0 |
| `python3 tools/map/build_transport_network.py --check` | PASS |
| `python3 tools/economy/build_economic_baseline.py --check` | PASS |
| `python3 tools/export/build_game_data.py --check` | PASS |
| `python3 tools/export/build_scenario.py --check` | PASS |
| `python3 tools/history/render_fiches.py --check` | PASS |
| `bash tools/map/validate_all.sh` | VALIDÉ (94 + 96 + 34 contrôles, 0 échec) |

12 nouveaux tests couvrent l'arbre et les prérequis, les coûts/progrès de recherche, la progression
inégale, les niveaux d'interception, le décryptage graduel, la production aéronautique, la
reconnaissance, les flottes, les opérations navales, l'IA, la persistance v8 et la migration v7.

## 11. Simulations

`tools/simulate_phase6.gd` exécute les **15 situations imposées** avec les graines **1914, 7, 2026** :
**15/15 réussies à chaque graine, 0 échec**. Notamment : recherche aboutie en paix ; progression
inégale ; interception sans décryptage ; décryptage abstrait abouti ; reconnaissance aérienne ;
production aéronautique refusée puis limitée par les ressources ; deux flottes depuis deux ports ;
escorte, blocus, transport et amphibie ; aucun stock négatif après 18 tours de guerre.

## 12. Performances

La recherche progresse une fois par mois et plafonne à 20 points/tour ; les interceptions sont
bornées à 4/tour et les opérations navales à 3/tour. Le rechargement d'une sauvegarde v8 est
deterministe (tests de non-régression Phase V inclus). La suite complète et les 15 simulations
restent de l'ordre de la dizaine de secondes.

## 13. Anomalies corrigées

- `create_fleet`/`produce` accédaient à `state.rules` (inexistant) → règles passées explicitement.
- Migration v4 : la boucle d'effacement des champs n'incluait pas `tech` → corrigée ; anciens tests
  de migration mis à jour pour effacer `tech`.
- Typage de la graine d'interception et de variables de test → explicite.
- Effet d'opération `transport` absent → ajouté.

## 14. Limitations restantes

- Acquisition technologique par **capture** documentée mais pas automatisée ; seul l'accord
  de diffusion est modélisé.
- L'espionnage industriel est couvert par l'interception/décryptage abstrait, sans opération dédiée.
- Aucune simulation tactique aérienne ou navale (volontaire : opérations stratégiques abstraction).
- Les zones maritimes utilisent les 16 zones de l'atlas ; pas de grille de navigation océanique fine.
- Les personnalités technologiques ne sont pas éditables depuis l'interface.
- CHORUS : 2 livrables sur 3 ; l'arbre technologique a été conçu directement.

## 15. Paramètres validés vs proposés

| Nature | Statut |
|---|---|
| Brouillard de guerre et renseignement imparfait (Phase I) | **VALIDÉ** |
| Réseaux de transport et ports (Phase IV) | **VALIDÉS** |
| Catégories industrielles et coûts ressources (Phase V) | **VALIDÉS** |
| Arbre technologique, effets, coûts, durées, personnalités IA | **PROPOSÉS** et configurables |
| Niveaux d'interception, taux de décryptage, coûts navires/avions | **PROPOSÉS** |

## 16. Commits publiés

- `2a9ce0c47eae0c580f263947d9b1883132a8e183` — `feat(phase6): technologie, communications, aviation et marine`
- rapport final — `docs(phase6): consigner le rapport de validation et les limitations`

## 17. État final du dépôt

Branche `dev/mil01-finalisation`, publication uniquement sur `origin/dev/mil01-finalisation`.
Aucun merge vers `main`, aucune suppression de branche, aucun push forcé, aucun secret versionné.
Arbre propre, `HEAD` local = `HEAD` distant à l'issue de la publication.

| Niveau | État |
|---|---|
| Conçu | OUI — arbre, communications, air, marine |
| Documenté | OUI — sources, limitations, paramètres proposés |
| Implémenté | OUI — 5 sous-systèmes, état v8, migration, interface |
| Testé | OUI — 202 tests + exports + cartographie |
| Fonctionnel | OUI — démontré par 15 simulations × 3 graines |

**La Phase VII n'a pas été commencée.**
