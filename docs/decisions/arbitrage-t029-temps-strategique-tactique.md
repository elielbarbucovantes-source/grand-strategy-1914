# Dossier d'arbitrage T-029 — Temps stratégique et temps tactique

> **Statut :** Document de travail — **ne vaut pas décision**
> **Date :** 2026-11-01
> **Auteur :** OpenCode
> **Décideur :** Propriétaire du projet
> **Portée :** tensions C-01, C-02, C-04, C-15 et C-17
> **Documents liés :** [ADR-0005](0005-integration-strategique-tactique.md) (proposé) · [design-review-v0.1.md](../design-review-v0.1.md) · [gameplay/rules.md](../gameplay/rules.md) · [military/tactical-battles.md](../military/tactical-battles.md) · [military/strategic-warfare.md](../military/strategic-warfare.md) · [architecture/overview.md](../architecture/overview.md) · [PROJECT.md](../../PROJECT.md) · [PROGRESS.md](../../PROGRESS.md)

---

## 1. Objet et mode d'emploi

Ce dossier rassemble ce qu'il faut pour **trancher** l'articulation entre le tour mensuel (stratégique) et les batailles de 30 minutes (tactiques). Il ne tranche rien.

**Comment répondre** — au choix :

1. remplir la **fiche de décision** du § 8 (cinq lignes D1 à D5) ;
2. répondre en texte : « D1 = A, D2 = E, D3 = I, D4 = 1+3, D5 = 1 » ;
3. accepter ou rejeter le **scénario recommandé S1** du § 5 en bloc.

Une réponse partielle est acceptée : les cinq décisions sont indépendantes, mais certaines combinaisons sont incohérentes (§ 5.2).

**Ce que ce dossier n'est pas :** une décision, un choix de moteur, une spécification chiffrée. Les valeurs (timeout exact, nombre d'offensives, budget) restent à fixer dans les tâches T-024 et T-026 après l'arbitrage.

---

## 2. Ce qui est déjà tranché et ne peut pas être contredit

| Élément | Décision validée | Référence |
|---|---|---|
| Unité de temps stratégique | Un tour = un mois ; les ordres sont préparés puis résolus simultanément pour le monde entier. | D-006, § 5 |
| Bataille tactique | Indépendante, inspirée de Lines of Battle, **30 minutes maximum**, contrôle direct des unités, effectifs proportionnels. | D-014, § 8.3 |
| Issue | Le vainqueur occupe la province ; pertes définitives ; les survivants conservent leur état. | D-015, § 8.5 |
| Commandement | Pas de moral, pas de généraux, pas de chaîne intermédiaire. | D-016, § 8.6 |
| Multijoueur | Non indispensable en v1, mais l'architecture doit l'anticiper. | D-026, § 16 |
| Persistance | Un modèle de sauvegarde et de rejeu reste **à définir** (Q-009). | PROJECT.md § 20 |

**Conséquence :** toute option ci-dessous doit rester compatible avec ces lignes. Une option qui les contredit doit être présentée comme un **changement de décision**, pas comme une simple modalité.

---

## 3. Les cinq décisions à prendre

### D1 — C-01 : quand la bataille se déroule-t-elle dans le tour ?

**Question.** Les 30 minutes ont-elles lieu avant, pendant ou après la résolution mensuelle ? Le monde stratégique est-il figé pendant la bataille ? Le résultat s'applique-t-il au mois en cours ?

**Ce que dit le document.** Le § 5 impose un tour mensuel à résolution simultanée. Le § 8.3 impose une bataille indépendante de 30 minutes. Le lien entre les deux n'est pas écrit.

