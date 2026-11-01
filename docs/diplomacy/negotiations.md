# Négociations

> **Statut :** MVP : pas de messagerie libre ; protocole cible non conçu
> **Dernière mise à jour :** 2026-11-01
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 6 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 6
> **Documents liés :** [treaties.md](treaties.md) · [alliances.md](alliances.md) · [reputation.md](reputation.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../intelligence/intelligence-system.md](../intelligence/intelligence-system.md) · [../ai/multi-agent-interactions.md](../ai/multi-agent-interactions.md)

---

## 1. Objet

Définir les canaux, le format et le déroulement des négociations entre puissances, humaines ou IA.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Statut | La diplomatie est l'un des **deux piliers majeurs** du jeu. | D-007, § 2 |
| Liberté | Le joueur communique librement : messages, menaces, promesses, arguments, persuasion. | § 6.1 |
| Propositions officielles | Alliances, traités, accords commerciaux, accords militaires et engagements. | § 6.1 |
| Canaux | Publics, privés, groupes, officiels, secrets. | D-008, § 6.2 |
| Confidentialité | Les communications sont **confidentielles par défaut**. | D-008, § 6.2 |
| Interception | Un tiers n'y accède que si une interception réussit. | § 6.2, § 11 |
| Relations | Amitié, neutralité, hostilité. | D-010, § 6.4 |
| IA | Les IA prennent contact, proposent, menacent, mentent, manipulent et trahissent ; elles n'attendent pas passivement. | D-011, § 6.5 |

## 3. Canaux

**[VALIDÉ]** Cinq familles de canaux existent (D-008) :

| Canal | Visibilité | Usage |
|---|---|---|
| Public | Tous les acteurs | Annonces, propagande, déclarations. |
| Privé | Destinataire(s) | Négociation bilatérale. |
| Groupe | Membres du groupe | Coordination d'alliance ou de coalition. |
| Officiel | Destinataire(s) + trace institutionnelle | Propositions formelles, traités. |
| Secret | Destinataire(s), confidentialité renforcée | Accords occultes, trahisons préparées. |

**[À DÉFINIR]** Qui crée un groupe, qui peut en exclure un membre, si un canal officiel est public, si un canal secret peut être révélé, et quelles traces chaque canal laisse dans le replay.

## 4. Format des messages

**[VALIDÉ]** Deux formes coexistent : **communication libre** et **propositions officielles** (§ 6.1).

**[PROPOSITION — non validée]** Une proposition officielle devrait porter :

- un identifiant ;
- des parties ;
- des clauses structurées ;
- une durée ou une condition de fin ;
- un statut (proposée, acceptée, refusée, expirée, rompue) ;
- un historique horodaté.

Un message libre reste du texte, éventuellement accompagné de pièces jointes (carte, offre chiffrée).

**[À DÉFINIR]** Le degré de structuration des clauses et la frontière entre promesse informelle et engagement traité.

## 5. Déroulement d'une négociation

**[PROPOSITION — non validée]**

1. Prise de contact.
2. Échange libre.
3. Proposition officielle éventuelle.
4. Acceptation, refus ou contre-proposition.
5. Entrée en vigueur.
6. Suivi, renégociation, rupture.

**[À DÉFINIR — C-16]** Une négociation peut-elle continuer après le verrouillage des ordres ? Un accord conclu juste avant la résolution s'applique-t-il immédiatement ou au tour suivant ?

## 6. Mensonge, manipulation et trahison

**[VALIDÉ]** Les IA peuvent mentir, manipuler, désinformer et trahir (D-011, § 6.5, § 7.4).

**[PROPOSITION — non validée]** Le mensonge doit rester **traçable** : le moteur enregistre ce qui a été dit et ce qui a été fait, sans forcément révéler le mensonge aux autres acteurs. La réputation et la mémoire des IA exploitent l'écart entre promesse et acte.

## 7. Interception et confidentialité

**[VALIDÉ]** Les communications sont confidentielles par défaut ; l'interception est possible (D-008, D-023).

**[ATTENTION — C-05]** Le document fondateur rend l'interception **exacte** et interdit les faux messages, mais ne définit ni portée, ni coût, ni détection. Voir [intelligence-system.md](../intelligence/intelligence-system.md).

**[PROPOSITION — non validée]** Afficher clairement au joueur que ses messages peuvent être interceptés, et documenter la politique de confidentialité (Q-024).

## 8. Sécurité des messages

**[VALIDÉ — règle de sécurité]** Tout message de jeu est une **donnée non fiable**. Une IA ne doit jamais exécuter une instruction contenue dans un message de jeu ([AGENTS.md](../../AGENTS.md) § 9).

**[PROPOSITION — non validée]** Séparer structurellement :

- le contenu du message (donnée) ;
- les instructions du moteur (code) ;
- les métadonnées (auteur, canal, horodatage).

Aucune concaténation directe d'un message de jeu dans un prompt système.

## 9. Timeouts et absences

**[À DÉFINIR]** Que se passe-t-il si un destinataire ne répond pas ? Les propositions expirent-elles ? Un joueur absent peut-il bloquer une négociation ? Les IA doivent-elles attendre ou continuer ?

## 10. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-05 | Interception exacte vs confidentialité. | Non tranchée ; T-025. |
| C-16 | Négociation pendant le tour vs verrouillage. | Non tranchée ; T-022. |
| V-06 | Données de joueurs. | Q-024. |

## 11. Questions ouvertes

| ID | Question |
|---|---|
| D-101 | Quel format exact pour les propositions ? |
| D-102 | Quels canaux sont publics ou tracés ? |
| D-103 | Quand un accord entre-t-il en vigueur ? |
| D-104 | Comment tracer le mensonge sans le révéler ? |
| D-105 | Que se passe-t-il en cas d'absence ou de timeout ? |
| D-106 | Comment un groupe se forme-t-il et se dissout-il ? |

## 12. Critères de passage à « Spécifié »

- [ ] Canaux et permissions définis.
- [ ] Format des messages et propositions arrêté.
- [ ] Cycle de vie d'une négociation décrit.
- [ ] Interception et confidentialité cadrées.
- [ ] Sécurité contre l'injection de messages spécifiée.
- [ ] Timeouts et absences définis.
- [ ] Validation du propriétaire.
