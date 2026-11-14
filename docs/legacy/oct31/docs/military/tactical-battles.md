# Batailles tactiques

> **Statut :** Cadrage aligné sur la fiche maîtresse — règles détaillées non conçues, non validées, non implémentées
> **Dernière mise à jour :** 2026-10-31
> **Dernière modification par :** OpenCode
> **Source de conception :** [PROJECT.md](../../PROJECT.md) § 8.3 à § 8.7 · [founding-document-v0.1.md](../founding-document-v0.1.md) § 8
> **Documents liés :** [strategic-warfare.md](strategic-warfare.md) · [../gameplay/rules.md](../gameplay/rules.md) · [../gameplay/map-system.md](../gameplay/map-system.md) · [../architecture/overview.md](../architecture/overview.md) · [../decisions/0005-integration-strategique-tactique.md](../decisions/0005-integration-strategique-tactique.md) · [../design-review-v0.1.md](../design-review-v0.1.md)

---

## 1. Objet

Décrire les **batailles tactiques indépendantes** qui résolvent une offensive stratégique.

Ce document ne choisit ni moteur, ni technologie, ni format de terrain. Il fixe le cadre validé et liste ce qui reste à définir.

## 2. Cadre validé par le propriétaire

| Élément | Décision | Référence |
|---|---|---|
| Inspiration | Philosophie de **Lines of Battle**. | D-014, § 8.3 |
| Déclenchement | Une offensive qui rencontre des armées sur la carte stratégique. | D-013, § 8.2 |
| Terrain | Terrain **distinct** de la carte stratégique. | § 8.3 |
| Contrôle | Le joueur contrôle **directement** ses unités. | § 8.3, D-016 |
| Durée | **30 minutes maximum**. | D-014, § 8.3 |
| Effectifs | Proportionnels aux forces engagées sur la carte. | D-014, § 8.3 |
| Commandement | Unités sélectionnables individuellement ou en groupes. | § 8.3 |
| Ordres | Préparation simultanée puis résolution des ordres. | § 8.3 |
| Terrain | Influence directe ; cohérent avec la province stratégique. | § 8.4 |
| Issue | Vainqueur = occupation automatique ; pertes définitives. | D-015, § 8.5 |
| Exclus | Moral, généraux, chaîne de commandement intermédiaire. | D-016, § 8.6 |
| Fortifications | Apparaissent dans la bataille et modifient les conditions. | D-017, § 8.7 |

## 3. Conversion des forces

**[VALIDÉ]** Les effectifs tactiques doivent être proportionnels aux forces stratégiques engagées (D-014).

**[À DÉFINIR — C-03, T-024]** Le modèle exact :

- quelle unité de conversion (homme, point de force, figurine) ?
- quels coefficients par type d'unité ?
- comment les équipements comptent-ils ?
- comment les pertes tactiques se reconvertissent-elles en pertes stratégiques ?
- une unité stratégique détruite à 100 % disparaît-elle de la carte ?
- que deviennent les blessés, les captifs et le matériel capturé ?
- comment arrondir sans créer d'effet disproportionné ?

**[PROPOSITION — non validée]** Une **table de conversion unique**, publiée, réversible et testée par simulation. Exemple de structure (valeurs purement illustratives, **non validées**) :

| Unité stratégique | Point de force proposé | Remarque |
|---|---|---|
| Régiment d'infanterie | 1 | Référence de base. |
| Division d'infanterie | 4 | Valeur illustrative. |
| Division blindée | 6 | Dépend de l'équipement. |
| Division aéroportée | 5 | Valeur illustrative. |

Ces chiffres ne doivent pas être implémentés avant validation. Ils montrent seulement la forme attendue de la table.

## 4. Déroulement d'une bataille

**[PROPOSITION — non validée]** Séquence minimale :

1. **Chargement** : le moteur construit le terrain, les unités, les fortifications et les conditions à partir de l'état stratégique.
2. **Briefing** : chaque camp voit ses forces et l'information autorisée sur l'adversaire.
3. **Préparation simultanée** : les deux camps donnent leurs ordres pour le round.
4. **Résolution** : le moteur résout les ordres simultanément.
5. **Mise à jour** : positions, pertes, état du terrain, objectifs.
6. **Répétition** jusqu'à la fin (objectif atteint, temps écoulé, capitulation, retraite).
7. **Clôture** : résultat, pertes, occupation, retour à la carte stratégique.

**[À DÉFINIR — C-01, C-15, C-17]** Le moment d'ouverture, la synchronisation avec le calendrier mensuel, le timeout, la pause et le replay.

## 5. Contrôle et commandement

**[VALIDÉ]** Le joueur commande directement ses unités, sans généraux ni chaîne de commandement intermédiaire (D-016).

**[À DÉFINIR]** Comment un joueur contrôle plusieurs groupes simultanément ; comment les ordres sont donnés (sélection, formation, trajectoire) ; quel degré d'automatisation est autorisé sans créer de « général ».

## 6. Terrain et fortifications

