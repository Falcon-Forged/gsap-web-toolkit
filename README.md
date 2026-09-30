# GSAP Web Toolkit

House GSAP conventions for web work, distributed to **Claude Code, Codex, and OpenClaw** from one
checkout, layered on the official GreenSock skills.

Two plugins:

- **`gsap-toolkit`** — the house layer. `gsap-house` (the motion contract, plugin adoption matrix,
  framework adapters, and copy-paste scaffolds) and `gsap-audit` (a read-only per-site motion audit).
- **`gsap-vendor`** — the eight official [GreenSock](https://github.com/greensock/gsap-skills) skills,
  MIT, vendored byte-for-byte at a pinned commit.

## Why this exists

GSAP has roughly nineteen plugins. Most teams use one. Ours used one — `ScrollTrigger` — not because
the others were wrong for the work but because nothing in any of our three agent surfaces knew they
existed. The official skills were installed in exactly one project, in a directory Claude Code does not
even scan, pointed at by a line in a file Codex never reads.

This repo fixes the distribution problem: one source of truth, three native registrations, one pinned
upstream.

## Install

```bash
git clone https://github.com/Falcon-Forged/gsap-web-toolkit ~/GitHub/gsap-web-toolkit
```

**Claude Code**
```bash
claude plugin marketplace add ~/GitHub/gsap-web-toolkit --scope user
claude plugin install gsap-toolkit@gsap-web-toolkit --scope user --yes
claude plugin install gsap-vendor@gsap-web-toolkit  --scope user --yes
```

**Codex**
```bash
codex plugin marketplace add ~/GitHub/gsap-web-toolkit
codex plugin add gsap-toolkit@gsap-web-toolkit
codex plugin add gsap-vendor@gsap-web-toolkit
# then start a NEW thread — Codex picks up skills per-thread
```

**OpenClaw** — append both `skills/` directories to `skills.load.extraDirs`. On the JARVIS host,
`scripts/97-install-gsap-toolkit.sh` in the `jarvis-ai` repo does all three surfaces idempotently.

## The house rules, in one paragraph

GSAP is the default motion library for new **marketing, portfolio, and narrative** web work — not for
authenticated product surfaces, where the right answer is usually the CSS you already have. Motion is
budgeted: one orchestrated non-user-triggered moment per page; everything else is a response to a user
action or information. Every animated surface ships a designed reduced-motion state (and a Save-Data
one), explicit cleanup, and a mobile path. Nothing is ever held out of the accessibility tree by an
animation that has not run yet.

Full contract: [`gsap-house/SKILL.md`](plugins/gsap-toolkit/skills/gsap-house/SKILL.md).

## Sourcing components from 21st.dev

Before hand-building a motion component, agents search [21st.dev](https://21st.dev) through the `21st`
CLI or MCP server, shortlist by fit, engine, and code quality (using the site's Featured and Popular
listings as a starting order), then adapt, rebase onto the house templates, or treat it as inspiration.
Nothing is used out of the box, and everything sourced passes the same tests, `gsap-audit`, and design
council as hand-written motion. Workflow:
[`references/21st-dev.md`](plugins/gsap-toolkit/skills/gsap-house/references/21st-dev.md).

## Licensing

**Every GSAP plugin is free**, including for commercial use, since Webflow's acquisition of GreenSock —
SplitText and MorphSVG included. Install from the public `gsap` package; there is no auth token, no
private registry, and no Club GSAP tier to join. Models trained before the acquisition get this wrong
routinely, which is why it is stated in the skill, in `AGENTS.md`, and here.

Details: [`references/licensing.md`](plugins/gsap-toolkit/skills/gsap-house/references/licensing.md).

## Upstream pin

`plugins/gsap-vendor/skills/` is generated, never hand-edited. `vendor.lock.json` records the upstream
commit and a sha256 per file; `scripts/check-vendor.sh` enforces it in CI.

```bash
scripts/check-upstream.sh                 # has GreenSock moved?
scripts/sync-vendor.sh --sha <new-sha>    # take it
scripts/check-vendor.sh                   # prove the tree matches the lock
```

## Audits

`audits/` holds per-site motion audits with stable finding IDs. Each one ends with an explicit
**"Explicitly not adopting"** list — the record of what was considered and rejected, which is what keeps
this a standard rather than a campaign to put GSAP everywhere.

## License

MIT (this repo). The vendored GreenSock skills are MIT — see
[`plugins/gsap-vendor/NOTICE.md`](plugins/gsap-vendor/NOTICE.md).
