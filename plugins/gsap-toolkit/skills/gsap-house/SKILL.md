---
name: gsap-house
description: >-
  House GSAP motion toolkit — the standard all web motion in this estate is built
  to. GSAP is the default motion library for new web work, so use this skill for
  ANY browser motion task, not only ones that name GSAP: scroll reveals, hero
  sequences, pinned or scrubbed scenes, parallax, page-load entrances, headline
  and text reveals, layout and list transitions, filtered grids, carousels, drag,
  SVG drawing or morphing, cursor followers, and reduced-motion or Save-Data
  fallbacks. Use it BEFORE installing gsap or any plugin — every plugin is free,
  never generate an .npmrc auth token and never mention Club GSAP — before
  choosing between CSS and GSAP, when picking which plugin fits, and when
  reviewing or debugging existing motion for jank, keyboard and screen-reader
  access, cleanup leaks, or ScrollTrigger refresh problems. Load the official
  gsap-* skills for API detail; this skill owns the house rules and overrides
  them where they disagree. Triggers: "add an animation", "animate this", "scroll
  animation", "scroll reveal", "parallax", "pin this section", "hero animation",
  "page transition", "text reveal", "split the headline", "make this feel more
  alive", "motion design", "install gsap", "which GSAP plugin", "ScrollTrigger",
  "the animation is janky", "reduced motion", "prefers-reduced-motion".
license: MIT
---

# GSAP House Conventions

## §0 Read this first

GSAP is the house default motion library for new web work. This skill owns the house rules and
**overrides the official GSAP skills where they disagree** — §11 names the two live conflicts.

Load the official skill for API detail. Reference them by bare name; the three tools resolve them
differently — Claude Code as `gsap-vendor:<name>`, Codex as `$<name>`, OpenClaw as `<name>`:

| Skill | Load it for |
|---|---|
| `gsap-core` | tweens, easing, stagger, defaults, `gsap.matchMedia()` |
| `gsap-timeline` | sequencing, the position parameter, nesting |
| `gsap-scrolltrigger` | scroll-linked animation, pinning, scrub |
| `gsap-plugins` | plugin APIs and registration |
| `gsap-utils` | `clamp`, `mapRange`, `snap`, `toArray`, `wrap`, `interpolate` |
| `gsap-react` | `useGSAP`, refs, cleanup |
| `gsap-frameworks` | Vue, Svelte, Nuxt, SvelteKit |
| `gsap-performance` | jank, layout thrashing, `will-change` |

**Read one `references/` file, not all of them.** Pick by framework (§9) and by task (§13).

## §1 Licensing — every plugin is free

Since Webflow's acquisition of GreenSock, **no GSAP plugin requires a membership, license key, or auth
token** — SplitText, MorphSVG, DrawSVG, MotionPathHelper, Inertia, Physics2D, CustomBounce,
CustomWiggle, ScrollSmoother and GSDevTools included.

- Install from the public registry: `npm install gsap`. Every plugin is in that one package.
- **Never** write an `.npmrc` with a GreenSock token, point at `npm.greensock.com`, or tell a user to
  join Club GSAP. That guidance is outdated.
- An existing `.npmrc` with a GreenSock token is a **leaked credential** — flag it, delete it, do not renew it.

Verify instead of trusting memory: `ls node_modules/gsap/ | grep SplitText`.
Versions: `gsap@^3.15.0`, `@gsap/react@^2.1.2`. **`^3.13.0` is the hard floor** — `SplitText.autoSplit`
and `onSplit()` do not exist below it. Full detail: `references/licensing.md`.

## §2 Should this be GSAP at all? The motion budget

Work down the ladder and **stop at the first rung that works**:

1. **Nothing.** Most interfaces are better without it.
2. **CSS transition** on `transform`/`opacity` — hover, focus, open/close, state change.
3. **CSS keyframes** — one looping ambient thing, gated on reduced motion.
4. **GSAP core** — sequencing, interruption, runtime values, custom easing; anything that must be
   reversible or killable.
