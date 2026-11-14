# Système de carte

> **Statut :** Cadrage aligné sur la fiche maîtresse — carte non conçue, non validée, non implémentée
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 4, § 8.4, § 15.1 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 4
> **Documents liés :** [rules.md](rules.md) · [military/strategic-warfare.md](../military/strategic-warfare.md) · [military/tactical-battles.md](../military/tactical-battles.md) · [economy/economy-system.md](../economy/economy-system.md) · [nations/nations.md](../nations/nations.md) · [architecture/data-model.md](../architecture/data-model.md)

---

## 1. Objet

Définir les besoins du système de carte : provinces, adjacences, propriété, attributs, représentation, édition et validation. Aucun format ni schéma n'est arrêté.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Zone représentée | **Europe de 1914**. | D-004, PROJECT.md § 4.1 |
| Présentation | Carte stratégique **en deux dimensions**, inspirée de Hearts of Iron IV. | § 4.1 |
| Unité territoriale | **Provinces conquérables**. | § 4.2 |
| Attributs obligatoires | Nation propriétaire, caractéristiques géographiques, ressources, importance stratégique, infrastructures éventuelles, fortifications éventuelles. | § 4.2 |
| Géographie | Influence réelle sur les décisions économiques et militaires. | § 4.2 |
| Niveau de détail | Suffisamment précis pour des stratégies intéressantes, sans multiplier inutilement les territoires. | § 4.2 |
| Cohérence tactique | Les caractéristiques géographiques d'une province doivent correspondre aux terrains de ses batailles tactiques. | § 8.4 |

**[À DÉFINIR — T-020]** Liste définitive des provinces, frontières, territoires jouables et découpage des petites puissances.

**Conséquence :** les hypothèses antérieures de ce document (carte inspirée du plateau Diplomacy, territoire abstrait, adjacences façon Diplomacy) sont **historiques** et ne font plus autorité.

## 3. Concepts retenus (proposition de modélisation)

**[PROPOSITION — non validée]** Une province devrait porter au minimum :

| Attribut | Rôle | Remarque |
|---|---|---|
| `id` | Identifiant stable. | Jamais réutilisé après suppression. |
| `name` | Nom affiché. | Localisable ; source historique à documenter. |
| `owner` | Nation propriétaire. | Peut différer du contrôleur en cas d'occupation. |
| `controller` | Nation qui contrôle militairement. | À définir avec les règles d'occupation. |
| `terrain` | Type de terrain stratégique. | Doit se traduire en terrain tactique cohérent. |
| `adjacencies` | Provinces voisines. | Terrestres et maritimes distinctes. |
| `resources` | Trois ressources avec niveau faible / moyen / fort. | Voir D-018 et [economy-system.md](../economy/economy-system.md). |
| `strategic_value` | Importance stratégique. | À définir : politique, militaire, économique ? |
| `infrastructure` | Niveau d'infrastructures. | Influence production et mouvement. |
| `fortification` | Niveau de fortification. | Voir D-017. |
| `victory_points` | Contribution éventuelle à la victoire territoriale. | **[À DÉFINIR — C-08]** |
| `population` | Population éventuelle. | **[À DÉFINIR — C-18]** |

**[À DÉFINIR]** Une province peut-elle appartenir à plusieurs nations (condominium, occupation partielle) ? Peut-elle être coupée en plusieurs sous-zones ? Comment représenter les mers, détroits et côtes ?

## 4. Hiérarchie territoriale

**[PROPOSITION]** Deux niveaux suffisent probablement :

- **Province** : unité conquérable, porteuse des ressources et des fortifications.
- **Région / nation** : agrégat pour l'affichage, le budget et les rapports.

**[À DÉFINIR]** Le besoin d'un niveau intermédiaire (région historique, district) dépendra du nombre final de provinces. Ne pas multiplier les niveaux avant d'avoir la liste validée.

## 5. Nations sur la carte

**[VALIDÉ]** Sept grandes puissances jouables : Allemagne, Royaume-Uni, France, Russie, Autriche-Hongrie, Italie, Empire ottoman (D-005).

**[VALIDÉ]** Les autres pays européens existent comme entités indépendantes, contrôlées par une IA, mais ne sont pas jouables en v1.

