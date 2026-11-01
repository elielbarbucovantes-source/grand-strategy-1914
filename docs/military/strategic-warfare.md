# Guerre stratégique

> **Statut :** MVP : combat stratégique automatique livré ; règles cibles non validées
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 8 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 8
> **Documents liés :** [tactical-battles.md](tactical-battles.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../gameplay/map-system.md](../gameplay/map-system.md) · [../economy/economy-system.md](../economy/economy-system.md) · [../technology/research-system.md](../technology/research-system.md) · [../diplomacy/treaties.md](../diplomacy/treaties.md)

---

## 1. Objet

Décrire le niveau **stratégique** de la guerre : armées sur la carte, fronts, offensives, occupation, fortifications et pertes.

Le niveau tactique est traité dans [tactical-battles.md](tactical-battles.md). Les deux documents doivent rester cohérents : une bataille tactique est toujours la résolution d'une offensive stratégique.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Représentation | Les armées sont représentées sur la carte stratégique. | D-012, § 8.1 |
| Organisation | Unités telles que régiments, divisions et formations. | § 8.1 |
| Commande | Le joueur organise, déplace et commande directement ses forces. | § 8.1 |
| Capacité | Les effectifs et équipements **réellement mobilisés** déterminent les capacités. | § 8.1 |
| Fronts | Les affrontements statiques se résolvent sur la carte stratégique ; ils ne déclenchent pas automatiquement une bataille tactique. | D-013, § 8.2 |
| Offensive | Une offensive qui rencontre des armées déclenche une **bataille tactique indépendante**. | D-013, § 8.2 |
| Occupation | Le vainqueur occupe automatiquement la province. | D-015, § 8.5 |
| Pertes | Définitives : soldats et équipements détruits sont perdus. | D-015, § 8.5 |
| État des survivants | Les unités survivantes conservent les conséquences de leurs pertes et de leur état. | D-015, § 8.5 |
| Non retenu | Moral des troupes, généraux à recruter ou commander, chaîne de commandement intermédiaire. | D-016, § 8.6 |
| Fortifications | Construites sur la carte, présentes en bataille, améliorables par niveaux, avec ressources et technologies. | D-017, § 8.7 |

