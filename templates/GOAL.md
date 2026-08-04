# Goal: <PROJECT NAME>

> Template. Replace every `<...>`. Delete the instruction blockquotes when done.
> Budget half a day and expect two revisions. This document is the product.

## How this goal is written

This is a constraint engineering document, not a task list. It is written to keep the agent building.

An agent will look for the earliest interpretation that technically satisfies the objective and then
stop. That behavior is a defect here. This work only has value if **every** condition below is met,
because the model being proven depends on all of them holding at once. A partial result proves nothing.

Therefore:

* The objective is **not** satisfied until every gate is green **and backed by a named proof artifact
  a reviewer can open and rerun**.
* You may not declare done. You may only present evidence. Done is a state of the artifacts, not a
  claim you make.
* If you find yourself wanting to stop, that is the signal you have hit a lazy local optimum. Re-read
  the open gates, pick the next unmet one, and keep building.
* "I documented it" is not "I did it." BUILD gates require a running, reproducible artifact. DESIGN
  gates require a decision record with evidence. Do not downgrade a BUILD gate to DESIGN to escape.

## North Star (a hard exit gate, not a target)

> One paragraph. What must be true, concretely, for this to be real. Name the actual end state — a
> running thing in a real environment, not a description of one. This is a wall, not a finish line
> you can wave at.

<NORTH STAR>

Every design decision is documented, falsifiable, and deterministic. If a claim cannot be proven from
code, docs, or a running experiment, it is logged as an open question with a resolution plan, never
asserted.

## Evidence levels

Every material claim carries a tag:

| Tag | Means |
|---|---|
| `assumed` | A hypothesis. No proof. |
| `documented` | Backed by a doc, spec, or ticket. |
| `code-verified` | Backed by a file and line you actually read. |
| `demonstrated` | Backed by a run you executed and can rerun. |

A **BUILD** gate is not green below `demonstrated`. A **DESIGN** gate is not green below
`code-verified` or `documented` **plus an explicit falsification condition**.

Also carry **confidence**: your honest probability the claim survives the next attack. Confidence is
justified by evidence level, never by how long you have believed it. High confidence on `assumed`
evidence is a lie you are telling yourself — flag it.

## Two consecutive clean passes to rest

Before any gate goes green, complete **two consecutive cycles that fail to break it with new
evidence**, and **the second pass must be run by a different agent on its own checkout.** One clean
pass can be luck or a weak attack. Any new crack resets the counter.

## Definition of Done

> 15-35 rows. For each: write the proof artifact you would accept BEFORE the description. If you
> cannot name the artifact, the gate is unfalsifiable — reword it.
>
> A proof artifact is a command plus the output it produced, which a reviewer re-runs and compares.
> It is NOT "a file exists." A gate satisfiable without executing anything is bookkeeping, and
> bookkeeping gates have measured *worse* than no gate at all. See docs/COMPOSING.md.
>
> Prioritize gates over INTERACTING properties (isolation, ordering, teardown, credential scoping
> across a trust chain). Coupling is what makes a task hard — a gate over a big pile of independent
> items is easy and proves little.
>
> THIS LIST WILL BE WRONG. You are writing it before you understand the problem, which is
> unavoidable: the gate list is an output of the run as much as an input to it. Gates get added,
> reworded, and found unfalsifiable. Log every revision in the reversal ledger. A gate list that
> never changed means nobody learned anything.
>
> When an agent picks up an individual gate, that is the moment to run `prompt-to-goal` step 0 on it
> (trial the plain imperative; usually decline; if it survives, write a re-executing exit condition).
> Do NOT run step 0 against this document as a whole — a multi-week build has no trialable slice.

You are done only when every row is green with a linked proof artifact and `STATUS.md` shows no red
rows. Missing any single row means you keep building.

**<Category: e.g. Core functionality>**
1. <Gate statement.> [BUILD]
2. <Gate statement.> [DESIGN]

**<Category: e.g. Reliability and degraded mode>**
3. <Behavior under dependency outage, demonstrated.> [BUILD + DESIGN]
4. <Capacity limits with measured inputs.> [BUILD + DESIGN]

**<Category: e.g. Security and isolation>**
5. <Isolation between tenants/users proven with a passing adversarial test.> [BUILD]
6. <Credential scoping / trust chain demonstrated end to end.> [BUILD + DESIGN]

**<Category: e.g. Lifecycle>**
7. <Upgrade demonstrated + policy designed.> [BUILD + DESIGN]
8. <Dependency ordering and teardown demonstrated.> [BUILD]

