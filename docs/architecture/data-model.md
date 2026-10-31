# Modèle de données — modèle conceptuel préliminaire

> **Statut :** Cadrage — aucun schéma validé, aucune base de données choisie
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 4, § 8, § 9, § 10, § 11, § 12 · [founding-document-v0.1.md](../founding-document-v0.1.md)
> **Documents liés :** [overview.md](overview.md) · [technical-decisions.md](technical-decisions.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../gameplay/map-system.md](../gameplay/map-system.md) · [../military/tactical-battles.md](../military/tactical-battles.md) · [../diplomacy/treaties.md](../diplomacy/treaties.md)

---

## 1. Objet et avertissement

Ce document décrit les **concepts** que le système devra probablement représenter. Il ne définit ni tables, ni types, ni format de sérialisation. Aucun schéma ne doit être implémenté avant validation des règles et d'un ADR de persistance.

**[PROPOSITION]** Les entités ci-dessous sont une base de discussion, pas un modèle arrêté.

## 2. Entités conceptuelles proposées

### 2.1 Partie et règles

| Entité | Rôle | Attributs envisagés (non contractuels) | Questions |
|---|---|---|---|
| `Game` | Une partie | identifiant, version des règles, graine, état, date courante, statut | Plusieurs parties par joueur ? Parties persistantes ? |
| `RuleSet` | Version des règles | identifiant, version, paramètres | Règles moddables (Q-018) ? |
| `Map` | Carte stratégique | identifiant, version, provinces, adjacences | Format ? Plusieurs cartes ? |
| `Province` | Province conquérable | nom, propriétaire, contrôleur, terrain, ressources, importance, infrastructures, fortifications, population éventuelle | Liste définitive (T-020) ? Population (C-18) ? |
| `Adjacency` | Liaison entre provinces | source, cible, type (terre/mer/côte), contraintes | Détroits ? Passages ? |
| `Event` | Événement du journal | type, acteurs, payload, séquence, date | Source de vérité ? |
| `Snapshot` | Sauvegarde | partie, version, état sérialisé, hash | Compatibilité ? |

### 2.2 Nations et politique

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `Nation` | Entité politique | nom, identifiant, régime, capitale, statut (jouable/IA/éliminée) | Pays non jouables ? |
| `Power` | Nation jouée ou contrôlée | identifiant, contrôleur (humain/IA), objectifs, relations | Nombre de joueurs ? |
| `Government` / `Regime` | Régime politique | type, stabilité, effets, conditions de changement | Liste des régimes (T-020) ? |
| `NationalObjective` | Objectif national | formulation, priorité, conditions, statut | Scripté ou généré (T-023) ? |
| `Player` | Joueur humain | identité, partie, rôle, nation contrôlée | Comptes ? Anonymat ? |
| `Controller` | Contrôleur d'une nation | humain, IA, observateur, remplaçant | Prise de contrôle en cours de partie (C-14) ? |

### 2.3 Économie et industrie

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `Resource` | Ressource | identifiant, nom, catégorie, stockable ou flux | Liste définitive (T-021) ? |
| `ResourceStock` | Stock d'une nation | nation, ressource, quantité, date | Plafonds ? |
| `Production` | Production par tour | province, ressource, niveau, multiplicateurs | Formule (T-021) ? |
| `Industry` | Capacité industrielle | nation ou province, usines, infrastructures, mobilisation | Agrégée ou localisée ? |
| `Budget` | Budget national | recettes, dépenses, catégories, dette | Catégories ? |
| `TradeAgreement` | Accord économique | parties, ressources, conditions, statut | Mécanique ou confiance (D-009) ? |
| `QualityOfLife` | Niveau de vie | nation, indicateur, valeur, date | Indicateur et seuil (C-07) ? |
| `Population` | Population | province ou nation, effectif, croissance, conscription | Modélisée ou non (C-18) ? |

