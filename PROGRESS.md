# PROGRESS.md — Tableau de bord permanent

> **Version :** 0.3.0
> **Dernière mise à jour :** 2026-11-01
> **Dernier agent intervenu :** OpenCode
> **Phase actuelle :** Phase 2 — MVP jouable (livré, à valider)
> **Prochaine phase :** Extension progressive après arbitrage des hypothèses et du cahier des charges (T-030)

> **À lire avant toute intervention.** Ce document décrit l'état réel du projet. Il ne remplace pas Git. Toute modification doit respecter [AGENTS.md](AGENTS.md) § 7.3 (mise à jour séquentielle).

---

## A. État général

| Élément | Valeur |
|---|---|
| Phase actuelle | Phase 2 — MVP jouable, **livré et testé** |
| Avancement des fonctionnalités de jeu | **1 MVP de bout en bout livré** (MVP-001) ; le backlog complet n'est pas défini, donc **aucun pourcentage global** n'est affiché |
| Backlog fonctionnel de jeu | MVP initial défini par D-031 ; extensions à prioriser après validation des hypothèses |
| Livrables d'infrastructure | **2 / 2 vérifiés** (INF-001, INF-002) |
| Livrables de conception | **3 terminés** (T-019, T-031, T-035) · **1 partiel** (T-020) |
| Livrables d'implémentation | **1 terminé** (T-036 / MVP-001) |
| Dernière mise à jour | 2026-11-01 |
| Dernier agent intervenu | OpenCode |
| Stabilité du projet | **MVP stable et testé** : 24 tests `unittest` passants, 83 vérifications documentaires, parcours navigateur vérifiés. Les limites sont explicites (pas de batailles tactiques, carte et valeurs provisoires, IA heuristique). |
| Dépôt Git | Initialisé ; travail MVP sur `feat/mvp-playable`, aucun remote. Nom officiel du jeu : *Grand Strategy-1914*. |

### Méthode de calcul de l'avancement

- **Avancement jeu** = fonctionnalités de jeu terminées / fonctionnalités de jeu planifiées.
  Le backlog complet n'existe pas encore ; le dénominateur est inconnu. **Aucun pourcentage de jeu n'est affiché.** Le MVP-001 est compté comme une fonctionnalité livrée, pas comme un pourcentage.
- **Avancement infrastructure** = livrables d'infrastructure vérifiés / livrables d'infrastructure définis.
  Aujourd'hui : 2 / 2. Ce chiffre ne mesure **pas** l'avancement du jeu.
- **Avancement conception** = livrables de conception terminés / livrables de conception identifiés.
  Aujourd'hui : 3 terminés (T-019, T-031, T-035) et 1 partiel (T-020). Ce chiffre ne mesure **pas** un pourcentage du jeu.
- **Avancement implémentation** = livrables de code terminés / livrables de code identifiés.
  Aujourd'hui : 1 / 1 (T-036, MVP-001). Ce chiffre ne mesure **pas** la conformité du jeu à la vision.
- Aucun pourcentage arbitraire, aucune estimation subjective.

### État de stabilité

- Le MVP s'exécute et est couvert par 24 tests `unittest` ; les parcours navigateur principaux ont été testés manuellement.
- Documentation alignée sur la fiche maîtresse et vérifiée par script (structure, liens, empreinte du document fondateur).
- ADR-0006 est **accepté pour le MVP** (délégation technique D-031) ; ADR-0005 reste **proposé**.
- Les valeurs de jeu restent des hypothèses H-001 à H-023, centralisées et révisables.
- Risque principal : prendre le MVP pour une validation des règles définitives. Le cahier des charges (T-030) et l'arbitrage stratégique/tactique (T-029) restent nécessaires.

---

## B. Fonctionnalités terminées

### B.1 Fonctionnalités du jeu