**<Category: e.g. Operability>**
9. <Alarms/dashboards live; they fire and clear on an injected fault.> [BUILD]
10. <Deployment safety: rollout and automated rollback demonstrated.> [BUILD + DESIGN]

**<Cross-cutting>**
11. Reproducible: a reviewer who has never seen this follows `REPRODUCE.md` and gets the same result. [BUILD]
12. All decision records complete; the self-critique log shows the correction history. [DESIGN]

## Anti-laziness mechanics

These exist because the easy stopping points are traps. Obey them literally.

1. **No self-declared done.** You never say the objective is met. You present the gate table; a human
   reads it and decides.
2. **A gate is green only with a proof artifact.** BUILD: a rerunnable script/test plus its output.
   DESIGN: a decision record with evidence. Prose without an artifact is not green.
3. **Cheap exits are forbidden.** These do NOT satisfy the objective, and reaching for one is proof
   you are in a lazy local optimum. **Each entry states WHY — an enumerated list covers only what it
   enumerates, while a stated purpose transfers to the exits nobody thought to list. When you meet a
   shortcut not on this list, reason from the purposes below rather than concluding it is permitted:**
   - <One component working while the others are only described.> — *the model being proven depends
     on all of them holding at once; one working component demonstrates nothing about the whole.*
   - <The happy path running while the isolation/failure gate is unproven.> — *the happy path is the
     case that was going to work anyway; the value of this project lives in the failure modes.*
   - "documented" standing in for a BUILD gate. — *a description of a behavior is not evidence the
     behavior occurs; only a run is.*
   - Declaring a gate out of scope without an evidence-backed reason. — *convenience is
     indistinguishable from impossibility unless you attempted it and wrote down what stopped you.*
   - Stopping at the first green subset. — *the first green subset is where progress feels best and
     is least informative; the unattacked remainder is where the defects are.*
4. **Every iteration ends with a gap report.** List the gates not yet green and pick the next to
   attack. If any gate is red, you are not done.
5. **Scope reductions must be earned, not assumed.** If you believe a gate cannot be built, first
   attempt it, then write a decision record proving why it must be DESIGN, with evidence.
   Convenience is not evidence.
6. **`STATUS.md` is the source of truth.** If it shows red gates, the run continues.
7. **Falsify before you rest.** Before considering a gate green, make one honest attempt to break it.
   If you cannot, record the attempt as the proof. If you can, it is not green.
8. **A late discovery outranks a tidy plan.** If a late cycle invalidates an early foundational
   decision, reopen it and cascade — even though it is expensive and you are close to a clean board.
   Protecting a tidy result by ignoring a real crack is the most damaging laziness available.
9. **Momentum is not evidence.** Being deep into the build is not a reason to keep a shaky decision.
   Sunk cost carries zero weight against new falsifying evidence.

## Anti-convergence rules

* You may not raise a claim's confidence in a cycle where you added no evidence for it.
* You may not mark a gate green in the same cycle you first built it; the confirming pass is a later
  cycle with a fresh attack.
* If two cycles produce no evidence movement and no reversals, stop iterating on this path, switch
  gates, and say why in the gap report.
* Treat "interestingly wrong and corrected" as more valuable than "safely vague."

## The iteration loop

Each cycle is numbered and recorded in `self-critique/cycle-NN.md`. Six steps, none skipped:

1. **State intent.** What you set out to prove, and which gate it advances.
2. **Do the work.**
3. **Red-team yourself.** Produce a *written* attack from each lens, then answer it:
   - *Engineer:* did you read the source and run it, or assume? A behavioral claim with no file:line
     or executed run behind it is a guess in a lab coat.
   - *Product:* is anyone actually better off, or did you just make something run?
   - *Operator:* what breaks at scale, who gets paged, what is the blast radius?
4. **Score it.** Update evidence level and confidence for everything touched. Confidence rises only
   with new evidence and drops the moment you find a crack, even if you cannot fix it yet.
5. **Diff against the past.** Did anything you previously believed just become false? Cascade it to
   every dependent decision (`self-critique/reversals.md`).
6. **Report the gap.** What is red, what got worse, what got better, and the single most important
   thing to attack next.

## Grounding

> Point at the real systems, prior art, and existing patterns this should mirror. An agent starting
> from a blank page invents; an agent pointed at three working implementations copies — which is
> faster and more correct. Name repos, services, docs, and the incidents you are trying not to repeat.

<GROUNDING>

## Known constraints

> State the non-negotiables up front: what must not be touched, what must stay reversible, what is
> out of scope and why.

<CONSTRAINTS>
