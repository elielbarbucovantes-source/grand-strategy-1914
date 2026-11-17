# Bulgarie — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **60 000** |
| Date de référence | 1914-01 (peacetime force after the Balkan Wars) |
| Définition | Troops on a permanent peace footing - the 'active army (i)' of the 1904 military law, i.e. cadres and conscripts actually serving |
| Source | `SEC_balkans_HALL_BALKAN` — Richard C. Hall, 'The Balkan Wars, 1912-1913: Prelude to the First World War' (Routledge, 2000), pp. 16, 18, as quoted in Wikipedia 'Bulgarian Land Forces' (quote VERIFIED 2026-11-17 in article section 'Early years'): Bulgarian peacetime force of 60,000 expanded to 370,000 in war (more than half the League's 700,000), 'with almost 600,000 men mobilised in total, out of a population of 4,300,000'; field army of 9 infantry divisions, 1 cavalry division and 1,116 artillery pieces. |
| Page / passage | pp. 16, 18 (as quoted in Wikipedia 'Bulgarian Land Forces') |
| Lien | https://en.wikipedia.org/wiki/Bulgarian_Land_Forces |
| Fiabilité | moyenne |
| Calcul | Hall (2000) gives a Bulgarian peacetime force of 60,000 on the eve of the Balkan Wars; this is used as the January 1914 peace-time estimate. The 1904-law establishment documented in EB1911 gives 2,500 officers + 48,200 men = 50,700 for 1905, 'the active army (i.) alone ... on a permanent footing'. Bulgaria's population and army grew after 1913, so 60,000 is the more appropriate 1914 order of magnitude. Both figures are theoretical establishments rather than audited head counts. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_HALL_BALKAN` | — | 50,700 (2,500 officers + 48,200 men) official peace strength for 1905 (EB1911_BULGARIA) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_HALL_BALKAN` | — | 370,000 field army in the First Balkan War and 'almost 600,000 men mobilised in total' (Hall) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_HALL_BALKAN` | — | 450,000+ mobilised in Second Balkan War (WIKI_BALKAN_WARS) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_HALL_BALKAN` | — | Wartime field army: 9 infantry divisions + 1 cavalry division + 1,116 artillery pieces (Hall) | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **280 000** |
| Date de référence | 1914-01 (derived from 1904-05 establishment, adjusted) |
| Définition | Trained reservists liable for recall: the active army reserve plus the reserve army (reservna armia); the opltchenïe (militia) is only partially trained and is counted separately |
| Source | `SEC_balkans_EB1911_BULGARIA` — 1911 Encyclopaedia Britannica, vol. 4, article 'Bulgaria' by James David Bourchier, subsection 'Army and Navy': organisation based on law of 1 Jan 1904; peace strength 1905 = 2,500 officers + 48,200 men; 9 infantry divisions with divisional HQs at Sofia, Philippopolis, Sliven, Shumla, Rustchuk, Vratza, Plevna, Stara-Zagora, Dupnitza; war strength active army + reserve 180,954; reserve army + opltchenie brings grand total to about 338,000 officers and men. |
| Page / passage | article 'Bulgaria/Description', subsection 'Army and Navy' |
| Lien | https://en.wikisource.org/wiki/1911_Encyclop%C3%A6dia_Britannica/Bulgaria/Description |
| Fiabilité | moyenne |
| Calcul | EB1911: war strength of the active army and its reserve = 180,954 officers and men, exclusive of the five cavalry regiments. Subtracting the 50,700 peace establishment gives about 130,000 active reservists. The 36 recruitment districts additionally furnished 144,000 infantry in reserve army battalions. 130,000 + 144,000 = about 274,000, rounded here to 280,000 trained reservists. Grand wartime total including opltchenïe, cavalry and services was about 338,000 on the 1904 establishment, rising to ~600,000 mobilised in 1912-13 after the Balkan Wars. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_EB1911_BULGARIA` | — | 180,954 = war strength of active army + active reserve alone (EB1911) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_BULGARIA` | — | 144,000 = reserve army battalions from 36 districts (EB1911) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_BULGARIA` | — | ~338,000 = grand total war strength including militia (EB1911) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_BULGARIA` | — | ~600,000 total mobilised in Balkan Wars (Hall) - includes untrained/second-line levies | divergence textuelle issue de la recherche secondaires |

Part des réserves sur la carte : 1/1 — Hypothese explicite : etat entierement sur la carte, aucun resonnement sur une fraction outre-mer documentee ; 100 % des reserves sont disponibles dans le reservoir de mobilisation du jeu.

### Échelons de mobilisation (T-051)

Aucun sous-echelon historiquement documente pour cet Etat.

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|

**Appel en bloc unique (approximation non documentee, décision MIL01-P1-D1) :** 280 000. Faute d echelon source, le reservoir est appele en bloc unique. Aucun sous-echelon n est invente.

### Ventilation par arme

**inconnue**

### Forces hors de la carte

**0** (hypothese documentee) — Aucun effectif hors carte n est attribue : les troupes coloniales eventuelles sont exclues de la definition de l effectif actif retenue.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 9 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| 1re division (Sofia) | Sofia | siege historique correspond a une ville de l atlas | region_072 (Bulgarie occidentale) |
| 2e division (Philippopolis/Plovdiv) | Plovdiv | siege historique correspond a une ville de l atlas | region_073 (Bulgarie orientale) |
| 3e division (Sliven) | Sliven | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 4e division (Shumla/Choumen) | Shumen | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 5e division (Rustchuk/Rousse) | Ruse | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 6e division (Vratza) | Vratsa | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 7e division (Plevna/Pleven) | Pleven | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 8e division (Stara-Zagora) | Stara Zagora | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |
| 9e division (Dupnitza) | Dupnitsa | siege approxime par la ville la plus proche (ESTIMATION) | region_073 (Bulgarie orientale) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 60 000 ; sur la carte : 60 000 (unités combattantes 60 000 + services 0).
- Réserves sur la carte (non incorporées) : 280 000 ; hors carte : 0.
- Unités : 9.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_072 (Bulgarie occidentale) | 6 667 | 0 | 0 |
| region_073 (Bulgarie orientale) | 53 333 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
