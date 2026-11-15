# Bibliographie vérifiable — effectifs militaires de 1914 (MIL-01)

Chaque identifiant (`US_WD_1916`…) est la clé utilisée dans `data/history/military_forces_1914.json`.

- **Date de consultation :** 15/11/2026.
- **« Contrôlé »** : passage lu dans la source elle-même. Pour les fac-similés, le numéro de page imprimé est indiqué, et le chiffre a été recontrôlé sur l'image quand l'OCR était douteuse.

## Sources utilisées pour les valeurs du jeu

| Clé | Référence | Accès | Type | Fiabilité | Passages contrôlés |
|---|---|---|---|---|---|
| `US_WD_1916` | United States War Department, Office of the Chief of Staff, War College Division, General Staff No. 22, *Strength and Organization of the Armies of France, Germany, Austria, Russia, England, Italy, Mexico and Japan (Showing Conditions in July, 1914)*, Washington, GPO, 1916 (War Dept. Doc. No. 499) | https://archive.org/details/strengthorganiza00unit (Library of Congress) | Publication officielle contemporaine d'un État neutre (renseignement) | **Moyenne** : homogène et datée, mais ce sont des estimations ; la source avertit p. 5 (« no accurate estimate can be given… ») | p. 5, 9 (tableaux, contrôlés sur le fac-similé, PDF p. 15), 15, 20, 22, 28, 29, 30, 34, 37, 38, 39, 42, 43, 45, 46, 60, 63, 66, 67 |
| `WO_1922` | War Office, *Statistics of the Military Effort of the British Empire during the Great War, 1914–1920*, Londres, HMSO, 1922 | https://archive.org/details/statisticsofmili00grea | Statistique officielle nationale | **Haute** | p. 30, tableau (i)(b) (PDF p. 40 ; **recontrôlé sur l'image le 15/11/2026** : Territorial Force 268 777, note † « Includes permanent staff ») ; p. 156-157, Section 10 (PDF p. 168-169, contrôlées sur l'image) ; p. 777 (PDF p. 795) |
| `RU_RASPISANIE_1914` | Главный штаб, *Краткое расписание сухопутных войск*, исправлено по сведениям к 1-му марта 1914 г., Saint-Pétersbourg, 1914 (état abrégé officiel des troupes de terre, à jour au 1er mars 1914) | https://archive.org/details/kratkoeraspisaniesuhoputnyhvojskpogo93 | **Source primaire** officielle (état-major russe) | **Haute** (OCR imparfait, orthographe pré-1918) | p. 214-226 : sièges des 27 corps européens (« Штабъ г. … »), lus dans le texte OCR le 15/11/2026 |
| `ERICKSON_2000` | Edward J. Erickson, « Turkey Prepares for War, 1913–1914 », *Relevance: The Quarterly Journal of the Great War Society*, printemps 2000 | Reprise : https://roadstothegreatwar-ww1.blogspot.com/2019/01/turkey-prepares-for-war-19131914.html | Article d'un historien spécialiste, lu dans une reprise en ligne | **Moyenne** (pagination originale indisponible) | Effectif de paix (« about 200,000 men and 8,000 officers »), réserves (« approximately 1,000,000 men […] easily available for recall »), potentiel (2 000 000), besoins (477 868) |

## Sources de contrôle (divergences documentées)

| Clé | Référence | Accès | Usage |
|---|---|---|---|
| `BUNDESARCHIV` | Bundesarchiv, « Preußische und deutsche Streitkräfte 1867 bis 1918 », rubrique Personalumfang | https://www.bundesarchiv.de/im-archiv-recherchieren/archivgut-recherchieren/nach-themen/preussische-und-deutsche-streitkraefte-1867-bis-1918/ | « Juli 1914 734.000 Mann » ; « August 1914 3,8 Mio. Mann mobil gemacht » : contrôle de vraisemblance |
| `BERNHARDI_1914` | F. von Bernhardi, « Das Heerwesen », *Deutschland unter Kaiser Wilhelm II.*, t. I, Berlin, Hobbing, 1914, p. 3-24 | https://de.wikisource.org/wiki/Das_Heerwesen_(1914) | Loi de 1913 (661 176 hommes du rang) ; création des XXe (Allenstein) et XXIe (Sarrebruck) corps |
| `WO_HANDBOOK_DE_1914` | General Staff, War Office, *Handbook of the German Army (Home and Colonial)*, 4e éd. 1912, amendée en août 1914 | https://archive.org/details/hndbk-german-army-1914 | 25 corps ; Garde à Berlin ; XVe et XVIe corps en Alsace-Lorraine |
| `HQ_GENERAL_KNOWLEDGE` | Sièges de corps du temps de paix (connaissance encyclopédique courante) | — | **Non revérifiés** : marqués « à vérifier » dans la base |

## Sources consultées sans résultat exploitable

