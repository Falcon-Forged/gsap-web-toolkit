# Sourcing motion from 21st.dev

Before hand-building a motion component — a scroll reveal, a pinned or scrubbed scene, a headline or
image reveal, a parallax plate, a marquee, a cursor follower, a hero sequence — **search 21st.dev
first.** It is a community registry of React + Tailwind (shadcn-compatible) components, many of them
already written on GSAP + ScrollTrigger + SplitText. Someone has usually solved the mechanics; our job
is to pick the best one, make it obey this contract, and prove it.

Sourcing never changes the budget. Decide *which* moment the page gets (`SKILL.md` §2) first, then
search for the best way to build that moment. A great component for a moment the page did not need is
still over-reach.

Everything below was verified against the live CLI (`@21st-dev/cli` 1.17.1) and MCP server on
**2026-09-30**.

## Tools — CLI and MCP are the same catalog

| Job | CLI | MCP tool (`21st` server) |
|---|---|---|
| Search the catalog | `21st search "<query>" --type component --limit 15 --json` | `search` |
| Rerank against this project's design | `21st search "<query>" --context auto` | `get_inspiration` (pass `.21st/design.json` as `context`) |
| Read full source + demo | `21st get <id> --json` | `get_component` |
| Install into a shadcn project | `21st add <author>/<slug>` (`--print` to preview) | the `installCommand` from `get_component` |
| Deterministic local UI review | `21st review <path...>` | — |
| Photograph a component in isolation | `21st render <file> [--demo <f>] --video` | — |
| Generate when nothing fits | `21st generate "<prompt>" --variants N` | `generate` |
| Keep a vetted shortlist | `21st list-new` / `21st list-add <listId> <id> --type component` | `create_bookmark_list` / `add_to_list` |

Check auth before starting: `21st whoami` and `21st usage`. **Use whichever surface is authenticated**
— they hit the same endpoint. If the MCP server returns 401, the key in `API_KEY_21ST` is stale (old
Magic keys were reset); fall back to the CLI and tell the user to mint a fresh key at
https://21st.dev/mcp.

`generate` spends 21st AI credits. Search, get, and review do not.

## Step 1 — Ground the search in the site

Run once per project, from the app root:

```bash
21st init --design-context          # writes .21st/design.json from the real tokens and stack
21st init --design-context --check  # later: report drift
```

That file is what makes `--context auto` and `get_inspiration` rank against *this* site's palette,
type, and stack instead of the catalog average. Also have the site's motion direction in hand — the
design review's named moment, its reduced-motion state, and its mobile simplification.

## Step 2 — Search wide, by effect

Phrase queries by the **effect**, not the library, and run several — the catalog is keyword-sensitive.
For each effect family, try the plain name, a cinematic variant, and a `gsap` variant:

| Effect | Queries worth running |
|---|---|
| Headline / text reveal | `text reveal`, `line mask reveal`, `split text scroll`, `gsap splittext` |
| Image reveal | `image reveal`, `clip path reveal`, `curtain wipe image`, `scroll reveal image` |
| Cinematic scroll | `pinned scroll section`, `horizontal scroll gallery`, `scroll storytelling`, `sticky scroll` |
| Depth | `parallax hero`, `parallax layers`, `zoom scroll hero` |
| Transitions | `page transition`, `flip layout`, `shared element` |
| Ambient / pointer | `marquee`, `cursor follower`, `magnetic` |

Pull 10–15 results per query with `--json`. Discard anything whose description does not match the
effect before spending time on it.

