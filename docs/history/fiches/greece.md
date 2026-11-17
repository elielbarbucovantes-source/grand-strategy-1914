# Grèce — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : effectifs documentes, repartition estimee**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **20 000** |
| Date de référence | 1914-01 (estimate; documented base 1908) |
| Définition | Peace-footing regular army: officers, NCOs and conscripts actually serving |
| Source | `SEC_balkans_EB1911_GREECE` — 1911 Encyclopaedia Britannica, vol. 12, article 'Greece' (Bourchier et al.), section 'Army': 1904 reorganisation scheme peace footing 1,887 officers + 25,140 NCOs and men, war active army >=120,000 plus territorial army >=60,000; 'In 1908 ... peace strength ... 1939 officers and civilians, 19,416 non-commissioned officers and men ... reserves will furnish about 77,000 men and the territorial army about 37,000 men in time of war.' |
| Page / passage | article 'Greece', section 'Army' |
| Lien | https://en.wikisource.org/wiki/1911_Encyclop%C3%A6dia_Britannica/Greece |
| Fiabilité | moyenne |
| Calcul | EB1911 gives the 1908 peace strength as 1,939 officers and civilians + 19,416 NCOs and men = 21,355 (plus 2,661 horses/mules). The 1904 reorganisation scheme envisioned 1,887 officers + 25,140 men = 27,027 on a peace footing, but its full implementation was suspended in 1906 for five years. The round value 20,000 is used as the January 1914 order of magnitude; after the Balkan Wars Greece doubled its territory and retained part of its army mobilised, so the true number under arms in early 1914 may have been considerably higher. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_EB1911_GREECE` | — | 21,355 peace strength in 1908 (EB1911) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_GREECE` | — | 27,027 planned peace footing under the 1904 law (EB1911) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_GREECE` | — | Foreign observers estimated only ~50,000 mobilisable before the Balkan Wars; Greece actually fielded 125,000 in 1912-13 (WIKI_HELLENIC_ARMY) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_EB1911_GREECE` | — | 125,000 (First Balkan War) and 148,000 (Second Balkan War) wartime strengths (WIKI_BALKAN_WARS) | divergence textuelle issue de la recherche secondaires |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **140 000** |
| Date de référence | 1914-01 (estimate based on 1912-13 mobilisation) |
| Définition | Trained reserves and National Guard available in addition to the regular peace establishment |
| Source | `SEC_balkans_WIKI_HELLENIC_ARMY` — Wikipedia, 'Hellenic Army', section 'Decade of wars: 1912-1922': French military mission 1911-1914; 'while foreign observers estimated a mobilized force of approximately 50,000 men, the Army eventually fielded 125,000, with another 140,000 in the National Guard and reserves.' |
| Page / passage | section 'Decade of wars: 1912-1922' |
| Lien | https://en.wikipedia.org/wiki/Hellenic_Army |
| Fiabilité | moyenne |
| Calcul | EB1911 (1908 base) estimated reserves of about 77,000 and a territorial army of about 37,000 in war (total ~114,000); the unimplemented 1904 scheme envisioned 120,000 active + 60,000 territorial in war (180,000). During the Balkan Wars Greece fielded 125,000 in the army and had 'another 140,000 in the National Guard and reserves' (WIKI_HELLENIC_ARMY). The value 140,000 is taken as the post-Balkan-War trained reserve pool, which after territorial gains and mobilisation reforms was larger than the 1908 estimate. This remains an estimate. |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| **inconnu** | `SEC_balkans_WIKI_HELLENIC_ARMY` | — | 77,000 reserves + 37,000 territorial army = ~114,000 (EB1911, 1908) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_HELLENIC_ARMY` | — | 180,000 = 120,000 active + 60,000 territorial under the 1904 scheme (never fully implemented) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_HELLENIC_ARMY` | — | 140,000 National Guard and reserves in 1912-13 (WIKI_HELLENIC_ARMY) | divergence textuelle issue de la recherche secondaires |
| **inconnu** | `SEC_balkans_WIKI_HELLENIC_ARMY` | — | A Greek wartime field army of 125,000-148,000 (WIKI_BALKAN_WARS) | divergence textuelle issue de la recherche secondaires |

Part des réserves sur la carte : 1/1 — Hypothese explicite : etat entierement sur la carte, aucun resonnement sur une fraction outre-mer documentee ; 100 % des reserves sont disponibles dans le reservoir de mobilisation du jeu.

### Échelons de mobilisation (T-051)

Aucun sous-echelon historiquement documente pour cet Etat.

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|

**Appel en bloc unique (approximation non documentee, décision MIL01-P1-D1) :** 140 000. Faute d echelon source, le reservoir est appele en bloc unique. Aucun sous-echelon n est invente.

### Ventilation par arme

**inconnue**

### Forces hors de la carte

**0** (hypothese documentee) — Aucun effectif hors carte n est attribue : les troupes coloniales eventuelles sont exclues de la definition de l effectif actif retenue.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 5 — recherche gs1914.secondary_forces_research (voir data/history/sources/)

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Commandement d'Athènes (1re division / corps) | Athens | siege approxime par la ville la plus proche (ESTIMATION) | region_077 (Grèce centrale) |
| Commandement de Larissa (Thessalie) | Larissa | siege historique correspond a une ville de l atlas | region_078 (Grèce septentrionale) |
| Commandement de Thessalonique (Macédoine annexée en 1913) | Thessaloniki | siege approxime par la ville la plus proche (ESTIMATION) | region_077 (Grèce centrale) |
| Commandement de Ioannina (Épire annexée en 1913) | Ioannina | siege approxime par la ville la plus proche (ESTIMATION) | region_077 (Grèce centrale) |
| Commandement du Péloponnèse (Patras) | Patras | siege historique correspond a une ville de l atlas | region_079 (Grèce méridionale et îles) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 20 000 ; sur la carte : 20 000 (unités combattantes 20 000 + services 0).
- Réserves sur la carte (non incorporées) : 140 000 ; hors carte : 0.
- Unités : 5.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_077 (Grèce centrale) | 12 000 | 0 | 0 |
| region_078 (Grèce septentrionale) | 4 000 | 0 | 0 |
| region_079 (Grèce méridionale et îles) | 4 000 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