| Option | Description | Effets sur l'expérience | Coût / risque | Verdict d'agent |
|---|---|---|---|---|
| **A** — Bataille « hors calendrier » | Les ordres stratégiques sont verrouillés, puis les batailles s'ouvrent ; le calendrier est suspendu pour les participants ; le résultat s'applique au tour en cours. | Sépare nettement les deux échelles ; le tour reste l'unité de résolution. | Blocage si un joueur est absent ; il faut un timeout et un mode automatique. | Compatible ; nécessite D2 et D4. |
| **A′** — Variante de A | Seuls les belligérants sont figés ; les autres nations peuvent négocier et observer, mais la résolution attend la fin des batailles. | Moins d'attente pour les non-belligérants. | Gestion d'états « bataille en cours » plus complexe. | Préférable à A si le multijoueur est visé. |
| **B** — Bataille asynchrone par rounds | La bataille est découpée en rounds ; « 30 minutes » devient un budget de temps de décision cumulé. | Compatible avec le jeu asynchrone et les sauvegardes. | Perd le temps réel ; change la philosophie Lines of Battle. | Possible, mais s'écarte du § 8.3. |
| **C** — Bataille temps réel planifiée | La bataille a lieu à un créneau fixé ; le tour ne se résout pas avant. | Forte tension dramatique ; synchronisation claire. | Contrainte d'horaire ; mauvais pour le solo et l'asynchrone. | Peu adapté à la cible solo. |
| **D** — Résolution automatique optionnelle | Le joueur peut déléguer la bataille à une résolution déterministe ; le temps réel reste une option. | Évite les blocages ; respecte les absences. | Nécessite un modèle de résolution et une IA tactique ; risque d'iniquité perçue. | Complément utile à A ou B, pas une option seule. |

**Recommandation (non validée) :** **A + D**. Les ordres stratégiques sont verrouillés d'abord ; les batailles s'ouvrent ensuite dans l'ordre de priorité ; un timeout bascule la bataille en résolution automatique ; le résultat s'impute au mois courant. Si le multijoueur devient prioritaire, préférer **A′**.

**Ce que cela débloque :** la séquence du tour (T-026), les règles d'ouverture et de timeout (T-024), le contrat de session du moteur de bataille (T-028).

**Si vous choisissez B ou C :** la bataille n'est plus « 30 minutes temps réel » au sens du § 8.3. Il faudra modifier D-014 par une nouvelle décision explicite, pas par une note de conception.

---

### D2 — C-02 : que se passe-t-il si plusieurs batailles sont ouvertes en même temps ?

**Question.** Une offensive peut rencontrer des armées sur plusieurs provinces le même mois. Un joueur humain ne peut pas commander deux batailles temps réel de 30 minutes en parallèle. Comment limiter ou déléguer ?

**Ce que dit le document.** Il ne limite pas le nombre de batailles simultanées et interdit les généraux (D-016). Le contrôle direct exigé au § 8.3 rend la parallélisation humaine impossible au-delà d'une bataille.

| Option | Description | Effets | Coût / risque | Verdict d'agent |
|---|---|---|---|---|
| **E** — Une bataille active par joueur + file d'attente | Les autres batailles attendent leur tour ; ordre de priorité défini par les ordres stratégiques. | Protège l'attention ; préserve le contrôle direct. | Retarde la résolution ; une bataille peut expirer en attente. | Nécessaire si plusieurs batailles sont possibles. |
| **F** — Résolution automatique des batailles secondaires | Le joueur ne supervise qu'une bataille ; les autres sont résolues par le modèle déterministe. | Rapide ; pas de blocage. | Iniquité perçue ; le joueur perd le contrôle de fait. | À combiner avec E, pas à la place. |
| **G** — IA tactique de subordination | Une IA commande les unités non supervisées. | Préserve un adversaire actif. | Contredit D-016 si l'IA devient un « général » ; coût LLM. | Écarter, sauf outil de résolution, pas personnage. |
| **H** — Limiter les offensives par mois | Une seule offensive par nation et par mois. | Simple. | Réduit fortement la liberté stratégique ; non prévu par le document. | Écarte une mécanique validée sans raison. |

**Recommandation (non validée) :** **E + F**. Une seule bataille active par joueur humain ; les batailles non supervisées sont résolues automatiquement par le même modèle déterministe, avec la même graine et la même version de règles. Aucune IA-personnage, aucun général.

