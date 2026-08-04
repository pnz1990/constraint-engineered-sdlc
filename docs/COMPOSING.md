# Composing with `prompt-to-goal`

This skill has a sibling: **[ai-epistemic-constraints](https://github.com/pnz1990/ai-epistemic-constraints)**,
which ships `skills/prompt-to-goal/`. The two are designed to be used together and they operate at
different scopes.

| | `prompt-to-goal` | `constraint-engineered-sdlc` (this one) |
|---|---|---|
| **Scope** | One task | A whole build, over days or weeks |
| **Question** | "What exit condition would prove this task is done?" | "What process keeps many such tasks honest?" |
| **Output** | A goal document with a machine-evaluable exit condition | A gate board, evidence ladder, cycle loop, coordination protocol |
| **Lifetime** | Minutes to hours | The duration of the project |
| **Empirical status** | Pre-registered trials, published raw output | One uncontrolled run (see caveat below) |

In one line: **`prompt-to-goal` writes the goal. This skill runs the process around it.**

## How they fit together

The gate board defined by this skill is a list of things to prove. `prompt-to-goal` is how you turn
any single one of those into an exit condition a script can evaluate.

```
constraint-engineered-sdlc  ──  GOAL.md, ~30 gates, evidence ladder, cycle loop
                                        │
                                        │  for each gate you are about to attack
                                        ▼
prompt-to-goal              ──  step 0: should this even have a goal?  (usually no)
                                step 1: exit condition must RE-EXECUTE, not count
                                step 2-3: write it, enforce it
                                        │
                                        ▼
                                a BUILD gate whose proof artifact is a command
                                whose output a verifier re-runs
```

The handoff point is precise: this skill's **`demonstrated` evidence level** and `prompt-to-goal`'s
**re-executing exit condition** are the same requirement stated at two scales. A gate reaches
`demonstrated` exactly when someone else can run the thing and get the same answer.

## The finding you must not ignore

`ai-epistemic-constraints` Round 8 compared three arms on the same task:

```
                                  bare prompt   counting gate   evidence gate
semantic defect audit, strict           29.8%          21.7%          60.0%
                       lenient          64.9%          55.0%          75.6%
```

**The counting gate scored below the bare prompt.** An exit condition that only verifies bookkeeping
— every item listed, counts agree, artifacts present — was *worse than no gate at all*, under both
scorings. It added cost and negative value.

This is a direct hazard for the method in this repo. A gate board is structurally close to
bookkeeping: it is a table of rows with checkboxes. If a gate is satisfied by *the existence of an
artifact* rather than by *re-running it and comparing the result*, you have built the arm that
underperformed a bare prompt.

**So apply this rule when writing gates:**

> A gate's proof artifact is not "a file exists." It is a command, plus the output it produced, that
> a reviewer re-runs and compares. If a gate could be satisfied without executing anything, rewrite
> it or delete it.

The corollary is uncomfortable and worth stating: **the evidence-tag counts in `MEASUREMENT.md` are
bookkeeping.** They are useful for spotting relabeling and stalls, but by this finding they are not
the mechanism that improves outcomes. The re-execution is. Do not let a rising `demonstrated` count
substitute for someone actually rerunning three of them.

## Two more transferable findings

**Difficulty comes from coupling, not size.** Round 9: two 12,079-line corpora, same generator, same
15 seeded defects. The only difference was whether the defects were *chained* so that fixing one
leaves the property violated. Scores were **19.2% versus 80.4% — a 61-point drop from coupling
alone.** Corpus size was near ceiling at 1.5k and 12k lines alike.

For gate design: prioritize gates over *interacting* properties — isolation between tenants, ordered
teardown, credential scoping across a trust chain, dependency ordering. A gate over a big pile of
independent items is easy and proves little, however impressive the row count.

**Declining is the common correct answer.** `prompt-to-goal` step 0 rejects most tasks and tells you
to run the plain imperative on a bounded slice first — and to let that trial overrule your judgment.
Import that discipline here: not every gate needs a formal goal document, and a method that wraps
everything in ceremony is the overhead complaint made real. Use the heavy machinery on the coupled,
high-cost-of-being-wrong gates.

## Honest comparison of evidence

The two repos are not equally evidenced, and the difference should be stated plainly.

`ai-epistemic-constraints` has pre-registered trials, sealed expectations, published raw output, void
rounds honored when their gates fired, and every original accuracy claim refuted by its own testing.
Its surviving claims are narrow and stated as ranges.

**This skill has one uncontrolled run.** No control arm, no pre-registration, no parallel team
building the same thing conventionally. Its mechanisms are described because they were used and
because specific defects were caught by specific mechanisms — that is a causal story, not a measured
effect. The speed claim is an estimate against an estimate.

Treated honestly, the split is: `prompt-to-goal` tells you *which* constraints demonstrably work at
task scale; this repo tells you *how to organize a long multi-agent run*, and that organization is
so far unmeasured. Both are worth using. Only one has been tested.

## Install both

```bash
# process layer
git clone https://github.com/pnz1990/constraint-engineered-sdlc
mkdir -p ~/.claude/skills/constraint-engineered-sdlc
cp constraint-engineered-sdlc/SKILL.md ~/.claude/skills/constraint-engineered-sdlc/

# task layer
git clone https://github.com/pnz1990/ai-epistemic-constraints
mkdir -p ~/.claude/skills/prompt-to-goal
cp ai-epistemic-constraints/skills/prompt-to-goal/{SKILL.md,TEMPLATE.md} ~/.claude/skills/prompt-to-goal/
```

Then, in your project's `AGENTS.md`:

```markdown
## Method
- Process, gate board, evidence ladder, review discipline: `constraint-engineered-sdlc`
- Writing any individual gate's exit condition: `prompt-to-goal`
  - Run its step-0 trial first. Declining to write a goal is usually correct.
  - No exit condition that merely counts. It must re-execute.
```
