# copilot-addons

A collection of **custom agents**, **skills**, and **prompts** that extend GitHub Copilot's capabilities in your projects.

---

## What's inside

### Custom Agents

Agents are GitHub Copilot custom agents (previously called custom chat modes). Each has a focused role, a restricted tool set, and a detailed system prompt. Together they form a complete multi-agent orchestration pipeline for feature development.

> **Format**: `.agent.md` files — the current VS Code Copilot format. Discovered from the path(s) configured in the `chat.agentFilesLocations` VS Code setting (default: `.github/agents/`).

**Frontmatter schema reference**

```yaml
---
description: Shown in the agent picker (Orchestrator only — pipeline agents are hidden)
tools: [codebase, editFiles, runCommands, ...]  # platform-enforced restrictions
model: claude-opus-4-7                           # pinned model for this agent role
user-invocable: true                             # false = hidden from picker, subagent only
agents: [02-planner, 03-architect, ...]          # restricts which agents this one can invoke
handoffs:                                        # UI routing buttons shown in chat
  - agent: 02-planner
    label: "→ Start Planning"
    prompt: "Pre-filled prompt sent to the target agent"
---
```

| Agent | File | Role |
|-------|------|------|
| Orchestrator | `agents/01-orchestrator.agent.md` | Coordinates end-to-end delivery. Delegates to all other agents. Never writes code. |
| Planner | `agents/02-planner.agent.md` | Breaks down a feature request into structured requirements (`docs/ai/requirements.md`). |
| Architect | `agents/03-architect.agent.md` | Translates requirements into a phased implementation plan (`docs/ai/implementation-plan.md`). |
| Coder | `agents/04-coder.agent.md` | Implements a phase: writes code + tests (TDD), runs autofix, commits with conventional format. |
| Reviewer | `agents/05-reviewer.agent.md` | Reviews Coder output against the plan and coding guidelines before tests run. |
| Test Agent | `agents/06-test-agent.agent.md` | Verifies the feature end-to-end using Playwright MCP. |

### Skills

Skills are reusable, self-contained instruction sets that tell an agent exactly how to perform a specific task.

| Skill | File | Description |
|-------|------|-------------|
| `code-autofix` | `skills/code-autofix/SKILL.md` | Runs ESLint `--fix` and Prettier `--write` after every file write. |
| `conventional-commit` | `skills/conventional-commit/SKILL.md` | Stages and commits changes using conventional commit format. |
| `security-review` | `skills/security-review/SKILL.md` | OWASP-aligned security checklist for changed code before merging. |
| `playwright-verify` | `skills/playwright-verify/SKILL.md` | Browser-based feature verification using Playwright MCP. |

### Templates

| Template | File | Description |
|----------|------|-------------|
| `CODING_GUIDELINES` | `templates/CODING_GUIDELINES.md` | Customisable coding standards reference shared across all agents. Copy to your repository root and adapt to your project. |

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
| `docs/ai/requirements.md` | Planner | Requirements + acceptance checklist (Section 10) for Test Agent |
| `docs/ai/implementation-plan.md` | Architect | Technical plan, phases, acceptance criteria |
| `docs/ai/phase-status.md` | Orchestrator | Phase-by-phase progress tracking |
| `docs/ai/phase-N-summary.md` | Coder | Per-phase implementation summary, files changed, commit refs |
| `docs/ai/test-report.md` | Test Agent | E2E results, performance, accessibility, sign-off |
| `docs/ai/session-log.md` | Orchestrator | Running log of all dispatches and outcomes |

---

## How to use

### Step 1 — Copy agents to your project

Copy the `agents/` folder contents to `.github/agents/` in your repository:

```bash
mkdir -p /path/to/your-project/.github/agents
cp agents/*.agent.md /path/to/your-project/.github/agents/
```

VS Code Copilot discovers agents from the path(s) set in `chat.agentFilesLocations` (default: `.github/agents/`). You can verify or change this in VS Code settings.

### Step 2 — Copy and customise CODING_GUIDELINES

```bash
cp templates/CODING_GUIDELINES.md /path/to/your-project/CODING_GUIDELINES.md
```

Edit it to match your project's actual conventions (styling framework, import alias, test runner, package names, etc.). All agents reference this file — keeping it accurate is critical.

