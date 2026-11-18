# POST_MIL01_PHASE2_AUDIT_REPORT — Audit historique et fiabilisation documentaire

> **Date :** 2026-11-18
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **Périmètre :** corrections documentaires et audit des sources des 15 États secondaires.
> **Aucune mécanique MIL-01 / Phase II modifiée. Aucune valeur militaire corrigée.**

---

## 1. État initial du dépôt

| Contrôle | Valeur observée |
|---|---|
| Branche active | `dev/mil01-finalisation` |
| Arbre de travail | propre (`git status` vide) |
| HEAD local | `2e6b564129aeb2a4167dc218eec38d921e07a056` |
| HEAD distant | identique (`origin/dev/mil01-finalisation`) |
| Divergence | `0 0` (aucun commit local ou distant en avance) |
| Amont | `origin/dev/mil01-finalisation` |
| 3 derniers commits | `b8bdb69`, `1b0b0a1`, `2e6b564` |

Les rapports Phase 0 et Phase II ont été relus avant toute intervention. Aucune modification
inattendue, aucune divergence, aucun travail concurrent à protéger.

## 2. Corrections documentaires effectuées

| Fichier | Correction |
|---|---|
| `docs/project/POST_MIL01_PHASE2_REPORT.md` | Suppression de la phrase contradictoire « Le push n'a pas pu être effectué » ; état final unique : publication réussie, branche correcte, arbre propre, HEAD local = distant, aucun push forcé, aucun merge vers `main` ; hash de publication corrigé en `2e6b564`. |
| `data/history/military_forces_1914.json` | Métadonnées uniquement : `title_fr` (« 22 États européens, MIL-01 étendu — Phase II »), `compiled` (2026-11-18), `status` (couverture 7 + 15, renvoi vers la recherche et le présent audit). **Aucune valeur militaire modifiée.** |
| `docs/project/COMBAT_SYSTEM.md` | Remplacement de « sept puissances / États hors MIL-01 à effectifs inconnus / repli neutre » par la situation réelle : 22 États sourcés, plus de repli neutre pour les secondaires. |
| `docs/project/PROTOTYPE_STATUS.md` | Mise à jour de la ligne Batailles (date, 7 + 15 États, suppression du repli neutre). |
| `tools/export/build_scenario.py` | Docstring et message de repli alignés sur la Phase II (le repli « inconnu » ne s'applique plus qu'à un État absent de la base, cas aujourd'hui inexistant). |
| `data/scenarios/campaign_1914.json`, `docs/history/fiches/*.md` | Régénérés par les scripts versionnés : seule l'empreinte SHA-256 de la base a changé. |

Les rapports historiques datés (MIL01_PHASE1…6, ROADMAP_AUDIT, T045_T046, etc.) décrivent
l'état de leur époque et ont été **volontairement laissés inchangés** : leur mention des
« sept puissances » est exacte pour la période couverte.

## 3. Audit des sources des 15 États

### Méthode et limites réelles

- Tentative de délégation à 4 agents CHORUS/OpenCode pour auditer les sources en parallèle :
  **échec des 4 agents** (erreurs d'outil, aucun fichier `audit.json` produit). Cette tentative
  n'a donc **aucune valeur probante** et n'est pas comptabilisée comme vérification.
- Audit direct effectué par moi-même : lecture de `secondary_states_research.json`, puis
  consultation en ligne des articles Wikisource de l'*Encyclopædia Britannica* (11e éd.)
  **Servia, Rumania, Greece, Denmark, Norway, Sweden, Belgium, Netherlands, Switzerland,
  Montenegro, Bulgaria** (HTTP 200), avec extraction ciblée des passages « peace strength »,
  « peace footing », « army », « available for service ».
- **Non vérifiés directement** : *Statesman's Year-Book* 1913/1914, U.S. War Department 1916,
  Richard C. Hall (2000), vojska.net, 1914-1918-online.net, articles Wikipédia, NYT 1914,
  GlobalSecurity, Tank Encyclopedia. Ils restent classés B/C/D selon leur identifiabilité.

### Grille appliquée

- **A** — source réellement consultée par moi **et** dont le passage confirme explicitement le chiffre.
- **B** — ouvrage/publication identifiable, mais passage précis non vérifié par moi.
- **C** — estimation documentée à partir de plusieurs faits historiques cohérents.
- **D** — référence trop vague, invérifiable ou insuffisante pour justifier le chiffre.

### Classement des 40 références

| Clé | Classe | Motif |
|---|---|---|
| `SEC_balkans_EB1911_SERVIA` | **A** | Consulté : « On a peace footing the strength of the army is 35,000 men; in war it might reach 225,000, including landsturm ». |
| `SEC_nordic_EB1911_RO` | **A** | Consulté : « peace strength in 1909–10 was 4415 officers, 89,227 non-commissioned officers and men » = 93 642 ; « militia should ultimately furnish an additional force of 100,000 men ». |
| `SEC_nordic_EB1911_DK` | **A** | Consulté : « peace strength of permanent troops [...] is about 13,500 officers and men » ; « about 80,000 » reservistes. |
| `SEC_nordic_EB1911_NO` | **A** | Consulté : « peace establishment of the line is 12,000 men, with 750 officers » = 12 750. |
| `SEC_nordic_EB1911_SE` | **A** | Consulté : « permanent cadres number about 22,000 » ; « It is estimated that 500,000 men are available for service [...] in case of war ». |
| `SEC_balkans_EB1911_GREECE` | **A** | Consulté : « peace strength of the army in 1908 consisted of 1939 officers [...] 19,416 non-commissioned officers and men » = 21 355 ; « reserves [...] about 77,000 [...] territorial army about 37,000 ». **La source est A, mais les chiffres retenus (20 000 / 140 000) sont des estimations postérieures : C.** |
| `SEC_west_EB1911_BE` | B | Article consulté ; donne « effective strength [...] in 1904 with the colours was 3406 officers and 40,382 men » (43 788), ce qui **ne confirme pas** le 33 000 retenu pour 1914 (année et définition différentes). |
| `SEC_west_EB1911_NL`, `SEC_west_EB1911_CH`, `SEC_balkans_EB1911_MONTENEGRO` | B | Articles consultés (description des systèmes) mais aucun effectif numérique confirmant la valeur retenue ; la page Suisse est un résumé court. |
| `SEC_west_SYB1914`, `SEC_west_USWD1916`, `SEC_balkans_US_WD_1916`, `SEC_iberia_SYB1913`, `SEC_iberia_WWI1916`, `SEC_iberia_NYT1914`, `SEC_iberia_WORLDARMY`, `SEC_balkans_HALL_BALKAN` | B | Publications identifiables (citation et souvent URL présentes), passages précis non vérifiés. |
| `SEC_balkans_EB1911_BULGARIA` | B | L'URL fournie résout vers une page courte (7 220 caractères) sans le passage cité ; ouvrage identifiable, passage non vérifié. |
| `SEC_balkans_WIKI_BALKAN_WARS`, `SEC_balkans_WIKI_HELLENIC_ARMY`, `SEC_balkans_WIKI_ROYAL_SERBIAN_ARMY`, `SEC_balkans_VOJSKA_SERBIA_1914`, `SEC_balkans_WIKI_BULGARIAN_LAND`, `SEC_iberia_HCPT`, `SEC_nordic_TANK_DK`, `SEC_nordic_GLOBALSEC_DK`, `SEC_nordic_WIKI_RO_CAMPAIGN`, `SEC_nordic_WIKI_RO_ARMY`, `SEC_nordic_WIKI_NO_ARMY`, `SEC_nordic_WIKI_SE_ARMY`, `SEC_nordic_WIKI_SE_WW1` | C | Compilations secondaires ou chiffres d'après-guerre/guerre utilisés comme bornes ; cohérents mais non confirmés pour janvier 1914. |
| `SEC_balkans_VOJSKA_MNE_1914`, `SEC_iberia_WIKI`, `SEC_nordic_SPARTACUS_RO`, `SEC_nordic_NYT_SE`, `SEC_west_EB1911_LU`, `SEC_west_METHODOLOGY`, `SEC_nordic_CHORUS_NOTE` | D | Données d'août 1914 ou postérieures, notes de recherche sans valeur historique, URL absente ou titre introuvable (l'article EB1911 correct est « Luxemburg » et non « Luxembourg »). |

Aucune référence bibliographique ni URL n'a été inventée ; aucune source n'a été promue A sans
lecture réelle de son contenu.

## 4. Classement A/B/C/D — synthèse par nature

- **A (6 sources)** : Britannica 1911 Servia, Rumania, Greece, Denmark, Norway, Sweden.
- **B (12 sources)** : Britannica Belgique/Pays-Bas/Suisse/Monténégro/Bulgarie, SYB 1913/1914,
  US War Dept 1916 (x2), Hall, 1914-1918-online, NYT 1914, World Armies.
- **C (13 sources)** : Wikipédia et dérivés, vojska.net Serbie, HCPT, GlobalSecurity,
  Tank Encyclopedia, estimations de réserves norvégiennes/suédoises/roumaines.
- **D (7 sources)** : vojska.net Monténégro, Wikipédia Albanie, Spartacus, NYT 1914 (rejeté),
  EB1911 Luxembourg (URL invalide), notes de méthodologie CHORUS (×2, non sources historiques).

## 5. Chiffres vérifiés (A)

| État | Chiffre | Passage vérifié |
|---|---|---|
| Serbie | actif 35 000 ; plafond guerre 225 000 | EB1911 « Servia » |
| Roumanie | actif 93 642 ; milice 100 000 (non entièrement organisée) | EB1911 « Rumania » |
| Danemark | actif 13 500 ; réservistes ~80 000 | EB1911 « Denmark » |
| Norvège | ligne 12 000 + 750 officiers = 12 750 | EB1911 « Norway » |
| Suède | cadres 22 000 ; 500 000 disponibles en guerre | EB1911 « Sweden » |
| Grèce | base 1908 = 21 355 ; réserves 77 000 + territoriale 37 000 | EB1911 « Greece » (source A, valeurs retenues C) |

Ces six vérifications confirment **exactement** les valeurs intégrées pour Serbie (actif),
Roumanie, Danemark, Norvège et Suède.

## 6. Chiffres estimés (C)

Belgique 33 000 / 100 000 ; Pays-Bas 25 000 / 175 000 ; Suisse 12 000 / 190 000 ;
Espagne 128 073 / 90 000 (établissement SYB1913 non consulté) ; Portugal 30 000 / 100 000 ;
Bulgarie 60 000 / 280 000 ; Serbie réserves 250 000 (EB1911 implique 190 000 ; 385 000 si l'on
part de la mobilisation d'août 1914) ; Grèce 20 000 / 140 000 ; Norvège réserves 282 000
(description c. 1920 utilisée comme proxy) ; Suède réserves 500 000 confirmées A mais
interprétées comme « disponibles en guerre », non comme présentes sous les drapeaux.

## 7. Données insuffisamment vérifiées (D)

- **Albanie** : 5 000 actifs / 0 réserve — aucune donnée de janvier 1914 fiable ; la source
  Wikipédia donne un effectif de 1923, non applicable. Conservé avec fiabilité faible.
- **Monténégro** : 3 000 actifs / 35 000 réserves — pas d'armée permanente au sens moderne ;
  les chiffres proviennent de descriptions de mobilisation (août 1914 ou avant 1912).
- **Luxembourg** : 400 actifs / 0 réserve — estimation d'ordre de grandeur, Garde civique
  exclue ; aucun retour d'effectif fiable.
Ces valeurs n'ont pas été « corrigées » : leur incertitude est déjà explicite dans la base,
les fiches et le rapport Phase II.

## 8. Corrections apportées aux données historiques

**Aucune.** Aucun chiffre n'a été suffisamment réfuté pour justifier une modification :

- Belgique : l'EB1911 donne 43 788 « avec les couleurs » en **1904**, contre 33 000 retenus
  pour **1914** selon le SYB1914 ; périmètre et année diffèrent → divergence conservée, pas une erreur établie.
- Serbie : 250 000 réserves est supérieur aux 190 000 implicites de l'EB1911 (1911), mais
  inférieur à ce qu'implique la mobilisation d'août 1914 (420 597) ; l'estimation tient compte
  des guerres balkaniques → conservée avec niveau C.
- Grèce : 20 000 est un arrondi de 21 355 (1908) ; 140 000 vient de 1912-13 → conservé avec niveau C.
- Bulgarie : le passage EB1911 cité n'a pas pu être retrouvé à l'URL fournie → la source est
  rétrogradée B dans le présent audit, sans changer le chiffre faute de meilleure donnée vérifiée.

Aucun chiffre n'a été modifié pour des raisons esthétiques ou d'harmonisation.

## 9. Tests réellement exécutés (après les corrections)

| Commande | Résultat réel |
|---|---|
| `bash tests/run.sh` | **152 test(s) réussi(s), 0 échec(s)** ; `RÉSULTAT UI : VALIDÉ` ; `RÉSULTAT UI BATAILLE : VALIDÉ` ; exit 0 |
| `python3 tools/history/build_secondary_forces.py --check` | `[PASS] base historique a jour` |
| `python3 tools/export/build_scenario.py --check` | `[PASS] scénarios à jour` |
| `python3 tools/history/render_fiches.py --check` | `[PASS] fiches MIL-01 à jour` |
| `python3 tools/export/build_game_data.py --check` | `[PASS] data/game/world_map.json à jour` |
| `bash tools/map/validate_all.sh` | **VALIDÉ** — 94 + 96 + 34 contrôles, 0 échec |

La suite complète a été relancée **après** la modification des métadonnées et la régénération
du scénario ; les 152 tests ne sont pas un résultat hérité de la mission précédente.

## 10. Limites restantes

- Vérification en ligne partielle : 6 articles Britannica lus ; SYB, US War Dept, Hall et les
  compilations secondaires n'ont pas été consultés dans cette mission.
- Tentative de délégation CHORUS infructueuse (4 agents en échec) : l'audit repose sur le
  travail direct de l'agent, sans deuxième opinion automatisée.
- Plusieurs réserves reposent sur des descriptions d'après-guerre ou d'août 1914 : niveau
  C assumé, non présenté comme certitude.
- Les données D (Albanie, Monténégro, Luxembourg) restent intrinsequement fragiles.
- Aucune nouvelle source n'a été découverte ni fabriquée ; les incertitudes sont documentées
  plutôt que comblées artificiellement.

## 11. Commits créés

- `8c9013baec216a2aea9e51cc0cc33bf7f7c954e0` — `docs(mil01): corriger contradictions et metadata etendues aux 22 Etats`
- commit du présent rapport — `docs(mil01): ajouter le rapport d'audit historique post-Phase II`

Les deux commits sont publiés sur `origin/dev/mil01-finalisation` (voir §12).

## 12. État final du dépôt

Branche : `dev/mil01-finalisation`. Aucun merge vers `main`, aucune branche supprimée, aucun
historique réécrit, aucun push forcé, aucun secret versionné. HEAD local = HEAD distant,
arbre de travail propre à l'issue de la publication.

---

## Tableau récapitulatif par État

| État | Actif (valeur retenue) | Réserve (valeur retenue) | Niveau global | Nature de la vérification |
|---|---:|---:|---|---|
| Belgique | 33 000 | 100 000 | **B** | SYB1914 identifié mais non consulté ; EB1911 donne 43 788 en 1904 (divergence conservée) |
| Pays-Bas | 25 000 | 175 000 | **C** | estimation à partir du système de conscription décrit, passage chiffré non vérifié |
| Luxembourg | 400 | 0 | **D** | estimation d'ordre de grandeur, URL EB1911 invalide, Garde civique exclue |
| Suisse | 12 000 | 190 000 | **C** | système de milice décrit, effectifs non confirmés par la source consultée |
| Espagne | 128 073 | 90 000 | **B** | SYB1913 identifié, passage non vérifié |
| Portugal | 30 000 | 100 000 | **C** | établissement identifié ; réserve estimée depuis un article d'octobre 1914 |
| Danemark | 13 500 | 80 000 | **A** | EB1911 consulté, deux chiffres confirmés |
| Norvège | 12 750 | 282 000 | **B** | actif A (EB1911) ; réserve C (description c. 1920) |
| Suède | 22 000 | 500 000 | **A** | EB1911 consulté, cadres et disponibilité confirmés |
| Roumanie | 93 642 | 100 000 | **A** | EB1911 consulté, deux chiffres confirmés (milice non entièrement organisée) |
| Bulgarie | 60 000 | 280 000 | **B** | source secondaire identifiable ; passage EB1911 non retrouvé à l'URL fournie |
| Serbie | 35 000 | 250 000 | **B** | actif A (EB1911) ; réserve C (estimée, divergences documentées) |
| Monténégro | 3 000 | 35 000 | **D** | pas d'armée permanente, chiffres de mobilisation non contemporains de janvier 1914 |
| Albanie | 5 000 | 0 | **D** | aucune source fiable pour janvier 1914 |
| Grèce | 20 000 | 140 000 | **C** | EB1911 consulté (21 355 / 114 000), valeurs retenues estimées postérieurement |

**Lecture honnête :** 4 États (Danemark, Suède, Roumanie, et l'actif serbe/norvégien) reposent
sur des sources directement vérifiées ; 8 États reposent sur des estimations documentées ou des
références identifiées mais non consultées ; 3 États restent insuffisamment vérifiés. Ce niveau
de confiance est signalé tel quel, sans tentative de le gonfler.

**La Phase III n'a pas été commencée.**
