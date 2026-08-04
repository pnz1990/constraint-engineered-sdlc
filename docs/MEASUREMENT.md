# Measuring success

The method makes claims about itself. Those claims should be held to the same standard the method
imposes on everything else — so this document is about instrumenting it honestly, including the ways
the numbers can lie.

## The headline claim, and how not to fool yourself with it

The reference run reached a pre-production deployment in **five calendar days** for scope estimated
at **three to four months** for a small team.

Both halves of that ratio are soft, and you should say so when you quote it:

- The denominator is an **estimate**, not a measurement. Nobody ran the control arm. There is no
  parallel universe where the same team built the same thing conventionally.
- "Five days" was five *active* days inside a longer wall-clock window, with hardening continuing
  afterward. Quote it as active build days and let people ask.
- Scope comparability is the weakest link. A prototype that mirrors existing patterns is not the same
  work as a from-scratch production service, even when the artifact list looks similar.

**What you can defend instead:** count the artifacts that exist and are rerunnable, and let the
reader draw the comparison. "Thirty-four rerunnable harnesses, twenty-six decision records, a
working deployment pipeline, and a live multi-tenant deployment, in N active days" is checkable.
"Ten times faster" is not.

## Instrumenting a run

All of these come from the repo itself, so they are cheap and hard to fake.

> **Read this first, because it undercuts everything below.** Every metric in this section is
> *bookkeeping* — counts of tags, gates, and reversals. A controlled comparison found that an exit
> condition which only counts deliverables scored **worse than no gate at all**, while one that
> re-executed evidence beat the baseline. So these numbers are diagnostic, not causal: use them to
> catch relabeling and stalls, never as evidence that the work is good. The thing that makes the work
> good is that each artifact re-runs. Spot-check by rerunning three of them, every time you read this
> board. See [COMPOSING.md](COMPOSING.md).

### Evidence movement

The core question: are claims climbing the ladder, or just accumulating?

```bash
# Distribution of evidence tags across all docs
grep -rho '\[assumed\]\|\[documented\]\|\[code-verified\]\|\[demonstrated\]' --include='*.md' . \
  | sort | uniq -c | sort -rn
```

Record this weekly. What you want: `demonstrated` rising, `assumed` falling, **total** roughly
stable or growing. What is suspicious: `assumed` dropping while `demonstrated` does not rise — that
is relabeling, not progress.

A cycle in which no evidence level moved and no reversal was logged was wheel-spinning. The method
requires saying so in the gap report rather than hiding it.

### Reversals

```bash
grep -c '^## R' self-critique/reversals.md
```

Reversals are a **health signal, not a failure signal.** Expect many early. If they fall to zero
while gates are still `assumed`, the agent has stopped inspecting and started rubber-stamping.

Quality check, not just count: does each entry name its **cascade** — the downstream decisions that
had to change? A reversal without a cascade is half done, and the conclusions built on the old
belief are silent defects.

### Gate board integrity

Audit for the anti-signals rather than trusting the summary:

```bash
# Gates claiming green — verify each links an artifact that exists
grep -n '🟢\|GREEN' STATUS.md

# Pass counters: anything green at 1/2 is mislabeled
grep -n '1/2' STATUS.md
```

Then spot-check three green gates by running their artifacts yourself. This is the single most
informative twenty minutes you can spend on a board.

### Harness honesty

The measurement that matters most, because it is where the method's core failure mode lives:

```bash
# Does the runner distinguish three outcomes?
grep -n 'CANNOT RUN\|SKIP\|exit 3' tests/run-*.sh
```

Then test the harness against absence: remove a precondition and confirm the check reports
cannot-run rather than pass. A harness that has never been tested against a missing precondition
has an untested claim at its center.

Track over time: **PASS / FAIL / CANNOT-RUN counts per run.** A rising cannot-run count is not
decay; it is often the harness becoming more honest about what it never actually verified. Report
it as such rather than hiding it.

### Human leverage

If you use a shared channel, the ratio of human to agent messages is a direct proxy for leverage.
In the reference run: **55 human posts out of 610 (9%)**.

Interpretation matters here. Low human share is only good if quality holds — 2% human involvement
with a board full of unverified greens is worse than 20% with real ones. Read it alongside evidence
movement, never alone.

### Defect provenance

The most meaningful lagging indicator: **who found the bugs?**

Classify each defect as found by (a) your own harnesses, (b) an agent's adversarial pass, (c) a
human reviewer, or (d) users/production. As the method takes hold, (a) and (b) should dominate.
Every (d) is a gate that did not exist or a check that scored on nothing — trace it back and add the
gate. That trace is the retrospective loop closing.

### Reproducibility

The only true test of a BUILD gate: hand `REPRODUCE.md` to someone who has never seen the project
and watch them, without helping. Every place they get stuck is a gap in the document, not a gap in
them.

Do this at least once with a genuinely independent person. Self-reproduction proves that your
machine works.

## A worked scoreboard

What a weekly readout looks like:

| Week | demonstrated | code-verified | documented | assumed | reversals | green gates | cannot-run |
|---|---|---|---|---|---|---|---|
| 1 | 12 | 40 | 95 | 88 | 5 | 2 | 3 |
| 2 | 78 | 210 | 300 | 140 | 9 | 14 | 7 |
| 3 | 190 | 380 | 450 | 165 | 13 | 24 | 6 |
| 4 | 276 | 481 | 559 | 173 | 16 | 34 | 4 |

Read it as: total claims grow (the map of the problem is expanding), `demonstrated` grows fastest,
`assumed` grows slowly and is never zeroed, reversals keep accruing. **`assumed` never reaching zero
is correct.** A board that reports zero unknowns is not finished; it has stopped looking.

## Honest reporting checklist

Before publishing results:

```
[ ] Speed claims state active build days, not calendar span
[ ] Any "N× faster" comparison is labeled an estimate with no control arm
[ ] Artifact counts are stated plainly and are checkable
[ ] Gates at one clean pass are reported amber, not green
[ ] Gates green on the author's own confirming pass are flagged
[ ] SKIP / cannot-run counts are reported, not folded into passes
[ ] The assumed-claim count is published, not hidden
[ ] Known open defects are listed with what would unblock them
[ ] Reproduction was verified by someone other than the author
```

The last one is the whole method applied to its own results. If you cannot pass your own checklist,
report what you have and name the gap — which is exactly what the method asks of every gate.
