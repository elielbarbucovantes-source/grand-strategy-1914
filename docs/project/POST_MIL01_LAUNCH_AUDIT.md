# POST_MIL01_LAUNCH_AUDIT — Audit de lancement

> **Date :** 2026-11-20
> **Agent :** OpenCode
> **Branche :** `dev/mil01-finalisation`
> **État du dépôt :** `d24e2b8f5d52684e8b45337877d3f428fc78f2e7`, arbre propre avant et après l'audit.
> **Contraintes respectées :** aucun code, paramètre, donnée ou fichier existant modifié ; aucun
> commit, aucun push. Seul ce rapport est créé.

---

## 1. Résumé exécutif — Verdict **B : jouable sous conditions**

Le jeu **se lance réellement et se joue** sur cet ordinateur : menu principal, nouvelle campagne,
carte stratégique, onglets, tours, IA, sauvegarde, fermeture, relance et rechargement ont été
**effectivement essayés en interface graphique** et fonctionnent. Les journaux ne contiennent
aucune erreur ni avertissement.

Les conditions qui empêchent le verdict A sont :
1. **Aucun export n'est possible** : pas de `export_presets.cfg` et aucun modèle d'export Godot
   installé. Le jeu ne peut être lancé que depuis le binaire Godot avec le chemin du projet.
2. **Problèmes d'interface visibles** : textes obsolètes (« Prototype technique », « Population :
   inconnue » alors que la Phase V fournit des données), barre d'onglets tronquée (4 onglets
   visibles sur 13 à 1600×900), panneau latéral dense.
3. **Plateforme unique vérifiée** : Linux x86_64 uniquement. Rien n'a été testé sous Windows/macOS.

## 2. Tests réellement effectués et commandes utilisées

| # | Action | Commande / moyen | Résultat observé |
|---|---|---|---|
| 1 | État du dépôt | `git status --short`, `git rev-parse HEAD`, `git fetch origin --prune` | propre, local = distant |
| 2 | Versions Godot | `godot --version` (binaire `~/.local/opt/godot-4.7.2/...`) | **4.7.2.stable.official.ed1daf0bf** ; projet declare `config/features = 4.7` → compatible |
| 3 | Lancement réel GUI | `~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path .` | processus actif, **aucune erreur** dans le journal |
| 4 | Capture du menu | `xwd -id <fenêtre>` + conversion PIL hors dépôt | menu lisible (voir `godot.png` ci-dessous) |
| 5 | Nouvelle partie | clic XTest sur « Nouvelle partie » | campagne janvier 1914, Royaume-Uni, carte 90 régions |
| 6 | Navigation onglets | clics sur « Diplomatie », « Économie » | contenus affichés, aucun plantage |
| 7 | Passage de tours | clic « Fin du mois » × plusieurs | date janvier → février → … → mai 1914 |
| 8 | Sauvegarde UI | clic « Sauvegarder » | `partie_united_kingdom_tour4.json` (~1,1 Mo) créé dans `app_userdata` |
| 9 | Rechargement en session | avancée à juillet puis clic « Charger » | retour à **mai 1914** |
| 10 | Fermeture puis relance | `kill <pid>` puis relance du binaire | redémarrage propre, nouveau menu |
| 11 | Rechargement après relance | clic « Charger la dernière sauvegarde » | partie restaurée à **mai 1914** |
| 12 | Tentative d'export | `--headless --export-release "Linux"` (et autres presets) | **échec** : « This project doesn't have an `export_presets.cfg` file » |
| 13 | Modèles d'export | inspection de `~/.local/share/godot/export_templates/` | **dossier vide** |
| 14 | Tests automatisés | `bash tests/run.sh` | **221 tests réussis, 0 échec**, UI et UI bataille validées |
| 15 | Arrêt du jeu | `kill <pid>` | processus arrêté, dépôt toujours propre |

Journaux et captures conservés hors dépôt dans `/tmp/gs1914-audit/` : `gui.log`, `gui2.log`,
`godot.png` (menu), `after-click.png` (carte), `diplo-panel.png`, `s-adv.png` / `s-load.png`
(sauvegarde/rechargement), `reload-top.png` (reprise après relance), `tests-final.log`.