**[À DÉFINIR]** Leur poids historique doit rester cohérent : une petite puissance ne doit pas devenir artificiellement l'égale d'une grande puissance (voir [design-review-v0.1.md V-02](../design-review-v0.1.md)).

Voir [nations/nations.md](../nations/nations.md) pour les caractéristiques et objectifs nationaux.

## 6. Ressources et économie sur la carte

**[VALIDÉ]** Chaque territoire produit **trois ressources** selon un principe inspiré de Catan : une en faible quantité, une en quantité moyenne, une en grande quantité (D-018).

**[À DÉFINIR — T-021]** La liste des ressources, les niveaux exacts, la production par tour, les rendements et l'effet des infrastructures.

**Conséquence :** la carte n'est pas qu'un support militaire ; elle porte le profil économique des provinces.

## 7. Fortifications

**[VALIDÉ]** Les fortifications sont construites sur la carte stratégique et apparaissent dans les batailles tactiques. Elles s'améliorent par niveaux, coûtent des ressources et dépendent de technologies (D-017).

**[À DÉFINIR]** Coûts, niveaux, effets stratégiques et tactiques, destruction éventuelle.

## 8. Adjacences et mouvement

**[À DÉFINIR]**

- adjacences terrestres, maritimes et côtières ;
- détroits et passages obligés ;
- effet des frontières et des pays neutres ;
- zones démilitarisées éventuelles ;
- mouvement naval et transports ;
- temps de traversée (ou mouvement instantané dans le tour).

**[VALIDÉ — contrainte]** Toute règle de mouvement doit rester compatible avec la résolution mensuelle simultanée (D-006).

## 9. Représentation et édition

**[PROPOSITION]** La carte devrait être décrite par des **données déclaratives** séparées du code, afin de permettre la validation automatique et, éventuellement, le modding (Q-018).

**[PROPOSITION]** Un validateur interne devrait vérifier au minimum :

- identifiants uniques ;
- adjacences symétriques et cohérentes ;
- provinces appartenant à une nation existante ;
- ressources dans les bornes autorisées ;
- terrains connus ;
- absence de provinces orphelines ;
- cohérence entre terrain stratégique et terrain tactique.

**[À DÉFINIR]** Format (JSON, YAML, binaire, éditeur dédié), outil de création et politique de versionnement.

## 10. Visibilité sur la carte

**[À DÉFINIR — C-06]** Quelles informations sont visibles par défaut, lesquelles exigent du renseignement, lesquelles restent secrètes.

**[PROPOSITION — non validée]** Positions des armées visibles ; effectifs et intentions filtrés par le renseignement. Cette proposition ne vaut pas décision.

## 11. Tensions et risques applicables

| ID | Tension / risque | Traitement |
|---|---|---|
| C-06 | Fog of war stratégique non défini. | Non tranché. |
| C-08 | Points de victoire territoriaux et carte. | Non tranché. |
| C-13 | Provenance de la carte, des noms et des données historiques. | À documenter avant publication. |
| C-18 | Population absente du modèle. | Non tranché. |
| V-01 | Lisibilité d'une carte riche. | À surveiller. |

## 12. Questions ouvertes

| ID | Question |
|---|---|
| K-001 | Combien de provinces et quel découpage ? |
| K-002 | Quels attributs sont obligatoires au lancement ? |
| K-003 | La population est-elle modélisée par province ou par nation ? |
| K-004 | Quel format de données pour la carte ? |
| K-005 | Comment représenter les mers et les détroits ? |
| K-006 | Quelles informations sont masquées ? |
| K-007 | Comment les infrastructures et fortifications évoluent-elles ? |
| K-008 | D'où viennent les noms et données historiques, sous quelle licence ? |

## 13. Critères de passage à « Spécifié »

- [ ] Liste des provinces validée.
- [ ] Schéma d'attributs arrêté.
- [ ] Adjacences et règles de mouvement définies.
- [ ] Ressources et production définies.
- [ ] Fortifications définies.
- [ ] Visibilité définie.
- [ ] Format de données et validateur choisis.
- [ ] Sources historiques et licences documentées.
- [ ] Validation du propriétaire.
