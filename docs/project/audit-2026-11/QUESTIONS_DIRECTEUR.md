# Questions au directeur du projet — questionnaire unique (14/11/2026)

Cochez une option par question, ou répondez librement. Toutes les questions techniques ordinaires ont été tranchées par l'équipe technique et ne figurent pas ici. Les recommandations sont des **propositions**.

## U1 — Licences et provenance des données — **TRANCHÉE le 14/11/2026**

> Décision : jeu gratuit et open source au départ ; données REGIS conservées ; attributions autorisées et publiées (`DATA_LICENSES.md`, `NOTICE`) ; avis juridique indépendant avant toute éventuelle commercialisation.

L'audit des licences a été remis directement au directeur. Il ne sera publié dans le dépôt public qu'après sa décision.

- [ ] U1.a — Autoriser l'ajout immédiat d'un fichier d'attributions et de licences des données (`NOTICE` / `DATA_LICENSES.md`) ? *(recommandé)*
- [ ] U1.b — Orientation : ☐ A (statu quo avec attributions) ☐ D (gel des nouvelles données dérivées, avec attributions) ☐ E (lever les restrictions : accord des auteurs ou re-dérivation) ☐ autre
- [ ] U1.c — Prendrez-vous contact avec les auteurs de la source concernée pour obtenir un accord écrit ?
- [ ] U1.d — Faut-il solliciter un avis juridique ?
- [ ] U1.e — Autoriser la publication de l'audit des licences dans le dépôt ?

## U2 — Alignement de `main`
- [ ] Autoriser l'exécution de `docs/project/MAIN_ALIGNMENT_PLAN.md` (commit de jonction à deux parents, fast-forward, sans `--force`), après reconstruction de la prévisualisation et contrôles (`07_ALIGNEMENT_MAIN.md`).

## U3 — Mers occidentales (MAP-OPEN-08)
26 façades côtières n'ont aucune zone maritime. Le réseau naval est coupé en deux.
- [ ] ☐ V1 : 7 nouvelles zones ☐ V2 : 9 zones (Atlantique scindé, Gibraltar explicite) ☐ autre découpage
- [ ] Le mouvement et le débarquement via les zones maritimes font-ils partie du graphe de déplacement jouable ? (détermine l'accès à l'Islande, région 051)

## U4 — Préalables à la collecte de données
- [ ] **R-13** — À quelle date commence la campagne ? ☐ janvier 1914 ☐ juin 1914 ☐ paramétrable. À quelle date se rapportent les données de départ ?
- [ ] **R-03** — Chaque région produit-elle les trois ressources (nourriture, matières premières, richesse) à des niveaux tirés des sources, éventuellement regroupés en paliers, sans l'obligation « une faible, une moyenne, une forte » de D-018 ? ☐ oui ☐ non
- [ ] **R-05** — Statistiques stockées en unités historiques et affichées sur une échelle de 1 à 10 calculée, les anciennes notes restant non officielles ? ☐ oui ☐ non

## U5 — T-029 (temps stratégique et tactique)
- [ ] Trancher D1 à D5 (`docs/decisions/arbitrage-t029-temps-strategique-tactique.md`). Le scénario S1 n'est pas approuvé à ce jour.

## U6 — Moteur
- [ ] Autoriser les prototypes techniques neutres NP-0 à NP-6 (aucune règle de jeu) et l'installation de Godot 4.7.2, en vue d'une ADR-0007 comparative soumise à votre décision ?

## U7 — Confirmations mineures (groupées)
- [ ] R-04 — La victoire collective remplace-t-elle la « victoire diplomatique » de D-025 ?
- [ ] R-07 — D-010 (amitié, neutralité, hostilité) reste-t-elle valable comme présentation des relations ?
- [ ] R-08 — La durée maximale de 30 minutes par bataille est-elle ferme ?
- [ ] R-09 — D-023 (interception exacte, pas de faux messages) s'applique-t-elle toujours ?
- [ ] R-14 — Les trois piliers de `PROJECT.md` font-ils référence (D-007 devenant un principe de priorité) ?
- [ ] C4 — Canal de Corfou : proximité seule (statu quo) ?
- [ ] C5 — Huit proximités : statu quo ?
- [ ] C6b — Séparer les sites des capitales à nom composite (par exemple Kronstadt, Ploiești) ; capitale albanaise de référence ?

## U8 — Licence du code — **orientation donnée le 14/11/2026 : gratuit et open source**

> Reste à choisir la licence open source précise du code (par exemple Apache-2.0, MIT, GPL-3.0 ; voir `02_LICENCES_PROVENANCE.md` §5). Aucune licence de code n'est ajoutée sans ce choix.
- [ ] Le jeu sera-t-il ☐ vendu ☐ gratuit et libre ☐ indécis ? *(détermine les licences possibles du code)*

## U9 — Anciens répertoires
- [ ] Autoriser la suppression de `~/Projets/GrandStrategy*` (archivés et vérifiés) ? Sans urgence.
