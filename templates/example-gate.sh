#!/usr/bin/env bash
# Example gate harness showing the shape every gate should have.
#
# The pattern that matters: ASSERT YOUR PRECONDITIONS FIRST and exit 3 if they
# are absent. Most false-green results come from a harness that queried
# something nonexistent, got an empty result, and concluded "no problems found."
#
#   exit 0 = the property was measured and holds
#   exit 3 = a precondition is missing, so nothing was measured
#   exit 1 = the property was measured and is violated

set -uo pipefail

TARGET="${TARGET:-}"

# ---------------------------------------------------------------------------
# 1. PRECONDITIONS -- exit 3, never 0, when the thing under test is not there.
# ---------------------------------------------------------------------------
if [ -z "$TARGET" ]; then
  echo "cannot run: TARGET is unset -- nothing to measure"
  exit 3
fi

if ! command -v some-required-tool >/dev/null 2>&1; then
  echo "cannot run: some-required-tool is not installed"
  exit 3
fi

# Confirm the subject EXISTS before asserting anything about it. An empty read
# is not evidence of absence of a problem; it is absence of evidence.
if ! some-required-tool describe "$TARGET" >/dev/null 2>&1; then
  echo "cannot run: $TARGET does not exist or is unreachable"
  exit 3
fi

# ---------------------------------------------------------------------------
# 2. A POSITIVE CONTROL -- prove the instrument works before trusting a null.
#    A query that returns nothing because it is malformed looks exactly like a
#    query that returns nothing because the system is clean.
# ---------------------------------------------------------------------------
control_count="$(some-required-tool list --all "$TARGET" 2>/dev/null | wc -l)"
if [ "$control_count" -eq 0 ]; then
  echo "cannot run: control query returned 0 rows -- the instrument is not reading anything"
  exit 3
fi
echo "control: instrument reads $control_count rows -- it works"

# ---------------------------------------------------------------------------
# 3. THE ACTUAL ASSERTION
#
#    Run this against the KNOWN-GOOD tree before you trust it. A check that
#    reports a violation on a clean tree is worse than no check: it will be
#    dismissed, then disabled, and the real violation it was built for arrives
#    to an audience that has learned to ignore it.
#
#    When a false positive appears, TIGHTEN THE PATTERN and record the exempted
#    near-miss in a comment. Do not add a blanket suppression -- the next real
#    violation hides behind it. (In practice: a check for forked-code
#    provenance matched prose describing a DESIGN lineage, "the X-vending fork
#    of the Y idiom". The fix was requiring an explicit code-provenance phrase,
#    with both near-misses named in the comment so a later reader does not
#    "helpfully" loosen it again.)
# ---------------------------------------------------------------------------
violations="$(some-required-tool list --violating "$TARGET" 2>/dev/null | wc -l)"

if [ "$violations" -gt 0 ]; then
  echo "FAIL: $violations violation(s) found"
  some-required-tool list --violating "$TARGET"
  exit 1
fi

echo "PASS: property holds ($control_count subjects checked, 0 violations)"
exit 0