| ID | Nom | Description | Date | Agent | Tests | Limitations |
|---|---|---|---|---|---|---|
| MVP-001 | Premier MVP jouable de bout en bout | Lancement local, carte d'Europe de juin 1914 (90 provinces), choix d'une des 7 puissances ou observation, tours mensuels à résolution simultanée, ordres (mouvement, construction, recrutement, recherche, diplomatie), économie, recherche, événements (dont Sarajevo), combat stratégique automatique, brouillard de guerre, IA heuristique autonome, victoire territoriale/diplomatique/économique, sauvegarde/chargement JSON, prise de contrôle, interface web. | 2026-11-01 | OpenCode | `python3 -m unittest discover -s tests -v` — 24 tests, 0 échec ; `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec ; parcours navigateur Firefox/geckodriver consignés au journal. | Pas de batailles tactiques ; carte et valeurs provisoires (H-001 à H-023) ; IA heuristique sans LLM ni mémoire longue ; diplomatie sans messagerie libre ; pas de multijoueur ; sauvegardes sans migration de schéma ; serveur local non destiné à une exposition publique. |

### B.2 Livrables d'infrastructure

| ID | Nom | Description | Date | Agent | Tests effectués | Limitations |
|---|---|---|---|---|---|---|
| INF-001 | Infrastructure documentaire | Création des documents de référence, de la documentation thématique, des ADR et des dossiers de base. | 2026-10-31 | OpenCode | Vérification de présence, de non-vacuité et des liens par `scripts/check-infrastructure.sh` ; inspection manuelle de la cohérence. | Les documents sont des documents de **cadrage**, pas des spécifications validées. La cohérence sémantique n'est pas vérifiée automatiquement. |
| INF-002 | Script de vérification | `scripts/check-infrastructure.sh` : contrôle des fichiers, dossiers, sections obligatoires, champs d'ADR, liens relatifs, empreinte du document fondateur, secrets et état Git. | 2026-10-31 | OpenCode | Exécution réelle : voir journal section G. | Ne vérifie pas le sens du contenu ni l'exactitude des décisions. Pas encore intégré à une CI. |

### B.3 Livrables de conception

| ID | Nom | Description | Date | Agent | Vérifications | Limitations |
|---|---|---|---|---|---|---|
| T-019 | Intégration de la fiche maîtresse | `PROJECT.md` reprend la fiche maîtresse v0.1 (D-001 à D-026, questions tranchées, Q-026) puis le dossier des nations (D-027 à D-029, Q-027 à Q-031). Version 0.2.2. | 2026-10-31 | OpenCode | Relecture du document source ; contrôle des liens par `scripts/check-infrastructure.sh`. | Plusieurs décisions restent « à définir » dans la fiche elle-même. |
| T-031 | Alignement de la documentation thématique | Réécriture ou alignement de 22 documents thématiques sur les décisions D-001 à D-029 ; ajout des documents tactiques, technologie, renseignement et régimes ; signalement des tensions C-01 à C-18. | 2026-10-31 | OpenCode | `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec, exit 0 (voir journal). | Alignement de **cadrage** à la date de T-031 ; le MVP ultérieur n'est pas couvert par cette tâche. Les valeurs chiffrées restent à définir. |
| T-020 | Profils des sept puissances jouables | Intégration du dossier du propriétaire dans `docs/nations/nations.md` : identité, douze caractéristiques, forces, faiblesses, armées, économie, diplomatie, ambitions, colonies. | 2026-10-31 | OpenCode | Relecture du dossier source ; contrôle des liens par `scripts/check-infrastructure.sh` ; valeurs nationales non modifiées. | **Partiel** : petites puissances non traitées ; articulation chiffrée avec province/économie/armée non définie (Q-027 à Q-031). Les relations initiales du MVP sont désormais dans `game/data/nations.json`, mais leur validation reste à faire. |
| T-035 | Nom officiel du jeu | Le propriétaire arrête **Grand Strategy-1914** (D-030, Q-001 close). En-tête de `PROJECT.md`, titre de `README.md` et entrées de `CHANGELOG.md` alignés. | 2026-10-31 | OpenCode | `bash scripts/check-infrastructure.sh` (voir journal) ; relecture du diff. | Le répertoire Git reste `GrandStrategy` : le renommer casserait les chemins de worktree. Aucun renommage n'a été fait. |

### B.4 Décisions et revue de conception

