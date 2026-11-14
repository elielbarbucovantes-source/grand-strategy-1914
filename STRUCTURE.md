# Structure du projet

```text
grand-strategy-1914/
├── project.godot                 # coquille Godot, aucune scène de jeu
├── .gitignore
├── README.md
├── PROJECT.md
├── PROGRESS.md
├── AGENTS.md
├── CHANGELOG.md
├── STRUCTURE.md
├── docs/
│   ├── ai/OVERVIEW.md
│   ├── architecture/
│   │   ├── PRINCIPLES.md             # document de conception source
│   │   └── TECHNICAL_ARCHITECTURE.md # proposition technique détaillée
│   ├── decisions/DECISIONS_PENDING.md
│   ├── diplomacy/OVERVIEW.md
│   ├── economy/OVERVIEW.md
│   ├── gameplay/OVERVIEW.md
│   ├── intelligence/OVERVIEW.md
│   ├── map/TECHNICAL_SPEC.md         # décisions + spécification, atlas non fixé
│   ├── military/OVERVIEW.md
│   ├── nations/PLAYABLE_POWERS.md
│   └── technology/OVERVIEW.md
├── prompts/OPENCODE_PROMPT.md
├── src/                           # arborescence vide, sans logique de jeu
│   ├── app/ core/ simulation/ ai/ history/ map/ ui/ adapters/
│   └── domains/{economy,industry,diplomacy,military,logistics,politics,technology,intelligence}/
├── data/
│   ├── world/map/README.md           # pas encore de données géographiques
│   ├── schemas/map.schema.json       # schémas des couches, plafond 100 régions
│   ├── scenarios/
│   └── rules/
├── tests/{unit,integration,scenarios,fixtures}/
├── tools/
├── assets/{maps,ui,audio}/
└── .git/                           # métadonnées du dépôt local
```

Les répertoires de code, données, tests, outils et assets contiennent seulement des marqueurs d’emplacement. Aucun système de jeu, scène principale ou ressource cartographique n’a été créé. Le dépôt Git local est initialisé sur `main`, sans commit.
