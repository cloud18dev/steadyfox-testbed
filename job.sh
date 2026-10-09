#!/usr/bin/env bash
# Fake cron job: acts out one scenario and reports it to every monitoring tool.
# Tools without a configured URL are skipped.
set -uo pipefail

HC_URL="${HC_URL:-}"
CRONITOR_URL="${CRONITOR_URL:-}"
BETTERSTACK_URL="${BETTERSTACK_URL:-}"
HYPERPING_URL="${HYPERPING_URL:-}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

scenario="${SCENARIO:-success}"
if [ "$scenario" = random ]; then
  r=$((RANDOM % 100))
  if   [ $r -lt 70 ]; then scenario=success
  elif [ $r -lt 80 ]; then scenario=slow
  elif [ $r -lt 88 ]; then scenario=zero
  elif [ $r -lt 94 ]; then scenario=fail
  elif [ $r -lt 97 ]; then scenario=hang
  else scenario=skip; fi
fi

# Ground truth: every run records what it simulated (see the run summary in Actions)
echo "$(date -u +%FT%TZ) scenario=$scenario" | tee -a "$SUMMARY"

# hit <base-url> <suffix> [curl args...]
hit() {
  local base=$1 suffix=$2
  shift 2
  [ -z "$base" ] && return 0
  curl -fsS -m 10 --retry 3 "$@" "$base$suffix" >/dev/null || echo "::warning::ping failed: ${base%%\?*}"
}

start() {
  hit "$HC_URL" "/start"
  hit "$CRONITOR_URL" "?state=run"
  # Better Stack and Hyperping heartbeats have no start signal
}

done_ok() { # $1 = records processed
  hit "$HC_URL" "" --data-raw "records=$1"
  hit "$CRONITOR_URL" "?state=complete&metric=count:$1"
  hit "$BETTERSTACK_URL" ""
  hit "$HYPERPING_URL" ""
}

done_fail() {
  hit "$HC_URL" "/fail" --data-raw "simulated failure"
  hit "$CRONITOR_URL" "?state=fail&message=simulated+failure"
  hit "$BETTERSTACK_URL" "/fail"
  # Hyperping: no fail endpoint wired up; it only notices the missing success ping
}

case $scenario in
  success) start; sleep $((20 + RANDOM % 20)); done_ok $((100 + RANDOM % 100)) ;;
  slow)    start; sleep 240;                   done_ok 150 ;; # about 8x normal duration
  zero)    start; sleep 25;                    done_ok 0 ;;   # ran fine, did nothing
  fail)    start; sleep 10;                    done_fail ;;
  hang)    start ;;                                           # started, never finished
  skip)    : ;;                                               # the cron never fired
  *)       echo "unknown scenario: $scenario" >&2; exit 2 ;;
esac

# "fail" deliberately exits 0: a red workflow makes GitHub email you,
# which would mix GitHub's notifications into the tool comparison.
exit 0
