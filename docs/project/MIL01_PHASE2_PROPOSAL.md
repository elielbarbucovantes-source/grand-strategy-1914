# MIL-01 — Proposition pour la phase 2 : refonte de la mobilisation

**Statut : PROPOSITION, validée par le directeur avec les décisions Q1 à Q10** (registre `docs/decisions/DECISIONS_MIL01_T047_T057.md` §5). **Implémentation : voir `docs/project/MIL01_PHASE2_REPORT.md`**, qui signale les écarts avec ce texte : délai ferroviaire désactivé, comptabilité des pertes avancée, paramètres nationaux.

**Branche :** `dev/mil01-finalisation`. **Date :** 15/11/2026.

**Décisions couvertes :**
- T-047 : catégories d'effectifs ;
- T-049 : rythme selon les capacités ;
- T-051 : échelons ;
- T-053 : posture et allocation de moyens ;
- T-056 : temps de paix, visibilité publique ;
- T-056 bis : réservistes en territoire occupé ;
- MIL01-P1-D1 à D3 : bloc unique, plafonds provisoires, réserves conservées.

**Légende des états :**

| Abréviation | Signification |
|---|---|
| **Doc.** | Documenté |
| **Prop.** | Proposé par ce document |
| **Impl.** | Implémenté |
| **Testé** | Couvert par un test qui passe |
| **Fonct.** | Fonctionnel en jeu (jouable dans l'interface) |

---

## 1. Point de départ : état réel du code

| Élément | Doc. | Impl. | Testé | Fonct. | Remarque |
|---|---|---|---|---|---|
| Cinq catégories : actif, réservoir, en cours, incorporés, présents | oui | oui | oui (en temps de paix) | oui | `MobilizationSystem.summary` |
| Invariant réservoir + en cours + incorporés = initial | oui | oui | oui | oui | Pas de suivi des pertes : phase 5 |
| Décret unique « mobilisation générale » | oui | oui | oui | oui | Tout ou rien, irréversible |
| Appel de 50 % du réservoir initial par mois, transit d'un mois | oui | oui | oui | oui | Identique pour toutes les nations |
| Incorporation seulement si la région est contrôlée et reliée à la capitale | oui | oui | oui | oui | Sinon, blocage **indéfini** |
| Échelons (T-051) | oui (base, phase 1) | **non** | données seulement | non | Le moteur ne lit pas `mobilization_echelons` |
| Bloc unique (P1-D1) | oui (base) | non | données seulement | non | |
| Rythme national (T-049) | oui | non | — | non | `national_overrides` vide |
| Posture et allocation (T-053) | oui | non | — | non | |
| Visibilité publique (T-056) | oui | non | — | non | Le journal de mobilisation n'est visible que du pays concerné |
| Voie de communication pour les réservistes occupés (T-056 bis) | oui | non | — | non | |
| Interface : pertes et prisonniers | demandé | non | — | non | Aucune comptabilité : phase 5 |
| IA de mobilisation | — | non | — | non | Phase 3 (P0-1 reste ouvert) |

---

## 2. Périmètre proposé

**Inclus :**
1. Modèle de données par échelons, y compris le bloc unique, dans le scénario et la sauvegarde.
2. Moteur d'appel par échelons, avec un rythme calculé à partir de capacités (T-049).
3. Postures de mobilisation (T-053), qui remplacent le décret unique.
4. Allocation des moyens administratifs, ferroviaires et logistiques (T-053), **sans coût économique** (voir §6).
5. Visibilité publique des postures (T-056).
6. Réservistes en territoire occupé (T-056 bis).
7. Onglet Armée : sept catégories plus les échelons. Pertes et prisonniers selon la décision Q6.
8. Tests de conservation, de sauvegarde et chargement, et de non-régression.

**Exclu :**
- IA de mobilisation : phase 3 ;
- Territorial Force (données prêtes) : phase 4 ;
- comptabilité des pertes : phase 5, sauf décision Q6 ;
- démobilisation (MIL-02 ouvert) ;
- coûts économiques ;
- tout recalibrage du combat.

---

## 3. Règles de mobilisation envisagées (toutes PROPOSÉES)

### 3.1 Modèle de données (`nations[n].forces` dans le scénario)

```
forces.echelons = [
  {id, label_fr, status: "dérivé" | "bloc_unique", documented: bool,
   pool_initial, pool, unlocked: bool, opened_turn}
]
forces.mobilizing = [{region, soldiers, ready_turn, echelon_id, origin_region}]
forces.blocked    = [{region, soldiers, echelon_id, since_turn}]   # T-056 bis : sans voie de communication
forces.posture, forces.allocation, forces.posture_history
```

**Invariant étendu (testé chaque mois) :**

Σ `echelons.pool` + Σ `mobilizing` + Σ `blocked` + `incorporated` = `reserve_pool_initial` (sur la carte).

- `reserve_pool` devient la somme des échelons, gardée pour compatibilité.
- Les réserves hors carte restent hors de ce calcul, comme aujourd'hui.

**Échelons repris de la base :**
- **Allemagne et Autriche-Hongrie** : premier échelon et échelons suivants, statut « dérivé ».
  - L'échelon résiduel (`null`) n'est **pas** créé.
  - Seule la part sur la carte est reprise, à la même proportion que le réservoir. Les deux puissances ont tout leur réservoir sur la carte, la proportion vaut donc 1.
- **France, Russie, Royaume-Uni, Italie, Empire ottoman** : un seul échelon `bloc_unique`, égal au réservoir sur la carte.
  - Il porte le statut « approximation non documentée historiquement » (P1-D1), affiché dans l'interface et dans le journal.
  - Aucun sous-échelon n'est créé.

### 3.2 Ouverture des échelons (T-051)

| Règle | Proposition |
|---|---|
| Premier échelon (ou bloc unique) | Ouvert par une posture de mobilisation (§3.4) |
| Échelons suivants | Ouverts seulement si le premier échelon est entièrement appelé **et** si le joueur donne un ordre distinct, « appeler l'échelon suivant ». Un délai minimal de N mois après l'ouverture du premier échelon s'applique (paramètre **PROPOSÉ**, 1 par défaut). **Aucune source consultée ne donne ce délai.** |
| Échelon résiduel | Non modélisé (valeur `null`) |

### 3.3 Rythme d'appel (T-049)

**Capacité mensuelle d'appel d'une nation :**

```
capacité = Σ sur les districts sur la carte, actifs (contrôlés, et reliés selon §3.6) :
             capacité_de_district × f_admin(allocation) × f_posture
appelés  = min(capacité, réservoir restant de l'échelon ouvert)
```

**Transit d'une cohorte :**

```
transit = transit_de_base (1 mois)
        + 1 mois si la région du district n'a aucune liaison ferroviaire attestée
          sur un chemin ami vers la capitale
        − réduction selon f_rail(allocation)          (borné à 1 mois minimum)
```

**Logistique :** `f_logistique(allocation)` agit sur l'incorporation hors du district d'origine (T-056 bis) et sur le délai supplémentaire de ce détour.

**Ce qui vient des données, et non d'un paramètre :**
- le nombre de districts, sourcé : c'est l'appareil administratif de recrutement, puisque chaque corps a son district ;
- le contrôle et la continuité avec la capitale (déjà dans le jeu) ;
- les 91 liaisons ferroviaires attestées de l'atlas (`rail_region_links`).

**Limite :** les liaisons ferroviaires disent seulement qu'une ligne **existe**. Elles ne donnent ni capacité ni densité. Ce n'est qu'un indicateur faible des « infrastructures ferroviaires » de T-049.

**Ce qui reste un paramètre PROPOSÉ, identique pour toutes les nations :**
- `capacité_de_district` ;
- les effets des postures et de l'allocation.

**Aucune différence nationale n'est inventée.** Les différences viennent du nombre de districts, du réseau et de la géographie, et plus tard de `national_overrides` sourcés.

**Calage historique proposé (une seule cible sourcée) :** en posture générale avec une allocation équilibrée, le premier échelon allemand (2 993 984 sur 25 districts) doit pouvoir être appelé **en un mois**, comme en août 1914 (« August 1914 3,8 Mio. Mann mobil gemacht », Bundesarchiv). Cela donne une `capacité_de_district` d'environ 120 000 hommes par mois. Cette valeur s'appliquerait **à toutes les nations** ; aucune autre cible historique n'est disponible.

### 3.4 Postures (T-053)

| Posture | Effet proposé | État |
|---|---|---|
| Paix | Aucun appel | Prop. |
| Préparatoire | Premier échelon ou bloc ouvert, à **50 %** de la capacité | Prop. (valeur de jeu) |
| Générale | Premier échelon ou bloc à 100 % ; ordre « échelon suivant » permis | Prop. |
| Accélérée | Capacité × 1,5 et transit −1 mois (minimum 1) | **Prop., à décider (Q1)** : sans économie, elle n'a aucun coût |

- La posture est un ordre secret du mois, comme les autres.
- Elle peut changer chaque mois, y compris à la baisse. Une baisse arrête les **nouveaux** appels ; les hommes déjà appelés terminent leur transit. Ce n'est **pas** une démobilisation (MIL-02 ouvert).
- L'ordre actuel `mobilize` deviendrait l'équivalent de « posture générale », gardé pour compatibilité.

### 3.5 Allocation des moyens (T-053)

- Trois curseurs : administration, chemin de fer, logistique. Leur somme fait toujours 100 % ; l'allocation équilibrée est de 34 / 33 / 33.
- C'est un **arbitrage sans coût** : renforcer un poste affaiblit les autres. Cette règle est cohérente sans rien inventer d'économique.

| Moyen | Effet proposé |
|---|---|
| Administration | `f_admin` = 0,5 + allocation (borné), multiplie la capacité d'appel |
| Chemin de fer | Réduit le transit (−1 mois au-delà de 50 %) |
| Logistique | Permet le détour des réservistes occupés (T-056 bis) au-delà de 25 % ; réduit le délai de ce détour |

- L'allocation est réglée par un ordre du mois. Pour éviter la microgestion, elle garde sa valeur d'un mois à l'autre.

### 3.6 Temps de paix et visibilité publique (T-056)

- La mobilisation reste libre en temps de paix et n'entraîne **aucune** pénalité diplomatique automatique. C'est déjà le cas.
- **Information publique**, ajoutée à un journal public lisible par toutes les nations et par la future IA :
  - le changement de posture, avec le mois et la nation ;
  - l'ouverture d'un échelon.
- Les **volumes** ne sont pas publics ; ils restent du ressort du renseignement (`IntelSystem`). Le contenu exact de l'information publique est à décider (Q3).

### 3.7 Réservistes en territoire occupé (T-056 bis)

**Au moment de l'appel :** si la région d'un district est occupée et n'a aucune voie de communication accessible, ses réservistes ne sont **pas appelés** et restent dans l'échelon. Cela supprime le blocage indéfini constaté par l'audit (P2-1). Alternative : Q4.

**Définition proposée d'une voie de communication accessible :**
- un chemin terrestre, détroits compris (les règles du graphe actuel), depuis la région du district ;
- jusqu'à une région **amie** (contrôlée par la nation ou un allié, selon la règle `LogisticsSystem.friendly`) reliée à la capitale ;
- en ne traversant que des régions amies, la région de départ mise à part ;
- la voie maritime est exclue tant que le réseau naval est incomplet (U3).

**À l'incorporation :**
- les réservistes d'un district occupé mais disposant d'une voie sont incorporés dans la **première région amie** de ce chemin, avec un délai supplémentaire d'un mois ;
- sans voie, ils passent dans la catégorie `blocked`, visible dans l'interface ;
- dès qu'une voie réapparaît, par libération ou par changement de contrôle, ils reprennent leur route.

**Évaluation :** à chaque résolution mensuelle, après les mouvements et les batailles. Elle tient donc compte des changements de contrôle et des voies coupées.

### 3.8 Correctif annexe (audit P2-8)

- Ne pas créer une nouvelle armée de réserve dans une région où une bataille est en cours.
- Les incorporés attendent la fin de la bataille, ou rejoignent la région amie la plus proche.
- **Modification de mécanisme : soumise à validation (Q8).**

---

## 4. Fichiers concernés

| Fichier | Modification prévue |
|---|---|
| `src/domains/military/mobilization_system.gd` | Échelons, capacité, postures, allocation, voies de communication, catégorie `blocked`, journal public. Refonte de `_call_up` et `_incorporate_ready` ; `incorporate` est conservée. |
| `src/simulation/orders.gd`, `turn_resolver.gd` | Ordres `set_posture`, `set_allocation`, `call_next_echelon` ; validation ; `mobilize` gardé comme alias |
| `src/app/game_session.gd` | Mise en file et validation des nouveaux ordres ; `summary` étendu |
| `src/simulation/game_state.gd` | Sérialisation des nouveaux champs ; journal public |
| `src/adapters/save_repository.gd` | `FORMAT_VERSION` +1. Une sauvegarde ancienne est **refusée** avec un message clair (pas de migration), sauf avis contraire (Q9). |
| `src/domains/intelligence/intel_system.gd` | Lecture du journal public par les autres nations |
| `src/ui/game_ui.gd` | Onglet Armée : catégories, échelons et statut d'approximation, posture, allocation, journal public |
| `tools/export/build_scenario.py` | Reprise des échelons et du bloc unique depuis la base vers le scénario |
| `data/rules/forces_rules.json` | Paramètres de capacité, de posture, d'allocation et de transit, tous marqués **PROPOSÉS** |
| `tests/unit/test_forces_mil01.gd`, nouveau `tests/unit/test_mobilization_phase2.gd`, `tests/ui_smoke.gd`, `tests/balance_report.gd` | Voir §8 |
| `docs/military/MOBILISATION.md`, `docs/decisions/DECISIONS_MIL01_T047_T057.md`, rapport de phase 2 | Documentation |

**Non touchés :**
- `src/ai/*` : l'IA ne mobilise toujours pas, jusqu'à la phase 3 ;
- le combat ;
- la carte ;
- la base historique, sauf erreur factuelle.

---

## 5. Compatibilité avec le multijoueur futur

- Les postures et allocations sont des **ordres secrets** résolus simultanément, comme tous les ordres (TURN-02).
- Le journal public est un état partagé, déterministe et sérialisé.
- Aucun calcul ne dépend de l'ordre des pays : les districts sont triés et les répartitions faites par la méthode des plus forts restes, déjà en place.

---

## 6. Dépendances avec le système économique

**Aucun coût fictif ne sera créé** (consigne du directeur). Les points de branchement sont identifiés et laissés **en attente**, avec la valeur `null` et un statut explicite dans les données, sur le modèle de `EconomySystem`.

| Besoin de T-053 | Mécanisme économique requis | État |
|---|---|---|
| Coût d'entretien des mobilisés (solde, vivres) | ECO-05 (budget), ECO-01 (nourriture) | À DÉFINIR |
| Retrait des travailleurs de la production | ECO-02 (production), ECO-06 (main-d'œuvre industrielle) | À DÉFINIR |
| Équipement des réservistes | ECO-06 (industrie), MIL-02 (équipement) | À DÉFINIR |
| Coût de la posture accélérée | ECO-05 | À DÉFINIR |
| Usage civil du chemin de fer pendant la mobilisation | ECO-02, MIL-04 | À DÉFINIR |

**Conséquence :** en phase 2, les seules contraintes réelles seront physiques et administratives (capacité, transit, territoire, voies de communication) et l'arbitrage interne de l'allocation. La posture accélérée serait donc gratuite (Q1).

---

## 7. Difficultés

### 7.1 Historiques

1. **Un seul point de calage sourcé** : l'Allemagne en août 1914. Les rythmes des autres puissances suivront les mêmes paramètres, donc une approximation. L'Empire ottoman, notoirement lent selon Erickson (non consulté, aucun chiffre utilisable), ne sera pas différencié.
2. **Bloc unique pour 5 puissances sur 7 (P1-D1).** Leur réservoir entier sera appelable au rythme commun. Elles pourront donc mobiliser plus vite et plus complètement qu'un plan de 1914 ne le permettait. C'est une approximation affichée, pas un fait historique.
3. **Chemin de fer** : l'atlas indique la présence d'une ligne, pas sa capacité. La densité réelle des réseaux (Allemagne et France denses, Russie et Empire ottoman faibles) n'est que partiellement représentée.
4. **Capacités administratives** : aucune donnée. Le nombre de districts n'en est qu'un indicateur.
5. **Départ en janvier 1914 (T-057)** : une mobilisation dès le premier mois est possible, ce qui est ahistorique mais permis par T-056. Sans l'IA (phase 3), un joueur peut mobiliser sans réaction adverse.

### 7.2 Techniques

1. **Sauvegardes** : le format change. L'ancien format sera refusé (Q9).
2. **Équilibrage** : le rythme et le volume des renforts changent. `balance_report` et les tests d'intégration de campagne seront relancés et leurs écarts publiés.
3. **Performance** : le nombre d'unités après mobilisation reste comparable (963). Le calcul des voies de communication ajoute un parcours de graphe par nation et par mois, ce qui est négligeable sur 90 régions.
4. **Interface** : afficher les échelons sans microgestion, en un seul panneau.
5. **Asymétrie avec l'IA** : elle persiste jusqu'à la phase 3 (P0-1).

---

## 8. Tests nécessaires

| Test | Vérifie |
|---|---|
| Conservation par échelon | L'invariant étendu, chaque mois, sur 12 mois de mobilisation, pour les sept puissances |
| Pas d'appel au-delà d'un échelon | Les échelons suivants restent fermés tant que le premier n'est pas épuisé, que l'ordre n'est pas donné et que le délai n'est pas écoulé |
| Pas d'échelon résiduel | Un échelon `null` n'est jamais appelé |
| Bloc unique | Les 5 puissances concernées ont un seul échelon, signalé comme approximation dans le résumé et le journal |
| Rythme | La capacité dépend des districts contrôlés, de l'allocation et de la posture ; le calage allemand se fait en un mois en posture générale |
| Postures | Paix = 0 appel ; une baisse de posture arrête les nouveaux appels sans perdre les cohortes en route |
| Allocation | La somme fait 100 % ; chaque curseur a l'effet annoncé ; l'allocation n'a aucun coût économique |
| Visibilité publique | Les autres nations voient la posture, pas les volumes ; les ordres restent secrets jusqu'à la résolution |
| T-056 bis | Occupation avec voie : incorporation dans la région amie et délai. Sans voie : `blocked`, puis reprise après libération. Pas d'appel dans un district sans voie. |
| Bataille en cours (si Q8 est accepté) | Aucune nouvelle armée de réserve dans la région d'une bataille |
| Sauvegarde et chargement | Empreinte identique avant et après, pendant une mobilisation par échelons, avec des cohortes bloquées ; refus d'une sauvegarde de l'ancien format |
| Déterminisme | Deux exécutions identiques ; résultat indépendant de l'ordre des pays et des ordres |
| Non-régression | Les 55 tests actuels, `ui_smoke` et `battle_ui_smoke` |
| Interface | `ui_smoke` : posture, allocation et lecture des sept catégories |

---

## 9. Décisions nécessaires

| N° | Question | Proposition par défaut |
|---|---|---|
| **Q1** | Posture **accélérée** : la proposer dès la phase 2 alors qu'elle n'a aucun coût (l'économie n'est pas définie), la reporter, ou la limiter à une contrainte physique (rail) ? | **La reporter** jusqu'à la définition d'ECO-05 |
| **Q2** | Postures **Paix, Préparatoire, Générale** et allocation à **somme fixe** (trois curseurs, arbitrage sans coût) : est-ce conforme à votre intention pour T-053 ? | Oui |
| **Q3** | **Information publique** (T-056) : posture et ouverture d'échelon seulement, ou aussi les volumes appelés ? | Posture et échelon seulement ; volumes par le renseignement |
| **Q4** | **District occupé sans voie** au moment de l'appel : ne pas appeler (les hommes restent dans l'échelon), ou appeler puis bloquer ? | Ne pas appeler |
| **Q5** | **Voie de communication** (T-056 bis) : le territoire allié compte-t-il ? La voie maritime est-elle exclue tant que le réseau naval est incomplet ? | Allié inclus ; voie maritime exclue |
| **Q6** | **Pertes et prisonniers** dans l'interface (exigence 2.7) : afficher « non comptabilisé (phase 5) », ou avancer en phase 2 une comptabilité minimale (compteurs nationaux de pertes et de redditions, sans prisonniers détenus) ? | Avancer la comptabilité minimale (compteurs seulement) |
| **Q7** | **Calage du rythme** : la cible unique « premier échelon allemand appelé en un mois en posture générale » s'applique-t-elle à toutes les nations ? | Oui, faute d'autre source |
| **Q8** | **Correctif P2-8** (pas de nouvelle armée de réserve dans une région en bataille) : l'inclure en phase 2 ? | Oui |
| **Q9** | **Anciennes sauvegardes** : refus clair ou migration ? | Refus (prototype) |
| **Q10** | **Délai minimal avant l'échelon suivant** (aucune source) : 1 mois par défaut, configurable ? | Oui, marqué PROPOSÉ |

---

## 10. Ce qui ne sera PAS fait sans nouvelle décision

- Aucun coût économique, même provisoire.
- Aucun sous-échelon pour les puissances en bloc unique.
- Aucun relèvement des réserves françaises ou russes.
- Aucune différence de rythme nationale non sourcée.
- Aucune modification de l'IA, du combat ou de la Territorial Force.
