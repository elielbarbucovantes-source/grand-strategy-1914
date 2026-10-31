# PROJECT.md — Document de référence du projet

> **Version :** 0.1.0
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Statut global :** Phase 0 — cadrage. Aucun code de jeu n'existe.
> **Nom du projet :** provisoire (`GrandStrategy`, nom du dossier). Le nom officiel reste **à définir**.
> **Propriétaire :** à définir formellement (voir § 11 et AGENTS.md § 18).

---

## Légende des statuts

Chaque affirmation importante de ce document est étiquetée :

| Étiquette | Signification |
|---|---|
| **[VALIDÉ]** | Décision explicite du propriétaire du projet. Ne peut être changée que par lui. |
| **[PROPOSITION]** | Recommandation d'un agent. **Non validée.** Peut être acceptée, modifiée ou rejetée. |
| **[HYPOTHÈSE]** | Supposition à vérifier par une étude, un prototype ou une décision ultérieure. |
| **[À DÉFINIR]** | Question ouverte. Aucune valeur par défaut ne doit être supposée. |

Règle : une proposition ou une hypothèse ne devient jamais une décision par simple répétition dans un autre document. Seul le propriétaire valide, et la validation est tracée (PROJECT.md ou ADR accepté).

---

## 1. Présentation du jeu

**[VALIDÉ]** Le projet est un jeu de **stratégie, de diplomatie et de guerre** inspiré de **webDiplomacy**.

**[VALIDÉ]** Il est enrichi par des **agents d'intelligence artificielle autonomes**, dotés de comportements réalistes, capables de :

- négocier ;
- coopérer ;
- manipuler ;
- respecter des traités ;
- trahir de manière intelligente et contextuelle.

