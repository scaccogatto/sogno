# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Releases up to 0.2.0 are described in their [GitHub release notes](https://github.com/scaccogatto/sogno/releases).

## [Unreleased]

### Security

- Backlog phase only picks issues opened by the repo owner (`gh issue list --author <owner>`, re-checked on the issue itself). Issues by anyone else are ignored, even if labeled.
- The issue text is fenced in the backlog prompt as untrusted data, and the backlog run gets an explicit tool allowlist that excludes `git push`.
- `sogno.conf` is no longer read from the current directory: running sogno inside a cloned repo cannot execute that repo's files.
- Scheduler templates escape paths: launchd plists and Task Scheduler XML are XML-escaped, systemd units quote the script path and escape `%`, and the Task Scheduler `bash -lc` command quotes the script path, so paths with spaces, `&`, `|` or quotes work.
- Release assets carry a signed build provenance attestation (`gh attestation verify sogno-<version>.tar.gz -R scaccogatto/sogno`).

### Changed

- **Breaking:** config lookup is `SOGNO_CONF` (if set), then `sogno.conf` next to the script, then `~/.config/sogno/sogno.conf` (`$XDG_CONFIG_HOME`). A `sogno.conf` in the working directory is ignored: move it next to the script or to the XDG path.
- **Breaking:** the backlog phase skips issues not authored by the repo owner. On an organization-owned repo the owner is the organization, so no issue is eligible.
- The backlog phase fetches the default branch before branching, so the worktree starts from the current remote tip, and the "default branch never moved" guard now checks the remote (`git ls-remote`) instead of the local remote-tracking ref.
- The backlog run may run `git status/diff/log/add/commit` without a permission prompt. Extra tools (e.g. the project's test command) go in the new `BACKLOG_ALLOWED_TOOLS` setting. Edits Claude leaves uncommitted are committed by the orchestrator.
- Desktop notifications are in English.
- Per-user bin dirs (`~/.local/bin`, `~/bin`) now come before `/opt/homebrew/bin` and `/usr/local/bin` on the PATH sogno sets up.

### Fixed

- `make install` produces a working install: sogno finds its prompts and templates under `$(PREFIX)/share/sogno`.
- `sogno dream --only <unknown>` exits 2 with an error instead of running nothing and consuming the daily stamp.
- `DREAM_DEADLINE` and `BACKLOG_DEADLINE` earlier than `DREAM_TIME` are treated as the next day, so a window that crosses midnight (e.g. 23:30 to 02:00) no longer skips every phase.

[Unreleased]: https://github.com/scaccogatto/sogno/compare/v0.2.0...HEAD
