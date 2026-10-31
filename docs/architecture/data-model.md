# Modèle de données — modèle conceptuel préliminaire

> **Statut :** Cadrage — aucun schéma validé, aucune base de données choisie
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [overview.md](overview.md) · [technical-decisions.md](technical-decisions.md) · [gameplay/rules.md](../gameplay/rules.md) · [diplomacy/treaties.md](../diplomacy/treaties.md)

---

## 1. Objet et avertissement

Ce document décrit les **concepts** que le système devra probablement représenter. Il ne définit ni tables, ni types, ni format de sérialisation. Aucun schéma ne doit être implémenté avant validation des règles et d'un ADR de persistance.

**[PROPOSITION]** Les entités ci-dessous sont une base de discussion, pas un modèle arrêté.

## 2. Entités conceptuelles proposées

| Entité | Rôle | Attributs envisagés (non contractuels) | Questions |
|---|---|---|---|
| `Game` | Une partie | identifiant, version des règles, graine, état, dates, statut | Plusieurs parties par joueur ? Parties persistantes ? |
| `RuleSet` | Version des règles | identifiant, version, paramètres | Règles moddables ? |
| `Map` | Carte | identifiant, version, territoires, adjacences | Format ? Plusieurs cartes ? |
| `Territory` | Province / région | nom, type (terre/mer/côte), propriétaire, centre | Fog of war ? |
| `Power` | Puissance jouée | nom, couleur, statut (actif/éliminé), contrôle | Nombre ? Équilibre ? |
| `Unit` | Unité militaire | type, propriétaire, position, état | Types ? Stacking ? |
| `Order` | Ordre soumis | acteur, type, cible(s), phase, statut | Ordres conditionnels ? |
| `Resolution` | Résultat d'une phase | ordres, résultats, événements, hash | Rejouable ? |
| `Message` | Message diplomatique | expéditeur, destinataires, contenu, canal, horodatage | Public/privé ? Modération ? |
| `Proposal` | Proposition diplomatique | auteur, type, clauses, échéance, statut | Clauses structurées ? |
| `Treaty` | Traité | parties, clauses, durée, statut, historique | Contraignant ? Secret ? |
| `Commitment` | Promesse / engagement | auteur, contenu, contexte, statut | Distinct d'un traité ? |
| `Reputation` | Réputation | cible, source, dimension, valeur, date | Globale ou par acteur ? |
| `AIPersonality` | Profil d'IA | traits, objectifs, style, seed | Généré ou écrit ? |
| `AIMemory` | Mémoire d'une IA | type, contenu, importance, date, accès | Rétention ? |
| `Event` | Événement du journal | type, acteurs, payload, séquence, date | Source de vérité ? |
| `Player` | Joueur humain | identité, partie, rôle | Comptes ? Anonymat ? |
| `Snapshot` | Sauvegarde | partie, version, état sérialisé, hash | Compatibilité ? |

## 3. Relations principales (proposées)

```
Game 1 ── * Power
Game 1 ── 1 Map
Game 1 ── 1 RuleSet
Map  1 ── * Territory
Power 1 ── * Unit
Power 1 ── * Order
Game 1 ── * Message
Message 1 ── * Proposal
Proposal 1 ── 0..1 Treaty
Power 1 ── 1 AIPersonality
Power 1 ── * AIMemory
Power 1 ── * Reputation (en tant que cible)
Game 1 ── * Event
Game 1 ── * Snapshot
```

Ces cardinalités sont indicatives. Par exemple, un message peut concerner plusieurs traités, et une réputation peut être agrégée.

## 4. Invariants potentiels

À valider avant implémentation :

1. Un ordre appartient à un acteur et à une phase précise.
2. Un acteur ne peut pas soumettre un ordre pour une unité qui ne lui appartient pas.
3. Un ordre invalide ne modifie jamais l'état ; il produit un rejet explicite.
4. La résolution d'une phase est déterministe pour une graine et un ensemble d'ordres donnés.
5. Un événement est immuable une fois écrit.
6. Un message ne peut être lu que par ses destinataires et, le cas échéant, les observateurs autorisés.
7. Une IA ne peut accéder qu'à sa perception filtrée, jamais à l'état complet.
8. Une sauvegarde référence la version des règles et du format.
9. Un traité rompu conserve son historique ; il n'est pas supprimé.
10. Toute modification d'état passe par un événement ou une commande traçable.

## 5. Journal d'événements (proposition)

**[PROPOSITION]** Journal append-only avec, pour chaque entrée :

- identifiant séquentiel ;
- identifiant de partie ;
- phase / tour ;
- type d'événement ;
- acteurs concernés ;
- payload minimal et versionné ;
- horodatage ;
- corrélation éventuelle (ordre, message, traité).

Le journal permettrait : replay, audit, debug, calcul de réputation, alimentation de la mémoire des IA, analyses.

**Question ouverte :** le journal est-il la source de vérité (event sourcing complet) ou un complément à un état courant sauvegardé ? Décision à prendre par ADR.

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

## 8. Critères de passage à « Spécifié »

- [ ] Règles de base validées.
- [ ] Décision de persistance (ADR).
- [ ] Décision sur le journal (ADR).
- [ ] Modèle de visibilité validé.
- [ ] Inventaire des événements.
- [ ] Schéma conceptuel revu par le propriétaire.
