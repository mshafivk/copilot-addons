---
name: security-review
description: >
  Perform a security-focused review of code changes before a PR is created or a phase
  is marked complete. Invoke after the Reviewer completes the standard checklist when
  a phase involves authentication, authorisation, data mutations, file handling, external
  API calls, or user-generated content. Also trigger when the user says "security check",
  "check for vulnerabilities", "security review this", or similar.
---

# security-review

Performs a targeted security review of changed files. Designed to be invoked by the Reviewer agent for significant features, or directly by a developer before merging a sensitive change. Covers OWASP Top 10 categories most relevant to React + Node.js monorepos.

---

## When to invoke

Always invoke for changes that include:
- New authentication or session management code
- Authorisation / permission checks
- Forms that accept user input
- API integrations (especially third-party)
- File uploads or downloads
- User-generated content rendered to the DOM
- Environment variables or secrets handling
- New npm dependencies

---

## Step-by-step workflow

### 1. Identify the review surface

```bash
git diff main...HEAD --name-only    # all files changed vs main
git diff --staged --name-only       # staged files only
```

Focus on files that match the trigger criteria above. You do not need to review every file — prioritise high-risk surfaces.

### 2. Run through the security checklist

Work through each category. Mark each item as ✅ Pass, ❌ Fail, or ⚠️ Needs attention.

---

### A. Injection (XSS, SQL, Command)

- [ ] No use of `dangerouslySetInnerHTML` without explicit sanitisation (e.g. `DOMPurify`)
- [ ] No direct string concatenation into HTML, SQL, or shell commands
- [ ] User-controlled values are never passed to `eval()`, `new Function()`, or `setTimeout(string)`
- [ ] URL parameters are encoded before use in links or API calls (`encodeURIComponent`)
- [ ] No raw `innerHTML` assignments with user-controlled content

### B. Authentication & Session

- [ ] Auth tokens are stored in `httpOnly` cookies, not `localStorage` (preferred)
- [ ] If `localStorage` is used for tokens — this is flagged as a risk (XSS can steal them)
- [ ] Token expiry and refresh logic handles edge cases (expired, revoked, network error)
- [ ] No hardcoded credentials, API keys, or secrets in source files
- [ ] Secrets are read from environment variables — `.env` files are in `.gitignore`
- [ ] No auth-related logic bypassed by URL manipulation or client-side checks alone

### C. Authorisation

- [ ] Authorisation checks exist server-side, not only client-side
- [ ] UI that conditionally hides elements for unauthorised users also has server-side guards
- [ ] No direct object references (IDs in URL) without ownership verification on the API
- [ ] Role/permission checks use constants or enums — not hardcoded strings scattered across code

### D. Input Validation

- [ ] All user inputs are validated before being sent to an API or used in logic
- [ ] Validation happens on both client (UX) and server (security)
- [ ] File upload inputs check file type via MIME type (not just file extension)
- [ ] Numeric inputs have min/max bounds enforced
- [ ] No unbounded string inputs that could cause resource exhaustion

### E. Sensitive Data Exposure

- [ ] No PII (name, email, phone, address) logged to the console or analytics
- [ ] No sensitive fields (password, token, SSN) included in error messages returned to UI
- [ ] API responses do not return more fields than the UI needs (over-fetching of sensitive fields)
- [ ] Sensitive fields in form state are cleared after submission (`password`, `cvv`, etc.)

### F. Dependencies

- [ ] New npm dependencies checked for known vulnerabilities:
  ```bash
  npm audit --audit-level=moderate
  ```
- [ ] New dependencies have recent maintenance activity (check package age and last publish date)
- [ ] No dependencies added that replicate functionality already in the codebase

### G. CSRF

- [ ] Mutating API calls (POST, PUT, PATCH, DELETE) include CSRF protection if the app uses cookie-based auth
- [ ] Forms do not rely solely on `Referer` header checking

### H. React-specific

- [ ] No `dangerouslySetInnerHTML` used with unsanitised content
- [ ] `key` props in lists use stable IDs, not array indices (can cause identity confusion)
- [ ] Sensitive data is not stored in Redux/Zustand state without encryption if state is persisted
- [ ] No server-side rendered content that echoes unsanitised user input

### I. Third-party integrations

- [ ] Third-party scripts loaded via `<script>` use Subresource Integrity (SRI) where possible
- [ ] OAuth redirect URIs are validated against a whitelist
- [ ] Webhook handlers validate signatures before processing payloads

---

### 3. Report findings

```markdown
## Security Review Report

**Phase / PR**: <name>
**Date**: YYYY-MM-DD
**Reviewer**: Test Agent / Reviewer Agent / Developer

### Status: CLEAR ✅  /  ISSUES FOUND ❌  /  ADVISORY ⚠️

### Findings

| # | Category | File | Line | Issue | Severity | Recommendation |
|---|----------|------|------|-------|----------|----------------|
| 1 | XSS | Login.tsx | 87 | `dangerouslySetInnerHTML` with unsanitised `userBio` | Critical | Wrap with `DOMPurify.sanitize()` before render |
| 2 | Sensitive data | useAuth.ts | 34 | Auth token stored in `localStorage` | High | Consider `httpOnly` cookie or memory-only storage |
| 3 | Dependency | package.json | — | `axios@0.21.1` has known SSRF vulnerability (CVE-2021-3749) | High | Upgrade to `axios@1.6.0` or later |

### Summary

[One paragraph: overall security posture of the change, key risks, any items that need a human decision before merging]
```

**Severity levels**:
- `Critical` — exploitable as-is, blocks merge
- `High` — significant risk, should be fixed before merge
- `Medium` — risk exists but requires specific conditions to exploit, fix recommended
- `Low` — best-practice deviation, low actual risk
- `Info` — informational, no action required

---

## What this skill does NOT do

- Does not perform penetration testing or dynamic analysis
- Does not scan server-side code (backend APIs, database queries) — frontend-focused only
- Does not replace a professional security audit for compliance-critical features
- Does not check infrastructure or deployment configuration

