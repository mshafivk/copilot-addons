# Coding Guidelines

> This file is the shared reference for all agents in the pipeline. The Orchestrator distributes it to Coder and Reviewer agents. It must be kept up to date as the project evolves.

---

## Language & Runtime
- TypeScript strict mode is mandatory — `"strict": true` in `tsconfig.json`
- No `any` type under any circumstance — use `unknown` + type narrowing if needed
- Target ES2020+

---

## React
- Functional components only — no class components
- Named exports for all components — no default exports
- Props interface defined in the same file or a co-located `types.ts`
- Prefer composition over prop drilling — use Context for shared state
- Avoid `useEffect` for data fetching — use React Query or SWR hooks
- Keep components focused — if a component exceeds ~150 lines, split it

---

## Styling
- Tailwind CSS utility classes only — no inline styles, no CSS modules
- Design tokens defined as CSS custom properties in `globals.css` — do not hardcode colours or spacing values
- Responsive design is required for all UI components (mobile-first)

---

## File & Folder Naming
- Components: `PascalCase.tsx` (e.g., `LoginForm.tsx`)
- Hooks: `camelCase` prefixed with `use` (e.g., `useAuth.ts`)
- Utilities: `camelCase.ts` (e.g., `formatDate.ts`)
- Types: `types.ts` co-located with feature
- Tests: co-located with source, suffix `.test.tsx` or `.test.ts`
- Feature folders: `src/features/<feature-name>/`

---

## Imports
- Use absolute imports via `@/` alias — no relative `../../` paths
- Group imports: external libraries → internal modules → relative files
- Remove all unused imports before committing

---

## Git & Commits
- Conventional commit format is mandatory (see Coder agent for full reference)
- One logical change per commit — do not bundle unrelated changes
- Never commit directly to `main`
- Branch naming: `feature/<feature-name>`, `fix/<issue>`, `chore/<task>`

---

## Testing
- Test files co-located with source
- Use Vitest or Jest — follow existing project setup
- Coverage target: 80% for new code
- Test behaviour, not implementation details
- Use `data-testid` attributes for DOM queries in tests and Playwright

---

## Accessibility
- Semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<section>`, etc.)
- All interactive elements must have accessible labels (`aria-label`, `aria-describedby`, or visible text)
- Keyboard navigation must work for all interactive components
- Colour contrast must meet WCAG AA minimum

---

## Code Hygiene
- No `console.log` in committed code — use a logger utility if needed
- No commented-out code blocks
- No unused variables or imports
- No TODO comments without a ticket reference

---

## Error Handling
- Never swallow errors silently
- Always handle loading, error, and empty states in UI components
- API errors must surface meaningful messages to the user
- Use typed error objects — not raw `catch (e: any)`

---

## Monorepo Package Boundaries
- `common-components` — shared UI components only, no feature logic
- `api-hooks` — data fetching hooks only, no UI
- `main-app` — feature implementations, pages, routing
- Do not import from `main-app` inside `common-components` or `api-hooks`