| Source | Raison |
|---|---|
| *1914-1918-online. International Encyclopedia of the First World War* (articles « Mobilization (Ottoman Empire) », « Pre-war Military Planning (Ottoman Empire) ») | Accès bloqué par un dispositif anti-robot pendant la mission. **À consulter manuellement.** |
| Wikipédia, « Imperial Russian Army formations and units (1914) », « List of corps of the Imperial German Army » | Pas de sièges ni de districts dans la version consultée |
| GenWiki, « Korps und Gouvernements (WK1) » | Accès bloqué (anti-robot) |
| Hoover Institution (OAC), fonds Bastunov | Inventaire sans liste de corps ; numérisation en cours |
| Роспись войск 1914 (transcription Google Docs) | Transcription partielle : corps sibériens seulement. Remplacée par `RU_RASPISANIE_1914` (phase 1). |
| Gallica : *Annuaire officiel de l'armée française* 1914 (ark:/12148/bpt6k176446d), pour les sièges des corps français | Accès automatisé refusé (Cloudflare) le 15/11/2026. **À consulter manuellement.** |
| `WO_HANDBOOK_DE_1914` : recherche des sièges des corps allemands | Le texte OCR d'archive.org ne couvre qu'une partie des pages et ne contient pas de tableau de stationnement ; l'image du fac-similé (969 Mo) n'a pas été parcourue. |
| *Rangliste der Königlich Preußischen Armee* 1914 | Exemplaire numérisé repéré (Württembergische Landesbibliothek), marqué sous droits, non consulté. |
| Reichsarchiv, *Der Weltkrieg 1914–1918*, t. I | Aucun fac-similé en texte intégral trouvé ; l'exemplaire de la Staatsbibliothek zu Berlin trouvé sous ce titre est un ouvrage de 1915, sans rapport. |

## Sources primaires recommandées pour consolider MIL-01

**Références bibliographiques seulement : aucune de ces sources n'a été consultée.** Elles ne servent de source à aucune valeur de la base.

- Reichsarchiv, *Der Weltkrieg 1914–1918. Kriegsrüstung und Kriegswirtschaft*, t. I et Anlagen, Berlin, 1930 : Friedensstärke 1914 et mobilisation.
- Ministère de la Guerre, État-major de l'armée, Service historique, *Les Armées françaises dans la Grande Guerre*, t. I, vol. 1 et annexes : effectifs et ordre de bataille d'août 1914.
- Bundesministerium für Heerwesen / Kriegsarchiv, *Österreich-Ungarns letzter Krieg 1914–1918*, t. I.
- Ufficio Storico dello Stato Maggiore, *L'Esercito italiano nella Grande Guerra*, t. I.
- E. J. Erickson, *Ordered to Die: A History of the Ottoman Army in the First World War*, Westport, Greenwood, 2001 (annexe sur l'organisation de 1914).
- Glavnoe upravlenie General'nogo shtaba, *Rospis' voisk* (1914) ; N. N. Golovine, *The Russian Army in the World War*, Yale UP, 1931.
- War Office, *General Annual Report on the British Army for the year ending 30th September 1913* : effectifs par commandement (numéro de document parlementaire à vérifier).

## Consultation manuelle nécessaire (décision MIL01-P1-D4, 15/11/2026)

Ces documents n'ont pas pu être consultés en ligne. **Aucune valeur de la base n'en est tirée**, et leur présence dans cette bibliographie ne prouve rien.

| Document | Ce qu'il permettrait d'établir | État de la recherche (15/11/2026) |
|---|---|---|
| Ministère de la Guerre, *Annuaire officiel de l'armée française* 1914 (Gallica, `ark:/12148/bpt6k176446d`) | Sièges des 22 corps français | Gallica refuse l'accès automatisé (Cloudflare). **Consultation manuelle.** |
| *Les Armées françaises dans la Grande Guerre*, t. I, vol. 1 et annexes | Premier échelon français (appel d'août 1914), ordre de bataille | archive.org n'a que le t. IX, vol. 3 et un volume de cartes (`lesarmeesfrancaisesdanslagrandeguerrep38`, `…p43`). **Consultation manuelle** (Gallica ou bibliothèque). |
| Bundesministerium für Heerwesen et Kriegsarchiv, *Österreich-Ungarns letzter Krieg*, **t. I** | Mobilisation austro-hongroise de 1914, sièges des corps | archive.org (Université de Toronto) n'a que les t. III, IV et VI (`sterreichungar03austuoft`, `…04…`, `…06…`). Le t. I n'a pas été trouvé. **Consultation manuelle.** |
| Reichsarchiv, *Der Weltkrieg 1914–1918*, t. I, et *Kriegsrüstung und Kriegswirtschaft*, Anlagen | Mobilisation allemande, échelons détaillés | Aucun texte intégral trouvé. **Consultation manuelle.** |
| *Rangliste der Königlich Preußischen Armee* 1914 | Sièges des corps allemands | Exemplaire numérisé repéré (Württembergische Landesbibliothek), marqué sous droits. **Consultation manuelle.** |
| E. J. Erickson, *Ordered to Die* (2001) | Armée ottomane : effectifs, sièges des corps, mobilisation | Exemplaire d'archive.org en prêt contrôlé (`orderedtodiehist0000eric`, accès restreint). Un autre dépôt en accès libre existe sous un autre identifiant. Il est vraisemblablement **non autorisé**, puisque l'ouvrage est sous droits ; il **n'a pas été consulté**. **Consultation manuelle** (prêt ou exemplaire papier). |
| Ufficio Storico, *L'Esercito italiano nella Grande Guerra*, vol. I | Premier échelon italien ; troupes en Libye | Aucun exemplaire en ligne trouvé. **Consultation manuelle.** |
| N. N. Golovine, *The Russian Army in the World War* (1931) | Mobilisation russe | archive.org : prêt contrôlé (`russianarmyinwor0000nich`). **Consultation manuelle.** |
