---
name: code-autofix
description: >
  Automatically format and lint all generated or modified JavaScript/TypeScript/React code
  using the project's existing Prettier and ESLint configuration — exactly like "Format on Save"
  in VS Code. Use this skill whenever Claude generates, edits, or scaffolds any .js, .ts, .jsx,
  .tsx, .mjs, or .cjs file in any package of the monorepo. This skill MUST run after every
  code-writing task in JS/TS projects, even if the user doesn't explicitly ask for formatting.
  It ensures zero formatting drift and zero lint errors in all agent-produced output. Triggers
  include: writing React components, creating utilities, generating hooks, scaffolding modules,
  editing existing files, and any file output destined for a JS/TS/React codebase inside a
  monorepo workspace (Lerna, npm workspaces, yarn workspaces).
---

# Prettier + ESLint Skill

Emulates VS Code's **Format on Save** + **ESLint auto-fix** behaviour for every file Claude
writes or modifies. After generating code, always run this skill before presenting output.

---

## Monorepo Structure

This skill is designed for the following monorepo layout:

```
web/                          ← repo root (run commands from here)
├── package.json              ← workspaces config (Lerna / npm / yarn)
├── lerna.json                ← (if Lerna)
├── .prettierrc               ← root Prettier config (applies to all packages)
├── eslint.config.js          ← root ESLint config (may extend per-package)
│
└── packages/
    ├── package-1/
    │   ├── package.json
    │   ├── .eslintrc.*       ← optional package-level ESLint override
    │   └── src/
    │       ├── components/   ← .jsx / .tsx files
    │       └── utils/        ← .js / .ts files
    │
    └── package-2/
        ├── package.json
        ├── .eslintrc.*       ← optional package-level ESLint override
        └── src/
            ├── components/
            └── utils/
```

**Config resolution priority** (highest → lowest):

1. Package-level config (e.g., `packages/package-1/.eslintrc.json`)
2. Root-level config (e.g., `web/eslint.config.js`)
3. Tool defaults

Prettier and ESLint both walk UP the directory tree from the file being processed,
so they always pick up the nearest applicable config automatically.

---

## Prerequisites

The project must already have:

- `prettier` installed (root `node_modules` via workspaces, or per-package)
- `eslint` installed (root `node_modules` via workspaces, or per-package)
- A Prettier config at root or package level
- An ESLint config at root or package level

> Claude does NOT install or create these configs — it uses whatever the project already has.
> If configs are missing, warn the user and skip the relevant step.

---

## Core Workflow

After writing or modifying any JS/TS/JSX/TSX file, run **all three steps in order**.
**Always run from the repo root (`web/`)** — this ensures workspace `node_modules` are found
and glob patterns resolve correctly across all packages.

### Step 1 — Prettier Format

```bash
# Single file (always use path relative to repo root)
npx prettier --write packages/package-1/src/components/MyComponent.tsx

# All files in one package
npx prettier --write "packages/package-1/src/**/*.{js,jsx,ts,tsx}"

# All files across all packages
npx prettier --write "packages/*/src/**/*.{js,jsx,ts,tsx}"
```

### Step 2 — ESLint Auto-fix

```bash
# Single file
npx eslint --fix packages/package-1/src/components/MyComponent.tsx

# All files in one package
npx eslint --fix "packages/package-1/src/**/*.{js,jsx,ts,tsx}"

# All files across all packages
npx eslint --fix "packages/*/src/**/*.{js,jsx,ts,tsx}"
```

- Applies all auto-fixable rules from whichever config is closest to the file.
- Remaining errors are **reported to the user** — do not silently ignore them.

### Step 3 — Verify (No Remaining Errors)

```bash
npx eslint packages/package-1/src/components/MyComponent.tsx
```

Run ESLint **without `--fix`** after fixing. If errors remain:

1. List them clearly (rule name + file + line number).
2. Attempt to fix them in the source code.
3. Re-run Steps 1–3 until clean, or tell the user which rules need manual attention.

---

## Automation Script

Use `scripts/format-and-lint.sh` for single or batch runs.
**Always run from `web/` (repo root).**

```bash
# Single file
bash .claude/skills/prettier-eslint/scripts/format-and-lint.sh \
  packages/package-1/src/components/MyComponent.tsx

# Entire package
bash .claude/skills/prettier-eslint/scripts/format-and-lint.sh \
  "packages/package-1/src/**/*.{js,jsx,ts,tsx}"

# All packages at once
bash .claude/skills/prettier-eslint/scripts/format-and-lint.sh \
  "packages/*/src/**/*.{js,jsx,ts,tsx}"
```

The script accepts a **package name shortcut** too:

```bash
# Shortcut — formats + lints everything in a named package
bash .claude/skills/prettier-eslint/scripts/format-and-lint.sh --package package-1
```

---

## Behaviour Rules

| Scenario                             | Behaviour                            |
| ------------------------------------ | ------------------------------------ |
| Root Prettier config exists          | Use it for all packages              |
| Package-level Prettier config exists | Overrides root for that package      |
| No Prettier config anywhere          | Run with defaults, warn user         |
| Root ESLint config exists            | Use it for all packages              |
| Package-level ESLint config exists   | Merges with / overrides root         |
| No ESLint config anywhere            | Skip ESLint, warn user               |
| Auto-fixable lint errors             | Fix silently                         |
| Non-fixable lint errors              | Report: rule name + file + line      |
| Mixed JS + TS in same package        | Handle both — no extension filtering |
| Files changed by Prettier            | Note which files were reformatted    |
| Already clean                        | Confirm "✓ Formatted and lint-clean" |

---

## File Types

Apply this skill to these extensions only:

```
.js  .jsx  .ts  .tsx  .mjs  .cjs
```

Do NOT run on: `.json`, `.md`, `.css`, `.html` — unless the user explicitly asks.

---

## Determining Which Package a File Belongs To

When the agent writes a file, it knows the full path. Extract the package name like so:

```
File:    packages/package-2/src/hooks/useAuth.ts
Package: package-2
Root:    web/
```

Always pass the full path from repo root to the tools — never `cd` into a package directory,
as this may cause workspace `node_modules` resolution to fail.

---

## Integration with Agent Prompt Pipeline

In your GitHub Copilot prompt pipeline, add this as the **final gate in Stage 3** (Code Generation):

```markdown
## Post-Generation Quality Gate

After writing all files, run the prettier-eslint skill from the repo root (web/):

1. Format: npx prettier --write <files>
2. Fix: npx eslint --fix <files>
3. Verify: npx eslint <files> ← must exit 0 before output is presented

Scope <files> to only the packages touched in this task.
Do not present output until all three steps pass clean.
```

---

## Config Discovery Debug Commands

If unsure which config is active for a file:

```bash
# Run from web/ (repo root)

# Which Prettier config applies?
npx prettier --find-config-path packages/package-1/src/components/Foo.tsx

# Which ESLint config applies?
npx eslint --print-config packages/package-1/src/components/Foo.tsx
```

---

## Reference Files

- `references/common-eslint-fixes.md` — Manual fixes for common non-auto-fixable ESLint errors
- `scripts/format-and-lint.sh` — Automation script (single file, package glob, or --package shortcut)
