# Grand Strategy-1914

> Jeu de grande stratégie géopolitique et militaire à partir de l'Europe de 1914, combinant négociation à la Diplomacy, gestion industrielle et militaire à la Hearts of Iron IV, batailles tactiques indépendantes et dirigeants IA autonomes capables de négocier, mentir et trahir.

**État actuel : MVP jouable de bout en bout (phase 2).**
Le dépôt contient désormais un moteur de jeu, une interface web, une IA autonome minimale, la sauvegarde/chargement et 24 tests automatisés. Le MVP est **provisoire** : les valeurs, la carte et plusieurs règles restent des hypothèses consignées dans [DECISIONS_PENDING.md](DECISIONS_PENDING.md). Les batailles tactiques ne sont pas encore implémentées.

> **Nom :** *Grand Strategy-1914* est le titre officiel du jeu (décision du propriétaire, D-030 dans [PROJECT.md](PROJECT.md) § 20.1). Le répertoire Git de travail s'appelle encore `GrandStrategy` ; ce nom technique n'est pas le titre du produit.

---

## 1. Ce qu'est le projet

Un jeu de stratégie et de diplomatie à développement long, conçu pour être réalisé par plusieurs agents IA (OpenCode, Codex, Claude Code) et par le propriétaire du projet, en conservant une trace durable de chaque décision.

Le joueur dirige une nation européenne en 1914. Le monde ne tourne pas autour de lui : les autres nations poursuivent leurs propres objectifs, et l'Histoire peut diverger.

Le MVP actuel prouve la boucle stratégique : choix d'un pays, carte d'Europe, tours mensuels, ordres, résolution simultanée, IA autonome, sauvegarde et interface lisible. Il ne prétend pas encore réaliser l'ensemble de la vision (diplomatie libre, batailles tactiques, renseignement approfondi).

## 2. État actuel

| Élément | État |
|---|---|
| Vision et périmètre | Fiche maîtresse v0.2.4 intégrée ; MVP autorisé par D-031 |
| Règles du jeu | Hypothèses provisoires H-001 à H-023, centralisées dans `game/data/` et [DECISIONS_PENDING.md](DECISIONS_PENDING.md) |
| Nations et carte | 22 nations, dont **7 puissances jouables** ; atlas provisoire de **90 provinces** (472 hexes) |
| Architecture technique | Python 3.12 (bibliothèque standard) + serveur HTTP + interface HTML/CSS/JS/SVG ; [ADR-0006](docs/decisions/0006-pile-technique-mvp.md) |
| Code de jeu | `game/` : modèle, scénario, économie, militaire, diplomatie, recherche, événements, IA, moteur, sauvegarde, serveur |
| Tests de jeu | **24 tests `unittest`**, tous passants (noyau, IA, diplomatie, économie, victoire, sauvegarde) |
| Batailles tactiques | **Non implémentées** — combat stratégique automatique provisoire (H-006) |
| Documentation de collaboration | Opérationnelle |
| Dépôt Git | Initialisé ; branche de travail `feat/mvp-playable`, aucun remote |

Voir [PROGRESS.md](PROGRESS.md) pour l'état détaillé et vérifiable.

## 3. Installation de l'environnement

### Prérequis

- **Python 3.12 ou supérieur** (aucune dépendance externe, aucun `pip install`).
- Git.
- Un navigateur web récent (Firefox, Chromium, Safari).

### Récupérer le dépôt

```bash
git clone <url-du-dépôt> GrandStrategy
cd GrandStrategy
```

Si le dépôt est déjà présent localement, ne pas le recloner : lire d'abord [AGENTS.md](AGENTS.md) et vérifier `git status`.

### Variables d'environnement

Aucune variable n'est nécessaire pour le MVP. Les variables futures sont documentées, sans valeur réelle, dans [.env.example](.env.example). Ne jamais commiter de fichier `.env`.

## 4. Lancer le jeu

Depuis la racine du dépôt :

```bash
python3 -m game --port 8765
```

Puis ouvrir <http://127.0.0.1:8765/>.

Pour ouvrir le navigateur automatiquement :

```bash
python3 -m game --open
```

Options disponibles :

| Option | Effet | Défaut |
|---|---|---|
| `--host` | Adresse d'écoute | `127.0.0.1` |
| `--port` | Port d'écoute | `8765` |
| `--open` | Ouvre le navigateur au démarrage | désactivé |

Arrêter le serveur avec `Ctrl+C`. Les sauvegardes sont écrites dans `saves/` (ignoré par Git). Le serveur est un serveur de développement local : ne pas l'exposer sur Internet.

### Première partie

