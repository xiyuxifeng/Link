# CLAUDE.md

> Project instructions for AI coding agents (Claude Code, etc.).
> Place this file at the repository root.
>
> **Repo convention:** all application source lives under `_src/`.

---

## 0) Prime Directive
You are an engineering agent working inside this repository. Optimize for:
1) correctness and safety,  
2) reproducibility (tests + documented steps),  
3) incremental progress (small, reviewable changes),  
4) full-repo awareness when asked to review.

When requirements conflict, prioritize: **security → data integrity → correctness → observability → performance → UX polish**.

---

## 1) Repo Layout & Working Directory Rules
- **All source code is in:** `_src/`
- Do not create parallel code trees outside `_src/` unless explicitly instructed.
- Allowed top-level items outside `_src/`: repo meta (README, LICENSE), CI/IaC, and this `CLAUDE.md`.

### 1.1 Common Paths (fill in)
- `_src/apps/` — [web/mobile apps]
- `_src/services/` — [backend services]
- `_src/libs/` — [shared libraries]
- `_src/infra/` — [IaC/CDK/Terraform modules if you keep them here]
- `_src/tests/` — [integration/e2e tests]
- `_src/docs/` — [documentation]
- `_src/docs/plans/` — **continuation prompts and checkpoints (required)**

---

## 2) How to Run, Test, and Build (fill in)
> Keep these commands accurate. Update them when they change.

### 2.1 Prerequisites
- Runtime(s): [Go 1.xx], [Node xx], [Python x], etc.
- Package manager(s): [pnpm/npm/yarn], etc.
- Local dependencies: [Docker, compose, Redis, Postgres, etc.]


### 2.2 Common Commands
- Install deps: `[ ]`
- Format: `[ ]`
- Lint: `[ ]`
- Unit tests: `[ ]`
- Integration tests: `[ ]`
- E2E tests: `[ ]`
- Build: `[ ]`
- Run locally: `[ ]`

### 2.3 Environment Variables
- Location: `_src/.env.example` (or `[path]`)
- Secrets: **never** stored in repo; use `[Secrets Manager/SSM/etc]`.

---

## 3) Context Window & Working Memory Guidance
Claude (and similar agents) have a limited **context window**. Treat it like a fixed-size buffer:
- As the project grows, old details can fall out of active context.
- Maintain a **balance**: keep the current task + recent decisions + key constraints in view; offload long-running state to files.

### 3.1 Required “External Memory” Files
- `_src/docs/plans/` — continuation prompts + checkpoints (see §7)
- `_src/docs/decisions/` — ADRs (architecture decision records) (optional but recommended)
- `_src/docs/runbooks/` — operational notes (optional)

### 3.2 Rule
When you discover anything that will matter later (commands, paths, constraints, tricky behaviors), write it down in `_src/docs/plans/` or `_src/docs/decisions/` rather than relying on memory.

---

## 4) Coding Standards & Safety Rules (Hard Requirements)
### 4.1 Non-Negotiables
- **No secrets** in code, tests, logs, or docs.
- **No sensitive data** in logs (PII/PCI/credentials). Redact at source.
- **Backward compatibility**: don’t break public APIs without versioning + migration plan.
- **Idempotency**: any retryable write/side-effect path must be idempotent.
- **Deterministic tests**: avoid flaky timing-based checks; use “wait for condition” not sleep.

### 4.2 Change Scope Discipline
- Prefer the smallest viable change set.
- Avoid broad refactors mixed with behavior changes.
- If a refactor is needed, do it in a separate commit/PR-sized unit.

### 4.3 Error Handling & Logging
- Return actionable errors; don’t leak internals to user-facing surfaces.
- Logs must include: `correlation_id`, plus `tenant_id` if multi-tenant.

---

## 5) “Review” Requests Must Cover the Entire Repo Scope
When the user asks for a **document review**, **project review**, **folder review**, **security review**, or similar:
- You must review **ENTIRE** requested scope, **including all documents and sources**, not only what seems “top priority”.
- If the scope is “the repo” or “the project”, that means:
  - all relevant `_src/**` code
  - all `_src/docs/**`
  - build/test scripts, configs, CI definitions (where present)
- If the repo is too large to read in one pass, do a multi-pass approach:
  1) inventory everything in scope (file tree + categories),
  2) review all files systematically in batches,
  3) produce findings with file references.

