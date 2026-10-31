# Système économique

> **Statut :** Cadrage antérieur — existence **confirmée** par la fiche maîtresse, système non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [rules.md](rules.md) · [military-system.md](military-system.md) · [map-system.md](map-system.md) · [PROJECT.md](../../PROJECT.md)

---

> **Note de cohérence (2026-10-31) —** La fiche maîtresse (PROJECT.md v0.2.0) confirme une économie : chaque territoire produit trois ressources en quantités faible, moyenne et forte, avec budget, industrie et réarmement civil/militaire. La liste des ressources reste à définir. Voir [PROJECT.md](../../PROJECT.md) § 9 et 20.3 (Q-015 tranchée). Révision suivie par la tâche **T-031**.

## 1. Avertissement essentiel

**La fiche maîtresse confirme que le projet aura une économie.** Ce document reste un cadrage antérieur : il explore des options et des questions, il ne décrit pas le système définitif.

**[VALIDÉ]** Aucune mécanique économique n'est validée à ce jour.
**[À DÉFINIR — Q-015]** Le jeu doit-il comporter une économie ?

## 2. Pourquoi envisager une économie

**[PROPOSITION]** Une économie pourrait :

- donner du poids aux territoires conquis ;
- créer des arbitrages entre guerre, diplomatie et développement ;
- fournir des leviers de négociation (aide, sanctions, tributs) ;
- enrichir les décisions des IA ;
- différencier les puissances par leurs profils économiques.

**Contre-arguments :**

- complexité de conception et d'équilibrage ;
- risque de détourner le jeu de la diplomatie ;
- charge de tests et de simulation ;
- difficulté pour les IA de gérer un système supplémentaire ;
- risque de rendre les parties plus longues et moins lisibles.

## 3. Options

### Option A — Aucune économie

Les ressources sont abstraites ou inexistantes. La puissance vient du contrôle territorial et des unités. C'est le modèle le plus proche de Diplomacy.

- Avantages : simplicité, lisibilité, focus diplomatique.
- Inconvénients : moins de leviers de négociation matériels.

### Option B — Économie légère

Une ressource unique (or, influence, ravitaillement) produite par les centres contrôlés, utilisée pour construire, entretenir ou négocier.

- Avantages : profondeur modérée, lisible.
- Inconvénients : équilibrage à soigner, risque de « snowball ».

### Option C — Économie profonde

Plusieurs ressources, production, commerce, entretien des armées, peut-être marchés.

- Avantages : grande richesse stratégique.
- Inconvénients : très coûteux à concevoir, tester et équilibrer ; risque de surcharge cognitive.

**Aucune option n'est retenue.**

## 4. Concepts à définir si une économie existe

| Concept | Questions |
|---|---|
| Ressource(s) | Une ou plusieurs ? Stockable ou flux ? |
| Production | Par territoire, par centre, par population ? |
| Entretien | Les unités coûtent-elles ? Que se passe-t-il en cas de défaut ? |
| Construction | Coût, délai, file d'attente ? |
| Commerce | Échanges entre puissances ? Accords économiques ? |
| Sanctions | Possibles ? Effets ? |
| Aide | Transferts de ressources ? Conditions ? |
| Monnaie | Fictive ? Unique ? |
| Affichage | Comment rendre l'économie lisible ? |

## 5. Interaction avec la diplomatie

**[PROPOSITION]** Une économie rendrait possibles :

- tributs et paiements ;
- accords commerciaux ;
- sanctions ;
- prêts et dettes ;
- aides conditionnelles ;
- blocus.

Chacun de ces éléments devrait être **traçable** et exploitable par la réputation et la mémoire des IA.

**[À DÉFINIR]** Ces accords seraient-ils appliqués par le moteur ou laissés à la confiance ?

## 6. Interaction avec le militaire

- coût de recrutement et d'entretien ;
- logistique ;
- effets d'un blocus ;
- destruction d'infrastructures ;
- butin de guerre.

**[À DÉFINIR]** Ces mécaniques sont-elles souhaitables pour le MVP ?

## 7. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Complexité | Trop de ressources, de règles, de cas limites | Commencer par l'option A, prototyper B |
| Snowball | Le leader devient inarrêtable | Rendements décroissants, coalitions, coûts |
| Opacité | Le joueur ne comprend pas son économie | Interface et rapports clairs |
| IA faible | Les IA gèrent mal l'économie | IA spécialisées ou heuristiques |
| Équilibrage | Difficile à tester | Simulations et métriques |
| Scope creep | Retarde le MVP | Décision explicite et documentée |

## 8. Questions ouvertes

| ID | Question |
|---|---|
| E-001 | Y a-t-il une économie (Q-015) ? |
| E-002 | Si oui, quelle option (A, B, C) ? |
| E-003 | Quelles ressources ? |
| E-004 | Comment sont-elles produites ? |
| E-005 | Les unités ont-elles un coût d'entretien ? |
| E-006 | Les échanges économiques sont-ils possibles ? |
| E-007 | Comment éviter le snowball ? |
| E-008 | Comment les IA gèrent-elles l'économie ? |
| E-009 | L'économie est-elle visible par tous ? |
| E-010 | Est-elle nécessaire au MVP ? |

## 9. Recommandation (non validée)

**[PROPOSITION]** Pour un MVP, l'option A (pas d'économie) réduirait fortement le risque et permettrait de valider d'abord le cœur diplomatique et militaire. L'option B pourrait être ajoutée ensuite, une fois le noyau stable.

Cette recommandation ne vaut pas décision. Elle doit être arbitrée par le propriétaire.

## 10. Critères de passage à « Spécifié »

- [ ] Q-015 tranchée.
- [ ] Option retenue et justifiée par ADR si structurante.
- [ ] Ressources et production définies.
- [ ] Interactions avec militaire et diplomatie définies.
- [ ] Modèle de données mis à jour.
- [ ] Stratégie d'équilibrage et de test définie.
- [ ] Validation du propriétaire.
