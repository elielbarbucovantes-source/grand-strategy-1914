# Portugal — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **30 000** |
| Date de référence | Peace establishment 'fixed of late years' as reported in 1913; applicable to January 1914 (1911 militia reorganisation in force; no mobilisation before 1916) |
| Définition | PEACE ESTABLISHMENT of the metropolitan active (first-line) army: '30,000 men', with 'about 2,800 officers, all told' counted separately by the source. This is the establishment of the conscript militia-style active army, not a verified daily headcount of effectives. Excluded: Republican Guard (~5,000), Fiscal Guard (~5,200), colonial army (~10,150) and the reserve/territorial categories. Portugal was neutral and unmobilised in January 1914. |
| Source | `SEC_iberia_SYB1913` — The Statesman's Year-Book: Statistical and Historical Annual of the States of the World for the Year 1913. Spain: 'Defence — Army', pp. 1260-1262; Portugal: 'Defence', pp. 1151-1152. Figures 'revised after official returns'. |
| Page / passage | Portugal, 'Defence', printed pp.1151-1152 (Wikisource djvu pages 1273-1274) |
| Lien | https://en.wikisource.org/wiki/Page:Statesman%27s_Year-Book_1913.djvu/1383 (Spain p.1261); https://en.wikisource.org/wiki/Page:Statesman%27s_Year-Book_1913.djvu/1274 (Portugal p.1152); full scan: https://archive.org/details/statesmansyearbo1913newy |
| Fiabilité | haute |
| Calcul | Direct reading of the SYB statement 'The peace establishment of the active army has been fixed of late years at 30,000 men. There are about 2,800 officers, all told.' The 30,000 is used as the active strength to avoid doubling the officers, whose relationship to the 30,000 is ambiguous in the text. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_iberia_SYB1913` | — | If the ~2,800 officers are additional to the 30,000 men, the total active army under arms would be about 32,800 — the source's wording is ambiguous. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_SYB1913` | — | HCPT gives about 44,000 'with colours including National Republican Guard and Police', plus about 10,000 in the colonies — a much broader definition that folds in paramilitary gendarmerie and colonial troops. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_SYB1913` | — | SYB1913 gives the broader structure (35 infantry regiments of 3 battalions, 11 cavalry regiments, 8 field artillery regiments with 63 batteries, etc.); Wikipedia (WIKI) describes the 1911 reform as 8 active divisions of 4 infantry regiments each plus a cavalry brigade — the same order of battle described at different levels, not a contradiction in numbers. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_SYB1913` | — | Portugal was not strictly a non-belligerent in practice after 1914 (seizure of German ships, border fighting in Africa from August 1914, war declared by Germany March 1916), but none of this affects the January 1914 peace establishment. | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **100 000** |
| Date de référence | Contemporary estimate of October 1914 (NYT1914), applied approximately to the 1914 reserve system in being in January 1914 |
| Définition | ESTIMATED trained reservists available in addition to the active army: the NYT (29 Oct 1914) reported about 130,000 'fully trained men in the active army and its two reserves' after wastage; subtracting the ~30,000-man active peace establishment gives roughly 100,000 trained reservists. This is an ESTIMATE by derivation, not a figure stated directly in the sources, and it is a mobilisation-availability figure — reservists were not under arms in January 1914. A further ~50,000 men of the territorial reserve were only partly trained and are excluded here. |
| Source | `SEC_iberia_NYT1914` — The New York Times, 29 October 1914, 'PORTUGAL'S ARMY 130,000.; With 50,000 in the Territorial Reserve' — 'When mobilization is ordered, after allowing for wastage, the number of fully trained men in the active army and its two reserves amounts to about 130,000, with perhaps 50,000 men of the territorial reserve...' (headline and lead retrieved via search index; full text paywalled). |
| Page / passage | Headline and lead paragraph, 29 October 1914 |
| Lien | https://timesmachine.nytimes.com/timesmachine/1914/10/29/101905679.html |
| Fiabilité | moyenne |
| Calcul | 130,000 (active + two reserves, fully trained, after wastage) minus 30,000 (active peace establishment, SYB1913) = about 100,000 trained reservists. Because both inputs are approximate and come from different sources, this value is explicitly an estimate. SYB1913 gives no numerical reserve strength, only the reserve order of battle: 35 infantry regiments, 8 cavalry squadrons, 24 field batteries and other units; the territorial army had no cadres. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_iberia_NYT1914` | — | NYT1914's own figure is 130,000 for active + two reserves combined; if a user wants the total trained mobilisable manpower including the active army, use 130,000 instead of the 100,000 reserve-only estimate. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_NYT1914` | — | NYT1914 also mentions 'perhaps 50,000 men of the territorial reserve' — additional, largely untrained manpower, not included in the 100,000. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_NYT1914` | — | HCPT's war-planning figures (5 infantry divisions on outbreak, ultimately 12 more) imply far larger wartime mobilisation, consistent with the trained-reserve estimate but not usable as a January 1914 active figure. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_iberia_NYT1914` | — | SYB1913's liability rules (10 years active, 10 reserve, 5 territorial, ages 17-45) imply a much larger theoretical manpower pool; the source does not quantify it. | divergence textuelle issue de la recherche secondaires |

Part des réserves sur la carte : 1/1 — Hypothese explicite : etat entierement sur la carte, aucun resonnement sur une fraction outre-mer documentee ; 100 % des reserves sont disponibles dans le reservoir de mobilisation du jeu.

### Échelons de mobilisation (T-051)

Aucun sous-echelon historiquement documente pour cet Etat.

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|

**Appel en bloc unique (approximation non documentee, décision MIL01-P1-D1) :** 100 000. Faute d echelon source, le reservoir est appele en bloc unique. Aucun sous-echelon n est invente.

### Ventilation par arme

**inconnue**

### Forces hors de la carte

**0** (hypothese documentee) — Aucun effectif hors carte n est attribue : les troupes coloniales eventuelles sont exclues de la definition de l effectif actif retenue.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 6 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| District militaire Nord (1re circonscription militaire) | Porto | siege historique correspond a une ville de l atlas | region_020 (Portugal) |
| District militaire Centre (2e circonscription militaire) | Coimbra | siege approxime par la ville la plus proche (ESTIMATION) | region_020 (Portugal) |
| District militaire Sud (3e circonscription militaire) | Évora | siege approxime par la ville la plus proche (ESTIMATION) | region_020 (Portugal) |
| Camp retranché de Lisbonne (commandement distinct) | Lisbonne | siege historique correspond a une ville de l atlas | region_020 (Portugal) |
| Commandement militaire des Açores | Ponta Delgada | siege approxime par la ville la plus proche (ESTIMATION) | region_020 (Portugal) |
| Commandement militaire de Madère | Funchal | siege approxime par la ville la plus proche (ESTIMATION) | region_020 (Portugal) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 30 000 ; sur la carte : 30 000 (unités combattantes 30 000 + services 0).
- Réserves sur la carte (non incorporées) : 100 000 ; hors carte : 0.
- Unités : 6.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_020 (Portugal) | 30 000 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