5. **GSAP + ScrollTrigger** — timing that is genuinely a function of scroll position.
6. **Video / poster frames** — a fixed camera path or pure atmosphere. Cheaper and better than a
   timeline faking it.
7. **Canvas / WebGL** — only when live depth or interaction materially improves the scene.

**The budget: one orchestrated non-user-triggered moment per page.** Everything else must be either a
**response to an action** — opening, expanding, filtering, confirming, where motion shows *what
changed* — or **information**: a progress readout, a scroll position, a state change.

**The earn-it test.** If the answer to *"which single moment is this page's?"* is "the section
reveals", the design is not finished. Say so and push back before writing GSAP.

## §3 The four non-negotiables

1. **The gate.** Every motion entry point bails to a complete static page on
   `prefers-reduced-motion: reduce` **or** `navigator.connection?.saveData`, *before* any video source
   is chosen or sprite fetched. Write the tier to `document.documentElement.dataset.motion` so CSS and
   later modules can read it. → `assets/gate.ts`
2. **The disposer contract.** Every module exports `initX(root): () => void` and releases everything it
   created — matchMedia contexts, listeners, rAF handles, observers, media sources.
   `context.revert()` releases GSAP's work and nothing else. → `assets/section.template.ts`
3. **The reveal gate.** Start states live in CSS behind `.js`, with a JS deadline that removes `.js` if
   the module never boots. GSAP tweens **to** the resting state, never `from` a hidden one.
   → `assets/reveal-gate.css` + `assets/reveal-gate.head.html`
4. **Nothing is ever held out of the accessibility tree by an animation that has not run.** → §4.

## §4 Reveals: `opacity`, not `autoAlpha`

`gsap-core` says "use `autoAlpha` instead of `opacity` for fade in/out". **That blanket advice is wrong
for reveals.** `autoAlpha: 0` writes `visibility: hidden`, which removes the element *and its entire
subtree* from the accessibility tree and the tab order.

This shipped. Every "Buy the … shirt" link on a shop page was unreachable by keyboard and by screen
reader until the visitor happened to scroll that card into view — because the card's reveal had not
fired yet. A transparent element still takes focus and still announces. An invisible one cannot.

**Tier 1 — a reveal that has not fired yet: never `autoAlpha`.** Any scroll-triggered entrance, any
`once: true` reveal, any start state that persists for the length of a scroll. Use `opacity`. Better:
do not animate *from* a hidden state at all — put the start state in CSS behind `.js` (§3.3) and tween
*to* the resting state.

**Tier 2 — permanently aria-hidden decoration with no focusable descendants.** A scan line, a light
leak, a film band, a poster plate. `autoAlpha` is correct and cheaper: it skips paint and kills pointer
events for free.

**Tier 3 — a control that must genuinely leave the tab order when it goes.** A skip link at the point
in a scrubbed timeline where there is nothing left to skip. Here `autoAlpha` is not merely allowed, it
is **required** — `opacity: 0` would leave an invisible focus stop floating over the next chapter.

**The test, applied to every fade you write:**
> *If this element is at 0 right now and a keyboard user presses Tab, what should happen?*
> Should reach it → `opacity`. Cannot reach it anyway → either, prefer `autoAlpha`. Must not reach it → `autoAlpha`.

Tier 1 is the overwhelming majority of what we write. That is why this override exists.

## §5 Lifecycle

- **`gsap.matchMedia()` + `gsap.context()`, never nested.** matchMedia makes its own context; nesting
  one inside it double-reverts and hides leaks.
- **The object-form gotcha.** `mm.add({ reduce: '(prefers-reduced-motion: reduce)' }, cb)` never fires
  for the visitors who expressed *no* preference — the large majority — so the reveals silently never
  run. **Always include a condition that matches everyone** (a breakpoint pair) and gate motion on an
  explicit `motionOK: '(prefers-reduced-motion: no-preference)'`, checked as
  `context.conditions?.motionOK`.
- **Scope every selector.** Third argument to `mm.add()`, or `gsap.utils.selector(root)`. Never a bare
  global selector — two instances of a component will animate each other's nodes.