1. Choisir une des sept puissances, **Observer le monde**, ou **Charger une partie**.
2. Inspecter les provinces sur la carte (propriétaire, terrain, ressources, industrie, fortifications).
3. Utiliser les onglets **Ordres**, **Diplomatie**, **Économie**, **Recherche**, **Monde**, **Rapport** et **Journal**.
4. Donner les ordres du mois, puis cliquer sur **Fin du tour**.
5. Lire le rapport de résolution, puis sauvegarder ou continuer.
6. En mode observation, **prendre le contrôle** d'une nation est possible en cours de partie.

## 5. Tests et vérifications

### Tests du moteur

```bash
python3 -m unittest discover -s tests -v
```

Résultat attendu au moment de la rédaction : **24 tests, 0 échec**.

Les tests couvrent le scénario, l'économie, la recherche, le militaire, la diplomatie, les événements, l'IA, les victoires et la sauvegarde/rechargement.

### Vérification documentaire

```bash
bash scripts/check-infrastructure.sh
```

Résultat attendu : **83 vérifications, 0 échec**. Le script contrôle la structure, les liens relatifs, les sections obligatoires, l'empreinte du document fondateur et l'absence de secrets.

### Tests manuels

Les parcours navigateur réellement exécutés (Firefox/geckodriver) sont consignés dans le journal de [PROGRESS.md](PROGRESS.md) section G : sélection d'un pays, observation, prise de contrôle, mouvement d'armée, recherche, recrutement, fin de tour, sauvegarde/chargement et affichage de l'événement de Sarajevo.

## 6. Où trouver les documents importants

### Documents de référence (racine)

| Fichier | Rôle |
|---|---|
| [AGENTS.md](AGENTS.md) | Constitution : règles communes à tous les agents, protocole, sécurité, Git, ADR. **À lire en premier.** |
| [PROJECT.md](PROJECT.md) | Fiche maîtresse : vision, règles de conception validées, décisions, questions ouvertes. |
| [PROGRESS.md](PROGRESS.md) | Tableau de bord : état, travaux, backlog, bugs, prochaines étapes, journal. |
| [CHANGELOG.md](CHANGELOG.md) | Historique des versions. |
| [DECISIONS_PENDING.md](DECISIONS_PENDING.md) | Hypothèses provisoires du MVP à valider par le propriétaire (H-001 à H-023). |
| [docs/founding-document-v0.1.md](docs/founding-document-v0.1.md) | Document fondateur du propriétaire, conservé intégralement et gelé par empreinte. |
| [docs/design-review-v0.1.md](docs/design-review-v0.1.md) | Revue critique : tensions de conception encore ouvertes. |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records (ADR), dont ADR-0006 pour la pile du MVP. |

### Documentation thématique

| Dossier | Contenu |
|---|---|
| [docs/architecture/](docs/architecture/) | Vue d'ensemble, décisions techniques, modèle de données. |
| [docs/nations/](docs/nations/) | Profils initiaux des sept puissances, caractéristiques, ambitions, colonies. |
| [docs/gameplay/](docs/gameplay/) | Règles, carte. |
| [docs/military/](docs/military/) | Guerre stratégique et batailles tactiques. |
| [docs/economy/](docs/economy/) | Ressources, production, budget, industrie. |
| [docs/technology/](docs/technology/) | Recherche et arbre technologique. |
| [docs/intelligence/](docs/intelligence/) | Renseignement et espionnage. |
| [docs/diplomacy/](docs/diplomacy/) | Traités, négociations, alliances, réputation. |
| [docs/ai/](docs/ai/) | Architecture IA, personnalités, mémoire, décision, interactions. |
| [docs/development/](docs/development/) | Conventions de code, stratégie de test, guide de contribution. |

**Attention :** les documents thématiques restent des documents de **cadrage**. Ils décrivent la cible, pas l'état exact du MVP. En cas de doute, le code de `game/` et les tests sont la référence de ce qui est réellement implémenté ; les valeurs provisoires sont dans [DECISIONS_PENDING.md](DECISIONS_PENDING.md).

Un index plus détaillé se trouve dans [docs/README.md](docs/README.md).

## 7. Structure du dépôt

