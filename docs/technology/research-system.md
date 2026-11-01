# Recherche et technologies

> **Statut :** MVP : 20 technologies provisoires ; arbre cible non validé
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 10 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 10
> **Documents liés :** [../economy/economy-system.md](../economy/economy-system.md) · [../military/strategic-warfare.md](../military/strategic-warfare.md) · [../military/tactical-battles.md](../military/tactical-battles.md) · [../intelligence/intelligence-system.md](../intelligence/intelligence-system.md) · [../nations/nations.md](../nations/nations.md) · [../design-review-v0.1.md](../design-review-v0.1.md)

---

## 1. Objet

Décrire le cadre de la recherche scientifique et de l'arbre technologique de 1914 à 1945. Aucun arbre, coût ou effet n'est arrêté.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Point de départ | Toutes les nations commencent en **1914**. | D-021, § 10.1 |
| Horizon | Progression possible jusqu'à un niveau technologique de **1945**. | § 10.1 |
| Histoire alternative | La progression doit permettre une histoire alternative. | § 10.1 |
| Inspiration | Arbre de recherche inspiré de **Hearts of Iron IV**. | § 10.2 |
| Branches envisagées | Infanterie et armement ; artillerie ; blindés ; aviation ; marine ; industrie ; communications et électronique ; médecine ; logistique. | § 10.2 |
| Prérequis | Les technologies avancées nécessitent normalement des technologies préalables. | D-021, § 10.3 |
| Avance | Une recherche en avance sur son époque est possible, avec un coût et un temps considérablement augmentés. | § 10.3 |
| Financement | Budget scientifique et ressources matérielles ; répartition entre branches. | § 10.4 |
| Spécialisations | Chaque pays possède des spécialisations scientifiques historiques, évolutives par investissement. | § 10.5 |

## 3. Arbre technologique

**[À DÉFINIR — T-025]** Structure complète : nombre de technologies, niveaux, branches, largeur, profondeur, liens, technologies mutualisées.

**[PROPOSITION — non validée]** Une structure en **branches** avec quelques technologies par décennie, plutôt qu'un arbre exhaustif de milliers de nœuds. La charge de conception et d'équilibrage doit rester compatible avec un projet mené par des agents.

**[À DÉFINIR]** Une technologie peut-elle appartenir à plusieurs branches ? Existe-t-il des technologies nationales uniques ? Les technologies se diffusent-elles entre alliés ou par espionnage ?

## 4. Prérequis et avance

**[VALIDÉ]** Les technologies avancées ont des prérequis ; une recherche en avance est possible mais coûteuse (D-021).

**[À DÉFINIR]** Modèle de coût : multiplicateur par décennie d'avance, plafond, temps minimum, risque d'échec, verrouillage par événement historique.

**[ATTENTION — C-12]** Le document fondateur va jusqu'en 1945 et cite l'inspiration HoI4. Il ne tranche pas le traitement des technologies historiquement sensibles : nucléaire, armes chimiques, biologique, bombardements stratégiques. **Aucune de ces technologies ne doit être implémentée avant validation explicite.**

## 5. Financement et rythme

**[VALIDÉ]** La recherche consomme un budget scientifique et des ressources matérielles ; le joueur répartit ses investissements (D-021, § 10.4).

**[À DÉFINIR]** Nombre de projets simultanés, file d'attente, coût par tour, effet de l'industrie et de la population, bonus de spécialisation, penalty de changement de branche.

**[PROPOSITION — non validée]** Un à trois projets simultanés, avec un coût croissant, pour éviter que la recherche ne devienne un simple clic mensuel.

## 6. Spécialisations nationales

**[VALIDÉ]** Chaque pays possède des spécialisations historiques, évolutives avec le temps et les investissements (D-021, § 10.5).

**[À DÉFINIR — T-020]** Liste des spécialisations par puissance, bonus exacts, coût de changement, interaction avec les changements de régime.

**[ATTENTION — V-02]** Les spécialisations ne doivent pas rendre une petite puissance artificiellement égale à une grande. Elles doivent rester cohérentes avec le poids historique.

## 7. Effets des technologies

**[À DÉFINIR]** Une technologie peut modifier :

- les unités et équipements (attaque, défense, mobilité) ;
- la production industrielle ;
- le renseignement et la cryptographie ;
- la médecine et les pertes ;
- la logistique et le ravitaillement ;
- la diplomatie et l'économie.

Chaque effet doit être **chiffré, lisible et testable**. Les effets purement descriptifs sont interdits.

## 8. Interaction avec le renseignement

**[VALIDÉ]** L'espionnage industriel peut obtenir des secrets technologiques adverses (D-022, D-023).

**[À DÉFINIR]** Une technologie volée est-elle immédiatement disponible, partiellement connue, ou seulement accélérée ? Comment éviter le vol en boucle ?

Voir [intelligence-system.md](../intelligence/intelligence-system.md).

## 9. Interaction avec les régimes et l'économie

**[VALIDÉ]** Les changements de régime ont des conséquences concrètes (D-024). Ils peuvent influencer la recherche.

**[À DÉFINIR]** Effets d'un régime sur les branches, les spécialisations, le budget scientifique et la fuite des cerveaux.

## 10. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-12 | Recherche 1914-1945 : rythme, coûts, technologies sensibles. | Non tranchée ; T-025. |
| C-13 | Données et inspirations historiques. | À documenter ; T-028. |
| V-02 | Équilibre entre puissances. | À surveiller. |
| V-04 | Temps de développement. | Prioriser un arbre réduit. |

## 11. Questions ouvertes

| ID | Question |
|---|---|
| S-001 | Combien de technologies et quelle structure ? |
| S-002 | Quels coûts et quelles durées ? |
| S-003 | Combien de projets simultanés ? |
| S-004 | Comment fonctionne exactement l'avance technologique ? |
| S-005 | Quelles technologies sensibles sont exclues ? |
| S-006 | Quelles spécialisations par nation ? |
| S-007 | Comment le vol technologique fonctionne-t-il ? |
| S-008 | Une partie atteint-elle réellement 1945 ? |

## 12. Critères de passage à « Spécifié »

- [ ] Structure de l'arbre validée.
- [ ] Coûts, durées et prérequis définis.
- [ ] Modèle d'avance tranché.
- [ ] Technologies sensibles tranchées.
- [ ] Spécialisations nationales définies.
- [ ] Effets chiffrés et testables.
- [ ] Interaction renseignement, économie et régimes définie.
- [ ] Validation du propriétaire.
