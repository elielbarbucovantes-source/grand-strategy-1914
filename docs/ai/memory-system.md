# Mémoire des IA

> **Statut :** MVP : pas de mémoire longue ; système cible non conçu
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Documents liés :** [ai-architecture.md](ai-architecture.md) · [personalities.md](personalities.md) · [decision-making.md](decision-making.md) · [diplomacy/reputation.md](../diplomacy/reputation.md) · [architecture/data-model.md](../architecture/data-model.md)

---

## 0. Cadre validé par la fiche maîtresse

**[VALIDÉ]** Les IA disposent d'une **mémoire à long terme** : conversations, promesses, trahisons, alliances, conflits, erreurs stratégiques et événements importants (D-011, § 7.3).

**[VALIDÉ]** Une IA trahie doit pouvoir en tenir compte **longtemps après les faits** (§ 7.3).

**[VALIDÉ]** La mémoire est liée à la réputation et aux accords, sans que le modèle exact soit défini. Voir [../diplomacy/reputation.md](../diplomacy/reputation.md).

**[À DÉFINIR — T-023]** Support, rétention, résumé, oubli, coût, confidentialité et reproductibilité. Aucune base de données ni technique d'embedding n'est choisie.

## 1. Objet

Définir ce qu'un agent IA doit retenir, comment il le retrouve, comment il oublie, et comment cette mémoire reste cohérente, utile et abordable.

**Aucun système de mémoire n'est conçu.**

## 2. Pourquoi la mémoire

Sans mémoire, un agent :

- répète les mêmes erreurs ;
- oublie ses engagements ;
- ne peut pas construire de relations ;
- réagit au dernier message seulement ;
- paraît incohérent.

Avec mémoire, il peut :

- tenir un raisonnement long ;
- reconnaître un allié fiable ou un traître ;
- tenir compte de l'historique d'une négociation ;
- évaluer ses propres prédictions ;
- développer un style.

## 3. Types de mémoire proposés

| Type | Contenu | Durée | Exemple |
|---|---|---|---|
| Mémoire de travail | Contexte du tour courant | Tour | Messages récents, ordres en cours |
| Mémoire épisodique | Événements marquants | Partie | Trahison subie au tour 5 |
| Mémoire sociale | Relations et confiance | Partie / long terme | « B a tenu trois traités » |
| Mémoire stratégique | Plans et objectifs | Partie | « Éliminer C avant le tour 10 » |
| Mémoire sémantique | Connaissances sur les règles | Permanente | « Le soutien coupe un mouvement » |
| Mémoire réflexive | Leçons et erreurs | Partie / long terme | « J'ai trop fait confiance à D » |

**[À DÉFINIR]** Faut-il distinguer formellement ces types, ou utiliser un stockage unique avec des métadonnées ?

## 4. Que stocker

**[PROPOSITION]** Pour chaque événement important :

- date / tour / phase ;
- acteurs concernés ;
- type d'événement ;
- résumé factuel ;
- interprétation de l'agent (croyance, pas vérité) ;
- importance ;
- émotion simulée éventuelle ;
- lien vers l'événement source ;
- date de dernière récupération.

**Ne pas stocker** :

- des secrets d'autres agents auxquels l'agent n'a pas droit ;
- des données personnelles inutiles ;
- des transcriptions complètes si un résumé suffit.

## 5. Récupération

**[À DÉFINIR]** Comment retrouver les souvenirs pertinents :

- par acteur concerné ;
- par type d'événement ;
- par récence ;
- par importance ;
- par similarité sémantique ;
- par proximité avec la situation courante.

**Contrainte :** le contexte envoyé au modèle doit rester borné. Un système de résumé et de sélection est nécessaire.

## 6. Résumé et compression

**[PROPOSITION]**

- résumé périodique des événements peu importants ;
- conservation intégrale des événements critiques (trahisons, traités, guerres) ;
- consolidation des relations sociales ;
- réécriture contrôlée, avec traçabilité de l'original si possible.

**[À DÉFINIR]** Les résumés sont-ils générés par le LLM ? Comment éviter les distorsions et les hallucinations ?

## 7. Oubli

**[À DÉFINIR]**

- la mémoire est-elle illimitée pendant une partie ?
- certains souvenirs s'effacent-ils ?
- l'oubli est-il volontaire (pour simuler l'humain) ou technique (limites de contexte) ?
- un agent peut-il « décider » d'oublier une offense ?
- comment gérer la fin de partie et une éventuelle mémoire inter-parties ?

