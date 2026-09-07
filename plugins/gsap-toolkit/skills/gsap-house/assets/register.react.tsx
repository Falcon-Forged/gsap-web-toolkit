'use client';
/**
 * React registration. Module scope, not component scope.
 *
 * Registering inside an effect re-runs on every dependency change and scatters
 * the plugin list across components. useGSAP is itself a plugin and must be
 * registered before first use.
 */
import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(useGSAP, ScrollTrigger);

// Same svh/dvh precondition as the vanilla register — see register.ts.
ScrollTrigger.config({ ignoreMobileResize: true });

export { gsap, ScrollTrigger, useGSAP };

export type Disposer = () => void;
