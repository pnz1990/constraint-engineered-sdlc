---
name: constraint-engineered-sdlc
description: Run an AI coding agent (or a fleet of them) against a falsifiable quality bar instead of a task list. Use when starting a substantial build with agents, when an agent keeps declaring work "done" that isn't, when green tests coexist with broken behavior, or when you need multiple agents working one codebase in parallel without collisions. Sets up a gate board, an evidence ladder, adversarial self-correction, and a coordination protocol.
---

# Constraint-Engineered SDLC

## What this is for

An agent asked to "build X" will find the earliest interpretation that technically satisfies the
request and stop. That is not dishonesty; it is the shortest path to a state that looks finished.
The result is a demo: something that runs, with tests that pass, over behavior nobody verified.

This skill replaces *instructions about how to build* with *conditions that cannot be escaped
without evidence*. The agent still chooses the approach. It just cannot claim completion without
producing artifacts a skeptic can rerun.

Use it when the cost of a confident wrong answer is high, and when the work is big enough that you
cannot personally review every step.

**Do not use it for** small well-specified tasks, throwaway experiments, or exploratory research
where the goal is to learn rather than to ship. The overhead is real and only pays off across many
iterations.

## The core failure mode this exists to catch

Almost every defect this method has caught in practice reduces to one shape:

> **A green result that scores on nothing.** A precondition is absent, so a check reads empty, so
> the assertion is satisfied. Nothing failed, because nothing ran.

Examples of the same bug wearing different clothes:
- A test suite whose runtime dependency is missing, so it skips every case and still exits `0`.
- A probe that queries a resource that does not exist, gets an empty list, and reports "no problems."
- A health check that reads a status field the component hardcodes, rather than observing behavior.
- A test whose fixture describes a state that cannot occur in production.
- A version bump that resolves to the identical artifact, so nothing changed.

Every mechanism below is aimed at this. If you keep only one thing from this skill, keep
**cannot-run is a third outcome, never a pass** and **a new test must fail on the old code.**

## Two scopes, two skills

This skill governs **the run**: an open-ended, long-horizon build where you do not yet know the
endpoint. Its product is as much *the discovery of which properties matter* as the code — which is why
it has a reversal ledger and why its gate list is expected to change.

