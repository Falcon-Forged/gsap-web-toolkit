# Vanilla / Vite / static adapter

No framework lifecycle to hang cleanup on, so the discipline is explicit: the reveal gate, the module
contract, and one entry point that boots and tears down.

## File layout

```
src/
  scripts/
    main.ts            # entry: clear the deadline, set the tier, boot sections
    gsap/
      register.ts      # the ONLY file that imports 'gsap'
      hero.ts          # initHero(root): () => void
      gallery.ts       # initGallery(root): () => void
  styles/
    reveal-gate.css
index.html             # carries reveal-gate.head.html in <head>
```

## The reveal gate is the load-bearing part here

On a static page there is no hydration signal, so a start state written in CSS with no JS to undo it is
a permanently blank page. The gate makes the failure mode safe:

1. `<head>` script adds `.js` and arms a 2500 ms deadline that removes it.
2. `reveal-gate.css` applies start states **only** under `.js`.
3. `main.ts` clears the deadline on its first line.

If the module never loads — a bundle 404, a syntax error on an old browser, a blocked CDN — the
deadline fires, `.js` comes off, and the visitor gets the finished page. If the module loads, it owns
the reveals from there.

```html
<!-- index.html <head>, before the stylesheet -->
<script>
  (function () {
    var h = document.documentElement;
    h.classList.add('js');
    window.__revealFallback = setTimeout(function () { h.classList.remove('js'); }, 2500);
  })();
</script>
```

```ts
// src/scripts/main.ts — first lines
declare global { interface Window { __revealFallback?: number } }
if (window.__revealFallback) {
  clearTimeout(window.__revealFallback);
  window.__revealFallback = undefined;
}
```

## Boot and teardown

```ts
import { setMotionTier } from './gate';

const disposers: Array<() => void> = [];

if (setMotionTier() === 'enhanced') {
  // Dynamic import: static-tier visitors never fetch the GSAP bundle.
  const [{ initHero }, { initGallery }] = await Promise.all([
    import('./gsap/hero'),
    import('./gsap/gallery'),
  ]);

  document.querySelectorAll<HTMLElement>('[data-hero]')
    .forEach((root) => disposers.push(initHero(root)));
  document.querySelectorAll<HTMLElement>('[data-gallery]')
    .forEach((root) => disposers.push(initGallery(root)));
}

// A multi-page static site reloads, so teardown is mostly insurance — but it is
// also how you verify the disposers actually work. Call it from the console and
// check ScrollTrigger.getAll().length drops to zero.
export const teardownMotion = () => {
  disposers.forEach((dispose) => dispose());
  disposers.length = 0;
};
```

Expose `teardownMotion` on `window` in dev builds only. The trigger-count check in
`references/review.md` needs it.

## Pointer-rate updates

For anything driven by `pointermove` — a cursor follower, a tilt, a spotlight — use `quickTo` or
`quickSetter`, never a fresh `gsap.to()` per event.

```ts
const setX = gsap.quickTo(el, 'x', { duration: 0.5, ease: 'power2.out' });
const setY = gsap.quickTo(el, 'y', { duration: 0.5, ease: 'power2.out' });
// quickSetter for no easing at all — a direct write, no tween machinery:
const setSpotX = gsap.quickSetter(spot, 'x', 'px');
```

Cache `getBoundingClientRect()` on `pointerenter` rather than reading it per move, and coalesce writes
into one `requestAnimationFrame`. A rect read per pointer event is a forced synchronous layout at
input rate.

## Multi-page sites

Each page load is a fresh document, so there is no leak surface — but that also means
`ScrollTrigger.refresh()` after `window.load` and `document.fonts.ready` matters more, because
above-the-fold images are the thing most likely to move a trigger's start position after first paint.
