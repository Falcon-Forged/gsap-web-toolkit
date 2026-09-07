'use client';
/**
 * The house section contract, React edition.
 *
 * Three things make this different from a useEffect that happens to call gsap:
 *   1. useGSAP owns the context and reverts it — including under StrictMode's
 *      double-invoke, which a hand-rolled effect gets wrong.
 *   2. `scope` is mandatory. A bare selector string without it reaches the whole
 *      document, so two instances of this component animate each other's nodes.
 *   3. Anything created inside an event handler must be wrapped in contextSafe(),
 *      or it escapes the context and leaks.
 */
import { useRef } from 'react';
import { gsap, useGSAP } from './register.react';
import { motionDenied } from './gate';

export function Section() {
  const root = useRef<HTMLElement>(null);

  const { contextSafe } = useGSAP(
    () => {
      // Static page for reduced-motion and Save-Data visitors.
      if (motionDenied()) return;

      const mm = gsap.matchMedia();

      mm.add(
        {
          // The always-matching breakpoint pair is required — see the comment in
          // section.template.ts. An object with only reduce/no-preference never
          // fires for visitors who expressed no preference.
          desktop: '(min-width: 961px)',
          compact: '(max-width: 960px)',
          motionOK: '(prefers-reduced-motion: no-preference)',
        },
        (context) => {
          if (!context.conditions?.motionOK) return;

          gsap.to('[data-reveal]', {
            opacity: 1,
            y: 0,
            duration: 0.52,
            ease: 'power3.out',
            stagger: 0.08,
            clearProps: 'transform',
            scrollTrigger: { trigger: root.current, start: 'top 88%', once: true },
          });
        },
        root,
      );

      // Explicit, even though useGSAP's own context would revert it: the house
      // rule is that whatever a module creates, that module releases by name.
      return () => mm.revert();
    },
    { scope: root },
  );

  // Example of the contextSafe requirement — without the wrapper this tween is
  // created outside the context and is never reverted.
  const onPress = contextSafe(() => {
    gsap.to('[data-reveal]', { scale: 0.98, duration: 0.12, yoyo: true, repeat: 1 });
  });

  return (
    <section ref={root} onPointerDown={onPress}>
      {/* … */}
    </section>
  );
}
