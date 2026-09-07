/**
 * The two conditions under which this site does not animate at all.
 *
 * Save-Data sits next to prefers-reduced-motion deliberately: the visitor who set
 * it is on a metered or slow connection, and the honest response to that is the
 * static page, not a cheaper animation. Gating HERE — before any video source is
 * chosen or any sprite is fetched — is what makes it mean anything. A gate that
 * runs after the fetch has already started saves nothing.
 */
export function motionDenied(): boolean {
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const saveData = Boolean(
    (navigator as Navigator & { connection?: { saveData?: boolean } }).connection?.saveData,
  );
  return reduce || saveData;
}

/**
 * Writes the motion tier onto <html> and returns whether motion may run.
 *
 * CSS reads [data-motion="static"] to supply the complete still layout, and later
 * modules read it to decide whether the layout they are about to measure is the
 * enhanced one or the static one.
 */
export function setMotionTier(): 'static' | 'enhanced' {
  const tier = motionDenied() ? 'static' : 'enhanced';
  document.documentElement.dataset.motion = tier;
  return tier;
}
