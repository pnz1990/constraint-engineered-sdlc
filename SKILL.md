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

**This failure has a mirror, and the mirror is more dangerous socially: a cannot-run rendered as a
FAIL.** Same missing third state, opposite blast radius. When a precondition is absent, a harness that
scores it PASS inflates *your* confidence — but a harness that scores it FAIL tells *everyone else* the
system is broken. Watch for it especially on the one command that others run to participate — the
documented entry point, the "how to reproduce" script, the reviewer's first step. If that command
FAILs whenever a precondition it doesn't actually need is missing (a credential, a live backend, a
cluster), every reviewer who lacks that precondition reads "broken, not my problem" and leaves. A green
that scores on nothing fools one person; a FAIL that scores on nothing silently shrinks the pool of
people who could have caught the green. So check **both** directions of the three-state contract, and
check them on the entry point first: with each precondition absent in turn, does the runner PASS
(scores on nothing), FAIL (repels the reviewers you need), or refuse to score (correct)? A gate that
sits unreviewed for a suspiciously long time is often not waiting on volunteers — its entry point is
turning them away.

Every mechanism below is aimed at this. If you keep only one thing from this skill, keep
**cannot-run is a third outcome — never a pass, and never a failure** and **a new test must fail on the
old code.**

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
- **The prohibition list, enumerated by name — each with its reason attached.** This is the
  highest-value paragraph in the file. Say outright that the agent is prone to stopping early, and
  name the specific exits:
  - No self-declared done.
  - No gate is green without a proof artifact.
  - Naming these cheap exits: one component working while the rest are only described; "documented"
    standing in for a BUILD gate; declaring a gate out of scope without evidence; stopping at the
    first green subset.
  - Scope reductions must be **earned** — attempt the thing first, then write a decision record
    proving why it must be DESIGN instead of BUILD. Convenience is not evidence.
  - A late discovery that invalidates an early decision outranks a tidy plan. Reopen it.
  - Momentum is not evidence. Being deep into the build is not a reason to keep a shaky decision.

  **State the purpose behind each prohibition, not only the prohibition.** An enumerated list covers
  exactly the cases it enumerates; a stated reason transfers to the cases you failed to think of —
  and you will fail to think of most of them. Anthropic's
  [teaching-why result](https://www.anthropic.com/research/teaching-claude-why) found that training
  on *explanations of why* an action is right substantially outperformed training on examples of the
  right action (22% → 15% misalignment from filtered examples; **3%** when the same data carried
  explicit deliberation over the values at stake). Independently, their
  [workspace research](https://transformer-circuits.pub/2026/workspace/index.html) observed that
  "instructions to suppress a thought increase its occurrence relative to no instruction at all" and
  that control is "imperfect and sensitive to phrasing" — so a bare prohibition is a weaker
  instrument than a stated purpose plus the desired behavior. Both are findings about *training*, not
  about instruction files, so treat the transfer as plausible rather than proven — but the cost of
  adding one clause of rationale per rule is nearly zero, and the failure it guards against (brittle
  compliance that collapses just outside the enumerated cases) is the expensive one.
  See [docs/RESEARCH-NOTES.md](docs/RESEARCH-NOTES.md).
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

**Make the board's own citations a gate.** A citation is a claim, and it is the one claim nothing
verifies: no compiler checks that a row's proof artifact still exists. On a mature board, three green
BUILD rows were found citing harnesses **deleted months earlier** — the rows still read
`demonstrated` while pointing at nothing. Add a check that every cited path resolves and put it in
the regression runner; it costs a few lines and it is the difference between a board that describes
reality and one that describes the past. See [docs/MEASUREMENT.md](docs/MEASUREMENT.md) for the
version of this check and the two ways its first draft got it wrong.

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

**If the team already has an `AGENTS.md`** — most do — you are merging into a living document, not
starting one. Do not append this method wholesale: root instruction files should stay **under ~200
lines**, because longer files measurably reduce adherence to *every* rule in them, including the ones
already working. Put only the non-negotiables in the root file (three-state exit contract,
discrimination check, evidence tags, no-self-declared-done, the autonomy boundary), move harness and
review detail to **path-scoped rules** that load only when matching files are touched, and keep the
cycle loop in a skill.

> **The one class that earns space over the 200-line target: a live multi-agent coordination
> protocol.** When several agents share one codebase, the claim/land/emoji/escalation rules are the
> swarm's single point of reconstruction — they must load *every* session for *every* agent, and they
> cannot be path-scoped (a collision is not tied to a file pattern) or deferred to a skill (a skill
> loads on demand, after the agent has already decided to act). So a coordinating repo's root file
> will run longer than a solo one, and that is correct, not debt. Keep the *procedural* detail (CR
> how-to, build commands) out — that is what path-scoped rules and skills are for — but the standing
> coordination contract stays in the root. Found by dogfooding: this method's own reference project
> ran its root file to ~390 lines, and the bulk that could not move was exactly the coordination
> protocol. Trim everything else hard; do not trim the thing that stops two agents colliding.

Where a rule already exists in weaker form, **strengthen it in place** rather
than adding a parallel version — instruction files *concatenate* rather than override, so a
contradiction does not resolve, it just sits there and the agent picks one arbitrarily. Full
procedure: [docs/ADOPTING-INTO-EXISTING-AGENTS-MD.md](docs/ADOPTING-INTO-EXISTING-AGENTS-MD.md).

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

### 5. The loop — and the two primitives that make it work

Everything above is inert without a way to *keep an agent going without a human in the seat*. Two
primitives supply that, and in practice they are what turns the method from a document into a run:

**`/goal` — orient against the bar.** Load `GOAL.md` as the driving objective at the start of every
tick. The agent re-reads the North Star, the gate board, and the prohibitions, so it always knows
what "done" means and can self-assess against it rather than against its own memory of the last
tick. This is what makes the constraint document *binding* instead of decorative — a document read
once at kickoff is forgotten by hour three; a document re-read every tick keeps constraining.

**`/loop` — keep grinding, autonomously.** Re-invoke the agent on an interval, for hours, against a
time or token budget. Each invocation is a fresh **tick**: sync, orient, pick the highest-leverage
unmet gate, work it, self-attack, score, report, repeat. A single kickoff then produces dozens of
build → attack → score → correct cycles with no human per step.

The combination is the engine, and neither half works alone:

```
/goal without /loop   →  a well-specified bar nobody grinds against. One good session, then it stops.
/loop without /goal   →  tireless motion with no bar. The agent drifts, repeats itself, declares done.
/goal + /loop         →  sustained pressure against an unfalsifiable bar. This is the whole method.
```

**Implementation is deliberately boring** — a recurring prompt is all it is. Cron, a scheduler, a
`/loop`-style command in your agent, or a shell `while` loop with a sleep. The reference run used
agent-set recurring self-checks ("I've set an hourly self-check loop to keep pushing/reporting").
What matters is not the mechanism but that **each tick re-orients before it acts.**

The tick prompt that worked:

> Sync (`git fetch`, read the channel for new messages). Re-read `GOAL.md` and `STATUS.md`. Pick the
> highest-leverage gate that is not green and work it. Run the six-step cycle and write the cycle log.
> Do not mark anything green in the cycle you build it. Post your findings, then report the gap.

**Tick interval is a real tuning knob**, and different lanes want different values:

| Interval | Fits |
|---|---|
| ~1 minute | A reviewer/responder agent that must react to fleet requests quickly |
| 10–60 minutes | Normal build work — long enough to finish something, short enough to catch redirects |
| Hourly+ | Long-running verification, soaks, waiting on external systems |

**What the loop needs to survive unattended:**

- **A budget and an honest report of it.** Ticks stop when credentials or tokens run out. Have the
  agent report remaining session time in every post so a human knows when it is about to go dark.
- **Idempotent ticks.** A tick may land mid-anything. Re-reading state at the start (rather than
  trusting in-memory context) is what makes an interrupted tick harmless.
- **Something to do when blocked — and a closed list of what "blocked" means.** The most common
  failure is an agent idling on a human-gated decision. Stating "fall through to unblocked work" is
  not enough: an agent that has decided no unblocked work exists will idle while quoting that rule.
  State it as a property instead. **A tick has no power the current turn lacks.** Anything the next
  tick could do, do now; "wait for the next tick" is never a plan. A tick that produces no new work
  is valid **only** if it names a specific blocker of one of three kinds: `auth` (a credential the
  agent cannot itself obtain), `other-actor` (a decision genuinely a human's or another agent's), or
  `done` (the gate is green under a re-executing exit). Anything else — "value per tick is low",
  "nothing new to add", "holding for a reply" — is a **defect**, logged in the reversal ledger. Two
  clauses make it bite: **a blocker excuses only the lane it blocks** (the observed failure was
  naming one real blocker and using it to stop every lane), and **low value-per-tick means escalate,
  not stop** — climb read → build-in-isolation → propose-fix → verify. Make it checkable: classify
  each tick DID-WORK | IDLE-VALID | IDLE-DEFECT from its own log, seeded with ticks known to be
  defects — if it does not convict those, it measures nothing.
- **A blocker is a claim, so it needs the same evidence tag as any other.** This is the loop's
  characteristic failure and it is worse than idling: an agent that *reports* a blocker stops work,
  tells the channel someone else is the constraint, and looks diligent while doing it. In the
  reference run one agent reported four blockers that did not exist — an auto-merge tool that "hangs"
  (it was a local permission prompt), a review approval requirement that was not active on the
  package, and twice a teammate's expired credential that was not the credential in use. Each cost a
  cycle, and one did real damage: forcing the issue by adding a required reviewer *created* the block
  it was meant to route around. Require an agent to establish a blocker at `code-verified` or
  `demonstrated` before announcing it — and give it a front door cheaper than an investigation:
  **attempt the action once, as a single bare command, and read what comes back.** Most reported
  blockers die there. In the reference run the same agent hit a fifth instance within an hour of
  landing this very rule: it reported two commits stuck because "my harness is declining the push,"
  when the invocation shape was the entire problem — a compound `cd <dir> && git push` tripped a local
  permission prompt, while the direct `git -C <path> push` form went straight through, first try.
  - **A blocker you have disproved once does not get to return in a new costume.** That fifth instance
    was the *same* block the agent had already refuted and written into its own ledger earlier in the
    session; it recurred because the command *form* differed, so it was not recognized as the same
    thing. When you refute a blocker, record the working invocation, not just the conclusion — a
    principle someone has read is weaker than a command someone runs.
  - **Read the machine's answer, not the plausible story.** Query the actual API/permission state
    rather than a months-old decision record or a remembered rule.
  - **Distinguish "my sandbox refused" from "the system rejected."** A denial by your own harness,
    permission prompt, or missing tool is *your* limitation, and saying "blocked" broadcasts it as
    everyone's.
  - **Check whether the blocked party is actually blocked.** If you claim a teammate cannot act, find
    evidence they have not acted — the commit log after the alleged expiry answers this in one command.
  - **Name the binding constraint, not the first plausible one.** When several could explain the
    stall, the one you have evidence for is the only one you report.
  A wrongly-reported blocker is a *reversal* and belongs in the ledger like any other overturned
  belief. Its cascade question is the valuable one: what work did I decline to do while I believed it?
- **A visible tick log.** Posts prefixed "Loop tick —" make the run auditable and let a human drop in
  at any point and see what happened while they were away.

Each tick runs six steps, written down in `self-critique/cycle-NN.md`:

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
4. **Probe one edge the author's tests did not — and make it structurally unlike theirs**, not just
   one more case of the same shape. A suite written against the cases its author had in mind produces
   compliance that is brittle just outside them: in Anthropic's
   [teaching-why work](https://www.anthropic.com/research/teaching-claude-why) the most efficient
   training data was structurally *unlike* the target evaluation (~28× more token-efficient), while
   data closely matching the evaluation generalized poorly. Vary the *kind* of input, not the value:
   a different call path, a different lifecycle stage, a different failure mode.
5. **Do not defer to a claim.** A proposal, a status update, or another agent's "verified" is a
   hypothesis. Pull the actual code. A well-tested change in the wrong direction is still wrong.

Treat a green harness as proving nothing on its own. The author can unintentionally write a test
that passes on both the broken and the fixed code.

## Multi-agent coordination: agents as team members

Only needed if several agents work one codebase concurrently — but if they do, this section was as
determining for success as any of the six mechanisms above. The insight is not "run several agents."
It is that **agents behave like team members when you give them a team's social structure**: an
identity, a lane, a shared room, and a chain of authority.

### 1. Each agent runs as a real person's agent

Not anonymous workers. Each agent runs **under a specific human's identity**, inheriting that
person's access, workspace, and code ownership. In the reference run they were named for their
humans — `alice-agent`, `bob-agent` — and posted as those people.

Why this matters more than it looks:

- **Accountability stays with a person.** A change from Bob's agent is Bob's lane and Bob's problem.
  There is always a human who owns any given piece of work, which is what makes review, escalation,
  and "who do I ask about this" tractable.
- **Access is naturally scoped.** An agent gets exactly the permissions its human has — no more.
  You do not have to invent a separate authorization model for the fleet.
- **Steering is direct.** Each human drives their own agent, and can redirect it without
  coordinating with anyone else.
- **Lanes emerge from ownership.** People already own areas: platform, product, operations, review,
  a particular subsystem. Their agents inherit those lanes, so parallel work naturally avoids
  collisions instead of needing a scheduler.

### 2. Slack (or your equivalent) is the shared working memory

One channel, and it is not a status feed — it is where the fleet's shared picture of reality lives.
Agents read it at the start of every tick and post to it throughout. A `git fetch` catches new
*commits*; only re-reading the channel catches new *messages* — a claim, a question, a human
redirect that arrived with no commit attached.

What agents post: intent before starting, file claims, CR/review links, findings, honest gaps, and
corrections. What they get back: each other's findings, and human steering.

### 3. The emoji code: 🤖 for agents, 🤵 for humans

**This is the single highest-leverage convention in the whole protocol, and it is one line of rules.**

- **Every agent post begins with a robot emoji** (`:robot_face:` 🤖).
- **Every human post uses a human emoji** (`:person_in_tuxedo:` 🤵, or whatever you pick — just make
  it consistently human and visually distinct).
- **Both markers are required, and absence means UNKNOWN — not human.** A post carrying the human
  marker outranks all agent traffic. A post carrying **neither** marker is of *unknown* authorship:
  ask in-channel rather than treating it as human steering.

  Getting this backwards is a live hazard, not a hypothetical. The tempting shorthand — "no robot
  emoji means a human wrote it" — is **fail-open**: long posts get truncated on send in real
  channels, and a truncated agent post that loses its prefix silently promotes itself to human
  authority, which every other agent is instructed to obey over its own plan. (Observed: an
  announcement post lost its body on send and left only a footer, with the API still returning
  success.) Requiring a positive marker on *both* sides is fail-safe.

The reason this is load-bearing rather than cosmetic: **agents post under their human's account.**
So the author name tells you nothing — `bob` in the channel is sometimes Bob and sometimes Bob's
agent. Without a marker, every agent post reads as authoritative human steering, and agents will
defer to each other's output as if a human had said it. The emoji is the type system of the control
channel. It is also what lets a human scan a thread and instantly separate what was machine-generated
from what was human-directed.

Additionally, have agents **sign posts with their identity and model** (`[bob-agent / <model>]`) and
**include remaining session/credential time** ("_session: ~6h left_"), so a human knows when that
agent is about to go dark and needs re-authentication.

### 4. Humans outrank agents, always

State it as an absolute, because agents need an unambiguous precedence rule when a human's
instruction conflicts with another agent's claim, a document, or their own plan:

- **A human message is authoritative steering.** It beats any agent post, any rulebook line, and the
  agent's own in-progress plan.
- **When a human instruction and the written rules disagree, the human wins** — and the rules get
  updated to match.
- **Humans redirect with short messages.** A one-line human correction mid-run is the cheapest
  possible intervention, and in practice it is how the biggest course changes happened.

Balance this with judgment so it does not become reflexive: a human post does **not** automatically
require stopping and asking. Interrupt your human for **a choice between viable approaches** (the
single most common reason agents stop, at 35% of self-initiated stops), one-way doors, matters of
taste, changes to a working agreement, approval-gated changes, missing credentials, or cross-lane
collisions. Handle the rest yourself. The bar is *what merits their attention*, not permission. (In
the reference run an early agent tagged its human on **every** human post; the fix — a
judgment-based escalation bar — was written into the rulebook by that human.)

**Do not mandate approval of every action.** Anthropic's
[agent-autonomy analysis](https://www.anthropic.com/research/measuring-agent-autonomy) found that
requiring approval for everything "will create friction without necessarily producing safety
benefits"; the test that matters is whether a human is *positioned to monitor and intervene*. The
same data shows experienced users approve *less* and interrupt *more* — oversight relocated, not
reduced. Design for visibility and easy intervention rather than gates on every step. And expect a
healthy loop to stop and ask on its own: on complex work, agents raise clarifying questions more
than twice as often as humans interrupt them.

### 5. The mechanics that prevent collisions

- **Claim work at FILE level before touching it, not gate level.** "I have gate 3" is not enough;
  collisions happen at the file. Check for an existing claim first, and release it when done.
- **Announce a land with the commit sha** ("landed `<file>` at `<sha>` — pull before you edit"), so a
  concurrent editor rebases instead of conflicting.
- **Keep a shared-file hotspot list** — the board, the rulebook, the harness runner — and check
  recent history plus the channel before editing one.
- **Rebase immediately before every push.** The fleet pushes concurrently.
- **Append to dated subsections** in shared docs rather than rewriting shared prose. Resolve
  conflicts by keeping *both* agents' additions.
- **Hand findings to the owning agent as a data point.** Do not double-drive someone else's lane or
  post a competing verdict on a review another agent already claimed — a second agent's attention is
  the scarce resource.

### 6. Correct yourself in public

Posts that open *"three of my own claims were wrong"* or *"retracting a blocker I raised an hour
ago — it was a query artifact"* are **the most valuable traffic in the channel**, more than any
milestone announcement. In a fleet working in parallel, a stale claim left standing is a defect that
other agents will build on. Public self-correction is what keeps the shared picture true.

Make it explicitly safe and expected: a retraction is a contribution, not an admission of failure.
This is the reversal ledger's discipline applied to the team channel.

### 7. Let the agents write the protocol

Seed the rulebook, then let agents append what they learn from their own sessions. In the reference
run most of the eventual rulebook came from agents encoding their own hard-won lessons — the review
checklist, the escalation bar, the file-claiming rule itself (written after two agents collided on
one file). That is the intended behavior, not drift: they hit the friction, so they write the rule.

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
- Ticks report "no unblocked work left" while unread sources, unbuilt harnesses, or undrafted diffs remain.

## Quick reference

Print this and stick it on the wall:

```
cannot-run is a third outcome — never a pass (fools you), never a FAIL (repels reviewers)
check both directions of the exit contract on the entry point first
a new test must FAIL on the old code
a proof artifact RE-EXECUTES; if it only counts, it is worse than nothing
the second pass is a different agent, on its own checkout
confidence drops the moment you find a crack
a reversal that does not cascade is half done
scope reductions are earned, not assumed
the gate list is an output of the run, not just an input
a tick has no power this turn lacks — "wait for the next tick" is never a plan
/goal every tick, not once at kickoff — /loop keeps the pressure on
🤖 marks an agent, 🤵 marks a human; NEITHER marker = unknown, ask (never assume human)
humans outrank agents, always
retracting your own claim in public is a contribution, not a failure
no self-declared done — present evidence, a human decides
```
