<div align="center">
  <img src=".github/logo.svg" width="220" alt="sogno logo">

  **Your coding agent dreams while you sleep.**

  <sub>Nightly briefing, memory consolidation proposals, doc patches, and a draft PR, ready before your first coffee. Plus a warmup that anchors Claude's 5-hour usage window to your actual schedule.</sub>

  [![ci](https://github.com/scaccogatto/sogno/actions/workflows/ci.yml/badge.svg)](https://github.com/scaccogatto/sogno/actions/workflows/ci.yml)
  [![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

  <img src=".github/demo.gif" width="800" alt="sogno demo">
</div>

---

Claude Code's 5-hour usage window anchors to your first message of the day: start at 8:30, hit the limit at 11, and you sit idle until 13:30. Meanwhile your agent's memory accumulates duplicates, stale facts, and "yesterday we decided" notes that mean nothing a week later, and the hours before your workday go unused. sogno fixes all three locally: a 1-token warmup fires before you wake and pins the window resets where you want them, and a nightly orchestrator reads yesterday's session transcripts and turns them into a morning briefing, consolidation and doc proposals, and one backlog issue implemented as a draft PR. No cloud, no daemon, no dependencies: two scheduler jobs and one bash script.

```sh
sogno advise      # analyze your usage, get the best anchor time for your schedule
sogno install     # load the warmup + dream launchd jobs (idempotent)
sogno dream --dry-run   # see what tonight's dream would do
sogno status      # jobs, last run, per-phase outcomes
```

## Why sogno

- **The window works for you, not against you.** `advise` reads your real first-message times from Claude Code transcripts, simulates every anchor candidate, and shows the resulting 5-hour windows so resets land at lunch and end of day, never mid-task.
- **Wake up already briefed.** The dream reads yesterday's transcripts across all active projects and writes one briefing: what was done, decisions, gotchas, open threads, top 3 things to look at today.
- **Proposals, never surprises.** CLAUDE.md, memory, and OKF changes are emitted as unified diffs in patch files. You review and `git apply` in the morning; nothing is applied overnight.
- **One issue a night, safely.** The backlog phase picks a single open issue labeled `sogno`, works in an isolated git worktree on its own branch, and opens a draft PR. Hard guards verify your default branch SHA never moved.
- **Boring machinery.** Bash and stdlib only, macOS/Linux/Windows alike. Atomic mkdir lock, daily stamp, wall-clock deadlines, a desktop notification with the outcome. The scheduler backend (launchd, systemd, Task Scheduler) replays missed fires after sleep.

## Quickstart

```sh
git clone https://github.com/scaccogatto/sogno && cd sogno
cp sogno.conf.example sogno.conf   # edit ANCHOR_TIME, PROJECTS_ROOT, DREAM_TIME
./sogno advise                     # let it recommend ANCHOR_TIME first
./sogno install
```

On macOS the first nightly run may ask once for notification permission.

## Configuration

| Key | Default | Meaning |
| --- | --- | --- |
| `ANCHOR_TIME` | `06:30` | When the warmup pins the 5-hour window |
| `DREAM_TIME` | `03:30` | When the nightly orchestrator starts |
| `DREAM_DEADLINE` | `07:30` | Hard stop: phases past this are skipped |
| `BACKLOG_DEADLINE` | `05:30` | Backlog phase will not start after this |
| `PROJECTS_ROOT` | `~/Developer` | Where your repos live |
| `PROJECTS_EXCLUDE` | empty | Space-separated repo names to skip |
| `BACKLOG_ENABLED` | `1` | Set `0` to disable the draft-PR phase |
| `BACKLOG_LABEL` | `sogno` | GitHub issue label the backlog phase picks up |
| `MODEL_MECHANICAL` | `haiku` | Model for warmup and consolidation |
| `MODEL_SYNTHESIS` | account default | Model for briefing, proposals, backlog |
| `DREAM_DIR` | `~/.claude/dream` | Briefings, patches, logs, lock, stamps |
| `PROJECTS_PREFIX` | auto-detected | Escape hatch: override the Claude Code transcript prefix derived from `PROJECTS_ROOT` |

## How it works

The warmup job sends one throwaway message (`claude -p "hi"`) at `ANCHOR_TIME`: the window opens before your day starts and every reset lands where `advise` planned it. The dream job runs four phases in one process, in order: consolidate (asks Claude to propose memory cleanup; pairs with Claude Code's native auto-dream when your account has it), briefing, proposals, backlog. Each phase is deadline-guarded and failure-isolated: one phase failing never blocks the next, and the stamp file records per-phase outcomes that `sogno status` reads back. Everything Claude touches overnight is either read-only (`--permission-mode plan`) or confined to a worktree branch. `sogno install` registers the two jobs with the native scheduler for your platform: launchd on macOS, systemd user timers on Linux, Task Scheduler on Windows.

## Requirements

macOS, Linux, or Windows via Git Bash; [Claude Code](https://code.claude.com) CLI on PATH; `gh` (only for the backlog phase). On Linux, `systemd --user` (falls back to printed crontab lines if unavailable) and optionally `notify-send` for desktop notifications. On Windows, Git Bash plus Task Scheduler. No other dependencies.

## Roadmap

Native `/dream` integration when the rollout lands, and smarter advise weights: see the issues.

## License

[MIT](LICENSE)