| ID | Objet | Statut | Preuve |
|---|---|---|---|
| ADR-0004 | Adoption du document fondateur v0.1 comme source de conception | **Accepté**, avec réserve sur le cahier des charges | `docs/decisions/0004-adoption-du-document-fondateur.md` |
| ADR-0005 | Intégration du temps stratégique et tactique | **Proposé** — ne vaut pas décision | `docs/decisions/0005-integration-strategique-tactique.md` |
| ADR-0006 | Pile technique du premier MVP jouable | **Accepté pour le MVP** (délégation D-031) | `docs/decisions/0006-pile-technique-mvp.md` |
| Revue de conception | Tensions C-01 à C-18, vigilances V-01 à V-08 | Cadrage, non validée | `docs/design-review-v0.1.md` |
| Document fondateur | Source gelée par empreinte SHA-256 | Gelé | `docs/founding-document-v0.1.md` |

---

## C. Travaux en cours

### T-036 — Premier MVP jouable de bout en bout

- **Responsable :** OpenCode
- **Date de début :** 2026-11-01
- **Fichiers concernés :** `game/`, `tests/`, `README.md`, `PROJECT.md`, `PROGRESS.md`, `CHANGELOG.md`, `docs/architecture/`, `docs/decisions/`, `DECISIONS_PENDING.md`
- **Dépendances :** D-031 (autorisation d'implémentation et délégation technique), ADR-0006 (pile technique du MVP).
- **État actuel :** **Terminé** le 2026-11-01 — moteur stratégique, IA heuristique, interface web, sauvegarde JSON, 24 tests et documentation du MVP.
- **Prochaine étape :** aucune pour le MVP initial. Les extensions (batailles tactiques, diplomatie négociée, économie approfondie, renseignement) nécessitent un arbitrage ou une nouvelle tâche.

### T-035 — Entériner le nom officiel du jeu

- **Responsable :** OpenCode
- **Date de début :** 2026-10-31
- **Fichiers concernés :** `PROJECT.md`, `PROGRESS.md`, `CHANGELOG.md`, `README.md`
- **Dépendances :** Décision du propriétaire du 2026-10-31 : le jeu s'appelle **Grand Strategy-1914**.
- **État actuel :** **Terminé** le 2026-10-31
- **Prochaine étape :** Aucune. D-030 est la référence ; toute modification du nom devra être une nouvelle décision du propriétaire.

Les réservations T-019 (2026-10-31), T-035 (2026-10-31) et T-036 (2026-11-01) ont été clôturées par OpenCode après vérification de leur achèvement (voir journal). Aucun autre agent n'a réservé de fichier.

### Modèle d'entrée (à utiliser pour toute nouvelle tâche)

```markdown
### T-XXX — Titre

- **Responsable :** <nom réel de l'outil>
- **Date de début :** AAAA-MM-JJ
- **Fichiers concernés :** ...
- **Dépendances :** ...
- **État actuel :** En cours
- **Prochaine étape :** ...
```

---

## D. Travaux à effectuer

> **Règle :** une tâche qui dépend d'une décision du propriétaire n'est pas « en cours » ; elle est **bloquée** tant que la décision n'est pas consignée. Aucun agent ne tranche une tension C-xx ou une question Q-xx à la place du propriétaire.

### P0 — Bloquant / indispensable

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-030 | Valider le cahier des charges détaillé | Le propriétaire valide le document qui autorisera l'implémentation des mécaniques définitives : valeurs, seuils et cas limites. | T-020 à T-029 | **À faire — propriétaire** ; bloque les mécaniques définitives, pas le MVP (D-031) |
| T-029 | Arbitrer l'intégration stratégique/tactique | Trancher C-01, C-02, C-04, C-15 et C-17 ; accepter, modifier ou rejeter ADR-0005. | Aucune | **À faire — propriétaire** ; ADR-0005 proposé ; bloque les batailles tactiques |
| T-021 | Économie, industrie et niveau de vie | Définir les trois ressources, la production, le budget, l'industrie, la population et l'indicateur de niveau de vie. | T-020, Q-028 | **À faire — agent** ; bloqué par Q-028 ; MVP économique provisoire livré |
| T-022 | Règles diplomatiques | Spécifier types d'accords, clauses contraignantes, sanctions, crises, cycle de vie et calendrier (C-16). | T-020, T-021 | **À faire — agent** ; MVP diplomatique partiel livré |
| T-026 | Tours, résolution, victoire et visibilité | Définir phases, verrouillage, résolution des conflits d'ordres, seuils de victoire (C-08) et fog of war (C-06). | T-021 à T-025, T-029 | **À faire — agent + propriétaire** ; MVP provisoire livré |

### P1 — Haute priorité

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-023 | IA dirigeantes | Spécifier personnalités, mémoire, objectifs, prise de décision, gestion des crises et étanchéité informationnelle (Q-012). | T-022, T-021 | À faire — agent ; MVP heuristique livré |
| T-024 | Règles militaires et batailles | Définir unités, fronts, offensives, fortifications, conversion stratégique ↔ tactique (C-03) et état des unités sans moral (C-10). | T-026, T-029 | À faire — agent ; combat stratégique MVP livré, tactique absent |
| T-025 | Technologies et renseignement | Définir l'arbre 1914-1945, coûts, avance, spécialisations, interception (C-05, C-11) et espionnage industriel. | T-021, T-023 | À faire — agent ; MVP partiel (20 technologies, renseignement simple) |
| T-027 | Interface et modes de jeu | Concevoir l'interface stratégique, les campagnes, les parties libres, l'observation, la prise de contrôle (C-14) et l'accessibilité. | T-026, T-029 | À faire — agent ; MVP web livré, cible à concevoir |
| T-028 | Architecture, persistance et licences | Étudier la pile technique (ADR), la persistance, le replay (C-15), l'anticipation multijoueur (C-17) et les licences (C-13, Q-020, Q-026). | T-030, Q-002, Q-007, Q-008 | **Partiel** — pile MVP choisie (ADR-0006) ; cible, replay, multijoueur et licences ouverts |
| T-032 | Modéliser les profils nationaux | Intégrer les douze caractéristiques, les ambitions initiales, les régions impériales et les relations de départ dans le modèle de données, sans double comptage avec les provinces. | T-021, T-020 | **Partiel** — profils intégrés dans `game/data/nations.json` ; articulation chiffrée à valider |
| T-033 | Traduire la situation diplomatique initiale | Convertir les relations décrites dans `docs/nations/nations.md` en valeurs amitié / neutralité / hostilité et en traités de départ, y compris secrets. | T-022, T-020 | **Partiel** — relations initiales intégrées ; traités secrets absents |

### P2 — Priorité normale

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-034 | Évolution des caractéristiques nationales | Définir coûts, seuils, durées et plafonds d'évolution des douze caractéristiques, ainsi que leurs effets. | T-032, Q-031 | À faire — agent |
| T-020 (suite) | Petites puissances et articulation | Définir la liste et le poids des pays non jouables, puis l'articulation chiffrée des douze caractéristiques avec les provinces, la production et le budget. | T-021, Q-028, Q-029 | **Partiel** — agent |

### D.4 Extensions post-MVP (proposées, non réservées)

Ces tâches ne sont pas nécessaires pour utiliser le MVP actuel. Elles dépendent d'un arbitrage du propriétaire ou d'une décision de conception.

| ID | Tâche | Description | Dépendances | Statut |
|---|---|---|---|---|
| T-037 | Batailles tactiques | Concevoir et prototyper la bataille indépendante de 30 minutes, la conversion stratégique ↔ tactique et le retour des pertes/occupation dans la partie stratégique. | T-029, ADR-0005 accepté | **Proposé** — agent, après arbitrage |
| T-038 | Diplomatie négociée et mémoire IA | Ajouter propositions officielles, messagerie, mémoire des engagements et conséquences des trahisons. | T-022, T-023 | **Proposé** — agent |
| T-039 | Économie et logistique approfondies | Étendre les ressources, le budget, l'industrie, le ravitaillement et le niveau de vie au-delà des formules provisoires. | T-021, Q-028 | **Proposé** — agent |
| T-040 | Renseignement et interception | Ajouter les estimations, l'interception, le décryptage et les rapports périodiques. | T-025 | **Proposé** — agent |
| T-041 | Équilibrage et validation du MVP | Jouer des parties complètes, mesurer les victoires, les blocages et la lisibilité, puis réviser les hypothèses H-001 à H-023. | MVP-001 | **Proposé** — agent + propriétaire |
| T-042 | Sauvegardes, CI et robustesse | Ajouter la migration de schéma, des tests d'API et une CI exécutant tests et vérifications documentaires. | MVP-001, TD-013 | **Proposé** — agent |

### D.5 Tâches archivées (remplacées)

Les anciennes tâches T-001 à T-018 ne sont plus suivies séparément : elles ont été remplacées par les tâches ci-dessus. Elles sont conservées pour l'historique et ne doivent pas être réactivées sans vérifier leur remplacement.

| Ancienne tâche | Objet | Remplacée par | Motif |
|---|---|---|---|
| T-001 | Valider la vision et le MVP | T-030 / Q-002 | La fiche maîtresse fixe la vision ; le MVP reste à valider. |
| T-002 | Trancher la relation à Diplomacy | Q-003 (tranchée) | Réponse consignée dans PROJECT.md § 1.2. |
| T-003 | Trancher le rythme | Q-005 (tranchée) | Un tour = un mois (D-006). |
| T-004 | Étude de pile technique + ADR | T-028 | Toujours ouverte, intégrée à l'architecture. |
| T-005 | Spécifier les règles de base | T-026 | Couvert par tours/résolution/victoire. |
| T-006 | Modèle de données v0.2 | T-032 / T-028 | Le modèle dépend des profils et de la persistance. |
| T-007 | Contrat d'interface IA | T-023 | Intégré aux IA dirigeantes. |
| T-008 | Format de carte + validateur | T-020 / T-026 | Dépend de la liste des provinces. |
| T-009 | Spécifier traités et négociations | T-022 | Intégré aux règles diplomatiques. |
| T-010 | Harnais d'évaluation des IA | T-023 | Intégré aux IA dirigeantes. |
| T-011 | Persistance et replay | T-028 | Intégré à l'architecture. |
| T-012 | Personnalités et mémoire | T-023 | Intégré aux IA dirigeantes. |
| T-013 | Étude UI/UX | T-027 | Intégré à l'interface. |
| T-014 | Observabilité | T-028 | Intégré à l'architecture. |
| T-015 | Modding | T-028 / Q-018 | Question ouverte. |
| T-016 | Localisation | T-027 / Q-019 | Question ouverte. |
| T-017 | Accessibilité | T-027 / Q-021 | Question ouverte. |
| T-018 | Éditeur de carte | T-020 / T-027 | Dépend de la carte et de l'interface. |

---

## E. Bugs et problèmes connus

### E.1 Bugs logiciels

**Aucun bug logiciel ouvert connu** dans le MVP au 2026-11-01. Les bugs détectés pendant la mise au point ont été corrigés et sont conservés ci-dessous pour l'historique.

| ID | Description | Gravité | Origine | Reproduction | État | Responsable |
|---|---|---|---|---|---|---|
| BUG-001 | Le serveur plantait à la journalisation d'une réponse 404 : `send_error` recevait un entier au lieu d'un message. | Moyenne | `game/server.py`, `log_message` | Requête vers un chemin API inexistant | **Résolu le 2026-11-01** | OpenCode |
| BUG-002 | À 768 px de hauteur, les onglets glissaient sous la barre supérieure et devenaient inaccessibles. | Moyenne | `game/web/style.css` | Fenêtre de 768 px de haut, défilement de la page | **Résolu le 2026-11-01** (écran de jeu en `100vh`, panneaux défilants) | OpenCode |
| BUG-003 | `build_view` supposait une nation joueur non nulle, ce qui cassait le mode observation. | Moyenne | `game/server.py`, helper `_view()` | Lancer une partie en mode observation | **Résolu le 2026-11-01** | OpenCode |

### E.2 Limitations connues de l'infrastructure et de la conception

| ID | Problème | Gravité | Origine | État | Responsable |
|---|---|---|---|---|---|
| L-001 | Le script vérifie la structure, les liens et une empreinte, pas la cohérence sémantique des documents. | Faible | Limite de l'automatisation | Connu, accepté | OpenCode |
| L-002 | Aucune CI n'exécute les tests ni le script automatiquement. | Moyenne | MVP local sans CI | Ouvert — tâche T-042 proposée | À assigner |
| L-003 | La protection de branche et la revue obligatoire ne sont pas configurées côté hébergeur. | Moyenne | Dépôt local, pas de remote | Ouvert | Propriétaire |
| L-004 | L'identité formelle du propriétaire et le canal d'arbitrage ne sont pas définis. | Moyenne | Information manquante | Ouvert — voir Q-025 | Propriétaire |
| L-005 | Aucun glossaire commun n'existe encore ; certains termes peuvent être interprétés différemment. | Faible | Cadrage initial | Ouvert | À assigner |
| L-006 | `PROGRESS.md` ne reflétait pas l'état décrit par le `CHANGELOG.md` : T-019 était listée « en cours » et les tâches T-020 à T-031 n'apparaissaient pas toutes. | Moyenne | Mises à jour séquentielles non clôturées | **Résolu le 2026-10-31** par la présente version 0.2.0 | OpenCode |
| L-007 | Le travail de la branche `docs/fiche-maitresse-v0.2` n'est pas encore commité : une perte du répertoire de travail perdrait la réorganisation, les réécritures et les nouveaux documents. | Haute tant que non commité | Commit non effectué | **Résolu le 2026-10-31** par le commit `a2e0940` | OpenCode |
| L-008 | Aucun système de jeu complet n'est spécifié : les documents sont des cadrages alignés, pas des spécifications. | Moyenne | Phase 1 | **Partiellement résolu** : le MVP prouve la boucle stratégique, mais les mécaniques définitives restent à spécifier | Propriétaire / agents |
| L-009 | Le document fondateur contient des tensions internes non tranchées (C-01 à C-18). | Haute | Document fondateur v0.1 | Connu — voir `docs/design-review-v0.1.md` | Propriétaire |
| L-010 | Les batailles tactiques ne sont pas implémentées ; le combat est résolu automatiquement sur la carte stratégique (H-006). | Haute pour la vision | MVP provisoire | Connu, assumé ; aucune fausse interface | Agents |
| L-011 | La carte (90 provinces) et les valeurs économiques, militaires, diplomatiques et de victoire sont provisoires (H-001 à H-023). | Haute | MVP | Connu — voir `DECISIONS_PENDING.md` | Propriétaire / agents |
| L-012 | L'IA est heuristique : pas de LLM, pas de mémoire conversationnelle longue, pas de négociation libre. | Moyenne | MVP | Connu, assumé | Agents |
| L-013 | Les sauvegardes JSON sont versionnées mais sans migration automatique entre versions du schéma. | Moyenne | MVP | Ouvert — tâche T-042 proposée | Agents |
| L-014 | Le serveur HTTP local n'est pas sécurisé pour une exposition publique (pas d'authentification, pas de TLS). | Haute si exposé | MVP | Connu, assumé | Agents / propriétaire |
| L-015 | Aucune CI n'exécute automatiquement les tests et le script de vérification. | Moyenne | MVP | Ouvert — tâche T-042 proposée | Agents |

