# Renseignement et espionnage

> **Statut :** Cadrage aligné sur la fiche maîtresse — système non conçu, non validé, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 11 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 11
> **Documents liés :** [../diplomacy/negotiations.md](../diplomacy/negotiations.md) · [../technology/research-system.md](../technology/research-system.md) · [../military/strategic-warfare.md](../military/strategic-warfare.md) · [../ai/decision-making.md](../ai/decision-making.md) · [../design-review-v0.1.md](../design-review-v0.1.md)

---

## 1. Objet

Décrire le renseignement : collecte, interception des communications, cryptographie, espionnage industriel et rapports. Aucun modèle, coût ou seuil n'est arrêté.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Rôle | Le renseignement apporte un avantage stratégique **sans rendre les nations omniscientes**. | D-011, § 11 |
| Missions v1 | Renseignement classique : informations **militaires, économiques et technologiques**. | D-022, § 11.1 |
| Exclusions v1 | Sabotage, contre-espionnage et action politique **non retenus**. | D-022, § 11.1 |
| Confidentialité | Les communications diplomatiques sont confidentielles par défaut. | D-008, § 6.2 |
| Interception | Une nation peut tenter d'intercepter les communications d'une autre. | § 11.2 |
| Compétences | La capacité à lire dépend des compétences et des investissements technologiques (Morse, décryptage). | § 11.2 |
| Cryptographie | Le décryptage exige des investissements importants. | § 11.3 |
| Espionnage industriel | Un investissement financier important et une recherche adaptée peuvent obtenir des secrets industriels ou technologiques. | § 11.4 |
| Fiabilité | Une interception réussie fournit des informations **exactes**. Pas de faux messages interceptés. | D-023, § 11.5 |
| Rapports | Système hybride : accès immédiat aux interceptions réussies + rapports périodiques. | § 11.6 |

**Conséquence :** les hypothèses antérieures de ce document (contre-espionnage v1, désinformation par faux messages, renseignement omniscient) sont **historiques** et ne font plus autorité.

## 3. Renseignement classique

**[À DÉFINIR — T-025]** Comment obtenir des informations sans interception :

- observation militaire (positions, effectifs, mouvements) ;
- renseignement économique (production, stocks, budget) ;
- renseignement technologique (recherches en cours, percées) ;
- renseignement diplomatique (relations, accords, intentions).

**[PROPOSITION — non validée]** Une collecte par **missions** orientées (militaire, économique, technologique), avec un coût, une durée et un risque. Les résultats arrivent sous forme de rapports, pas de vérité brute.

## 4. Interception des communications

**[VALIDÉ]** Les communications sont confidentielles par défaut ; une interception réussie donne des informations exactes (D-008, D-023).

**[À DÉFINIR — C-05, C-11]** Le modèle opérationnel :

- qui peut tenter d'intercepter qui ?
- à quelle fréquence ?
- quels messages (publics, privés, groupes, officiels, secrets) ?
- le message complet ou un fragment ?
- la détection de l'interception existe-t-elle ?
- les messages interceptés peuvent-ils être réutilisés, cités ou publiés ?
- l'interception est-elle visible dans le replay ?
- les joueurs humains consentent-ils à ce que leurs messages soient lisibles ?

**[ATTENTION — C-05]** Une interception exacte peut vider la diplomatie de son incertitude, créer un déséquilibre et poser des questions de vie privée. Le document fondateur tranche l'**exactitude**, pas la **portée**, le **coût** ni la **détection**. Ces éléments doivent être arbitrés.

**[PROPOSITION — non validée]** Conserver l'exactitude, mais ajouter un coût, une portée et une détection. Ne pas ajouter de faux messages sans validation. Documenter une politique de confidentialité (Q-024).

## 5. Cryptographie et compétences

**[VALIDÉ]** Le décryptage dépend de compétences et d'investissements technologiques (D-021, D-022).

