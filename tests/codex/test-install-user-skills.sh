#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

# Preflight must reject an incomplete runtime layout before writing any skills.
mkdir -p "${test_root}/.codex" "${test_root}/.codex-a" "${test_root}/.codex-b"
if bash "${repo_root}/scripts/install-user-skills.sh" "${test_root}"; then
  echo 'FAIL: installation accepted a missing Claude home' >&2
  exit 1
fi
[[ ! -e "${test_root}/.codex/skills" ]]

mkdir -p "${test_root}/.claude/skills/delegating-to-codex"
printf 'stale skill\n' > "${test_root}/.claude/skills/delegating-to-codex/SKILL.md"
mkdir -p "${test_root}/.codex/skills/unrelated"
printf 'preserve me\n' > "${test_root}/.codex/skills/unrelated/SKILL.md"

# Upgrade stale content, then prove a repeated install produces identical copies.
for run in 1 2; do
  bash "${repo_root}/scripts/install-user-skills.sh" "${test_root}"
  for runtime in .codex .codex-a .codex-b .claude; do
    for skill in delegating-to-codex update-superpowers; do
      diff -qr "${repo_root}/user-skills/${skill}" "${test_root}/${runtime}/skills/${skill}"
    done
  done
  [[ "$(cat "${test_root}/.codex/skills/unrelated/SKILL.md")" == 'preserve me' ]]
  printf 'PASS: install %s updated all homes and preserved unrelated skills\n' "${run}"
done