**Point d'attention.** Si les deux camps sont des IA, la bataille doit être résolue automatiquement, pas simulée pendant 30 minutes : personne ne la regarde et le coût serait injustifié.

**Ce que cela débloque :** la charge de l'interface (T-027), le contrat de bataille (T-028), les règles d'offensive (T-024).

---

### D3 — C-04 : que signifie « immédiatement tenter une nouvelle offensive » ?

**Question.** Le § 8.5 autorise une nouvelle offensive après un échec. « Immédiatement » peut signifier dans la même bataille, dans le même mois, au tour suivant ou sans limite.

**Ce que dit le document.** « Après une offensive échouée, le joueur peut immédiatement tenter une nouvelle offensive. Cependant, les pertes et l'état des unités rendent les tentatives successives plus difficiles. » (§ 8.5)

| Option | Description | Fidélité au texte | Effets | Coût / risque | Verdict d'agent |
|---|---|---|---|---|---|
| **I** — Relance dans le mois, bornée | Relance possible dans le même mois, mais limitée par un budget d'actions par province et par les pertes subies. | **Élevée** : « immédiatement » est conservé. | Permet l'acharnement voulu par le document, sans boucle infinie. | Budget à équilibrer. | **Recommandé** ; à chiffrer en T-024. |
| **J** — Une offensive par province et par mois | La relance attend le tour suivant. | Faible : contredit « immédiatement ». | Simple, prévisible. | Modifie une décision validée sans validation. | Possible seulement par décision explicite. |
| **K** — Relance dans la même bataille | La bataille continue avec les survivants. | Moyenne. | Tension maximale, mais mélange bataille et tour. | Risque de bataille sans fin ; complique le timeout. | À éviter. |
| **L** — Sans limite | Aucun plafond. | Littérale. | Boucle potentielle d'offensives. | Déséquilibre, exploitation. | À éviter. |

**Recommandation (non validée) :** **I**. Conserver « immédiatement » au sens du mois courant, avec un budget d'offensives par province et par mois, et des pertes cumulées qui rendent chaque tentative plus coûteuse. Le chiffre exact (une, deux, trois relances) relève de T-024, pas de ce dossier.

**Transparence.** La revue de conception proposait « une offensive par province et par mois » (option J). Cette proposition **s'écarte du texte** ; je ne la recommande pas, car elle transformerait une décision validée en règle nouvelle sans validation.

**Ce que cela débloque :** les règles d'offensive et de pertes (T-024), la boucle de tour (T-026).

---

### D4 — C-15 : jusqu'où sauvegarder, mettre en pause et rejouer une bataille ?

**Question.** Une bataille temps réel est difficile à sauvegarder, à mettre en pause et à rejouer de façon déterministe. Quel niveau de garantie veut-on ?

**Ce que dit le document.** Le document fondateur n'aborde pas la sauvegarde ni le rejeu. La revue de conception (C-15) rappelle que le projet exige la sauvegarde/reprise des parties et la rejouabilité ; le modèle reste ouvert (Q-009). Le § 8.3 impose le temps réel. Rien n'est écrit sur la pause ni sur le rejeu d'une bataille.

| Option | Description | Garantie | Coût / risque | Verdict d'agent |
|---|---|---|---|---|
| **1** — Journal de commandes horodatées | Enregistrer les commandes et la graine ; rejouer la bataille de façon déterministe. | Rejeu fidèle, audit, test. | Stockage et versionnage des règles. | **Recommandé.** |
| **2** — Résultat seul conservé | Seul le résultat final est sauvegardé ; la bataille n'est pas rejouable. | Sauvegarde simple. | Perte de l'audit et du débogage. | Insuffisant si le rejeu est requis. |
| **3** — Moteur à pas fixes déterministe | Le moteur avance par pas fixes, indépendamment du rendu. | Déterminisme fort ; rejeu exact. | Architecture plus rigide ; temps réel simulé. | Complément de 1, à privilégier. |
| **4** — Pause autorisée | Le joueur peut mettre la bataille en pause. | Confort solo. | Inéquitable en multijoueur ; fausse le temps réel. | Solo uniquement, jamais en multijoueur. |

