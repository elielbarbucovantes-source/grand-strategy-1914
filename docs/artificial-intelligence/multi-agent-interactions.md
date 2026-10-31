# Interactions multi-agents

> **Statut :** Cadrage — non conçu, non implémenté
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Documents liés :** [ai-architecture.md](ai-architecture.md) · [decision-making.md](decision-making.md) · [diplomacy/negotiations.md](../diplomacy/negotiations.md) · [diplomacy/alliances.md](../diplomacy/alliances.md)

---

## 1. Objet

Décrire comment plusieurs agents IA coexistent dans une même partie : protocole d'échange, ordre d'activation, coalitions, sécurité, observabilité et reproductibilité.

**Aucun protocole n'est conçu.**

## 2. Topologie proposée

```
                 ┌─────────────────────┐
                 │  Orchestrateur      │
                 │  (cycle, timers)    │
                 └──────┬──────┬───────┘
                        │      │
          ┌─────────────▼─┐  ┌─▼─────────────┐
          │  Agent IA 1   │  │  Agent IA N   │
          │  (puissance)  │  │  (puissance)  │
          └───────┬───────┘  └───────┬───────┘
                  │                  │
          ┌───────▼──────────────────▼───────┐
          │        Bus de messages           │
          │  (filtré par destinataires)      │
          └───────────────┬──────────────────┘
                          │
          ┌───────────────▼──────────────────┐
          │   Noyau de règles + journal       │
          └──────────────────────────────────┘
```

**[PROPOSITION]** Les agents ne communiquent pas directement entre eux : ils passent par un bus et un format commun, contrôlé par l'orchestrateur. Cela permet l'audit, le filtrage et l'équité.

## 3. Cycle d'interaction proposé

1. L'orchestrateur ouvre la phase.
2. Chaque agent reçoit sa perception filtrée.
3. Les agents peuvent émettre des messages (dans la limite des canaux et des quotas).
4. Les messages sont distribués à leurs destinataires.
5. Les agents peuvent répondre, dans un nombre de tours borné.
6. Chaque agent soumet ses ordres.
7. L'orchestrateur vérifie les délais et déclenche la résolution.
8. Le noyau résout et émet les événements.
9. Les agents mettent à jour leur mémoire.

**[À DÉFINIR]** Les agents jouent-ils :

- séquentiellement (un par un) ?
- en parallèle ?
- avec des tours de négociation séparés de la soumission des ordres ?

L'ordre d'activation ne doit pas donner d'avantage indu. Si les agents jouent en parallèle, il faut définir comment les messages simultanés sont ordonnés.

## 4. Protocole de messages

**[PROPOSITION]** Un format commun, indépendant du fournisseur de LLM :

- expéditeur, destinataires, canal ;
- type de message (texte, proposition, acceptation, refus, information) ;
- contenu ;
- référence à une négociation ;
- horodatage et phase ;
- identifiant unique ;
- signature / intégrité.

**[À DÉFINIR]** Faut-il un langage formel pour les propositions, ou du texte libre avec des balises ?

## 5. Coalitions et dynamique collective

**[PROPOSITION]** Les agents devraient pouvoir :

- former des coalitions ;
- coordonner des votes ou des attaques ;
- partager des informations ;
- se méfier les uns des autres ;
- trahir.

**[À DÉFINIR]** Comment éviter :

- la collusion permanente contre un joueur ;
- les coalitions absurdes ;
- le leadership automatique du plus fort ;
- l'effet « tous contre l'IA la plus avancée ».

## 6. Équité entre agents

- Tous les agents doivent avoir accès aux mêmes informations pour un même rôle.
- Aucun agent ne doit pouvoir lire la mémoire d'un autre.
- Aucun agent ne doit connaître les ordres secrets des autres.
- Les différences de qualité doivent venir de la stratégie, pas d'un accès privilégié.
- Les modèles utilisés peuvent différer, mais cela doit être documenté et, si possible, équilibré.

**[À DÉFINIR]** Un agent peut-il avoir un budget de tokens supérieur ? Est-ce équitable ?

## 7. Sécurité

