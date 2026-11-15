# Mobilisation progressive — documentation du système (MIL-01 / MIL-02, phase 2)

- **Code :** `src/domains/military/mobilization_system.gd` ; comptabilité des pertes : `force_ledger.gd`.
- **Paramètres :** `data/rules/forces_rules.json`, bloc `mobilization` (postures, allocation, `defaults`, `national_parameters`).
- **Données :** échelons de `data/history/military_forces_1914.json`, repris par `tools/export/build_scenario.py`.
- **Tests :** `tests/unit/test_mobilization_phase2.gd`, `tests/unit/test_forces_mil01.gd`, `tests/ui_smoke.gd`.
- **Décisions :** T-047, T-049, T-051, T-053, T-056, T-056 bis ; MIL01-P1-D1 à D3 ; Q1 à Q10. Registre : `docs/decisions/DECISIONS_MIL01_T047_T057.md`.

**Statuts :**
- **principes validés** par les décisions ci-dessus ;
- **valeurs de jeu** (facteurs de posture, effets de l'allocation, seuils) **PROPOSÉES** ;
- **paramètres nationaux** « dérivé » (source consultée) ou **PROVISOIRES** ;
- MIL-02 (entraînement, équipement, remplacement, démobilisation) reste **OUVERT**.

## 1. Cycle

```
Échelons (base historique, par district) ─ posture + rythme national ─▶ En cours de mobilisation ─ transit ─▶ Incorporés
      │ district sans voie de communication (Q4) : non appelé            │ voie coupée : « bloqués »          │
      ▼                                                                   ▼ (repartent à la libération)       ▼
  reste dans le réservoir                                                                    unités du district complétées,
                                                                                            puis unités de réserve nouvelles
```

1. **Échelons (T-051).**
   - Allemagne et Autriche-Hongrie : deux échelons **dérivés** de sources. L'échelon résiduel, introuvable, n'est pas créé.
   - France, Russie, Royaume-Uni, Italie, Empire ottoman : **bloc unique**, présenté dans le jeu comme une *approximation non documentée historiquement* (MIL01-P1-D1). Aucun sous-échelon.
   - Chaque échelon est réparti par district (plus forts restes), selon la clé de répartition des réserves.
2. **Postures (T-053, Q1, Q2).** Ordre secret du mois ; changement **public**.

   | Posture | Effet |
   |---|---|
   | Paix | Aucun appel |
   | Préparatoire | Premier échelon (ou bloc) seulement, à la moitié du rythme |
   | Générale | Rythme complet ; ordre « appeler l'échelon suivant » permis |

   - Une baisse de posture arrête les nouveaux appels ; les cohortes en route terminent leur transit. Ce n'est pas une démobilisation.
   - La posture accélérée est **reportée** (Q1).
3. **Échelon suivant (Q10).** Il faut la posture générale, un échelon en cours entièrement appelé (hors districts sans voie) et un délai minimal d'**un mois** (provisoire, réglable). L'ouverture est **publique**.
4. **Appel mensuel (T-049, Q7).** Pour chaque district relié :

   ```
   appelés = min(réservoir du district, ⌈part initiale du district × rythme national × facteur de posture × facteur administratif⌉)
   ```

   - Rythme national `call_share_per_month` :
     - **Allemagne : 1,0 (dérivé)**. Premier échelon appelé en un mois, repère « août 1914 » (Bundesarchiv), **propre à l'Allemagne** ;
     - **autres puissances : 0,5 (PROVISOIRE, aucune source)**.
   - Facteur administratif = (part administration / 33,3 %), borné entre 0,5 et 1,5, × `administrative_capacity` nationale (1,0 provisoire partout).
5. **Transit.** `transit_months` national (1, provisoire), plus :
   - +1 mois si la part « chemins de fer » est < 15 % ;
   - +1 mois de détour (+1 si la part « logistique » est < 25 %) quand le réserviste rejoint une autre région que son district (T-056 bis).
6. **Incorporation**, à l'arrivée. Elle a lieu dans la région prévue si elle est toujours nationale et reliée à la capitale, sinon dans une autre région atteignable. Sans voie, la cohorte est **bloquée**. Si une bataille se déroule dans la région, l'incorporation est **reportée** (Q8).
   - Dans le district d'origine, les unités du district sont d'abord complétées jusqu'à `war_establishment_mult` × leur effectif de paix (2,0 proposé).
   - Le reste forme des unités de réserve de 20 000 hommes (proposé).
   - Un réserviste qui a fait un détour forme de nouvelles unités et ne complète pas les unités d'un autre district.

## 2. Allocation des moyens (T-053, Q2) : effets définis, sans coût

Trois pourcentages entiers de somme 100 ; défaut 34 / 33 / 33. Il n'y a **aucun coût économique** : c'est un arbitrage interne.

| Moyen | Effet | Ce que l'effet ne prétend pas |
|---|---|---|
| Administration | Multiplie le volume appelé (0,5 à 1,5) | Pas de capacité administrative historique (aucune donnée) |
| Chemins de fer | Sous 15 % : transit +1 mois. À 50 % ou plus : supprime le délai des districts sans liaison attestée. Ce délai vaut **0** aujourd'hui, voir §4. | **Aucune capacité ferroviaire** : la carte indique seulement la présence d'une liaison |
| Logistique | Sous 25 % : détour T-056 bis +1 mois | — |

## 3. Communications et territoire occupé (T-056 bis, Q4, Q5)

- Une voie est un chemin **terrestre** continu (détroits du graphe compris, **mer exclue**) depuis la région du district jusqu'à une région **contrôlée par la nation et reliée à sa capitale**. Il ne traverse que des régions de la nation ou de ses **alliés**.
- **District sans voie** au moment de l'appel : ses réservistes restent dans le réservoir (Q4). Cela supprime le blocage indéfini relevé par l'audit.
- **Voie coupée pendant le transit** : la cohorte passe en « bloqués ». Elle repart dès qu'une voie réapparaît (libération, changement de contrôle).
- Tout est réévalué chaque mois, après les mouvements et les batailles.

## 4. Paramètres nationaux et limites historiques

| Paramètre | Allemagne | Autres puissances | Statut |
|---|---|---|---|
| `call_share_per_month` | 1,0 | 0,5 | Allemagne : **dérivé** (Bundesarchiv) ; autres : PROVISOIRE |
| `transit_months` | 1 | 1 | PROVISOIRE (minimum technique d'un tour mensuel) |
| `administrative_capacity` | 1,0 | 1,0 | PROVISOIRE (aucune différence documentée) |
| `rail_gap_months` | 0 | 0 | **Désactivé** : couche ferroviaire de l'atlas incomplète (MAJ-006) |
| `detour_months` | 1 | 1 | PROVISOIRE |

**Pourquoi le délai ferroviaire est désactivé.** Dans l'atlas, ces districts n'ont aucun chemin ferroviaire vers leur capitale :
- Prusse-Orientale (026) ;
- Pologne russe (055, 056) ;
- Ukraine occidentale (058) ;
- Crimée (063) ;
- Irlande hors Ulster (006) ;
- Italie Centre-Est, Sud et Sicile (083 à 085).

Ces absences viennent très probablement de la couverture de l'atlas, pas de l'histoire (non vérifié). Les pénaliser ferait d'une lacune de données une certitude historique. Le mécanisme est conservé et réglable.

**Différences nationales non modélisées faute de source :** la lenteur ottomane (Erickson, non consulté), la densité ferroviaire, les capacités administratives.

## 5. Information publique (T-056, Q3)

- **Publics** (journal visible de toutes les puissances ; `IntelSystem.view_for(...)["public_mobilization"]`) : changements de posture et ouvertures d'échelon.
- **Confidentiels** : les volumes appelés et incorporés (journal du seul pays concerné). Aucun mécanisme de renseignement ne les révèle encore (INT-01/02 ouverts).
- Aucune pénalité diplomatique automatique.

## 6. Ordres de grandeur observés (`tests/balance_report.gd`, posture générale des sept puissances en janvier 1914)

- Allemagne : premier échelon (2 993 984) incorporé en un mois ; second échelon ouvert au mois 2 ; **4 610 000** présents au mois 4.
- France, Russie, Italie, Royaume-Uni, Empire ottoman (bloc unique, rythme provisoire de 0,5) : réservoir incorporé en 3 mois.
- Autriche-Hongrie : premier échelon en 2 mois, second échelon à partir du mois 3.
- 980 unités sur la carte après mobilisation complète ; calcul de 4 mois d'environ 1,9 s.

## 7. Hors périmètre

IA de mobilisation (phase 3), Territorial Force (phase 4), coûts économiques (ECO-01, 02, 05, 06 non définis), démobilisation (MIL-02).