**Do not** silently skip files because they look unimportant.

---

## 6) Operating Procedure for Any Work (Mandatory Workflow)
Use this loop for every task:

1) **Restate goal + constraints** (briefly).  
2) **Repo discovery**: locate relevant code/docs under `_src/`.  
3) **Plan**: 3–10 bullet steps, minimal and ordered.  
4) **Implement**: make changes in small chunks.  
5) **Test**: run the most relevant tests/linters.  
6) **Commit**: commit with meaningful message.  
7) **Checkpoint**: write a continuation prompt into `_src/docs/plans/`.  
8) **Push**: push to `main`.  
9) **Summarize**: what changed, how tested, any follow-ups.

### 6.1 “Sizable Work” Definition
Treat work as “sizable” if it includes any of:
- touching more than ~3 files,
- adding/modifying core logic,
- changing APIs/contracts,
- changing data model/migrations,
- UI flow changes,
- any security/permissions logic.

For sizable work, you **must** do §6 steps 5–8 **before** moving on.

---

## 7) Mandatory Checkpointing & Continuation Prompts
After each block of sizable work (see §6.1), you must create a file in:

- `_src/docs/plans/`

### 7.1 File Naming Convention
Use timestamp + short slug, e.g.:
- `_src/docs/plans/2026-02-20__feature-xyz__checkpoint.md`

### 7.2 Required Contents of Each Checkpoint File
Include these sections:

```md
# Checkpoint: [short description]
Date: [YYYY-MM-DD]
Branch: main
Last commit: [hash]
Scope completed:
- [what was done]

Tests run:
- [command] -> [result]
- [command] -> [result]

Notes / decisions:
- [important constraints, reasoning, tradeoffs]

Known issues / follow-ups:
- [list]

Continuation prompt (copy/paste into Claude):
- Goal: [next objective]
- Context: [key facts to keep in mind]
- Next steps:
  1) ...
  2) ...
- Files to inspect next:
  - _src/...
  - _src/...
- Risks:
  - ...
```

### 7.3 Continuation Prompt Quality Bar
The continuation prompt must be actionable and include:
- exact file paths,
- commands to run,
- what “done” looks like,
- any pitfalls discovered.

---

## 8) Git Workflow (Required)
### 8.1 Commit Policy
- Commit after each sizable work block.
- Commit message format (choose one and stick to it):
  - Conventional Commits: `feat: ...`, `fix: ...`, `chore: ...`, `docs: ...`
  - Or: `[component] short summary`

### 8.2 Push Policy
- After each sizable work block:
  - `git push origin main`

### 8.3 If Something Breaks
- Do not leave main broken.
- If a change fails tests:
  - fix immediately, or
  - revert cleanly, or
  - isolate behind a feature flag (if allowed).

---

## 9) Documentation Rules
- Keep docs in `_src/docs/`.
- When you change behavior, update:
  - relevant docs,
  - usage examples,
  - runbooks/checklists if impacted.

### 9.1 “Docs-as-Code”
Docs should be:
- versioned,
- tested where applicable (lint links, validate snippets),
- kept current with the codebase.

---

## 10) Security Practices (Minimum)
- Use least privilege in IAM-style policies/configs (where applicable).
- Never print tokens/PAN/PII in logs.
- Validate all inbound inputs (server and client).
- Use secure defaults; fail safe.

---

## 11) When to Stop and Ask
Stop and request clarification before:
- changing auth/authz, multi-tenant boundaries, role definitions,
- changing key management/crypto,
- introducing new data retention/deletion behavior,
- changing payment flows (if relevant),
- deleting large code paths or performing sweeping refactors.

If ambiguity is minor and you can proceed safely, document assumptions in a checkpoint file.

---

## 12) Output Expectations for Each Task
At the end of each task, provide:
- summary of changes,
- tests executed + results,
- commit hash,
- path to the new checkpoint file in `_src/docs/plans/`,
- any remaining risks/follow-ups.

---

## 13) Project-Specific Notes (Fill In)
- Multi-tenant model: [tenant_id claim source; enforcement layer]
- Primary services: [ ]
- Data stores: [ ]
- External dependencies: [payment gateway, email provider, etc.]
- Compliance constraints: [PCI, SOC2, etc.]
