# copilot-addons

A collection of **custom agents**, **skills**, and **prompts** that extend GitHub Copilot's capabilities in your projects.

---

## What's inside

### Custom Agents (Chat Modes)

Agents are specialised GitHub Copilot chat modes. Each agent has a focused role, a restricted tool set, and a detailed system prompt. Together they form a complete multi-agent orchestration pipeline for feature development.

| Agent | File | Role |
|-------|------|------|
| Orchestrator | `agents/01-orchestrator.chatmode.md` | Coordinates end-to-end delivery. Delegates to all other agents. Never writes code. |
| Planner | `agents/02-planner.chatmode.md` | Breaks down a feature request into structured requirements (`docs/ai/requirements.md`). |
| Architect | `agents/03-architect.chatmode.md` | Translates requirements into a phased implementation plan (`docs/ai/implementation-plan.md`). |
| Coder | `agents/04-coder.chatmode.md` | Implements a phase: writes code + tests (TDD), runs autofix, commits with conventional format. |
| Reviewer | `agents/05-reviewer.chatmode.md` | Reviews Coder output against the plan and coding guidelines before tests run. |
| Test Agent | `agents/06-test-agent.chatmode.md` | Verifies the feature end-to-end using Playwright MCP. |

### Skills

Skills are reusable, self-contained instruction sets that tell an agent exactly how to perform a specific task.

| Skill | File | Description |
|-------|------|-------------|
| `code-autofix` | `skills/code-autofix/SKILL.md` | Runs ESLint `--fix` and Prettier `--write` after every file write. |
| `conventional-commit` | `skills/conventional-commit/SKILL.md` | Stages and commits changes using conventional commit format. |
| `security-review` | `skills/security-review/SKILL.md` | OWASP-aligned security checklist for changed code before merging. |
| `playwright-verify` | `skills/playwright-verify/SKILL.md` | Browser-based feature verification using Playwright MCP. |

---

## Multi-agent pipeline overview

```
User request
    │
    ▼
┌─────────────┐
│ Orchestrator │  ← manages the whole flow, creates PR at the end
└──────┬──────┘
       │
       ├─► Planner ──────────► docs/ai/requirements.md
       │
       ├─► Architect ─────────► docs/ai/implementation-plan.md
       │
       └─► Per phase:
               │
               ├─► Coder ──── code + tests + code-autofix + conventional-commit
               │
               ├─► Reviewer ── plan compliance + quality + security-review (if needed)
               │         │
               │         └── CHANGES REQUESTED ──► back to Coder (max 2 retries)
               │
               └─► Test Agent ── playwright-verify
                         │
                         └── FAILED ──► back to Coder (max 2 retries)
```

### Shared artifact locations

Every agent reads and writes to `docs/ai/` in the repository root:

| File | Written by | Purpose |
|------|-----------|---------|
| `docs/ai/requirements.md` | Planner | Functional/non-functional requirements + API-to-UI mapping |
| `docs/ai/implementation-plan.md` | Architect | Technical plan, phases, acceptance criteria |
| `docs/ai/phase-status.md` | Orchestrator | Phase-by-phase progress tracking |

---

## How to use

### Step 1 — Copy agents to your project

Copy the `agents/` folder contents to `.github/chatmodes/` in your repository:

```bash
cp agents/*.chatmode.md /path/to/your-project/.github/chatmodes/
```

GitHub Copilot in VS Code discovers chat modes from `.github/chatmodes/*.chatmode.md`.

### Step 2 — Copy skills to your project

Copy the skill folders you need to your repository:

```bash
cp -r skills/code-autofix       /path/to/your-project/skills/
cp -r skills/conventional-commit /path/to/your-project/skills/
cp -r skills/security-review    /path/to/your-project/skills/
cp -r skills/playwright-verify  /path/to/your-project/skills/
```

### Step 3 — Configure Playwright MCP (for Test Agent)

Add Playwright MCP to your VS Code MCP configuration (`.vscode/mcp.json`):

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Install the MCP server:
```bash
npx @playwright/mcp@latest
```

### Step 4 — Start a feature

1. Open GitHub Copilot Chat in VS Code
2. Switch to **Orchestrator** mode from the chat mode picker
3. Describe your feature — the Orchestrator will guide you through the full pipeline

---

## Tailored for React + Lerna monorepos

The agents and skills are tuned for:
- **React JSX** packages (functional components, hooks)
- **TypeScript** packages (strict types, interfaces)
- **Lerna monorepo** structure (per-package ESLint/Prettier, cross-package imports)
- **ESLint + Prettier** (code-autofix skill handles both)
- **Jest** unit tests co-located with source files

---

## Repository structure

```
copilot-addons/
├── agents/
│   ├── 01-orchestrator.chatmode.md
│   ├── 02-planner.chatmode.md
│   ├── 03-architect.chatmode.md
│   ├── 04-coder.chatmode.md
│   ├── 05-reviewer.chatmode.md
│   └── 06-test-agent.chatmode.md
└── skills/
    ├── code-autofix/
    │   └── SKILL.md
    ├── conventional-commit/
    │   └── SKILL.md
    ├── security-review/
    │   └── SKILL.md
    └── playwright-verify/
        └── SKILL.md
```

---

## Contributing

Open a pull request to add new agents, skills, or prompts. Include a clear description of the role/purpose and when it should be used.