**[À DÉFINIR]** Niveaux de compétence, branches de recherche, progrès par nation, course aux armements cryptographiques, effet de la capture de codebooks ou de machines.

**[PROPOSITION — non validée]** Une valeur de **compétence cryptographique** par nation, mise à jour par la recherche et l'espionnage, comparée à la valeur de protection de la cible. Le résultat est binaire (lu / non lu) ou gradué (extrait / complet). À trancher.

## 6. Espionnage industriel et technologique

**[VALIDÉ]** Un investissement important et une recherche adaptée peuvent obtenir des secrets industriels ou technologiques (D-022, § 11.4).

**[À DÉFINIR]** Ce qu'on obtient exactement : une technologie complète, un bonus de recherche, un plan de production, un aperçu de l'arbre adverse ? Comment éviter le vol en boucle et la perte de valeur de la recherche ?

## 7. Rapports

**[VALIDÉ]** Système hybride : accès immédiat aux interceptions réussies, rapports périodiques sur les informations recueillies (§ 11.6).

**[À DÉFINIR]** Fréquence, format, niveau de confiance affiché, faux positifs éventuels (attention : D-023 interdit les faux **messages**, pas nécessairement les erreurs d'analyse — à trancher), conservation et suppression.

**[PROPOSITION — non validée]** Un rapport mensuel par nation, avec les informations datées et leur source. Aucune information ne doit être présentée comme certaine si elle ne l'est pas.

## 8. Information des IA et équité

**[VALIDÉ]** Les IA ne sont pas omniscientes (D-011). L'asymétrie d'information doit être identique pour les humains et les IA.

**[À DÉFINIR — Q-012]** Comment garantir qu'une IA ne triche pas informationnellement : filtrage des perceptions, journal d'accès, tests.

**[PROPOSITION — non validée]** Une **frontière informationnelle** unique, traversée par un filtre de perception identique pour tous les acteurs. Aucune IA ne doit recevoir l'état complet du jeu.

## 9. Confidentialité des joueurs

**[À DÉFINIR — Q-024, C-05]** Les messages des joueurs humains peuvent-ils être interceptés ? Dans quelles conditions ? Quelles données sont conservées, pendant combien de temps, et avec quel consentement ?

**[VALIDÉ — règle de sécurité]** Un message de jeu est une **donnée non fiable** ; il ne doit jamais être exécuté comme une instruction système par une IA ([AGENTS.md](../../AGENTS.md) § 9).

## 10. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-05 | Interception exacte vs confidentialité et équité. | Non tranchée ; T-025 / T-029. |
| C-11 | Portée, coût et détection de l'interception. | Non tranchée ; T-025. |
| C-12 | Recherche et technologies sensibles. | Non tranchée ; T-025. |
| V-06 | Données de joueurs et RGPD. | À traiter ; Q-024. |

## 11. Questions ouvertes

| ID | Question |
|---|---|
| I-001 | Quelles missions de renseignement en v1 ? |
| I-002 | Qui peut intercepter qui, et à quel coût ? |
| I-003 | Le message est-il complet ou fragmenté ? |
| I-004 | L'interception est-elle détectable ? |
| I-005 | Quelles compétences cryptographiques ? |
| I-006 | Que produit exactement l'espionnage industriel ? |
| I-007 | Quelle fréquence et quel format de rapports ? |
| I-008 | Comment garantir l'étanchéité informationnelle ? |
| I-009 | Quelle politique de confidentialité des messages ? |

## 12. Critères de passage à « Spécifié »

- [ ] Missions et coûts définis.
- [ ] Portée et fréquence de l'interception tranchées.
- [ ] Détection et contre-mesures tranchées.
- [ ] Compétences cryptographiques définies.
- [ ] Espionnage industriel défini.
- [ ] Rapports définis.
- [ ] Politique de confidentialité validée.
- [ ] Frontière informationnelle spécifiée.
- [ ] Validation du propriétaire.
