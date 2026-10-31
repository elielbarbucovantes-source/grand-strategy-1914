# Architecture Decision Records (ADR)

> **Statut :** Opérationnel (document de gouvernance)
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Index :** 5 ADR (4 acceptés, dont 1 avec réserve ; 1 proposé)

---

## 1. Objet

Un ADR (Architecture Decision Record) documente une décision importante : son contexte, les options envisagées, la solution retenue, sa justification et ses conséquences.

Les ADR servent à :

- éviter de redécider sans cesse ;
- comprendre *pourquoi* une solution a été choisie ;
- distinguer une décision validée d'une simple préférence ;
- garder une trace durable, indépendante des conversations.

## 2. Règles

1. **Un ADR = une décision.**
2. **Numérotation séquentielle** à quatre chiffres : `0001`, `0002`, etc.
3. **Nom de fichier** : `NNNN-titre-court-en-kebab-case.md`.
4. **Statuts autorisés** :
   - `proposé` : en discussion, ne vaut pas décision ;
   - `accepté` : décision en vigueur ;
   - `remplacé` : une décision ultérieure le remplace (référencer le nouvel ADR) ;
   - `rejeté` : option étudiée et écartée (conserver la trace).
5. **Un ADR accepté est immuable.** On ne modifie pas son contenu ; on crée un nouvel ADR qui le remplace et on met à jour son statut.
6. **Auteur** : nom réel de l'outil ou de la personne. Le décideur est indiqué séparément si ce n'est pas l'auteur.
7. **Pas d'ADR fictif.** Ne jamais dater ou signer une décision qui n'a pas eu lieu.
8. **Toute décision structurante** (langage, moteur, base de données, architecture, sécurité, licence) nécessite un ADR.

## 3. Processus

```
Besoin identifié
   ↓
Étude des options (document ou prototype)
   ↓
ADR créé au statut « proposé »
   ↓
Revue / arbitrage du propriétaire
   ↓
« accepté » ou « rejeté »
   ↓
Mise à jour de l'index, des documents impactés et de PROGRESS.md
```

## 4. Index

| N° | Titre | Statut | Date | Auteur | Décideur |
|---|---|---|---|---|---|
| [0001](0001-documentation-et-git-comme-socle.md) | Documentation et Git comme socle de collaboration | Accepté | 2026-10-31 | OpenCode | Propriétaire (via brief) |
| [0002](0002-interoperabilite-multi-agents.md) | Interopérabilité multi-agents via un fichier de règles unique | Accepté | 2026-10-31 | OpenCode | OpenCode (délégation d'infrastructure) |
| [0003](0003-report-du-choix-de-pile-technique.md) | Report du choix de pile technique | Accepté | 2026-10-31 | OpenCode | Propriétaire (via brief) |
| [0004](0004-adoption-du-document-fondateur.md) | Adoption du document fondateur v0.1 comme source de conception | Accepté | 2026-10-31 | OpenCode | Propriétaire (document remis) |
| [0005](0005-integration-strategique-tactique.md) | Intégration du temps stratégique et du temps tactique | **Proposé** — ne vaut pas décision | 2026-10-31 | OpenCode | Arbitrage du propriétaire attendu |

## 5. Modèle

Copier [0000-template.md](0000-template.md).

## 6. Documents liés

- [AGENTS.md § 11](../../AGENTS.md#11-décisions-techniques-et-adr)
- [PROJECT.md § 20](../../PROJECT.md#20-gouvernance-décisions-et-questions-ouvertes)
- [architecture/technical-decisions.md](../architecture/technical-decisions.md)
- [Document fondateur v0.1](../founding-document-v0.1.md)
- [Revue de conception v0.1](../design-review-v0.1.md)
