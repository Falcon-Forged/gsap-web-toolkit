# Motion preflight

Run this before handing motion work back. It is also the finding taxonomy the `gsap-audit` skill uses,
so the severities here and the severities in an audit report mean the same thing.

Order is deliberate: A11Y blocks, CORRECTNESS blocks, everything below is negotiable.

## A11Y — blocking

- [ ] **Nothing sits at `visibility: hidden` waiting on a trigger.** No `autoAlpha: 0` (and no
      `.from({ autoAlpha: 0 })`, which sets it immediately) on anything containing text or a control.
      See `SKILL.md` §4 for the three tiers and the Tab test.
- [ ] **Every interactive element is reachable by Tab before its reveal fires.** Test by tabbing
      through the page from the top without scrolling.
- [ ] **Reduced motion produces a complete page**, not a broken one — every element a timeline would
      have revealed is present, legible, and reachable from first paint. Implemented via
      `gsap.matchMedia()` / the gate, not a blanket `animation: none`.
- [ ] **Save-Data produces the same static page**, and never fetches the motion bundle or its media.
- [ ] **SplitText output is announced correctly** — `aria: 'auto'` (the default) preserved, or a
      screen-reader duplicate present.
- [ ] **Every Draggable has a keyboard path** — a focusable target and arrow-key handling.
- [ ] **Focus never lands on an element the scrub has faded out.** If a control genuinely leaves the
      page, it must leave the tab order too (Tier 3 `autoAlpha`).
- [ ] **No scroll trap.** Keyboard scrolling, in-page anchors, browser find-in-page, and deep links
      reach every section. Pinned scenes are escapable.

## CORRECTNESS — blocking

- [ ] **`initX` returns a disposer** that releases listeners, rAF handles, observers, and media
      sources — not just GSAP's own work.
- [ ] **`ScrollTrigger.getAll().length` does not grow** across a re-init or a client-side route change.
      Measure it; do not eyeball it.
- [ ] **No `scrub` and `toggleActions` on the same trigger.**
- [ ] **No `clearProps` under a reversing `toggleActions`.**
- [ ] **No `gsap.context()` nested inside `matchMedia()`.**
- [ ] **matchMedia object form includes an always-matching condition** (a breakpoint pair) alongside
      `motionOK`. Without it the handler never fires for visitors with no stated preference.
- [ ] **Selectors are scoped** — `mm.add(…, root)` or `gsap.utils.selector(root)`, never bare globals.
- [ ] **`refresh()` is called after `window.load` and `document.fonts.ready`**, and not per frame.

## PERF

- [ ] **Transform and opacity only for movement.** No animated `top`/`left`/`bottom`/`width`/`height`/
      `margin`/`box-shadow` on a scrubbed or per-frame path.
- [ ] **`quickTo`/`quickSetter` for pointer-rate updates**, not a fresh tween per event.
- [ ] **Nothing loops unattended.** Offscreen work is paused; an ambient loop keeps a phone's GPU warm
      for the whole session.
- [ ] **`will-change` is bounded** — applied near the animation, removed after, never blanket-applied
      to a list or container.
- [ ] **Measurement uses `offsetHeight`, not `getBoundingClientRect()`,** on transformed elements.
- [ ] **Pinned sections reserve their own space** — `ScrollTrigger.refresh()` (which fires on resize
      and on late image/font load) does not shift surrounding content. Pin-induced shift counts against
      the CLS budget even when a cold-load Lighthouse run does not observe it.

## HYGIENE — grep gates

```bash
grep -rn "markers:\s*true" src/          # ScrollTrigger debug markers
grep -rn "GSDevTools\|MotionPathHelper" src/
grep -rn "greensock" .npmrc* 2>/dev/null # a leaked auth token, not a config
```

- [ ] All four come back empty.
- [ ] `gsap` is `^3.15.0` (floor `^3.13.0`); React projects also declare `@gsap/react@^2.1.2`.
- [ ] Every registered plugin is actually used — each one is bundle weight on every page.
- [ ] Plugins are registered, so a bundler cannot tree-shake them out of a production build.

## CRAFT

- [ ] **One orchestrated non-user-triggered moment per page.** The `[data-reveal]` entrance is the
      floor, not the moment.
- [ ] **Every plugin present is justified** by `references/plugins.md` — check it against that
      plugin's over-reach line, not just its right-tool line.
- [ ] **Eases match the house set** — `power3.out` entrances, `power2.in` exits, `none` for scrubbed.
- [ ] **A simplified or static mobile variant exists.** Long-scrub pinned sequences are not shipped
      unchanged to touch.

## Report what you could not check

If you could not run the browser, say so and name what is unverified — the trigger count, the tab
order, the reduced-motion state. An unstated gap reads as a passed check.