## 8. Mémoire et personnalité

La mémoire donne de la continuité à la personnalité :

- un agent loyal se souvient de ses engagements ;
- un agent vindicatif se souvient des offenses ;
- un agent opportuniste oublie vite les promesses peu coûteuses.

**[À DÉFINIR]** La personnalité influence-t-elle la sélection des souvenirs ? Oui, probablement, mais selon quels poids ?

## 9. Mémoire et réputation

- La réputation est une forme agrégée de mémoire sociale.
- La mémoire doit conserver les **preuves** qui justifient la réputation.
- Un agent peut se tromper : sa mémoire est une croyance, pas la vérité du journal.
- Les autres agents ne doivent pas pouvoir lire sa mémoire.

## 10. Persistance et confidentialité

**[À DÉFINIR]**

- la mémoire est-elle stockée côté serveur ou côté agent ?
- est-elle sauvegardée avec la partie ?
- est-elle chiffrée ?
- qui peut la consulter (debug, admin) ?
- est-elle conservée après la partie ?
- comment respecter la vie privée des joueurs humains (Q-024) ?

**Contrainte proposée :** la mémoire d'une IA ne doit jamais contenir d'informations auxquelles elle n'avait pas accès au moment de l'événement.

## 11. Coût et performance

- nombre de souvenirs injectés par appel ;
- taille des résumés ;
- fréquence de mise à jour ;
- coût des embeddings éventuels ;
- latence de récupération.

**[PROPOSITION]** Un budget de mémoire par appel et une hiérarchie de résumés permettent de tenir un contexte borné.

## 12. Évaluation

Comment vérifier que la mémoire fonctionne :

- l'agent se souvient-il d'un engagement ancien ?
- distingue-t-il un allié fiable d'un traître ?
- ses résumés sont-ils fidèles ?
- oublie-t-il ce qui est utile ?
- la mémoire améliore-t-elle ses résultats ?

**[PROPOSITION]** Tests de scénarios avec événements injectés et questions de rappel.

## 13. Risques

| Risque | Description | Mitigation proposée |
|---|---|---|
| Hallucination | Souvenir inventé | Résumés ancrés, sources |
| Fuite | Mémoire contenant des secrets | Filtrage à l'écriture |
| Coût | Contexte trop long | Résumés, sélection |
| Incohérence | Mémoire contradictoire | Consolidation, horodatage |
| Biais | Souvenirs négatifs surreprésentés | Pondération |
| Vie privée | Données personnelles | Minimisation, rétention |
| Dépendance | L'agent ne décide plus sans mémoire | Fallback |

## 14. Questions ouvertes

| ID | Question |
|---|---|
| MEM-001 | Quels types de mémoire ? |
| MEM-002 | Où est-elle stockée ? |
| MEM-003 | Est-elle persistante entre parties ? |
| MEM-004 | Comment sélectionner les souvenirs ? |
| MEM-005 | Comment résumer sans déformer ? |
| MEM-006 | Y a-t-il un oubli ? |
| MEM-007 | Qui peut consulter la mémoire ? |
| MEM-008 | Comment la sauvegarder avec la partie ? |
| MEM-009 | Quel budget de contexte ? |
| MEM-010 | Comment mesurer son efficacité ? |
| MEM-011 | La mémoire est-elle propre à chaque agent ? |
| MEM-012 | Comment éviter les fuites d'information ? |

## 15. Dépendances

- [ai-architecture.md](ai-architecture.md) : pipeline et contrat.
- [decision-making.md](decision-making.md) : usage des souvenirs.
- [personalities.md](personalities.md) : continuité du style.
- [diplomacy/reputation.md](../diplomacy/reputation.md) : réputation comme mémoire agrégée.
- [architecture/data-model.md](../architecture/data-model.md) : persistance.
- [development/testing-strategy.md](../development/testing-strategy.md) : tests de rappel.

## 16. Critères de passage à « Spécifié »

- [ ] Types de mémoire validés.
- [ ] Format de stockage défini.
- [ ] Stratégie de récupération et de résumé définie.
- [ ] Politique d'oubli et de rétention définie.
- [ ] Contrôles de confidentialité définis.
- [ ] Budget de contexte défini.
- [ ] Scénarios de test définis.
- [ ] Validation du propriétaire.
