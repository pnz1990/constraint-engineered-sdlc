#!/usr/bin/env bash
# Reference gate runner: the three-outcome contract, which is the load-bearing
# mechanism of this whole method.
#
#   0     = PASS        the thing was measured, and it is correct
#   3     = CANNOT RUN  a precondition is absent, so the gate refused to score
#   other = FAIL        the thing was measured, and it is wrong
#
# Without the third state, a harness that honestly refuses to run is
# indistinguishable from one that found a real defect -- and, worse, a harness
# whose precondition is missing silently reports success because it read nothing
# and therefore violated nothing.
#
# Usage:  ./run-gates.sh [output-dir]

set -uo pipefail

RESULTS_DIR="${1:-evidence/gate-run}"
mkdir -p "$RESULTS_DIR"

PASS=0; FAIL=0; CANNOT=0
results=()

run_gate() {
  local gate="$1" harness="$2" rc=0
  printf '  %-16s ' "$gate:"
  bash "$harness" > "$RESULTS_DIR/${gate}.log" 2>&1 || rc=$?

  if [ "$rc" -eq 0 ]; then
    echo "PASS"
    PASS=$((PASS + 1))
    results+=("{\"gate\":\"$gate\",\"verdict\":\"PASS\"}")
  elif [ "$rc" -eq 3 ]; then
    # Surface WHY it could not run. A cannot-run with no stated reason is
    # indistinguishable from a harness that is simply broken.
    local why
    why="$(grep -m1 -i 'cannot run\|FATAL' "$RESULTS_DIR/${gate}.log" 2>/dev/null | tr -d '"' | cut -c1-120)"
    echo "CANNOT RUN -- ${why:-no reason given (fix the harness)}"
    CANNOT=$((CANNOT + 1))
    results+=("{\"gate\":\"$gate\",\"verdict\":\"CANNOT_RUN\",\"reason\":\"$why\"}")
  else
    echo "FAIL (rc=$rc, see $RESULTS_DIR/${gate}.log)"
    FAIL=$((FAIL + 1))
    results+=("{\"gate\":\"$gate\",\"verdict\":\"FAIL\"}")
  fi
}

echo "== gate run =="

# ---- register gates here ----
# run_gate "ISOLATION" "tests/test-isolation.sh"
# run_gate "TEARDOWN"  "tests/test-teardown.sh"
# run_gate "ROLLBACK"  "tests/test-rollback.sh"
# -----------------------------

# The verdict is three-valued on purpose. A run with cannot-runs is NOT a green
# run: it is a run with unmeasured gates, and saying so is the point.
if [ "$FAIL" -gt 0 ]; then
  VERDICT="FAIL"
elif [ "$CANNOT" -gt 0 ]; then
  VERDICT="INCOMPLETE"
else
  VERDICT="PASS"
fi

cat > "$RESULTS_DIR/results.json" <<EOF
{
  "verdict": "$VERDICT",
  "pass": $PASS,
  "fail": $FAIL,
  "cannot_run": $CANNOT,
  "gates": [$(IFS=,; echo "${results[*]-}")]
}
EOF

echo
echo "== $VERDICT -- $PASS pass, $FAIL fail, $CANNOT cannot-run =="
echo "   $RESULTS_DIR/results.json"

# INCOMPLETE must not exit 0. A summary that reports success while gates went
# unmeasured is the exact failure this file exists to prevent.
[ "$VERDICT" = "PASS" ] || exit 1