**[VALIDÉ]** Le terrain influence les combats et doit correspondre à la province stratégique (D-017, § 8.4).

**[VALIDÉ]** Les fortifications apparaissent dans la bataille et modifient les conditions (D-017).

**[À DÉFINIR — T-024]** Types de terrain, avantages/désavantages par type d'unité, cartes tactiques, fortifications et niveaux, destruction du terrain.

## 7. Effectifs, équipements et pertes

**[VALIDÉ]** Les effectifs et équipements mobilisés comptent (D-012) ; les pertes sont définitives (D-015).

**[À DÉFINIR — C-03, C-10]** Conversion des pertes, état matériel des survivants, remplacement, récupération du matériel, influence de la technologie et de l'industrie.

**[À DÉFINIR]** La bataille peut-elle être perdue sans perdre toutes ses unités ? Peut-on retraiter ? Le vainqueur capture-t-il du matériel ?

## 8. Batailles multiples et disponibilité du joueur

**[À DÉFINIR — C-02, T-029]** Une offensive peut rencontrer des armées sur plusieurs provinces dans le même mois. Le document fondateur ne limite pas le nombre de batailles simultanées, alors qu'un joueur humain ne peut pas commander deux batailles temps réel en parallèle.

Options non validées :

- une seule bataille active par joueur, les autres en file d'attente ;
- résolution automatique des batailles non supervisées ;
- limitation du nombre d'offensives par mois ;
- délégation à une résolution déterministe.

**Interdit sans validation :** créer des généraux ou une IA tactique qui **commande** à la place du joueur (contredirait D-016). Une IA de **résolution** n'est pas un personnage et doit être présentée comme un outil.

Voir [ADR-0005](../decisions/0005-integration-strategique-tactique.md), état `proposé`.

## 9. Joueur absent, IA et parties observées

**[VALIDÉ]** Le joueur peut observer une partie entièrement contrôlée par les IA et prendre le contrôle d'une nation en cours de partie (§ 15.4).

**[À DÉFINIR]** Une bataille IA contre IA est-elle simulée, résolue automatiquement ou seulement résumée ? Que voit le joueur qui observe ? Que se passe-t-il si un joueur se déconnecte pendant une bataille ?

## 10. Sauvegarde, pause et replay

**[À DÉFINIR — C-15, T-028]** Une bataille temps réel est difficile à sauvegarder et à rejouer de façon déterministe.

Options non validées :

- enregistrer les commandes horodatées et rejouer ;
- considérer la bataille comme non rejouable mais conserver son résultat ;
- moteur à pas fixes déterministe ;
- pause autorisée ou non.

Toute option retenue doit rester compatible avec la sauvegarde de partie et l'anticipation du multijoueur (D-026).

## 11. Multijoueur anticipé

**[VALIDÉ]** Le multijoueur humain n'est pas indispensable en v1, mais l'architecture doit l'anticiper (D-026).

**[À DÉFINIR — C-17]** Synchronisation, timers communs, déconnexions, pause, modération, spectateurs.

**[PROPOSITION — non validée]** Isoler le **moteur de bataille** du **calendrier stratégique**, avec un contrat de session explicite. Voir [architecture/overview.md](../architecture/overview.md) § 4.

## 12. Tensions applicables

| ID | Tension | Traitement |
|---|---|---|
| C-01 | Calendrier mensuel vs 30 minutes temps réel. | Non tranchée ; ADR-0005. |
| C-02 | Batailles simultanées et un seul joueur. | Non tranchée. |
| C-03 | Conversion des forces. | Non tranchée ; T-024. |
| C-10 | État des unités sans moral. | Non tranchée. |
| C-15 | Sauvegarde, pause, replay. | Non tranchée ; T-028. |
| C-17 | Multijoueur et temps réel. | Non tranchée ; T-028. |

## 13. Questions ouvertes

| ID | Question |
|---|---|
| B-001 | Quelle unité et quelle table de conversion ? |
| B-002 | Quelle durée effective et quel timeout ? |
| B-003 | Comment ouvrir et fermer une bataille dans le tour ? |
| B-004 | Comment gérer plusieurs batailles simultanées ? |
| B-005 | Quel contrôle exact des unités ? |
| B-006 | Quels terrains et quels effets ? |
| B-007 | Quelles pertes et quel état des survivants ? |
| B-008 | Une bataille peut-elle être mise en pause ou rejouée ? |
| B-009 | Que se passe-t-il en IA vs IA et en cas d'absence ? |
| B-010 | Comment préparer le multijoueur sans le livrer ? |

## 14. Critères de passage à « Spécifié »

- [ ] Table de conversion validée et testée.
- [ ] Déroulement et timeout définis.
- [ ] Contrôle des unités spécifié.
- [ ] Terrains, fortifications et effets définis.
- [ ] Pertes et état des survivants définis.
- [ ] Batailles multiples arbitrées.
- [ ] Sauvegarde et replay définis.
- [ ] Contrat de session compatible multijoueur.
- [ ] Validation du propriétaire.