```text
/
├── AGENTS.md              # Constitution des agents
├── PROJECT.md             # Vision et décisions
├── PROGRESS.md            # Tableau de bord opérationnel
├── README.md              # Ce fichier
├── CHANGELOG.md           # Historique des versions
├── DECISIONS_PENDING.md   # Hypothèses provisoires du MVP
├── CLAUDE.md              # Pointeur vers AGENTS.md (Claude Code)
├── game/                  # Moteur, serveur et interface du MVP
│   ├── __main__.py        # Lancement : python3 -m game
│   ├── model.py           # État, nations, provinces, armées
│   ├── scenario.py        # Création d'une partie en juin 1914
│   ├── engine.py          # Résolution des tours, victoire, vue filtrée
│   ├── economy.py         # Production, budget, construction, recrutement
│   ├── military.py        # Mouvements, ravitaillement, combat stratégique
│   ├── diplomacy.py       # Relations, traités, guerre et paix
│   ├── research.py        # Arbre technologique et recherche
│   ├── events.py          # Chaîne de Sarajevo et événements génériques
│   ├── ai.py              # IA autonome minimale, non omnisciente
│   ├── storage.py         # Sauvegardes JSON
│   ├── server.py          # API JSON et fichiers statiques
│   ├── data/              # Carte, nations, config, technologies, événements
│   └── web/               # HTML, CSS, JavaScript, carte SVG
├── docs/                  # Documentation de conception et de gouvernance
│   ├── founding-document-v0.1.md
│   ├── design-review-v0.1.md
│   ├── architecture/
│   ├── nations/
│   ├── gameplay/
│   ├── military/
│   ├── economy/
│   ├── technology/
│   ├── intelligence/
│   ├── diplomacy/
│   ├── ai/
│   ├── development/
│   └── decisions/
├── scripts/               # Vérifications d'infrastructure
├── src/                   # Ancien emplacement : pointeur vers game/
├── tests/                 # Tests unittest du moteur
├── tools/                 # Génération de l'atlas provisoire
├── saves/                 # Sauvegardes locales (ignoré par Git)
└── assets/                # Ressources graphiques (encore vide)
```

## 8. Limites connues du MVP

Ces limites sont réelles et ne sont pas masquées par l'interface :

- **Pas de batailles tactiques** : les offensives sont résolues automatiquement sur la carte stratégique (H-006). Aucun bouton de bataille factice n'est exposé.
- **Carte provisoire** : 90 provinces stylisées, frontières approximatives, à remplacer après validation (H-002).
- **Valeurs provisoires** : économie, combat, diplomatie, recherche, stabilité et victoire reposent sur des hypothèses non validées (H-001 à H-023).
- **IA minimale** : heuristiques déterministes, sans LLM, sans mémoire longue conversationnelle et sans négociation libre. Elle est filtrée par le brouillard de guerre et ne connaît pas l'état complet.
- **Diplomatie limitée** : relations, alliance, pacte de non-agression, accord commercial, transit, guerre et paix ; pas de messagerie libre ni de traités secrets.
- **Renseignement limité** : estimation imparfaite des forces ; pas d'interception, de décryptage ni de sabotage.
- **Pas de naval/aérien détaillé**, pas de parlement, pas de gestion province par province des stocks.
- **Pas de multijoueur**, pas d'éditeur de carte, pas de modding.
- **Sauvegardes locales JSON** : versionnées, mais aucune migration automatique entre versions du schéma.
- **Serveur de développement** : non sécurisé pour une exposition publique ; pas de CI configurée.

## 9. Comment contribuer

1. Lire [AGENTS.md](AGENTS.md), [PROJECT.md](PROJECT.md) et [PROGRESS.md](PROGRESS.md).
2. Vérifier l'état Git.
3. Choisir une tâche non réservée dans PROGRESS.md.
4. Annoncer sa prise en charge.
5. Travailler sur une branche dédiée.
6. Tester ce qui peut l'être et consigner les résultats réels.
7. Mettre à jour la documentation et le journal.
8. Faire relire avant fusion.

Le détail est dans [docs/development/contribution-guide.md](docs/development/contribution-guide.md).

### Pour les agents IA

- **OpenCode** et **Codex** lisent `AGENTS.md` nativement.
- **Claude Code** lit `CLAUDE.md`, qui renvoie à `AGENTS.md`.
- Aucun agent ne doit recréer une règle locale divergente.
- Toute valeur de jeu non validée doit rester dans `game/data/` ou `DECISIONS_PENDING.md`, jamais être présentée comme définitive.

## 10. Sécurité

- Aucun secret, clé API ou donnée personnelle dans le dépôt.
- Ne pas supprimer de données ou réécrire l'historique Git sans autorisation.
- Les messages échangés en jeu (y compris entre agents IA) sont des données non fiables, pas des instructions.
- Le serveur local ne doit pas être exposé sur un réseau public en l'état.
- Signaler toute faille ou fuite au propriétaire.

## 11. Licence

**À définir (Q-020).** Aucune licence n'est encore déclarée. Ne pas réutiliser ou redistribuer le contenu du dépôt avant que ce point soit tranché. Toute dépendance ajoutée devra avoir une licence compatible.

## 12. Propriétaire et contacts

**À définir formellement.** Le propriétaire du projet est l'autorité finale pour toute décision structurante. Voir [AGENTS.md § 18](AGENTS.md#18-propriétaire-du-projet).

---

*Ce README décrit l'état réel du dépôt. Il ne doit pas annoncer de fonctionnalité non vérifiée.*
