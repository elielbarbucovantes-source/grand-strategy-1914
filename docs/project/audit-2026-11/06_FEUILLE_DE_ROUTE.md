# Livrable 6 — Feuille de route opérationnelle

- **Statut :** plan de travail. Chaque lot ne démarre que sur **autorisation explicite** du directeur. Les décisions de conception restent les siennes (`QUESTIONS_DIRECTEUR.md`).
- Complexité : S < ½ jour d'agent, M ≈ 1 jour, L > 2 jours.

## 1. Phases

| Phase | Contenu | Dépendances | Critère de réussite | Validation humaine |
|---|---|---|---|---|
| **A. Sécurisation** | Licences et provenance (attributions, décision de scénario) ; documentation à jour (fait au lot 1) ; statut des anomalies (fait) ; nouveau bundle de sauvegarde ; copie de sauvegarde sur un support distinct ; alignement de `main` | — | `main` = lignée de référence ; données accompagnées de leurs licences ; sauvegarde hors disque | U1, U2, U8 |
| **B. Cartographie** | C1, puis C2a, puis C8, puis C2b (série) ; C3 à C7 et C10 (parallèle) — voir le livrable 4 | U1 (si une re-dérivation des régions était nécessaire, elle précéderait tout) | Plus de façade orpheline injustifiée ; graphe naval connexe ; 16/16 zones valides ; villes et couches thématiques validées en CI | U3, et confirmations C3 à C5 et C6b |
| **C. Arbitrages** | R-13, R-03, R-05, puis T-029 et R-08, puis R-04, R-07, R-09, R-14 ; ensuite spécifications NAT, ECO, MIL, DIP, INT, IA, victoire | — | Registre sans « À DÉFINIR » bloquant pour le premier système visé | U4, U5, U7 |
| **D. Technologie** | NP-0 à NP-6 ; ADR-0007 comparative | Autorisation U6 ; Godot 4.7.2 installé | Mesures comparables publiées | U6, puis décision du moteur |
| **E. Préparation** | Modèle de données du monde (schémas JSON), contrat d'ordres, format de sauvegarde, plan de tests, organisation de `src/`, outillage CI de l'interface | C (T-029), D | ADR acceptées ; schémas validés en CI | Revue |
| **F. Développement** | Uniquement les systèmes dont les règles sont **validées** | GATE-01 | — | Autorisation explicite |

## 2. Lots prêts à autoriser

| Lot | Contenu | Décision préalable | Estimation [ESTIMÉ] | Parallélisable |
|---|---|---|---|---|
| **Lot 1** | Livrables d'audit, scripts d'audit, corrections documentaires | — (fait) | — | — |
| **Lot 2** | Cartographie technique : C1, puis C2a, puis C8 (série) ; C6 et C7 (parallèle) ; C3 à C5 (fiches) | Aucune décision de conception | 4 à 6 j | C6, C7 et les fiches en parallèle |
| **Lot 3** | Mers occidentales C2b (V1 ou V2) | U3, U1 | 2 à 3 j | — |
| **Lot 4** | Prototypes neutres NP-0 à NP-6 | U6 | 6 à 8 j | NP-2 à NP-4 en parallèle |
| **Lot 5** | Données historiques (population de 1914 des 90 régions, schéma de provenance, correspondance des notes sur les ressources C10) | U4 (R-13 au minimum) | 5 à 10 j | Par zone géographique |
| **Lot 6** | Alignement de `main` (`docs/project/MAIN_ALIGNMENT_PLAN.md`, `07_ALIGNEMENT_MAIN.md`) | U2 | ½ j | — |
| **Lot 7** | Mise en conformité des licences selon le scénario choisi | U1 | 1 à 3 j (scénarios A et D) ; L à XL (re-dérivation) | — |

## 3. Tâches réalisables sans arbitrage humain

- Lot 2 en entier, sauf C2b et C6b.
- Préparation des fiches C3, C4, C5 et des variantes V1 et V2 de C2b (sans les appliquer).
- Table de concordance des identifiants C-xx avec ceux du registre (R-12), glossaire région / province (R-10).
- Correspondance des notes sur les ressources (C10).
- Script de reconstruction de la prévisualisation de `main` (`tools/git/build_main_alignment.sh`).
- Nouveau bundle de sauvegarde après chaque lot.

## 4. Points de validation humaine, par urgence

Le détail figure dans `QUESTIONS_DIRECTEUR.md`.

1. **U1** — licences des données (immédiat).
2. **U2** — alignement de `main`.
3. **U3** — mers occidentales (nombre de zones).
4. **U4** — R-13 (date de départ), R-03 (ressources), R-05 (statistiques).
5. **U5** — T-029 (D1 à D5).
6. **U6** — prototypes neutres et installation de Godot.
7. **U7** — confirmations mineures groupées (R-04, R-07, R-08, R-09, R-14, C3 à C5, C6b).
8. **U8** — licence du code (vente ou gratuité).
9. **U9** — suppression des anciens répertoires (sans urgence).

## 5. Risques principaux

| Risque | Gravité | Atténuation |
|---|---|---|
| Conditions de réutilisation des données sources (voir U1) | **Élevée** | Décision U1 avant tout nouvel investissement cartographique lourd (C2b, re-dérivations) |
| Absence de réseau naval à l'Ouest, alors que la logistique, les débarquements et les blocus en dépendent | Élevée | Lot 3 après U3 |
| Données historiques inventées pour remplir des tableaux | Élevée | Schéma de provenance obligatoire ; valeur `null` plutôt qu'une estimation non sourcée |
| Conflits sur `adjacency.json` et les empreintes | Moyenne | Série obligatoire sur une seule branche d'intégration |
| Prévisualisation de `main` dépassée par les nouveaux commits | Moyenne | Reconstruction scriptée juste avant l'exécution |
| Sauvegardes sur le même disque | Moyenne | Copie sur un support distinct |
