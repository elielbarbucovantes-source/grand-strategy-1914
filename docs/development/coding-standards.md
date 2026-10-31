# Conventions de programmation

> **Statut :** Cadrage — la pile technique n'étant pas choisie, ce document fixe des principes et non des règles de syntaxe
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [testing-strategy.md](testing-strategy.md) · [contribution-guide.md](contribution-guide.md) · [AGENTS.md](../../AGENTS.md) · [architecture/technical-decisions.md](../architecture/technical-decisions.md)

---

## 1. Portée

Ce document s'appliquera dès le premier fichier de code. Tant que le langage n'est pas choisi (TD-001), les règles spécifiques à un langage restent **à définir**. Les principes ci-dessous sont indépendants du langage.

## 2. Principes généraux

1. **Lisibilité avant astuce.** Un code compris par un autre agent des mois plus tard a plus de valeur qu'un code court et obscur.
2. **Une responsabilité par module.** Le noyau de règles ne connaît ni l'interface ni les IA.
3. **Explicite plutôt qu'implicite.** Les dépendances, effets de bord et hypothèses doivent être visibles.
4. **Déterministe par défaut.** Toute source d'aléatoire est injectée et enregistrée.
5. **Testable.** Une logique métier doit pouvoir être testée sans réseau, sans interface et sans LLM.
6. **Petites unités.** Fonctions et modules courts, noms précis.
7. **Pas de duplication.** Factoriser seulement quand la duplication est réelle et stable.
8. **Pas de dépendance inutile.** Chaque dépendance doit être justifiée (AGENTS.md § 10).
9. **Documentation utile.** Commenter le *pourquoi*, pas le *quoi* évident.
10. **Erreurs explicites.** Ne jamais ignorer silencieusement une erreur.

## 3. Nommage

En attendant le choix du langage :

- noms en anglais pour le code (identifiants, modules, types), afin de rester compatible avec l'écosystème ;
- documentation et messages de jeu en français par défaut, sauf décision contraire ;
- pas d'abréviations ambiguës ;
- les noms de domaine du jeu doivent être cohérents avec le glossaire (à créer) ;
- les constantes de configuration ne doivent pas être codées en dur dans la logique.

**[À DÉFINIR]** Le choix définitif de la langue des identifiants doit être validé par le propriétaire. En attendant, l'anglais est une **proposition**, pas une règle validée.

## 4. Organisation des fichiers

Structure cible proposée, à adapter au langage :

```
src/
├── core/          # règles, état, résolution (pur)
├── diplomacy/     # messages, traités, réputation
├── ai/            # perception, mémoire, décision (sans règles)
├── persistence/   # sauvegarde, journal
├── api/           # interfaces
└── shared/        # types et utilitaires communs

tests/
├── unit/
├── integration/
├── scenarios/
└── fixtures/
```

Cette organisation est une **proposition**. Elle ne doit pas être créée avant validation de l'architecture.

## 5. Frontières et dépendances

Rappel des règles proposées ([architecture/overview.md](../architecture/overview.md)) :

- `core` ne dépend d'aucune autre couche applicative ;
- `ai` ne reçoit jamais l'état complet ;
- `api` ne contient pas de règle métier ;
- `persistence` ne décide pas des règles ;
- les dépendances circulaires sont interdites.

## 6. Style et formatage

**[À DÉFINIR — TD-016]** Une fois le langage choisi :

- utiliser un formateur automatique unique ;
- utiliser un linter unique ;
- configurer l'éditeur pour formater à l'enregistrement ;
- ne pas mélanger plusieurs styles ;
- documenter les règles dans ce fichier ;
- vérifier le formatage en CI.

Aucun style manuel ne doit être imposé avant que l'outil soit choisi.

## 7. Commentaires et documentation du code

- Les API publiques doivent être documentées.
- Les décisions non évidentes doivent être expliquées (pourquoi, alternatives).
- Les `TODO` doivent être reliés à une tâche de PROGRESS.md ou à un ADR ; un `TODO` orphelin est un défaut.
- Ne pas laisser de code commenté mort : supprimer ou justifier.
- Ne pas documenter une fonctionnalité non implémentée comme si elle existait.

## 8. Gestion des erreurs

- Distinguer erreur attendue (ordre invalide) et erreur inattendue (bug).
- Un ordre invalide produit un rejet explicite, pas une exception non gérée.
- Ne jamais avaler une erreur sans log.
- Les messages d'erreur destinés au joueur ne doivent pas révéler d'information cachée.
- Les erreurs des LLM doivent être traitées comme des défaillances récupérables.

## 9. Journalisation

- Logs structurés (niveau, horodatage, corrélation, acteur).
- Ne jamais logger de secret, de clé ou de donnée personnelle inutile.
- Les messages de jeu peuvent être journalisés, mais avec une politique de rétention.
- Les décisions d'IA doivent être traçables sans exposer les secrets des autres agents.
- Les logs de debug ne doivent pas être activés par défaut en production.

## 10. Configuration et secrets

- Toute configuration passe par des variables d'environnement ou un fichier de configuration non versionné.
- `.env.example` documente les variables, sans valeur réelle.
- Aucune clé API dans le code, les tests, les fixtures ou les logs.
- Les valeurs par défaut doivent être sûres (pas de mode debug en production).
- Un secret compromis doit être révoqué, pas seulement supprimé du fichier.

## 11. Dépendances

Avant ajout :

1. nécessité démontrée ;
2. licence vérifiée ;
3. maintenance et sécurité vérifiées ;
4. version épinglée ;
5. justification documentée ;
6. ADR si structurante.

Éviter les dépendances pour des tâches triviales. Préférer la bibliothèque standard quand elle suffit.

## 12. Tests

- Chaque règle métier doit avoir des tests.
- Chaque bug corrigé doit avoir un test de non-régression.
- Les tests doivent être déterministes.
- Ne jamais désactiver un test sans justification et sans tâche de suivi.
- Ne pas écrire de test qui passe artificiellement (mock de la logique testée).
- Voir [testing-strategy.md](testing-strategy.md).

## 13. Revue de code

La revue vérifie :

- conformité au périmètre annoncé ;
- lisibilité et nommage ;
- frontières d'architecture ;
- tests et résultats ;
- absence de secrets ;
- documentation ;
- performance raisonnable ;
- cohérence avec les ADR.

Un agent ne doit pas approuver son propre travail lorsqu'une revue indépendante est requise.

## 14. Definition of Done

Voir [AGENTS.md § 12](../../AGENTS.md#12-definition-of-done-dod). Aucune tâche n'est terminée sans tests réels et documentation à jour.

## 15. Règles spécifiques à définir après le choix de la pile

- [ ] langue des identifiants ;
- [ ] formateur et linter ;
- [ ] gestion des imports ;
- [ ] style de tests ;
- [ ] gestion des erreurs idiomatique ;
- [ ] structure des modules ;
- [ ] versionnement des API ;
- [ ] outillage de build ;
- [ ] CI.

Ces points seront ajoutés ici par un ADR ou une mise à jour signée, pas improvisés dans le code.