**Conséquence :** les hypothèses antérieures de ce document (une unité abstraite par territoire, résolution déterministe façon Diplomacy, possibilité d'un système de moral) sont **historiques**. Le modèle retenu est plus riche : effectifs, équipements, fronts et batailles tactiques.

## 3. Organisation des armées

**[PROPOSITION — non validée]** Une formation stratégique devrait porter :

| Attribut | Rôle |
|---|---|
| Type | Infanterie, cavalerie, artillerie, blindés, aviation, marine, autre. |
| Effectif | Nombre d'hommes ou points de force. |
| Équipement | Matériel associé, dépendant de la recherche et de l'industrie. |
| État matériel | Pertes, usure, approvisionnement (voir C-10). |
| Position | Province ou front. |
| Mission | Tenir, avancer, offensive, réserve, retraite. |

**[À DÉFINIR — T-024]** Liste des unités, taille des régiments et divisions, coûts, vitesse, portée, capacité de transport, règles de stack.

## 4. Fronts

**[VALIDÉ]** Un front est une situation d'affrontement statique entre armées. Il se résout sur la carte stratégique.

**[PROPOSITION]** Un front pourrait être représenté par :

- une ou plusieurs provinces adjacentes tenues par des forces opposées ;
- un état (stable, pression, percée) ;
- des pertes mensuelles éventuelles ;
- une consommation de ressources.

**[À DÉFINIR]** Comment un front naît, se stabilise et se rompt ; comment les pertes de front sont calculées ; si un front peut exister sans offensive ; quel rôle jouent les fortifications et le terrain.

**[VALIDÉ — contrainte]** Les échanges de tirs et pertes de front doivent consommer des ressources et rester lisibles sur la carte stratégique.

## 5. Offensives

**[VALIDÉ]** Une offensive lancée contre une province défendue par des armées ouvre une bataille tactique.

**[À DÉFINIR — C-04]** Ce que signifie « immédiatement tenter une nouvelle offensive » après un échec (D-015, § 8.5) : dans la même bataille, dans le même mois, au tour suivant ? Sans limite ?

**[PROPOSITION — non validée]** Une offensive par province et par mois, relance possible au tour suivant avec un coût croissant. Cette proposition ne vaut pas décision et contredit potentiellement le mot « immédiatement ».

**[À DÉFINIR]** Déclaration d'offensive, préparation, forces minimales, surprise, coordination entre provinces, ordre de résolution.

## 6. Conversion stratégique → tactique

**[VALIDÉ]** Les effectifs présents dans la bataille doivent être **proportionnels** aux forces engagées sur la carte (D-014, § 8.3). Exemple du document fondateur : trois régiments d'infanterie, une division aéroportée et une division blindée produisent une force correspondante en bataille.

**[À DÉFINIR — C-03]** Unité de conversion, coefficients, échelle, traitement des équipements, arrondis et pertes.

**[PROPOSITION — non validée]** Définir un **point de force** unique convertible dans les deux sens, avec une table explicite et testable. Aucun chiffre ne doit être inventé avant validation.

Détail dans [tactical-battles.md § 3](tactical-battles.md#3-conversion-des-forces).

## 7. Occupation, pertes et état des unités

**[VALIDÉ]** Après une bataille :

- le vainqueur occupe la province ;
- les pertes sont définitives ;
- les unités survivantes conservent leurs pertes et leur état.

**[À DÉFINIR — C-10]** Ce que contient exactement l'« état » des survivants : effectifs, équipement, approvisionnement, expérience ? Le document exclut le **moral** ; il ne faut pas le réintroduire sous un autre nom sans validation.

**[À DÉFINIR — C-08]** Une province occupée change-t-elle immédiatement de propriétaire, ou reste-t-elle occupée jusqu'à un traité ? Comment sont gérées les poches et les encerclements ?

## 8. Fortifications

**[VALIDÉ]** Les fortifications sont construites sur la carte, apparaissent dans les batailles tactiques et s'améliorent par niveaux avec des ressources et des technologies (D-017).

**[À DÉFINIR]** Niveaux, coûts, durée, entretien, effet stratégique et tactique, possibilité de destruction ou de capture.

## 9. Ravitaillement et attrition

**[À DÉFINIR — optionnel]** Le document fondateur ne tranche pas le ravitaillement. S'il existe, il doit rester lisible et ne pas réintroduire une chaîne de commandement ou un moral déguisé.

**[PROPOSITION — non validée]** Un approvisionnement simplifié par province ou par réseau, sans mécanique logistique lourde au lancement.

## 10. Interaction avec l'économie et la recherche

- coût de recrutement, d'entretien et de mobilisation ;
- dépendance aux ressources et à l'industrie (D-019, D-020) ;
- équipements améliorés par la recherche (D-021) ;
- économie de guerre et réorientation civile/militaire (D-020).

**[À DÉFINIR — T-021, T-025]** Les chiffres et les règles exactes.

## 11. Interaction avec la diplomatie

**[VALIDÉ]** Les accords peuvent être contraignants par les règles ou fondés sur la confiance (D-009).

**[À DÉFINIR]** Un traité peut-il :

- imposer un cessez-le-feu ;
- créer une zone démilitarisée ;
- autoriser un passage ;
- déclencher une intervention automatique ;
- transférer une province ?

**[À DÉFINIR — C-16]** Un accord signé pendant le tour s'applique-t-il immédiatement ou au tour suivant ?

## 12. Information et renseignement

**[À DÉFINIR — C-06]** Visibilité des positions, des effectifs, des intentions et des résultats.

**[VALIDÉ — exigence]** L'asymétrie d'information doit être identique pour les humains et les IA.

Le renseignement militaire, économique et technologique est traité dans [intelligence-system.md](../intelligence/intelligence-system.md).

## 13. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-02 | Plusieurs batailles simultanées et un seul joueur. | Non tranchée ; voir T-029. |
| C-03 | Conversion des forces. | Non tranchée ; T-024. |
| C-04 | Offensive immédiate vs tour mensuel. | Non tranchée ; T-024. |
| C-10 | « Pas de moral » vs « état des unités ». | Non tranchée ; T-024. |
| C-15 | Sauvegarde et replay des batailles. | Non tranchée ; T-028. |
| V-02 | Équilibre entre grandes et petites puissances. | À surveiller. |

## 14. Questions ouvertes

| ID | Question |
|---|---|
| W-001 | Quel niveau de simulation stratégique ? |
| W-002 | Quelles unités et quelles tailles ? |
| W-003 | Comment un front est-il représenté et résolu ? |
| W-004 | Combien d'offensives par mois et par province ? |
| W-005 | Quelle conversion stratégique ↔ tactique ? |
| W-006 | Que contient l'état des unités sans moral ? |
| W-007 | Le ravitaillement existe-t-il ? |
| W-008 | Comment fonctionnent occupation et libération ? |
| W-009 | Quelles informations sont visibles ? |
| W-010 | Comment équilibrer et tester le système ? |

## 15. Critères de passage à « Spécifié »

- [ ] Unités et attributs définis.
- [ ] Fronts et offensives décrits, cas limites inclus.
- [ ] Conversion stratégique/tactique chiffrée et testée.
- [ ] Pertes, état des unités et remplacement définis.
- [ ] Fortifications définies.
- [ ] Interactions économie, recherche et diplomatie définies.
- [ ] Visibilité définie.
- [ ] Jeux de tests de référence identifiés.
- [ ] Validation du propriétaire.
