# Motion adoption audit — 2026-09

First estate-wide audit against the house GSAP rules. Read-only: no site code was changed.

## How to read this

Finding IDs (`SC-nn`, `HP-nn`, `LUJ-nn`, `X-nn`) are **stable across re-audits**. A fixed finding keeps
its number and gets marked resolved; numbers are never recycled.

Severity ladder and criteria come from `gsap-house/references/review.md` — the same checklist that
gates a hand-off, so "passes preflight" and "passes audit" mean the same thing.

`A11Y > CORRECTNESS > PERF > HYGIENE > CRAFT > OPPORTUNITY` · effort `S <1h · M 1–4h · L 1–2d · XL >2d`

Every site section ends with **Explicitly not adopting**. That list is the point: it is the record of
what was considered and rejected, and it is what stops the next agent adding a plugin for symmetry.

## Estate summary

| Site | Stack | gsap | Motion surface | Verdict | Open |
|---|---|---|---|---|---|
| stranger-court-website | Astro 7 | `^3.12.0` → 3.15.0 | Large — cinematic v2 homepage, scrubbed drone sequence, 6-file proposal deck | **Adopt with corrections.** Most house rules were mined from here. | 9 |
| hickman-portfolio-website | Vite + vanilla TS; React 19 prototype | `^3.13.0` | Medium — the best-written motion in the estate, on an unmerged branch | **Merge first, then align.** | 6 |
| leveled-up-jobs | Next 16, React 19, Tailwind 4 | none | Minimal — 3 CSS keyframes | **Two adoptions, keep the CSS.** | 2 |

---

## stranger-court-website

Astro 7. `gsap@^3.12.0` (resolves 3.15.0), ScrollTrigger only. This repo is the estate's reference
implementation *and* the source of most house rules — `src/scripts/gsap/v2-home.ts` documents, in
comments, the bugs that became §4, §6, and §7 of the house skill. The findings below are almost all in
code written *before* those lessons, not in the code that taught them.

### Findings

##### SC-03 — Proposal reveals hold headings and body copy out of the accessibility tree [A11Y] [M]
- **File** `src/scripts/proposal/{sections,court-plan,attractions,timeline,fundraising}.ts` — 24 sites.
  Representative: `sections.ts:44,50,56,61`, `court-plan.ts:43,49,54,59`, `timeline.ts:47-86`.
- **Today** Each file builds a `gsap.timeline({ scrollTrigger: { trigger: root, start: 'top 74%',
  once: true } })` and populates it with `.from(el, { autoAlpha: 0, … })`. `.from()` renders its start
  state immediately, so `visibility: hidden` is written at init and persists until the visitor scrolls
  that section to 74% of the viewport.
- **Wrong because** every `h2`, section intro, and body block in the proposal deck is absent from the
  accessibility tree and the tab order until it is scrolled into view. A screen-reader user
  navigating by heading finds nothing below the fold. Any link inside those blocks is unreachable by
  Tab. `visibility: hidden` propagates to the whole subtree, so this is not one element per call — it
  is everything inside `[data-proposal-section-body]`.
- **Proposed** House §4 Tier 1: `opacity` instead of `autoAlpha`, or better, the reveal gate — CSS
  start state behind `.js`, tween *to* the resting state. Mechanical across the five files.
- **Blast radius** `.from` → `.fromTo` or a `.to` against a CSS start state changes nothing visually.
  Watch for the `once: true` + `clearProps` interaction (§6) if `clearProps` is added.
- **Verify** Load a proposal page, do not scroll, Tab from the top — every link below the fold must be
  reachable. Then a screen-reader heading list.
- **Effort** M (~3h; repetitive, low risk)

##### SC-01 — Shop filter reflows as a hard cut [CRAFT] [M]
- **File** `src/scripts/shop-grid.ts:213-228`
- **Today** `apply()` sets `item.hidden = !on` per item and `chapter.hidden` per chapter; the grid
  snaps to its new layout.
- **Wrong because** the reader loses track of which items stayed. This is the textbook Flip case —
  the same elements in two layouts.
- **Proposed** `Flip.getState(items)` before the mutation, `Flip.from(state, { absolute: true,
  onEnter, onLeave })` after. Keep `hidden` for accessibility; skip the animation entirely when
  `motionDenied()`; the `[data-shop-filter-status]` count stays the authoritative announcement.
- **Blast radius** Adds Flip to `register.ts` (bundle weight on every page that loads motion).
- **Verify** Filter with reduced motion on — must be an instant swap, and the status text must still
  announce.
- **Effort** M (~2h)

