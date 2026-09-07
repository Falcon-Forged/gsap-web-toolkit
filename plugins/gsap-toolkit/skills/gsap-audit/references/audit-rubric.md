# Audit rubric

The rubric is **not duplicated here**. It is the preflight checklist at
`gsap-house/references/review.md`, read with an auditor's eye instead of an author's.

Two files, one ladder, on purpose: a check that blocks a hand-off must be the same check that raises a
finding, or the two drift and "passes preflight" stops meaning "passes audit".

Read, in order:

1. `gsap-house/references/review.md` — the criteria and the severity ladder.
2. `gsap-house/references/plugins.md` — for every adopt/do-not-adopt call, and especially the
   over-reach column, which is where CRAFT findings come from.
3. `gsap-house/SKILL.md` §4 (opacity vs autoAlpha) and §6 (ScrollTrigger rules) — the two sections that
   generate the most A11Y and CORRECTNESS findings in practice.
4. The toolkit's `audits/` directory — for existing findings and prior *not adopting* decisions on the
   files you are about to look at.
