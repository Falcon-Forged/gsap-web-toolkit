#!/usr/bin/env bash
# check-upstream.sh — network drift check: is greensock/gsap-skills ahead of our pin?
#
# Compares COMMIT SHAs, never timestamps: a repo's `pushed_at` moves when any
# branch or tag is pushed, so upstream's pushed_at is routinely newer than the
# HEAD of main and would report drift that does not exist.
#
# Exit 0 = in sync. Exit 1 = upstream moved (a bump is a human decision).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_REPO="greensock/gsap-skills"

PINNED="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstream"]["sha"])' "${REPO_ROOT}/vendor.lock.json")"
HEAD_SHA="$(gh api "repos/${UPSTREAM_REPO}/commits/main" --jq .sha)"

if [[ "${PINNED}" == "${HEAD_SHA}" ]]; then
    echo "In sync with ${UPSTREAM_REPO}@${PINNED:0:7}."
    exit 0
fi

echo "UPSTREAM DRIFT: ${UPSTREAM_REPO}"
echo "  pinned   ${PINNED}"
echo "  upstream ${HEAD_SHA}"
echo
echo "Commits since the pin:"
gh api "repos/${UPSTREAM_REPO}/compare/${PINNED}...${HEAD_SHA}" \
    --jq '.commits[] | "  " + .sha[0:7] + "  " + (.commit.message | split("\n")[0])' || true
echo
echo "To take it:  scripts/sync-vendor.sh --sha ${HEAD_SHA}"
echo "Review the diff before committing — an upstream rewrite can contradict the"
echo "house rules in gsap-house, and that reconciliation is a human call."
exit 1
