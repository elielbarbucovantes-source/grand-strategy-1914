# Albanie — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **5 000** |
| Date de référence | 1914-01 (extremely rough estimate) |
| Définition | Nominal gendarmerie and regular armed formations nominally under the provisional Albanian government - NOT a national army in the effective sense |
| Source | `SEC_balkans_WIKI_ALBANIAN_AF` — Wikipedia, 'Albanian Armed Forces': Albanian National Army formed 4 December 1912 by Ismail Qemali's provisional government, first commander Lt. Col. Ali Shefqet Shkupi; next numerical strength quoted is 10,691 active troops in 1923, i.e. no reliable contemporary 1914 return is given. |
| Page / passage | section 'History' |
| Lien | https://en.wikipedia.org/wiki/Albanian_Armed_Forces |
| Fiabilité | faible |
| Calcul | Albania declared independence 28 November 1912; the Albanian National Army was created 4 December 1912 under Ismail Qemali (first commander Lt. Col. Ali Shefqet Shkupi). In January 1914 the new state was under the International Commission of Control; public order was maintained by a gendarmerie organised with Dutch officers, while most armed men were tribal irregulars owing allegiance to local chiefs, not to the government. The value 5,000 is a PLACEHOLDER ORDER OF MAGNITUDE only, not supported by a located contemporary return. The first concrete strength figure in the Wikipedia article is 10,691 active troops in 1923 - a decade later. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | No reliable January 1914 strength return located in any accessible source | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | Estimates in secondary literature range widely (a few thousand gendarmerie to 10,000-15,000 armed men including irregulars) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | WIKI_ALBANIAN_AF gives 10,691 active in 1923 - not applicable to 1914 | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | US War Department 1916 handbook (not directly consulted) is the most likely source for a contemporary gendarmerie figure | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **0** |
| Date de référence | 1914-01 |
| Définition | No organised, trained reserve force existed; armed tribal irregulars are not counted as trained reservists |
| Source | `SEC_balkans_WIKI_ALBANIAN_AF` — Wikipedia, 'Albanian Armed Forces': Albanian National Army formed 4 December 1912 by Ismail Qemali's provisional government, first commander Lt. Col. Ali Shefqet Shkupi; next numerical strength quoted is 10,691 active troops in 1923, i.e. no reliable contemporary 1914 return is given. |
| Page / passage | section 'History' |
| Lien | https://en.wikipedia.org/wiki/Albanian_Armed_Forces |
| Fiabilité | faible |
| Calcul | The value 0 means 'no documented organised reserve establishment', NOT that no armed men existed. In practice thousands of armed tribesmen (Kachaks, Tosks and Ghegs) could be mobilised locally, but they were neither trained nor centrally controlled. Any numeric value here would be invented; 0 is used to avoid presenting a fabricated estimate as fact. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | Potential irregular mobilisation of unknown size | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | During the First Balkan War Albanian volunteers and irregulars fought on both Ottoman and Balkan-League sides (WIKI_BALKAN_WARS) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_ALBANIAN_AF` | — | No conscription law or reserve structure documented for January 1914 | divergence textuelle issue de la recherche secondaires |

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

Contrôle du nombre : 6 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Shkodër (nominal, sous contrôle international) | Shkodër | siege approxime par la ville la plus proche (ESTIMATION) | region_076 (Albanie) |
| Tirana (capital nominale) | Tirana | siege approxime par la ville la plus proche (ESTIMATION) | region_076 (Albanie) |
| Durrës (port) | Durrës | siege historique correspond a une ville de l atlas | region_076 (Albanie) |
| Vlorë (siège du gouvernement provisoire) | Vlorë | siege approxime par la ville la plus proche (ESTIMATION) | region_076 (Albanie) |
| Berat | Berat | siege approxime par la ville la plus proche (ESTIMATION) | region_076 (Albanie) |
| Korçë (contestée par la Grèce) | Korçë | siege approxime par la ville la plus proche (ESTIMATION) | region_076 (Albanie) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 5 000 ; sur la carte : 5 000 (unités combattantes 5 000 + services 0).
- Réserves sur la carte (non incorporées) : 0 ; hors carte : 0.
- Unités : 6.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_076 (Albanie) | 5 000 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
