# Mobilisation progressive — documentation du système (MIL-01 / MIL-02)

- **Code :** `src/domains/military/mobilization_system.gd`.
- **Paramètres :** `data/rules/forces_rules.json` (bloc `mobilization`).
- **Tests :** `tests/unit/test_forces_mil01.gd`, `tests/ui_smoke.gd`.

**Statuts :**
- **Principe VALIDÉ** par le directeur (15/11/2026) : réserves disponibles mais non incorporées au départ ; mobilisation progressive ; aucune apparition instantanée, aucun dépassement des réserves, aucun double comptage.
- **Toutes les valeurs numériques sont PROPOSÉES.**
- MIL-02 (recrutement, entraînement, équipement, remplacement, démobilisation) reste **OUVERT**.

## 1. Cycle

```
Réservoir (B, sourcé) ──appel mensuel──▶ En cours de mobilisation ──après transit_months──▶ Incorporés
                                             (cohortes par district)                          │
                                                                                               ▼
                                                     unités du district complétées jusqu'à l'effectif de guerre,
                                                     puis nouvelles unités de réserve dans la région du district
```

1. **Décret.**
   - Ordre secret `mobilize`, appliqué à la résolution du mois, comme tout ordre.
   - Une seule fois par partie : la démobilisation est ouverte.
   - Refusé pour un pays sans données historiques, et dans le bac à sable.
2. **Appel**, à chaque fin de mois après le décret.
   - `call_share_per_month` × réservoir **initial** est rappelé (0,5 proposé), sans dépasser le réservoir restant.
   - Les rappelés sont répartis entre les districts selon la clé de répartition (voir `docs/history/MIL01_METHODE.md` §3).
3. **Transit.**
   - Les rappelés restent `transit_months` mois « en cours de mobilisation » (1 proposé) : rejoindre le dépôt, être équipé.
   - Rien n'apparaît le mois du décret.
4. **Incorporation**, à la fin du mois suivant, seulement si la région du district est **contrôlée** par le pays **et reliée à sa capitale** (`LogisticsSystem`). Sinon les rappelés attendent.
   - Une part va aux **services**, selon la ventilation sourcée : présents, non combattants.
   - Les unités du district encore présentes dans leur district, non engagées et non encerclées, sont **complétées** jusqu'à `war_establishment_mult` × leur effectif de paix (2,0 proposé).
   - Le reste forme de **nouvelles unités de réserve** de `new_unit_soldiers` (20 000 proposé) dans la région. Un reliquat trop petit attend le mois suivant.

## 2. Garanties (vérifiées par les tests)

| Exigence | Mécanisme | Test |
|---|---|---|
| Pas d'apparition instantanée | Transit d'un mois | `test_progressive_mobilization_without_double_counting` |
| Pas de dépassement des réserves | Appel borné par le réservoir restant | idem (réservoir à 0, jamais négatif) |
| Pas de double comptage | Seul le réservoir alimente les unités ; un actif n'y figure jamais | Présents = actifs + incorporés, exactement |
| Pas de soldat sans origine | Invariant réservoir + en cours + incorporés = réservoir initial | Vérifié chaque mois |
| Pas de mobilisation d'incorporés | Une cohorte quitte la liste « en cours » dès son incorporation | idem |
| District occupé | Pas d'incorporation ; les rappelés attendent | `test_mobilization_blocked_in_occupied_district` |
| Données insuffisantes signalées | Refus motivé pour les États hors MIL-01 et le bac à sable | `test_campaign_and_sandbox_are_separate` |

## 3. Différences nationales

- **Aucune n'est inventée.** Les paramètres sont identiques pour toutes les nations.
- Les différences entre pays viennent uniquement des données sourcées : taille de l'armée active, taille du réservoir, part hors carte, ventilation par arme, nombre et position des districts.
- Le bloc `national_overrides` permet d'ajouter un rythme national **s'il est sourcé**.
  - Exemple de piste : Erickson indique que l'armée ottomane n'était pas apte au combat avant décembre 1914.
  - Il reste vide.

## 4. Influence de l'économie

**OUVERTE.** L'équipement, le coût et l'effet sur la production (ECO-01/02, R-03) ne sont pas définis. Aucune contrainte économique n'est appliquée. Les seules contraintes actuelles sont territoriales : contrôle de la région et liaison avec la capitale.

## 5. Ordres de grandeur observés (simulation, `tests/balance_report.gd`)

- Avec les paramètres proposés, tout le réservoir sur la carte est appelé en 2 mois et incorporé en 3 mois.
- L'Allemagne passe de 806 016 à 4 806 016 présents ; il y a 974 unités sur la carte après mobilisation complète des sept puissances.
- Pour comparaison historique, le Bundesarchiv indique 3,8 millions d'hommes mobilisés en août 1914, actifs compris. Le réservoir de la source commune, 4,0 millions de réservistes instruits, dépasse donc le rappel effectif d'août 1914.
- C'est cohérent avec la définition (tous les instruits), mais **le rythme et le plafond d'appel sont à arbitrer par le directeur**.
