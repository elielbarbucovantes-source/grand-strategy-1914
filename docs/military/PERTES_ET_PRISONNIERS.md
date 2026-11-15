# Pertes et prisonniers — comptabilité nationale (MIL-01, phase 2)

- **Décision :** Q6 du directeur (15/11/2026) : suivi national rigoureux dès la phase 2, sans système médical ni de captivité complexe.
- **Code :** `src/domains/military/force_ledger.gd`. Branchements dans `src/domains/combat/battle_manager.gd` : clôture de bataille, encerclement, capitulation, armée anéantie.
- **Tests :** `tests/unit/test_mobilization_phase2.gd` (`test_war_losses_are_accounted`, `test_surrender_creates_prisoners_not_deaths`, `test_save_load_and_determinism`, `_check_conservation`).

## 1. Catégories

| Catégorie demandée | Dans le jeu | État |
|---|---|---|
| Effectifs actifs | `forces.active_start`, dont `active_on_map` | Implémenté |
| Réservistes non appelés | Σ `forces.echelons[].pool_by_region` | Implémenté |
| Réservistes en cours de mobilisation | `forces.mobilizing`, plus `forces.blocked` (voie coupée) | Implémenté |
| Soldats incorporés | `forces.incorporated` (cumul) | Implémenté |
| Présents dans les unités | somme des unités et des services | Implémenté |
| **Morts** | `military_ledger.dead = null` | **Non modélisé** : voir §3 |
| **Blessés temporairement indisponibles** | `military_ledger.wounded = null` | **Non modélisé** : voir §3 |
| Pertes (tués, blessés et disparus confondus) | `military_ledger.losses` par cause, `losses_total` | Implémenté |
| Prisonniers perdus | `prisoners_lost`, `prisoners_lost_by_captor` | Implémenté |
| Prisonniers détenus | `prisoners_held`, `prisoners_held_by_origin` | Implémenté |
| Libérés ou rapatriés | `released`, `repatriated` = 0 | **Aucun mécanisme** |
| Survivants ayant rejoint leur territoire | `rejoined` (information), toujours présents | Implémenté (MIL01-P2-D2) |

## 2. Règles d'inscription (un soldat n'est inscrit qu'une fois)

| Événement | Inscription |
|---|---|
| Fin de bataille tactique | Pour chaque unité engagée : effectif avant moins effectif après, en cause `combat`. Cela inclut le reliquat d'une unité anéantie, que la simulation remet à 0 sous le seuil minimal. |
| Attrition mensuelle d'une armée encerclée (T-044) | Cause `encirclement_attrition` |
| Capitulation d'une armée encerclée (T-044) | Tout le personnel restant (unités et services) devient prisonnier : perdu pour le pays d'origine, détenu par le contrôleur de la région |
| Armée anéantie (plus aucune unité), **avec retraite sûre** | Ses services restants **rejoignent leur territoire** : ils restent présents (`forces.services_regrouped`) et sont comptés dans `rejoined` à titre d'information (MIL01-P2-D2) |
| Armée anéantie **sans retraite sûre** | Sort inconnu, aucune capture établie : pertes (disparus), cause `annihilated_services`. **Jamais en prisonniers.** |
| Unité détruite | Rien de plus : son effectif est déjà à 0 et ses pertes sont comptées en `combat`. Elle est retirée et ne compte plus comme opérationnelle (testé). |

**Invariant de personnel** (nation historique, carte seulement ; testé en paix, pendant et après une bataille, après une capitulation, après une sauvegarde et un rechargement) :

```
présents dans les unités + services + pertes + prisonniers perdus = actifs sur la carte + incorporés
```

**Invariant des réserves :**

```
non appelés + en cours + bloqués + incorporés = réservoir initial sur la carte
```

## 3. Limites et évolutions nécessaires (non implémentées)

1. **Tués et blessés non distingués.**
   - La simulation tactique produit une perte unique par tir (`tactical_sim.gd`), conformément au principe validé des pertes définitives (MIL-07).
   - Séparer tués, blessés et disparus exigerait des ratios **sourcés**, par exemple les statistiques de pertes nationales. **Aucun ratio n'est inventé.**
   - Conséquence : les blessés qui seraient revenus au front disparaissent aujourd'hui des effectifs, à l'intérieur des « pertes ». C'est contraire à l'intention du directeur, et c'est **signalé ici comme limite**.
   - Évolution à concevoir : un ratio sourcé, une catégorie « blessés indisponibles » avec un délai de retour, et un retour vers le réservoir ou les unités.
2. **Pas de libération ni de rapatriement.** Les prisonniers restent détenus jusqu'à ce qu'un mécanisme soit défini : traité de paix, échange, libération d'une région. Il dépend de DIP-04.
3. **Pas de prisonniers en bataille tactique.** Seule la capitulation d'une armée encerclée en produit. Les unités en déroute ne sont pas capturées : la déroute relève du combat (phases suivantes).
4. **États hors MIL-01** (effectifs inconnus, `null`) : rien n'est inscrit pour eux. En revanche, un État hors MIL-01 peut **détenir** des prisonniers d'une puissance documentée.
5. **Survivants d'une armée anéantie** (décision MIL01-P2-D2) : prisonniers seulement en cas de capture établie (capitulation) ; avec une retraite sûre, ils rejoignent leur territoire ; sinon, ils sont comptés en pertes (sort inconnu).
6. **Tués, blessés et disparus** : recherche de proportions documentées prévue en **phase 5** (MIL01-P2-D3) ; aucune proportion sans source suffisante.