##### SC-02 — Lightbox opens with no transition [CRAFT] [M]
- **File** `src/scripts/shop-lightbox.ts` (146 lines, currently zero GSAP)
- **Today** A native `<dialog>` over a CSS-only radio-switcher gallery. Clicking a frame calls
  `showModal()` and swaps `image.src`. No transition.
- **Wrong because** the connection between the thumbnail clicked and the image shown is asserted
  rather than demonstrated. Flip is exactly the tool.
- **Proposed** `Flip.fit` / `Flip.from` from the clicked `[data-shop-gallery-frame] img` into
  `[data-shop-lightbox-image]`, after `showModal()`.
- **Blast radius** **This file is deliberate progressive enhancement** — the gallery works with no JS
  at all, and the zoom control ships `hidden` until `<dialog>` is known good. Any Flip layer must be
  strictly additive and must not delay the focus trap or the close-focus-restore.
- **Verify** Open and close with the keyboard; confirm focus lands correctly and is not delayed.
  Confirm the gallery still works with JS disabled.
- **Effort** M–L (~4h, mostly on not breaking the existing contract)

##### SC-04 — Fund tracker animates a layout property [PERF] [S]
- **File** `src/scripts/support-tracker.ts:107-112`
- **Today** `fillTween.to(surface, { bottom: surfaceBottom, opacity: … })` — `bottom` is inside the
  tween, so it is interpolated per frame.
- **Wrong because** every frame triggers layout. The sibling tween on the same timeline already does
  the right thing (`scaleY` with `transformOrigin: 'center bottom'`).
- **Proposed** `y`/`yPercent` against the liquid's scaled height. (`:97` and `:206` are `gsap.set` —
  one-shot writes, not a per-frame path. Leave them.)
- **Verify** Performance panel during a fill; no layout in the frame breakdown.
- **Effort** S (~30m)

##### SC-05 — Declared gsap range under-states the floor [HYGIENE] [S]
- **File** `package.json` — `"gsap": "^3.12.0"`, resolving 3.15.0
- **Wrong because** `SplitText.autoSplit` and `onSplit()` do not exist below 3.13.0. The range
  documents a version the house SplitText pattern does not work at; a clean install could resolve lower.
- **Proposed** `^3.15.0`.
- **Effort** S

##### SC-06 — No headline gesture [OPPORTUNITY] [M]
- **File** v2 chapter headings; proposal `h2`s
- **Today** Plain reveals everywhere. The site has no single memorable typographic moment.
- **Proposed** SplitText on **one** heading — lines, `mask: 'lines'`, `autoSplit: true`, animation
  inside `onSplit()`. Blocked on SC-05.
- **Blast radius** House budget: one orchestrated moment per page. Adding this to every heading is the
  failure mode, not the goal.
- **Effort** M (~2h)

##### SC-08 — Vendored skills drift and double-load [CORRECTNESS] [M]
- **File** `.agents/skills/gsap-*` (8 dirs) + `skills-lock.json` + `CLAUDE.md:21`
- **Today** Eight unpinned copies of the GreenSock skills, discovered automatically by no tool,
  reachable only because `CLAUDE.md` names the path in prose. `AGENTS.md` never mentions them, so
  Codex — an authorized implementation agent in this repo — has no route to them at all.
- **Wrong because** the install is recorded as complete in `docs/implementation/02-gsap-ai-enablement.md`
  while half the agents cannot reach it. Once the toolkit is installed, leaving these in place makes
  Claude see `gsap-core` twice.
- **Proposed** Delete `.agents/skills/gsap-*` and `skills-lock.json`; keep `stranger-court-gsap` as the
  thin project layer; add the house `AGENTS.md` motion block.
- **Effort** M

##### SC-09 — Project skill contradicts the shipped code [A11Y] [S]
- **File** `.agents/skills/stranger-court-gsap/references/astro-gsap-patterns.md:103`
- **Today** "Use `autoAlpha` for hidden/revealed elements."
- **Wrong because** that is the advice that produced SC-03, and `src/scripts/gsap/v2-home.ts:41-45` in
  the same repo documents why it is wrong. A project doc contradicting the project's own production
  code is worse than no doc.
- **Proposed** Replace with the house three-tier rule and cite `v2-home.ts:41-45`. Ship with SC-08.
- **Effort** S

##### SC-10 — `AGENTS.md` asserts a dependency that does not exist [HYGIENE] [S]
- **File** `AGENTS.md:63`
- **Today** "GSAP/ScrollTrigger and Lenis power the cinematic homepage."
- **Wrong because** `lenis` appears in neither `package.json` nor `src/`. The project skill is
  *correct* on this ("treat Lenis as an optional later enhancement"); only the file agents treat as
  authoritative is wrong. An agent that finds one stated fact false discounts the rest of the file.
