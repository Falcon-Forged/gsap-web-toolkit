# GSAP Web Toolkit — Agent Instructions

These rules apply to Codex, Claude Code, JARVIS, and any other coding agent.

This repo is the single source of truth for how web motion is built in this estate. It ships two
plugins to three agent surfaces from one checkout.

## What is here

| Path | What it is |
|---|---|
| `plugins/gsap-toolkit/skills/gsap-house/` | The house motion contract — rules, plugin matrix, framework adapters, scaffolds. **Hand-authored, edit freely.** |
| `plugins/gsap-toolkit/skills/gsap-audit/` | The read-only per-site motion audit skill. |
| `plugins/gsap-vendor/skills/` | The eight official GreenSock skills (MIT). **Generated. Never hand-edit.** |
| `vendor.lock.json` | The upstream pin: repo, commit SHA, and a sha256 per vendored file. |
| `audits/` | Per-site motion audits, with stable finding IDs. |

## The one rule that matters

**Never edit anything under `plugins/gsap-vendor/skills/`.** It is a byte-for-byte copy of
`greensock/gsap-skills` at the commit in `vendor.lock.json`, and `scripts/check-vendor.sh` fails CI if
it drifts. House deltas — including places where we deliberately disagree with GreenSock — belong in
`gsap-house/SKILL.md`, which states that it overrides the vendor skills and names the conflicts.

To take an upstream change:

```bash
scripts/check-upstream.sh                    # is upstream ahead of our pin?
scripts/sync-vendor.sh --sha <new-sha>       # fetch, re-lock, re-stamp both manifests
git diff --stat plugins/gsap-vendor          # review before committing
```

Review the diff rather than rubber-stamping it: an upstream rewrite can contradict a house rule, and
reconciling that is a human decision.

## Versions are cachebusters, not decoration

Claude Code and Codex both install plugins as **cached copies keyed by the `version` in
`plugin.json`**. A content change under an unchanged version does not reach either tool. So:

- Vendor bumps: `sync-vendor.sh` stamps both vendor manifests automatically.
- House changes: bump `version` by hand in **both** `plugins/gsap-toolkit/.claude-plugin/plugin.json`
  and `plugins/gsap-toolkit/.codex-plugin/plugin.json`.

OpenClaw is the exception — it loads this tree live via `skills.load.extraDirs` with `watch: true`,
so it needs no bump and no reinstall.

## Always-on context cost (measured)

Every skill description is loaded in every session on every surface, forever — including
sessions that have nothing to do with the web. Measured on 2026-09-07 via `claude plugin details`:

| Plugin | Always-on |
|---|---|
| `gsap-toolkit` (2 skills) | ~874 tok |
| `gsap-vendor` (8 skills) | ~1,141 tok |
| **Total** | **~2,015 tok** |

The plan for this repo set a 1.5k threshold above which `gsap-vendor` would be scoped per-project.
We are over it and both plugins are still installed at user scope anyway, deliberately: scoping the
vendor skills per-project reintroduces exactly the per-repo setup step this repo exists to remove,
and 2k tokens is a fair price for GSAP being available wherever you are. Recording the number rather
than the rule, so the trade-off is re-checkable.

The escape hatch, if it ever bites: install `gsap-vendor` with `--scope project` in web repos and
keep only `gsap-toolkit` global. That is why the two plugins have no `dependencies` link.

CI enforces a 6,000-character ceiling on total frontmatter descriptions. Adding a third house skill
is the thing most likely to breach it — put depth in `references/`, not in a new skill.

## Licensing — say this correctly

Every GSAP plugin is free, including for commercial use, including SplitText and MorphSVG. Install
from the public `gsap` package. Never generate an `.npmrc` with a GreenSock auth token, never point at
`npm.greensock.com`, never suggest joining Club GSAP. Full text and the verification command:
`plugins/gsap-toolkit/skills/gsap-house/references/licensing.md`.

## Writing house rules

Rules in `gsap-house` are **mined from shipped code, not invented**. Each one should be traceable to a
bug that actually happened or a pattern that is actually running in production. If you cannot say what
goes wrong without the rule, it is not a rule yet.

A claim about a stack in any `AGENTS.md` — ours or a consuming project's — must be verifiable from
`package.json` or `src/`. That rule exists because a project doc in this estate asserted a smooth-scroll
library was powering its homepage for months after it had never been installed.

## Skill layout constraints

- Skills sit at `plugins/<plugin>/skills/<name>/SKILL.md` — exactly one level deep, which auto-discovery
  covers. **Do not add a `skills` key** to `gsap-toolkit`'s manifest; it is only needed for deeper
  nesting, and getting it wrong silently loads zero skills.
- Frontmatter: `name`, `description`, `license`. The description is the entire triggering mechanism —
  keep the explicit `Triggers:` phrase list, and keep it in **outcome** vocabulary ("scroll reveal",
  "make this feel more alive"), because an agent writing a hero section never types "GSAP".
- `SKILL.md` stays under 500 lines. Detail goes in `references/`; code goes in `assets/`.
- Each house skill carries `agents/openai.yaml` for Codex's display metadata. The vendored skills do
  not — adding files there would break the byte-identity check.

## Verify before claiming it works

```bash
scripts/check-vendor.sh
claude plugin validate --strict .
claude plugin details gsap-toolkit@gsap-web-toolkit   # expect Skills (2)
openclaw skills list --agent main | grep gsap         # expect 10
```

`Skills (0)` from `plugin details` means the manifest and the on-disk layout disagree — the skills are
silently not loading, and no other check catches it.
