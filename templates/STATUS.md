# Gate board: <PROJECT NAME>

> The source of truth. If this file shows red rows, the run continues.
> Historical sections are **append-only** — add dated subsections rather than rewriting prose.
> Two agents rewriting shared narrative is the worst merge conflict class on this project.

Last updated: <DATE> — <one-line summary of where things stand>

**Evidence levels:** `assumed` → `documented` → `code-verified` → `demonstrated`.
BUILD gates green only at `demonstrated`. DESIGN gates green only at `code-verified`/`documented`
plus a falsification condition. **Green requires two consecutive clean passes, the second by a
different agent on its own checkout.** Any crack resets the counter.

## The board

| # | Gate | Type | Evidence | Confidence | Passes | Proof artifact | Status |
|---|------|------|----------|-----------|--------|----------------|--------|
| 1 | <gate statement> | BUILD | demonstrated | 0.85 | 2/2 | `tests/test-01.sh` + `evidence/01/results.json` | 🟢 |
| 2 | <gate statement> | DESIGN | code-verified | 0.8 | 2/2 | `decisions/dr-02-....md` (falsifier: <what would make this wrong>) | 🟢 |
| 3 | <gate statement> | BUILD | demonstrated | 0.8 | 1/2 | `tests/test-03.sh` — **amber: the author of the fix ran this pass, so it is not the independent second one** | 🟡 |
| 4 | <gate statement> | BUILD | assumed | 0.3 | 0/2 | none yet | 🔴 |

Legend: 🟢 green (2 clean passes) · 🟡 one pass, or a known caveat · 🔴 not proven

> Amber is not a failure state — it is honesty about the pass counter. A gate whose confirming pass
> was run by the author of the change stays amber and says so.

## Current gap report

**Not green:** <list>

**Next attack (single most important thing):** <one item, and why it is the highest leverage>

**Got better this cycle:** <what moved up the evidence ladder, with the evidence>

**Got worse this cycle:** <cracks found, confidence drops — including ones you cannot fix yet>

**Known defects carried:** <defect, why unresolved, what would unblock it>

## Open questions

| Question | Why it matters | Resolution plan | Status |
|---|---|---|---|
| <question> | <consequence if wrong> | <how it will be settled> | open |

## <DATE> — <dated subsection title>

> Append new findings here. Never rewrite an earlier subsection: it records a true sequence, and the
> sequence is often the most useful part. If a later finding supersedes an earlier one, say so
> explicitly in the new subsection and cite what it supersedes.

<content>
