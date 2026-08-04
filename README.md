# Constraint-Engineered SDLC

A reusable method for running AI coding agents against a **falsifiable quality bar** instead of a task
list. Ships as a [Claude Code](https://docs.claude.com/en/docs/claude-code) skill, but the mechanisms
are process — they work with any agent, or with none.

**Companion skill:** [ai-epistemic-constraints](https://github.com/pnz1990/ai-epistemic-constraints)
converts a single imperative prompt into a verifiable declarative goal. This repo is the process
around it. See [docs/COMPOSING.md](docs/COMPOSING.md) — including a finding there that constrains
how you should write gates here.

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
4. **A six-step self-correction cycle** with three adversarial lenses turned on the agent's *own*
   output, plus a reversal ledger where every overturned belief cascades to its dependents.
5. **Two consecutive clean passes to go green**, the second by a *different* agent on its own
   checkout. This is the rule most often quietly skipped.
6. **A file-level coordination protocol** for multiple agents on one codebase.

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

The companion repo, [ai-epistemic-constraints](https://github.com/pnz1990/ai-epistemic-constraints),
is held to a much higher evidentiary standard — pre-registered trials, published raw output, void
rounds honored, and every original accuracy claim refuted by its own testing. One of its findings
directly constrains this repo: **a gate that only counts artifacts measured *worse* than no gate at
all.** If your gates can be satisfied without executing anything, you have built the arm that
underperformed. [docs/COMPOSING.md](docs/COMPOSING.md) explains what to do about it.

Applying this method's own standard to itself: the mechanisms are `demonstrated` (they ran, and caught
things). The efficiency claim is `assumed`. Stated plainly rather than dressed up — which is the whole
point.

## What it costs

Real overhead, and it only pays off across many iterations on work where a confident wrong answer is
expensive. Skip it for small well-specified tasks, throwaway experiments, and exploratory research.

It also needs three properties of your *problem*, without which it adds cost and returns little:
a checkable definition of done, existing patterns to copy, and a real target environment from day one.
If agents can only reach a simulation, they will produce a green simulation.

## License

MIT — see [LICENSE](LICENSE).
