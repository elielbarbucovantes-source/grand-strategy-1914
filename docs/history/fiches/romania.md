# Roumanie — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **93 642** |
| Date de référence | 1909-1910 (closest documented pre-war peace establishment; used as proxy for January 1914) |
| Définition | Peace establishment of the field army actually maintained under arms: 4,415 officers + 89,227 NCOs and men (18,920 horses excluded). Four army corps, the Dobrudja independent brigade and the separate cavalry division. This is the standing/peace force, not the mobilised army. |
| Source | `SEC_nordic_EB1911_RO` — Encyclopaedia Britannica, 11th edition (1911), vol. 23, article 'Rumania' (Arthur J. Evans, Henry Trotter, Moses Gaster), section 'Defence'. Gives the 1891 conscription law (modified 1900, 1908), three military sections (field army and reserves ages 21-30; territorial militia ages 30-36; Gloata/Landsturm ages 36-46), four army corps at Craiova, Bucharest, Jassy, Galatz, an independent Dobrudja brigade and a cavalry division at Bucharest; peace strength 1909-10 = 4,415 officers + 89,227 NCOs and men + 18,920 horses; war footing of field army 225,000 combatants; projected militia 100,000 (not fully organised by 1910). |
| Page / passage | article 'Rumania', section 'Defence' |
| Lien | https://en.wikisource.org/wiki/1911_Encyclop%C3%A6dia_Britannica/Rumania |
| Fiabilité | haute |
| Calcul | 4,415 + 89,227 = 93,642; directly stated component figures, no estimation beyond the sum. Horses excluded from headcount. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_nordic_EB1911_RO` | — | Spartacus Educational gives 'around 100,000 men' regular strength (SPARTACUS_RO) - compatible rounding. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_RO` | — | 1911 Britannica describes the field army on a war footing as 225,000 combatants; this is a wartime establishment, not a peacetime under-arms figure. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_RO` | — | No exact January 1914 return was found; the 1909-10 figure is the nearest contemporary documented peace establishment. | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **100 000** |
| Date de référence | 1909-1910 (establishment target; explicitly not fully organised by 1910) |
| Définition | Projected territorial militia (second section, citizens aged 30-36, mustering in spring for shooting practice and autumn manoeuvres), intended to add 100,000 men; included men who had completed ranks service and conscripts chosen by lot but not called to the field army. Additionally the Gloata (Landsturm) comprised all citizens aged 36-46 for home service only, not quantified in the source. |
| Source | `SEC_nordic_EB1911_RO` — Encyclopaedia Britannica, 11th edition (1911), vol. 23, article 'Rumania' (Arthur J. Evans, Henry Trotter, Moses Gaster), section 'Defence'. Gives the 1891 conscription law (modified 1900, 1908), three military sections (field army and reserves ages 21-30; territorial militia ages 30-36; Gloata/Landsturm ages 36-46), four army corps at Craiova, Bucharest, Jassy, Galatz, an independent Dobrudja brigade and a cavalry division at Bucharest; peace strength 1909-10 = 4,415 officers + 89,227 NCOs and men + 18,920 horses; war footing of field army 225,000 combatants; projected militia 100,000 (not fully organised by 1910). |
| Page / passage | article 'Rumania', section 'Defence' |
| Lien | https://en.wikisource.org/wiki/1911_Encyclop%C3%A6dia_Britannica/Rumania |
| Fiabilité | haute |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_nordic_EB1911_RO` | — | The 100,000 militia figure was an establishment target and was reported as not completely organised up to 1910; the actually trained reserve in January 1914 is uncertain and may have been lower. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_RO` | — | If the 225,000 war-footing field army is compared with the 93,642 peace establishment, the implied field-army reserve increment is about 131,000 - a derived, not stated, figure. | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_nordic_EB1911_RO` | — | Wartime mobilisation was far larger: c.330,000 in the 1913 Second Balkan War (WIKI_RO_ARMY) / c.400,000 (SPARTACUS_RO) and 658,088 in 1916 (WIKI_RO_CAMPAIGN); these include Landsturm and newly raised units, not just trained reservists. | divergence textuelle issue de la recherche secondaires |

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
| Ier corps d'armée (Olténie) | Craiova | siege approxime par la ville la plus proche (ESTIMATION) | region_070 (Roumanie méridionale) |
| IIe corps d'armée (Munténie) | Bucarest | siege historique correspond a une ville de l atlas | region_070 (Roumanie méridionale) |
| IIIe corps d'armée (Moldavie) | Iași | siege historique correspond a une ville de l atlas | region_071 (Roumanie septentrionale) |
| IVe corps d'armée (Moldavie méridionale) | Galați | siege historique correspond a une ville de l atlas | region_071 (Roumanie septentrionale) |
| Brigade indépendante de Dobroudja | Constanța | siege historique correspond a une ville de l atlas | region_070 (Roumanie méridionale) |
| Division de cavalerie séparée | Bucarest | siege historique correspond a une ville de l atlas | region_070 (Roumanie méridionale) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 93 642 ; sur la carte : 93 642 (unités combattantes 93 642 + services 0).
- Réserves sur la carte (non incorporées) : 100 000 ; hors carte : 0.
- Unités : 12.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_070 (Roumanie méridionale) | 62 428 | 0 | 0 |
| region_071 (Roumanie septentrionale) | 31 214 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
