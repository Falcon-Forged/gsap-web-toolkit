---
name: gsap-audit
description: >-
  Read-only motion audit of an existing site against the house GSAP rules.
  Inspects GSAP and CSS animation for accessibility (nothing held out of the tab
  order or the accessibility tree by a reveal whose trigger has not fired),
  reduced-motion and Save-Data fallbacks, ScrollTrigger cleanup and refresh
  behaviour, layout-property animation, pin-induced layout shift, leftover debug
  markers or GSDevTools, stale dependency ranges, and plugin over-reach. Produces
  a findings table with file paths, line numbers, severity, effort estimates, and
  an explicit "not adopting" list; changes no code. Use before shipping motion
  work, when inheriting a site that already has animation, when deciding whether
  a GSAP plugin is worth adopting, or when motion feels janky, jumpy, or
  unreachable by keyboard. Triggers: "review the animations", "audit motion",
  "audit the GSAP", "why is this janky", "is this animation accessible", "motion
  checklist", "check reduced motion", "ScrollTrigger leak", "the page jumps when
  I scroll", "animation performance", "should we use Flip here".
license: MIT
---

# GSAP Motion Audit

Read-only. Produce findings; change nothing. If the user wants fixes, that is a separate pass against
`gsap-house`.

## Procedure

1. **Establish the stack.** Read `package.json` for `gsap`, `@gsap/react`, and any competing motion
   library (`motion`, `framer-motion`, `lottie`, `anime`). Two motion libraries in one bundle is a
   finding on its own. Note the framework — it decides which cleanup rules apply.
2. **Find the motion.** Locate every GSAP import, every `@keyframes`, every `transition:` that carries
   more than a colour, and every `scrollIntoView`/`window.scrollTo`. Flag any file carrying a
   `21st.dev` provenance header, or matching a 21st registry install, for the SOURCED section of the
   checklist.
3. **Run the checklist** in `gsap-house`'s `references/review.md`. That file is the source of the
   severity ladder — do not invent a different one.
4. **Check the estate record.** Read the toolkit's `audits/` directory. A file may already have a
   finding with an agreed approach, or an explicit *not adopting* decision that you should not reopen.
5. **Write findings** in the block format below, ordered by severity.
6. **Write the "Explicitly not adopting" list.** This is required, not optional — see below.
7. **State what you could not verify.** If you did not run a browser, say which checks are unverified.

## Severity ladder

`A11Y > CORRECTNESS > PERF > HYGIENE > CRAFT > OPPORTUNITY`

- **A11Y** — content or a control is unreachable: held out of the tab order by an unfired reveal, lost
  under reduced motion, or stranded behind a scroll trap. Blocking.
- **CORRECTNESS** — leaks, double-init, a matchMedia branch that never fires, a disposer that does not
  dispose. Blocking.
- **PERF** — layout properties on a scrubbed path, unbounded `will-change`, unattended loops,
  pin-induced CLS.
- **HYGIENE** — shipped debug markers, stale dependency ranges, unused registered plugins, a
  GreenSock token in an `.npmrc`.
- **CRAFT** — the motion works and is safe, but it is generic, over-reaching, or inconsistent.
- **OPPORTUNITY** — no defect; a plugin or pattern would make this materially better.

## Effort scale

`S` under 1h · `M` 1–4h · `L` 1–2d · `XL` over 2d. Include the setup cost — adding `gsap` to a project
that does not have it is part of the estimate.

## Finding block

```markdown
##### <SITE>-<nn> — <one-line claim>  [SEVERITY] [EFFORT]
- **File**   path/to/file.ts:120-140
- **Today**  what the code does now, in one sentence
- **Wrong because**  the consequence for a real visitor — not a restatement of the rule
- **Proposed**  the house rule or plugin, named
- **Blast radius**  what else changes, what could break
- **Verify**  the command or the manual check that proves it
```

IDs are `<SITE>-<nn>` and are **stable across re-audits** — a fixed finding keeps its number and is
marked resolved, never recycled.

"Wrong because" is the field that does the work. *"Uses `autoAlpha`"* is not a finding.
*"Every buy link on the shop page is unreachable by keyboard until the visitor scrolls that card into
view"* is.

## The "Explicitly not adopting" list

Every site section ends with one. It records the plugins and patterns you considered and rejected, and
why. Two reasons it is mandatory:

- It is the evidence this is a **standard**, not a campaign to put GSAP everywhere. An audit that only
  ever recommends adding things is a sales pitch.
- It stops the next agent adding ScrollToPlugin "for symmetry" six months from now.

Format: one line each — plugin, and the reason it does not fit *this* site.

## Scope boundary

The house default — GSAP for new web work — covers **marketing, portfolio, and narrative surfaces**.
It does not mean adding a motion library to an authenticated product workspace. When auditing an app
rather than a site, the correct finding is usually *"keep the CSS,"* and the audit should say so
explicitly rather than staying silent.

Full criteria: `gsap-house` → `references/review.md`. Plugin fit: `references/plugins.md`.
