# Plugin adoption matrix

Every GSAP plugin, with the case for reaching for it and the case that means you are over-reaching.
Read this **before adding any plugin**. All of them are free and ship in the public `gsap` package
(`references/licensing.md`).

Two things to hold while reading:

- The **over-reach** column is not decoration. It is where the house restraint rule is enforced —
  each entry names the version of that plugin that reads as machine-generated.
- A plugin you register is bundle weight on every page that loads the register module. Add them as
  sections need them, not speculatively.

---

## Scroll

### ScrollTrigger
- **Right tool when** timing is genuinely a function of scroll position — reveals, scrubs, pins — or
  you need to gate non-animation work on visibility: lazy-mount a third-party widget, pause a video
  off-screen, tint UI per section.
- **Over-reach when** it is a 40 kB dependency doing one `once: true` reveal that `IntersectionObserver`
  would do; or it is pinning a form, a payment step, or long copy; or it is a long pin on mobile.
  `ScrollTrigger.batch()` is usually better than N triggers for a long uniform list.

### ScrollTo
- **Right tool when** a scripted scroll must be interruptible or tweened alongside other properties —
  `scrollTo: { y: el, autoKill: true }` so the user's wheel cancels the trip.
- **Over-reach when** it replaces `el.scrollIntoView({ behavior: 'smooth' })` or CSS `scroll-behavior`
  for ordinary anchors. **House rule:** native for hops under about three viewports; an *instant* jump
  beyond that — a smooth 20,000px trip replays every chapter backwards on the way past.

### ScrollSmoother
- **Right tool when** a desktop editorial page has scrub-driven film or parallax that chatters against
  raw wheel deltas — and only after native scroll, anchors, keyboard scrolling, and mobile already work.
- **Over-reach when** the page has a form, an authenticated workspace, or a `<dialog>`. Also when
  `scrub: 0.7`, or a narrow scroll governor over the one offending section, would have done it. Always
  disabled for reduced motion and touch.

## Text

### SplitText
- **Right tool when** it is the page's **one** headline gesture: `type: 'lines'`, `mask: 'lines'`,
  `autoSplit: true`, animation built inside `onSplit()` and returned from it.
- **Over-reach when** it is character-by-character anything; more than one heading per page; body copy;
  or splitting before fonts resolve without `autoSplit` — measured against fallback metrics that
  produced a ten-line, one-word-per-line heading in this estate.

### ScrambleText
- **Right tool when** a diegetic readout is *supposed* to resolve — a status line, a counter, a
  terminal, a code being decoded — where the scramble is the content's own behaviour.
- **Over-reach when** it scrambles a headline or a nav label for texture. It defeats copy-paste, reads
  as generated, and needs a static duplicate or `aria-live` to stay readable.

### Text
- **Right tool when** swapping a short string with a typewriter or replace effect inside an element
  that is already announced as a live region.
- **Over-reach when** the string is content rather than state — it is unselectable mid-animation and
  invisible to a crawler at the moment it matters.

## SVG

### DrawSVG
- **Right tool when** a line that *means something* is being drawn: a route, a boundary, a chart series,
  a signature, an underline tracing a heading.
- **Over-reach when** it is a decorative squiggle; when the stroke has no hidden resting state; or when
  the destination is something the reader cannot anticipate, so the draw reads as loading rather than drawing.

### MorphSVG
- **Right tool when** two shapes are the same object in two states — play↔pause, icon↔check, logo↔mark.
- **Over-reach when** morphing unrelated illustrations: the in-betweens are noise. Also when shipping
  whatever `shapeIndex` GSAP guessed after `MorphSVGPlugin.convertToPath()` without a visual check.

### MotionPath
- **Right tool when** something travels a path *with orientation* — `autoRotate: true` is the tell. A
  vehicle, a marker along a route, a particle on a curve.
- **Over-reach when** the move is straight or near-straight (that is `x`/`y`), or the arc is one a
  `power` ease on two axes already gives you.

### MotionPathHelper
- **Right tool when** authoring a path in the browser instead of guessing `d` attributes. **Dev only.**
- **Over-reach when** it reaches a commit. Treat it exactly like `markers: true` — the preflight grep
  fails the build on it.

## UI

