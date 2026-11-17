# Luxembourg — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **400** |
| Date de référence | January 1914 (peace establishment; the Grand Duchy was invaded and occupied from 2 August 1914) |
| Définition | ESTIMATED peace-time strength actually under arms of the armed force of the Grand Duchy: a single small infantry battalion (a few companies) with a tiny mounted/technical element, roughly 300-400 officers and men, taken here as about 400. Under the 1867 Treaty of Luxembourg the Grand Duchy was declared perpetually neutral and the great fortress of Luxembourg was demolished, leaving only a token force. EXCLUDES the nominal civic guard (Garde Civique), a largely untrained citizen militia of a few thousand enrolled men. |
| Source | `SEC_west_EB1911_LU` — Encyclopaedia Britannica, 11th edition (1911), article 'Luxemburg'/'Luxembourg', section 'Defence'. Notes the Grand Duchy's perpetual neutrality under the 1867 Treaty of London, the demolition of the fortress of Luxembourg and the existence of only a very small armed force. Reliable for the qualitative picture, not for exact numbers. |
| Page / passage | article 'Luxemburg'/'Luxembourg', section 'Defence'; cf. SYB1914, Luxembourg, 'Defence' |
| Lien | — |
| Fiabilité | faible |
| Calcul | ESTIMATE. The standard references and later accounts agree only that the force was a token one of a few hundred men (usually quoted as 300-400). The round value 400 is adopted; given the scarcity and vagueness of the sources this value has low reliability. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_west_EB1911_LU` | — | Some accounts give c.300 men, others c.400 for the 1914 army; both are of the same order of magnitude. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_west_EB1911_LU` | — | The Garde Civique (c.2,000-3,000 nominal members) was barely trained and is excluded from the regular under-arms figure. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_west_EB1911_LU` | — | No mobilisation of significance occurred: German troops occupied the country on 2 August 1914 and the tiny army offered only token resistance. | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **0** |
| Date de référence | January 1914 (no organised trained reserve of military significance) |
| Définition | No trained reserve of military significance. Luxembourg had no substantial body of ex-service trained reservists; the nominal Garde Civique was a citizen militia with little or no systematic training and is therefore not counted here. A value of 0 is used to mark the absence of a usable trained reserve, NOT to deny that a paper militia existed. |
| Source | `SEC_west_EB1911_LU` — Encyclopaedia Britannica, 11th edition (1911), article 'Luxemburg'/'Luxembourg', section 'Defence'. Notes the Grand Duchy's perpetual neutrality under the 1867 Treaty of London, the demolition of the fortress of Luxembourg and the existence of only a very small armed force. Reliable for the qualitative picture, not for exact numbers. |
| Page / passage | article 'Luxembourg', section 'Defence' |
| Lien | — |
| Fiabilité | faible |
| Calcul | Qualitative assessment from the cited references: the post-1867 settlement limited Luxembourg to a tiny regular force and a nominal militia. No numerical trained-reserve return exists in the accessible literature; 0 is used as a deliberate 'none of significance' marker. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_west_EB1911_LU` | — | If the Garde Civique's nominal membership (c.2,000-3,000) is loosely called a 'reserve', a figure of a few thousand could be quoted — but it was not trained reservists in the sense used for the great powers. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_west_EB1911_LU` | — | Some later accounts speak of a wartime expansion to roughly 1,000-2,000 men, but this is a paper mobilisation, not trained manpower. | divergence textuelle issue de la recherche secondaires |

Part des réserves sur la carte : 1/1 — Hypothese explicite : etat entierement sur la carte, aucun resonnement sur une fraction outre-mer documentee ; 100 % des reserves sont disponibles dans le reservoir de mobilisation du jeu.

### Échelons de mobilisation (T-051)

Aucun sous-echelon historiquement documente pour cet Etat.

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|

**Appel en bloc unique (approximation non documentee, décision MIL01-P1-D1) :** 0. Faute d echelon source, le reservoir est appele en bloc unique. Aucun sous-echelon n est invente.

### Ventilation par arme

**inconnue**

### Forces hors de la carte

**0** (hypothese documentee) — Aucun effectif hors carte n est attribue : les troupes coloniales eventuelles sont exclues de la definition de l effectif actif retenue.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 3 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Garnison de Luxembourg-ville (ancienne forteresse, capitale) | Luxembourg | siege historique correspond a une ville de l atlas | region_019 (Luxembourg) |
| Poste du nord (Diekirch) — commandement nominal | Diekirch | siege approxime par la ville la plus proche (ESTIMATION) | region_019 (Luxembourg) |
| Poste du sud (Esch-sur-Alzette, bassin industriel) — commandement nominal | Esch-sur-Alzette | siege approxime par la ville la plus proche (ESTIMATION) | region_019 (Luxembourg) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 400 ; sur la carte : 400 (unités combattantes 400 + services 0).
- Réserves sur la carte (non incorporées) : 0 ; hors carte : 0.
- Unités : 3.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_019 (Luxembourg) | 400 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