### E.3 Risques suivis (rappel)

Les risques architecturaux sont détaillés dans [docs/architecture/overview.md § 7](docs/architecture/overview.md#7-risques-architecturaux-identifiés). Ils ne sont pas des bugs.

---

## F. Prochaines étapes

Cinq prochaines actions recommandées, dans l'ordre :

| # | Action | Responsable | Dépendances | Pourquoi maintenant |
|---|---|---|---|---|
| 1 | **Tester le MVP** et consigner les retours | Propriétaire | MVP-001 | Le MVP est jouable ; les défauts d'expérience doivent être observés avant d'étendre les systèmes. |
| 2 | **T-041** — Réviser les hypothèses H-001 à H-023 | Propriétaire + agent | MVP-001 | La carte, l'économie, les seuils de victoire et l'IA reposent sur des valeurs provisoires. |
| 3 | **T-029** — Arbitrer le temps stratégique/tactique | Propriétaire | Aucune | Conditionne les batailles tactiques et l'architecture cible ; ADR-0005 est prêt à être accepté ou rejeté. |
| 4 | **T-030** — Valider le cahier des charges | Propriétaire | T-020 à T-029 | Conditionne les mécaniques définitives, pas le MVP actuel. |
| 5 | **T-038 / T-039 / T-040** — Étendre diplomatie, économie, renseignement | Agent | T-021 à T-025 | Le MVP prouve la boucle ; l'extension doit rester progressive et testée. |

**Point de blocage actuel :** T-029 et T-030 appartiennent au propriétaire. Aucun agent ne doit les trancher à sa place. Les extensions T-037 à T-042 sont proposées, non réservées.

---

## G. Journal des interventions

| Date | Agent | Intervention | Fichiers | Tests | Résultat |
|---|---|---|---|---|---|
| 2026-10-31 | OpenCode | Création de l'infrastructure documentaire initiale : documents de référence, documentation thématique, ADR 0001–0003, script de vérification, initialisation Git. | `AGENTS.md`, `PROJECT.md`, `PROGRESS.md`, `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `.gitignore`, `.env.example`, `docs/**`, `scripts/check-infrastructure.sh`, `src/README.md`, `tests/README.md`, `assets/README.md` | `./scripts/check-infrastructure.sh` — 67 vérifications, 0 échec (après correction d'un lien cassé) ; `git status` — vérification avant commit. | Terminé |
| 2026-10-31 | OpenCode | Intégration du dossier des puissances jouables fourni par le propriétaire : profils des sept nations, douze caractéristiques, ambitions, colonies, comparaison, comportement des IA et annexe d'intégration (D-027 à D-029, Q-027 à Q-031). Mise à jour des index et des liens, correction des chemins de documentation déplacés, ajout des nouveaux documents au script de vérification. | `docs/nations/nations.md` (nouveau), `PROJECT.md`, `PROGRESS.md`, `CHANGELOG.md`, `README.md`, `docs/README.md`, `AGENTS.md`, `docs/architecture/overview.md`, `docs/development/testing-strategy.md`, `scripts/check-infrastructure.sh` | `bash scripts/check-infrastructure.sh` — 76 vérifications, 0 échec, exit 0 ; `git diff --stat` et `git status` — vérification du périmètre. | Terminé |
| 2026-10-31 | OpenCode | Gel du document fondateur, revue de conception, ADR-0004 (accepté) et ADR-0005 (proposé), réorganisation `docs/ai`, `docs/military`, `docs/economy`, alignement de 22 documents thématiques sur les décisions D-001 à D-029, mise à jour des index, de `PROJECT.md` v0.2.2, du `CHANGELOG.md` et du script (empreinte SHA-256). Clôture de T-019 ; T-020 laissée **partielle** ; T-021 à T-034 documentées ; tâches T-001 à T-018 archivées avec leur remplacement. | `docs/founding-document-v0.1.md`, `docs/design-review-v0.1.md`, `docs/decisions/0004-adoption-du-document-fondateur.md`, `docs/decisions/0005-integration-strategique-tactique.md`, `docs/README.md`, `docs/decisions/README.md`, `docs/gameplay/rules.md`, `docs/gameplay/map-system.md`, `docs/military/strategic-warfare.md`, `docs/military/tactical-battles.md`, `docs/economy/economy-system.md`, `docs/technology/research-system.md`, `docs/intelligence/intelligence-system.md`, `docs/nations/regimes.md`, `docs/diplomacy/*.md`, `docs/architecture/*.md`, `docs/ai/*.md`, `PROJECT.md`, `PROGRESS.md`, `README.md`, `CHANGELOG.md`, `AGENTS.md`, `scripts/check-infrastructure.sh` | `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec, exit 0 ; `sha256sum docs/founding-document-v0.1.md` — empreinte conforme ; `git status` et `git diff` — périmètre examiné. | Partiel (T-020) / Terminé (reste) ; commit non effectué |
| 2026-10-31 | OpenCode | Clôture de session : commit du travail documentaire sur `docs/fiche-maitresse-v0.2`, vérification finale après réécriture de PROGRESS.md, résolution de L-007 et mise à jour du tableau de bord. | `PROGRESS.md` (journal et état) ; commit `a2e0940` portant 36 fichiers (racine, `docs/`, `scripts/`) | `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec, exit 0 ; `git status` propre avant commit ; `git commit` → `a2e0940` (36 fichiers, +5409/−1334). | Terminé |
| 2026-10-31 | OpenCode | Consolidation demandée par le propriétaire : correctif du test Git du script (reconnaissance d'un worktree), puis fusion fast-forward de `docs/fiche-maitresse-v0.2` dans `main`. La branche `docs/fiche-maitresse-opencode` (travail parallèle isolé, commit `ca0d4e2`) est entièrement reprise par la branche consolidée ; elle reste archivée, non fusionnée. | `scripts/check-infrastructure.sh`, `CHANGELOG.md`, `PROGRESS.md` | `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec, exit 0 ; `git merge --ff-only` — succès, `main` avancée. | Terminé |
| 2026-10-31 | OpenCode | T-035 : enregistrement du nom officiel du jeu, **Grand Strategy-1914**, décidé par le propriétaire. Ajout de D-030, clôture de Q-001, alignement de l'en-tête de `PROJECT.md` (v0.2.3), du titre de `README.md`, du `CHANGELOG.md` et du tableau de bord. Aucune règle de jeu touchée ; aucun renommage du répertoire Git. | `PROJECT.md`, `README.md`, `CHANGELOG.md`, `PROGRESS.md` | `bash scripts/check-infrastructure.sh` — 83 vérifications, 0 échec, exit 0 ; `git diff --check` — aucune erreur d'espacement ; `git status` — périmètre limité aux quatre fichiers. | Terminé |
| 2026-11-01 | OpenCode | T-036 : implémentation du **premier MVP jouable de bout en bout** (D-031, ADR-0006) — modèle et scénario de juin 1914, carte de 90 provinces, moteur de tour à résolution simultanée, économie, recherche, militaire stratégique, diplomatie, événements (Sarajevo), IA heuristique filtrée, victoire, sauvegarde JSON, serveur HTTP et interface web. Documentation du MVP : `DECISIONS_PENDING.md` (H-001 à H-023), ADR-0006, `README.md`, `PROJECT.md` v0.2.4, `PROGRESS.md` v0.3.0, `CHANGELOG.md`, index et registres techniques. | `game/**`, `tools/generate_map.py`, `tests/test_engine.py`, `README.md`, `PROJECT.md`, `PROGRESS.md`, `CHANGELOG.md`, `DECISIONS_PENDING.md`, `docs/decisions/0006-pile-technique-mvp.md`, `docs/decisions/README.md`, `docs/architecture/technical-decisions.md`, `docs/architecture/overview.md`, `docs/README.md`, `docs/development/testing-strategy.md`, `docs/development/coding-standards.md`, `src/README.md`, `tests/README.md` | `python3 -m unittest discover -s tests -v` — **24 tests, 0 échec** ; `bash scripts/check-infrastructure.sh` — **83 vérifications, 0 échec, exit 0** ; parcours Firefox/geckodriver : sélection d'une puissance, observation, prise de contrôle, mouvement d'armée, recherche, recrutement, fin de tour, sauvegarde/chargement, événement de Sarajevo, carte de 90 provinces sans débordement horizontal ; `git status` et `git diff` — périmètre examiné. | Terminé |

> Le journal est append-only. Ne jamais supprimer ni réécrire une ligne existante. Une correction s'ajoute avec une référence à la ligne corrigée.

---

## H. Historique du tableau de bord

| Date | Agent | Changement |
|---|---|---|
| 2026-10-31 | OpenCode | Création initiale. |
| 2026-10-31 | OpenCode | Version 0.1.1 : phase 1 en cours, livrable de conception T-020, tâches T-032 à T-034, constat L-006, journal d'intégration du dossier des nations. |
| 2026-10-31 | OpenCode | Version 0.2.0 : clôture de T-019, ajout de T-021 à T-034, archivage de T-001 à T-018, constats L-007 à L-009, résolution de L-006, journal d'alignement documentaire. |
| 2026-10-31 | OpenCode | Version 0.2.2 : correctif du script pour les worktrees et consolidation sur `main` (fast-forward). |
| 2026-10-31 | OpenCode | Version 0.2.1 : commit `a2e0940`, résolution de L-007, journal de clôture de session. |
| 2026-10-31 | OpenCode | Version 0.2.3 : nom officiel *Grand Strategy-1914* (D-030), clôture de Q-001, livrable T-035. |
| 2026-11-01 | OpenCode | Version 0.3.0 : phase 2, MVP-001 livré (T-036), 24 tests, ADR-0006, hypothèses H-001 à H-023, limites et extensions post-MVP documentées. |
