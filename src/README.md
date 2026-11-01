# src/ — Ancien emplacement du code source

**Ce dossier n'accueille plus le code du MVP.** Depuis l'[ADR-0006](../docs/decisions/0006-pile-technique-mvp.md), le code exécutable vit dans [`game/`](../game/) :

- `game/` : moteur, données, serveur et interface web ;
- `tests/` : tests `unittest` du moteur ;
- `tools/` : outillage de génération de l'atlas provisoire.

Ce dossier est conservé comme pointeur pour ne pas casser les liens historiques et le script de vérification. Ne pas y ajouter de nouveau code sans ADR.

## Règles pour la suite

- respecter les frontières décrites dans [docs/architecture/overview.md](../docs/architecture/overview.md) ;
- respecter les [conventions de programmation](../docs/development/coding-standards.md) ;
- ajouter les tests correspondants dans `tests/` ;
- documenter les décisions structurantes par ADR ;
- mettre à jour [PROGRESS.md](../PROGRESS.md).

Voir [README.md](../README.md) pour lancer le jeu et exécuter les tests.
