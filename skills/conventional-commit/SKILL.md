---
name: conventional-commit
description: >
  Write a well-formed conventional commit message for the changes just made. Invoke
  this skill whenever you need to commit code — especially during multi-phase agent
  workflows where each logical task requires its own commit. Also trigger when the
  user says "commit this", "write a commit message", "stage and commit", or similar.
---

# conventional-commit

Produces a correctly-formatted conventional commit message and stages + commits the changes. Designed for use in the Coder agent workflow inside a Lerna monorepo (React + TypeScript/JSX), but works for any project.

---

## Commit message format

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

### Rules for the subject line
- **type** and **scope** are lowercase
- **short description** is in imperative mood, present tense ("add", "fix", "remove" — not "added" or "fixes")
- No period at the end
- Maximum 72 characters total

### Types

| Type | When to use |
|------|-------------|
| `feat` | A new feature or capability visible to users/consumers |
| `fix` | A bug fix |
| `refactor` | Code restructured without changing behaviour |
| `test` | Adding or updating tests only |
| `chore` | Build, tooling, dependency, or config changes |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no logic change |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |

### Scope

Use the **package name** or **feature area** as scope:

| Example | When |
|---------|------|
| `feat(ui):` | New component in the UI package |
| `fix(api-hooks):` | Bug fix in the API hooks package |
| `test(auth):` | Tests for auth feature |
| `chore(deps):` | Dependency update |
| `feat(main-app):` | Feature in the main application |

For a Lerna monorepo, the scope is typically the `name` field from the affected package's `package.json`.

---

## Step-by-step workflow

### 1. Identify what changed

```bash
git diff --staged --name-only   # already staged files
git status                      # unstaged changes
```

If nothing is staged yet, stage the relevant files:
```bash
git add <file1> <file2> ...
# Prefer specific files over `git add .` to avoid accidentally staging unintended files
```

### 2. Group changes by type

One commit per **logical task unit** — not one commit per file and not one giant commit per phase.

Good grouping examples:
```
# Separate commits for implementation and its tests:
feat(ui): add UserCard component with avatar and display name
test(ui): add unit tests for UserCard render behaviour

# Or combined if the test was written test-first:
feat(ui): add UserCard component with test coverage
```

### 3. Write the commit message

Use the format:
```bash
git commit -m "feat(ui): add UserCard component with avatar and display name"
```

For commits that need a body (breaking changes, non-obvious context):
```bash
git commit -m "feat(api-hooks): replace polling with WebSocket in useNotifications

Previous polling implementation caused excessive API load at scale.
WebSocket connection is established once per session and reused.

BREAKING CHANGE: useNotifications no longer accepts a pollingInterval prop."
```

### 4. Breaking changes

If the commit introduces a breaking change (changed API, removed export, changed prop shape):
- Add `BREAKING CHANGE:` in the commit footer with a description
- The subject line may optionally include `!` after the scope: `feat(ui)!:`

---

## Common examples for a React + Lerna monorepo

```
feat(ui): add Tooltip component with keyboard accessibility support
fix(ui): correct hover state colour in Button disabled variant
test(ui): add snapshot and interaction tests for Modal component
refactor(api-hooks): extract error handler into shared utility
chore(ui): update package index to export new Tooltip component
feat(main-app): add /settings/notifications page with preference toggles
fix(main-app): prevent double submit on ContactForm when Enter is pressed
docs(api-hooks): add JSDoc to useUserProfile hook parameters
perf(ui): memoize DataTable row renders to avoid unnecessary re-renders
chore(deps): upgrade react-query from 4.x to 5.x
```

---

## What this skill does NOT do

- Does not decide which files to include — stage them first
- Does not run tests or lint — use `code-autofix` skill before committing
- Does not push — the Orchestrator decides when to push
- Does not create PRs — that is the Orchestrator's responsibility

