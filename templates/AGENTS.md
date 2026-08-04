# How agents work on this project

> Template. Replace every `<...>`. Seed this file, then let agents append what they learn —
> most of its eventual content should come from agents encoding their own session lessons.
> If this file and a **human** instruction disagree, the human wins and this file gets updated.

## Orient before you touch anything

1. **Sync first.** `git fetch origin` and check status before trusting local files. If several agents
   push, a fresh checkout can be many commits stale. Reconcile against the remote, not local.
   Note that `git fetch` alone does not update your working tree — merge or check the behind-count
   before you trust a local rerun, or you will test stale code.
2. **`STATUS.md` is the source of truth** for the gate board. `GOAL.md` is the objective and the
   operating contract. Read both before claiming work.
3. **Read the team channel from the top** if there is one.

## The autonomy boundary

> The single most valuable paragraph in this file. One explicit sentence here removes hundreds of
> permission round-trips. Be concrete about what is outside.

**Inside the boundary — act without asking:** <this repo, its tests, its docs, its own
infrastructure>.

**Outside the boundary — propose, then wait for explicit human approval:**
- Other teams' repositories. Prepare the change and show it; do not submit it.
- Shared or production infrastructure, and anything with real users.
- Anything irreversible or outward-facing (publishing, sending, deleting, deploying to production).

## Hard human-approval gates

Triggered by the **invariant**, not the file. A change that enforces or modifies any of these needs
human approval before it lands, not just agent review:

- Authorization or access-control logic
- Credential scoping, trust relationships, identity boundaries
- Isolation between tenants or users
- <project-specific invariants>

## Evidence discipline

- **Every material claim carries a tag:** `assumed` / `documented` / `code-verified` /
  `demonstrated`. Untagged assertions get bounced in review.
- **A gate is green only with a rerunnable proof artifact** and **two consecutive clean adversarial
  passes**, the second by a *different* agent on its *own* checkout. Any new crack resets the counter.
- **No self-declared done.** Present the gate table; a human decides.
- Prefer building the thing that finds the bug over asserting correctness. The most valuable output
  of a cycle is often the attack you could not answer.

## Look it up before you assert it

Before making any claim about how a system behaves, ground it against the real source: read the code,
query the docs, inspect the live resource. Reasoning from memory about someone else's system is the
most reliable source of confident wrong answers.

Before building on an assumption about an external component, pull its actual source. Before claiming
a deployed thing's state, go look at it.

## Review discipline

A green harness proves nothing on its own — the author can unintentionally write a test that passes
on both the broken and the fixed code. When you review, do all five:

1. **Discrimination check (the one that matters most).** Run the new/edited test against the
   **pre-fix** code. It MUST fail there. If it passes on both, it is not testing the fix.
2. **Test-not-weakened check.** If the change edits existing tests, diff them. Assertions should get
   stronger or stay the same, never loosened to pass.
3. **Rerun on your own checkout/environment**, not the author's. Environment divergence has
   repeatedly surfaced real bugs a same-machine rerun masked.
4. **Probe one edge the author's tests did not**, and confirm the fix holds there too.
5. **Do not defer to a claim.** A proposal, a status line, or another agent's "verified" is a
   *hypothesis to verify*, not a fact. Pull the actual code. A well-tested change in the wrong
   direction is still wrong. If you cannot verify it, say so explicitly and treat it as unverified —
   never launder an unchecked claim into a "confirmed."

## Harness honesty

**Three outcomes, always:**

```
0 = PASS          measured, and correct
3 = CANNOT RUN    a precondition is absent; the check refused to score
other = FAIL      measured, and wrong
```

A cannot-run is never a pass and never a failure — one hides a gap, the other sends people chasing
ghosts. Before trusting any check, ask: *if the thing I measure were absent, what would this report?*
If the answer is "pass," the check scores on nothing and must be fixed.

Beware measuring an exit code through a pipe: `cmd | tail; echo $?` reports the exit code of `tail`.

## Change flow

- **<Branch + code review for substantive work>**: code changes, decision records that change
  architecture or scope, infrastructure changes, anything a second agent should eyeball.
- **Direct to main is fine for**: typo/comment/whitespace fixes, new evidence artifacts, session
  logs, pure-doc additions that do not change existing decisions.
- **Rebase immediately before every push.** A push cut against a stale base will be rejected —
  rebase, do not force.

## Multi-agent coordination

> Delete this section if only one agent works this project.

1. **Mark who is speaking.** Agent posts start with `<AGENT MARKER>`; human posts use
   `<HUMAN MARKER>`. This matters because agents post under their human's account, so the author
   name is not a reliable discriminator. Sign posts with your identity and model, and include
   remaining session/credential time so a human knows when you are about to go dark.
2. **Humans outrank agents, always.**
3. **Claim work at FILE level before you touch it**, not gate level — collisions happen at the file.
   Check for an existing claim first. Release the claim when done.
4. **Announce a land immediately** with the commit sha, so a concurrent editor rebases instead of
   conflicting.
5. **Shared-file hotspots** — check recent history and the channel before editing:
   `STATUS.md`, `GOAL.md`, `AGENTS.md`, the harness runner, `<others>`.
6. **When you build on another agent's just-landed work, re-verify its foundation.** Do not assume a
   fresh dependency is correct; run its check on your own checkout.
7. **Hand findings to the owning agent as a data point.** Do not double-drive their lane or post a
   competing verdict on a review someone already claimed. Only take over if they are unavailable AND
   it is urgent, and say so.
8. **Append to distinct dated subsections** in shared docs rather than rewriting shared prose. Merge
   conflicts on decision records cost more than the edit. Resolve by keeping BOTH agents' additions.
9. **Correct yourself in public.** A post that says "my earlier claim was wrong, here is the real
   root cause" is what keeps a parallel fleet from building on stale conclusions.

## When to escalate to a human

Use judgment; do not reflex. A human message does not automatically require stopping. Interrupt your
human for: genuine complexity, a one-way-door or hard-to-reverse decision, a matter of taste, a change
to a working agreement, anything touching an approval gate above, or a cross-lane collision. Handle
the rest yourself. The bar is about *what merits their attention*, not permission.
