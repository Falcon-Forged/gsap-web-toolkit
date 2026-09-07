/**
 * The house section-initializer contract.
 *
 * One initializer per animated section. It takes the section root, owns
 * everything it creates, and returns a disposer that releases all of it.
 *
 * Rename initSection and the data attributes; keep the shape.
 */
import { gsap, ScrollTrigger, type Disposer } from './register';

export function initSection(root: HTMLElement): Disposer {
  const mm = gsap.matchMedia();

  mm.add(
    {
      // A breakpoint pair that always matches SOMETHING is required.
      //
      // With only a reduce/no-preference query in this object, the handler never
      // fires for the majority of visitors — the ones who have expressed no
      // preference at all — and every reveal silently never runs. The page looks
      // fine in a browser with reduced motion forced either way, and broken for
      // everyone else. This has shipped once.
      desktop: '(min-width: 961px)',
      compact: '(max-width: 960px)',
      motionOK: '(prefers-reduced-motion: no-preference)',
    },
    (context) => {
      if (!context.conditions?.motionOK) return;

      const q = gsap.utils.selector(root);
      const desktop = Boolean(context.conditions.desktop);

      // Anything GSAP does not own — listeners, rAF handles, observers, media
      // sources — is pushed here and drained below. context.revert() releases
      // GSAP's own work and nothing else.
      const disposers: Disposer[] = [];

      // Tween TO the resting state. The start state lives in CSS behind .js, so a
      // visitor whose JS never boots gets the finished page — and nothing is ever
      // held out of the accessibility tree by a trigger that has not fired.
      gsap.to(q('[data-reveal]'), {
        opacity: 1,
        y: 0,
        duration: 0.52,
        ease: 'power3.out',
        stagger: 0.08,
        clearProps: 'transform',
        scrollTrigger: {
          trigger: root,
          start: 'top 88%',
          // once + clearProps go together. Never pair clearProps with a
          // toggleActions that reverses — a tween that cleared its own
          // properties has nothing left to reverse.
          once: true,
        },
      });

      // Do NOT nest gsap.context() here; matchMedia already made one.
      return () => {
        disposers.forEach((dispose) => dispose());
        disposers.length = 0;
      };
    },
    // Scope: selector text inside the handler is limited to this root.
    root,
  );

  // Refresh after the two things that change layout late. Not per frame, not
  // per scroll.
  const refresh = () => ScrollTrigger.refresh();
  window.addEventListener('load', refresh, { once: true });
  document.fonts?.ready.then(refresh).catch(() => undefined);

  return () => {
    window.removeEventListener('load', refresh);
    mm.revert();
  };
}
