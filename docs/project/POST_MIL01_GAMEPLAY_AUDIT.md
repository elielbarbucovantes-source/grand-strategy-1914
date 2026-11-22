# POST_MIL01_GAMEPLAY_AUDIT — Audit approfondi du gameplay

> **Date :** 2026-11-21
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`, `HEAD = 5e08928`, arbre propre.
> **Nature :** audit uniquement. **Aucun code, paramètre ou donnée modifié ; aucun commit, aucun
> push.** Scripts d'observation créés dans `/tmp/opencode/`, hors dépôt.

---

## 1. Verdict général — **C : Gameplay incomplet**

Les systèmes sont techniquement solides (221 tests, 36 scénarios de consolidation, export
exécutable), mais **ils ne produisent pas encore une expérience de grande stratégie vivante**
lorsqu'on laisse une campagne évoluer sans intervention artificielle.

Faits déterminants observés sur 120 tours (1914 → 2024) avec trois graines :
- **0 technologie découverte**, malgré 42 ordres de recherche ;
- **0 déclaration de guerre par une IA** — les guerres n'existent que si le joueur ou un script
  les force (aucun `declare_war` dans `src/ai/` ou `src/domains/`) ;
- **3 ordres de commerce et 0 investissement dans les ressources** sur 120 tours ;
- **0 trahison / rupture d'alliance** jamais observée ;
- **classement des puissances inchangé** du tour 12 au tour 120 ;
- **résultats rigoureusement identiques pour les graines 1914, 7 et 2026**.

Le noyau militaire MIL-01 fonctionne réellement quand un conflit est forcé (batailles, pertes,
mobilisation), et la diplomatie produit des alliances et des réponses. Mais les boucles qui
devraient rendre la partie dynamique (recherche, économie active, commerce, guerres, trahisons)
sont soit bloquées, soit inutilisées par l'IA.

Le classement D est écarté : les systèmes ne sont pas cassés et une partie dirigée par le joueur
reste jouable. Le classement B est écarté : les défauts ci-dessus ne sont pas des détails
d'équilibrage, mais des boucles stratégiques inexistantes en pratique.

---

## 2. État de l'intelligence artificielle

### 2.1 Personnalités : différences fortes, mais parfois pathologiques

Expérience contrôlée : 22 États forcés à la même personnalité, 24 tours.

| Personnalité | Propositions d'alliance | Guerres | Trahisons | Technologies |
|---|---:|---:|---:|---:|
| prudent | 254 | 0 | 0 | 0 |
| conciliant | 254 | 0 | 0 | 0 |
| honorable | 254 | 0 | 0 | 0 |
| expansionniste | **0** | **0** | 0 | 0 |
| opportuniste | **0** | **0** | 0 | 0 |
| méfiant | **0** | **0** | 0 | 0 |
| ambitieux | **0** | **0** | 0 | 0 |

**Problème MAJEUR confirmé.** Quatre profils « agressifs » ne produisent **aucune action
diplomatique et aucune action militaire**. Cause : `DiplomaticAI._score()` exige un score ≥ 50
pour proposer une alliance ; le score de départ vaut ~49, plus `trust_bias` moins
`hostility_bias`. Les profils expansionniste (-8/-10), méfiant (-12/-12), opportuniste (0/-2)
et ambitieux (-4/-6) tombent sous le seuil et n'agissent jamais. Ils ne déclarent pas non plus la
guerre, car personne ne le fait (§2.3). Résultat : ces personnalités sont **silencieuses**, pas
agressives.

### 2.2 Trahisons : mécanisme présent mais jamais déclenché

`DiplomaticAI.decide()` prévoit `leave_alliance` si la confiance tombe sous 25, mais cette règle
est évaluée **en dernier**, après les réponses, la paix, les alliances, les échanges et les
crises. Le plafond `max_initiatives_per_turn = 2` est déjà consommé avant d'y arriver. Sur 120
tours et toutes les graines : **aucune rupture d'alliance observée**. L'engagement n'a donc jamais
d'effet de défiance dans la pratique.

### 2.3 Aucune initiative de guerre

Recherche dans le code : `Orders.declare_war` n'est produit **que par l'interface**
(`src/ui/game_ui.gd:355`). Aucune IA ne le génère. Les crises internationales peuvent évoluer vers
la guerre via `CrisisSystem.to_war()`, mais aucune IA ne crée de crise : `start_crisis` n'est
utilisé que par les tests et l'interface. En campagne libre, **il n'y a donc jamais de guerre**.

### 2.4 Graine sans effet

L'audit précédent supposait un déterminisme « à graine identique ». En réalité, les trois graines
produisent des campagnes **bit à bit identiques**. Le champ `seed_value` n'est utilisé que pour
le départage neutre des batailles (`military_system.gd:178`) ; aucune décision IA, aucun
événement et aucune économie n'en dépend. La reproductibilité est donc triviale, et la variabilité
des parties inexistante.

### 2.5 Coordination entre domaines

Les quatre IA (diplomatique, économique, politique, technologique) produisent des ordres
indépendants, avec des plafonds séparés. Elles se coordonnent mal :
- l'IA politique demande des mesures de cohésion alors que les fonds manquent (§5.1) ;
- l'IA économique ne commerce jamais faute de déficit détectable (§4.3) ;
- l'IA technologique lance des projets que l'économie ne peut financer (§3.1).

**Déséquilibre probable :** la personnalité n'influence réellement que la diplomatie. Les profils
économiques et politiques testés produisent des compteurs d'ordres quasi identiques
(`alloc=21`, `trade=0` pour les quatre profils économiques).

---

## 3. État de la diplomatie

Ce qui fonctionne (confirmé) :
- propositions, réponses, contre-propositions, retraits, expirations ;
- alliances avec engagements et effets sur le transit ;
- crises, médiation, négociation, traités bilatéraux, pacte universel accessible depuis l'UI ;
- réputation et historique persistants.

Ce qui ne fonctionne pas en pratique :
- **spam de propositions** : 484 propositions sur 120 tours, pour 12 alliances actives. Les
  propositions s'accumulent sans que l'IA apprenne d'un refus ;
- ** aucune variance** de stratégie liée aux rivalités historiques : les mêmes puissances se retrouvent
  alliées dans toutes les configurations ;
- **absence de conséquence négative** : puisqu'il n'y a ni guerre ni trahison, la réputation et
  les engagements n'ont presque aucun impact observable.

**Problème MODÉRÉ confirmé :** la négociation produit beaucoup de bruit (centaines de
propositions) et peu de changements stratégiques. Le joueur pourrait difficilement y lire une
intention.

---

## 4. État de l'économie

### 4.1 Démarrage à zéro et extraction inertielle

`data/game/economic_baseline.json` donne des dépôts mais des `stocks` initiaux à **0**. Les
ressources ne s'extraient que si le taux d'exploitation est investi
(`ResourceSystem.monthly` : `rate * investment_effect + ...`). Or **aucun ordre `invest_resource`
n'a jamais été observé** dans les campagnes, malgré l'existence de la commande. Résultat :
production quasi nulle, stocks qui plafonnent à ~30 par État après 120 tours.

### 4.2 Recherche bloquée

`TechSystem.monthly` consomme charbon/fer pour avancer. Avec des stocks vides, `affordable = 0`
et le projet reste à `progress = 0.0` indéfiniment. Les projets en cours occupent alors les
deux créneaux de l'IA (`max_research_projects = 2`), qui n'en lance plus jamais.

Preuve : en campagne normale, 42 ordres de recherche, 0 découverte. En injectant 5000 unités de
chaque ressource, `electrification` (coût 80, ~90 points/tour) se termine en **un tour**. Le
problème est donc bien l'alimentation, pas la formule de recherche.

Même avec des stocks initiaux de 500 pour tous les États, on n'observe que **2 découvertes au
total en 36 tours** : l'IA ne relance pas de projets après les premiers.

### 4.3 Commerce inutilisé

`EconomicAI.decide` n'achète que si `stocks[res] < 5` et exige un fournisseur ayant ≥ 10 unités.
Comme tout le monde reste sous le seuil, **3 ordres de commerce en 120 tours**, tous graines
confondues. Le système de commerce, les dépendances et les accords de transit n'ont donc presque 
aucune conséquence économique réelle.

### 4.4 Stabilité démographique

Population et main-d'œuvre évoluent sans effondrement ni explosion, avec ou sans crise. Aucun
stock négatif détecté (cohérence comptable validée). Les pénuries sont donc surtout un état
« zéro stock » permanent, pas une dynamique de crise.

**Problème CRITIQUE confirmé :** l'économie ne démarre jamais. Une chaîne
`dépôt → investissement → extraction → stock → recherche/industrie` existe dans le code mais est
coupée dès le premier maillon par l'absence d'investissement IA et de stocks initiaux.

---

## 5. État du système militaire et logistique

Ce qui fonctionne quand un conflit est forcé :
- mobilisation, effectifs, pertes, remplacement progressif, moral, ravitaillement, capacités de
  transport, ponts et franchissements, batailles tactiques résolues.

Ce qui manque en jeu libre :
- aucune guerre spontanée (§2.3) ; donc aucun déplacement militaire (`moves = 0` sur 120 tours) ;
- avec un conflit forcé, l'IA attaque surtout les 12 premiers tours puis s'arrête (observations
  des campagnes 24 et 120 tours : 3 batailles, puis plus aucune) ;
- les capacités de transport ne sont jamais saturées dans la pratique (pas assez de mouvements).

**Problème MAJEUR confirmé :** la carte stratégique et MIL-01 sont bien intégrés techniquement,
mais le système reste **inactif** dans une partie non scriptée. Le joueur doit lui-même créer
tous les conflits pour que le cœur militaire s'exécute.

---

## 6. État de la politique intérieure

- Groupes d'influence : satisfaction qui évolue lentement (ex. militaires 60 → 54,2 en 24 tours),
  influence constante. Effet observable mais faible.
- Crises intérieures : déclenchables, mais **ne se résolvent jamais** sans injection massive de
  fonds ; avec tension 90 et stabilité 20, la dérive naturelle mettrait ~260 tours à sortir de
  crise. Observé : 22 crises actives à la fois au tour 12 et au tour 120 dans le scénario
  d'instabilité.
- **Problème MAJEUR confirmé (bug de nom de clé)** : `phase7_rules.politics.decisions.costs`
  utilise les clés `tension` et `trust`, alors que l'état utilise `social_tension` et
  `institution_trust`. `PoliticalSystem.apply_decision()` ignore donc silencieusement ces effets.
  Preuve : avec 100 fonds, `cohesion_campaign` coûte 15 et ne réduit **pas** la tension
  (89,75 → 89,75). Le joueur paie pour une décision sans effet.
- Conséquence : sur 24 tours d'instabilité, 504 décisions politiques sont émises, sans résoudre
  les crises.

---

## 7. État des technologies

- Arbre de 33 technologies 1914-1945, prérequis, coûts, effets : correctement chargé.
- Recherche fonctionne si et seulement si les ressources sont présentes (§4.2).
- Diffusion : `can_research` ne vérifie pas l'accord technologique ; le facteur
  `diffusion_cost_factor` est défini dans les règles mais **aucune réduction observable** n'a été
  trouvée. Un État peut rechercher une technologie déjà connue d'un partenaire sans accord.
- **Problème MAJEUR confirmé : la progression technologique est effectivement nulle en campagne
  normale**, et la limite 1945 est dépassée (le jeu tourne jusqu'en 2024) sans contenu nouveau.

---

## 8. Résultats des campagnes longues

Matrice exécutée : 3 graines × 7 contextes × 24 tours, plus des campagnes de 60 et 120 tours.

| Contexte | Observation marquante |
|---|---|
| Paix (0) | 0 guerre, 0 bataille, 12 alliances, 0 tech, classement figé |
| Guerre forcée (1) | 13 guerres, 3 batailles, puis stabilisation ; 0 tech |
| Crise économique (2) | stocks identiques au scénario paix au bout de 24 tours (production automatique compense) |
| Mobilisation (3) | aucune différence de résultats vs paix |
| Instabilité (4) | 22 crises actives permanentes, 504 décisions sans effet |
| Activité diplomatique (5) | 222 propositions pour 4 alliances, 25 réponses |
| Course technologique (7) | aucune différence vs paix |

Campagnes 60 et 120 tours (graine 1914) : temps 20,8 s / 109,8 s ; 892 / 1418 événements ;
stocks totaux 515 / 669 ; **0 technologie, 0 commerce, 0 investissement, 0 trahison** dans les
deux cas. Aucune erreur technique, aucun stock négatif.

---

## 9. Équilibrage général

- Puissances initiales historiquement différenciées (Russia/UK/Germany en tête) — cohérent.
- États secondaires présents et jouables par l'IA, mais sans stratégie propre observable.
- **Aucun rattrapage ni domination dynamique** : le top 3 est identique au tour 12 et au tour 120.
- Conditions de victoire : militaire atteignable seulement par conquête manuelle ; IDH jamais
  atteinte en campagne (ratio ~1,07 pour un seuil 1,25) ; diplomatique accessible via l'UI mais
  nécessite 21 acceptations tour par tour.
- **Stratégie dominante observed : rester passif.** C'est la seule stratégie qui ne coûte rien et
  qui conserve le classement initial. C'est un déséquilibre majeur pour un jeu de grande stratégie.

---

## 10. Expérience utilisateur (gameplay)

- Information abondante (13 onglets, 17 couches, relations chiffrées) mais **peu d'événements
  stratégiques marquants** : le journal se remplit surtout de propositions, réponses et décisions
  sans effet.
- Le joueur ne peut pas comprendre pourquoi une décision politique ne change rien (erreur
  « fonds insuffisants » non remontée dans l'UI ; effets de clés ignorés silencieusement).
- Impossible de planifier plusieurs tours à l'avance : aucun indicateur de progression de
  recherche lisible, aucune anticipation des pénuries, aucune notification quand un projet est
  bloqué faute de ressources.
- Causes identifiées : absence de boucle de feed-back visible entre investissement, production et
  recherche.

---

## 11. Liste hiérarchisée des problèmes

| # | Gravité | Problème | Confirmé ? | Système |
|---|---|---|---|---|
| 1 | **CRITIQUE** | Chaine économique coupée : aucun investissement IA → pas d'extraction → recherche et industrie bloquées | confirmé | économie / technologie |
| 2 | **CRITIQUE** | Aucune IA ne déclare la guerre ; campagne libre sans conflit | confirmé | IA / militaire |
| 3 | **MAJEURE** | 4 personnalités sur 7 diplomatiquement et militairement inertes | confirmé | IA |
| 4 | **MAJEURE** | Effets politiques `trust`/`tension` ignorés (noms de clés) | confirmé | politique |
| 5 | **MAJEURE** | Aucune trahison jamais déclenchée (plafond d'initiatives consommé) | confirmé | diplomatie / IA |
| 6 | **MAJEURE** | Graine sans effet sur les campagnes (variabilité nulle) | confirmé | simulation |
| 7 | **MODÉRÉE** | Crises intérieires permanentes, jamais résolues | confirmé | politique |
| 8 | **MODÉRÉE** | Spam de propositions (484/120 tours) sans apprentissage | confirmé | diplomatie |
| 9 | **MODÉRÉE** | Commerce et transit sans effet réel (3 ordres/120 tours) | confirmé | économie |
| 10 | **MODÉRÉE** | Diffusion technologique non opérationnelle malgré paramètre dédié | confirmé | technologie |
| 11 | **MINEURE** | Titre de fenêtre « prototype » et quelques textes résiduels | confirmé | interface |

Aucun problème critique de corruption, de sauvegarde ou de stabilité technique : ces aspects
restent valides.

---

## 12. Recommandations pour les prochains chantiers

Aucune correction n'est entreprise ici. Priorités suggérées, sans création automatique de phase :

1. **Rétablir la boucle économique** (avant tout) : stocks initiaux ou investissement IA, et
   remontée visible des projets bloqués. Critère : au moins une technologie par puissance en
   24 tours sans injection manuelle.
2. **Donner une initiative de guerre à l'IA** (crises ou décision stratégique), avec garde-fous.
   Critère : des conflits apparaissent dans une campagne libre sans script.
3. **Réparer les effets politiques** (noms de clés) et remonter les motifs de refus à l'UI.
   Critère : une campagne de cohésion réduit mesurablement la tension.
4. **Corriger le seuil de proposition des personnalités agressives** pour qu'elles agissent
   (guerre ou diplomatie) au lieu de se taire. Critère : comportements distincts et actifs.
5. **Activer la trahison** en donnant priorité à la règle avant les autres initiatives.
6. **Utiliser la graine** dans les décisions IA ou documenter explicitement l'absence de
   variabilité comme limitation définitive.
7. **Borne et expiration des propositions** en attente pour réduire le bruit diplomatique.

---

## 13. Limites de l'audit

- Aucune partie jouée manuellement sur des dizaines de tours : les conclusions viennent de
  scripts d'observation instrumentés et de captures d'interface pour les phases précédentes.
- Les scénarios « forcés » (guerre, crise) ne reproduisent pas une partie utilisateur typique ;
  ils sont utilisés uniquement pour isoler les systèmes.
- Les résultats sont reproductibles avec `/tmp/opencode/gp_observe.gd` et
  `/tmp/opencode/gp_personality.gd` (hors dépôt), avec les graines 1914, 7 et 2026.
- Aucun paramètre n'a été modifié pour améliorer artificiellement les observations.

**Aucune correction n'a été appliquée. Aucun commit, aucun push. En attente de validation.**