**Recommandation (non validée) :** **1 + 3**, avec **pause autorisée en solo uniquement**. La sauvegarde en cours de bataille n'est pas garantie : on sauvegarde au niveau stratégique et on rejoue la bataille depuis son journal. Une sauvegarde à la fin de chaque round est une option ultérieure, à trancher avec T-028.

**Ce que cela débloque :** le modèle de persistance (T-028, Q-009), le déterminisme des tests (stratégie de test), la rejouabilité demandée par le projet.

---

### D5 — C-17 : combien anticiper le multijoueur dès maintenant ?

**Question.** D-026 impose d'anticiper le multijoueur sans l'exiger en v1. Faut-il investir dès la conception dans un contrat de session de bataille, ou repousser ?

| Option | Description | Effet sur la v1 | Effet sur le multijoueur futur | Coût | Verdict d'agent |
|---|---|---|---|---|---|
| **1** — Moteur de bataille isolé + contrat de session | Séparer le moteur du calendrier ; définir timers, déconnexions, spectateurs, reprise. | Aucun surcoût fonctionnel immédiat. | Ajout progressif, sans réécriture. | Moyen, conception seulement. | **Recommandé** (conforme à D-026). |
| **2** — Multijoueur complet en v1 | Synchronisation, salons, modération dès la première version. | Retarde la v1. | Immédiat. | Élevé. | Contraire à D-026 (« non indispensable »). |
| **3** — Aucune anticipation | Architecture solo pure. | Plus simple à court terme. | Réécriture coûteuse. | Faible maintenant, élevé plus tard. | Contraire à D-026. |

**Recommandation (non validée) :** **1**. Définir dès la conception un **contrat de session de bataille** (qui participe, qui attend, qui peut observer, comment on reprend après déconnexion), sans implémenter de multijoueur. Le contrat reste indépendant de la pile technique, qui n'est pas choisie (ADR-0003).

**Ce que cela débloque :** l'architecture (T-028), l'interface des batailles (T-027), les tests de session (stratégie de test).

---

## 4. Contraintes transverses

### 4.1 Issues de décisions validées (non négociables)

| ID | Contrainte | Origine |
|---|---|---|
| X-1 | **Aucun général, aucun moral.** Une IA de résolution ne doit jamais devenir un personnage ni une chaîne de commandement. | D-016 |
| X-2 | **Pertes définitives et état des survivants conservé** entre les batailles. | D-015 |
| X-3 | **Le résultat tactique alimente toujours l'état stratégique** (province, pertes, matériel), même en résolution automatique. | D-015 |
| X-6 | **Aucune bataille ne modifie des ordres stratégiques déjà verrouillés et résolus.** | D-006, § 5.2 |

### 4.2 Exigences proposées (à accepter avec l'arbitrage ou à renvoyer)

Ces exigences ne sont **pas** des décisions validées. Elles conditionnent pourtant la faisabilité des options ci-dessus. Les accepter fait partie de l'arbitrage ; les refuser déplace le problème vers T-026 ou T-028.

| ID | Exigence | Pourquoi | Origine | Statut |
|---|---|---|---|---|
| X-4 | **Déterminisme** : même graine, mêmes commandes et même version de règles ⇒ même résultat. | Sans lui, le rejeu et l'audit sont impossibles. | Q-009 (ouverte), V-05 | **[PROPOSITION]** |
| X-5 | **Pas de fuite d'information** : le résultat d'une bataille n'est visible que selon les règles de visibilité. | Évite de donner à un camp une information que le renseignement ne fournit pas. | C-06 (non tranchée), D-022 | **[PROPOSITION]** |
| X-7 | **Un joueur absent ne doit pas bloquer indéfiniment** la résolution. | Équité entre joueurs présents et absents. | V-07 | **[PROPOSITION]** |

