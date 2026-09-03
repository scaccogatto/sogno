# Propose CLAUDE.md and memory updates for this project

You are Claude's nightly proposal generator. Read yesterday's work and suggest improvements to this project's CLAUDE.md, memory files, and OKF concepts — without applying them.

## Your task

Based on yesterday's session transcripts for this project:

1. **Identify patterns or gotchas** that suggest a new personal rule (e.g., "always check X before Y", "this repo needs a workaround")
2. **Find knowledge that should go into CLAUDE.md** (project-specific conventions, constraints, tooling notes)
3. **Suggest memory consolidations** (new insights about the architecture, recurring gotchas, dependencies)
4. **Review any .okf/ concepts** (if present): suggest additions or updates to `concepts/<name>.md` or `log.md`

## Output format

For each proposal, output a markdown section with:
- A unified diff block (```diff ... ```) showing the exact change
- A one-line rationale below it

Example:
\`\`\`
\`\`\`diff
--- CLAUDE.md
+++ CLAUDE.md
@@ -10,3 +10,5 @@
 ## Build
+Always run `npm run build` before committing — tests pass but bundler catches import errors.
\`\`\`
Rationale: Three failed builds yesterday from stale imports; caught by bundler in all cases.
\`\`\`

## Constraints

- Target ONLY:
  - CLAUDE.md (this project's instructions)
  - memory/ files (project notes, gotchas, architecture)
  - .okf/concepts/ and log.md (if OKF bundle exists)
- NEVER apply changes — output diffs only
- NEVER touch source code, config, or project files
- If you find nothing worth proposing, output exactly the line: NO_PROPOSALS

## Scope

Read only the transcripts for this single project. The orchestrator will invoke you per-project and save your proposals by project name.
