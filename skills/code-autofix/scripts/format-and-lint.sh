#!/usr/bin/env bash
# ============================================================
# format-and-lint.sh
# Emulates VS Code "Format on Save" + ESLint auto-fix
# Designed for: web/ monorepo with packages/* structure
#
# Usage:
#   bash format-and-lint.sh <file-or-glob>
#   bash format-and-lint.sh --package <package-name>
#   bash format-and-lint.sh --all
#
# IMPORTANT: Always run from the repo root (web/)
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*"; }
info() { echo -e "  ${CYAN}→${RESET} $*"; }

TARGET=""; PACKAGE_NAME=""; RUN_ALL=false

if [[ "${1:-}" == "--all" ]]; then
  RUN_ALL=true; TARGET='packages/*/src/**/*.{js,jsx,ts,tsx}'
elif [[ "${1:-}" == "--package" ]]; then
  [[ -z "${2:-}" ]] && { err "--package requires a name"; exit 1; }
  PACKAGE_NAME="$2"; TARGET="packages/${PACKAGE_NAME}/src/**/*.{js,jsx,ts,tsx}"
  [[ ! -d "packages/${PACKAGE_NAME}" ]] && { err "Not found: packages/${PACKAGE_NAME}"; exit 1; }
elif [[ -n "${1:-}" ]]; then
  TARGET="$1"
else
  echo "Usage:"
  echo "  $0 <file-or-glob>"
  echo "  $0 --package <name>"
  echo "  $0 --all"
  exit 1
fi

[[ ! -d "packages" ]] && { err "No packages/ dir. Run from web/ root."; exit 1; }

echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Prettier + ESLint  ·  Monorepo Format & Fix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""

[[ -n "$PACKAGE_NAME" ]] && info "Scope: package → ${PACKAGE_NAME}" \
  || ($RUN_ALL && info "Scope: all packages" || info "Scope: ${TARGET}")

# Config detection
PRETTIER_OK=false; ESLINT_OK=false
for cfg in .prettierrc .prettierrc.json .prettierrc.js prettier.config.js .prettierrc.yaml; do
  [[ -f "$cfg" ]] && { PRETTIER_OK=true; info "Prettier config: $cfg"; break; }
done
$PRETTIER_OK || warn "No root Prettier config — will use defaults"

for cfg in eslint.config.js eslint.config.mjs .eslintrc .eslintrc.json .eslintrc.js .eslintrc.yaml; do
  [[ -f "$cfg" ]] && { ESLINT_OK=true; info "ESLint config: $cfg"; break; }
done
$ESLINT_OK || warn "No root ESLint config — per-package configs will be used if present"

echo ""

# Step 1 — Prettier
echo "▶ Step 1/3 · Prettier format"
if npx --no -- prettier --version &>/dev/null 2>&1; then
  PRETTIER_OUT=$(npx prettier --write "$TARGET" --log-level warn 2>&1 || true)
  [[ -n "$PRETTIER_OUT" ]] && echo "$PRETTIER_OUT" | head -20 | while IFS= read -r l; do info "reformatted: $l"; done
  ok "Prettier done"
else
  warn "prettier not found. Run: npm install --save-dev prettier"
fi
echo ""

# Step 2 — ESLint fix
echo "▶ Step 2/3 · ESLint auto-fix"
ESLINT_BIN=false
npx --no -- eslint --version &>/dev/null 2>&1 && ESLINT_BIN=true

if $ESLINT_BIN; then
  set +e; npx eslint --fix "$TARGET" 2>&1; FIX_EXIT=$?; set -e
  [[ $FIX_EXIT -eq 0 ]] && ok "ESLint auto-fix done — no errors remaining" \
    || warn "Some errors could not be auto-fixed (see Step 3)"
else
  warn "eslint not found. Run: npm install --save-dev eslint"
fi
echo ""

# Step 3 — Verify
echo "▶ Step 3/3 · ESLint verify"
if $ESLINT_BIN; then
  set +e; VERIFY_OUT=$(npx eslint "$TARGET" 2>&1); VERIFY_EXIT=$?; set -e
  if [[ $VERIFY_EXIT -eq 0 ]]; then
    ok "Clean — zero lint errors"
  else
    echo ""; err "Remaining errors (manual fixes needed):"
    echo "─────────────────────────────────────────────────────────"
    echo "$VERIFY_OUT"
    echo "─────────────────────────────────────────────────────────"
    warn "See: .claude/skills/prettier-eslint/references/common-eslint-fixes.md"
  fi
else
  warn "(Skipped — eslint not available)"
fi

echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done."; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""