---

## 5. Combinaisons et scénarios

### 5.1 Matrice de compatibilité

| Combinaison | Compatible ? | Remarque |
|---|---|---|
| A + E + D | Oui | Scénario S1. |
| A′ + E + D | Oui | Variante multijoueur de S1. |
| B + E + D | Oui | Scénario S3, asynchrone. |
| A + C | Non | Deux moments incompatibles pour la même bataille. |
| B + C | Non | Asynchrone et créneau fixe s'excluent. |
| A + F sans E | Partiel | F suppose une bataille supervisée ; sans E, le joueur peut être submergé. |
| J + « immédiatement » | Non | Contradiction directe avec § 8.5. |
| Pause en multijoueur | Non | Fausse le temps réel et l'équité. |

### 5.2 Trois scénarios cohérents

| Scénario | Contenu | Expérience | Coût de développement | Risques principaux |
|---|---|---|---|---|
| **S1 — Solo confortable** (recommandé) | D1 = A · D2 = E+F · D3 = I · D4 = 1+3, pause solo · D5 = 1 | Temps réel optionnel, jamais bloquant, contrôle direct préservé. | Moyen : modèle de résolution automatique, journal de commandes, contrat de session. | Iniquité perçue de l'automatique ; équilibrage du budget d'offensives. |
| **S2 — Temps réel fidèle** | D1 = C · D2 = E · D3 = I · D4 = 3, sans pause · D5 = 1 | Tension maximale, synchronisation exigeante. | Élevé : planification, timers, gestion des absences. | Horaires contraignants, solo délaissé, accessibilité (V-07). |
| **S3 — Asynchrone** | D1 = B · D2 = E+F · D3 = I · D4 = 1+2 · D5 = 1 | Plus lent, plus proche d'un Diplomacy moderne. | Moyen. | Perte du temps réel voulu par le § 8.3 ; modification de D-014. |

**Si vous acceptez S1 en bloc**, écrivez : « J'accepte le scénario S1 ». L'agent créera l'ADR-0006 correspondant, sans ajouter de règle non mentionnée ici.

---

## 6. Questions secondaires (à trancher maintenant ou plus tard)

Ces points ne bloquent pas l'arbitrage, mais ils conditionnent l'implémentation. Les valeurs ci-dessous sont des **propositions d'agent**, pas des décisions.

| ID | Question | Proposition (non validée) | À trancher avec |
|---|---|---|---|
| S-1 | Durée exacte du timeout d'une bataille. | 30 minutes de bataille + fenêtre de reconnexion à définir. | T-024 |
| S-2 | Que fait-on si un joueur ne se connecte pas du tout ? | Résolution automatique en posture défensive. | T-024 |
| S-3 | Peut-on sauvegarder au milieu d'une bataille ? | Non en v1 ; sauvegarde stratégique + rejeu depuis le journal. | T-028 |
| S-4 | Les batailles IA contre IA sont-elles simulées ? | Non : résolution automatique déterministe. | T-024 |
| S-5 | Un spectateur peut-il voir une bataille en cours ? | Oui, en lecture seule, selon la visibilité. | T-027 |
| S-6 | Que voit-on du résultat dans le replay ? | Commandes, graine et résultat, selon le fog of war. | T-026 |
| S-7 | Une déconnexion en cours de bataille est-elle une défaite ? | Non : fenêtre de reprise, puis résolution automatique. | T-028 |
| S-8 | Combien de relances offensives par mois ? | À chiffrer (une à trois) après simulation. | T-024 |

---

## 7. Impacts documentaires selon la décision