- **Proposed** State that scrolling is native.
- **Effort** S

### Explicitly not adopting — stranger-court-website

- **ScrollToPlugin.** Six form files use `scrollIntoView({ block: 'center', behavior: 'auto' })` to
  reach the first invalid field. Native is correct there — instant, accessible, no library.
  `proposal/index.ts:48` is the only arguable case (anchor nav, sticky-header offset) and is not worth
  a plugin.
- **ScrollSmoother.** The site has forms, a `<dialog>`, and a bespoke scroll governor in
  `v2-drone-sequence.ts` already tuned against the film.
- **Observer.** The drone sequence's wheel governor is narrower than Observer and already correct.
- **ScrambleText, Physics2D, CustomWiggle.** No diegetic readout, no physical particle source, no
  motivated shake anywhere in the design.

---

## hickman-portfolio-website

Two codebases. `construction/` is what deploys (Vite + three.js, **no GSAP**). `site/` — Vite +
vanilla TS, `gsap@^3.13.0`, ScrollTrigger + SplitText — is the best motion code in the estate and
exists only on a branch. `prototype/` is React 19 + vinext.

### Findings

##### HP-01 — The good site is not on main [CORRECTNESS] [L]
- **File** branch `claude/hickman-contact-form-setup-c38e18`, worktree `.claude/worktrees/…/site/`
- **Today** `main` has no `site/` directory. The SplitText work, the reveal gate, and the contact form
  live only on that branch.
- **Wrong because** the estate's best motion implementation is not deployed and not discoverable, and
  it blocks every other hickman item.
- **Blast radius** The branch entangles form and security work; this is a merge, not a cherry-pick.
- **Effort** L

##### HP-02 — React motion bypasses the React adapter [CORRECTNESS] [M]
- **File** `prototype/app/motion.tsx:13-33`
- **Today** `gsap.registerPlugin(ScrollTrigger)` **inside** `useEffect`, re-running on every `enabled`
  toggle; `gsap.context()` with no scope; global selectors `.hero-copy`, `.layer-top`,
  `.architecture-panel`; `mm` created outside the context.
- **Wrong because** unscoped global selectors mean two instances animate each other's nodes, and
  hand-rolled context handling gets StrictMode's double-invoke wrong. `@gsap/react` is not installed.
- **Proposed** `useGSAP` with `scope: rootRef`; register at module scope per `assets/register.react.tsx`.
- **Verify** `ScrollTrigger.getAll().length` stable across a toggle and a route change.
- **Effort** M (~2h)

##### HP-03 — Missing `@gsap/react` [HYGIENE] [S]
- **File** `prototype/package.json` — `gsap@^3.13.0`, no `@gsap/react`
- **Proposed** Add `@gsap/react@^2.1.2`; bump gsap to `^3.15.0`. Blocks HP-02.
- **Effort** S

##### HP-04 — The SplitText implementation should be promoted [OPPORTUNITY] [S]
- **File** `site/src/scripts/main.ts:88-118`
- **Today** Exemplary: `SplitText.create` + `onSplit` + `autoSplit`, a `played` WeakSet guard against
  re-split replays, and an immediate-play path for headings already on screen at split time.
- **Proposed** Promote verbatim into the toolkit as `assets/split-lines.ts` and cite from
  `references/plugins.md`. This is a finding *in our favour* — the estate already solved it.
- **Effort** S

##### HP-05 — Two near-identical hand-rolled crossfades [CRAFT] [S]
- **File** `site/src/scripts/main.ts:190-268` and `:275-324`
- **Today** Duplicated opacity crossfade + auto-advance + on-screen containment.
- **Proposed** One shared `crossfade()` helper. **Explicitly not Flip** — two different images, no
  shared element to invert; a plain opacity tween is correct and cheaper. Recorded here as the estate's
  canonical Flip over-reach example.
- **Effort** S–M (~1h)

##### HP-06 — Pointer follower is correct as written [—] [none]
- **File** `site/src/scripts/main.ts:363-391`
- **Today** `quickSetter` + manual rAF coalescing + rect cached on `pointerenter`.
- **Recorded as a non-finding** so a later pass does not "fix" it. `quickTo` would be a preference,
  not an improvement.

##### HP-07 — No `AGENTS.md`, no `CLAUDE.md` [CORRECTNESS] [S]
- **Today** The repo root has neither. Claude and Codex both get zero project instruction.
- **Proposed** Create both, from `product-AGENTS.md` plus the house motion block.
- **Effort** S

### Explicitly not adopting — hickman-portfolio-website

- **ScrollSmoother.** `site/src/scripts/main.ts:20-25` states the site's motion contract as "no lerp,
  no smooth-scroll library, no pin, no scroll-jacking." The house layer defers to it.
