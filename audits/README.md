# Audits

Per-site motion audits, produced by the `gsap-audit` skill.

## Conventions

- **One file per audit round**, named `<YYYY-MM>-motion-adoption.md`.
- **Finding IDs are stable.** `SC-03` means the same thing forever. A fixed finding keeps its number
  and is marked resolved in the next round; numbers are never recycled. That is what makes
  "is this still open?" answerable without re-reading the code.
- **Every site section ends with "Explicitly not adopting."** An audit that only recommends adding
  things is a sales pitch, not a standard. The rejection list is also what stops the next agent
  adding a plugin for symmetry six months from now.
- **Withdrawn findings stay in the document**, marked as corrected, with the evidence. "We checked and
  it was fine" is worth as much to the next auditor as a defect — otherwise the same false positive
  gets re-raised every round.

## When to re-audit

- A house rule changes in `gsap-house`.
- A site adds a motion surface.
- Before a redesign, so the existing findings inform it rather than being rediscovered after.

## Reading order for an auditor

1. `gsap-house/references/review.md` — the criteria and the severity ladder.
2. `gsap-house/references/plugins.md` — especially the over-reach column.
3. The most recent audit here — for open findings and prior rejections on the files you are about to
   look at.
