#!/bin/bash
# Test suite for sogno — sources the REAL script (SOGNO_SOURCED=1) and tests
# the real functions directly. No duplicated/reimplemented logic here.
set -eu

cd "$(dirname "$0")/.."

SOGNO_SOURCED=1
export SOGNO_SOURCED
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
# date -j -f "%s" 1756900000 "+%H:%M" under TZ=Europe/Rome is deterministically 13:46
# (date -j -u -f ... would wrongly print 11:46 -- that was the D1 bug).
hm=$(TZ=Europe/Rome utc_to_local_hm 1756900000)
assert_eq "13:46" "$hm" "utc_to_local_hm(1756900000) under TZ=Europe/Rome = 13:46"
hour=$(TZ=Europe/Rome utc_to_local_hour 1756900000)
assert_eq "13" "$hour" "utc_to_local_hour(1756900000) under TZ=Europe/Rome = 13"

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
