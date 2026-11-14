# Réputation et confiance

> **Statut :** Cadrage aligné sur la fiche maîtresse — modèle non validé, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 6.4, § 7.3 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 6, § 7
> **Documents liés :** [treaties.md](treaties.md) · [alliances.md](alliances.md) · [negotiations.md](negotiations.md) · [../ai/memory-system.md](../ai/memory-system.md) · [../nations/regimes.md](../nations/regimes.md)

---

## 1. Objet

Définir comment la confiance, la fiabilité et l'historique des engagements sont représentés et utilisés.

La réputation est le mécanisme qui donne un coût à la trahison et de la valeur aux promesses.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Relations | Amitié, neutralité, hostilité. | D-010, § 6.4 |
| Évolution | Les relations évoluent selon les actions, négociations, promesses et conflits. | § 6.4 |
| Accords | Contraignants par les règles ou fondés sur la confiance. | D-009, § 6.3 |
| IA | Mémoire longue des conversations, promesses, trahisons, alliances, conflits, erreurs. | D-011, § 7.3 |
| Conséquences | Une violation doit avoir des conséquences cohérentes avec la nature de l'accord. | § 6.3 |
| Confiance | Une IA trahie doit pouvoir en tenir compte longtemps après les faits. | § 7.3 |

**Conséquence :** l'hypothèse antérieure « la réputation n'est qu'une option » est **historique**. La mémoire longue et le coût de la trahison sont validés ; leur **modèle** reste à définir.

## 3. Pourquoi une réputation

**[PROPOSITION — non validée]** Sans réputation :

- trahir n'a aucun coût ;
- les promesses ne valent rien ;
- les IA n'ont aucune raison de coopérer durablement ;
- la diplomatie se réduit à un jeu de dupes à court terme.

Avec une réputation :

- les engagements passés influencent les décisions futures ;
- la coopération devient possible ;
- la trahison devient un calcul, pas une impulsion ;
- les personnalités peuvent se distinguer.

## 4. Modèle proposé

**[PROPOSITION — non validée]** Deux niveaux distincts, à ne pas confondre :

| Niveau | Objet | Portée |
|---|---|---|
| Relation diplomatique | État officiel entre deux nations : amitié / neutralité / hostilité. | Globale, connue. |
| Réputation | Fiabilité perçue d'une nation, fondée sur ses actes. | Par nation observatrice, ou agrégée. |

**[À DÉFINIR]** La réputation est-elle :

- une valeur unique par nation ;
- un vecteur par type d'engagement (militaire, commercial, territorial) ;
- une croyance par observateur (A peut croire B fiable et C non) ;
- une combinaison de ces options.

**[PROPOSITION — non validée]** Une croyance **par observateur** est plus riche et plus réaliste, mais plus coûteuse à stocker et à expliquer. Une valeur agrégée est plus lisible. Le choix doit être tranché avant implémentation.

## 5. Sources de réputation

**[PROPOSITION — non validée]**

- respect ou violation d'un accord contraignant ;
- respect ou violation d'une promesse informelle ;
- trahison d'une alliance ;
- déclaration de guerre sans préavis ;
- aide effective à un allié ;
- respect d'un cessez-le-feu ;
- propagande et mensonges découverts ;
- comportement lors d'une crise.

**[À DÉFINIR]** Poids, durée, oubli, récupération, effet des régimes et de la propagande.

## 6. Utilisation par les IA

**[VALIDÉ]** Les IA se souviennent des trahisons et en tiennent compte longtemps (D-011).

**[À DÉFINIR]** Comment la réputation entre dans la décision : seuils d'alliance, primes de coopération, pénalités de négociation, mémoire des promesses non tenues. Voir [../ai/decision-making.md](../ai/decision-making.md) et [../ai/memory-system.md](../ai/memory-system.md).

## 7. Lisibilité pour le joueur

**[À DÉFINIR]** Le joueur voit-il sa propre réputation ? Celle des autres ? Sous quelle forme : valeur, historique, alertes ?

**[PROPOSITION — non validée]** Afficher un **historique des engagements** plutôt qu'un score opaque : chaque promesse, chaque trahison, chaque accord, avec sa conséquence. Le joueur comprend ainsi pourquoi une IA se méfie.

## 8. Interaction avec les accords contraignants

**[VALIDÉ]** Un accord contraignant est appliqué par les règles (D-009).

**[À DÉFINIR]** La violation d'un accord contraignant est-elle seulement une sanction mécanique, ou aussi une perte de réputation ? Les deux devraient probablement coexister, sans que l'un remplace l'autre.

## 9. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Score opaque | Le joueur ne comprend pas sa réputation. | Historique explicite. |
| Réputation infinie | Une trahison rend une nation éternellement discréditée. | Oubli progressif, rédemption. |
| Réputation cosmétique | Aucun effet réel sur les IA. | Effets testés. |
| Collusion | Les IA se coordonnent trop parfaitement. | Information filtrée, méfiance. |
| Complexité | Trop de dimensions à stocker. | Commencer simple, étendre après validation. |

## 10. Questions ouvertes

| ID | Question |
|---|---|
| Y-001 | Valeur unique ou croyance par observateur ? |
| Y-002 | Quelles sources et quels poids ? |
| Y-003 | Comment la réputation s'oublie-t-elle ? |
| Y-004 | Comment entre-t-elle dans la décision des IA ? |
| Y-005 | Que voit le joueur ? |
| Y-006 | Quel lien avec les accords contraignants ? |

## 11. Critères de passage à « Spécifié »

- [ ] Modèle de réputation tranché.
- [ ] Sources et poids définis.
- [ ] Oubli et récupération définis.
- [ ] Utilisation par les IA spécifiée.
- [ ] Affichage joueur défini.
- [ ] Interaction avec les accords contraignants définie.
- [ ] Validation du propriétaire.
