# copilot-addons

A collection of useful **skills**, **custom agents**, **prompts**, and **custom instructions** that extend GitHub Copilot's capabilities in your projects.

---

## What's inside

### Skills

Skills are reusable, self-contained instruction sets that tell a Copilot agent exactly how to perform a specific task. Drop a `SKILL.md` into your repository and reference it in your agent session.

| Skill | Description |
|---|---|
| [`code-autofix`](./skills/code-autofix/) | Automatically runs ESLint `--fix` and Prettier `--write` on any file you just created or edited. Ideal for multi-step agent workflows where you want to prevent lint debt from accumulating across files. |

---

## How to use

### Using a skill

1. Copy the skill folder (e.g. `skills/code-autofix/`) into your own repository, or reference it directly from this repo.
2. In your Copilot agent session, instruct the agent to use the skill:
   > "Use the `code-autofix` skill to fix the files I just edited."
3. The agent will follow the step-by-step workflow defined in the skill's `SKILL.md`.

---

## Repository structure

```
copilot-addons/
└── skills/
    └── code-autofix/   # ESLint + Prettier auto-fix skill
        └── SKILL.md
```

---

## Contributing

Feel free to open a pull request to add new skills, agents, prompts, or custom instructions. Please include a clear description of what the addon does and when it should be used.
