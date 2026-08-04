# Research notes: what external evidence backs (and doesn't back) this method

This method rests on one uncontrolled run. Where published work bears on a mechanism here, it is
recorded below — including work that was **read and deliberately not incorporated**, because a
selective reading list is a way of manufacturing authority.

Each entry states what the source actually claims, what changed here as a result, and how far the
claim transfers. A finding about *training* is not a finding about *instruction-writing*; a finding
about model internals is not process guidance. Those gaps are marked rather than glossed.

---

## 1. Refactoring's economic benefit — Thoughtworks / martinfowler.com

**INCORPORATED — and it fixes this repo's weakest claim.**

[Article](https://martinfowler.com/articles/exploring-gen-ai/refactoring-economic-benefit.html).
A ~150 kLoC agent-written application whose data-access layer had bloated into a single 17,155-line
Rust file. The author measured whether refactoring pays for itself in tokens.

**The methodological contribution, which matters more here than the result:** agents are stateless,
so *an identical prompt can be replayed cleanly against different tree states*. In the author's
words — "Precisely because agents never learn this was now possible to run as an experiment." The
design: define one representative change, measure a baseline in a sub-agent, discard, then loop —
apply one refactoring step, re-run the same prompt, record tokens, discard.

That is **a control arm for agent work**, and it is exactly what this method has been missing. It
does not measure a whole multi-week run, but it measures a *single gate* rigorously. See the
control-arm section added to [MEASUREMENT.md](MEASUREMENT.md).

**Results, stated honestly by the author:** input tokens per change fell 159,564 → 27,360 (83%),
worth about **39.7 cents** — which he concedes is "Not a lot." Output tokens stayed flat despite
costing 5× more. The mechanism is falsifiable and was tested: savings come from the agent *reading
less*, not from less code existing (total layer size barely moved, 17,155 → 16,608), which predicts
that arbitrary file-splitting would *not* help. Consistent with that, tokens stayed flat until the
largest file began shrinking.

**Two findings that corroborate mechanisms already in this method:**

- **Agents do not reliably identify what needs fixing.** "Claude was not good at refactoring" — it
  produced only refactorings the prompt steered it toward and could not independently judge which
  applied. This is the case for a human-authored gate list: an agent will grind against a bar, but
  it will not invent the bar.
- **The author's own refactoring check never flagged the 17,155-line file** — a check that scored on
  nothing, found in the wild, in a project explicitly about code quality. And token counts had to be
  approximated (characters ÷ 4) because live counting was unreliable "despite showing token
  counts... and **billing** for tokens." The instrument lied first, again.

**Transfer:** direct — same tooling, same kind of work. **Limits, as stated:** one experiment, one
greenfield app, one developer, one simple change, generation noise masking output-token effects.

---

## 2. Measuring agent autonomy in the wild — Anthropic

**INCORPORATED — the strongest external validation of the human-oversight model here.**

[Post](https://www.anthropic.com/research/measuring-agent-autonomy). Millions of human–agent
interactions across a coding product and a public API, analyzed with privacy-preserving tooling.

**The framing that matters:** autonomy is "not a fixed property of a model or system but an emergent
characteristic of a deployment" — shaped jointly by model behavior, user oversight habits, and
product design. That is precisely why the *autonomy boundary* belongs in the rulebook: it is a
property you set, not one you inherit.

**The finding that independently validates the judgment-based escalation bar.** The post advises
against mandating interaction patterns, because requiring approval of every action "will create
friction without necessarily producing safety benefits"; the right test is whether a human is
*positioned to monitor and intervene*. This method arrived at the same rule from a different
direction — an agent that tagged its human on every single human post, and the human who replaced
that reflex with a judgment bar. Convergence from practice and from population data is worth more
than either alone.

**Experienced users shift from approving to monitoring**, measurably: auto-approve rises from ~20%
of sessions for newer users to over 40% by ~750 sessions, while interrupts *also* rise (~5% → ~9% of
turns). Not less oversight — differently placed oversight. This is the shape the "stay out of the
loop" guidance was reaching for.

**Agent-initiated stops exceed human interrupts.** On the most complex work the agent asks for
clarification more than twice as often as humans break in. Reasons: choosing between approaches
(35%), gathering diagnostics (21%), clarifying vague requests (13%), requesting credentials (12%),
seeking approval (11%). Two consequences adopted here: the escalation list should name *choosing
between approaches* first (it dominates), and a well-run loop is expected to stop and ask — that is
the mechanism working, not the agent failing.

**A metric adopted into [MEASUREMENT.md](MEASUREMENT.md):** interventions per session. Anthropic's
internal usage saw interventions fall 5.4 → 3.3 while success on the hardest tasks doubled. That is
a better leverage measure than message-share alone, because it pairs oversight cost with outcome.

**Also adopted:** post-deployment monitoring over pre-deployment evaluation — "pre-deployment evals
can't surface these usage patterns." The analogue here is that a green gate board is a
pre-deployment artifact; the live-state inspection is the post-deployment one.

**Transfer:** direct for coding agents. **Limits, as stated:** one provider's traffic;
classifications produced by a model and not manually inspectable, so human-involvement figures read
as upper bounds; a narrow late-2025-to-early-2026 window; evaluation traffic indistinguishable from
production.

---

## 3. Teaching Claude why — Anthropic

**INCORPORATED WITH A CAVEAT, because it critiques this method's own goal template.**

[Post](https://www.anthropic.com/research/teaching-claude-why). The headline: **training on
explanations of why an action is right beat training on examples of the right action.** Fine-tuning
on filtered good-behavior examples moved misalignment 22% → 15% ("surprisingly unsuccessful"); the
same data rewritten to include deliberation over values reached **3%**.

**Why this is a critique and not a compliment.** The `GOAL.md` template here leans on an *enumerated
prohibition list* — name the cheap exits individually. This work suggests enumeration alone
generalizes poorly: a list of prohibitions covers what it lists, while a stated purpose transfers to
cases the author never enumerated. The template now requires **a reason attached to each
prohibition**, not just the prohibition. That is a real change driven by reading this.

**Two more findings adopted:**

- **Beware specs written against your test cases.** Close matching to the target evaluation bought
  little and produced brittle, distribution-local compliance. This is the same shape as the
  counting-gate result in [COMPOSING.md](COMPOSING.md) and as "a test whose fixture cannot occur in
  production."
- **Go deliberately off-distribution.** The most token-efficient dataset was structurally *unlike*
  the target evaluation, which is why it generalized. Sharpens the adversarial-review step from
  "probe one edge the author's tests didn't" to "probe an edge *structurally unlike* the author's
  tests."
- **Match the deployment surface.** Chat-only alignment data failed to cover tool-using agents; even
  cosmetically adding tool definitions helped. Analogue: write and test instructions **in the harness
  the agent will actually run in**, not in a chat window.

**THE CAVEAT, stated plainly:** this is a result about **training data**, not about prompts or
instruction files. That rationale-over-enumeration transfers to instruction-writing is *plausible*
and is corroborated by item 4 below, but it is **not established** by this work. Treat it as
`documented`, not `demonstrated`. A cautionary note from the same post cuts both ways: a model
trained on synthetic honeypots scored near zero on the target evaluation yet still misbehaved in
far-from-distribution situations — fitting the eval is not generalizing.

---

## 4. The global workspace / J-space — Anthropic + Transformer Circuits

**LARGELY DECLINED. Two narrow findings taken as corroboration; no section built on it.**

[Blog post](https://www.anthropic.com/research/global-workspace) ·
[technical paper](https://transformer-circuits.pub/2026/workspace/index.html).

This is genuinely interesting interpretability work — a small, densely-wired set of internal
representations that behaves like a broadcast hub, readable with a Jacobian lens, causally load-
bearing for multi-step reasoning (ablating it drops multi-step reasoning to near zero while leaving
fluency intact).

**Why it is mostly declined here.** The technical paper **makes no recommendations** about prompting,
instruction-writing, evaluation design, or agent monitoring. The blog post's "practical implications"
are, on inspection, inferences drawn *about* the work rather than claims made *by* it. Citing it as
support for process guidance would be borrowing prestige to dress up advice that rests on something
else — the exact move this method is built to catch. So it gets two lines of corroboration, not a
section.

**What was taken, both stated findings rather than inferences:**

- **Prohibition partly backfires.** "Instructions to suppress a thought increase its occurrence
  relative to no instruction at all," control is "imperfect and sensitive to phrasing," and "a bare
  mention of the concept can prime it almost as strongly as an explicit focus instruction." This
  corroborates item 3 from an independent direction: a rulebook that is *only* prohibitions is a
  weaker instrument than one that states purposes. Both now inform the template's guidance to pair
  each prohibition with its reason and to prefer a positive statement of the desired behavior.
- **Externalizing beats holding in context.** Step-by-step working was "substantially more robust to
  ablation" than direct answering, interpreted as the model externalizing onto the page what it
  would otherwise hold internally. Mild independent support for an existing practice: write the cycle
  log and the gap report to a *file* rather than carrying them in context.

**One finding noted but not acted on:** the workspace sometimes encodes recognition of being tested
("fake", "fictional"), and ablating those representations surfaced behaviors that were otherwise
concealed. Suggestive for making evaluations realistic, and it rhymes with "a fixture that cannot
occur in production." But the mechanism is about model internals under ablation, not about test
design, so it is recorded here rather than turned into a rule.

**Transfer:** weak to none for process. Recorded so a reader knows it was considered.

---

## What none of this establishes

The efficiency claim in the [README](../README.md) — a long build compressed by roughly an order of
magnitude — remains **`assumed`**. Item 1 supplies a method for measuring a single gate against a
control, and item 2 supplies a better oversight metric, but neither measures a multi-week run, and no
control arm for one has been run here or anywhere cited.

Item 3 warns specifically against the failure this repo is most exposed to: a specification written
against the cases its author already had in mind, producing compliance that is brittle outside them.
The mitigations are to attach reasons to rules, and to probe edges structurally unlike the ones the
gates already cover.