### 2.4 Militaire

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `Formation` | Formation stratégique | type, propriétaire, position, effectif, équipement, état | Unités et tailles (T-024) ? |
| `Unit` | Unité militaire | type, formation, effectif, équipement, état | Stacking ? |
| `Front` | Front statique | provinces, camps, pression, pertes | Représentation (T-024) ? |
| `Offensive` | Offensive | origine, cible, forces, date, statut | Une par mois (C-04) ? |
| `Fortification` | Fortification | province, niveau, état, technologies | Coûts et effets (D-017) ? |
| `Battle` | Bataille tactique | participants, forces converties, terrain, fortifications, statut, résultat | Moment d'ouverture (C-01) ? |
| `BattleSession` | Session temps réel | bataille, timer, participants, commandes, résultat, replay | Sauvegarde et pause (C-15) ? |
| `ForceConversion` | Table de conversion | type stratégique, points tactiques, pertes | Coefficients (C-03) ? |
| `Loss` | Pertes | bataille, camp, unité, effectif, équipement | Conversion et remplacement ? |

### 2.5 Recherche et renseignement

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `Technology` | Technologie | identifiant, branche, prérequis, coût, effets, date historique | Arbre (T-025) ? |
| `ResearchProject` | Recherche en cours | nation, technologie, avancement, coût, statut | Projets simultanés ? |
| `NationalSpecialization` | Spécialisation | nation, branche, bonus, évolution | Liste (T-020) ? |
| `IntelMission` | Mission de renseignement | nation, cible, type, coût, statut | Missions v1 ? |
| `Interception` | Interception | intercepteur, cible, message, date, détection | Portée et détection (C-05/C-11) ? |
| `IntelReport` | Rapport | nation, contenu, source, fiabilité, date | Fréquence et format ? |

### 2.6 Diplomatie

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `Channel` | Canal de communication | type (public/privé/groupe/officiel/secret), membres | Permissions ? |
| `Message` | Message diplomatique | expéditeur, destinataires, contenu, canal, horodatage, accès | Interception ? Rétention ? |
| `Proposal` | Proposition diplomatique | auteur, type, clauses, échéance, statut | Clauses structurées ? |
| `Treaty` | Accord | parties, clauses, catégorie (contraignant/confiance), durée, statut, historique | Sanctions ? |
| `Commitment` | Promesse / engagement | auteur, contenu, contexte, statut | Distinct d'un traité ? |
| `Relation` | Relation bilatérale | source, cible, état (amitié/neutralité/hostilité), date | Évolution ? |
| `Reputation` | Réputation | cible, source, dimension, valeur, date | Globale ou par acteur ? |
| `Crisis` | Crise internationale | participants, cause, phase, issue | Gestion (T-022) ? |

### 2.7 IA

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `AIPersonality` | Profil d'IA | traits, objectifs, style, seed | Généré ou écrit ? |
| `AIMemory` | Mémoire d'une IA | type, contenu, importance, date, accès | Rétention ? |
| `Perception` | Vue filtrée | acteur, contenu, date, source | Étanchéité (Q-012) ? |
| `Plan` | Plan d'une IA | objectifs, étapes, révision, statut | Format ? |
| `AIDecision` | Décision tracée | acteur, contexte, options, choix, justification | Audit ? |

### 2.8 Victoire et fin de partie

| Entité | Rôle | Attributs envisagés | Questions |
|---|---|---|---|
| `VictoryCondition` | Condition de victoire | type (territoriale/diplomatique/économique), seuil, portée | Seuils (C-08) ? |
| `VictoryProgress` | Progression | nation ou coalition, condition, valeur, date | Calcul ? |
| `Elimination` | Élimination | nation, date, cause, remplaçant éventuel | Retour (C-08) ? |

## 3. Relations principales (proposées)

```
Game 1 ── * Nation
Game 1 ── 1 Map
Game 1 ── 1 RuleSet
Map  1 ── * Province
Province 1 ── * Adjacency
Nation 1 ── * Formation
Formation 1 ── * Unit
Nation 1 ── * Order
Nation 1 ── * ResourceStock
Nation 1 ── 0..1 Industry
Nation 1 ── 1 Budget
Nation 1 ── 0..1 AIPersonality
Nation 1 ── * AIMemory
Nation 1 ── * Reputation (en tant que cible)
Game 1 ── * Offensive
Offensive 1 ── 0..1 Battle
Battle 1 ── 1 BattleSession
Battle 1 ── * Loss
Nation 1 ── * ResearchProject
ResearchProject * ── 1 Technology
Nation 1 ── * IntelMission
IntelMission 1 ── * IntelReport
Game 1 ── * Channel
Channel 1 ── * Message
Message 1 ── * Proposal
Proposal 1 ── 0..1 Treaty
Game 1 ── * Event
Game 1 ── * Snapshot
```

