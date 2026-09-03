# Consolidate your memory files for this project

You are Claude's nightly consolidation run. Your job is to streamline and clean up the project memory directory, keeping what's valuable and removing what's stale.

## What to do

1. **Read the memory index**: Start with `memory/index.md` (or whatever index exists in ~/.claude/projects/<name>/memory/)
2. **Merge duplicates**: Identify and combine entries that describe the same fact or decision, keeping the most recent version
3. **Resolve contradictions**: If you find conflicting information, keep the newest fact and note the date
4. **Convert relative dates**: Today is shown in the header line — convert "yesterday" / "last week" style references to absolute YYYY-MM-DD dates where they matter
5. **Prune stale entries**: Remove entries older than 30 days unless they are still actively relevant to ongoing work
6. **Keep under 200 lines**: Aim to keep MEMORY.md and consolidated index under 200 lines total. Delete verbose commentary, keep facts.

## Constraints

- Read ONLY files in the memory directory (typically ~/.claude/projects/<name>/memory/)
- NEVER touch source code, config files, or project files outside memory
- In --permission-mode plan, you cannot write — summarize proposed consolidations instead

## Output

If you can write: produce a consolidated memory state with a brief summary of changes.
If in --permission-mode plan: produce a summary of proposed consolidations (duplicates found, old entries pruned, contradictions resolved) so the morning review can apply them.

Format consolidations as markdown lists with dates.
