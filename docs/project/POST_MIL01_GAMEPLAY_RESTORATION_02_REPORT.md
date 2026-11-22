# POST_MIL01_GAMEPLAY_RESTORATION_02_REPORT — Commerce, classement, diffusion et confiance

> **Date :** 2026-11-22
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation` (jamais `main`)
> **Référence :** `docs/project/POST_MIL01_GAMEPLAY_RESTORATION_01_REPORT.md` (limites §9)
> **Nature :** amélioration des quatre mécanismes identifiés. Aucune nouvelle phase, aucune
> fusion, aucune réécriture d'historique, aucun push forcé.

---

## 1. Problèmes initiaux (hérités de RESTORATION 01)

| Limite | Observation de référence |
|---|---|
| Commerce quasi inexistant | 2 ordres / 120 tours ; aucune livraison traçable. |
| Classement figé | Russie / Allemagne / Autriche-Hongrie du tour 12 au tour 120. |
| Diffusion technologique inactive | `diffusion_cost_factor` et `transfer_months` définis mais jamais utilisés. |
| Trahison rare | 1 rupture / 120 tours en contexte diplomatique actif, 0 en paix. |

---

## 2. Causes identifiées

### Commerce
1. `MarketSystem` lisait `rules["trade"]` alors que la configuration est sous `rules["economy_model"]["trade"]` — `route_capacity_share` et `max_imports_per_nation_per_month` étaient morts.
2. Le trafic était une boîte noire : route calculée puis **jetée**, aucun `path`, aucune capacité engagée (`TransportRouter.commit()` jamais appelé), impossible de certifier une livraison.
3. Aucun prix : l'exportateur ne recevait rien, l'importateur ne payait rien.
4. `EconomicAI` utilisait un double seuil fixe (`stock < 5` / fournisseur `≥ 10`) et un `break` inconditionnel dès le premier fournisseur — un refus de route annulait tout commerce.
5. L'IA ne proposait aucun accord `trade`/`transit` : la plupart des capitales étaient inaccessibles faute de traité de passage.
6. Le profil économique `commercial` n'influençait pas la décision commerciale ; `autarkic` commerçait comme les autres.
7. Aucune interface joueur pour commercer (seule l'IA émettait des ordres).

### Classement
8. Aucun indicateur global n'existait. `VictorySystem.final_summary()` ne classe qu'en fin de partie et uniquement sur le contrôle militaire. Les 12 champs `stats` du scénario sont `null` (« À DÉFINIR »).

### Diffusion
9. `can_research()` ne vérifiait aucun accord ; `diffusion_cost_factor`, `transfer_months` et `capture_cost_factor` n'étaient utilisés que dans des tests arithmétiques. Aucun type d'accord `tech` n'existait.
10. L'IA de recherche choisissait toujours les technologies dans le même ordre → les partenaires découvraient les mêmes techs, rendant le transfert inutile.
11. L'espionnage existant (`Orders.INTERCEPT`) ne fournit qu'un renseignement, jamais une technologie : il ne doit pas être confondu avec la coopération.

### Confiance / trahison
12. La rupture ne vérifiait qu'un seul motif (`trust < 25`) avec un garde-fou de personnalité ; `leave_alliance` n'écrivait ni mémoire ni réputation.
13. La pénalité de réputation de `change_government()` était écrasée le même tour par le recalcul mensuel.
14. Un bug d'expiration d'alliance passait l'identifiant d'alliance là où un ID de nation était attendu — pénalité silencieusement ignorée.

---

## 3. Corrections apportées et fichiers modifiés

### 3.1 Commerce international
- **`market_system.gd`** : lecture correcte de `economy_model.trade` ; prix par ressource payé par l'importateur à l'exportateur ; itinéraire réel conservé dans l'expédition (`path`, `links`, `modes`, `time`, `bottleneck`) ; `TransportRouter.commit()` engage la capacité ; une liaison interrompue **retarde** la livraison ; cache de routes par tour.
- **`economic_ai.gd`** : réserve stratégique calculée depuis les intrants industriels réels, demande récurrente, profil `trade` pondérant les quantités (`autarkic` = 0), tous les fournisseurs testés (score de confiance/coopération/accords calculé une seule fois), quota d'importations respecté.
- **`diplomacy_rules.json`** : type d'accord `trade` avec engagement `transit: true` (passage commercial), seuil d'acceptation assoupli, initiative commerciale avec cooldown dédié de 12 tours et préférence de voisinage.
- **`intel_system.gd`** : vue IA enrichie de `own_stocks` et de la dépendance commerciale agrégée (données propres/publicaines uniquement).
- **`economy_system.gd`** : transmission des règles au cycle commercial mensuel.

### 3.2 Classement dynamique
- **`power_rank_system.gd`** (nouveau) : score composite 0-100 en huit composantes (démographie, industrie, économie, technologie, militaire, stabilité, prestige, territoire), rang, variation depuis le début et historique borné.
- **`power_rules.json`** (nouveau) : poids et échelles explicites, sans lien avec les conditions de victoire.
- **`game_state.gd` / `game_session.gd` / `turn_resolver.gd`** : champ `power` sérialisé (compatible anciennes sauvegardes via valeur par défaut), recalcul mensuel après économie/technologie.
- **`game_ui.gd`** : section « Puissance des États » ajoutée à la page Victoire existante (rang, score, variation, trois facteurs clés), sans nouvel onglet ni nouveau système d'affichage.

### 3.3 Diffusion technologique
- **`diplomacy_rules.json` / `diplomacy_system.gd`** : nouveau type d'accord `tech`, enregistré par `TechSystem.register_cooperation()`.
- **`tech_system.gd`** : accords de coopération, transferts d'une technologie **déjà découverte** par le donneur, coût réduit par `diffusion_cost_factor`, délai `transfer_months`, part versée au donneur, dépendance aux prérequis et à la limite temporelle de l'arbre ; réduction du coût de recherche d'un projet déjà connu d'un partenaire.
- **`phase6_ai.gd`** : diversification déterministe des choix de recherche par graine (bruit ±0,15), pour que les partenaires aient des technologies différentes à échanger.
- **`intel_system.gd`** : exposition publique des accords de coopération uniquement — aucun renseignement technologique adverse, espionnage inchangé.

### 3.4 Confiance et trahisons
- **`diplomatic_ai.gd`** : `review_commitments()` évalue cinq motifs déterministes (confiance effondrée, rivalité devenue insoluble, changement de gouvernement, dépendance commerciale excessive, divergence stratégique), filtrés par `reputation_value` et `war_likelihood`. Les profils opportunistes utilisent `break_treaty` (trahison mémorisée), les autres `leave_alliance`.
- **`relations_system.gd`** : nouvel événement `alliance_exit` (confiance, tensions, hostilité, réputation), `alliance_betrayal` pris en compte dans la réputation, pénalité persistante des changements de gouvernement.
- **`alliance_system.gd`** : sortie d'alliance mémorisée, correction du bug d'expiration.
- **`political_system.gd`** : pénalité de réputation stockée dans `government_penalty` au lieu d'une écriture éphémère.

---

## 4. Nouveaux tests

`tests/unit/test_gameplay_restoration_02.gd` — **17 tests** : paiement et traçage commercial, livraison conditionnée au réseau praticable, dépendance de l'activité au profil économique, persistance des transactions, score de puissance explicable et borné, réaction du classement à un choc, séparation puissance/victoire, transfert technologique réel, absence de copie gratuite, réduction du coût de recherche, persistance des coopérations, différences de trahison selon la personnalité, conséquences de réputation et de mémoire, persistance de la pénalité de gouvernement, effet relationnel d'un accord commercial, effet d'une avancée technologique sur la puissance, reproductibilité par graine.

Tests existants renforcés (sans affaiblissement) : `test_economy_phase5.gd` vérifie désormais le paiement, le chemin et la capacité engagée ; `test_phase7.gd` vérifie la persistance de la dégradation de réputation après recalcul mensuel.

---

## 5. Résultats des campagnes

Matrice complète exécutée : **3 graines × 7 contextes × 4 durées = 84 campagnes**, **0 erreur
GDScript**. Script : `/tmp/opencode/gp_observe_r02.gd`.

### 5.1 Comparatif RESTORATION 01 → 02 (120 tours, contexte paix, graine 1914)

| Métrique | RESTORATION 01 | RESTORATION 02 |
|---|---:|---:|
| Ordres commerciaux | 2 | 10 |
| Livraisons effectivement réalisées | 0 (non tracées) | 10 |
| Accords commerciaux actifs | 0 | 13 (à 24 tours) |
| Transferts technologiques livrés | 0 | 10 |
| Technologies connues (total) | 276 | 294 |
| Ruptures d'engagement | 1 (contexte diplomatique) | 5 (dont 1 trahison mémorisée) |
| Propositions d'accord | 88 | 256 |
| Première puissance au T120 | Russie | **Italie** (70,26) |
| Stocks négatifs | 0 | 0 |

### 5.2 Diversité des graines (120 tours, paix)

| Graine | Livraisons | Transferts | Trahisons | Propositions | 1re puissance (score) |
|---|---:|---:|---:|---:|---|
| 1914 | 10 | 10 | 5 | 256 | Italie (70,26) |
| 7 | 26 | 8 | 6 | 233 | Russie (69,33) |
| 2026 | 25 | 18 | 5 | 230 | Espagne (71,20) |

Le classement n'est plus figé : selon la graine, l'Italie, la Russie ou l'Espagne termine
en tête. Les volumes commerciaux et les transferts technologiques varient également, tout en
restant reproductibles pour une graine donnée (test dédié).

### 5.3 Contextes notables (graine 1914, 24 tours)

| Contexte | Guerres | Livraisons | Transferts | Trahisons | Technologies |
|---|---:|---:|---:|---:|---:|
| Paix | 2 | 2 | 6 | 4 | 55 |
| Forte rivalité | 2 | 2 | 5 | 4 | 55 |
| Crise économique | 2 | 2 | 6 | 4 | 55 |
| Mobilisation | 2 | 2 | 6 | 4 | 55 |
| Coopération commerciale | 2 | 2 | 7 | 4 | 55 |
| Coopération scientifique | 2 | 2 | **10** | 4 | **59** |
| Instabilité diplomatique | 1 | 2 | 5 | 0 | 55 |

La coopération scientifique augmente mesurablement les transferts (6 → 10) et les
découvertes (55 → 59). L'instabilité intérieure bloque l'initiative diplomatique (0 trahison),
ce qui est cohérent avec les garde-fous de stabilité.

## 6. Interactions entre systèmes

- **Commerce → diplomatie** : la conclusion d'un accord commercial augmente la confiance (`treaty_signed`, +6).
- **Commerce → confiance → trahison** : la dépendance commerciale agrégée alimente le motif « dépendance excessive » de la réévaluation des engagements.
- **Réseau → commerce** : une liaison interrompue retarde la livraison ; la capacité réellement consommée est conservée dans l'expédition.
- **Coopération → technologie → puissance** : un transfert ajoute une technologie à la composante `technology` du score de puissance, mesuré par test dédié.
- **Coopération → recherche** : un projet déjà connu d'un partenaire coûte moins cher (`diffusion_cost_factor`).
- **Crise économique → classement** : la mise à zéro des stocks réduit mesurablement le score du pays concerné.
- **Rupture → réputation → diplomatie** : trahison mémorisée, confiance et réputation dégradées, ce qui rend les futurs accords plus difficiles à conclure.

---

## 7. Régressions et non-régression

- Aucune régression détectée : la suite complète est exécutée et doit rester verte.
- La durée de la suite (~9 min) correspond au temps de référence du commit `508ae20` (~9 min 18 s), mesuré dans un worktree distinct : pas de ralentissement introduit.
- La reproductibilité par graine est conservée (test dédié).
- Les sauvegardes anciennes restent lisibles : le nouveau champ `power` et les sous-clés `tech` ont des valeurs par défaut, sans bump de `FORMAT_VERSION`.

---

## 8. Limites restantes

1. Le volume commercial reste modeste (2 ordres / 24 tours en paix) : le commerce est limité aux blocs reliés par des accords de passage, ce qui est cohérent mais restrictif.
2. Les propositions d'accords restent nombreuses (256 / 120 tours) malgré les cooldowns ; elles ont diminué de 457 à 256 au cours du chantier.
3. Le transfert technologique suppose un accord explicite : aucun transfert « informel » par espionnage industriel (INT-02 reste ouvert, par choix).
4. Le classement évolue désormais (Italie, Russie ou Espagne en tête selon la graine), mais reste dominé par la démographie et l'industrie : le rattrapage est réel mais graduel.
5. Le bonus `industry_mult` des technologies reste non consommé par l'industrie (limite héritée).
6. Aucune interface joueur dédiée au commerce ou aux transferts technologiques ; ces mécanismes sont pilotés par l'IA et les ordres scripts.

---

## 9. Verdict

**B — progrès réels, limitations persistantes.**

Les quatre systèmes demandés sont désormais **implémentés**, **testés automatiquement** et **observés en campagne** (livraisons, transferts, variations de classement et ruptures), avec des interactions mesurables entre eux. Le grade A est écarté : le volume commercial et la fréquence des propositions restent imparfaits, et deux mécanismes (espionnage industriel, `industry_mult`) demeurent hors périmètre.

---

**Fin de mission. Aucune nouvelle phase lancée. En attente de validation du directeur.**
