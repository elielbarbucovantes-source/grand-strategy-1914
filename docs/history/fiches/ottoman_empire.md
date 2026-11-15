# Empire ottoman — effectifs 1914 (MIL-01)

> Fiche générée par `tools/history/render_fiches.py` depuis `data/history/military_forces_1914.json` ; ne pas modifier à la main.

**État des données : INSUFFISANT pour la ventilation par arme ; effectif et réserves sourcés à fiabilité moyenne ; part européenne estimée**

### A. Armée active (temps de paix)

| Champ | Contenu |
|---|---|
| Valeur retenue | **208 000** |
| Date de référence | été 1914 |
| Définition | « peacetime operating strength of about 200,000 men and 8,000 officers » (classes 1893 et 1894 sous les drapeaux) |
| Source | `ERICKSON_2000` — Edward J. Erickson, « Turkey Prepares for War, 1913-1914 », Relevance: The Quarterly Journal of the Great War Society, printemps 2000. Repris sur le blog Roads to the Great War, 7 janvier 2019. |
| Page / passage | non disponible (article repris en ligne) |
| Lien | https://roadstothegreatwar-ww1.blogspot.com/2019/01/turkey-prepares-for-war-19131914.html |
| Fiabilité | faible à moyenne |
| Remarque | Abaissée le 15/11/2026 (audit P2-7) : source secondaire unique, consultée dans une reprise en ligne sans pagination, en attendant Erickson, Ordered to Die (2001). |

### B. Réserves mobilisables

| Champ | Contenu |
|---|---|
| Valeur retenue | **1 000 000** |
| Date de référence | été 1914 |
| Définition | « approximately 1,000,000 men [...] were easily available for recall » (estimation de l'état-major ottoman) |
| Source | `ERICKSON_2000` — Edward J. Erickson, « Turkey Prepares for War, 1913-1914 », Relevance: The Quarterly Journal of the Great War Society, printemps 2000. Repris sur le blog Roads to the Great War, 7 janvier 2019. |
| Page / passage | non disponible |
| Lien | https://roadstothegreatwar-ww1.blogspot.com/2019/01/turkey-prepares-for-war-19131914.html |
| Fiabilité | faible à moyenne |

**Divergences conservées :**

| Valeur | Source | Page | Définition | Note |
|---|---|---|---|---|
| 2 000 000 | `ERICKSON_2000` | — | « mobilization potential of about 2,000,000 men » (potentiel total) |  |
| 477 868 | `ERICKSON_2000` | — | Hommes nécessaires pour compléter les divisions (« 477,868 men and 12,469 officers ») | Besoin, pas réservoir. |

Part des réserves sur la carte : 3/13 — ESTIMATION : 3 corps (Ire armée) sur 13 sont en Thrace et à Constantinople (à vérifier).

**Contrôle de cohérence avec la source :** total des instruits, actifs compris : 2 000 000 (`ERICKSON_2000` non disponible) ; actif + réserves = 1 208 000. « mobilization potential of about 2,000,000 men » (potentiel total) Contrôle de phase 1 : armée active + réserves ≤ ce total (testé par test_forces_mil01.gd).

### Échelons de mobilisation (T-051)

T-051 (VALIDÉ) : mobilisation par échelons historiquement documentés. Un échelon sans donnée fiable vaut null (« introuvable ») ; aucun total n'est réparti arbitrairement. Données de phase 1 : le moteur ne les utilise pas encore (phase 2).

| Échelon | Valeur | Statut | Sources | Définition, calcul ou motif |
|---|---|---|---|---|
| Premier échelon : appel prévu par le plan de mobilisation de 1914 | ****inconnu**** | introuvable | — | ERICKSON_2000 donne 1 000 000 hommes « easily available for recall » et un besoin de 477 868 hommes pour compléter les divisions ; ni l'un ni l'autre n'est le plan d'appel. Source attendue : Erickson, Ordered to Die (2001), non consulté. |
| Échelons suivants | ****inconnu**** | introuvable | — | Même lacune documentaire. |
| Réserves résiduelles | ****inconnu**** | introuvable | — | Potentiel total « about 2,000,000 men » (ERICKSON_2000) : non ventilé ; non utilisable comme échelon. |

### Ventilation par arme

INCONNU : aucune ventilation par arme sourcée. Le jeu modélise ces soldats en infanterie générique (simplification technique signalée sur chaque unité), sans artillerie ni cavalerie.

### Forces hors de la carte

**160 000** (estimation) — ESTIMATION : la carte ne comprend que la Thrace et Constantinople (régions 087 à 090). Seule la Ire armée (corps I, II et III) y est rattachée, sur 13 corps (connaissance générale, à vérifier dans Erickson 2001) : part sur la carte 3/13 de 208 000 = 48 000 ; hors carte 160 000.

### Districts du temps de paix (répartition ESTIMÉE)

Contrôle du nombre : 3 — Composition de la Ire armée en août 1914 (corps I, II, III) : article Wikipédia « First Army (Ottoman Empire) » (cite Erickson) — à vérifier.

| District | Siège | Siège vérifié ? | Région du jeu |
|---|---|---|---|
| Ier corps (Ire armée) | Constantinople | à vérifier | region_087 (Constantinople et environs) |
| IIe corps (Ire armée, Thrace) | Thrace — siège précis non vérifié, rattaché au QG de la Ire armée | à vérifier — indice contraire — Indices secondaires (articles encyclopédiques citant Erickson, versions divergentes) : garnison en Thrace, à Edirne et Kırk Kilise (région 089) ou à Tekirdağ (région 088). Aucune source primaire consultée : le siège n'est PAS déplacé. | region_087 (Constantinople et environs) |
| IIIe corps (Ire armée, Thrace) | Thrace — siège précis non vérifié, rattaché au QG de la Ire armée | à vérifier — indice contraire — Indices secondaires (articles encyclopédiques citant Erickson, versions divergentes) : garnison en Thrace, à Edirne et Kırk Kilise (région 089) ou à Tekirdağ (région 088). Aucune source primaire consultée : le siège n'est PAS déplacé. | region_087 (Constantinople et environs) |

### Situation de départ dans le jeu (campagne historique)

- Actifs au démarrage : 208 000 ; sur la carte : 48 000 (unités combattantes 48 000 + services 0).
- Réserves sur la carte (non incorporées) : 230 769 ; hors carte : 769 231.
- Unités : 6.

| Région | Infanterie | Cavalerie | Artillerie |
|---|---|---|---|
| region_087 (Constantinople et environs) | 48 000 | 0 | 0 |

Méthode et limites : [`../MIL01_METHODE.md`](../MIL01_METHODE.md) ; sources : [`../BIBLIOGRAPHIE.md`](../BIBLIOGRAPHIE.md).