**[VALIDÉ]** Le projet est destiné à un développement de plusieurs mois, potentiellement plusieurs années, mené par plusieurs agents IA (OpenCode, Codex, Claude Code et éventuellement d'autres) et par le propriétaire.

**[À DÉFINIR]** Le nom officiel, le positionnement commercial, la plateforme cible et le public précis.

### Ce que le projet n'est pas (à ce stade)

- Ce n'est pas un clone de webDiplomacy : la relation exacte avec les règles de Diplomacy reste **à définir**.
- Ce n'est pas encore un jeu jouable : aucun moteur, aucune règle implémentée, aucune interface.
- Ce n'est pas un projet dont la pile technique est choisie.

---

## 2. Vision à long terme

**[VALIDÉ]** Construire un jeu de stratégie et de diplomatie durable, où des IA autonomes agissent comme des adversaires ou alliés crédibles, et où la négociation, la confiance, la réputation et la trahison ont des conséquences réelles.

**[PROPOSITION]** La vision pourrait se décliner ainsi :

- un monde persistant ou des parties longues, avec une mémoire des engagements passés ;
- des IA avec des personnalités distinctes, des objectifs propres et une capacité à mentir de façon plausible ;
- une expérience lisible pour le joueur humain : il doit comprendre *pourquoi* une IA agit, sans que cela révèle ses secrets ;
- une architecture qui permet d'ajouter des mécaniques, des cartes et des comportements sans réécrire le cœur ;
- un projet documenté et reproductible, capable de survivre à des interruptions longues.

Ces éléments sont des propositions, pas des engagements.

---

## 3. Objectifs principaux

### 3.1 Objectifs validés

**[VALIDÉ]**

1. Créer une infrastructure documentaire et collaborative durable pour le projet.
2. Permettre à plusieurs agents de travailler sans repartir de zéro et sans se détruire mutuellement le travail.
3. Concevoir un jeu de stratégie/diplomatie inspiré de webDiplomacy.
4. Intégrer des IA autonomes de négociation et de décision.
5. Préserver la traçabilité des décisions et des interventions.

### 3.2 Objectifs proposés (non validés)

**[PROPOSITION]**

- Définir un MVP jouable avant toute ambition graphique.
- Rendre le moteur de règles déterministe et testable indépendamment de l'interface et des IA.
- Isoler les IA derrière un contrat d'interface stable, afin de pouvoir changer de modèle ou de fournisseur.
- Mesurer la qualité des IA par des scénarios reproductibles, pas par une impression subjective.
- Documenter chaque système avant son implémentation.

---

## 4. Public et expérience de jeu recherchée

**[À DÉFINIR]** Le public cible n'est pas arrêté. Les questions ouvertes incluent :

- joueurs habitués à Diplomacy et aux jeux de grande stratégie ;
- joueurs attirés par les jeux de négociation sociale ;
- observateurs et créateurs de contenu ;
- usage solo contre IA, multijoueur humain, ou mixte.

**[PROPOSITION]** Expérience visée :

- des décisions stratégiques lisibles mais profondes ;
- une diplomatie qui repose sur des engagements, des informations incomplètes et des retournements ;
- des IA crédibles, avec des styles distincts, sans être caricaturales ;
- des parties dont la durée et le rythme restent **à définir** (temps réel, tour par tour asynchrone, etc.).

**[HYPOTHÈSE]** Une partie asynchrone de type « play-by-email / web » réduirait la contrainte de latence des IA et faciliterait les parties longues. Cette hypothèse doit être testée avant tout choix d'architecture.

---

## 5. Inspirations et références

### 5.1 Inspiration validée

- **webDiplomacy** et le jeu de plateau **Diplomacy** : inspiration déclarée par le propriétaire.

### 5.2 Références proposées (non validées)

**[PROPOSITION]**

- Jeux de grande stratégie pour la profondeur des systèmes.
- Jeux de négociation et de rôle pour la dimension sociale.
- Travaux sur les agents conversationnels et la théorie des jeux pour la modélisation de la confiance et de la trahison.

Toute référence externe doit être documentée avec sa source et sa licence avant d'être utilisée comme base de règles, de carte ou d'assets. Aucune œuvre protégée ne doit être copiée sans vérification.

---

## 6. Principes fondamentaux du gameplay

**[VALIDÉ]** Les principes suivants sont imposés par le brief initial :

- stratégie, diplomatie et guerre sont au cœur du jeu ;
- les IA doivent pouvoir négocier, coopérer, manipuler, respecter ou trahir des traités ;
- les décisions doivent avoir des conséquences.

**[PROPOSITION]** Principes de conception recommandés :

1. **Information incomplète** : aucun joueur ne voit tout ; la diplomatie a de la valeur parce que l'information est imparfaite.
2. **Engagements traçables** : un traité, une promesse ou une trahison doivent laisser une trace exploitable par les autres acteurs.
3. **Résolution déterministe** : à ordres et graine identiques, le résultat doit être identique.
4. **Séparation règles / IA / interface** : les règles ne dépendent ni du modèle d'IA ni de l'affichage.
5. **Lisibilité** : le joueur doit pouvoir reconstituer ce qui s'est passé, même après une trahison.
6. **Temps de décision borné** : une IA ne doit jamais bloquer une partie indéfiniment.
7. **Pas de triche informationnelle** : une IA ne doit accéder qu'aux informations auxquelles un joueur de son rôle aurait droit.

**[À DÉFINIR]** Les règles précises (types d'ordres, résolution, conditions de victoire, tours, fog of war, économie) ne sont pas arrêtées. Voir [docs/gameplay/rules.md](docs/gameplay/rules.md).

---

## 7. Systèmes envisagés

| Système | Description | Document | Statut |
|---|---|---|---|
| Règles de base | Ordres, phases, résolution, victoire | [docs/gameplay/rules.md](docs/gameplay/rules.md) | Non conçu |
| Carte et territoires | Provinces, adjacences, centres, propriété | [docs/gameplay/map-system.md](docs/gameplay/map-system.md) | Non conçu |
| Système militaire | Unités, soutien, mouvement, attrition | [docs/gameplay/military-system.md](docs/gameplay/military-system.md) | Non conçu |
| Système économique | Ressources, production, coûts | [docs/gameplay/economy-system.md](docs/gameplay/economy-system.md) | **Existence non confirmée** |
| Traités | Types, cycle de vie, rupture | [docs/diplomacy/treaties.md](docs/diplomacy/treaties.md) | Non conçu |
| Négociations | Canaux, propositions, tours de parole | [docs/diplomacy/negotiations.md](docs/diplomacy/negotiations.md) | Non conçu |
| Alliances | Coalitions, coordination, victoire partagée | [docs/diplomacy/alliances.md](docs/diplomacy/alliances.md) | Non conçu |
| Réputation | Confiance, mémoire sociale, conséquences | [docs/diplomacy/reputation.md](docs/diplomacy/reputation.md) | Non conçu |
| Architecture IA | Perception, décision, action, évaluation | [docs/artificial-intelligence/ai-architecture.md](docs/artificial-intelligence/ai-architecture.md) | Non conçu |
| Personnalités IA | Traits, cohérence, diversité | [docs/artificial-intelligence/personalities.md](docs/artificial-intelligence/personalities.md) | Non conçu |
| Mémoire IA | Mémoire épisodique, sociale, résumé | [docs/artificial-intelligence/memory-system.md](docs/artificial-intelligence/memory-system.md) | Non conçu |
| Décision IA | Planification, utility, LLM, validation | [docs/artificial-intelligence/decision-making.md](docs/artificial-intelligence/decision-making.md) | Non conçu |
| Interactions multi-agents | Protocole, coalitions, sécurité | [docs/artificial-intelligence/multi-agent-interactions.md](docs/artificial-intelligence/multi-agent-interactions.md) | Non conçu |

**[PROPOSITION]** Systèmes transverses à prévoir : journal d'événements, configuration, sauvegarde/rechargement, observabilité, modération, rejouabilité, accessibilité, localisation. Ils ne sont pas encore spécifiés.

---

## 8. Architecture technique

**[À DÉFINIR]** Aucune architecture technique n'est validée. Voir [docs/architecture/overview.md](docs/architecture/overview.md) pour la décomposition logique **proposée** et [docs/architecture/technical-decisions.md](docs/architecture/technical-decisions.md) pour les choix ouverts.

**[PROPOSITION]** Séparation logique en couches :

1. **Noyau de règles** : état du jeu, validation et résolution des ordres ; pur, déterministe, sans IA ni interface.
2. **Modèle de données / persistance** : sauvegarde, rechargement, journal d'événements.
3. **Couche diplomatique** : messages, propositions, traités, réputation.
4. **Couche IA** : perception filtrée, mémoire, décision, génération de messages et d'ordres.
5. **Interface / API** : accès joueurs humains, IA, observateurs.
6. **Outillage** : tests, simulation, évaluation des IA, administration.

**[HYPOTHÈSE]** Un noyau déterministe et un journal d'événements append-only faciliteraient les tests, la rejouabilité et l'audit des IA. À valider par une étude et éventuellement un prototype.

Aucun framework, moteur de jeu, langage ou base de données n'est choisi. Toute sélection devra faire l'objet d'un ADR.

---

## 9. Technologies utilisées

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

**Contrainte validée :** ne pas choisir de framework ou de moteur graphique sans étude préalable (voir ADR-0003).

---

## 10. Contraintes techniques

### 10.1 Contraintes validées

- Développement multi-agents avec des outils hétérogènes.
- Documentation lisible par tous les agents, sans dépendance à une conversation passée.
- Git comme source de vérité.
- Aucune clé API ni secret dans le dépôt.
- Aucune décision technique irréversible sans justification.

### 10.2 Contraintes proposées / à étudier

**[PROPOSITION]**

- Le moteur de règles doit pouvoir tourner sans interface graphique (tests, simulations, évaluation).
- Les IA doivent être isolées du noyau : le noyau ne doit pas dépendre d'un fournisseur de LLM.
- Une partie doit pouvoir être sauvegardée, rechargée et rejouée.
- Les messages entre agents doivent être traités comme des entrées non fiables (risque d'injection de prompt).
- Le coût et la latence des appels LLM doivent être bornés et mesurés.
- Le système doit fonctionner avec des modèles locaux ou distants, si possible.

**[À DÉFINIR]** Budget de latence, coût par partie, nombre de joueurs, taille de carte, durée de partie, plateforme, contraintes de conformité (RGPD, données de joueurs, contenus générés).

---

## 11. Décisions déjà prises

### 11.1 Décisions du propriétaire (validées)

| ID | Décision | Source |
|---|---|---|
| D-001 | Le jeu est un jeu de stratégie, diplomatie et guerre inspiré de webDiplomacy. | Brief initial |
| D-002 | Les IA doivent être autonomes, réalistes, capables de négocier, coopérer, manipuler, respecter des traités et trahir intelligemment. | Brief initial |
| D-003 | Le développement est multi-agents (OpenCode, Codex, Claude Code, éventuellement autres). | Brief initial |
| D-004 | La documentation de référence est centrale et doit permettre la reprise sans conversation préalable. | Brief initial |
| D-005 | Aucun moteur, framework ou langage ne doit être choisi sans étude préalable. | Brief initial |
| D-006 | Cette phase ne doit pas commencer le développement du jeu. | Brief initial |
| D-007 | Git est la source de vérité ; les commits ne doivent pas écraser un travail préexistant. | Brief initial |
| D-008 | Les secrets et clés API sont interdits dans le dépôt ; `.env.example` documente les variables. | Brief initial |

### 11.2 Décisions d'infrastructure prises par OpenCode (délégation limitée, réversibles)

| ID | Décision | ADR | Portée |
|---|---|---|---|
| I-001 | Documentation de référence + Git comme socle de collaboration. | [ADR-0001](docs/decisions/0001-documentation-et-git-comme-socle.md) | Structurante, validée par le brief |
| I-002 | `AGENTS.md` est l'unique constitution ; `CLAUDE.md` n'est qu'un pointeur. | [ADR-0002](docs/decisions/0002-interoperabilite-multi-agents.md) | Réversible |
| I-003 | Report de tout choix de pile technique jusqu'à étude et ADR. | [ADR-0003](docs/decisions/0003-report-du-choix-de-pile-technique.md) | Réversible, contrainte du propriétaire |

Ces décisions d'infrastructure ne préjugent pas des choix de game design ou de technologie. Elles peuvent être remplacées par un ADR ultérieur.

### 11.3 Propositions (non validées)

- Architecture logique en couches (noyau de règles isolé, IA derrière un contrat).
- Journal d'événements append-only.
- Moteur déterministe et rejouable.
- Séparation stricte entre information accessible aux IA et état réel.
- Format de carte déclaratif et versionné.

---

## 12. Questions encore ouvertes

| ID | Question | Impact | Statut |
|---|---|---|---|
| Q-001 | Quel est le nom officiel du projet ? | Identité, communication | Ouverte |
| Q-002 | Quel est le périmètre exact du MVP ? | Priorisation | **Bloquante** |
| Q-003 | Le jeu reprend-il les règles exactes de Diplomacy ou s'en inspire-t-il librement ? | Game design, juridique | **Bloquante** |
| Q-004 | Combien de joueurs par partie ? | Carte, équilibrage | Haute |
| Q-005 | Partie en temps réel, tour par tour, asynchrone ou hybride ? | Architecture, IA | **Bloquante** |
| Q-006 | Solo contre IA, multijoueur humain, ou mixte ? | Produit, architecture | Haute |
| Q-007 | Quelle plateforme (web, desktop, mobile) ? | Stack, UI | Haute |
| Q-008 | Quel langage et quel moteur ? | Tout le développement | **Bloquante** (étude requise) |
| Q-009 | Quel modèle de persistance et de sauvegarde ? | Architecture | Haute |
| Q-010 | Quels fournisseurs de LLM, avec quels coûts et quelles limites ? | IA, budget | Haute |
| Q-011 | Les IA peuvent-elles utiliser des modèles locaux ? | Coût, confidentialité | Moyenne |
| Q-012 | Comment garantir qu'une IA ne triche pas informationnellement ? | Équité, architecture | **Bloquante** pour l'IA |
| Q-013 | Quel niveau de fog of war ? | Règles, IA | Haute |
| Q-014 | Quelles conditions de victoire ? | Règles | Haute |
| Q-015 | Y a-t-il une économie ? | Game design | Moyenne |
| Q-016 | Les traités sont-ils contraignants mécaniquement ou seulement socialement ? | Diplomatie, IA | Haute |
| Q-017 | Quelle durée de partie cible ? | Rythme, IA | Moyenne |
| Q-018 | Le jeu doit-il être moddable ? | Architecture | Basse |
| Q-019 | Quelles langues sont supportées ? | i18n | Basse |
| Q-020 | Quelle licence pour le code et les assets ? | Juridique, dépendances | **Bloquante** avant publication |
| Q-021 | Quel niveau d'accessibilité est visé ? | UI | Basse |
| Q-022 | Comment évaluer objectivement la qualité des IA ? | Tests, produit | Haute |
| Q-023 | Quel est le budget d'infrastructure et d'API ? | Choix techniques | Haute |
| Q-024 | Quelles données de joueurs sont collectées et conservées ? | RGPD, sécurité | Haute |
| Q-025 | Qui est le propriétaire formel du projet et quel est le canal d'arbitrage ? | Gouvernance, validation | Haute |

Les questions sont détaillées dans les documents thématiques. Elles ne doivent pas être tranchées par un agent seul.

---

## 13. Fonctionnalités envisagées à long terme

**[PROPOSITION]** Liste non priorisée et non validée :

- cartes multiples et éditeur de carte ;
- personnalités d'IA variées, avec mémoire inter-parties ;
- traités multi-clauses, renégociation, clauses secrètes ;
- réputation persistante et conséquences sociales ;
- modes spectateur, replay et analyse de partie ;
- tournois et classements ;
- multijoueur asynchrone ;
- modding et contenu communautaire ;
- localisation ;
- observabilité et outils d'administration ;
- évaluation automatisée des IA par scénarios.

**[VALIDÉ]** Aucune de ces fonctionnalités n'est engagée. Elles ne doivent pas être présentées comme planifiées avant validation et priorisation.

---

## Historique de ce document

| Date | Agent | Modification |
|---|---|---|
| 2026-10-31 | OpenCode | Création initiale à partir du brief du propriétaire. |

Toute modification de ce document doit être cohérente avec [PROGRESS.md](PROGRESS.md), [AGENTS.md](AGENTS.md) et les ADR acceptés.
