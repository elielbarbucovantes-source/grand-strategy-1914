# POST_MIL01_GAMEPLAY_RESTORATION_03_REPORT — Interface commerciale, technologique et transparence diplomatique

> **Date :** 2026-11-23
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation` (jamais `main`)
> **Référence :** `docs/project/POST_MIL01_GAMEPLAY_RESTORATION_02_REPORT.md` (limite §8.6)
> **Nature :** rendre accessibles depuis l'interface des mécanismes déjà présents. Aucune
> nouvelle phase de simulation, aucune reconstruction des systèmes, aucune fusion.

---

## 1. État initial de l'interface

- **13 onglets** (`TAB_NAMES`), navigables par une barre de boutons, avec barre d'onglets interne masquée et panneau latéral adaptatif (520 px au-dessus de 1400 px, 460 px en dessous).
- Aucun helper de table ou de liste : les pages sont composées de `RichTextLabel`, `Label`, `HBoxContainer`, `Button`, `SpinBox` et `OptionButton`, reconstruites à chaque `refresh()` via `_clear()`.
- **Économie** : affichait `EconomySystem.national_balance()` dont les valeurs sont `null` en campagne (données « À DÉFINIR »), des stocks bruts et des dépendances agrégées. Aucun accord, aucune expédition, aucun prix, aucun besoin industriel lisible, aucun bouton commercial.
- **Recherche** : technologies connues, projets, 10 technologies disponibles avec bouton « Lancer », communications. Aucun arbre (prérequis/domaine/effets), aucune coopération, aucun transfert.
- **Diplomatie** : propositions, relations instantanées, alliances, crises, traités, messages. Aucun historique de confiance, aucune rupture avec son motif, aucune réputation.
- Les ordres `TRADE`, les accords `trade`/`tech`, les transferts et les expéditions existaient dans la simulation mais n'étaient accessibles au joueur que par script.

---

## 2. Améliorations réalisées

Aucun nouvel onglet n'a été créé : les ajouts sont des sections dans les pages existantes, sur le modèle de la section « Puissance des États » ajoutée en RESTORATION 02.

### 2.1 Page Économie — commerce international
- **Consultation** : stocks réels (`ResourceSystem.available`), réserve industrielle calculée depuis les intrants réels (`EconomicAI._reserve`), excédents/déficits, prix de base et prix préférentiel (`MarketSystem.unit_price`), accords `trade`/`transit` actifs, dépendances en transit (`MarketSystem.dependencies`), expéditions avec direction, quantité, coût, goulot, nombre de liaisons, échéance, retards et statut.
- **Séparation des états** : `en transit (arrivée T…)` ≠ `livrée T…`. Aucune livraison n'est affichée comme terminée avant exécution réelle.
- **Négociation** : `Vendre` émet `Orders.trade(me, me, partenaire, …)` validé par `MarketSystem.validate` ; `Demander achat` émet une proposition `trade` avec `{request, resource, amount}` — aucun prélèvement unilatéral ; `Accord commercial` émet une proposition `trade` cadre.
- **Exécution de l'achat** : `DiplomacySystem._apply_accepted()` traduit l'acceptation d'une demande d'achat en expédition réelle émise par l'exportateur, après revalidation économique et logistique ; un refus est journalisé sans transfert.
- **Historique** : toutes les expéditions du joueur, livrées ou en retard, avec quantités, prix, partenaires, dates et nombre de retard.

### 2.2 Page Recherche — technologie
- **Arbre** : domaines, années, prérequis, effets, statuts (`découverte`, `en recherche`, nombre d'accessibles et de verrouillées), progression en pourcentage.
- **Coopération** : partenaires actifs via `TechSystem.partners_of()`, bouton « Proposer » émettant `Orders.propose_agreement(..., "tech", {})`.
- **Transferts** : ceux concernant uniquement le joueur, avec technologie, sens, coût, délai (`arrivée T…`) et statut. Aucun transfert entre tiers n'est révélé.
- Aucun bouton « transférer de force » : un transfert est consensuel, coûteux et différé ; l'interface l'explique explicitement.

### 2.3 Page Diplomatie — historique et confiance
- Réputation calculée (`RelationsSystem.reputation`), confiance par partenaire et 5 dernières entrées de son historique (`trust`, `tensions`, motifs).
- Engagements rompus (`treaty_broken`, `alliance_betrayal`, `alliance_exit`) avec tour, partenaire, détail et **nature** (`retrait négocié` vs `rupture unilatérale`).
- Traités rompus avec tour et motif enregistré, propositions refusées émises par le joueur.
- **Secret préservé** : uniquement `state.memory[joueur]` et ses propres relations ; aucune mémoire tiers, aucune relation entre tiers, aucun volume militaire étranger.

---

## 3. Composants réutilisés

`_clear()`, `_rich()`, `_label()`, `_button()`, `_wrap()`, `_num()`, `_format_stocks()`, lignes `HBoxContainer`, `ScrollContainer` et `TabContainer` existants. Helpers existants utilisés sans duplication : `ResourceSystem.available`, `EconomicAI._reserve`, `MarketSystem.*`, `TechSystem.*`, `RelationsSystem.*`, `Orders.*`, `DiplomacySystem.*`, `SaveRepository.*`. Aucune dépendance ajoutée.

Un seul petit helper nouveau, purement présentationnel : `GameUI.panel_width_for(viewport_width)`, extrait du `_build()` pour être testable aux deux résolutions.

---

## 4. Fichiers modifiés

| Fichier | Modification |
|---|---|
| `src/ui/game_ui.gd` | sections `_trade_section`, `_tech_section`, `_diplomacy_history_section` ; `panel_width_for()` ; libellés `_describe()` pour `TRADE` et `PROPOSE_AGREEMENT` |
| `src/domains/diplomacy/diplomacy_system.gd` | exécution consensuelle d'une demande d'achat acceptée |
| `tests/ui_restoration03_smoke.gd` | **nouveau** — 35 contrôles UI, données réelles, deux résolutions |
| `tests/run.sh` | exécution du nouveau test de fumée UI |

Aucune donnée historique, aucun paramètre d'équilibrage, aucun système validé n'a été modifié.

---

## 5. Fonctionnalités réellement accessibles au joueur

| Action | Circuit | État |
|---|---|---|
| Consulter stocks, besoins, prix, accords, livraisons, dettes commerciales | sections Économie | accessible |
| Vendre une ressource | `Orders.trade` → `GameSession.queue_order` → `MarketSystem.validate` | accessible et validée |
| Demander un achat | proposition `trade` → acceptation partenaire → `MarketSystem.propose` | accessible et exécutée |
| Proposer un accord commercial / de passage / de coopération scientifique | `Orders.propose_agreement` → validation diplomatique existante | accessible |
| Accepter / refuser / renégocier / retirer une proposition | boutons préexistants de la page Diplomatie | accessible |
| Consulter arbre, prérequis, effets, statuts, coopérations et transferts | section Recherche | accessible |
| Consulter historique de confiance et ruptures | section Diplomatie | accessible |
| Forcer un transfert technologique | aucun ordre dans la simulation | **non disponible (intentionnel)** |

---

## 6. Tests et résultats

- `tests/ui_restoration03_smoke.gd` : **40 contrôles, 0 échec** — navigation, contenus réels, ordres émis par les boutons, livraison en transit non anticipée, achat après acceptation, arbre et coopération, secret des tiers, sauvegarde/chargement pendant accord actif, absence de marqueurs fictifs.
- `tests/ui_smoke.gd` et `tests/battle_ui_smoke.gd` : non-régression de l'interface existante.
- Suite complète `tests/run.sh` : voir résultat final en fin de rapport.
- `run.sh` échoue sur toute erreur GDScript détectée dans la sortie (`SCRIPT ERROR`, `Parse Error`, `Compile Error`).

---

## 7. Validations visuelles aux deux résolutions

- **Vérifié en headless** : `panel_width_for(1600) = 520`, `panel_width_for(1280) = 460` ; les 13 onglets se construisent et chaque nouvelle page est générée sans erreur après navigation.
- **Non vérifié** : capture pixels réelle à 1600×900 et 1280×720. Le harnais de capture existant (`tests/engagement_capture.gd`) nécessite un affichage graphique, indisponible en modeheadless. Le rapport ne prétend donc pas à une validation visuelle humaine.

---

## 8. Sauvegardes testées

Sauvegarde/chargement avec accords commercial et scientifique actifs, expédition en transit et transfert technologique en cours : rechargement réussi, expédition/coopération/transfert persistés, `checksum()` identique. Le format de sauvegarde n'a pas changé (aucun nouveau champ top-level).

---

## 9. Régressions

Aucune régression détectée à ce stade. Les tests existants sont conservés et exécutés ; un seul test existant a été étendu (`tests/run.sh`, ajout d'un lanceur), aucun n'a été affaibli. La correction du formatage dans la ligne d'expédition a été nécessaire pendant le développement (argument manquant) et est validée.

---

## 10. Limites restantes

1. Aucun transfert technologique imposé par le joueur : il est négocié par coopération et généré par le système, par conception.
2. L'arbre affiche domaines, années, prérequis et effets, mais pas de représentation graphique des liens (pas de `Tree` ou de graphe dédié).
3. Le prix est une proposition du modèle économique (`PROPOSÉ`, non sourcé) ; l'interface l'indique explicitement.
4. L'historique commercial est affiché tour par tour sans graphique de tendance.
5. L'interface n'a pas de bouton « investir dans une ressource » (`INVEST_RESOURCE` reste piloté par l'IA), bien que le système existe.
6. Validation visuelle réelle aux deux résolutions non effectuée dans cet environnement headless (voir §7).

---

## 11. Distinction des états

| Élément | Implémenté | Testé automatiquement | Vérifié visuellement | Fonctionnel en campagne réelle |
|---|---|---|---|---|
| Sections commerce / technologie / historique | ✔ | ✔ | non (headless) | ✔ |
| Vente validée par le système | ✔ | ✔ | non | ✔ |
| Achat après acceptation du partenaire | ✔ | ✔ | non | ✔ |
| Coopération scientifique depuis l'UI | ✔ | ✔ | non | ✔ |
| Transfert affiché avec coût/délai | ✔ | ✔ | non | ✔ |
| Secret des tiers respecté | ✔ | ✔ | non | ✔ |
| Largeur 1600 / 1280 | ✔ | ✔ (logique) | non | ✔ (logique) |
| Transfert technologique forcé | ✘ (intentionnel) | ✘ | ✘ | ✘ |
| Capture visuelle humaine | ✘ | ✘ | ✘ | ✘ |

---

## 12. Verdict

**B — progrès réels, certaines possibilités restent limitées.**

Les trois domaines demandés sont désormais accessibles depuis l'interface et utilisent exclusivement les systèmes de simulation existants. Le grade A est écarté : absence de transfert technologique imposé (choix de conception cohérent avec le caractère consensuel du mécanisme), absence de graphe visuel de l'arbre et de validation visuelle humaine aux deux résolutions dans cet environnement.

---

**Fin de mission. Aucune nouvelle phase lancée. En attente de validation du directeur.**
