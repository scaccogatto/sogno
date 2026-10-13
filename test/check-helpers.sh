#!/bin/bash
# Unit tests for sogno's pure helpers (time math, paths, template rendering).
# Sources the REAL script (SOGNO_SOURCED=1) and tests the real functions
# directly. No duplicated/reimplemented logic here.
set -eu

cd "$(dirname "$0")/.."

SOGNO_SOURCED=1
# Isolate from a developer's own sogno.conf.
SOGNO_CONF=/dev/null
export SOGNO_SOURCED SOGNO_CONF
. ./sogno

PASS=0
FAIL=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  OK %s\n" "$msg"
  else
    FAIL=$((FAIL + 1))
    printf "  FAIL %s\n" "$msg"
    printf "    expected: %s\n" "$expected"
    printf "    actual:   %s\n" "$actual"
  fi
}

echo "Testing window boundary calculations (real window_end)..."
assert_eq "11:30" "$(window_end "06:30")" "window_end(06:30) = 11:30"
assert_eq "16:30" "$(window_end "11:30")" "window_end(11:30) = 16:30"
assert_eq "21:30" "$(window_end "16:30")" "window_end(16:30) = 21:30"
assert_eq "02:30" "$(window_end "21:30")" "window_end(21:30) = 02:30 (wrapped)"
assert_eq "01:00" "$(window_end "20:00")" "window_end(20:00) = 01:00"
assert_eq "13:30" "$(window_end "08:30")" "window_end(08:30) = 13:30 (octal trap: leading-zero hour)"
assert_eq "14:00" "$(window_end "09:00")" "window_end(09:00) = 14:00 (octal trap: leading-zero hour)"

echo ""
echo "Testing UTC->local conversion (real utc_to_local_hm, pinned TZ=Europe/Rome)..."
# Git Bash ships without the zoneinfo database, so a TZ override silently falls
# back to UTC there. Real runs are unaffected (MSYS takes the Windows zone when
# TZ is unset), but these two asserts cannot be pinned, so they are skipped.
if [ "$(TZ=Europe/Rome utc_to_local_hour 1756900000)" = "$(TZ=UTC utc_to_local_hour 1756900000)" ]; then
  echo "  SKIP no zoneinfo database: TZ overrides are ignored on this host"
else
  # date -j -f "%s" 1756900000 "+%H:%M" under TZ=Europe/Rome is deterministically 13:46
  # (date -j -u -f ... would wrongly print 11:46 -- that was the D1 bug).
  hm=$(TZ=Europe/Rome utc_to_local_hm 1756900000)
  assert_eq "13:46" "$hm" "utc_to_local_hm(1756900000) under TZ=Europe/Rome = 13:46"
  hour=$(TZ=Europe/Rome utc_to_local_hour 1756900000)
  assert_eq "13" "$hour" "utc_to_local_hour(1756900000) under TZ=Europe/Rome = 13"
fi

echo ""
echo "Testing flattened-path -> repo-name mapping (real flattened_to_repo)..."
PROJECTS_PREFIX="-Users-gatto-Developer-scaccogatto-"
assert_eq "growth-oss" "$(flattened_to_repo "-Users-gatto-Developer-scaccogatto-growth-oss")" \
  "flattened_to_repo strips PROJECTS_PREFIX, keeps hyphenated repo name intact"
assert_eq "sogno" "$(flattened_to_repo "-Users-gatto-Developer-scaccogatto-sogno")" \
  "flattened_to_repo maps sogno"
assert_eq "-some-other-tree" "$(flattened_to_repo "-some-other-tree")" \
  "flattened_to_repo passes through dirs that don't match the prefix"

echo ""
echo "Testing anchor scoring (real score_anchor) with synthetic per-day first-message data..."
# Synthetic data: earliest observed first message across days is 08:00.
# Full candidate sweep (06:00-08:45 step 15, same as cmd_advise) should prefer
# 08:00 itself: no lateness penalty, and all three window boundaries land on
# lunch (13:00) / evening (18:00) / evening (23:00) for max +30.
earliest_hm="08:00"
best_anchor=""
best_score=-999999
for h in 06 07 08; do
  for m in 00 15 30 45; do
    anchor="${h}:${m}"
    score=$(score_anchor "$anchor" "$earliest_hm")
    if [ "$score" -gt "$best_score" ]; then
      best_score=$score
      best_anchor="$anchor"
    fi
  done
done
assert_eq "08:00" "$best_anchor" "best anchor for earliest=08:00 is 08:00 (score $best_score)"
assert_eq "30" "$best_score" "best score for earliest=08:00 is 30 (lunch+evening+evening, no lateness penalty)"

# A same-hour-but-later-minute anchor should score worse than one that isn't late at all.
score_0630=$(score_anchor "06:30" "08:00")
score_0830=$(score_anchor "08:30" "08:00")
if [ "$score_0830" -gt "$score_0630" ]; then
  PASS=$((PASS + 1))
  printf "  OK 08:30 (lunch/evening boundaries, 30min late) outscores 06:30 (double work-hour hit) for earliest=08:00\n"
else
  FAIL=$((FAIL + 1))
  printf "  FAIL expected score(08:30)=%s > score(06:30)=%s\n" "$score_0830" "$score_0630"
fi

echo ""
echo "Testing PROJECTS_PREFIX derivation (real derive_projects_prefix)..."
SOGNO_OS=macos
assert_eq "-Users-gatto-Developer-" "$(derive_projects_prefix "/Users/gatto/Developer")" \
  "derive_projects_prefix POSIX path unchanged from before"
