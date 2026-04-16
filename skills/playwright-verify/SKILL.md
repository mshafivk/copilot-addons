---
name: playwright-verify
description: >
  Use Playwright MCP to run browser-based verification of a feature or acceptance
  criteria. Invoke this skill inside the Test Agent when verifying a completed phase,
  or directly when the user says "verify this in the browser", "test this with
  Playwright", "run a browser check", "verify the UI", or similar.
---

# playwright-verify

Runs end-to-end browser verification using Playwright MCP tools. Designed for use inside the Test Agent workflow, but usable standalone for ad-hoc UI verification.

---

## Prerequisites

### Playwright MCP must be configured

Playwright MCP is a Model Context Protocol server that gives the agent browser automation capabilities. It must be added to your VS Code Copilot MCP configuration.

**Install**:
```bash
npx @playwright/mcp@latest
```

**VS Code MCP config** (`.vscode/mcp.json` or user settings) — always use `--headless` flag:
```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless"]
    }
  }
}
```

### The application must be running

Start the app before invoking this skill:
```bash
# Lerna monorepo — start the target app:
yarn lerna run start --scope=<app-name>

# Or from the app directory:
yarn run start
```

Confirm it is ready by checking terminal output (`terminalLastCommand`) for a success message.

---

## Playwright MCP tool reference

| Tool | Purpose | Example |
|------|---------|---------|
| `browser_navigate` | Navigate to a URL | `browser_navigate({ url: "http://localhost:8000/login" })` |
| `browser_screenshot` | Capture current page state | `browser_screenshot({ name: "login-page" })` |
| `browser_click` | Click an element | `browser_click({ selector: "button[type=submit]" })` |
| `browser_fill` | Fill an input field | `browser_fill({ selector: "#email", value: "user@example.com" })` |
| `browser_select_option` | Select a dropdown option | `browser_select_option({ selector: "#role", value: "admin" })` |
| `browser_wait_for` | Wait for element or condition | `browser_wait_for({ selector: ".success-banner" })` |
| `browser_evaluate` | Execute JS in page context | Use sparingly — only for assertions not achievable via selectors |
| `browser_close` | Close the browser | Always call at the end |

---

## Step-by-step verification workflow

### 1. Plan scenarios before executing

Map each acceptance criterion to a concrete browser scenario:

```
AC-001: User can log in with valid credentials
  → Navigate to /login
  → Fill: #email = "test@example.com", #password = "Password123"
  → Click: button[type=submit]
  → Wait for: .dashboard-header (or URL change to /dashboard)
  → Screenshot: login-success

AC-002: Login form shows error for invalid credentials
  → Navigate to /login
  → Fill: #email = "test@example.com", #password = "wrong"
  → Click: button[type=submit]
  → Wait for: .error-message
  → Assert: error text contains "Invalid credentials"
  → Screenshot: login-error
```

### 2. Choose reliable selectors

Prefer selectors in this order (most stable → least stable):
1. `data-testid` attributes: `[data-testid="submit-button"]`
2. ARIA roles and labels: `role=button[name="Submit"]`
3. Semantic elements: `button[type=submit]`, `input[name=email]`
4. CSS classes: `.login-form__submit` (only if stable)
5. Text content: `text=Submit` (fragile — avoid for critical paths)

**Avoid**: nth-child selectors, deeply nested paths, auto-generated class names.

### 3. Execute the happy path

For each scenario:
```
1. browser_navigate → target URL
2. browser_screenshot → "before-<scenario-name>" (baseline)
3. browser_fill / browser_click / browser_select_option → interactions
4. browser_wait_for → expected result element
5. browser_screenshot → "after-<scenario-name>" (evidence)
```

### 4. Execute error and edge cases

- Empty required fields → submit → assert validation messages appear
- Network errors → if possible, test with devtools offline mode or mock
- Loading states → assert spinner/skeleton appears before data loads

### 5. Spot-check for regressions

Navigate to 2–3 pages adjacent to the changed feature:
- No blank pages
- No visible JS errors in the browser console (`browser_evaluate({ script: "window.__errors" })` if instrumented)
- Layout is not broken

---

## Evidence and reporting

Always collect:
- A screenshot **before** and **after** each key interaction
- Screenshot filenames should be descriptive: `ac-001-login-success.png`, `ac-002-error-shown.png`

Report format:

```markdown
## Playwright Verification Report

**Feature**: <name>
**Branch**: feature/<name>
**App URL**: http://localhost:8000
**Date**: YYYY-MM-DD

### Results

| AC | Scenario | Result | Screenshot |
|----|----------|--------|------------|
| AC-001 | Valid login redirects to dashboard | ✅ PASS | ac-001-login-success.png |
| AC-002 | Invalid login shows error message | ✅ PASS | ac-002-error-shown.png |
| AC-003 | Remember me checkbox persists session | ❌ FAIL | ac-003-cookie-check.png |

### Failures

**AC-003 — Remember me persists session**
- Expected: Session cookie with `expires` set 30 days in future after checking "Remember me"
- Actual: Cookie created but with session lifetime (no `expires` attribute)
- Suspected cause: `createSession` in `useLogin` hook does not pass `persistent: true` flag when checkbox is checked
- Suggested fix: Check `apps/main-app/src/hooks/useLogin.ts` — the checkbox value may not be passed through
```

---

## Cleanup

Always close the browser and stop the dev server after verification:

```bash
# Stop dev server (replace port):
kill $(lsof -t -i:8000) 2>/dev/null || true
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `browser_navigate` times out | Confirm dev server is running and listening on the correct port |
| Selector not found | Inspect the page with `browser_screenshot` first; check if element has `data-testid` |
| Page shows blank / error | Check `problems` tool for compile errors; restart the dev server |
| MCP tools not available | Ensure Playwright MCP server is configured in VS Code MCP settings |
| `ECONNREFUSED` on localhost | Dev server is not running — start it first |