### Step 3 — Copy skills to your project

```bash
cp -r skills/code-autofix        /path/to/your-project/skills/
cp -r skills/conventional-commit /path/to/your-project/skills/
cp -r skills/security-review     /path/to/your-project/skills/
cp -r skills/playwright-verify   /path/to/your-project/skills/
```

Add the `skills/` folder to VS Code's skill discovery by adding this to your workspace settings (`.vscode/settings.json`):

```json
{
  "chat.agentSkillsLocations": ["skills"]
}
```

Once configured, skills are available as **slash commands** in Copilot Chat:
- `/code-autofix` — fix lint and formatting on edited files
- `/conventional-commit` — stage and commit with conventional format
- `/security-review` — run OWASP security checklist
- `/playwright-verify` — browser verification via Playwright MCP

### Step 4 — Configure Playwright MCP (for Test Agent)

Add Playwright MCP to your VS Code MCP configuration (`.vscode/mcp.json`):

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

### Step 5 — Verify model availability

The agents specify models in their frontmatter. Check that these models are available in your Copilot subscription under **VS Code Settings → GitHub Copilot → Chat: Models**. If a model is unavailable, update the `model:` field in the relevant `.agent.md` file to one that is.

| Agent | Model | Reason |
|-------|-------|--------|
| Orchestrator | `claude-opus-4-7` | Complex multi-step coordination and reasoning |
| Architect | `claude-opus-4-7` | Technical design decisions and trade-off analysis |
| Planner | `claude-sonnet-4-6` | Document analysis and structured writing |
| Coder | `claude-sonnet-4-6` | Fast, high-quality code generation |
| Reviewer | `claude-sonnet-4-6` | Diff analysis and pattern recognition |
| Test Agent | `claude-sonnet-4-6` | Browser interaction and failure diagnosis |

### Step 6 — Start a feature

1. Open GitHub Copilot Chat in VS Code
2. Select **Orchestrator** from the agent picker (pipeline agents are hidden from the picker — they are only reachable via Orchestrator handoff buttons)
3. Describe your feature — use the handoff buttons to route between agents

---

## Workspace layout (your project)

```
your-project/
├── .github/
│   └── agents/                        ← VS Code Copilot discovers agents here
│       ├── 01-orchestrator.agent.md
│       ├── 02-planner.agent.md
│       ├── 03-architect.agent.md
│       ├── 04-coder.agent.md
│       ├── 05-reviewer.agent.md
│       └── 06-test-agent.agent.md
├── .vscode/
│   └── mcp.json                       ← Playwright MCP server config
├── skills/                            ← referenced by agents during sessions
│   ├── code-autofix/SKILL.md
│   ├── conventional-commit/SKILL.md
│   ├── security-review/SKILL.md
│   └── playwright-verify/SKILL.md
├── CODING_GUIDELINES.md               ← shared by all agents (repo root)
├── docs/
│   └── ai/                            ← written by agents at runtime
│       ├── requirements.md
│       ├── implementation-plan.md
│       ├── phase-status.md
│       ├── phase-N-summary.md
│       ├── test-report.md
│       └── session-log.md
├── packages/
├── apps/
└── lerna.json
```

---

## Tailored for React + Lerna monorepos

The agents and skills are tuned for:
- **React JSX** packages (functional components, hooks)
- **TypeScript** packages (strict types, interfaces)
- **Lerna monorepo** structure (per-package ESLint/Prettier, cross-package imports)
- **Less** for styling (`.less` files co-located with components)
- **Yarn** as the package manager
- **Jest** unit tests co-located with source files

---

## Repository structure

```
copilot-addons/
├── agents/
│   ├── 01-orchestrator.agent.md
│   ├── 02-planner.agent.md
│   ├── 03-architect.agent.md
│   ├── 04-coder.agent.md
│   ├── 05-reviewer.agent.md
│   └── 06-test-agent.agent.md
├── skills/
│   ├── code-autofix/SKILL.md
│   ├── conventional-commit/SKILL.md
│   ├── security-review/SKILL.md
│   └── playwright-verify/SKILL.md
└── templates/
    └── CODING_GUIDELINES.md           ← copy to your repo root and customise
```

---

## Contributing

Open a pull request to add new agents, skills, or prompts. Include a clear description of the role/purpose and when it should be used.
