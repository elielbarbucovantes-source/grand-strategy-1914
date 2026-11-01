# Stratégie de test

> **Statut :** MVP testé avec `unittest` ; stratégie cible encore ouverte
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Documents liés :** [coding-standards.md](coding-standards.md) · [contribution-guide.md](contribution-guide.md) · [AGENTS.md](../../AGENTS.md) · [ai/decision-making.md](../ai/decision-making.md) · [ADR-0006](../decisions/0006-pile-technique-mvp.md)

---

## 1. Objet

Définir comment le projet prouve qu'une fonctionnalité fonctionne, et comment éviter les fausses déclarations de réussite.

**Règle fondatrice :** un résultat de test non exécuté n'existe pas. Un test qui n'a pas été lancé ne peut pas être déclaré « OK ».

## 1.1 État du MVP (2026-11-01)

- **Framework :** `unittest` de la bibliothèque standard Python (ADR-0006).
- **Commande :** `python3 -m unittest discover -s tests -v`.
- **Résultat réel :** 24 tests, 0 échec.
- **Périmètre couvert :** scénario, économie, recherche, militaire, diplomatie, événements, IA, victoires, sauvegarde/chargement.
- **Tests manuels :** parcours navigateur Firefox/geckodriver consignés dans [PROGRESS.md](../../PROGRESS.md) section G (sélection, observation, prise de contrôle, ordres, fin de tour, sauvegarde/chargement, événement de Sarajevo).
- **Non couvert :** batailles tactiques (absentes), multijoueur (absent), performance à grande échelle, sécurité réseau, qualité subjective des IA.

Les sections suivantes décrivent la stratégie cible ; elles ne doivent pas être lues comme un état déjà réalisé.

## 2. Niveaux de test prévus

| Niveau | Objet | Exemples | Dépendances |
|---|---|---|---|
| Unitaire | Logique isolée | Résolution d'un ordre, calcul de réputation | Aucune |
| Intégration | Interaction entre modules | Noyau + persistance, noyau + API | Base de test |
| Scénario | Partie ou phase complète | Tour de Diplomacy complet | Noyau |
| Simulation | Plusieurs parties automatisées | Équilibrage, IA | Noyau + IA |
| Évaluation IA | Qualité des décisions | Tournois, métriques | Harnais dédié |
| Performance | Temps, mémoire, coût | Résolution à grande échelle | Environnement stable |
| Sécurité | Isolation, secrets, injection | Tentatives de fuite | Configuration dédiée |
| Régression | Bugs déjà corrigés | Chaque bug | Aucune |

## 3. Tests du noyau de règles (priorité absolue)

Le noyau est la partie la plus critique : une erreur invalide toutes les parties.

Tests nécessaires :

- chaque type d'ordre, valide et invalide ;
- conflits de mouvement ;
- coupes de soutien ;
- chaînes de convoi ;
- retraites et constructions ;
- conditions de victoire ;
- cas limites (bord de carte, unités isolées, égalités) ;
- déterminisme : même entrée ⇒ même sortie ;
- rechargement d'une sauvegarde ⇒ même état.

**[PROPOSITION]** Constituer un corpus de scénarios de référence, versionné, servant de base à toutes les évolutions.

## 4. Tests de diplomatie

- cycle de vie d'un traité ;
- propositions, acceptations, rejets, expirations ;
- ruptures et conséquences ;
- visibilité des messages ;
- réputation et décroissance ;
- timeouts et absence de réponse.

## 5. Tests des IA

Les IA ne se testent pas comme une fonction pure. Il faut distinguer :

### 5.1 Tests de contrat

- la sortie respecte le format ;
- les ordres sont légaux ;
- les messages sont adressés à des destinataires valides ;
- le budget est respecté ;
- le fallback fonctionne.

### 5.2 Tests de comportement

