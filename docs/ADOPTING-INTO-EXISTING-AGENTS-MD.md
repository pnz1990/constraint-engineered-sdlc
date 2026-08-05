# Landing these rules in an `AGENTS.md` a team already has

Most teams adopting this method already have an `AGENTS.md` (or `CLAUDE.md`, `.cursorrules`,
`.github/copilot-instructions.md`). You are not starting a file — you are **merging into someone
else's living document**, which is a different and more delicate job.

The honest starting point: **the [AGENTS.md](https://agents.md/) convention has no merge spec.** It
defines nearest-file precedence and nothing about combining two sets of rules. So the practices below
are assembled from what the ecosystem actually documents and from what large real-world files do.

---

## What the ecosystem actually specifies

Worth knowing before you design your rollout, because three of these constrain the approach:

**1. Nearest file wins; user prompts beat everything.** For monorepos you add `AGENTS.md` files
inside packages, and agents read the nearest one in the directory tree. Conflicts resolve by
proximity to the edited file, not by merge.

**2. Files concatenate rather than override.** In Claude Code, every discovered memory file is
concatenated into context, ordered from filesystem root down to the working directory — so a
project instruction is read *after* a user instruction, and a nested file after its parent. Nothing
is replaced. **This means a contradiction between two files does not resolve; it just sits there,
and the agent may pick either one arbitrarily.** Contradiction is the failure mode to design against.

**3. Size degrades adherence.** Target **under 200 lines** per file. Longer files consume more
context and are followed less reliably. This is the single hardest constraint on "just append our
rules," and it is why the layering below matters. *One principled exception:* a live **multi-agent
coordination protocol** (claim/land/marker/escalation rules) must load every session for every agent
and cannot be path-scoped or deferred to a skill, so a coordinating repo's root file legitimately runs
longer. Trim everything else hard; keep the coordination contract. (This method's own reference repo
ran to ~390 lines for exactly this reason — the irreducible remainder was the protocol.)

**4. Imports exist, but do not save context.** `@path/to/file` expands at launch — good for
organization, useless for size. Import parsing skips code spans, so `` `@thing` `` in backticks stays
literal.

**5. Path-scoped rules are the real size lever.** In Claude Code, `.claude/rules/*.md` with `paths:`
frontmatter load **only when the agent touches matching files**. That is how you add substantial
rules without taxing every session.

**6. One file can serve many agents.** `AGENTS.md` is read natively by many tools; Claude Code reads
`CLAUDE.md`, so the documented bridge is a `CLAUDE.md` containing `@AGENTS.md` (plus any
Claude-specific lines below it), or a symlink if you need nothing extra.

**7. Instructions are context, not enforcement.** No memory file guarantees compliance. For anything
that *must* happen at a specific moment, use a hook or a CI check. Pair every rule with an
enforcement path where one exists.

---

## The layering decision: what goes where

Do not dump this method into the root file. Split by *who needs it when*:

| Content | Where | Why |
|---|---|---|
| The non-negotiables: three-state exit contract, discrimination check, evidence tags, "no self-declared done", the autonomy boundary | **Root `AGENTS.md`**, ~15–30 lines total | Every agent, every session, every file. This is the irreducible core. |
| Harness/test conventions, review checklist detail | **Path-scoped rule** (`paths: ["tests/**", "**/*_test.*"]`) | Only matters when touching tests. Keeps the root file small. |
| The full cycle loop, reversal-ledger format, three-lens self-attack | **A skill**, or `GOAL.md` | A multi-step procedure, not a standing fact. Loads on demand. |
| Multi-agent coordination: emoji code, file claiming, hotspots | **Root `AGENTS.md`** if you run a fleet; omit entirely if not | Cheap, and useless-but-harmless when unused. |
| Per-subsystem specifics | **Nested `AGENTS.md`** in that package | Nearest-file precedence does the routing for you. |

The rule of thumb: **root file = standing facts an agent needs in every session. Everything
procedural or conditional goes to a rule or a skill.**

---

## The merge procedure

### 1. Read the existing file first, and inventory what is already there

Half of what you would add is usually present in some form. Adding a second version of a rule the
team already has is how you create the contradiction that makes an agent pick arbitrarily.

For each rule you intend to introduce, classify it:

- **Already covered** → leave it alone. Do not restate.
- **Covered but weaker/negative** → *strengthen in place*, do not add a parallel rule. (Concrete
  example from the reference project: the file said "a message with no 🤖 is from a human," which is
  fail-open. The fix was editing that line to add a positive human marker — not adding a new bullet
  elsewhere saying the same thing differently.)
- **Genuinely absent** → add it, in the section where it belongs topically.
- **Contradicted** → this is a *human decision*, not an edit. Raise it; do not silently overwrite a
  rule someone put there deliberately.

### 2. Match the house style

Read how the existing file phrases things and match it. Real-world files converge on:

- **Imperative, second person.** "Never add X", "Run Y before committing" — not "developers should
  consider".
- **Graded strength, deliberately.** `Prefer` for defaults, `Avoid` for soft bans, `Never`/`MUST`
  for hard ones. Do not make everything a MUST; if all rules are absolute, none are.
- **Thresholds as numbers, not adjectives.** "under 500 lines", "10K tokens" — not "keep it small".
- **Rationale inline, briefly.** State the *why* so the agent is not over-literal, and so a future
  maintainer knows whether the rule still applies. One clause is enough.
- **Explicit exemptions**, or agents apply rules where they do not belong.
- **Link to the authority instead of restating it.** Point at the lint, the doc, the runner. A
  restated rule drifts from its source; a link cannot.

### 3. Anchor every rule to an enforcement path

The strongest convention in mature files: each rule names the thing that checks it — a lint, a CI
job, a `make` target, a test. This turns a rule from aspirational into checkable, and it tells a
skeptical reader the rule is real.

```markdown
- **Three exit states in every harness — cannot-run is never a pass.**
  Enforcement: `run_gate` in `tests/run-gates.sh`; `tests/test-skip-rollup.sh` guards the roll-up.
```

If a rule has no enforcement path, say so explicitly ("no automated check; caught in review") rather
than implying one exists.

### 4. Cite the origin for anything that came from a human decision

Attribute directives, with a date, and quote them where the wording matters:

```markdown
### The autonomy boundary (human directive, 2026-07-14 — verbatim)
> "Everything belonging to this project is ok. The only thing you can't do is touch other
> packages or infra/accounts without my consent."
```

Two reasons this pays off. It tells a future agent that the rule is *not* an agent's invention and
must not be relaxed unilaterally. And a rule with a date can be re-litigated with its author; an
anonymous rule just accretes forever.

### 5. Land it the way the team lands code

A rulebook change is a working-agreement change, so it goes through review — **especially** if agents
authored it. Do not push it straight to the main branch.

State in the change description: what you added, what you *strengthened in place* and why the old
wording was unsafe, and what you deliberately left alone. Reviewers can then check the diff for the
thing that actually matters — a silently weakened rule.

### 6. Let the file grow from real friction

The most durable rules are written by whoever hit the problem. In the reference project, most of the
eventual rulebook came from agents encoding their own session lessons — the review checklist, the
escalation bar, and the file-claiming rule (added after two agents collided on one file).

So: seed the core, then add a rule **each time a mistake recurs**. The trigger to write one is a
correction you have now typed twice.

---

## Multi-tool repos

If the team uses several agents, keep **one source of truth** and bridge to it:

```bash
# Claude Code reads CLAUDE.md; bridge without duplicating
printf '@AGENTS.md\n' > CLAUDE.md          # plus any Claude-specific lines below
# or, if you need nothing extra:
ln -s AGENTS.md CLAUDE.md
```

Other tools need a pointer in their own config (for example `read: AGENTS.md` in `.aider.conf.yml`,
or setting the context filename for Gemini CLI). If you are migrating a legacy filename, the
documented move is to rename and leave a symlink behind for compatibility.

**Never maintain two copies of the same rules.** They diverge, and then the agent has two
contradictory instructions and picks one arbitrarily — which is worse than having no rule.

---

## Anti-patterns

**Appending a 200-line block to a root file.** Blows the size budget and drops adherence for
*everyone's* rules, including the ones that were working. Layer it instead.

**Adding a rule that already exists in different words.** Creates the contradiction that makes an
agent choose arbitrarily. Strengthen in place.

**Silently rewriting a rule someone added deliberately.** Raise the conflict; it is a human call.

**Rules with no enforcement and no rationale.** They read as boilerplate and get ignored — or worse,
followed over-literally in a case they were never meant for.

**Duplicating the file per tool.** Guaranteed divergence.

**Restating what the code already says.** Directory layouts and dependency lists are derivable and go
stale. Keep the file for pitfalls, rationale, and conventions that differ from tool defaults.

---

## Checklist

```
[ ] Read the existing file end to end before writing anything
[ ] Every intended rule classified: covered / weaker / absent / contradicted
[ ] "Weaker" ones strengthened IN PLACE, not duplicated elsewhere
[ ] Contradictions raised with a human, not overwritten
[ ] Root file under ~200 lines — OR longer only because a multi-agent coordination protocol must load every session (the one principled exception)
[ ] Procedural and conditional content moved to path-scoped rules or a skill
[ ] House style matched: imperative, graded strength, numeric thresholds
[ ] Every rule names its enforcement path, or admits it has none
[ ] Human directives quoted, dated, attributed
[ ] One source of truth; other tools bridged by import or symlink
[ ] Landed through code review, with strengthened wording called out in the description
```
