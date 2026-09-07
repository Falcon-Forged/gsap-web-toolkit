#!/usr/bin/env bash
# sync-vendor.sh — refresh plugins/gsap-vendor/skills/ from greensock/gsap-skills
# at a pinned commit, rewrite vendor.lock.json, and stamp both vendor manifests
# with a cache-busting version.
#
#   ./scripts/sync-vendor.sh                 # re-sync at the SHA already in the lock
#   ./scripts/sync-vendor.sh --sha <sha>     # bump to a new upstream commit
#
# The version stamp is not cosmetic. Claude Code and Codex both install plugins
# as CACHED COPIES keyed by the `version` in plugin.json — a content change under
# an unchanged version does not propagate to either tool. Upstream's own manifest
# is a hardcoded "1.0.0" they have never bumped, which is the whole reason we
# vendor rather than point at their repo: we own the cachebuster.
#
# The vendored tree is generated, never hand-edited. scripts/check-vendor.sh
# enforces that in CI.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="${REPO_ROOT}/vendor.lock.json"
VENDOR="${REPO_ROOT}/plugins/gsap-vendor"
UPSTREAM_REPO="greensock/gsap-skills"

SHA=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sha) SHA="${2:?--sha needs a value}"; shift 2 ;;
        -h|--help) sed -n '2,16p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [[ -z "${SHA}" ]]; then
    [[ -f "${LOCK}" ]] || { echo "No --sha given and no ${LOCK} to read." >&2; exit 1; }
    SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstream"]["sha"])' "${LOCK}")"
    echo "Re-syncing at the pinned SHA ${SHA}"
else
    echo "Syncing to ${SHA}"
fi

[[ "${SHA}" =~ ^[0-9a-f]{40}$ ]] || { echo "Not a full 40-char commit SHA: ${SHA}" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Fetching ${UPSTREAM_REPO}@${SHA}"
curl -fsSL "https://codeload.github.com/${UPSTREAM_REPO}/tar.gz/${SHA}" | tar -xz -C "${TMP}"
SRC="${TMP}/gsap-skills-${SHA}"
[[ -d "${SRC}/skills" ]] || { echo "Upstream tarball has no skills/ directory." >&2; exit 1; }

# Replace wholesale — a stale file left behind is exactly the drift we are preventing.
rm -rf "${VENDOR}/skills"
mkdir -p "${VENDOR}/skills"
cp -R "${SRC}/skills/." "${VENDOR}/skills/"
cp "${SRC}/LICENSE" "${VENDOR}/LICENSE"

SHORT="${SHA:0:7}"

REPO_ROOT="${REPO_ROOT}" VENDOR="${VENDOR}" LOCK="${LOCK}" \
SHA="${SHA}" SHORT="${SHORT}" UPSTREAM_REPO="${UPSTREAM_REPO}" python3 <<'PYEOF'
import hashlib, json, os, pathlib, subprocess

vendor = pathlib.Path(os.environ["VENDOR"])
lock_path = pathlib.Path(os.environ["LOCK"])
sha, short = os.environ["SHA"], os.environ["SHORT"]
upstream_repo = os.environ["UPSTREAM_REPO"]

# Per-file sha256 over every vendored file, sorted for a stable diff.
files = {}
for p in sorted((vendor / "skills").rglob("*")):
    if p.is_file():
        rel = p.relative_to(vendor).as_posix()
        files[rel] = hashlib.sha256(p.read_bytes()).hexdigest()

# The upstream commit date is the honest "as of", not the moment we happened to run.
try:
    date = subprocess.run(
        ["gh", "api", f"repos/{upstream_repo}/commits/{sha}", "--jq", ".commit.committer.date"],
        capture_output=True, text=True, timeout=60, check=True,
    ).stdout.strip()
except Exception:
    date = None

lock = {
    "version": 1,
    "upstream": {
        "repo": upstream_repo,
        "url": f"https://github.com/{upstream_repo}",
        "ref": "main",
        "sha": sha,
        "license": "MIT",
        "committedAt": date,
    },
    "files": files,
}
lock_path.write_text(json.dumps(lock, indent=2) + "\n")
print(f"vendor.lock.json: {len(files)} files pinned at {short}")

# Stamp both manifests. Claude uses semver build metadata (+gsap.<short>);
# Codex's documented cachebuster format replaces rather than appends
# (<base>+codex.<token>), so the two strings differ by design.
for manifest, suffix in (
    (vendor / ".claude-plugin" / "plugin.json", f"+gsap.{short}"),
    (vendor / ".codex-plugin" / "plugin.json", f"+codex.gsap-{short}"),
):
    if not manifest.exists():
        continue
    data = json.loads(manifest.read_text())
    base = data.get("version", "1.0.0").split("+", 1)[0]
    data["version"] = base + suffix
    data["description"] = (
        "Official GSAP skills from GreenSock (MIT) — core, timeline, ScrollTrigger, "
        "plugins, utils, React, frameworks, performance. Vendored byte-for-byte from "
        f"{upstream_repo} at commit {short}."
    )
    manifest.write_text(json.dumps(data, indent=2) + "\n")
    print(f"{manifest.name}: version -> {data['version']}")
PYEOF

echo
echo "Done. Review the diff, then commit:"
echo "  git diff --stat plugins/gsap-vendor"
echo "  git commit -am 'vendor: sync gsap-skills to ${SHORT}'"
echo
echo "Then propagate — both plugin channels cache by version:"
echo "  claude plugin marketplace update gsap-web-toolkit && claude plugin update gsap-vendor@gsap-web-toolkit"
echo "  codex plugin add gsap-vendor@gsap-web-toolkit   # then start a NEW Codex thread"
echo "  (OpenClaw needs nothing — extraDirs points at this tree and watch is on)"
