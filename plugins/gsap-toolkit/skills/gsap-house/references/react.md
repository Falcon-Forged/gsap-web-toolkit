# React / Next.js adapter

Use `@gsap/react` (`^2.1.2`). `useGSAP()` is a drop-in replacement for `useLayoutEffect`/`useEffect`
that owns a `gsap.context()` and reverts it on unmount — including under StrictMode's double-invoke,
which a hand-rolled effect gets wrong.

Load the official `gsap-react` skill for the full API. This file is the house delta.

## The three rules

**1. Register at module scope, never in an effect.**

```tsx
// motion/register.react.tsx  — see assets/register.react.tsx
'use client';
import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(useGSAP, ScrollTrigger);
ScrollTrigger.config({ ignoreMobileResize: true });

export { gsap, ScrollTrigger, useGSAP };
```

Registering inside `useEffect` re-runs on every dependency change and scatters the plugin list across
components. `useGSAP` is itself a plugin and must be registered before first use.

**2. `scope` is mandatory.** A bare selector string without it reaches the whole document, so two
instances of the same component animate each other's nodes.

```tsx
const root = useRef<HTMLElement>(null);
useGSAP(() => { /* '[data-reveal]' resolves inside root only */ }, { scope: root });
```

**3. Anything created in an event handler must be wrapped in `contextSafe()`,** or it escapes the
context and leaks.

```tsx
const { contextSafe } = useGSAP(() => { /* … */ }, { scope: root });
const onPress = contextSafe(() => gsap.to('[data-reveal]', { scale: 0.98, duration: 0.12 }));
```

Full worked component: `assets/section.react.tsx`.

## Server components and `'use client'`

GSAP touches the DOM, so every module that imports it is a client module. Keep the boundary tight:
the animated leaf is `'use client'`, its parent page stays a server component. Do not mark a whole
route client just to animate a hero.

## Next.js App Router navigation

Client-side navigation unmounts components, so `useGSAP` reverts correctly — **but** ScrollTriggers
created outside a `useGSAP` body (in a module-level init, a layout effect, or a third-party wrapper)
survive the navigation and accumulate. Symptom: scrolling gets progressively janky the longer a session
runs.

Verify with the count, not by eye:

```ts
// before navigating away, and again after navigating back
ScrollTrigger.getAll().length
```

It must be stable. `ScrollTrigger.refresh()` after a route change is also usually needed once the new
route's images and fonts settle.

## The gate in React

```tsx
useGSAP(() => {
  if (motionDenied()) return;   // assets/gate.ts — reduced motion OR Save-Data
  // …
}, { scope: root });
```

A user-facing motion toggle layered *over* the gate is a genuine improvement, not a replacement for it:
default the switch from `prefers-reduced-motion`, let the visitor override, and keep Save-Data as a
hard floor.

## matchMedia inside useGSAP

The object-form gotcha from `SKILL.md` §5 applies unchanged — always include an always-matching
breakpoint pair alongside `motionOK`, or the handler never fires for visitors with no stated
preference. Return `mm.revert()` from the `useGSAP` body explicitly, even though the context would
also revert it: the house rule is that whatever a module creates, that module releases by name.

## Do not reach for GSAP first in React

React already re-renders on state change, and CSS transitions on `transform`/`opacity` cover most
enter/leave and hover work with no library. The ladder in `SKILL.md` §2 applies here more strictly than
anywhere else, because a React app is usually a product surface rather than a narrative one — and an
authenticated workspace is explicitly outside the scope of the house motion default.
