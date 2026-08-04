# Constraint-Engineered SDLC

A reusable method for running AI coding agents against a **falsifiable quality bar** instead of a task
list. Ships as a [Claude Code](https://docs.claude.com/en/docs/claude-code) skill, but the mechanisms
are process — they work with any agent, or with none.

**Companion skill:** [ai-epistemic-constraints](https://github.com/pnz1990/ai-epistemic-constraints)
ships `prompt-to-goal`, which turns one imperative prompt into a goal whose exit condition a script
re-executes. **Use both.** They cover different scopes, and each repairs the other's weak point:

```
THE RUN   (this repo)            days–weeks   endpoint unknown, gate list evolves, unmeasurable
   └─ THE GATE (prompt-to-goal)   hours       endpoint known, exit condition re-executes, measured
```

The run discovers *what the gates are*; `prompt-to-goal` proves *an individual gate*. Discovery can't
be trial-controlled — you don't know the endpoint yet, which is what the reversal ledger is for. Proof
can be, and must be, because a gate board left alone is just bookkeeping. Full treatment, including
the controlled result that makes this pairing load-bearing rather than optional:
[docs/COMPOSING.md](docs/COMPOSING.md).

---

## The problem

An agent asked to "build X" finds the earliest interpretation that technically satisfies the request
and stops. That is not dishonesty; it is the shortest path to a state that looks finished. You get a
demo: something that runs, with tests that pass, over behavior nobody verified.

Nearly every defect this method has caught reduces to one shape:

> **A green result that scores on nothing.** A precondition is absent, so a check reads empty, so the
> assertion is satisfied. Nothing failed, because nothing ran.

The same bug in different clothes: a suite whose test runtime is missing so it skips everything and
exits `0`; a probe that queries a nonexistent resource, gets an empty list, and reports "no problems";
a health check that reads a status field the component hardcodes; a test whose fixture describes a
state production cannot produce; a version bump that resolves to the identical artifact.

## The approach

Replace *instructions about how to build* with *conditions that cannot be escaped without evidence*.
The agent still picks the approach. It cannot claim completion without artifacts a skeptic can rerun.

Six mechanisms, described in full in [SKILL.md](SKILL.md):

1. **A goal document written as constraints**, not tasks — with a hard exit gate and an explicit list
   of the cheap exits the agent is forbidden to take, named individually.
2. **Gates typed BUILD or DESIGN.** BUILD needs a rerunnable artifact. DESIGN needs a decision record
   plus a falsification condition. No silent downgrades.
3. **An evidence ladder** — `assumed → documented → code-verified → demonstrated` — with confidence
   that must be justified by evidence level and drops the moment a crack appears.
4. **A six-step self-correction cycle**, driven by two primitives — **`/goal`** (re-orient against
   the bar every tick) and **`/loop`** (keep grinding autonomously for hours) — with three
   adversarial lenses turned on the agent's *own* output, plus a reversal ledger where every
   overturned belief cascades to its dependents.
5. **Two consecutive clean passes to go green**, the second by a *different* agent on its own
   checkout. This is the rule most often quietly skipped.
6. **Agents as team members**: each running under a real person's identity, coordinating in Slack,
   with a 🤖/🤵 emoji code marking who is speaking and humans outranking agents absolutely.

The two primitives are what turn the document into a run — and neither works alone:

```
/goal without /loop   →  a good bar nobody grinds against. One session, then it stops.
/loop without /goal   →  tireless motion with no bar. Drifts, repeats, declares done.
/goal + /loop         →  sustained pressure against an unfalsifiable bar.
```

If you keep only two things:

```
cannot-run is a third outcome, never a pass
a new test must FAIL on the old code
```

## Install

```bash
git clone https://github.com/pnz1990/constraint-engineered-sdlc
cd constraint-engineered-sdlc

# Personal skill (all projects)
mkdir -p ~/.claude/skills/constraint-engineered-sdlc
cp SKILL.md ~/.claude/skills/constraint-engineered-sdlc/

# Or project-scoped, shared with your team
mkdir -p .claude/skills/constraint-engineered-sdlc
cp SKILL.md .claude/skills/constraint-engineered-sdlc/
```

Invoke with `/constraint-engineered-sdlc`, or just describe the situation — the skill's `description`
is written to trigger on "the tests pass but it's broken," "the agent keeps saying it's done," and
similar. For any other agent, paste `SKILL.md` into your system prompt or instruction file.

## Start here

| If you are… | Read |
|---|---|
| Starting a new project | [docs/ONBOARDING.md](docs/ONBOARDING.md) — Path A |
| Mid-flight and something's wrong | [docs/ONBOARDING.md](docs/ONBOARDING.md) — Path B (each step is independently useful, start with step 1) |
| Adding this to an `AGENTS.md` your team already has | [docs/ADOPTING-INTO-EXISTING-AGENTS-MD.md](docs/ADOPTING-INTO-EXISTING-AGENTS-MD.md) |
| Wondering whether it worked | [docs/MEASUREMENT.md](docs/MEASUREMENT.md) |
| Already using `prompt-to-goal` | [docs/COMPOSING.md](docs/COMPOSING.md) |

Templates you can copy directly:

```
templates/GOAL.md          the constraint document (the product — budget half a day)
templates/AGENTS.md        the agent rulebook, incl. the autonomy boundary
templates/STATUS.md        the live gate board
templates/REVERSALS.md     the reversal ledger + carried-defect table
templates/run-gates.sh     working three-outcome gate runner
templates/example-gate.sh  a gate harness with preconditions and a positive control
```

## Fastest useful thing to do

If you read nothing else, audit your existing checks for the pass-on-nothing shape. For each one ask:
*if the thing I measure were absent, what would this report?* If the answer is "pass," you have a
check that scores on nothing.

Then take the pre-fix commit of your last bug fix and run the new test against it. **It must fail.**
A test that passes on both the broken and fixed code is not testing the fix, and the bug can silently
return. This usually finds something.

## Honest status of the evidence

This method came out of **one real multi-agent run** that reached a pre-production deployment — a
working pipeline, a live multi-tenant deployment, passing canary and soak validation — in five active
build days, for scope estimated at three to four months for a small team.

**That is one uncontrolled run.** There was no control arm, no pre-registration, and no parallel team
building the same thing conventionally. The estimate in the denominator is an estimate. What I can
defend is narrower and more useful: specific defects were caught by specific mechanisms, and those
mechanisms are described here so you can try them.

The companion repo is held to a much higher evidentiary standard — pre-registered trials, published
raw output, void rounds honored when their own gates fired, and every original accuracy claim refuted
by its own testing. One of its findings directly constrains this repo: **a gate that only counts
artifacts measured *worse* than no gate at all.** If your gates can be satisfied without executing
anything, you have built the arm that underperformed. That is precisely why the two skills belong
together, and [docs/COMPOSING.md](docs/COMPOSING.md) explains the fix.

Applying the evidence ladder to the two skills themselves:

| Claim | Level |
|---|---|
| A re-executing exit condition beats a bare prompt on a coupled task | `demonstrated` |
| A counting-only exit condition is worse than no gate at all | `demonstrated` |
| Coupling, not size, is what makes a task hard | `demonstrated` |
| These six process mechanisms catch real defects | `demonstrated` — they ran; defects trace to them |
| The process compresses a long build by roughly an order of magnitude | **`assumed`** — one run, no control arm |

Keep that last row visible. Use the open-ended run because the *shape* is right for discovery work,
and use the inner skill because its *effect* is measured. Do not claim the outer number.

## What it costs

Real overhead, and it only pays off across many iterations on work where a confident wrong answer is
expensive. Skip it for small well-specified tasks, throwaway experiments, and exploratory research.

It also needs three properties of your *problem*, without which it adds cost and returns little:
a checkable definition of done, existing patterns to copy, and a real target environment from day one.
If agents can only reach a simulation, they will produce a green simulation.

## License

MIT — see [LICENSE](LICENSE).
