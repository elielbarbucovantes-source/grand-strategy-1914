# Norvège — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **12 750** |
| Date de référence | 1911 |
| Définition | Peace establishment of the line: 12,000 men with 750 officers. The only enlisted (long-service) troops were the fortress garrisons and the Christiania garrison of Norwegian Guards; the line was otherwise a cadre trained for 18-102 days per year. This is the force under arms in peacetime, distinct from the much larger total trained establishment (see divergences). |
| Source | `SEC_nordic_EB1911_NO` — Encyclopaedia Britannica, 11th edition (1911), vol. 19, article 'Norway' (Philip Lake, Osbert J. R. Howarth, Bertha S. Phillpotts, Hans L. Brækstad, Edmund Gosse), section 'Army and Navy'. Army = line + landværn (reserve) + landstorm (second reserve); conscription from 22, 6 years line, 6 reserve, 4 second reserve; war liability ages 18-50; peace establishment of the line 12,000 men with 750 officers; war footing 26,000 or more but not above 18,000 without parliamentary authority; only fortress garrisons and the Christiania garrison of Norwegian Guards are enlisted troops; principal fortresses Oscarsborg, Agdenes, Bergen, Tönsberg, Christiansand. |
| Page / passage | article 'Norway', section 'Army and Navy' |
| Lien | https://en.wikisource.org/wiki/1911_Encyclop%C3%A6dia_Britannica/Norway |
| Fiabilité | haute |
| Calcul | 12,000 men + 750 officers = 12,750; directly stated components. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_nordic_EB1911_NO` | — | A later (c.1920) description quoted in WIKI_NO_ARMY gives a 'total peace strength' of 118,500 men with 71,836 rifles, 228 field and 36 heavy guns. This almost certainly denotes the total trained line+landværn establishment on paper, NOT troops continuously under arms, and is roughly ten times the peace establishment of the line. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_NO` | — | The same source gives 282,000 additional men available on mobilisation, implying a theoretical wartime pool of roughly 400,000 - an establishment figure, not a peacetime presence. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_NO` | — | EB1911_NO states a war footing of 26,000 or more but not exceeding 18,000 without parliamentary authority; this ambiguity is noted rather than resolved. | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **282 000** |
| Date de référence | c.1920 description of the system in force from 1911/1914 (approximate proxy for January 1914) |
| Définition | Additional men available on mobilisation under the militia/territorial system: the landværn (reserve, 6 years) and landstorm (second reserve, 4 years), with war liability from 18 to 50 and 12 years in the line followed by 12 in the landvern then the landstorm. The figure is an establishment/pool estimate, NOT reservists under arms in peacetime. |
| Source | `SEC_nordic_WIKI_NO_ARMY` — Wikipedia, 'Norwegian Army', sections 'Independence' and 'World War I' (text derived from an early-20th-century encyclopedic description of the post-1920 militia system): six brigades established 1911, called divisions from 1916; 56 infantry battalions, 5 cyclist (ski) companies, 3 cavalry regiments (16 squadrons), 27 four-gun field batteries, 3 mountain batteries, 9 heavy artillery batteries, 1 engineer regiment and 2 battalions; 'The total peace strength was 118,500 men and comprised 71,836 rifles, 228 field and 36 heavy guns. The additional numbers available on mobilization amount to 282,000 men.' Liability 18-56, 12 years line then 12 years landvern then landstorm; initial training 48-102 days by arm. Note: this description is of the c.1920 'national militia' system and must not be read as troops continuously under arms. |
| Page / passage | section 'Independence' (c.1920 system description) |
| Lien | https://en.wikipedia.org/wiki/Norwegian_Army |
| Fiabilité | moyenne |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_nordic_WIKI_NO_ARMY` | — | The source text describes the post-1920 'national militia' organisation of a system introduced earlier; the exact January 1914 reserve total is uncertain. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_WIKI_NO_ARMY` | — | EB1911_NO describes the same three-tier structure (line, landværn, landstorm) but gives no headcount for the reserves, only the line's war footing of 26,000. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_WIKI_NO_ARMY` | — | The 118,500 'peace strength' and 282,000 mobilisable extras from the same later source should not be added to the 12,750 line peace establishment without triple-counting; they describe different levels of the same establishment. | divergence textuelle issue de la recherche secondaires |

Part des réserves sur la carte : 1/1 — Hypothese explicite : etat entierement sur la carte, aucun resonnement sur une fraction outre-mer documentee ; 100 % des reserves sont disponibles dans le reservoir de mobilisation du jeu.

### Échelons de mobilisation (T-051)

Aucun sous-echelon historiquement documente pour cet Etat.

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|

**Appel en bloc unique (approximation non documentee, décision MIL01-P1-D1) :** 282 000. Faute d echelon source, le reservoir est appele en bloc unique. Aucun sous-echelon n est invente.

### Ventilation par arme

**inconnue**

### Forces hors de la carte

**0** (hypothese documentee) — Aucun effectif hors carte n est attribue : les troupes coloniales eventuelles sont exclues de la definition de l effectif actif retenue.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 6 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| 1re brigade (Akershus) | Christiania (Oslo) | siege historique correspond a une ville de l atlas | region_045 (Norvège — Sud) |
| 2e brigade (Norvège orientale) | Halden | siege approxime par la ville la plus proche (ESTIMATION) | region_046 (Norvège — Ouest) |
| 3e brigade (Trondhjem) | Trondhjem | siege historique correspond a une ville de l atlas | region_046 (Norvège — Ouest) |
| 4e brigade (Bergen) | Bergen | siege historique correspond a une ville de l atlas | region_046 (Norvège — Ouest) |
| 5e brigade (Møre og Romsdal, Trøndelag) | Kristiansund | siege approxime par la ville la plus proche (ESTIMATION) | region_046 (Norvège — Ouest) |
| 6e brigade (Norvège occidentale / Nord-Norge) | Stavanger | siege approxime par la ville la plus proche (ESTIMATION) | region_046 (Norvège — Ouest) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 12 750 ; sur la carte : 12 750 (unités combattantes 12 750 + services 0).
- Réserves sur la carte (non incorporées) : 282 000 ; hors carte : 0.
- Unités : 6.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_045 (Norvège — Sud) | 2 125 | 0 | 0 |
| region_046 (Norvège — Ouest) | 10 625 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
