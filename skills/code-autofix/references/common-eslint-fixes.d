# Common Non-Auto-Fixable ESLint Errors — Manual Fix Guide

ESLint can auto-fix ~30% of rules. The rest require human (or agent) intervention.
This file covers the most common ones in React + TypeScript projects.

---

## `@typescript-eslint/no-explicit-any`

**Error:** Unexpected `any`. Specify a different type.

**Fix:** Replace `any` with a proper type or `unknown`.
```ts
// ✗
function process(data: any) {}

// ✓
function process(data: unknown) {}
// or define the shape:
function process(data: { id: string; value: number }) {}
```

---

## `@typescript-eslint/no-unused-vars`

**Error:** 'myVar' is defined but never used.

**Fix:** Remove the variable, or prefix with `_` if intentionally unused.
```ts
// ✗
const unused = computeSomething();

// ✓ — intentionally unused (e.g., destructuring)
const [_first, second] = arr;
```

---

## `react-hooks/exhaustive-deps`

**Error:** React Hook useEffect has missing dependencies: 'myProp'.

**Fix:** Add the missing dependency, or use `useCallback`/`useMemo` to stabilise refs.
```ts
// ✗
useEffect(() => {
  doSomething(myProp);
}, []); // missing myProp

// ✓
useEffect(() => {
  doSomething(myProp);
}, [myProp]);
```

---

## `react/prop-types` (JS only)

**Error:** 'children' is missing in props validation.

**Fix:** Add PropTypes, or (better) migrate to TypeScript with typed props.
```ts
// ✓ TypeScript approach
interface Props {
  children: React.ReactNode;
}
function MyComponent({ children }: Props) { ... }
```

---

## `no-console`

**Error:** Unexpected console statement.

**Fix:** Replace with a proper logger, or disable for a line if intentional.
```ts
// ✗
console.log("debug");

// ✓ — suppress for a specific line
console.log("debug"); // eslint-disable-line no-console

// ✓ — use a logger utility
import { logger } from '@/lib/logger';
logger.debug("info");
```

---

## `import/no-cycle`

**Error:** Dependency cycle detected.

**Fix:** Extract shared logic to a third module that both can import without creating a loop.
```
// ✗ a.ts → b.ts → a.ts
// ✓ a.ts → shared.ts ← b.ts
```

---

## `@typescript-eslint/explicit-function-return-type`

**Error:** Missing return type on function.

**Fix:** Add an explicit return type annotation.
```ts
// ✗
function getUser() { return { id: 1 }; }

// ✓
function getUser(): { id: number } { return { id: 1 }; }
// or use a named type
function getUser(): User { return { id: 1 }; }
```

---

## `jsx-a11y/alt-text`

**Error:** img elements must have an alt prop.

**Fix:** Add a descriptive `alt` attribute.
```tsx
// ✗
<img src={src} />

// ✓
<img src={src} alt="Profile picture of the user" />
// or for decorative images
<img src={src} alt="" role="presentation" />
```

---

## `jsx-a11y/anchor-is-valid`

**Error:** Anchor used as a button.

**Fix:** Use `<button>` for actions, `<a href="...">` for navigation only.
```tsx
// ✗
<a onClick={handleClick}>Click me</a>

// ✓
<button onClick={handleClick}>Click me</button>
```

---

## `no-shadow`

**Error:** 'resolve' is already declared in the upper scope.

**Fix:** Rename the inner variable to avoid shadowing.
```ts
// ✗
const resolve = () => {};
function inner() {
  const resolve = () => {}; // shadows outer
}

// ✓
function inner() {
  const innerResolve = () => {};
}
```