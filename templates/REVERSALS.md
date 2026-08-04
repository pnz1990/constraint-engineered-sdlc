# Reversal ledger

Format: what was believed → what evidence overturned it → what is now believed → what must cascade.

**Reversals are a health signal, not a failure signal.** Getting something wrong and correcting it is
the mechanism that makes this method work. A run with zero reversals across many cycles is
suspicious: either the problem was trivial or the attacks are too weak. Expect many early. If they
slow to zero while gates are still `assumed`, say so and re-engage.

**A reversal that does not cascade is half done.** Conclusions built on the old belief are now silent
defects. List every one.

---

## R1 (cycle NN): "<the belief, stated as it was believed>"

- **Believed:** <the claim, and why it was plausible at the time — this matters, because a belief that
  was never plausible teaches nothing>
- **Overturned by:** <the specific evidence: file:line, a command and its output, a live observation>
- **Now believed:** <the corrected claim, with its evidence tag>
- **Cascade:** <every downstream decision, doc, gate, or test that must change. Name them
  individually. "Various docs" is not a cascade.>
  - `decisions/dr-NN.md` — <what changes>
  - Gate N — <confidence drops to X / resets to 0 passes>
  - `<test>` — <needs to be rewritten because it encoded the old belief>

---

## R2 (cycle NN): "<belief>"

- **Believed:**
- **Overturned by:**
- **Now believed:**
- **Cascade:**

---

# Known defects carried

Defects you cannot yet fix. Never let one disappear silently.

| # | Defect | Why unresolved | What would unblock it | Severity |
|---|--------|----------------|----------------------|----------|
| D1 | <defect> | <reason> | <the specific unblock> | <high/med/low> |
