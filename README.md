# sogno

Nightly dream mode orchestrator for Claude Code: consolidate memory, generate morning briefing, propose project improvements, and tackle GitHub issues while you sleep.

## Installation

```sh
cd ~/Developer/scaccogatto/sogno
sogno install
```

## Usage

- `sogno advise` — analyze your work patterns and recommend a warmup anchor time
- `sogno warmup` — wake up Claude session (runs daily at ANCHOR_TIME)
- `sogno dream` — orchestrator: consolidate, briefing, proposals, backlog (runs daily at DREAM_TIME)
- `sogno install` — install/reload launchd jobs
- `sogno status` — show job status and last runs

## Configuration

Edit `sogno.conf` locally (defaults in `sogno.conf.example`). Key settings:

- `ANCHOR_TIME` — daily warmup time (HH:MM, local)
- `DREAM_TIME` — orchestrator start time (HH:MM, local)
- `PROJECTS_ROOT` — root directory of active project repos
- `DREAM_DIR` — output directory for briefings and logs

After changing times: `sogno install` to reload launchd.

## How it works

sogno runs via launchd at fixed times:

1. **Warmup** (ANCHOR_TIME) — cheap session prime, one line to log
2. **Dream** (DREAM_TIME) — four phases:
   - Phase 0: Consolidate Claude memory
   - Phase 1: Generate morning briefing from yesterday's sessions
   - Phase 2: Propose CLAUDE.md and memory improvements
   - Phase 3: Implement a GitHub issue (if one exists with the backlog label)

Each phase runs in `--permission-mode plan` except phase 3 (acceptEdits for implementation). Results saved to `$DREAM_DIR/` with daily briefing and proposals ready to review in the morning.

macOS notifications fire at the end with a summary (success, errors, or full skip if deadlines passed).

## Output files

- `~/.claude/dream/YYYY-MM-DD-briefing.md` — morning briefing
- `~/.claude/dream/YYYY-MM-DD-proposals/` — proposed diffs per project
- `~/.claude/dream/YYYY-MM-DD.log` — orchestrator log
- `~/.claude/dream/warmup.log` — warmup session history

## Constraints

- Bash + macOS stdlib (BSD tools, no GNU-isms)
- No external dependencies (uses native `gh` CLI for GitHub)
- Lock via atomic mkdir; stale locks (>6h) auto-reclaimed
- Hard deadline guards: DREAM_DEADLINE and BACKLOG_DEADLINE
- No auto-revert: failed worktree left for inspection

## License

MIT
