# Déconnexions pendant une bataille (T-046)

**Statut :**
- **T-046 VALIDÉ** (directeur, 15/11/2026) ;
- délai de grâce : valeur PROPOSÉE, configurable ;
- **aucune couche réseau n'existe** : seules les fondations de simulation sont implémentées et testées.

**Code :**
- `BattleManager.on_disconnect`, `on_reconnect`, `voters`, `_grace_expiry` ;
- `GameSession.disconnect_player`, `reconnect_player`.

**Paramètres :** `data/rules/combat_rules.json`, bloc `disconnection`.

**Tests :** `tests/unit/test_disconnect_t046.gd`, `tests/unit/test_combat.gd`.

## 1. Règles

| Mode | Déconnexion | Pendant l'absence | Reconnexion |
|---|---|---|---|
| **Solo** (un seul humain dans la partie) | Bataille **mise en pause** (`disconnect_pause`) | Le temps ne s'écoule pas ; unités et ordres intacts | Pause levée, contrôle restitué |
| **Multijoueur** | Contrôleur `disconnected` ; la bataille **continue** pour les autres | **Délai de grâce** (`grace_ticks`, 30 pas = 1 min de bataille, PROPOSÉ) : les unités **conservent leurs ordres**, personne ne les commande. Ensuite, contrôleur `ai_takeover` : l'IA tactique décide pour elles | Contrôleur `human` : le joueur reprend ses unités dans leur état, avec les ordres en cours (les siens, ou ceux donnés par l'IA après le délai) |

**Compatibilité avec T-029 I (pause unanime) :**
- Votent seulement les humains participants **actuellement connectés** (`BattleManager.voters`).
- Un joueur déconnecté, ou remplacé par l'IA, ne vote pas. Son vote antérieur est effacé.
- Si une pause était en cours, elle est maintenue seulement si les humains restants l'avaient tous votée.
- Le délai de grâce court en temps de bataille. Il ne s'écoule donc pas pendant une pause unanime des joueurs restants.

## 2. Garanties

- **Aucune perte ni duplication :**
  - la déconnexion ne touche ni la liste des unités de la bataille, ni les formations stratégiques, ni les verrous `battle_id` ;
  - les tests comparent ces trois ensembles avant et après.
- **Brouillard de guerre :**
  - l'IA qui remplace un joueur est `TacticalAI.decide`, qui ne lit que la mémoire du brouillard de son camp ;
  - cette non-omniscience est couverte par `test_ai_respects_fog`.
- **Autres joueurs non affectés :**
  - en multijoueur, aucune pause n'est imposée ;
  - la bataille avance et les autres humains gardent leur contrôle et leur vote.
- **Cohérence du passage humain → IA → humain :**
  - un seul champ fait foi : `controllers[nation]` ;
  - l'IA n'agit que si ce champ vaut `ai` ou `ai_takeover` ;
  - le passage est instantané et journalisé dans `b.log` ;
  - l'état est sauvegardé et rechargé à l'identique (test d'empreinte).

## 3. Limites restantes

- **Non implémenté et non testé :**
  - détection réelle d'une déconnexion réseau ;
  - délai mesuré en temps réel ;
  - reconnexion d'un client distant ;
  - synchronisation multi-postes.
- Les fonctions sont appelées directement par les tests ; aucune interface ni couche réseau ne les appelle encore.
- Une déconnexion **hors bataille**, pendant la phase stratégique, n'est pas couverte par T-046 et reste à définir.
- La pause de déconnexion en solo bloque aussi la fin du mois, puisque la bataille reste active (T-029 A).
