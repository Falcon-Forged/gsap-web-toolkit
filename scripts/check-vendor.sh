#!/usr/bin/env bash
# check-vendor.sh — offline integrity check: the tracked vendor tree must match
# vendor.lock.json exactly.
#
# This is what makes "never hand-edit a vendored skill" a rule rather than a wish.
# Any local edit, any file added or removed, fails here — in CI on every push, and
# in the JARVIS bootstrap step before anything is wired up.
#
# Exit 0 = clean. Exit 1 = drift (the output names every offending file).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REPO_ROOT="${REPO_ROOT}" python3 <<'PYEOF'
import hashlib, json, os, pathlib, sys

root = pathlib.Path(os.environ["REPO_ROOT"])
lock_path = root / "vendor.lock.json"
vendor = root / "plugins" / "gsap-vendor"

if not lock_path.exists():
    sys.exit("vendor.lock.json is missing — run scripts/sync-vendor.sh")

lock = json.loads(lock_path.read_text())
expected = lock["files"]

actual = {}
for p in sorted((vendor / "skills").rglob("*")):
    if p.is_file():
        actual[p.relative_to(vendor).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()

problems = []
for rel, want in sorted(expected.items()):
    got = actual.get(rel)
    if got is None:
        problems.append(f"  MISSING   {rel}")
    elif got != want:
        problems.append(f"  MODIFIED  {rel}\n            expected {want}\n            found    {got}")
for rel in sorted(set(actual) - set(expected)):
    problems.append(f"  UNTRACKED {rel}")

short = lock["upstream"]["sha"][:7]
if problems:
    print(f"Vendored GSAP skills do NOT match vendor.lock.json (pinned at {short}):")
    print("\n".join(problems))
    print("\nThe vendor tree is generated. To take an upstream change, run")
    print("  scripts/sync-vendor.sh --sha <new-sha>")
    print("and commit the result. Never edit plugins/gsap-vendor/skills/ by hand —")
    print("house deltas belong in the gsap-house skill.")
    sys.exit(1)

print(f"Vendored GSAP skills match vendor.lock.json ({len(expected)} files, pinned at {short}).")
PYEOF