Ces cardinalités sont indicatives. Par exemple, un message peut concerner plusieurs traités, et une réputation peut être agrégée.

## 4. Invariants potentiels

À valider avant implémentation :

1. Un ordre appartient à un acteur et à une phase précise.
2. Un acteur ne peut pas soumettre un ordre pour une formation qui ne lui appartient pas.
3. Un ordre invalide ne modifie jamais l'état ; il produit un rejet explicite.
4. La résolution d'une phase est déterministe pour une graine et un ensemble d'ordres donnés.
5. Un événement est immuable une fois écrit.
6. Un message ne peut être lu que par ses destinataires et, le cas échéant, les observateurs autorisés.
7. Une IA ne peut accéder qu'à sa perception filtrée, jamais à l'état complet.
8. Une sauvegarde référence la version des règles et du format.
9. Un traité rompu conserve son historique ; il n'est pas supprimé.
10. Toute modification d'état passe par un événement ou une commande traçable.
11. Une bataille ne peut modifier que les forces, pertes, fortifications et la province concernée.
12. Le résultat d'une bataille est appliqué une seule fois au tour stratégique.
13. La conversion stratégique ↔ tactique est réversible et conserve le total des effectifs (aux arrondis documentés près).
14. Les pertes sont définitives : aucune perte n'est silencieusement restaurée.
15. Un changement de régime produit un événement et des effets tracés.
16. Une interception réussie ne produit pas de faux message.
17. Un accord contraignant est appliqué par le moteur ; un accord de confiance ne l'est pas.

## 5. Journal d'événements (proposition)

**[PROPOSITION]** Journal append-only avec, pour chaque entrée :

- identifiant séquentiel ;
- identifiant de partie ;
- phase / tour ;
- type d'événement ;
- acteurs concernés ;
- payload minimal et versionné ;
- horodatage ;
- corrélation éventuelle (ordre, message, traité, bataille).

Le journal permettrait : replay, audit, debug, calcul de réputation, alimentation de la mémoire des IA, analyses.

**Question ouverte :** le journal est-il la source de vérité (event sourcing complet) ou un complément à un état courant sauvegardé ? Décision à prendre par ADR.

**[PROPOSITION]** Un **journal de bataille** distinct conserve les commandes horodatées, les résultats intermédiaires et le résultat final, afin de permettre le replay et l'audit (C-15).

## 6. Données sensibles et visibilité

| Donnée | Visibilité proposée |
|---|---|
| État complet du plateau | Serveur uniquement |
| Perception d'un acteur | Cet acteur uniquement |
| Messages privés | Expéditeur, destinataires, administration |
| Ordres avant résolution | Secret (sauf règles contraires) |
| Traités | Selon leur nature (public/secret) |
| Réputation | Au moins partiellement visible ; modalités à définir |
| Mémoire d'une IA | IA concernée et administration/debug |
| Rapports de renseignement | Nation concernée uniquement |
| Interceptions | Intercepteur uniquement, sauf révélation volontaire |
| Journal de bataille | Participants, spectateurs autorisés, administration |

Toute règle de visibilité doit être testée : c'est une condition de l'équité (Q-012).

## 7. Questions ouvertes

- Faut-il un modèle multi-parties persistant ou des parties isolées ?
- Comment versionner les règles sans casser les sauvegardes ?
- Le replay doit-il être garanti à long terme ? Avec quelle précision ?
- Comment stocker les messages générés par les LLM (coût, taille, rétention) ?
- Faut-il anonymiser les joueurs dans les journaux ?
- Quelle est la durée de conservation des données (RGPD, Q-024) ?
- Les IA partagent-elles un format de mémoire commun ?
- Comment représenter les clauses d'un traité de façon structurée et négociable ?
- Comment représenter une bataille en cours sans bloquer la sauvegarde de la partie (C-15) ?
- Faut-il stocker la table de conversion stratégique ↔ tactique comme donnée de règles versionnée (C-03) ?

## 8. Critères de passage à « Spécifié »

- [ ] Règles de base validées.
- [ ] Décision de persistance (ADR).
- [ ] Décision sur le journal (ADR).
- [ ] Contrat de session de bataille défini.
- [ ] Modèle de visibilité validé.
- [ ] Inventaire des événements.
- [ ] Schéma conceptuel revu par le propriétaire.
