
# Architecture --- Principes techniques à respecter

Statut : principes directeurs de conception. Architecture technique
détaillée proposée dans `TECHNICAL_ARCHITECTURE.md` ; carte et règles
restent à spécifier. La décision de pile est réversible et ne valide pas
de gameplay.

## 1. Choix technique documenté

Le choix proposé est Godot 4.7.2 stable avec GDScript typé, sans
dépendance tierce de gameplay. Il sera vérifié par un prototype technique
isolé après confirmation des plateformes. Les outils de tests, les
formats cartographiques et l’architecture réseau sont à confirmer.
Ce choix technique n’autorise pas le développement du gameplay.

## 2. Séparation conceptuelle

L'architecture future devrait séparer clairement : - données historiques
et géographiques ; - état courant de la partie ; - règles de simulation
; - résolution des ordres ; - IA nationale ; - interface utilisateur ; -
sauvegarde et chargement ; - outils de test et de diagnostic.

Il s'agit d'un principe d'organisation, pas d'une prescription de
framework.

## 3. Résolution simultanée

La simultanéité est une règle structurante. L'architecture doit
permettre : - de collecter les ordres de tous les pays ; - de les
verrouiller avant résolution ; - de résoudre les interactions sans
avantage artificiel lié à l'ordre de traitement ; - de conserver un
journal des décisions et résultats ; - de reproduire une résolution à
partir d'un état et d'une graine identiques, si cette approche est
retenue lors de la conception technique.

## 4. Données stables

Les pays, provinces, unités, technologies, accords et événements devront
disposer d'identifiants stables. Les noms affichés ne doivent pas servir
seuls de clés internes.

Les formats exacts et la stratégie de migration des données sont À
DÉFINIR.

## 5. Sauvegarde et observabilité

La partie doit pouvoir être sauvegardée et rechargée. Les décisions et
événements importants doivent être traçables afin de comprendre pourquoi
une IA ou le moteur a agi.

Les formats de sauvegarde, versions, compatibilité et outils de
journalisation sont À DÉFINIR.

## 6. Tests

Prévoir des tests pour : - règles économiques ; - mouvement et
logistique ; - ordres simultanés ; - diplomatie et traités ; - combat
stratégique et tactique ; - IA et limites d'information ; - sauvegarde
et chargement ; - scénarios historiques de référence.

Les tests doivent être indépendants autant que possible de l'interface.

## 7. Multijoueur futur

La première version est solo, mais l'architecture doit éviter de rendre
impossible le multijoueur futur. Cela ne justifie pas de développer
immédiatement un système réseau complexe.

## 8. Sécurité et intégrité

-   Pas de secrets dans le dépôt.
-   Pas d'opérations Git destructives sans autorisation.
-   Pas de publication ou déploiement sans autorisation.
-   Préférer les changements petits et réversibles.
-   Documenter les décisions techniques.

## 9. Questions techniques ouvertes

-   Plateformes et version stable exacte de Godot.
-   Modèle de simulation et cadence.
-   Architecture de données.
-   Système de sauvegarde.
-   Modèle de déterminisme et génération aléatoire.
-   Interface et rendu cartographique.
-   Architecture IA.
-   Stratégie de tests et intégration continue.
-   Compatibilité multiplateforme.
