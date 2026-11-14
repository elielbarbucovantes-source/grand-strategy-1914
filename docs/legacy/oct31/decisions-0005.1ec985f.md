# ADR-0005 — Intégration du temps stratégique et du temps tactique

> **Statut :** Proposé — **ne vaut pas décision**
> **Date :** 2026-10-31
> **Auteur :** OpenCode
> **Décideur :** Propriétaire du projet (arbitrage attendu)
> **Remplace :** aucun
> **Remplacé par :** aucun
> **Documents liés :** [design-review-v0.1.md](../design-review-v0.1.md) · [gameplay/rules.md](../gameplay/rules.md) · [military/strategic-warfare.md](../military/strategic-warfare.md) · [military/tactical-battles.md](../military/tactical-battles.md) · [architecture/overview.md](../architecture/overview.md)

---

## 1. Contexte

Le document fondateur v0.1 fixe deux échelles de temps incompatibles en apparence :

- **stratégique** : un tour = un mois, préparation puis résolution simultanée pour le monde entier (§ 5) ;
- **tactique** : une bataille indépendante, en temps réel, d'une durée maximale de 30 minutes, avec contrôle direct des unités (§ 8.3).

Il ne précise pas comment ces deux échelles s'articulent. La revue de conception identifie les tensions **C-01** (moment de la bataille), **C-02** (batailles simultanées), **C-04** (offensive immédiate), **C-15** (sauvegarde/replay) et **C-17** (multijoueur).

## 2. Problème à résoudre

Comment permettre à un joueur de mener des batailles tactiques de 30 minutes sans casser :

- la résolution mensuelle simultanée ;
- l'équité entre joueurs présents et absents ;
- la possibilité de sauvegarder et rejouer ;
- l'anticipation du multijoueur ;
- l'interdiction des généraux et du moral (§ 8.6) ?

## 3. Solutions envisagées

### Option A — Bataille « hors calendrier », résultat imputé au tour courant

La bataille s'ouvre après validation des ordres stratégiques. Le calendrier stratégique est suspendu pour les participants ; les autres nations ne peuvent pas agir pendant la bataille. Le résultat est appliqué au tour en cours.

- **Avantages :** séparation claire des échelles ; le tour mensuel reste l'unité de résolution ; le temps réel est préservé.
- **Inconvénients :** un joueur absent peut bloquer ; il faut un timeout et un mode automatique ; les autres joueurs attendent.
- **Réversibilité :** moyenne.
- **Verdict :** compatible avec le document, mais nécessite des règles de timeout.

### Option B — Bataille asynchrone par rounds

La bataille est découpée en rounds ; chaque round est un échange d'ordres avec une minuterie longue. Les « 30 minutes » deviennent un budget de temps de décision cumulé.

- **Avantages :** compatible avec le jeu asynchrone et les sauvegardes ; pas de blocage par absence.
- **Inconvénients :** s'éloigne du temps réel de Lines of Battle ; change l'expérience.
- **Réversibilité :** élevée.
- **Verdict :** possible, mais contredit l'intention « temps réel » si elle est stricte.

### Option C — Bataille temps réel planifiée à un créneau

La bataille a lieu à un horaire convenu ; le tour ne se résout pas avant.

- **Avantages :** tension dramatique, synchronisation claire.
- **Inconvénients :** contrainte d'horaire forte ; difficile en solo et en asynchrone.
- **Réversibilité :** faible.
- **Verdict :** peu adapté à la cible solo.

### Option D — Résolution automatique optionnelle

Le joueur peut déléguer la bataille à une résolution automatique déterministe ; le temps réel reste une option.

- **Avantages :** évite les blocages ; respecte les absences ; permet de tester le système.
- **Inconvénients :** nécessite un modèle de résolution automatique et une IA tactique ; risque de déséquilibre entre joueurs qui jouent et ceux qui délèguent.
- **Réversibilité :** élevée.
- **Verdict :** utile comme **complément** à A ou B.

### Option E — File d'attente des batailles

Une seule bataille active par joueur ; les autres sont résolues automatiquement ou mises en attente.

- **Avantages :** protège l'attention du joueur.
- **Inconvénients :** peut retarder la résolution ; nécessite une priorisation.
- **Réversibilité :** élevée.
- **Verdict :** nécessaire si plusieurs batailles sont possibles.

## 4. Solution retenue

**Aucune.** Cet ADR est à l'état `proposé`.

**Recommandation d'agent (non validée) :** combiner **A + D + E** :

1. les ordres stratégiques sont verrouillés puis résolus ;
2. les batailles sont ouvertes dans l'ordre de priorité définie par les ordres ;
3. une seule bataille active par joueur ;
4. un timeout et une résolution automatique déterministe existent ;
5. le résultat s'impute au tour courant ;
6. aucune bataille ne peut modifier les ordres stratégiques déjà résolus.

Cette recommandation ne devient une décision qu'après validation du propriétaire.

## 5. Justification (de la proposition)

- Préserve l'unité de temps mensuelle décidée.
- Évite qu'un joueur doive commander plusieurs batailles en parallèle.
- Ne crée ni généraux ni moral.
- Permet de sauvegarder avant/après bataille et de rejouer les commandes.
- Laisse le multijoueur possible si le moteur de bataille est isolé.

## 6. Conséquences

### Positives (si acceptée)

- Règles temporelles explicites.
- Moins de blocages.
- Meilleure testabilité.

### Négatives / coûts (si acceptée)

- Développement d'une résolution automatique.
- Règles de priorité à équilibrer.
- Risque de frustration si la bataille automatique est perçue comme injuste.

### Impacts sur les documents et le code

- `docs/gameplay/rules.md` : phases et verrouillage.
- `docs/military/tactical-battles.md` : ouverture, timeout, résultat.
- `docs/architecture/overview.md` : moteur de bataille séparé.
- `docs/architecture/technical-decisions.md` : TD-021 à TD-024.
- Aucun code tant que l'ADR n'est pas accepté.

## 7. État

`proposé`. **Ne vaut pas décision.** Le propriétaire doit arbitrer C-01, C-02, C-04, C-15 et C-17 dans [design-review-v0.1.md](../design-review-v0.1.md).

## 8. Suivi

- [x] Options documentées
- [x] Tensions reliées
- [ ] Arbitrage du propriétaire
- [ ] Mise à jour des documents impactés
- [ ] Index mis à jour

## 9. Références

- [Document fondateur v0.1 § 5 et § 8](../founding-document-v0.1.md)
- [Revue de conception v0.1](../design-review-v0.1.md)
- [ADR-0003 — report du choix de pile](0003-report-du-choix-de-pile-technique.md)
