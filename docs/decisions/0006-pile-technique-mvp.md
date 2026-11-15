# ADR-0006 — Pile technique du premier MVP jouable

> **Statut :** accepté (délégation technique du propriétaire, 2026-10-31)
> **Statut mis à jour le 2026-11-15 : REMPLACÉ par [ADR-0007](0007-moteur-godot.md)** (décision du directeur ; contenu d'origine inchangé).
> **Date :** 2026-11-01
> **Auteur :** OpenCode
> **Décideur :** propriétaire du projet, par la consigne d'exécution du 2026-10-31 (« décide toi-même de l'architecture, des bibliothèques, de l'organisation du code, des tests »)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [PROJECT.md](../../PROJECT.md) · [PROGRESS.md](../../PROGRESS.md) · [DECISIONS_PENDING.md](../../DECISIONS_PENDING.md) · [technical-decisions.md](../architecture/technical-decisions.md) · [overview.md](../architecture/overview.md)

---

## 1. Contexte

Le projet était bloqué en phase de conception. Le propriétaire a demandé, le 2026-10-31, une première version jouable de bout en bout : lancement, carte européenne de 1914, choix d'un pays, tour mensuel, ordres, résolution simultanée, IA autonome minimale, sauvegarde/chargement et interface lisible. Il a explicitement délégué les choix techniques ordinaires.

Le dépôt ne contenait aucun code exécutable. Les contraintes structurantes déjà validées sont : noyau de règles séparé de l'interface et des IA, résolution déterministe, sauvegarde/rechargement, architecture compatible avec un multijoueur futur, aucune dépendance inutile, données numériques non validées centralisées.

## 2. Problème à résoudre

Choisir une pile permettant de livrer rapidement un MVP jouable, testable hors interface, sans installer de chaîne de build lourde ni créer une dette qui empêcherait les évolutions prévues (batailles tactiques, multijoueur, modding).

## 3. Solutions envisagées

### Option A — Python 3 (bibliothèque standard) + interface web HTML/CSS/JS + SVG

- **Description :** moteur et serveur HTTP en Python 3.12 sans dépendance externe ; interface servie par le même processus ; carte et composants en SVG/DOM ; sauvegardes JSON ; tests avec `unittest`.
- **Avantages :** zéro installation, démarrage immédiat, noyau testable sans navigateur, sérialisation native, très bonne lisibilité du code de règles, aucun verrou de build.
- **Inconvénients :** interface moins structurée qu'un framework front ; pas de typage statique ; performances suffisantes pour un jeu au tour par tour mais pas pour un rendu massif.
- **Coût / effort :** faible à moyen.
- **Risques :** dette front si l'interface devient très riche ; nécessité de discipline sur les contrats JSON.
- **Réversibilité :** bonne : le noyau Python peut être conservé si l'interface est remplacée ; les données sont séparées.

### Option B — TypeScript + Vite + React + serveur Node

- **Description :** moteur et interface en TypeScript, rendu SVG/Canvas, build Vite.
- **Avantages :** typage, écosystème riche, interface plus facile à structurer à long terme.
- **Inconvénients :** installation de dépendances, chaîne de build, surface d'attaque et maintenance plus grandes pour un MVP ; duplication possible des règles entre client et serveur.
- **Coût / effort :** moyen à élevé.
- **Risques :** dépendances nombreuses, temps passé sur l'outillage plutôt que sur le jeu.
- **Réversibilité :** moyenne.

### Option C — Moteur de jeu existant (Godot, Unity, moteur web)

- **Description :** utiliser un moteur généraliste pour la carte et les batailles.
- **Avantages :** rendu et interactions riches, batailles tactiques plus simples à prototyper.
- **Inconvénients :** dépendance lourde, courbe d'apprentissage, testabilité du noyau moins directe, choix prématuré alors que les règles tactiques ne sont pas tranchées.
- **Coût / effort :** élevé.
- **Risques :** enfermement technique avant validation des règles.
- **Réversibilité :** faible.

## 4. Solution retenue

**Option A.** Le MVP utilise :

- **Langage :** Python 3.12, bibliothèque standard uniquement.
- **Serveur :** `http.server.ThreadingHTTPServer` avec une petite API JSON et service de fichiers statiques.
- **Interface :** HTML, CSS et JavaScript natifs ; carte SVG générée à partir de données JSON ; aucun framework front.
- **Persistance :** sauvegardes JSON versionnées dans un répertoire de sauvegarde local ; aucune base de données.
- **Tests :** `unittest` de la bibliothèque standard ; tests du noyau indépendants du serveur et du navigateur.
- **Données :** fichiers JSON dans `game/data/`, valeurs provisoires centralisées et étiquetées.
- **Déterminisme :** graine explicite enregistrée dans la partie ; ordre de résolution stable ; pas d'itération sur des ensembles non ordonnés.

Sont explicitement **exclus** de cette décision : le choix définitif du moteur de bataille tactique, le transport multijoueur, la base de données de production, l'hébergement et les services LLM. Ces points restent ouverts et pourront faire l'objet d'ADR ultérieurs.

## 5. Justification

Le MVP doit d'abord prouver la boucle stratégique et l'autonomie des IA. Un noyau Python sans dépendance permet de tester ces règles immédiatement, sans que l'interface ou l'outillage ne masquent les problèmes de conception. L'interface web native suffit pour une carte SVG, des panneaux et des formulaires. La séparation moteur/interface est nette : le serveur expose un état filtré et des commandes, le navigateur ne contient aucune règle de jeu.

Le choix est réversible : si l'interface devient le goulot d'étranglement, elle peut être remplacée par un front TypeScript sans réécrire le moteur. Les données JSON et les contrats d'API sont les points de couplage.

## 6. Conséquences

### Positives

- Démarrage immédiat : `python3 -m game --port 8765` (ou `python3 -m game --open`).
- Aucun gestionnaire de paquets, aucune compilation.
- Tests rapides et déterministes.
- Code de règles lisible et modifiable par plusieurs agents.
- Sauvegardes inspectables et diffables.

### Négatives / coûts

- Interface native plus verbeuse qu'avec un framework.
- Absence de typage statique : les contrats JSON doivent être testés.
- Le serveur de développement n'est pas prévu pour une exposition publique.

### Neutrales

- Le nom du paquet est `game` ; le titre du produit reste **Grand Strategy-1914**.
- Le rendu cartographique est un atlas provisoire, pas la carte définitive.

### Impacts sur les documents et le code

- `docs/architecture/technical-decisions.md` : TD-001, TD-002, TD-003, TD-004, TD-005, TD-006, TD-011, TD-012, TD-016, TD-017, TD-025 passent de « ouvert » à « décidé pour le MVP » avec renvoi au présent ADR.
- `PROJECT.md` : ajout de D-031 (autorisation d'implémentation et délégation technique).
- `README.md` : commandes de lancement et de test.
- `PROGRESS.md` : phase 2, backlog d'implémentation, journal.
- `DECISIONS_PENDING.md` : hypothèses de gameplay à valider.

## 7. État

`accepté` pour le MVP. Les choix définitifs de moteur tactique, de multijoueur et d'hébergement restent ouverts.

## 8. Suivi

- [x] Index mis à jour
- [x] Documents impactés mis à jour
- [x] PROGRESS.md mis à jour
- [x] Validation du propriétaire : délégation explicite du 2026-10-31

## 9. Références

- [PROJECT.md](../../PROJECT.md) § 5, § 16, § 21
- [AGENTS.md](../../AGENTS.md) § 7, § 11, § 14
- [technical-decisions.md](../architecture/technical-decisions.md)
- [overview.md](../architecture/overview.md)