| Menace | Description | Mitigation proposée |
|---|---|---|
| Prompt injection | Un message contient des instructions | Traiter comme données, délimiter, filtrer |
| Fuite de prompt | Un agent révèle ses instructions | Ne pas exposer de secrets dans le prompt |
| Collusion | Agents coordonnés hors règles | Détection, canaux contrôlés |
| Déni de service | Un agent spamme ou bloque | Quotas, timeouts |
| Usurpation | Un agent se fait passer pour un autre | Identité côté orchestrateur |
| Fuite de mémoire | Un agent lit la mémoire d'un autre | Isolation du stockage |
| Manipulation d'outils | Un message tente de déclencher un outil | Aucun outil exposé aux messages de jeu |

**Règle absolue :** un message de jeu n'est jamais une instruction pour l'agent. Il est du contenu à interpréter.

## 8. Observabilité

**[PROPOSITION]** Journaliser pour chaque agent et chaque tour :

- perception reçue (ou son hash) ;
- messages envoyés/reçus ;
- décision et rationale résumé ;
- ordres bruts et validés ;
- coût, latence, modèle utilisé ;
- erreurs et fallbacks.

Cela permet l'audit, le debug, l'évaluation et le replay — sans exposer les secrets aux autres agents.

## 9. Reproductibilité

Pour comparer des agents et déboguer :

- graine fixe ;
- configuration identique ;
- versions de modèles enregistrées ;
- température et paramètres enregistrés ;
- ordre d'activation déterministe ;
- journal complet.

**[À DÉFINIR]** Comment reproduire une partie si les modèles distants changent ou sont dépréciés ?

## 10. Défaillances

- Un agent lent : timeout, fallback, poursuite de la partie.
- Un agent qui plante : ordres par défaut ou abstention.
- Un agent qui produit des messages incohérents : filtrage, journalisation.
- Un agent qui boucle : limite d'appels.
- Un fournisseur indisponible : bascule ou fallback.

**[À DÉFINIR]** Un agent défaillant doit-il être remplacé par une IA de secours, ou la partie continue-t-elle sans lui ?

## 11. Évaluation multi-agents

- équilibre des coalitions ;
- diversité des comportements ;
- qualité des négociations ;
- fréquence des trahisons ;
- stabilité des parties ;
- coût total ;
- absence de collusion dégénérée.

**[PROPOSITION]** Organiser des tournois internes avec des configurations variées, sur des scénarios reproductibles.

## 12. Questions ouvertes

| ID | Question |
|---|---|
| MA-001 | Les agents jouent-ils en parallèle ou séquentiellement ? |
| MA-002 | Combien de tours de négociation par phase ? |
| MA-003 | Quel protocole de messages ? |
| MA-004 | Comment garantir l'équité ? |
| MA-005 | Comment détecter la collusion ? |
| MA-006 | Que faire d'un agent défaillant ? |
| MA-007 | Comment reproduire une partie ? |
| MA-008 | Quels journaux conserver ? |
| MA-009 | Les agents peuvent-ils avoir des budgets différents ? |
| MA-010 | Comment éviter « tous contre un » ? |
| MA-011 | Comment tester les interactions ? |
| MA-012 | Un agent peut-il observer les autres sans jouer ? |

## 13. Dépendances

- [ai-architecture.md](ai-architecture.md) : pipeline individuel.
- [decision-making.md](decision-making.md) : décisions.
- [diplomacy/negotiations.md](../diplomacy/negotiations.md) : canaux.
- [diplomacy/alliances.md](../diplomacy/alliances.md) : coalitions.
- [architecture/overview.md](../architecture/overview.md) : orchestration.
- [development/testing-strategy.md](../development/testing-strategy.md) : évaluation.

## 14. Critères de passage à « Spécifié »

- [ ] Topologie et cycle d'interaction validés.
- [ ] Protocole de messages spécifié.
- [ ] Règles d'équité et d'isolation définies.
- [ ] Mesures anti-injection spécifiées.
- [ ] Journalisation et replay définis.
- [ ] Gestion des défaillances définie.
- [ ] Scénarios multi-agents définis.
- [ ] Validation du propriétaire.
