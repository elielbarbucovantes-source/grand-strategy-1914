# Traités

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [negotiations.md](negotiations.md) · [alliances.md](alliances.md) · [reputation.md](reputation.md) · [gameplay/rules.md](../gameplay/rules.md) · [architecture/data-model.md](../architecture/data-model.md)

---

## 1. Objet

Définir ce qu'est un traité dans le jeu, comment il naît, vit et meurt, et comment une IA peut le respecter ou le trahir de façon crédible.

**Aucun type de traité n'est validé.** Les listes ci-dessous sont des propositions de conception.

## 2. Définition proposée

**[PROPOSITION]** Un traité est un accord explicite entre au moins deux puissances, portant sur des obligations identifiables, avec :

- des parties ;
- des clauses ;
- une durée ou une condition de fin ;
- un statut ;
- un historique (proposition, acceptation, rupture, expiration).

Un simple message n'est pas nécessairement un traité. La frontière entre promesse informelle, engagement et traité doit être définie.

## 3. Types de traités proposés

| Type | Contenu possible | Statut |
|---|---|---|
| Non-agression | Ne pas attaquer une puissance ou un territoire | Proposition |
| Alliance défensive | Se défendre mutuellement en cas d'agression | Proposition |
| Alliance offensive | Coordonner une attaque | Proposition |
| Cessez-le-feu | Arrêter les hostilités | Proposition |
| Paix | Mettre fin à un conflit, éventuellement avec conditions | Proposition |
| Zone démilitarisée | Interdire des unités dans une zone | Proposition |
| Accord commercial | Échanges de ressources, si économie | Proposition |
| Soutien logistique | Autoriser le passage ou le ravitaillement | Proposition |
| Partage de renseignement | Échanger des informations | Proposition |
| Pacte de partage de victoire | Coordonner la fin de partie | Proposition |
| Ultimatum | Exigence avec échéance et conséquence | Proposition |

**[À DÉFINIR]** Les traités peuvent-ils contenir des clauses secrètes ? Des clauses conditionnelles ? Des clauses automatiques ?

## 4. Cycle de vie proposé

```
proposé → accepté → actif → (rempli | expiré | rompu | renégocié)
                  ↘ rejeté
                  ↘ annulé
```

Règles à définir :

- qui peut proposer, accepter, rejeter ?
- faut-il une acceptation unanime ?
- un traité peut-il être accepté tacitement ?
- comment modifier un traité actif ?
- que se passe-t-il si une partie est éliminée ?
- un traité survit-il à la fin de la partie ?

## 5. Clauses

**[PROPOSITION]** Une clause devrait être structurée pour être vérifiable et exploitable par les IA :

- type d'obligation ;
- acteurs concernés ;
- portée (territoires, unités, ressources) ;
- condition de déclenchement ;
- échéance ;
- conséquence en cas de violation ;
- visibilité (publique / privée).

**[À DÉFINIR]** Jusqu'où structurer ? Un texte libre est plus riche mais moins vérifiable. Un format structuré est plus testable mais moins expressif. Un mélange (clauses structurées + commentaire libre) est possible.

## 6. Application : mécanique ou sociale ?

**[À DÉFINIR — Q-016]** Trois modèles possibles :

### Modèle 1 — Traités purement sociaux

Le moteur n'empêche rien. Un traité est une promesse ; la violation est possible et n'a de conséquence que par la réputation et les représailles.

- Avantages : liberté, mensonge, diplomatie riche.
- Inconvénients : les traités peuvent sembler décoratifs ; les IA doivent gérer la confiance.

### Modèle 2 — Traités partiellement contraignants

Certaines clauses sont appliquées par le moteur (par exemple une zone démilitarisée), d'autres sont sociales.

- Avantages : compromis.
- Inconvénients : règles complexes, cas limites.

### Modèle 3 — Traités contraignants

Le moteur empêche de violer un traité ; il faut d'abord le dénoncer.

- Avantages : clarté.
- Inconvénients : réduit la trahison « surprise », qui est au cœur de la vision.

**[PROPOSITION]** Le modèle 1 ou 2 préserve mieux la vision de trahison intelligente, mais le choix appartient au propriétaire.

## 7. Trahison

**[VALIDÉ]** Les IA doivent pouvoir trahir intelligemment.

**[À DÉFINIR]** Ce que « trahir » signifie mécaniquement :

- violer un traité actif ;
- rompre une promesse informelle ;
- attaquer un allié ;
- révéler des informations confidentielles ;
- ne pas fournir l'aide promise.

Pour chaque cas : comment le détecter, le rendre visible, et quel effet sur la réputation ?

**[PROPOSITION]** Une trahison doit être **traçable** et avoir un coût social, sans être automatiquement irrationnelle. Une IA peut gagner à court terme et perdre en réputation à long terme.

## 8. Traités et IA

Une IA doit pouvoir :

- proposer, lire, accepter, refuser un traité ;
- se souvenir de ses engagements ;
- évaluer le risque de trahison de l'autre ;
- décider de tenir ou de rompre ;
- expliquer (au moins en interne) sa décision ;
- ne pas être piégée par un format ambigu.

**[PROPOSITION]** Le format des traités doit être assez simple pour être fiable, assez riche pour permettre la négociation.

## 9. Journalisation et visibilité

- Chaque proposition, acceptation, rejet, modification et rupture doit produire un événement.
- Les traités publics et secrets doivent être distingués.
- Les observateurs et les administrateurs doivent pouvoir auditer.
- Les autres IA ne doivent voir que ce qui est public ou ce qui leur est communiqué.

**[À DÉFINIR]** Un traité secret reste-t-il secret après sa rupture ? Qui peut le révéler ?

## 10. Questions ouvertes

| ID | Question |
|---|---|
| T-001 | Quelle définition exacte d'un traité ? |
| T-002 | Quels types sont nécessaires au MVP ? |
| T-003 | Clauses structurées, libres ou hybrides ? |
| T-004 | Application mécanique ou sociale (Q-016) ? |
| T-005 | Comment modifier un traité actif ? |
| T-006 | Que se passe-t-il si un acteur est éliminé ? |
| T-007 | Comment détecter et qualifier une trahison ? |
| T-008 | Quels traités sont publics ? |
| T-009 | Les traités peuvent-ils être secrets ? |
| T-010 | Comment empêcher les interprétations abusives ? |
| T-011 | Un traité peut-il être imposé par un ultimatum ? |
| T-012 | Les traités sont-ils versionnés avec les règles ? |

## 11. Dépendances

- [negotiations.md](negotiations.md) : format des propositions.
- [alliances.md](alliances.md) : cas particulier des alliances.
- [reputation.md](reputation.md) : conséquences des ruptures.
- [gameplay/rules.md](../gameplay/rules.md) : effets mécaniques éventuels.
- [artificial-intelligence/memory-system.md](../artificial-intelligence/memory-system.md) : mémorisation des engagements.

## 12. Critères de passage à « Spécifié »

- [ ] Q-016 tranchée.
- [ ] Types de traités du MVP listés.
- [ ] Structure des clauses validée.
- [ ] Cycle de vie complet, cas limites inclus.
- [ ] Règles de visibilité et de trahison définies.
- [ ] Événements de journal identifiés.
- [ ] Jeux de tests de scénarios diplomatiques définis.
- [ ] Validation du propriétaire.
