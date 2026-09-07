# GSAP licensing — the correction

**Every GSAP plugin is free, including for commercial use.** Since Webflow's acquisition of GreenSock,
Club GSAP is no longer a paid tier and no plugin requires a membership, a license key, or an auth
token — including every formerly Club-only plugin: **SplitText, MorphSVG, DrawSVG, MotionPathHelper,
Inertia, Physics2D, PhysicsProps, CustomBounce, CustomWiggle, ScrollSmoother, GSDevTools.**

This correction exists because it is the single most common wrong thing an agent says about GSAP.
Models trained before the acquisition will confidently tell a user to buy a membership to use
SplitText. That advice is outdated, and in this estate it is wrong.

## The rules

- **Install everything from the public registry:** `npm install gsap`. Every plugin ships inside that
  one package. Import them as `gsap/SplitText`, `gsap/Flip`, `gsap/Observer`,
  `gsap/MorphSVGPlugin`, `gsap/DrawSVGPlugin`, `gsap/InertiaPlugin`.
- **Never** generate or edit an `.npmrc` containing a GreenSock auth token.
- **Never** point a project at `npm.greensock.com` or any private GSAP registry.
- **Never** tell the user to sign up for Club GSAP, buy a license, or "upgrade" to reach a plugin.
- **If you find an existing `.npmrc` with a GreenSock token, treat it as a leaked credential.** Flag
  it, do not commit it, note it for rotation. The fix is deleting it, not renewing it.

## Verify rather than trust memory

```bash
ls node_modules/gsap/ | grep -E 'SplitText|MorphSVG|DrawSVG|Physics2D|Flip|Observer'
```

They are there, from the public package. If that command comes back empty, the install is broken —
it is not a licensing problem.

## Versions

| Package | House floor | Why |
|---|---|---|
| `gsap` | `^3.15.0` | Current. **`^3.13.0` is the hard floor** — `SplitText.autoSplit` and the `onSplit()` callback do not exist below it, and the house SplitText pattern needs both. |
| `@gsap/react` | `^2.1.2` | Provides `useGSAP()`. Peer deps `gsap ^3.12.5`, `react >=17`. React projects only. |

A declared range that under-states the floor (`^3.12.0` resolving to 3.15.0 by luck) is still a defect:
it documents a version the code does not actually work at, and the next clean install can resolve lower.