- scénarios avec résultat attendu (défendre un allié fiable, profiter d'une faiblesse) ;
- cohérence avec la personnalité ;
- mémoire d'un engagement ancien ;
- résistance à une manipulation ;
- absence de triche informationnelle.

### 5.3 Évaluations quantitatives

- taux de victoire ;
- survie moyenne ;
- respect des engagements ;
- fréquence des trahisons ;
- coût et latence ;
- stabilité des parties.

**[À DÉFINIR — Q-022]** Les métriques exactes, les seuils acceptables et la méthode de comparaison.

### 5.4 Limites

Les tests de comportement ne prouvent pas qu'une IA est « intelligente ». Ils prouvent qu'elle respecte des propriétés observables. Toute affirmation plus forte doit être nuancée.

## 6. Tests de sécurité

- une IA ne peut pas lire l'état complet ;
- un message de jeu ne déclenche pas d'outil ;
- une tentative d'injection ne modifie pas les instructions ;
- les secrets ne sont pas loggés ;
- les fichiers `.env` ne sont pas versionnés ;
- les permissions d'accès aux messages sont respectées.

## 7. Preuves et traçabilité

Chaque intervention doit consigner :

- la commande exacte exécutée ;
- la date ;
- l'environnement (version, commit) ;
- le résultat réel (succès, échec, nombre de tests) ;
- les tests non exécutés et la raison.

Le journal de PROGRESS.md ne doit contenir ni « tests OK » générique, ni résultat inventé.

## 8. Ce qui compte comme « testé »

| Situation | Statut |
|---|---|
| Test automatisé exécuté et réussi | Testé |
| Test manuel documenté avec étapes et résultat | Testé manuellement |
| Vérification de compilation | Vérifié à la compilation, pas testé fonctionnellement |
| Relecture visuelle | Non testé |
| « Ça devrait marcher » | Non testé |

## 9. Intégration continue (à définir)

**[À DÉFINIR — TD-013]** Une CI devra à terme :

- formater et linter ;
- compiler ;
- exécuter les tests unitaires et d'intégration ;
- vérifier les secrets ;
- produire un rapport ;
- échouer explicitement.

Aucun pipeline n'existe aujourd'hui.

## 10. Couverture

**[PROPOSITION]** La couverture de code est un indicateur, pas un objectif. Le noyau de règles doit avoir une couverture élevée et surtout des scénarios pertinents. Les interfaces et les adaptateurs peuvent être moins couverts.

Ne jamais gonfler la couverture avec des tests sans assertion.

## 11. Tests manuels

Lorsqu'un test manuel est nécessaire :

- décrire les prérequis ;
- décrire les étapes ;
- décrire le résultat attendu ;
- consigner le résultat observé ;
- joindre une capture si utile ;
- identifier la personne ou l'outil qui a testé.

## 12. Tests de performance et de coût

Pour les IA et le serveur :

- temps de résolution d'un tour ;
- temps de réponse d'un agent ;
- coût par partie ;
- nombre d'appels ;
- mémoire utilisée ;
- comportement sous charge.

**[À DÉFINIR]** Les seuils acceptables dépendent du rythme de partie (Q-005) et du budget (Q-023).

## 13. Politique en cas d'échec

- Un test qui échoue bloque la déclaration « Terminé ».
- Un test instable doit être identifié comme tel, pas supprimé.
- Un test ignoré doit avoir une justification et une tâche de suivi.
- Un bug corrigé sans test de non-régression doit être signalé comme dette.

## 14. Questions ouvertes

| ID | Question |
|---|---|
| TS-001 | Quel framework de test (TD-011) ? |
| TS-002 | Quelle CI (TD-013) ? |
| TS-003 | Quels scénarios de référence ? |
| TS-004 | Quelles métriques pour les IA (Q-022) ? |
| TS-005 | Quels seuils de performance ? |
| TS-006 | Comment tester le déterminisme sur plusieurs plateformes ? |
| TS-007 | Comment tester la sécurité des prompts ? |
| TS-008 | Quelle politique de couverture ? |

## 15. Critères de passage à « Spécifié »

- [ ] Framework et CI choisis.
- [ ] Arborescence de tests définie.
- [ ] Scénarios de référence du noyau listés.
- [ ] Métriques IA définies.
- [ ] Tests de sécurité définis.
- [ ] Format de preuve adopté.
- [ ] Validation du propriétaire.
