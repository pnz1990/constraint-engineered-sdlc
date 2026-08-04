# Composing with `prompt-to-goal`

This skill has a sibling: **[ai-epistemic-constraints](https://github.com/pnz1990/ai-epistemic-constraints)**,
which ships `skills/prompt-to-goal/`. Use them together. They are not alternatives, and they are not
the same thing at two sizes — they do different jobs, and **each one covers the other's known weak
point.**

## The one-paragraph version

The long-horizon run **discovers what the gates are.** `prompt-to-goal` **proves an individual gate.**
Discovery cannot be trial-controlled, because you do not yet know the endpoint — that is what the
reversal ledger is for. Proof can be, and must be. So: run the open-ended loop at project scope, and
write a re-executing exit condition at gate scope. Neither substitutes for the other.

```
constraint-engineered-sdlc  ─── the RUN (days to weeks, open-ended, unmeasurable)
  North Star as an exit gate
  ~30 gates, discovered and revised as you learn
  evidence ladder, reversal ledger, human inspecting live state
  │
  │  for each gate you are about to attack
  ▼
prompt-to-goal              ─── the GATE (hours, bounded, measurable)
  step 0: should this even get a goal?   ← usually no
  step 1: exit condition must RE-EXECUTE, not count
  step 2: evidence_command + evidence_output, pasted verbatim
  step 3: a checker re-runs it and compares
  │
  ▼
  a proof artifact that a reviewer re-runs → the gate reaches `demonstrated`
```

The handoff is exact: this skill's **`demonstrated`** evidence level and `prompt-to-goal`'s
**re-executing exit condition** are the same requirement stated at two scopes. A gate reaches
`demonstrated` precisely when someone else can run the command and get the same output.

## The tension, stated honestly

`prompt-to-goal` step 0 is emphatic: run the plain imperative on a bounded slice first, and **let the
trial overrule your judgment.** Decline unless the items are coupled.

**That rule is unrunnable at project scope, and you should not pretend otherwise.** There is no
bounded slice of "build a managed multi-tenant capability with isolation, rollback, and a deployment
pipeline" whose outcome tells you whether to write the constraint document. You cannot A/B a five-day
build against yourself. The trial requires a task with a knowable end state; a long-horizon run is
the case where the end state is *what you are discovering.*

So:

- **Do not apply step 0 to the project.** The constraint document is not a `prompt-to-goal` artifact.
  It is a different genre: prohibitions, an exit gate, and a gate list that will be wrong and get
  revised. Its job is to keep an agent building and stop it declaring victory — not to be
  machine-evaluable in one command.
- **Do apply step 0 to every gate.** Here the trial is cheap and real: run the plain imperative on
  the gate, see if it comes back clean, and if it does, write no goal. Most gates should decline.
  This is what stops the method drowning in ceremony.

## Why the unmeasured outer loop is still the right shape

`prompt-to-goal` optimizes *accuracy on a known task*. That is a different objective from the one the
long-horizon run serves, which is **finding out which properties matter at all.**

Look at what the outer loop actually produced in the reference run, none of which a per-task goal
could have produced:

- **Sixteen reversals**, several overturning foundational decisions made on day one. You cannot
  pre-register a gate list that contains the discovery that your architecture is inverted.
- **Gates that did not exist when the run started** — added because a retrospective of comparable
  systems surfaced a failure class nobody had listed.
- **Two human catches from inspecting live state**, where the board was green and the deployed
  topology was backwards. No exit condition catches that; the exit conditions were passing.

That is discovery work, and its output *is* the gate list. Then each gate becomes a bounded task —
and bounded tasks are exactly where `prompt-to-goal`'s measured mechanism applies.

Put plainly: the open run earns the right to be unmeasured because its product is a set of questions.
Each answer to those questions must then be measured, and that is not optional.

## The finding that makes this composition load-bearing

`ai-epistemic-constraints` Round 8, three arms on one task:

```
                                  bare prompt   counting gate   evidence gate
semantic defect audit, strict           29.8%          21.7%          60.0%
                       lenient          64.9%          55.0%          75.6%
```

**The counting gate scored below the bare prompt.** An exit condition that only verified bookkeeping —
every item listed, counts agree, artifacts present — was *worse than no gate at all.*

**A gate board is structurally a counting predicate.** It is a table of rows with checkmarks. Left
alone, it is the arm that lost: ceremony that enforces nothing. What converts it into the arm that
won is that **each row's proof artifact re-executes.** `prompt-to-goal` is how you write that.

So the composition is not a nice-to-have. Without the inner skill, this repo's central artifact
defaults to the shape that measured *worse than doing nothing.*

The rule that follows, and it is non-negotiable:

> A gate's proof artifact is **a command plus the output it produced**, which a reviewer re-runs and
> compares. Not "a file exists." Not "the harness is present." If a gate can be satisfied without
> executing anything, rewrite it or delete it.

An uncomfortable corollary, stated because the method demands it: **the evidence-tag counts in
[MEASUREMENT.md](MEASUREMENT.md) are bookkeeping.** They are useful for catching relabeling and
stalls, but by this finding they are not the mechanism that improves outcomes. The re-execution is.
Never let a rising `demonstrated` count substitute for someone rerunning three of them.

## What a gate looks like on each side of the seam

**Gate row on the board** (this skill) — the bookkeeping half, which is fine as long as the artifact
column points at something that re-executes:

| # | Gate | Type | Evidence | Passes | Proof artifact |
|---|---|---|---|---|---|
| 9 | Tenants cannot read each other's credentials | BUILD | demonstrated | 2/2 | `tests/test-isolation.sh` + `evidence/09/results.json` |

**The gate's own goal** (`prompt-to-goal`) — the half that does the enforcing:

```
GOAL: no tenant can read another tenant's credential material

## Deliverable
One row per attack attempted:
  <attack> | <target> | <expected: denied> | <observed>

Every row must carry:
  evidence_command: the command that attempts the attack
  evidence_output:  its raw output, pasted verbatim, not summarized

## Exit condition, evaluated by a script you do not control
Every evidence_command is re-executed in a clean subprocess. A row passes only if the
re-run output matches the pasted evidence_output after whitespace normalization, AND the
output shows a denial. A claim of "denied" without the output is not demonstrated.
An attack you did not run is marked UNVERIFIED, not passed.
```

Note the seam: the board says *what must be true and how many passes it has.* The goal says *what
command proves it.* Neither is sufficient alone — the board without the command is bookkeeping, the
command without the board has no memory across a long run.

## When step 0 declines, ask what artifact it *is* pointing at

Found while applying this to a real gate, and worth naming because the first reading of step 0 sends
you to the wrong place.

`prompt-to-goal` step 0 asks whether the items interact and whether one command could produce the
work list. If the work is greppable, it says decline — correctly, because an exit condition over a
one-shot grep measures nothing.

**But a gate is not a one-time task. It is a property that must keep holding.** So "one command
produces the work list" does not mean *no artifact is needed*; it often means the right artifact is a
**regression check** rather than a goal document.

Worked example. A gate read "no forked code from other teams; every delta logged," tagged BUILD, with
a markdown document recording a six-step manual audit as its proof. Step 0 on it:

- *Do the items interact?* Barely — a fork can appear in the module file, in source provenance
  comments, in an applied patch, or as a copied directory, and finding one tells you nothing about the
  others. Leans decline.
- *Can one command produce the work list?* Largely yes, it is greppable. Decline again.
- *So write nothing?* **No.** The gate's own falsification condition was "any fork entry or external
  CR resets this to red" — a standing invariant. The audit document could only ever describe one
  moment, and would silently go stale on the next commit.

The resolution: **decline the goal document, write the harness.** Four greppable checks plus a
positive control, wired into the regression runner, discrimination-proven against four injected
violations and one cannot-run. The gate moved from `code-verified` to `demonstrated` because there is
now a command that re-executes.

The general rule:

| Step 0 says | The task is | Write |
|---|---|---|
| Decline — items independent, work greppable, **one-time** | A one-off fix or audit | Nothing. Do it, record the output. |
| Decline — items independent, work greppable, **standing property** | An invariant that must keep holding | A **regression check** in the runner |
| Proceed — items coupled | Interlocking work | A goal with a re-executing exit condition |

The middle row is the one people miss, and it is where most gate rows actually land.

## Two more findings worth importing

**Difficulty comes from coupling, not size.** Round 9: two 12,079-line corpora, same generator, same
15 seeded defects; the only difference was whether the defects were *chained* so fixing one leaves
the property violated. **19.2% vs 80.4% — a 61-point drop from coupling alone.** Size was near
ceiling at 1.5k and 12k lines alike.

For gate design: prioritize gates over *interacting* properties — isolation between tenants, ordered
teardown, credential scoping across a trust chain, dependency ordering. A gate over a big pile of
independent items is easy and proves little, however impressive the row count. This is also why a
30-row board is not 30 times better than a 10-row board; what matters is how many rows sit on coupled
properties.

**Declining is the common correct answer.** Step 0 rejects most tasks. Import that discipline per
gate: the heavy machinery goes on the coupled, high-cost-of-being-wrong gates. A method that wraps
everything in ceremony is the overhead complaint made real.

## How a human actually drives both

The division of labour that fell out of the reference run:

1. **Human writes the constraint document** (`templates/GOAL.md`) — North Star, prohibitions, the
   first draft of the gate list. Half a day. This is not a `prompt-to-goal` output.
2. **Human or agent picks the next gate** from the board.
3. **Run `prompt-to-goal` step 0 on that gate.** Trial the plain imperative. If it comes back clean,
   no goal — just do it and record the artifact. This declines most of the time.
4. **For the gates that survive step 0** — the coupled ones — write the goal with
   `evidence_command`/`evidence_output` and a checker that re-runs them.
5. **The board records the outcome:** evidence level, pass counter, and a link to the artifact that
   re-executes.
6. **The reversal ledger absorbs what this teaches you about the gate list itself** — including gates
   that were wrong, missing, or unfalsifiable as written. That feeds back into step 1.

Step 6 closing back onto step 1 is the loop that the per-task skill cannot supply on its own, and
step 3–4 is the enforcement the long run cannot supply on its own.

## Honest comparison of evidence

The two repos are not equally evidenced, and conflating them would be the exact failure both exist to
prevent.

`ai-epistemic-constraints` has pre-registered trials, sealed expectations, published raw output, void
rounds honored when their own gates fired, and every original accuracy claim refuted by its own
testing. Its surviving claims are narrow and stated as ranges (+10 to +30 points, with the lenient
metric failing correction).

**This repo has one uncontrolled run.** No control arm, no pre-registration, no parallel team. Its
mechanisms are described because they ran and because specific defects were caught by specific
mechanisms — a causal story, not a measured effect. The speed claim is an estimate against an
estimate.

Applying the evidence ladder to the two skills themselves:

| Claim | Level |
|---|---|
| A re-executing exit condition beats a bare prompt on a coupled task | `demonstrated` (pre-registered, published, range-stated) |
| A counting-only exit condition is worse than no gate | `demonstrated` |
| Coupling, not size, drives difficulty | `demonstrated` |
| The six process mechanisms catch real defects | `demonstrated` (they ran; defects are traceable to them) |
| The process compresses a long build by ~10× | `assumed` (one run, no control) |

That last row is the one to keep visible. Use the outer loop because the shape is right for
discovery; use the inner skill because its effect is measured. Do not claim the outer number.

## Install both

```bash
# process layer — the run
git clone https://github.com/pnz1990/constraint-engineered-sdlc
mkdir -p ~/.claude/skills/constraint-engineered-sdlc
cp constraint-engineered-sdlc/SKILL.md ~/.claude/skills/constraint-engineered-sdlc/

# task layer — the gate
git clone https://github.com/pnz1990/ai-epistemic-constraints
mkdir -p ~/.claude/skills/prompt-to-goal
cp ai-epistemic-constraints/skills/prompt-to-goal/{SKILL.md,TEMPLATE.md} ~/.claude/skills/prompt-to-goal/
```

Then in your project's `AGENTS.md`:

```markdown
## Method
Two skills, two scopes. Do not use one where the other belongs.

- **The run** — gate board, evidence ladder, cycle loop, review discipline:
  `constraint-engineered-sdlc`. The gate list is expected to be wrong at first and to be
  revised; log every revision in the reversal ledger.
- **A gate** — writing any individual gate's exit condition: `prompt-to-goal`.
  - Run its step-0 trial on the gate first. Declining is usually correct.
  - No exit condition that merely counts. It must re-execute.
  - Do NOT run step 0 against the project as a whole — it is not a trialable task.
```