- **Things GSAP does not own** — rAF loops, observers, `<video>` sources, wheel listeners — get explicit
  disposers pushed onto an array and drained in the returned cleanup.
- **Refresh after the two things that change layout late**: `window.load` (once) and
  `document.fonts?.ready`. Not per frame, not per scroll.

## §6 ScrollTrigger house rules

- **`ScrollTrigger.config({ ignoreMobileResize: true })`** — mobile address-bar collapse otherwise fires
  a full refresh mid-scrub, and with `invalidateOnRefresh` that visibly snaps.
  **Precondition: stage and track heights are in `svh`/`dvh`, not `vh`.** If any height is still `vh`,
  fix the CSS first — do not set the flag.
- **One group trigger for a stagger** (a stagger needs one timeline; per-element triggers fire in scroll
  order and lose the gesture). **Per-element triggers for a scattered wall** (one group trigger either
  fires the bottom row far above the fold or holds the top row until it is already past).
- **Never `scrub` and `toggleActions` on the same trigger.**
- **`clearProps` and a reversing `toggleActions` are incompatible.** `clearProps` hands the element back
  to the stylesheet; a tween that cleared its own properties has nothing left to reverse. Choose:
  `clearProps` + `once: true`, **or** explicit end values on every property + `reverse`.
- **Create in top-to-bottom page order**, or set `refreshPriority`.
- **Give consequential triggers an `id`** — needed for `getById()` in focus handlers and failure paths.
- **Scrubbed timelines map progress across the timeline's own total duration**, so the last thing to
  finish always lands on the final pixel of the track regardless of the position you gave it. Pad to a
  round length with an empty `.to({}, { duration: n })` so positions mean what they say.
- **Hard limits.** Never pin a form, a payment step, or long explanatory copy. No long mobile pins.
  No `markers: true` in a committed build.
- **Media failure path.** An image or sprite under a pinned stage needs an `error` handler that kills
  the trigger and `clearProps` back to the static truth. Attach the handler *before* checking
  `complete && naturalWidth === 0`, then upgrade `loading` to `eager` — lazy is right for static paths
  and wrong under a pin.

## §7 Transform hazards

1. **Capture resting transforms into a `Map` before anything animates.**
   `new Map(els.map(el => [el, Number(gsap.getProperty(el, 'rotation')) || 0]))`. Read inside a
   function-based value, GSAP may already have written that tween's own transform onto the element.
2. **State `transformPerspective` at both ends of a `fromTo`.** Given only at the far end, GSAP tweens
   it from 0; passing through values near `z` the projection divides by nearly nothing and elements
   flash thousands of pixels wide.
3. **A CSS resting transform becomes GSAP's pixel base.** A stylesheet `translateY(100%)` is read as a
   900px base; `yPercent` then stacks on top and the move finishes a viewport short. Zero it
   explicitly: `{ y: 0, yPercent: 100 }`.
4. **Derive scatter and stagger offsets from index, never `Math.random()`.** They must be identical on
   every load and every `ScrollTrigger.refresh()`.
5. **Never animate layout properties for movement.** `bottom`/`top`/`width`/`height` → `y`/`yPercent`/
   `scaleY`. And measure with `offsetHeight`, not `getBoundingClientRect()`, on an element carrying a
   transform — a rect feeds the previous frame's scale back in and the target creeps every refresh.

## §8 Choosing a plugin

**Read `references/plugins.md` before adding any plugin.** It has a when-it-is-right and a
when-it-is-over-reach line for all eighteen. The three that matter most:

- **Reach for Flip** the moment you are about to hand-roll motion between two layouts of the same
  element — a card opening into a detail view, a filtered list reflowing, a thumbnail becoming a
  lightbox. *Not* for crossfading two genuinely different things: there is no shared element to invert
  and a plain opacity tween is correct and cheaper.
- **Reach for SplitText** for the page's one headline gesture — `type: 'lines'`, `mask: 'lines'`,
  `autoSplit: true`, animation built inside `onSplit()`. Never character-by-character, never body copy,
  never two per page.