### Flip
- **Right tool when** one element exists in two layouts: a card opening into a detail view, a thumbnail
  becoming a lightbox image, a filtered or sorted list reflowing, an item moving between columns, a
  shared element across a route change. **If you are about to hand-roll motion between two states of
  the same thing, stop and use Flip.**
- **Over-reach when** crossfading two genuinely *different* things — two carousel slides, two
  screenshots in a switcher. There is no shared element for Flip to invert; a plain opacity tween is
  correct and cheaper. Also over-reach when the reflow is one item moving 8px.

### Draggable
- **Right tool when** the user physically manipulates a control: a before/after slider, a knob, a
  throwable card, a reorderable list, a map pan.
- **Over-reach when** drag substitutes for a button or a link; when there is no keyboard equivalent
  (every Draggable needs a focusable target and arrow-key handling); or `type: 'scroll'` on the
  document body, which is scroll-jacking.

### Inertia
- **Right tool when** paired with Draggable and a released object should keep going and land somewhere
  meaningful — `snap` + `inertia` together are the point.
- **Over-reach when** there is momentum on something the user did not throw, or on a control where
  overshoot changes a value: a price, a quantity, a date.

### Observer
- **Right tool when** you need unified wheel/touch/pointer input for a **non-scroll** gesture — a
  section switcher, a swipeable panel, a dial, pull-to-reveal — or the cheapest scroll-direction read
  without a full ScrollTrigger.
- **Over-reach when** it takes over the wheel on an ordinary scrolling page. If you `preventDefault`,
  you now own the keyboard, screen-reader, and reduced-motion paths for that gesture. Do it
  deliberately and narrowly or not at all.

## Easing

### CustomEase
- **Right tool when** a named ease demonstrably does not fit the physical story: a settle with a
  specific overshoot, or a curve traced from a reference video or a brand motion spec.
- **Over-reach when** the hand-drawn curve is within a hair of `power2.out`.
  **House eases:** `power3.out` for entrances, `power2.in` for exits, `none` for anything scrubbed.

### EasePack
- **Right tool when** you specifically want `rough`, `slow`, or `expoScale` — `slow` in particular for a
  move that should linger at its midpoint.
- **Over-reach when** reached for before trying the built-in `power`/`back`/`elastic` families.

### CustomWiggle
- **Right tool when** the shake is discrete and physically motivated: a rejected field, a rattling
  container, a bulb flickering from a source you can see.
- **Over-reach when** it is ambient wiggle on decoration, or anything that loops forever — an
  unattended loop keeps a phone's GPU warm for the whole session.

### CustomBounce
- **Right tool when** an object with mass lands on a surface, once, and the squash carries meaning — a
  dropped card, a stamp.
- **Over-reach when** bouncing UI chrome or text, or when `back` / `elastic` was already close enough.

## Physics and rendering

### Physics2D
- **Right tool when** many independent particles move under one shared force with no authored path —
  sparks, debris, confetti on a real accomplishment.
- **Over-reach when** you could have keyframed it; confetti as a default success state; any particle
  field with no physical source in the scene.

### PhysicsProps
- **Right tool when** a single non-positional property needs velocity and friction rather than a
  duration — a needle, a dial settling.
- **Over-reach when** a `back` or `elastic` ease reads the same.

### GSDevTools
- **Right tool when** scrubbing a long authored timeline while tuning it. **Dev only.**
- **Over-reach when** it ships. Same preflight grep as `markers` and MotionPathHelper.

### Easel / Pixi
- **Right tool when** the project already renders through EaselJS or PixiJS and you want GSAP driving
  their display objects.
- **Over-reach when** neither library is already in the project. Introducing a canvas renderer to
  animate DOM is the wrong end of the ladder (`SKILL.md` §2).

---

## Quick index by intent

| You are about to… | Reach for |
|---|---|
| animate between two layouts of the same element | **Flip** |
| reveal the page's one headline | **SplitText** (lines, masked, `onSplit`) |
| time something to scroll position | **ScrollTrigger** |
| build a non-scroll wheel/touch gesture | **Observer** |
| let the user throw something | **Draggable + Inertia** |
| draw a meaningful line | **DrawSVG** |
| move something along a curve, facing forward | **MotionPath** (`autoRotate`) |
| swap an icon between two states | **MorphSVG** |
| scroll to an anchor | **nothing** — native `scrollIntoView` |
| fade a hover state | **nothing** — a CSS transition |
| show a loading spinner | **nothing** — CSS keyframes |
