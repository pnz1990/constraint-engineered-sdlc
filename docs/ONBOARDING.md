# Onboarding

Two paths. Pick one.

- **[Path A: a new project](#path-a-a-new-project)** — you are starting a build and want the method in place from day one.
- **[Path B: a project already in flight](#path-b-a-project-already-in-flight)** — you have agents working and something is wrong: they keep declaring done, or tests are green and behavior is not.

Both assume you have an AI coding agent that can read files, run commands, and commit. Nothing here
is specific to a particular agent or model.

---

## Install the skill

**Claude Code** — copy the skill into either location:

```bash
# Personal (available in every project)
mkdir -p ~/.claude/skills/constraint-engineered-sdlc
cp SKILL.md ~/.claude/skills/constraint-engineered-sdlc/

# Or project-scoped (shared with your team via the repo)
mkdir -p .claude/skills/constraint-engineered-sdlc
cp SKILL.md .claude/skills/constraint-engineered-sdlc/
```

Invoke with `/constraint-engineered-sdlc`, or just describe the situation — the `description`
frontmatter is written so the agent picks it up on its own when you say things like "the tests pass
but it's broken" or "set up a gate board for this build."

**Any other agent** — `SKILL.md` is plain Markdown with no tool dependencies. Paste it into your
system prompt, your `AGENTS.md`, a custom instruction file, or the equivalent. The mechanisms are
process, not code.

---

## Path A: a new project

### Day 0 — Human only. Do not start an agent yet.

The temptation is to start building and write the bar later. That ordering does not work: a gate
board written after the build rationalizes what was built instead of constraining it.

**1. Confirm the preconditions.** From `SKILL.md`: a checkable bar, existing patterns to copy, and a
real target environment. If you are missing the first one, stop and sharpen the problem instead.

**2. Write `GOAL.md`.** Copy `templates/GOAL.md` and fill it in. Budget half a day and expect two
revisions. Read your first draft adversarially and ask: *where could an agent stop early and
technically claim success?* Then close that exit by name.

The section that does the most work is the prohibition list. Generic rigor ("be thorough") does
nothing. Naming the specific exit ("a single component working while the others are only described
does not satisfy this") does.

**3. Draft the gate list.** 15–35 rows. For each one write the *proof artifact you would accept*
before you write the gate description — if you cannot name the artifact, the gate is unfalsifiable
and needs rewording. The artifact is a **command plus its output**, not a file that exists.

Favor gates over *interacting* properties (isolation, ordering, teardown, credential chains). Coupling
is what makes a task hard; a gate over many independent items is easy and proves little.

Accept up front that this list will be wrong. You are writing it before you understand the problem.
Gates get added, reworded, and discovered unfalsifiable — log each revision in the reversal ledger.
A gate list that never changed means nobody learned anything.

Optional, high value: run the retrospective first. Pull real incidents from comparable systems,
map each to the gate that prevents its recurrence. This usually adds gates you would not have
thought of, and it makes the list defensible.

**Do not run `prompt-to-goal` against the project as a whole.** Its step-0 trial ("run the plain
imperative on a bounded slice and let the result overrule you") cannot be executed on a multi-week
build — there is no slice whose outcome tells you whether to write this document. That skill enters
later, per gate, at step 5 below.

**4. Create the skeleton and the rulebook.**

```bash
cp templates/GOAL.md      GOAL.md         # filled in above
cp templates/AGENTS.md    AGENTS.md
cp templates/STATUS.md    STATUS.md
cp templates/REVERSALS.md self-critique/reversals.md
mkdir -p decisions evidence tests self-critique
```

In `AGENTS.md`, the one thing you must customize is the **autonomy boundary**. One explicit sentence
about what is inside the project versus outside removes hundreds of permission round-trips. Be
concrete: name the repos, accounts, and resources that are off-limits.

### Day 1 — Start the agent, then set up the loop

**First, orient it against the bar (`/goal`):**

> Read `GOAL.md`, `AGENTS.md`, and `STATUS.md`. Then pick the highest-leverage gate that is not
> green and work it. Follow the six-step cycle and write the cycle log. Do not mark anything green
> in the cycle you build it.

**Then set up the loop (`/loop`)** — this is the step people skip, and without it the method is a
document rather than a run. A recurring prompt, every 10–60 minutes, that **re-orients before it
acts**:

> Sync (`git fetch`, read the channel for new messages). Re-read `GOAL.md` and `STATUS.md`. Pick the
> highest-leverage gate that is not green and work it. Run the six-step cycle and write the cycle
> log. Do not mark anything green in the cycle you build it. Post your findings, then report the gap.

Any scheduler works — cron, your agent's own loop command, or a shell loop with a sleep. Four things
to get right or the loop stalls unattended:

- **Report remaining session/credential time in every post**, so you know when it is about to go dark.
- **Re-read state at the start of each tick** rather than trusting in-memory context, so an
  interrupted tick is harmless.
- **Tell it to fall through when blocked.** The most common failure is idling on a human-gated
  decision. The instruction that works: *"if the open items need a human, work the gaps that don't."*
- **Make it prove a blocker before reporting one.** The instruction that works: *"a blocker is a
  claim — establish it at code-verified before you announce it, try the action once as a single bare
  command first, and say plainly when the refusal came from your own tooling rather than the system."*
  Watch for this in the posts you read: a blocker named without a query behind it is the single most
  expensive thing an unattended loop produces, because it looks like diligence, it stops real work,
  and it often points at the wrong person. In the reference run five reported blockers turned out not
  to exist; one attempt to force past a suspected block *created* a real one; and the fifth arrived
  within an hour of the agent writing this rule for itself, because the same block wearing a different
  command shape did not register as the same block. Treat a retraction as the healthy outcome, and ask
  for the working invocation to be written down rather than just the conclusion.

### Days 2–3 — Inspect live state yourself

**This is the most important thing you will do.** Not read the agent's report — open the running
system and look at it with your own tools.

In the reference run, this is where a human found that the components were deployed in exactly the
inverted topology from the product thesis, and that a resource described as a managed cluster was a
plain unmanaged one. The gate board was green through both. Agent rigor cannot catch a wrong
foundation; only someone looking at the real thing can.

Do it again around the halfway mark.

### Per gate — Decide whether it needs a formal goal

Each time an agent picks up a gate, run [`prompt-to-goal`](https://github.com/pnz1990/ai-epistemic-constraints)
step 0 **on that gate**:

1. **Trial the plain imperative** on a bounded slice of the gate. If it comes back clean, write no
   goal — just do the work and record the artifact. **This declines most of the time, and declining is
   correct**, not a failure to engage.
2. **If it survives the trial** — the gate is over coupled properties where fixing one site leaves
   another wrong — write the goal with `evidence_command` / `evidence_output` per row and a checker
   that re-executes them.
3. **Record the outcome on the board:** evidence level, pass counter, and a link to the artifact that
   re-runs.

This is what keeps the method from becoming ceremony. The heavy machinery goes on the coupled,
high-cost-of-being-wrong gates and nowhere else.

### Ongoing — Stay out of the loop

Spend your attention on the five things in `SKILL.md` ("The human's job during a run"). If you find
yourself reviewing every step, you have rebuilt the bottleneck.

### Adding more agents

Only when one agent is genuinely the constraint. The setup is a team structure, not a worker pool:

**1. One agent per real person.** Each agent runs under a specific human's identity — `alice-agent`,
`bob-agent` — inheriting that person's access, workspace, and ownership lane. This is what keeps
accountability on a human, scopes permissions without inventing a new authorization model, and makes
lanes fall out of what people already own (platform, product, operations, review).

**2. One shared Slack channel as the working memory.** Not a status feed. Agents read it at the top of
every tick and post intent, file claims, review links, findings, and corrections. A `git fetch`
catches new commits; only re-reading the channel catches a claim or a human redirect that arrived
without one.

**3. Set the emoji code on day one.** This is the highest-leverage line in the protocol:

- Agent posts begin with a **robot emoji** 🤖 (`:robot_face:`).
- Human posts use a **human emoji** 🤵 (`:person_in_tuxedo:`).
- **No robot emoji ⇒ a human wrote it ⇒ it outranks all agent traffic.**

It is load-bearing because agents post *under their human's account*, so the author name discriminates
nothing — `bob` is sometimes Bob and sometimes Bob's agent. Without the marker, agents defer to each
other's output as though a human had said it. Have agents also sign `[bob-agent / <model>]` and report
remaining session time.

**4. State that humans outrank agents, absolutely.** A human message beats any agent post, any
rulebook line, and the agent's own plan. Pair it with a judgment-based escalation bar so it does not
become reflexive — interrupt a human for one-way doors, taste, working-agreement changes, and
cross-lane collisions; handle the rest yourself.

**5. Make public self-correction expected.** A post that says "my earlier claim was wrong, here is the
real root cause" is the most valuable traffic in the channel. In a parallel fleet, a stale claim left
standing is a defect other agents will build on.

**6. Let the agents write the protocol.** Seed `AGENTS.md`, then let them append lessons from their own
sessions. Most of the reference run's rulebook was written this way — including the file-claiming rule
itself, added after two agents collided on one file. That is intended, not drift.

---

## Path B: a project already in flight

You do not need to restructure everything. Adopt in this order; each step is independently useful
and each one is cheap.

**Step 1 — Fix the exit codes (highest value, ~1 hour).**

Audit your test and check harnesses for the pass-on-nothing shape. For every check, ask: *if the
thing I measure were absent, what would this report?* If the answer is "pass," you have a check that
scores on nothing.

Introduce a third outcome and make the runner distinguish it:

```
0 = PASS          the thing was measured and is correct
3 = CANNOT RUN    a precondition is absent; the check refused to score
other = FAIL      the thing was measured and is wrong
```

Then make the summary report all three separately. A SKIP must never read as a pass, and a
cannot-run must never read as a failure — one hides a gap, the other sends people chasing ghosts.

**Step 2 — Adopt the discrimination check (~1 hour).**

For each recently "fixed" bug, check out the pre-fix commit and run the new test against it. It must
fail. Any test that passes on both the broken and the fixed code is decorative — it is not testing
the fix, and the bug can silently return.

Expect this to find something. It usually does.

**Step 3 — Start the reversal ledger (ongoing, ~0 cost).**

Create `self-critique/reversals.md` and add an entry the next time evidence overturns something you
believed. Include the cascade: every downstream decision built on the old belief. Those are silent
defects until you list them.

**Step 4 — Tag claims with evidence levels (~2 hours).**

Go through your status doc or README and tag each material claim `assumed` / `documented` /
`code-verified` / `demonstrated`. The point is not bookkeeping — it is discovering how many
load-bearing claims are actually `assumed`. That count is usually the surprise.

**Step 5 — Retrofit the gate board (~half a day).**

Now write `GOAL.md` and `STATUS.md`. It is weaker than doing it first — a board written after the
build tends to describe what exists — so counteract that deliberately: write the gates for the
launch blockers you have been *avoiding*, not the ones you have already satisfied.

**Step 6 — Require two passes by different reviewers.**

From here on, no gate goes green on the author's own confirming pass.

---

## First-week checklist

```
[ ] GOAL.md exists, with a North Star framed as an exit gate
[ ] The prohibition list names specific cheap exits, not generic rigor
[ ] Every gate names the proof artifact that would satisfy it
[ ] AGENTS.md states the autonomy boundary in one explicit sentence
[ ] STATUS.md has a row per gate: evidence level, confidence, pass counter, artifact link
[ ] Harnesses distinguish PASS / FAIL / CANNOT-RUN
[ ] A human has inspected the live system directly, not via agent report
[ ] The first cycle log exists in self-critique/
[ ] Nothing is marked green in the same cycle it was built
```

---

## Common failure modes when adopting

**"The agent marked everything green in two days."** The prohibition list is too generic. Name the
exits explicitly. Also check that gates require artifacts, not prose.

**"The reversal ledger is empty after a week."** Either the problem is trivial, or the agent is not
attacking its own work. Add an explicit instruction to produce a written attack per cycle, and check
that the three lenses are actually being applied to *its own* output rather than the problem.

**"Evidence levels are all `demonstrated` already."** Ask for the rerun command for three of them
and run them yourself. `demonstrated` means *the agent executed it and you can too*.

**"The board says green but the thing is broken."** The canonical symptom. Work Path B steps 1 and 2
immediately — you almost certainly have checks that score on nothing.

**"Multiple agents keep colliding."** Claims are at gate level, not file level. Fix the claim
granularity and add the shared-file hotspot list.

**"This is a lot of overhead."** It is, and for small tasks it is not worth it. It pays off across
many iterations on work where a confident wrong answer is expensive. If your task is neither, skip it.
