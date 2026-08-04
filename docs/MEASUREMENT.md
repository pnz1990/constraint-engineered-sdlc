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

**First, check that every cited artifact still exists.** This is the cheapest audit available and it
finds real rot: on a mature board, three green BUILD rows were found citing harnesses that had been
**deleted months earlier** when an obsolete test tree was scrubbed. The rows still read
`demonstrated`, so the board asserted a rerunnable proof that nobody could run. Nothing broke loudly,
because a citation has no compiler.

```bash
# every script/evidence path cited in a gate row must resolve
grep -oE '(tests|evidence|docs)/[a-zA-Z0-9_/.-]+\.(sh|py|json)' STATUS.md | sort -u \
  | while read -r p; do [ -e "$p" ] || echo "BROKEN CITATION: $p"; done
```

Better, make it a gate of its own so it reruns forever. Two cautions learned from writing exactly
that check:

- **Judge only unambiguous rooted paths.** A first draft matched bare basenames (`results.json`) and
  brace shorthand (`evidence/x/{a.json,b.json}`) and reported **20 broken citations on a clean
  board**. A check that cries wolf gets disabled, and then the real defect arrives to an audience
  trained to ignore it. Tighten the pattern; never suppress the output.
- **A missing citation is not a missing artifact.** The same audit flagged a row whose harness existed
  and was already running — the row just never named it. Reporting that as "no proof exists" sends
  someone hunting for a file that was there all along. Distinguish *artifact absent* (downgrade the
  claim) from *citation absent* (fix the row).

Then audit for the anti-signals rather than trusting the summary:

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

### Human leverage: interventions per session, not message share

The obvious metric is the ratio of human to agent messages. In the reference run: **55 human posts
out of 610 (9%)**.

**Prefer interventions per session, paired with an outcome.** Anthropic's
[agent-autonomy analysis](https://www.anthropic.com/research/measuring-agent-autonomy) reports
internal usage where interventions per session fell **5.4 → 3.3 while success on the hardest tasks
doubled**. That pairing is the real signal: oversight cost down *and* outcome up. Message share alone
can drop for the worst reason — a human who stopped paying attention.

Also worth tracking, because the same analysis found experienced users do not reduce oversight so much
as **relocate** it: auto-approve rose from ~20% of sessions for newer users to over 40% by ~750
sessions, while interrupt rate *also* rose (~5% → ~9% of turns). Approve less, watch more. If your
auto-approve rate climbs and your interrupt rate falls to zero, you are not more efficient; you have
stopped supervising.

**Agent-initiated stops are a healthy signal, not a failure.** On the most complex work, that analysis
found agents ask for clarification more than twice as often as humans interrupt — most often to choose
between approaches (35%), gather diagnostics (21%), clarify a vague request (13%), or request
credentials (12%). A loop that never stops to ask is more suspicious than one that stops often.

Interpretation caveat: low human share is only good if quality holds. 2% human involvement with a
board full of unverified greens is worse than 20% with real ones. Read it alongside evidence movement,
never alone.

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

## Running a control arm on a single gate

You cannot A/B a multi-week run against itself. **You can A/B one gate**, and the method comes from
Thoughtworks' [refactoring economics experiment](https://martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html).

The enabling insight is that **agents are stateless, so an identical prompt replays cleanly.** In the
author's words: *"Precisely because agents never learn this was now possible to run as an experiment."*
Statelessness is usually a limitation; here it is what makes a controlled comparison possible at all.

The loop:

```
1. Define ONE representative task, phrased identically every time.
2. Measure a baseline: run it in a throwaway/sub-agent context. Record cost, time, outcome. DISCARD the work.
3. Apply one change (a refactor, a rule, a goal, a harness).
4. Re-run the SAME prompt in a fresh context. Record. DISCARD.
5. Repeat, one variable at a time.
```

Use it to answer questions this method otherwise only asserts:

- Does adding a re-executing exit condition to this gate change the outcome versus a bare prompt?
  (This is `prompt-to-goal`'s step-0 trial, formalized.)
- Does the rulebook change reduce the intervention count on a representative task?
- Is this refactor worth its cost in future work on this area?

Two disciplines borrowed from that experiment:

**Report the effect size honestly, including when it is small.** Its input tokens per change fell 83%
(159,564 → 27,360) — which the author priced at **39.7 cents** and called, in his own words, "Not a
lot." A large percentage on a small base is a small result. Say so.

**State the mechanism as a falsifiable prediction, then test it.** He claimed the saving came from the
agent *reading less*, not from less code existing — total code barely moved — which predicts that
arbitrary file-splitting would *not* help. The data matched: tokens stayed flat until the largest file
began shrinking. A measured improvement with an untested mechanism is a coincidence you have not ruled
out yet.

A caution from the same source, in the same spirit as this whole document: his token counts had to be
approximated (characters ÷ 4) because live counting was unreliable "despite showing token counts...
and **billing** for tokens." Verify your instrument before you trust its numbers.

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
