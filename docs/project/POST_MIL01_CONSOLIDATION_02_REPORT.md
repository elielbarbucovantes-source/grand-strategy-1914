# POST_MIL01_CONSOLIDATION_02_REPORT — Navigation, données nationales et exports

> **Date :** 2026-11-21
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État initial :** `d24e2b8`, arbre propre **sauf** `docs/project/POST_MIL01_LAUNCH_AUDIT.md`
> non commité (rapport de l'audit précédent, préservé et inclus ici).
> **Source :** `POST_MIL01_LAUNCH_AUDIT.md` (verdict B).

---

## 1. Problèmes identifiés

| Problème (audit de lancement) | Cause identifiée |
|---|---|
| 4 onglets visibles sur 13, flèches inutilisables | `TabContainer` dans un panneau de 440 px ; barre d'onglets interne tronquée |
| « Population : inconnue », statistiques « inconnu » | `_page_country()` lisait `n["stats"][*]["value"]` (champs `null` du scénario) au lieu des systèmes Phase V |
| « Prototype technique », « 7 puissances » | textes codés en dur dans `main.gd` |
| Export impossible | aucun `export_presets.cfg`, aucun modèle d'export installé |
| Erreur JSON au démarrage de l'export | `data/world/.gdignore` exclut `terrain.json` du PCK ; conséquence : liste des rivières vide |

## 2. Modifications réalisées

### Navigation (13 onglets)
- `src/ui/game_ui.gd` : `HFlowContainer` de 13 boutons qui **passent à la ligne** ; la barre
  d'onglets interne du `TabContainer` est masquée (`tab_bar.visible = false`) pour supprimer les
  flèches tronquées, mais le `TabContainer` et son API (`current_tab`, `get_tab_title`) sont
  conservés — aucun test affaibli.
- Boutons de navigation avec surbrillance de l'onglet actif ; panneau élargi (520 px, 460 px sous
  1400 px de large) ; barre de couches déplacée pour éviter le chevauchement.
- Aucune fonctionnalité supprimée.

### Données nationales
- `src/ui/game_ui.gd` : l'onglet Pays affiche désormais la **population Phase V**
  (`DemographySystem.summary`), la main-d'œuvre et sa répartition, la capacité industrielle
  (`IndustrySystem.capacity`), les stocks (`ResourceSystem.summary`), les soldats sous les
  drapeaux (MIL-01), la stabilité (Phase VII) et les relations bilatérales. Les champs
  d'abstraction encore non sourcés sont signalés explicitement, sans valeur inventée.
- Économie régionale : gisements, population et industrie depuis la baseline Phase V.
- `src/ui/main.gd` : textes corrigés — « Simulation stratégique — 22 États, 90 régions » et
  « Campagne historique 1914 (22 États, forces MIL-01 et Phase II) ».
- `src/domains/diplomacy/relations_system.gd` : `summary()` et `monthly()` tolèrent les relations
  partielles (champs absents) — défaut de lecture découvert pendant les tests UI.

### Exports
- `export_presets.cfg` créé : **Linux x86_64** (priorité 1) et **Windows Desktop** (priorité 2),
  sans chemin personnel ni dépendance propre à cette machine.
- Modèles d'export Godot 4.7.2 installés dans `~/.local/share/godot/export_templates/4.7.2.stable`
  (35 fichiers), hors dépôt.
- `tools/export/build_rivers.py` + `data/rules/rivers.json` : copie reproductible des 59 rivières
  hors du dossier `data/world` marqué `.gdignore`, afin qu'elles soient présentes dans le PCK.
- `src/app/game_session.gd` : lecture des rivières depuis `data/rules/rivers.json`.

## 3. Tests effectivement exécutés

| Commande | Résultat |
|---|---|
| `bash tests/run.sh` | **221 tests réussis, 0 échec** ; UI et UI bataille validées |
| `python3 tools/export/build_rivers.py --check` | PASS |
| `python3 tools/export/build_game_data.py --check` | PASS |
| `python3 tools/export/build_scenario.py --check` | PASS |
| `python3 tools/history/render_fiches.py --check` | PASS |
| `--export-release "Linux x86_64"` | **réussi** (EXIT 0) |
| `--export-release "Windows Desktop"` | **réussi** (EXIT 0) |
| `./GrandStrategy-1914.x86_64 --headless` | **aucune erreur** (l'erreur JSON de l'audit a disparu) |
| Navigation souris 13 onglets | validée visuellement à 1600×900 **et 1280×720** |
| Partie depuis l'exécutable exporté | nouvelle campagne 1914, carte, tours janvier → mars 1914, aucune erreur |

Captures conservées hors dépôt : `/tmp/consol2-final.png` (1600×900, 13 onglets + données),
`/tmp/consol2-1280play3.png` (1280×720), `/tmp/consol2-exe-turn2.png` (tour depuis l'exécutable).

## 4. Plateformes d'export — distinction des niveaux

| Niveau | Linux x86_64 | Windows Desktop | macOS |
|---|---|---|---|
| Preset configuré | OUI | OUI | NON (non prioritaire, environnement indisponible) |
| Modèles disponibles | OUI | OUI | non vérifié |
| Export réussi | **OUI** | **OUI** | NON |
| Exécutable lancé | **OUI** | NON (impossible sur Linux) | NON |
| Partie testée depuis l'exécutable | **OUI** | NON | NON |

Aucune affirmation n'est faite sur le fonctionnement réel de l'exécutable Windows : il est
**produit**, pas testé.

## 5. Non-régression

Les 221 tests de la consolidation 01 restent tous verts. Aucun test supprimé ou affaibli : le
`TabContainer` et son API sont conservés, les tests `ui_smoke`/`battle_ui_smoke` parcourent toujours
les 13 onglets. Les systèmes diplomatique, militaire, économique et politique n'ont pas été
modifiés dans leur logique (seule une lecture défensive de relations partielles a été ajoutée).

## 6. Limites restantes

- L'export Windows n'a pas pu être exécuté sur cet ordinateur Linux ; sa production est vérifiée,
  pas son fonctionnement.
- La fenêtre « prototype » dans le titre (`get_window().title`) n'a pas été corrigée (mineur).
- Les stocks affichent « — » au départ : c'est l'état réel de la Phase V (production accumulée),
  pas un défaut d'affichage.
- Le panneau latéral reste dense à 1280×720 ; les 13 onglets sont accessibles mais la lecture
  des relations demande un défilement vertical (fonctionnel).
- Le multijoueur réseau reste non implémenté (documenté dans l'audit général).

## 7. Verdict final

**A — prêt à être distribué sur les plateformes testées**, avec la réserve explicite que seule
**Linux x86_64** a été réellement lancée et jouée. Windows est produit mais non exécuté ; macOS
n'a pas été préparé.

Commande pour jouer immédiatement sans export :
```
~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path /home/vega/grand-strategy-1914
```

Exécutable exporté : `/home/vega/builds/linux/GrandStrategy-1914.x86_64`.

## 8. Commits et état Git

Commits attendus (à publier sur `origin/dev/mil01-finalisation`) :
- `feat(consolidation02): navigation 13 onglets, donnees nationales Phase V et exports Godot`
- `docs(consolidation02): publier le rapport de consolidation et le rapport de lancement`

Aucun merge vers `main`, aucun push forcé, aucune suppression de branche. Le rapport de lancement
précédent, initialement non commité, est préservé et publié avec cette consolidation.