- **Flip** for HP-05 — see above.
- **A second SplitText gesture.** The masked line reveal is the page's one moment and it is already
  spent well.

---

## leveled-up-jobs

Next 16, React 19, Tailwind 4, Radix. **No GSAP, and that is mostly correct.** An authenticated job-
tracking workspace is outside the scope of the house motion default. This section is the audit's proof
that the standard is a standard.

### Findings

##### LUJ-01 — Filtered opportunity list snaps [CRAFT] [M]
- **File** `src/components/opportunities.tsx:41` (the `shown` filter), rendered at `:44`
- **Today** Search + visibility + status filters recompute a client-side list; cards appear and
  disappear with a hard reflow.
- **Wrong because** with three filters interacting, the reader cannot tell whether a card left because
  of the search or the status filter. Motion here is *information*, not decoration — it shows what
  changed, which is exactly the category the house budget allows.
- **Proposed** Flip. Gate on `prefers-reduced-motion`; do not animate on first paint; the `role="status"`
  count stays authoritative.
- **Blast radius** Adds `gsap` to a project that has none. Justified by this finding alone — if it does
  not earn its keep, remove the dependency.
- **Effort** M (~3h including setup)

##### LUJ-05 — Record the scope boundary [—] [none]
- The house default — GSAP for new web work — covers **marketing, portfolio, and narrative** surfaces.
  It does **not** mean adding a motion library to an authenticated product workspace. LUJ gets GSAP for
  LUJ-01 and nothing else. Recorded so the boundary is citable.

### Corrected during this audit

**LUJ-02 (withdrawn).** An earlier draft flagged `.page-enter` in `src/app/globals.css:192` as lacking a
`prefers-reduced-motion` guard. **That is wrong.** `globals.css:226-229` carries a global block —
`html { scroll-behavior: auto }` plus a universal
`*, *::before, *::after { animation-duration: .01ms !important; … }` reset — which covers `.page-enter`
and every other animation in the app. The `.profile-spin` guard in `intake.css:122` is belt-and-braces
on top of it. **No finding.** Recorded rather than deleted because "we checked and it was fine" is
worth as much to the next auditor as a defect.

### Explicitly not adopting — leveled-up-jobs

- **ScrollTrigger** — nothing on any page is timed to scroll position.
- **ScrollSmoother** — forms and dialogs everywhere.
- **SplitText** — no display headline is doing that work.
- **Draggable, Observer, any hero sequence** — no surface calls for them.
- **Porting the CSS keyframes to GSAP** — the spinner and page-enter are correct as CSS.
  `playbook-workspace.tsx:544` already does reduced-motion-aware smooth scroll correctly in plain JS.

---

## Cross-cutting

##### X-01 — Three gsap ranges across four `package.json` files [HYGIENE] [S each]
`^3.12.0` (stranger-court), `^3.13.0` (hickman site and prototype), none (leveledupjobs). Standardize
on `^3.15.0`; `^3.13.0` is the documented floor.

##### X-02 — No repo has a motion preflight grep [HYGIENE] [S each]
No repo greps for `markers: true`, `GSDevTools`, `MotionPathHelper`, or `greensock` in an `.npmrc`.
One line in each repo's existing verify script.

##### X-03 — The reduced-motion gate exists in three shapes [CORRECTNESS] [M]
`v2-home.ts:8-14` (matchMedia + Save-Data — the house pattern), hickman `main.ts:71` (matchMedia
string form, no Save-Data), `motion.tsx:9` (React state toggle, no Save-Data). Converge on
`assets/gate.ts`. **Note:** the prototype's user-facing Motion switch is a genuine improvement over all
three and should be promoted as an optional layer *over* the gate, not replaced by it.

##### X-04 — `beyond-earth-v2` ships two motion libraries [HYGIENE] [M]
`gsap@^3.15.0` **and** `motion@^12.40.0` in one bundle. Out of scope for this audit's three sites, but
flagged: it is a house-convention violation and pure duplicated weight. `beyond-earth` (v1) is on
`gsap@^3.15.0` + `@gsap/react@^2.1.2` and is a candidate reference implementation.

---

## Sequencing

1. **SC-09 + SC-08** — stop the drift before anything else consumes it.
2. **SC-03** — the only A11Y finding in the estate.
3. **HP-01** — the merge that unblocks all of hickman.
4. **SC-05 → SC-06**, **HP-03 → HP-02**, **HP-07** — cheap, unblocking.
5. **SC-01, SC-02, LUJ-01** — the Flip adoptions, once the rules are in place to judge them.
6. **SC-04, X-01, X-02, X-03** — hygiene sweep.