SOGNO_OS=windows
assert_eq "C--Users-x-dev-" "$(derive_projects_prefix 'C:\Users\x\dev')" \
  "derive_projects_prefix windows path (no cygpath on this host)"
SOGNO_OS=macos

echo ""
echo "Testing date helpers (real epoch_to_local_date, iso_utc_to_epoch, yesterday_date) under TZ=Europe/Rome..."
date_str=$(TZ=Europe/Rome epoch_to_local_date 1756900000)
assert_eq "2025-09-03" "$date_str" "epoch_to_local_date(1756900000) under TZ=Europe/Rome = 2025-09-03"
epoch_back=$(TZ=Europe/Rome iso_utc_to_epoch "2025-09-03T11:46:40")
assert_eq "1756900000" "$epoch_back" "iso_utc_to_epoch(2025-09-03T11:46:40) = 1756900000"

# Compared as a range, not against now-86400s: those disagree on DST switch days.
now_epoch=$(date +%s)
yd=$(yesterday_date)
if [ "$yd" \< "$(date +%F)" ] && [ "$yd" \> "$(epoch_to_local_date $((now_epoch - 172800)))" ]; then
  PASS=$((PASS + 1))
  echo "  PASS yesterday_date is the day before today"
else
  FAIL=$((FAIL + 1))
  printf "  FAIL yesterday_date returned %s\n" "$yd"
fi


echo ""
echo "Testing deadline checks (real past_deadline)..."
DREAM_TIME="03:30"
past_deadline "07:30" "07:00" && r=past || r=ok
assert_eq "ok" "$r" "03:30 run, deadline 07:30, now 07:00 is not past"
past_deadline "07:30" "07:30" && r=past || r=ok
assert_eq "ok" "$r" "03:30 run, deadline 07:30, now 07:30 is not past (inclusive)"
past_deadline "07:30" "08:00" && r=past || r=ok
assert_eq "past" "$r" "03:30 run, deadline 07:30, now 08:00 is past"
DREAM_TIME="23:30"
past_deadline "02:00" "23:45" && r=past || r=ok
assert_eq "ok" "$r" "23:30 run, deadline 02:00, now 23:45 is not past (window crosses midnight)"
past_deadline "02:00" "00:30" && r=past || r=ok
assert_eq "ok" "$r" "23:30 run, deadline 02:00, now 00:30 is not past (after midnight)"
past_deadline "02:00" "02:30" && r=past || r=ok
assert_eq "past" "$r" "23:30 run, deadline 02:00, now 02:30 is past"
DREAM_TIME="03:30"

echo ""
echo "Testing template rendering with hostile paths (real render_template)..."
tmp_render=$(mktemp -d "${TMPDIR:-/tmp}/sogno-render.XXXXXX")
saved_self="$SELF"
saved_dream_dir="$DREAM_DIR"
SELF="$tmp_render/a b&c|d'e%f"
DREAM_DIR="$tmp_render/dream&dir"

render_template launchd/com.scaccogatto.sogno.dream.plist.tmpl "$tmp_render/dream.plist" 03 30 || true
plist_prog=$(grep -m1 '/sogno</string>' "$tmp_render/dream.plist" | sed 's/^ *//')
assert_eq "<string>$tmp_render/a b&amp;c|d&apos;e%f/sogno</string>" "$plist_prog" \
  "plist: script path is XML-escaped and survives sed metacharacters"
assert_eq "1" "$(grep -c '<integer>03</integer>' "$tmp_render/dream.plist")" "plist: hour rendered"
if command -v xmllint >/dev/null 2>&1; then
  if xmllint --noout "$tmp_render/dream.plist" 2>/dev/null; then r=valid; else r=invalid; fi
  assert_eq "valid" "$r" "plist: rendered file is well-formed XML"
fi

render_template windows/sogno-dream.xml.tmpl "$tmp_render/dream.xml" 03 30 || true
win_args=$(sed -n 's|.*<Arguments>\(.*\)</Arguments>.*|\1|p' "$tmp_render/dream.xml" |
  sed -e 's/&quot;/"/g' -e "s/&apos;/'/g" -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/\&/g')
# Arguments is -lc "<script>": bash runs <script>, so parse it as shell words.
win_script=${win_args#-lc \"}
win_script=${win_script%\"}
eval "set -- $win_script"
assert_eq "$SELF/sogno" "$1" "Task Scheduler: bash -lc sees the script path as one word"
assert_eq "dream" "${2:-}" "Task Scheduler: subcommand passed after the script path"
if command -v xmllint >/dev/null 2>&1; then
  if xmllint --noout "$tmp_render/dream.xml" 2>/dev/null; then r=valid; else r=invalid; fi
  assert_eq "valid" "$r" "Task Scheduler: rendered file is well-formed XML"
fi

render_template systemd/sogno-dream.service.tmpl "$tmp_render/dream.service" 03 30 || true
assert_eq "ExecStart=\"$tmp_render/a b&c|d'e%%f/sogno\" dream" "$(grep '^ExecStart=' "$tmp_render/dream.service")" \
  "systemd: script path quoted, % escaped as a specifier"

if render_template systemd/sogno-dream.service.tmpl "$tmp_render/dream.service" 03 30; then r=changed; else r=unchanged; fi
assert_eq "unchanged" "$r" "render_template is idempotent (returns 1 when nothing changed)"

SELF="$saved_self"
DREAM_DIR="$saved_dream_dir"
rm -rf "$tmp_render"

echo ""
echo "Test summary:"
printf "  Passed: %d\n" "$PASS"
printf "  Failed: %d\n" "$FAIL"

if [ $FAIL -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