## 3. Vérification Godot et chargement des ressources

- Version requise : Godot 4.7 (`project.godot`) ; version installée : 4.7.2 stable → compatible.
- Scène principale : `res://src/ui/main.tscn` — chargée avec succès.
- Moteur de rendu : `gl_compatibility`, OpenGL 3.3 Mesa 25.2.8, AMD RV710 → carte et figurines
  rendues correctement.
- Données historiques et cartographiques chargées : 90 régions colorées, 175 villes/capitales
  (étoiles jaunes), noms de capitales visibles, frontières nettes.
- Aucune dépendance manquante signalée ; aucun `push_error` ou `SCRIPT ERROR` dans les journaux.
- Les 13 onglets sont instanciés sans erreur (validé aussi par `tests/ui_smoke.gd` dans la suite).

## 4. Exports — distinction des niveaux

| Niveau | État |
|---|---|
| Export configuré | **NON** — aucun `export_presets.cfg` à la racine |
| Export techniquement possible | **NON** — aucun modèle d'export dans `~/.local/share/godot/export_templates/` |
| Export effectivement réalisé | **NON** — trois tentatives (`Linux`, `Linux/X11`, `Windows Desktop`) toutes échouées |
| Exécutable lancé et testé | **NON** — seul le lancement depuis le binaire Godot + `--path .` a été testé |

Aucune affirmation ne peut être faite concernant un exécutable Windows ou macOS.

## 5. Parcours utilisateur observé

1. Menu principal : titre, devise, sélecteurs *Puissance* (Royaume-Uni par défaut), *Scénario*
   (campagne historique 1914), *Mois de départ*, boutons « Nouvelle partie » et « Charger la
   dernière sauvegarde ».
2. « Nouvelle partie » → carte stratégique, janvier 1914, contrôle 6,7 %, victoire `ongoing`.
3. Barre supérieure : date, nation, contrôle, « Fin du mois », « Sauvegarder », « Charger »,
   « Menu », « Panneau » — tous présents ; « Fin du mois », « Sauvegarder » et « Charger »
   effectivement testés.
4. Barre de couches : `rail, road, river, maritime, ports, interruptions, capacity, resources,
   industry, population, agriculture, stocks, airbases, fleets, intel_activity, rivers, bridges`.
5. Onglets observés : Pays, Diplomatie, Économie, Industrie (les autres existent mais sont hors
   cadre visible à 1600×900).
6. Onglet Diplomatie : négociations, relations chiffrées (confiance/hostilité/tensions), boutons
   Guerre / Passage / Alliance / Garantie / Crise pour chaque État.
7. Onglet Pays : **affiche « Population : inconnue (NAT-02) » et toutes les statistiques
   « inconnu »**, alors que la Phase V calcule population, industrie, ressources et main-d'œuvre.
8. Passage de 7 tours : date avancée jusqu'à juillet 1914, indicateur de victoire stable, aucune
   erreur visible. L'IA produit des ordres à chaque tour (vérifié aussi par les simulations
   automatiques) ; son détail n'a pas été suivi à l'écran tour par tour.
9. Sauvegarde/rechargement : validé dans la session **et** après fermeture/relance complète.
10. Aucun bouton « Quitter » n'a été identifié dans le menu principal ; l'arrêt a été fait par
    signal au processus (propre, sans erreur).

## 6. Expérience utilisateur observée

**Points positifs :** carte lisible, couleurs nationales distinctes, capitales toujours visibles,
texte globalement lisible à 1600×900, navigation entre onglets fonctionnelle, boutons de tour et
de sauvegarde réactifs.

**Points problématiques :**
- Textes obsolètes : « Prototype technique : voir docs/project/PROTOTYPE_STATUS.md » et
  « Campagne historique 1914 (effectifs sourcés des 7 puissances…) » alors que 22 États sont
  intégrés ; « Population : inconnue » et statistiques « inconnu » alors que les systèmes Phase V
  produisent ces valeurs.
- Barre d'onglets tronquée : seuls 4 onglets sur 13 visibles ; les flèches de défilement n'ont pas
  permis d'atteindre les onglets Politique, Victoire et Multijoueur lors de l'essai manuel.
