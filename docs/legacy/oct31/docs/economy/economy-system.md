# Système économique et industriel

> **Statut :** Cadrage aligné sur la fiche maîtresse — **existence validée**, mécaniques non conçues, non implémentées
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 9, § 13 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 9
> **Documents liés :** [../gameplay/map-system.md](../gameplay/map-system.md) · [../military/strategic-warfare.md](../military/strategic-warfare.md) · [../technology/research-system.md](../technology/research-system.md) · [../nations/nations.md](../nations/nations.md) · [../diplomacy/treaties.md](../diplomacy/treaties.md) · [../design-review-v0.1.md](../design-review-v0.1.md)

---

## 1. Objet

Décrire le cadre de l'économie, de l'industrie et du niveau de vie. **L'existence d'une économie n'est plus une question ouverte** : elle est validée par la fiche maîtresse. Les mécaniques détaillées restent à définir.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Existence | L'économie doit permettre une véritable stratégie nationale, sans complexité excessive. | D-019, § 9 |
| Ressources | Chaque territoire produit **trois ressources**, en faible / moyenne / forte quantité (principe inspiré de Catan). | D-018, § 9.1 |
| Profils | Les provinces ont des profils économiques différents. | § 9.1 |
| Gestion | Revenus, dépenses, investissements, financement militaire, production industrielle, recherche. | D-019, § 9.2 |
| Lisibilité | Éviter une comptabilité inutilement détaillée. | § 9.2 |
| Industrie | Usines, infrastructures, chaînes de production, mobilisation industrielle, économie de guerre. | D-020, § 9.3 |
| Réorientation | Possibilité de basculer une partie de l'économie civile vers la production militaire. | § 9.3 |
| Puissance | Les capacités industrielles influencent directement la puissance nationale. | § 9.3 |

**Conséquence :** les hypothèses antérieures de ce document (« l'existence de l'économie n'est pas décidée », option A « aucune économie », option B « ressource unique ») sont **historiques**. Le modèle retenu est celui de trois ressources par territoire avec industrie.

## 3. Ressources

**[VALIDÉ]** Trois ressources par territoire, avec trois niveaux de production (D-018).

**[À DÉFINIR — T-021]** La liste défisitive des ressources. Le document fondateur ne la donne pas. Les agents ne doivent pas la figer sans validation.

**[PROPOSITION — non validée]** Une structure possible, à titre d'illustration :

| Piste | Ressources possibles | Remarque |
|---|---|---|
| Matières premières | charbon, fer, pétrole | Dépend des provinces et de la période. |
| Production | acier, munitions, biens manufacturés | Dépend de l'industrie. |
| Soutien | nourriture, main-d'œuvre, finance | Dépend de la population. |

Cette liste est **illustrative** et ne doit pas être implémentée. Une ressource peut être stockable ou être un flux par tour ; ce choix reste ouvert.

## 4. Production et revenus

**[À DÉFINIR]**

- production par province, par niveau et par ressource ;
- effet des infrastructures et des usines ;
- effet de l'occupation, du blocus et de la destruction ;
- monnaie ou ressource financière ;
- budget national : recettes, dépenses, dette, emprunts ;
- entretien des armées et des fortifications.

**[PROPOSITION]** Un budget par tour, lisible, avec quelques catégories seulement (armée, industrie, recherche, social), plutôt qu'une comptabilité détaillée. Non validé.

## 5. Industrie

**[VALIDÉ]** L'industrie est un élément stratégique (D-020).

**[À DÉFINIR]** Types d'usines, capacités, chaînes de production, coûts de construction, délais, entretien, conversion civile/militaire, effet de la recherche, vulnérabilité aux attaques.

**[PROPOSITION — non validée]** Une capacité industrielle agrégée par nation, avec des usines localisées dans certaines provinces. La localisation permet les conquêtes et les bombardements futurs, sans imposer une simulation usine par usine.

## 6. Population et niveau de vie

**[À DÉFINIR — C-07, C-18]** La victoire économique et sociale exige un indicateur de niveau de vie, mais la fiche maîtresse ne modélise ni population ni indicateur social.

Points à trancher :

- population par province ou par nation ?
- croissance, conscription, pertes civiles ?
- indicateur : PIB par habitant, consommation, espérance de vie, bonheur composite ?
- effet de la guerre, du blocus et des dépenses sociales ;
- seuil et durée de la victoire économique et sociale.

**[PROPOSITION — non validée]** Un indicateur composite simple et lisible, dérivé de la production, de la consommation et des dépenses sociales, sans simulation démographique lourde. **Ne pas implémenter avant validation.**

## 7. Commerce, sanctions et diplomatie économique

**[À DÉFINIR]** Le document fondateur mentionne des accords commerciaux (§ 6.1) mais ne définit ni commerce, ni sanctions, ni tributs.

**[PROPOSITION — non validée]** Une économie rend possible :

- tributs et paiements ;
- accords commerciaux ;
- sanctions ;
- prêts et dettes ;
- aides conditionnelles ;
- blocus.

Chaque accord doit être **traçable** et exploitable par la réputation et la mémoire des IA. La question de savoir s'il est appliqué par le moteur ou laissé à la confiance recoupe D-009 (deux catégories d'accords).

## 8. Interaction avec le militaire

- recrutement, entretien et mobilisation ;
- production d'équipements dépendant de la recherche ;
- ravitaillement éventuel ;
- effet d'un blocus ;
- destruction d'infrastructures ;
- butin et occupation.

**[À DÉFINIR — T-024]** Les chiffres et les règles exactes.

## 9. Lisibilité et interface

**[VALIDÉ]** La gestion financière doit rester lisible et éviter une comptabilité inutilement détaillée (§ 9.2).

**[À DÉFINIR]** Tableaux de bord, alertes, prévisions, explication des variations. L'interface est traitée dans [../gameplay/rules.md](../gameplay/rules.md) et le futur document UI (T-027).

## 10. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Complexité | Trop de ressources et de règles. | Trois ressources maximum au lancement ; catégories de budget simples. |
| Snowball | Le leader devient inarrêtable. | Rendements décroissants, coûts, coalitions. |
| Opacité | Le joueur ne comprend pas son économie. | Interface et rapports clairs. |
| IA faible | Les IA gèrent mal l'économie. | Heuristiques et rapports explicites. |
| Équilibrage | Difficile à tester. | Simulations, métriques, parties de test. |
| Scope creep | Retarde le MVP. | Décision explicite et documentée. |
| Population absente | Victoire économique impossible. | Trancher C-07/C-18 avant implémentation. |

## 11. Questions ouvertes

| ID | Question |
|---|---|
| E-001 | Quelles sont les trois ressources définitives ? |
| E-002 | Sont-elles stockables ou des flux ? |
| E-003 | Comment la production est-elle calculée ? |
| E-004 | Quelles catégories de budget ? |
| E-005 | Comment fonctionne l'industrie ? |
| E-006 | La population est-elle modélisée ? |
| E-007 | Quel indicateur de niveau de vie ? |
| E-008 | Quels accords économiques sont possibles ? |
| E-009 | Comment éviter le snowball ? |
| E-010 | Comment les IA gèrent-elles l'économie ? |

## 12. Critères de passage à « Spécifié »

- [ ] Liste des ressources validée.
- [ ] Production et revenus définis.
- [ ] Budget et catégories définis.
- [ ] Industrie définie.
- [ ] Population et niveau de vie tranchés.
- [ ] Accords économiques définis.
- [ ] Interactions militaire, recherche et diplomatie définies.
- [ ] Stratégie d'équilibrage et de test définie.
- [ ] Validation du propriétaire.
