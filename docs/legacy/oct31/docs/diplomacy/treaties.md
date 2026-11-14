# Traités et accords

> **Statut :** Cadrage aligné sur la fiche maîtresse — types non validés, non implémentés
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 6.3 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 6.3
> **Documents liés :** [negotiations.md](negotiations.md) · [alliances.md](alliances.md) · [reputation.md](reputation.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../military/strategic-warfare.md](../military/strategic-warfare.md) · [../architecture/data-model.md](../architecture/data-model.md)

---

## 1. Objet

Définir ce qu'est un traité dans le jeu, comment il naît, vit et meurt, et comment une IA peut le respecter ou le trahir de façon crédible.

## 2. Cadre validé par le propriétaire

**[VALIDÉ]** Deux catégories d'accords coexistent (D-009, § 6.3) :

1. **Accords juridiquement contraignants dans les règles** : le moteur applique l'accord et sanctionne sa violation selon des règles définies.
2. **Accords fondés sur la confiance** : le respect dépend de la volonté des dirigeants, de la réputation et de la mémoire des IA.

**[VALIDÉ]** Les conséquences d'une violation doivent être **cohérentes avec la nature de l'accord** (§ 6.3).

**Conséquence :** l'hypothèse antérieure « on ne sait pas si un traité est appliqué par le moteur ou par la confiance » est **historique** : la réponse est « les deux, selon la catégorie ».

## 3. Définition proposée

**[PROPOSITION — non validée]** Un accord est un engagement explicite entre au moins deux puissances, portant sur des obligations identifiables, avec :

- des parties ;
- des clauses ;
- une **catégorie** (contraignant ou de confiance) ;
- une durée ou une condition de fin ;
- un statut ;
- un historique horodaté (proposition, acceptation, rupture, expiration).

Un simple message n'est pas nécessairement un accord. La frontière entre promesse informelle et engagement doit être claire pour le joueur.

## 4. Types d'accords envisagés

**[PROPOSITION — non validée]** Types possibles, à valider un par un :

| Type | Contenu possible | Catégorie par défaut |
|---|---|---|
| Non-agression | Ne pas attaquer pendant une durée. | À trancher |
| Alliance | Coordination militaire et diplomatique. | À trancher |
| Soutien militaire | Intervention sous conditions. | À trancher |
| Cessez-le-feu | Arrêt des combats. | Contraignant ? |
| Paix | Fin de guerre, transferts éventuels. | Contraignant ? |
| Commerce | Échanges de ressources. | À trancher |
| Passage | Droit de traverser un territoire. | À trancher |
| Zone démilitarisée | Interdiction de forces dans une zone. | À trancher |
| Tribut / aide | Paiement ou transfert conditionnel. | À trancher |
| Secret | Accord occulte, non public. | De confiance ? |

**Règle :** un accord « contraignant » doit avoir des **conséquences mécaniques** explicites. Un accord « de confiance » ne doit pas être secrètement appliqué par le moteur, sinon la catégorie n'a pas de sens.

## 5. Cycle de vie

**[PROPOSITION — non validée]**

1. **Proposition** : rédigée, envoyée, horodatée.
2. **Négociation** : acceptation, refus, contre-proposition.
3. **Signature / entrée en vigueur** : selon la catégorie et le calendrier (voir C-16).
4. **Exécution** : le moteur applique les clauses contraignantes ; les autres reposent sur la confiance.
5. **Violation** : détection, conséquence, trace.
6. **Rupture / expiration / renégociation**.
7. **Archivage** : l'accord reste dans l'historique et la mémoire des IA.

## 6. Violation et conséquences

**[À DÉFINIR — T-022]** Pour chaque type :

- qu'est-ce qu'une violation ?
- qui la constate : le moteur, la victime, un tiers ?
- quelles conséquences : réputation, sanctions, rupture automatique, guerre ?
- la violation est-elle publique ou secrète ?
- peut-on violer un accord contraignant ? À quel coût ?

**[PROPOSITION — non validée]** Un accord contraignant viole les règles **et** produit une sanction mécanique ; un accord de confiance ne produit qu'un effet de réputation et de mémoire. Les deux doivent être traçables.

## 7. Application par le moteur

**[VALIDÉ]** Une partie des accords est appliquée par les règles (D-009).

**[À DÉFINIR]** Quelles clauses sont mécaniques : interdiction d'attaque, transfert de province, paiement, passage, cessez-le-feu. Toute clause mécanique doit être testable et ne pas dépendre de l'interprétation d'un texte libre.

## 8. Accords secrets

**[VALIDÉ]** Les canaux secrets existent et les communications sont confidentielles par défaut (D-008).

**[À DÉFINIR]** Un accord secret est-il connu du moteur seul ? Peut-il être révélé par interception ? Sa violation est-elle plus ou moins coûteuse en réputation ?

## 9. Interaction avec la réputation et la mémoire

**[VALIDÉ]** Les IA ont une mémoire longue et se souviennent des promesses et des trahisons (D-011, § 7.3).

**[À DÉFINIR]** Voir [reputation.md](reputation.md) : comment un accord violé modifie la confiance, la réputation et les décisions futures.

## 10. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-05 | Interception des accords secrets. | Non tranchée ; T-025. |
| C-08 | Accords de paix et victoire. | Non tranchée. |
| C-16 | Entrée en vigueur pendant le tour. | Non tranchée ; T-022. |

## 11. Questions ouvertes

| ID | Question |
|---|---|
| D-201 | Quels types d'accords au lancement ? |
| D-202 | Quelles clauses sont contraignantes ? |
| D-203 | Quelles sanctions pour violation ? |
| D-204 | Comment un accord secret est-il géré ? |
| D-205 | Quand entre-t-il en vigueur ? |
| D-206 | Peut-on renégocier ou suspendre un accord ? |

## 12. Critères de passage à « Spécifié »

- [ ] Types d'accords validés.
- [ ] Catégorie de chaque accord tranchée.
- [ ] Clauses mécaniques spécifiées.
- [ ] Violations et sanctions définies.
- [ ] Cycle de vie et calendrier arrêtés.
- [ ] Interaction avec la réputation définie.
- [ ] Validation du propriétaire.
