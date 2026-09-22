#!/usr/bin/env bash
# Install the fork's standalone skills without changing plugin opt-in rules.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_root="${1:-${HOME}}"

for runtime in .codex .codex-a .codex-b .claude; do
  if [[ ! -d "${target_root}/${runtime}" ]]; then
    printf 'Runtime home does not exist: %s\n' "${target_root}/${runtime}" >&2
    exit 1
  fi
done

for runtime in .codex .codex-a .codex-b .claude; do
  for skill in delegating-to-codex update-superpowers; do
    destination="${target_root}/${runtime}/skills/${skill}"
    mkdir -p "${destination}"
    cp -R "${repo_root}/user-skills/${skill}/." "${destination}/"
    diff -qr "${repo_root}/user-skills/${skill}" "${destination}"
    printf 'Installed %s in %s\n' "${skill}" "${target_root}/${runtime}"
  done
done
