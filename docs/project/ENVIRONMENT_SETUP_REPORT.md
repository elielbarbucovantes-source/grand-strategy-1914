# ENVIRONMENT_SETUP_REPORT — Reconstitution de l'environnement (Phase 0)

> **Date :** 2026-11-17
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **Commit de référence :** `f0de9725de8150824287d34b25b1d723f57902b8`
> **Statut :** Phase 0 **VALIDÉE** — environnement fiable, Phase II autorisée.

---

## 1. Configuration de l'ordinateur

| Élément | Valeur observée |
|---|---|
| Système | Ubuntu 24.04.5 LTS (noble) |
| Noyau | Linux 6.8.0-149-generic #149-Ubuntu SMP x86_64 |
| Architecture | amd64 (x86_64) |
| Disque | 292 Go au total, **253 Go disponibles** (9 % utilisé) |
| Interpréteur de commandes | GNU bash 5.2.21(1)-release |
| Réseau | GitHub accessible (HTTP 200, ~1 s) |

## 2. Outils installés et versions

| Outil | Version | Emplacement / remarque |
|---|---|---|
| Git | 2.43.0 | `/usr/bin/git` (préinstallé) |
| Godot | **4.7.2.stable.official.ed1daf0bf** | `~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64` |
| Python | 3.12.3 | `/usr/bin/python3` (préinstallé) |
| uv | 0.13.8 | `~/.local/bin/uv` (déjà présent, utilisé pour créer le venv) |
| bash | 5.2.21 | `/usr/bin/bash` |
| curl / wget / unzip / sha256sum | présents | `/usr/bin/` |
| Dépendances GIS | numpy 2.5.4, pyogrio 0.13.0, pyproj 3.8.0, shapely 2.2.0, certifi 2026.10.23, packaging 26.3 | venv `~/.venvs/gs1914-gis`, versions **exactes** de `tools/map/requirements.lock` |
| jq | absent | non nécessaire aux scripts du projet |

### Installation de Godot

Binaire officiel téléchargé depuis la release GitHub `godotengine/godot` tag `4.7.2-stable`,
**vérifié par SHA-512** contre `SHA512-SUMS.txt` officiel (`grep " $F.zip$" ... | sha512sum -c -`
→ `Réussi`), exactement comme la procédure du workflow CI `.github/workflows/game-tests.yml`.
Aucun binaire tiers n'a été utilisé. Un lien `godot` pointe vers le binaire.

### Environnement Python

`python3 -m venv` échouait initialement (`ensurepip` absent sur cette image Ubuntu ; le paquet
`python3.12-venv` nécessite un mot de passe sudo non disponible). Solution retenue : création du
venv avec `uv venv --python 3.12`, puis `uv pip install -r tools/map/requirements.lock`.
Aucune version de dépendance n'a été modifiée.

## 3. Dépôt et branche

| Élément | Valeur |
|---|---|
| Emplacement | `/home/vega/grand-strategy-1914` |
| Origine | `https://github.com/elielbarbucovantes-source/grand-strategy-1914.git` |
| Branche active | `dev/mil01-finalisation` (suivi de `origin/dev/mil01-finalisation`) |
| Commit local | `f0de9725de8150824287d34b25b1d723f57902b8` |
| Commit distant | `f0de9725de8150824287d34b25b1d723f57902b8` |
| Différence | **aucune** — synchronisation exacte |
| Arbre de travail | propre avant toute modification |

Le dépôt existait déjà localement (initialement sur `research/natural-resources-1914`, arbre
propre). La branche cible n'existait pas localement ; `git fetch --all --prune` l'a rendue
disponible, puis `git checkout -b dev/mil01-finalisation --track origin/dev/mil01-finalisation`
a été effectué **sans perte de modification locale** (la branche de recherche est conservée).
Aucune archive ZIP n'a été utilisée pour remplacer le dépôt Git.

### Documents téléchargés conservés (références documentaires uniquement)

- `~/Téléchargements/grand-strategy-1914-main.zip` — archive GitHub du commit `1ec985f`.
- `~/gs1914-zip/grand-strategy-1914-main/` — extraction non destructive de cette archive.
- Ces documents sont antérieurs au dépôt de développement (ils ne contiennent ni Godot, ni
  historique de branche complet) et n'ont **pas été modifiés**. Ils servent uniquement de
  référence documentaire.

## 4. Vérification du projet

| Contrôle | Résultat |
|---|---|
| `godot --version` | `4.7.2.stable.official.ed1daf0bf` |
| Import des ressources (`--headless --import`) | effectué sans erreur bloquante |
| `project.godot` | `config_version=5`, `config/features=4.7`, scène principale `res://src/ui/main.tscn` |
| Scènes et ressources principales | accessibles (UI smoke : 90 régions dessinées, 10 onglets construits) |
| Erreurs de parsing GDScript | aucune (`tests/run.sh` échoue explicitement sur `SCRIPT ERROR`, `Parse Error`, `Compile Error`) |
| Exports reproductibles | `build_game_data.py --check`, `build_scenario.py --check`, `render_fiches.py --check` → **PASS** (3/3) |
| Configurations de campagne | scénarios exportés et vérifiés par `--check` ; campagne historique chargée par les tests |
| Validation cartographique | `tools/map/validate_all.sh` → **VALIDÉ** : 94 + 96 + 34 contrôles, 0 échec |

### Tests de référence — `bash tests/run.sh`

```
RÉSULTAT : 144 test(s) réussi(s), 0 échec(s)
RÉSULTAT UI : VALIDÉ
RÉSULTAT UI BATAILLE : VALIDÉ
TESTS_EXIT=0
```

Durée d'exécution : quelques minutes (limites internes 900 s / 300 s / 300 s non atteintes).

## 5. Erreurs rencontrées et solutions appliquées

| Erreur | Diagnostic | Solution |
|---|---|---|
| `python3 -m venv` : `ensurepip is not available` | Paquet système `python3.12-venv` absent, sudo non interactif indisponible | venv créé avec `uv venv --python 3.12`, dépendances installées depuis le lock sans changement de version |
| `ERROR: Parse JSON failed. Error at line 0: Unterminated string` pendant `test_save_load_roundtrip_and_integrity` | **Attendu** : le test écrit volontairement un fichier tronqué (`text.substr(0, 200)`) et vérifie que `SaveRepository.load_save` retourne bien `{"error": ...}` | Aucune action ; le test passe. Comportement de robustesse validé, non une erreur d'environnement. |
| `DeprecationWarning: shapely.ops.transform()` | Avertissement de la bibliothèque épinglée (shapely 2.2.0) | Non bloquant ; aucune modification de version ni de code (conformément à la consigne) |
| `AVERTISSEMENT: l’absence d’une emprise de référence empêche de conclure...` (validate_atlas) | Limite documentée de la validation cartographique, déjà connue du projet | Non bloquant ; 34 contrôles thématiques validés par ailleurs |

Aucune erreur provenant du dépôt ou du code n'a été masquée, et aucun code n'a été modifié
pour faire passer les tests.

## 6. Conclusion

L'environnement est **suffisamment fiable** pour entrer en Phase II : version exacte de Godot
vérifiée par empreinte, dépôt Git complet avec historique et branche cible synchronized,
dépendances épinglées reproduites, 144 tests GDScript + 2 suites UI + 3 exports reproductibles
+ 224 contrôles cartographiques tous réussis.

**Phase II peut commencer. La Phase III ne sera pas commencée sans validation explicite.**
