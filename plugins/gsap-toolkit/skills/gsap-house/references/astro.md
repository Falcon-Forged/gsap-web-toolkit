# Astro adapter

Astro ships zero JS by default and swaps documents on client-side navigation. Both facts shape how
GSAP is wired here.

## File layout

```
src/
  components/Section.astro        # markup + data-* hooks + a <script> that boots the module
  scripts/
    gsap/
      register.ts                 # the ONLY file that imports 'gsap'
      section-name.ts             # one initX(root) per animated section
    motion.ts                     # entry: clears the reveal deadline, boots the sections
  styles/
    reveal-gate.css               # .js start states
```

Copy `assets/register.ts` and `assets/section.template.ts` verbatim as the starting point.

## Component hookup

```astro
---
// Section.astro
---
<section data-section-motion>
  <h2 data-reveal>…</h2>
  <p data-reveal>…</p>
</section>

<script>
  import { initSection } from '../scripts/gsap/section-name';

  const disposers: Array<() => void> = [];

  const boot = () => {
    document
      .querySelectorAll<HTMLElement>('[data-section-motion]')
      .forEach((root) => disposers.push(initSection(root)));
  };

  const teardown = () => {
    disposers.forEach((dispose) => dispose());
    disposers.length = 0;
  };

  boot();

  // View transitions swap the document. Without this, every navigation leaks a
  // full set of ScrollTriggers and the page gets progressively janky the longer
  // the session runs. This is the single most common Astro GSAP bug.
  document.addEventListener('astro:before-swap', teardown);
  document.addEventListener('astro:page-load', boot);
</script>
```

If the project does **not** use `<ViewTransitions />`, the two listeners are harmless and cost nothing.
Leave them in — they are insurance against the day someone enables it.

## Islands

GSAP does not need an island. A plain `<script>` in an `.astro` component is bundled, scoped to that
component's usage, and runs after hydration of anything around it. Do not add
`client:load` to a component purely to animate it — that ships a framework runtime to do a job the
`<script>` already does.

Reach for a React island (and `references/react.md`) only when the motion is genuinely driven by
component state.

## Boot order

1. `reveal-gate.head.html` in the base layout `<head>` — adds `.js`, arms the 2.5s deadline.
2. `reveal-gate.css` imported by the base layout's stylesheet.
3. `src/scripts/motion.ts` clears the deadline on its first line, calls `setMotionTier()`, and returns
   early on the static tier before importing anything heavy.

```ts
// src/scripts/motion.ts
declare global { interface Window { __revealFallback?: number } }

if (window.__revealFallback) {
  clearTimeout(window.__revealFallback);
  window.__revealFallback = undefined;
}

import { setMotionTier } from './gate';

if (setMotionTier() === 'enhanced') {
  // Dynamic import so reduced-motion and Save-Data visitors never fetch the
  // GSAP bundle at all. This is the whole point of gating before the fetch.
  const { initSection } = await import('./gsap/section-name');
  // …boot
}
```

## Scrubbed vs toggled

```ts
// Scrubbed: progress is a function of scroll position.
scrollTrigger: {
  trigger: root, start: 'top top', end: '+=560',
  pin: true, scrub: 1, anticipatePin: 1,
  invalidateOnRefresh: true, id: 'hero-pin',
}

// Toggled: the scroll position is a threshold, not a dial.
scrollTrigger: {
  trigger: element, start: 'top 88%',
  toggleActions: 'play none none reverse',
}
```

Never both on one trigger. See `SKILL.md` §6 for the `clearProps` interaction.

## Sticky, not pinned, where you can

CSS `position: sticky` on the stage is often better than a ScrollTrigger pin: the compact layout simply
stops being sticky and the beats read as a stacked story, with no pin-spacer and no CLS risk on
refresh. Use a pin when you need the scrubbed progress of the pinned range; use sticky when you only
need the element to hold still.

## Lenis

**Do not add it during first setup.** Native scroll plus a well-tuned `scrub` value covers most of what
people reach for Lenis to fix, and Lenis brings anchors, focus, history, and keyboard scrolling into
your maintenance surface. If it is later approved: disable it for reduced motion and touch, verify
anchors/focus/history/keyboard still work, and wire it to `ScrollTrigger.update()`.

If a project's docs claim Lenis is in use, verify against `package.json` before believing it —
that claim has been stale in this estate before.
