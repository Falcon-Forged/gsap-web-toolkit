# Attribution

`plugins/gsap-vendor/skills/` is a byte-for-byte copy of the `skills/` directory of:

- **Project:** GSAP Skills
- **Author:** GreenSock (Webflow, Inc.)
- **Upstream:** https://github.com/greensock/gsap-skills
- **License:** MIT — full text in `LICENSE`, copied verbatim from upstream
- **Pinned commit:** recorded in `vendor.lock.json` (`upstream.sha`), with a sha256 for every file

No modifications are made. `scripts/check-vendor.sh` fails if any file diverges from the lock, so a
local edit cannot silently become a fork.

Where the house conventions disagree with these skills, the disagreement is stated in
`plugins/gsap-toolkit/skills/gsap-house/SKILL.md` (§4 and §11) rather than by patching the vendored
text. That keeps the upstream diff clean and keeps our reasoning visible.

GSAP itself is separately licensed by GreenSock under its standard no-charge license:
https://gsap.com/standard-license
