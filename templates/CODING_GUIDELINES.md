# Coding Guidelines

> Shared reference for all agents in the pipeline. The Orchestrator passes this file to
> Coder and Reviewer agents at dispatch time. Keep it up to date as conventions evolve.
>
> **How to use**: Copy this file to your repository root and customise it for your project.

---

## Language & Runtime

- JavaScript packages: ES2020+, JSX (`.jsx`)
- TypeScript packages: strict mode mandatory — `"strict": true` in `tsconfig.json`
- No `any` type in TypeScript — use `unknown` + type narrowing if needed
- No `// @ts-ignore` or `// @ts-nocheck` — fix the underlying type issue instead

---

## React

- Functional components only — no class components
- Hooks for all state (`useState`, `useReducer`) and side effects (`useEffect`)
- Props destructured in the function signature
- Prefer composition over prop drilling — use Context for cross-cutting shared state
- Avoid `useEffect` for data fetching — use the project's existing API hook pattern
- Keep components focused — if a component exceeds ~150 lines, consider splitting it
- Named exports for components — default exports only when the module convention requires it

---

## Styling

- Use Less (`.less` files) — no inline styles, no CSS-in-JS, no Tailwind
- Co-locate the Less file with its component: `Button.tsx` → `Button.less`
- Import the Less file at the top of the component: `import './Button.less'`
- Design tokens (colours, spacing, breakpoints) live in the shared tokens file — do not hardcode values
- Responsive design required for all UI components — mobile-first breakpoints
- BEM or the project's existing class-naming convention for Less selectors

---

## File & Folder Naming

- Components: `PascalCase.tsx` / `PascalCase.jsx` (e.g. `LoginForm.tsx`)
- Hooks: `camelCase` prefixed with `use` (e.g. `useAuth.ts`)
- Utilities: `camelCase.ts` / `camelCase.js` (e.g. `formatDate.ts`)
- Types: `types.ts` co-located with the feature or component
- Tests: co-located with source, suffix `.test.tsx` or `.test.ts`
- Less files: co-located with component, same base name (e.g. `Button.less`)
- Feature folders: `src/features/<feature-name>/` or follow the existing monorepo structure

---

## Imports

- Group imports: external libraries → internal packages (by package name) → relative files
- Use package name imports for cross-package references — never relative `../../` paths across package boundaries:
  ```
  ✅ import { Button } from '@my-org/common-components'
  ❌ import { Button } from '../../../common-components/src/Button'
  ```
- Remove all unused imports before committing (enforced by ESLint)
- Run `code-autofix` skill after every file write to auto-fix import ordering

---

## Monorepo Package Boundaries

| Package | What belongs here |
|---------|-------------------|
| `packages/common-components` | Shared, reusable UI components only — no feature logic |
| `packages/api-hooks` | Data-fetching hooks only — no UI rendering |
| `apps/<app-name>` | Feature implementations, pages, routing, app-level state |

- Do not import from an app package inside a shared package
- New shared components must be exported via the package's `index.ts` / `index.js` barrel
- Cross-package dependency changes require `package.json` and `yarn.lock` updates

---

## Git & Commits

- Conventional commit format is mandatory (see `skills/conventional-commit/SKILL.md`)
- One logical change per commit — do not bundle unrelated changes
- Never commit directly to `main`
- Branch naming: `feature/<feature-name>`, `fix/<issue>`, `chore/<task>`
- `yarn.lock` must be committed alongside any `package.json` dependency change

---

## Testing

- Test files co-located with source: `Component.test.tsx` next to `Component.tsx`
- Use the project's existing test runner (Jest or Vitest — check root `package.json`)
- Coverage target: 80% for all new code
- Test behaviour, not implementation details — tests should survive internal refactors
- Use `data-testid` attributes for DOM queries in both unit tests and Playwright

### What to test per unit type

| Unit | Test for |
|------|---------|
| Component | Renders correctly, handles props, user interactions, loading/error/empty states |
| Hook | Return values, state changes, error boundaries, side effect triggers |
| Utility | Output for valid inputs, edge cases, error cases |

---

## Accessibility

- Semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<section>`, `<header>`, etc.)
- All interactive elements must have accessible labels (`aria-label`, `aria-describedby`, or visible text)
- Keyboard navigation must work for all interactive components (Tab, Enter, Space, Escape)
- Colour contrast must meet WCAG 2.1 AA minimum
- Use `data-testid` attributes on key interactive elements to support both tests and Playwright

---

## Code Hygiene

- No `console.log`, `console.error`, or `debugger` in committed code
- No commented-out code blocks
- No unused variables or imports
- No `TODO` / `FIXME` comments without a ticket reference
- No magic strings — use named constants

---

## Error Handling

- Never swallow errors silently (empty `catch` blocks)
- Always handle loading, error, and empty states in UI components
- API errors must surface meaningful messages to the user
- Use typed error objects — not `catch (e: any)`
- Validate user input at the boundary; trust internal code

---

## TypeScript Specifics

- Prefer `interface` over `type` for object shapes
- Export types that consumers will need
- Avoid optional chaining as a shortcut around proper null handling — check whether `null` can actually occur
- Props interfaces defined in the same file or a co-located `types.ts`

---

## Security

- No secrets, tokens, or API keys in source files — use environment variables
- No PII logged to console or analytics
- Validate user input before use — do not trust data from `window.location`, URL params, or form fields without checks
- No `dangerouslySetInnerHTML` without explicit sanitisation (e.g. `DOMPurify`)
- See `skills/security-review/SKILL.md` for the full security checklist