| Décision | Documents à mettre à jour | Tâches débloquées |
|---|---|---|
| D1 (C-01) | `gameplay/rules.md`, `military/tactical-battles.md`, `architecture/overview.md` | T-026, T-024, T-028 |
| D2 (C-02) | `military/tactical-battles.md`, `gameplay/rules.md` | T-024, T-027 |
| D3 (C-04) | `military/strategic-warfare.md`, `military/tactical-battles.md` | T-024, T-026 |
| D4 (C-15) | `military/tactical-battles.md`, `architecture/data-model.md` | T-028 |
| D5 (C-17) | `architecture/overview.md`, `architecture/technical-decisions.md` | T-028 |
| Toutes | ADR-0006 (nouveau), ADR-0005 (statut mis à jour), `PROJECT.md`, `PROGRESS.md` | T-029 clôturée |

**Rappel :** la décision ne rend pas les systèmes « spécifiés ». Elle autorise seulement T-024/T-026/T-028 à écrire des règles détaillées, qui resteront à valider dans le cahier des charges (T-030).

---

## 8. Fiche de décision (à remplir par le propriétaire)

> Remplacer `—` par l'option retenue. Ajouter toute contrainte ou réserve.

| Réf. | Tension | Options | Réponse | Contraintes / réserves |
|---|---|---|---|---|
| **D1** | C-01 — moment de la bataille | A / A′ / B / C / D | — | |
| **D2** | C-02 — batailles multiples | E / F / G / H (combinaisons possibles) | — | |
| **D3** | C-04 — relance offensive | I / J / K / L | — | |
| **D4** | C-15 — sauvegarde, pause, rejeu | 1 / 2 / 3 / 4 (combinaisons possibles) | — | |
| **D5** | C-17 — anticipation multijoueur | 1 / 2 / 3 | — | |

**Décision globale (facultatif) :** ☐ J'accepte le scénario S1 · ☐ J'accepte le scénario S2 · ☐ J'accepte le scénario S3 · ☐ Réponses au cas par cas ci-dessus.

**Questions secondaires :** ☐ J'accepte les propositions S-1 à S-8 · ☐ Je les traiterai plus tard · ☐ Je modifie : …

**Décidé par :** ______________________  **Date :** ____________

---

## 9. Procédure après décision (pour l'agent)

1. Créer **ADR-0006** à l'état `accepté`, signé par l'agent, avec le décideur = propriétaire et la date de décision.
2. Mettre à jour **ADR-0005** :
   - si le propriétaire accepte la recommandation A+D+E telle quelle, ADR-0005 peut passer `accepté` ;
   - sinon, le passer `remplacé` et référencer ADR-0006.
3. Mettre à jour les documents du § 7 **sans ajouter de règle non décidée**.
4. Fermer **T-029** dans PROGRESS.md, journaliser la décision et ses preuves.
5. Ne pas démarrer T-024/T-026 avant que les règles détaillées ne soient elles-mêmes validées (T-030).

---

## 10. Ce que ce dossier ne fait pas

- Il ne tranche aucune tension.
- Il ne choisit ni moteur, ni langage, ni framework.
- Il ne fixe aucun chiffre d'équilibrage (timeout, relances, budget).
- Il ne traite pas C-03 (conversion des forces), C-05 (interception), C-08 (victoire), C-13 (licences), C-16 (diplomatie et verrouillage) : ces points relèvent de T-024, T-025, T-026, T-028 et T-022.
- Il ne remplace pas le cahier des charges détaillé (T-030).

---

## 11. Références

- [Document fondateur v0.1](../founding-document-v0.1.md) — § 5 (temps), § 8.3 à § 8.6 (batailles et éléments non retenus), § 16 (multijoueur).
- [Revue de conception v0.1](../design-review-v0.1.md) — C-01, C-02, C-04, C-15, C-17 ; V-05, V-07.
- [ADR-0005](0005-integration-strategique-tactique.md) — proposition A + D + E, non acceptée.
- [PROJECT.md](../../PROJECT.md) — D-006, D-014 à D-016, D-026 ; Q-009.
- [PROGRESS.md](../../PROGRESS.md) — T-029, T-024, T-026, T-027, T-028, T-030.