- Panneau latéral dense : les boutons d'action diplomatique se répètent sur 21 lignes, rendant la
  lecture difficile sans défilement.
- Aucun retour visuel évident expliquant pourquoi une action particulière serait refusée
  (les motifs sont enregistrés dans `orders_history.rejected`, mais non mis en avant).
- Résolution testée : 1600×900 (fenêtre 1614×981 avec cadre). Aucune autre résolution testée.

## 7. Fonctionnalités non testées manuellement

- Décisions diplomatiques individuelles (proposition d'alliance/transit, acceptation/refus) et
 traité universel depuis l'interface : **boutons et section observés, effet non suivi à l'écran** ;
  couverts par les tests automatisés (221 tests) et les 36 simulations de consolidation.
- Interface de production industrielle, recherche, aviation, marine, politique, victoire,
  multijoueur : **instanciées sans erreur** (UI smoke) mais non parcourues manuellement faute
  d'accès aux onglets tronqués.
- export Windows/macOS/Web : non testé (impossible, cf. §4).
- Multijoueur réseau : non testé (non implémenté, documenté dans l'audit général).
- Comportement à d'autres résolutions, plein écran, et après longue session (> 7 tours ici).

## 8. Problèmes rencontrés pendant l'audit

| Problème | Gravité | Impact |
|---|---|---|
| Aucun preset/template d'export | **Majeur** | impossible de distribuer un exécutable ; lancement uniquement via Godot |
| Textes « inconnu » dans l'onglet Pays | **Majeur (UX)** | le joueur croit que l'économie n'existe pas |
| Onglets tronqués (4/13 visibles) | **Modéré** | certaines interfaces inaccessibles à la souris à 1600×900 |
| Textes « 7 puissances » / « Prototype technique » | **Modéré** | information fausse sur l'état du projet |
| Aucun bouton Quitter visible | **Mineur** | dépendance au gestionnaire de fenêtre |

Aucun problème technique bloquant le lancement ou la sauvegarde n'a été observé.

## 9. Séparation des niveaux de preuve

| Catégorie | Détail |
|---|---|
| Implémenté | 13 onglets, 17 couches cartographiques, tour, IA, sauvegarde, export (non configuré) |
| Testé automatiquement | 221 tests, UI smoke parcourant les 13 onglets, simulations de toutes les phases |
| Effectivement essayé en jeu | lancement, menu, nouvelle partie, carte, onglets Pays/Diplomatie/Économie, 7 tours, sauvegarde, rechargement en session, fermeture, relance, rechargement depuis le menu |
| Non essayé en jeu | traité universel, production, recherche, aviation/marine, politique, victoire, multijoueur, export |

## 10. Verdict et réponses finales

**Verdict : B — jouable sous conditions.**

**Puis-je lancer le jeu maintenant ?** Oui, sur cet ordinateur, en Local.

**Quelle commande ?**
```
~/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path /home/vega/grand-strategy-1914
```
(ou ouvrir le dossier `/home/vega/grand-strategy-1914` comme projet dans l'éditeur Godot 4.7.2 et appuyer sur F6/F5).

**Sur quelle plateforme ?** Linux x86_64 uniquement (X11/Wayland via XWayland, OpenGL Mesa). Aucune autre plateforme vérifiée.

**Étapes à suivre ?**
1. Lancer la commande ci-dessus.
2. Dans le menu, choisir une *Puissance* et *Campagne historique 1914*.
3. Cliquer « Nouvelle partie ».
4. Utiliser « Fin du mois » pour avancer, « Sauvegarder » / « Charger » pour la persistance.
5. Consulter les onglets (certains nécessitent un élargissement de la fenêtre ou un défilement horizontal).

**Qu'est-ce qui empêche de jouer ?** Rien de bloquant pour une session locale. Les limites sont :
absence d'export exécutable, textes d'interface obsolètes/trompeurs, onglets tronqués à 1600×900,
et multijoueur réseau non implémenté.

**Recommandation avant distribution :** configurer un preset Linux + installer les modèles d'export,
corriger les textes « inconnu »/« 7 puissances », élargir ou rendre scrollable la barre d'onglets.

Aucune correction n'a été appliquée pendant cet audit, conformément à la mission.
