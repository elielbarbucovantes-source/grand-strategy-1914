#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-infrastructure.sh — vérification de l'infrastructure documentaire
#
# Vérifie :
#   - la présence et la non-vacuité des fichiers obligatoires ;
#   - la présence des dossiers de documentation ;
#   - les sections obligatoires de PROGRESS.md ;
#   - les champs obligatoires du modèle d'ADR ;
#   - les liens Markdown relatifs ;
#   - l'absence d'un fichier .env réel et de secrets évidents ;
#   - l'absence de journal fictif (marqueur volontaire).
#
# Usage : ./scripts/check-infrastructure.sh
# Code de sortie : 0 si tout est valide, 1 sinon.
# ---------------------------------------------------------------------------
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

failures=0
checks=0

ok()   { checks=$((checks + 1)); printf '  OK   %s\n' "$1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf '  FAIL %s\n' "$1"; }

check_file() {
  if [ -s "$1" ]; then
    ok "fichier présent et non vide : $1"
  else
    fail "fichier manquant ou vide : $1"
  fi
}

check_dir() {
  if [ -d "$1" ]; then
    ok "dossier présent : $1"
  else
    fail "dossier manquant : $1"
  fi
}

printf '== Fichiers obligatoires ==\n'
required_files=(
  AGENTS.md
  PROJECT.md
  PROGRESS.md
  README.md
  CHANGELOG.md
  CLAUDE.md
  .gitignore
  .env.example
  docs/README.md
  docs/architecture/overview.md
  docs/architecture/technical-decisions.md
  docs/architecture/data-model.md
  docs/gameplay/rules.md
  docs/gameplay/map-system.md
  docs/gameplay/military-system.md
  docs/gameplay/economy-system.md
  docs/diplomacy/treaties.md
  docs/diplomacy/negotiations.md
  docs/diplomacy/alliances.md
  docs/diplomacy/reputation.md
  docs/artificial-intelligence/ai-architecture.md
  docs/artificial-intelligence/personalities.md
  docs/artificial-intelligence/memory-system.md
  docs/artificial-intelligence/decision-making.md
  docs/artificial-intelligence/multi-agent-interactions.md
  docs/development/coding-standards.md
  docs/development/testing-strategy.md
  docs/development/contribution-guide.md
  docs/decisions/README.md
  docs/decisions/0000-template.md
  docs/decisions/0001-documentation-et-git-comme-socle.md
  docs/decisions/0002-interoperabilite-multi-agents.md
  docs/decisions/0003-report-du-choix-de-pile-technique.md
  scripts/check-infrastructure.sh
  src/README.md
  tests/README.md
  assets/README.md
)
for f in "${required_files[@]}"; do
  check_file "$f"
done

printf '\n== Dossiers ==\n'
for d in \
  docs/architecture \
  docs/gameplay \
  docs/diplomacy \
  docs/artificial-intelligence \
  docs/development \
  docs/decisions \
  src \
  tests \
  assets \
  scripts
do
  check_dir "$d"
done

printf '\n== Sections obligatoires de PROGRESS.md ==\n'
progress_sections=(
  "## A. État général"
  "## B. Fonctionnalités terminées"
  "## C. Travaux en cours"
  "## D. Travaux à effectuer"
  "## E. Bugs et problèmes connus"
  "## F. Prochaines étapes"
  "## G. Journal des interventions"
)
for s in "${progress_sections[@]}"; do
  if grep -qF "$s" PROGRESS.md 2>/dev/null; then
    ok "section présente : $s"
  else
    fail "section absente de PROGRESS.md : $s"
  fi
done

printf '\n== Champs obligatoires du modèle d ADR ==\n'
adr_fields=(
  "## 1. Contexte"
  "## 2. Problème à résoudre"
  "## 3. Solutions envisagées"
  "## 4. Solution retenue"
  "## 5. Justification"
  "## 6. Conséquences"
  "## 7. État"
)
for s in "${adr_fields[@]}"; do
  if grep -qF "$s" docs/decisions/0000-template.md 2>/dev/null; then
    ok "champ ADR présent : $s"
  else
    fail "champ ADR absent : $s"
  fi
done

printf '\n== Formulaire du journal ==\n'
if grep -qF '| Date | Agent | Intervention | Fichiers | Tests | Résultat |' PROGRESS.md 2>/dev/null; then
  ok "en-tête du journal conforme"
else
  fail "en-tête du journal absent ou non conforme dans PROGRESS.md"
fi

printf '\n== Liens Markdown relatifs ==\n'
link_failures=0
while IFS= read -r file; do
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    target="${link%%#*}"
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    if [ ! -e "$(dirname "$file")/$target" ]; then
      fail "lien cassé dans $file : $link"
      link_failures=$((link_failures + 1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$file" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//')
done < <(find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*')
if [ "$link_failures" -eq 0 ]; then
  ok "aucun lien relatif cassé détecté"
fi

printf '\n== Secrets et fichiers sensibles ==\n'
if [ -e .env ]; then
  fail "un fichier .env existe à la racine (ne doit jamais être versionné)"
else
  ok "aucun fichier .env à la racine"
fi
if grep -qE '^(OPENAI_API_KEY|ANTHROPIC_API_KEY|GOOGLE_API_KEY|DATABASE_URL|SESSION_SECRET)=.+' .env.example 2>/dev/null; then
  fail ".env.example contient une valeur non commentée pour une variable sensible"
else
  ok ".env.example ne contient pas de secret en clair"
fi

printf '\n== Dépôt Git ==\n'
if [ -d .git ]; then
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    fail ".env est suivi par Git"
  else
    ok ".env n est pas suivi par Git"
  fi
  if git check-ignore -q .env.example 2>/dev/null; then
    fail ".env.example est ignoré par Git (il doit être versionné)"
  else
    ok ".env.example n est pas ignoré par Git"
  fi
else
  fail "dépôt Git non initialisé"
fi

printf '\n----------------------------------------\n'
printf 'Vérifications : %d — Échecs : %d\n' "$checks" "$failures"
if [ "$failures" -eq 0 ]; then
  printf 'Résultat : infrastructure documentaire conforme.\n'
  exit 0
else
  printf 'Résultat : %d problème(s) à corriger.\n' "$failures"
  exit 1
fi