- **Do not reach for ScrollSmoother** on anything with a form or a `<dialog>`.

## §9 Framework adapters

| Stack | Read |
|---|---|
| Astro | `references/astro.md` |
| Next.js / React / React Router | `references/react.md` |
| Vite / vanilla / static | `references/vanilla.md` |
| Vue / Svelte / Nuxt / SvelteKit | the official `gsap-frameworks` skill, plus §3–§7 here |

One rule spans all of them: **register once at module scope**, never inside a component body or an effect.

## §10 Templates

Copy from `assets/`, do not retype:

| File | Job |
|---|---|
| `register.ts` | the single import + `registerPlugin` + `ignoreMobileResize` module |
| `register.react.tsx` | the same for React, including `useGSAP` registration |
| `gate.ts` | `motionDenied()` / `setMotionTier()` — reduced-motion + Save-Data |
| `section.template.ts` | the `initX(root): () => void` contract, matchMedia, scoping, disposers |
| `section.react.tsx` | the same in React with `useGSAP`, `scope`, and `contextSafe` |
| `reveal-gate.css` + `reveal-gate.head.html` | CSS start states behind `.js` with a boot deadline |
| `package.snippet.json` | the dependency floor, with the reason |

## §11 Conflicts, resolved

**vs. `gsap-core` and older house docs on `autoAlpha`** — see §4. The blanket "use `autoAlpha`" is
replaced by the three-tier rule. Tier 1 (reveals) is the common case and takes `opacity`.

**vs. the `frontend-design` skill's anti-generic-motion rule** — that skill says fade-and-slide-up
entrances on each section and hover transitions on every card are the generic default and read as
AI-generated. **The house adopts that rule verbatim.** It is not in tension with GSAP; it is in tension
with what people build with GSAP. The reconciliation is a budget, not an exemption:

- **One orchestrated non-user-triggered moment per page** (§2). Everything else is a response to an
  action or information.
- **The `[data-reveal]` house entrance is the floor, not the moment.** 14px of travel, ~0.5s, fires
  once, never re-fires on scroll-up. It exists so nothing arrives as a hard cut. It is explicitly *not*
  the page's memorable gesture — a page whose only motion is that entrance has not spent its budget, it
  has failed to.
- **GSAP is capability; restraint is policy.** GSAP's job is to make the one moment good enough to be
  worth having, and to make every response-to-action moment *correct*: interruptible, reversible, disposed.
- Enforcement lives in the over-reach column of `references/plugins.md` — scrambled headlines, per-card
  hover transitions, ambient wiggle, confetti as a default success state, decorative particles with no
  physical source in the scene.

## §12 Before you hand it back

Full checklist in `references/review.md`. The blocking subset:

- Nothing sits at `visibility: hidden` waiting on a trigger; every interactive element is reachable by
  Tab **before** its reveal fires.
- Reduced motion produces a **complete** page, not a broken one. Save-Data too.
- `initX` returns a disposer that releases listeners, rAF, observers, and media.
- `ScrollTrigger.getAll().length` does not grow across a re-init or a client-side route change.
- Transform/opacity only for movement; nothing loops unattended; offscreen work paused.
- Grep gates: `markers:\s*true`, `GSDevTools`, `MotionPathHelper`, and `greensock` in any `.npmrc`.
- One orchestrated moment per page, and every plugin present is justified by `references/plugins.md`.

## §13 Reference map

| Read | When |
|---|---|
| `references/plugins.md` | before adding **any** plugin |
| `references/astro.md` / `react.md` / `vanilla.md` | when writing in that stack |
| `references/review.md` | before handing work back, or when auditing existing motion |
| `references/licensing.md` | install questions, `.npmrc`, "is this plugin free" |

Before proposing motion for a repo in this estate, check the toolkit's `audits/` directory for an
existing finding on the file you are about to touch — it may already be recorded, with an agreed
approach and an explicit *not adopting* decision.