**How ranking actually works.** Component search over the CLI and MCP is **relevance-ranked only** —
the `sort` parameter affects themes and templates, not components, and results carry no likes or
install counts. Popularity lives on the website: the **Featured** listing
(https://21st.dev/community/components/featured), the **Popular** listing
(https://21st.dev/community/components/popular), and the per-category pages
(`/community/components/s/<tag>` — Texts, Scroll Areas, Heroes, Images, Galleries, Backgrounds,
Marquees, Shaders). Open those in a browser for the effect family and note which candidates appear
there.

Use popularity as a **starting order, never as a pass.** A Featured component that fails §3 of the
house contract loses to an obscure one that meets it. What decides the shortlist, in order:

1. **Fit to the moment** — watch the `videoUrl` preview. Does it produce the effect the design named,
   at the right tempo and weight for this site?
2. **Engine** — GSAP + ScrollTrigger/SplitText beats Framer Motion/`motion` beats a bespoke rAF loop,
   because the first needs adapting and the others need porting.
3. **Code quality** — `21st get <id> --json` and read `componentCode`: cleanup, scoping, transform-only
   movement, reduced-motion handling, no `autoAlpha` on text.
4. **Popularity and author track record** — the tiebreaker.

Shortlist two or three and say which you picked and why.

## Step 3 — Choose an adoption mode

Out-of-the-box is never the default. Pick the least-invasive mode that ends up meeting the contract:

| Mode | When | What you do |
|---|---|---|
| **A — Adapt** | React + Tailwind + shadcn project; component already GSAP; defects are local | Install, then fix it in place against §3–§7 |
| **B — Rebase** | Right effect, wrong structure or engine (Motion/Framer, global selectors, JS-set start states) | Keep the choreography; rebuild it on `assets/section.react.tsx` or `section.template.ts`, the gate, the register module, and the reveal-gate CSS |
| **C — Inspiration** | Non-React stack (Astro, vanilla), unclear licence, or code you would rewrite anyway | Study the preview and source; write our own component from the house templates |

Motion/Framer components get ported to GSAP (mode B or C) unless the plan records an explicit decision
to take the dependency.

## Step 4 — Install hygiene

- **Preview before writing:** `21st add <author>/<slug> --print`. Confirm a `components.json` exists.
- **Never commit the key.** Install commands embed `?api_key=$API_KEY_21ST`. Keep it an environment
  variable; it must not land in `components.json`, a script, or a doc.
- **Read every file it writes**, including `registryDependencies` and helper modules. A registry item
  is source code landing in the repo — give it the read a PR gets. `git status --short` afterwards;
  anything outside `components/` is a failed install.
- **Provenance header** on the pulled or adapted file, and a line in the PR body:
  `// Adapted from 21st.dev @<author>/<slug> (id <n>) — <licence>`. If no licence is stated on the
  component page or the author's source repo, treat it as mode C.
- **Retune to the house.** Eases to the house set (`power3.out` entrances, `power2.in` exits, `none`
  for scrubbed), durations to the project's motion tokens, colours to the site's tokens. Upstream
  numbers are the author's taste.
- **One registration.** Move `gsap.registerPlugin(...)` into the project's register module and delete
  it from the component.

## Worked example — `@soralabs/text-reveal-block` (id 19260)

A well-built component that still needs mode A work before it meets the house contract. Line-by-line
colour-block wipe on GSAP SplitText + ScrollTrigger.

Good as shipped: animates `opacity`, not `autoAlpha` (§4); `once: true` reveal; kills its own triggers
and reverts its splits on unmount.

Needs work:

1. **Start state set by JS after mount** — `gsap.set(lines, { opacity: 0 })`. Move it to CSS behind
   `.js` with the boot deadline, and tween *to* the resting state (§3.3).
2. **No Save-Data branch**, and reduced motion comes from a React hook rather than the gate and
   `gsap.matchMedia()` (§3.1, §5).
3. **`SplitText` with `type: 'lines'` but no `autoSplit` / `onSplit()`** — lines are not re-split on
   resize, so a reflowed headline wipes the wrong line boxes (§8).
4. **Registers its plugins** in the component file — move to the register module.
5. **`power4.inOut` on every wipe** — retune to the house eases and the project's tokens.

## Step 5 — Test it like you wrote it

A sourced component is not pre-cleared by its popularity, its preview, or its author. Everything below
runs on the component **in the real page**, not in its demo.

1. `21st review <changed files>` — fix what it finds (`--fix` only for its conservative mechanical fixes).
2. Lint, typecheck, and a production build.
3. In a browser (the built-in browser or Playwright), at desktop and a 375 px mobile width:
   - scroll through the moment and capture evidence — screenshots at start, mid, and end of each
     trigger, and a short recording of any scrub or pin;
   - emulate `prefers-reduced-motion: reduce` and confirm a **complete** static page;
   - stub `navigator.connection.saveData = true` in an init script and confirm the same;
   - Tab from the top **without scrolling** and confirm every control is reachable before its reveal;
   - record `ScrollTrigger.getAll().length`, re-init or navigate away and back, and confirm it is unchanged;
   - take a performance trace across the scrub: no layout-property animation, no long tasks per frame.
4. Grep gates from `references/review.md` HYGIENE.

State anything you could not run. An unstated gap reads as a passed check.

## Step 6 — Review cycles

Sourced and custom components go through the same cycles as anything else, in this order:

1. **Preflight** — `references/review.md`, every blocking item.
2. **Audit** — the `gsap-audit` skill over the touched files. BLOCKER and HIGH findings are fixed
   before review continues.
3. **Design council** — the multi-lens cycle already used on this estate's cinematic sites: capture
   rendered evidence → independent lenses (typography, motion, colour and light, layout rhythm, copy,
   accessibility and interaction) → an adversarial verifier on every finding, defaulting to refuted
   when uncertain → ranked plan → implement → re-verify. Reference run:
   `stranger-court-website/docs/implementation/09-v2-polish-log.md`.
4. **Project gates** — whatever the project runs on top: the factory's design, usability, and perf
   gates, `web-design-review`, or the SDLC web reviewers.

Repeat 2–3 until the council returns no confirmed finding against the component.

## Step 7 — Close the loop

- Add components that passed review to the shared 21st bookmark list for vetted house motion
  (`21st lists` to find it; `21st list-new "Falcon Forged — vetted motion"` if it does not exist yet),
  so the next search starts from something already proven.
- If a component failed review in a way worth remembering, record it in the site's audit under
  "Explicitly not adopting" with the component id, so it is not re-proposed.
