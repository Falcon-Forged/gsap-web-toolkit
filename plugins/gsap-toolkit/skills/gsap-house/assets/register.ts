/**
 * The one place GSAP is imported and plugins are registered.
 *
 * Every other module imports from here, never from 'gsap' directly. That keeps
 * registration single-sourced, keeps tree-shaking predictable, and gives one
 * place to add a plugin when a section needs it.
 *
 * Add plugins here as sections need them — not speculatively. Every registered
 * plugin is bundle weight on every page.
 */
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

/**
 * Mobile browsers fire resize as the address bar collapses and returns. Left on,
 * each one is a full ScrollTrigger refresh mid-scrub — and with
 * invalidateOnRefresh that visibly snaps the scrub.
 *
 * PRECONDITION: every stage and track height in this project is in svh/dvh, so
 * none of them ever depended on those resizes. If any height is still in vh,
 * fix the CSS first — do not set this flag. Desktop resizes still refresh.
 */
ScrollTrigger.config({ ignoreMobileResize: true });

export { gsap, ScrollTrigger };

/** Every init function returns one of these. It releases everything it created. */
export type Disposer = () => void;

export const NOOP: Disposer = () => undefined;