It pairs with **[`prompt-to-goal`](https://github.com/pnz1990/ai-epistemic-constraints)**, which
governs **a gate**: one bounded task, where the exit condition can be written as a command whose
output a script re-runs. That skill's effect is measured; this one's is not.

```
THE RUN   (this skill)          days–weeks   endpoint unknown, gate list evolves
   └─ THE GATE (prompt-to-goal)  hours       endpoint known, exit condition re-executes
```

The seam is exact: a gate reaches this skill's **`demonstrated`** level precisely when it has
`prompt-to-goal`'s **re-executing exit condition.**

Two rules that follow, and getting them backwards is the common mistake:

- **Do not** run `prompt-to-goal`'s step-0 trial against the whole project. There is no bounded slice
  of a five-day build whose outcome tells you whether to write the constraint document, and you cannot
  A/B a long run against yourself. The constraint document is a different genre — prohibitions and an
  exit gate, not a machine-evaluable predicate.
- **Do** run it against every individual gate. There the trial is cheap and real, and it will tell you
  to skip the ceremony most of the time. Declining is the common correct answer.

Full treatment, including the controlled-comparison result that makes this composition load-bearing:
[docs/COMPOSING.md](docs/COMPOSING.md).

## Setup: the six mechanisms

Work through these in order. Steps 1–3 are human work and come before any agent builds anything.

### 1. Write the goal document (human, half a day)

This document is the product. Everything else derives from it. Create `GOAL.md`:

- **A North Star written as a hard exit gate, not a target.** State plainly that the agent may not
  declare completion — it may only present evidence, and a human decides. Phrase it as a wall, not
  a finish line.
- **The gate list.** 15–35 rows depending on scope. Each row gets a type:
  - **BUILD** — requires a rerunnable script or test plus its recorded output.
  - **DESIGN** — requires a decision record with evidence *and a falsification condition*.
  - Cover the unglamorous launch blockers, not just the feature: availability and degraded-mode
    behavior, failure isolation between tenants/users, authorization and credential scoping,
    deployment safety and rollback, upgrade and migration, dependency ordering and teardown,
    capacity limits, cost, observability, reproducibility by a stranger.
  - **Prioritize gates over *interacting* properties.** Difficulty comes from coupling, not size: in
    a controlled comparison, chaining defects so that fixing one leaves the property violated dropped
    scores from 80.4% to 19.2%, while corpus size barely mattered. A gate over a big pile of
    independent items is easy and proves little, however impressive the row count.

  **Expect this list to be wrong.** You are writing it before you understand the problem, which is
  unavoidable — the gate list is an output of the run as much as an input to it. Gates will be added,
  reworded, and found unfalsifiable. Log every such revision in the reversal ledger. A gate list that
  never changed is a sign nobody learned anything.
- **The prohibition list, enumerated by name.** This is the highest-value paragraph in the file.
  Say outright that the agent is prone to stopping early, and name the specific exits:
  - No self-declared done.
  - No gate is green without a proof artifact.
  - Naming these cheap exits: one component working while the rest are only described; "documented"
    standing in for a BUILD gate; declaring a gate out of scope without evidence; stopping at the
    first green subset.
  - Scope reductions must be **earned** — attempt the thing first, then write a decision record
    proving why it must be DESIGN instead of BUILD. Convenience is not evidence.
  - A late discovery that invalidates an early decision outranks a tidy plan. Reopen it.
  - Momentum is not evidence. Being deep into the build is not a reason to keep a shaky decision.
- **Grounding.** Point at the real systems, prior incidents, and existing patterns the work should
  mirror. An agent starting from a blank page invents; an agent pointed at three working
  implementations copies. Copying is faster and more correct.

Revise it at least twice. The first draft always reads as a wish list and lets the agent win early.

### 2. Create the skeleton (human, minutes)

The agent needs somewhere to put evidence *while working*, not afterward.

```
GOAL.md          the objective and the operating contract (step 1)
AGENTS.md        the binding rulebook (step 3)
STATUS.md        the live gate board — the source of truth
REPRODUCE.md     exact steps for a reviewer who has never seen this
decisions/       one record per meaningful tradeoff
self-critique/   numbered cycle logs + reversals.md
evidence/        one directory per gate, holding proof artifacts
tests/           the harnesses
```

`STATUS.md` carries, for every gate: evidence level, confidence, clean-pass counter,
proof-artifact link, and a current gap report. Declare historical sections **append-only** —
two agents rewriting shared prose is the worst merge conflict you will hit.

Optional but high value: do a **retrospective first**. Collect real incidents from comparable
systems and map each to the gate that prevents its recurrence. This is what makes the gate list
credible rather than invented, and it usually adds gates you would not have thought of.

### 3. Write the rulebook (human seeds it, agents grow it)

`AGENTS.md` holds the non-negotiable operating rules. Seed it with the escalation boundary and the
review discipline (below), then **let agents append to it.** In practice most of its eventual
content comes from agents encoding lessons from their own sessions — that is the intended behavior,
not drift. Include:

- The autonomy boundary, stated once and explicitly. One sentence of the form *"everything inside
  this project is yours; touching anything outside it needs my approval"* eliminates hundreds of
  permission round-trips. Be specific about what is outside: other teams' repositories, shared
  infrastructure, production resources, anything with real users.
- Hard human-approval gates, triggered by the **invariant**, not the file: authorization logic,
  credential scoping, trust relationships, isolation boundaries, anything irreversible or
  outward-facing.
- The review checklist (step 6).
- A standing instruction to look up existing patterns with real tools before asserting anything
  about how a system behaves. Reasoning from memory about someone else's system is the most
  reliable source of confident wrong answers.

### 4. The evidence ladder

Every material claim carries a tag. Untagged assertions get bounced in review.

| Tag | Means |
|---|---|
| `assumed` | A hypothesis. No proof. |
| `documented` | Backed by a doc, spec, or ticket. |
| `code-verified` | Backed by a file and line the agent actually read. |
| `demonstrated` | Backed by a run the agent executed and can rerun. |

A BUILD gate is not green below `demonstrated`. A DESIGN gate is not green below `code-verified`
or `documented` **plus an explicit falsification condition** — what would have to be true for this
to be wrong.

**`demonstrated` has a specific meaning: a command, plus the output it produced, that someone else
re-runs and compares.** Not "a harness exists." Not "the artifact is present." This distinction is
the difference between the two arms of a controlled comparison, where an exit condition that only
counted deliverables scored *worse than no gate at all* while one that re-executed evidence beat the
baseline by a clear margin. A gate board is structurally a counting predicate; what rescues it is
that every row's artifact re-executes. See [docs/COMPOSING.md](docs/COMPOSING.md) — this is what the
companion skill `prompt-to-goal` is for, and it is not optional.

Also track **confidence**: the honest probability the claim survives the next attack. Confidence
must be justified by evidence level, never by how long it has been believed. High confidence on
`assumed` evidence is self-deception and should be flagged as such.

**Keep the `assumed` count visible.** The instinct is to drive it to zero by relabeling. The
number is a feature: it is the honest map of what you do not know.

### 5. The loop

There is no special tooling required. A recurring prompt (cron, a scheduler, or a loop command)
pointed at a session that re-reads `GOAL.md`, `STATUS.md`, and the team channel at the start of
each tick. Each tick runs six steps, written down in `self-critique/cycle-NN.md`:

1. **State intent** — what you are proving, which gate it advances.
2. **Do the work.**
3. **Red-team yourself.** Three lenses, each producing a *written* attack you then answer:
   - *Engineer:* did you read the source and run it, or assume the behavior? A claim about how a
     system behaves that has no file:line or executed run behind it is a guess in a lab coat.
   - *Product:* is anyone actually better off, or did you just make something run?
   - *Operator:* what breaks at scale, who gets paged, what is the blast radius?
4. **Score it.** Update evidence level and confidence for everything touched. Confidence rises
   only with new evidence, and **drops the moment you find a crack**, even unfixed.
5. **Diff against the past.** Did anything previously believed just become false? Cascade it.
6. **Report the gap.** What is red, what got worse, and the single most important next attack.

**Anti-convergence rules** (these prevent the loop from becoming theater):
- May not raise a claim's confidence in a cycle where no evidence was added for it.
- May not mark a gate green in the same cycle it was built. The confirming pass is a later cycle
  with a fresh attack.
- Two cycles with no evidence movement and no reversals means the current path is exhausted —
  switch gates and say why in the gap report.

**The reversal ledger** (`self-critique/reversals.md`) is the engine, not the confessional. Format:

```
## R7: "<what was believed>"
- Believed: <the claim, and why it was plausible>
- Overturned by: <the specific evidence>
- Now believed: <the corrected claim>
- Cascade: <every downstream decision that must change>
```

A reversal that does not cascade is half done — conclusions built on the old belief are now silent
defects. **Reversals are a health signal.** A run with zero reversals across many cycles means
either the problem was trivial or the agent stopped attacking. Expect many early; if they stop
while gates are still `assumed`, say so and re-engage.

### 6. Two passes, and how to actually review

**A gate goes green only after two consecutive cycles that fail to break it with a fresh attack.**
Any new crack resets the counter. One clean pass can be luck or a weak attack.

**The second pass must be a different agent, on its own checkout.** This is the rule most often
quietly skipped, and skipping it is self-review with extra steps. If the author of a fix ran the
confirming pass, the gate stays amber and the board should say why.

When reviewing a change (yours or another agent's), do all five:

1. **Discrimination check — the one that matters most.** Run the new test against the *pre-fix*
   code. It **must fail** there. If it passes on both the broken and fixed versions, it is not
   testing the fix.
2. **Test-not-weakened check.** If the change also edits existing tests, diff them. Assertions
   should get stronger or stay the same, never loosened to pass.
3. **Rerun on your own machine.** Environment divergence — a missing tool, a stale build, an
   unmerged branch — has repeatedly surfaced real bugs that a same-machine rerun masked.
4. **Probe one edge the author's tests did not.**
5. **Do not defer to a claim.** A proposal, a status update, or another agent's "verified" is a
   hypothesis. Pull the actual code. A well-tested change in the wrong direction is still wrong.

Treat a green harness as proving nothing on its own. The author can unintentionally write a test
that passes on both the broken and the fixed code.

## Multi-agent coordination

Only needed if several agents work one codebase concurrently.

- **One agent per human identity**, each inheriting that person's access and owning a lane
  (e.g. platform, product, operations, review). Accountability stays with a person.
- **A shared channel is the working memory.** Agents read it at the start of every tick and post
  intent, claims, findings, and corrections.
- **Mark who is speaking.** Use one marker for agent posts and a different one for human posts.
  This matters more than it sounds: if agents post under their human's account, the author name is
  useless as a discriminator and every agent post reads as authoritative human steering. Have
  agents sign posts with their identity and model, and include remaining session/credential time so
  a human knows when the agent is about to go dark.
- **Humans outrank agents, always.**
- **Claim work at file level before touching it, not at gate level.** "I have gate 3" is not enough;
  collisions happen at the file. Check for an existing claim first. Announce the land with the
  commit sha so a concurrent editor rebases instead of conflicting.
- **Maintain a shared-file hotspot list** — the board, the rulebook, the harness runner — and check
  recent history plus the channel before editing one.
- **Correct yourself in public.** Posts that open "three of my own claims were wrong" are what keep
  a parallel fleet from building on stale conclusions. This is the single most valuable habit in the
  channel, more than the milestone announcements.
- **Hand findings to the owning agent as a data point.** Do not double-drive someone else's lane or
  post a competing verdict on a review another agent already claimed.

## The human's job during a run

Small and specific. In a measured run of this method, human messages were **9% of channel traffic**.
Spend them on:

1. **Independently inspecting live state, early.** Do this by day two or three. The two most
   valuable corrections in the reference run both came from a human looking at the running system
   directly and finding that the architecture was inverted from the product thesis — while the gate
   board was green. No amount of agent rigor catches a foundation that is wrong; only someone
   looking at the real thing does.
2. **Setting the autonomy boundary once**, explicitly (step 3).
3. **Answering genuine judgment calls** and rejecting shortcuts that carry hidden cost.
4. **Unblocking what agents structurally cannot do** — approvals, permissions, cross-team asks.
5. **Asking the inverting question when progress stalls:** "What do you need from me?"

Resist reviewing every step. If you are in the loop continuously, you have rebuilt the bottleneck
the method exists to remove.

## Preconditions — check before adopting

This method needs three properties of the *problem*. Without them it adds overhead and returns little:

1. **A bounded problem with a checkable bar.** If you cannot write down what done looks like
   specifically enough that an agent can self-assess and you can verify against artifacts, there is
   nothing for the constraints to grip.
2. **Existing patterns to copy.** Much of the speed comes from agents finding and mirroring proven
   implementations. On true greenfield they invent instead, which is where they are weakest.
3. **A real target environment from day one.** Not a mock. If agents can only reach a simulation,
   they will produce a green simulation.

## Success criteria

Judge the method, not the vibe. See `docs/MEASUREMENT.md` for how to collect these.

**Leading indicators (during the run)**
- Evidence levels move **up** over time and the `assumed` count trends down — without relabeling.
- Reversals are being logged, and each one cascades to named dependents. Zero reversals over many
  cycles is a red flag, not a green one.
- Every gate marked green links to an artifact a stranger can rerun.
- Second passes are done by a *different* agent than the author.
- Human share of coordination traffic stays low (roughly ≤15%) without quality dropping.

**Lagging indicators (after)**
- A reviewer who has never seen the project follows `REPRODUCE.md` and gets the same result.
- Defects found by *your own harnesses* outnumber defects found by users or reviewers.
- Artifacts survive the prototype: the tests, decision records, and pipelines are reused rather
  than thrown away.

**Anti-signals — the method is being performed rather than practiced**
- Gates flip green in the same cycle they were built.
- Confidence rises in cycles where no evidence was added.
- The reversal ledger is empty while gates sit at `assumed`.
- SKIP or cannot-run outcomes are being counted as passes.
- The second pass is run by the author of the change.
- `STATUS.md` disagrees with the artifacts it links to.

## Quick reference

Print this and stick it on the wall:

```
cannot-run is a third outcome, never a pass
a new test must FAIL on the old code
a proof artifact RE-EXECUTES; if it only counts, it is worse than nothing
the second pass is a different agent, on its own checkout
confidence drops the moment you find a crack
a reversal that does not cascade is half done
scope reductions are earned, not assumed
the gate list is an output of the run, not just an input
no self-declared done — present evidence, a human decides
```
