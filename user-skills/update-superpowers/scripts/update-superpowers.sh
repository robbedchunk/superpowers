#!/usr/bin/env bash
set -euo pipefail

readonly marketplace="superpowers-dev"
readonly plugin="superpowers@${marketplace}"
readonly expected_source="https://github.com/robbedchunk/superpowers.git"
readonly homes=("${HOME}/.codex" "${HOME}/.codex-a")

for codex_home in "${homes[@]}"; do
  if [[ ! -d "${codex_home}" ]]; then
    printf 'Codex home does not exist: %s\n' "${codex_home}" >&2
    exit 1
  fi

  marketplace_json="$(CODEX_HOME="${codex_home}" codex plugin marketplace list --json)"
  MARKETPLACE_JSON="${marketplace_json}" EXPECTED_SOURCE="${expected_source}" \
    python3 - <<'PY'
import json
import os
import sys

data = json.loads(os.environ["MARKETPLACE_JSON"])
expected = os.environ["EXPECTED_SOURCE"]
for marketplace in data.get("marketplaces", []):
    if marketplace.get("name") != "superpowers-dev":
        continue
    source = marketplace.get("marketplaceSource", {}).get("source")
    if source == expected:
        break
    raise SystemExit(f"superpowers-dev points to {source!r}, expected {expected!r}")
else:
    raise SystemExit("superpowers-dev marketplace is not configured")
PY

  printf '\nUpdating Superpowers in %s\n' "${codex_home}"
  CODEX_HOME="${codex_home}" codex plugin marketplace upgrade "${marketplace}" --json
  CODEX_HOME="${codex_home}" codex plugin remove "${plugin}" --json
  CODEX_HOME="${codex_home}" codex plugin add "${plugin}" --json
done

claude_registry="${HOME}/.claude/plugins/known_marketplaces.json"
CLAUDE_REGISTRY="${claude_registry}" EXPECTED_SOURCE="${expected_source}" \
  python3 - <<'PY'
import json
import os

path = os.environ["CLAUDE_REGISTRY"]
expected = os.environ["EXPECTED_SOURCE"]
try:
    with open(path) as f:
        data = json.load(f)
except FileNotFoundError:
    raise SystemExit(f"Claude Code marketplace registry not found: {path}")
entry = data.get("superpowers-dev")
if entry is None:
    raise SystemExit("superpowers-dev marketplace is not configured in Claude Code")
url = entry.get("source", {}).get("url")
if url != expected:
    raise SystemExit(f"superpowers-dev points to {url!r}, expected {expected!r}")
PY

printf '\nUpdating Superpowers in %s\n' "${HOME}/.claude"
claude plugin marketplace update "${marketplace}"
# Remove-then-install (not `plugin update`) so changes land even when the
# manifest version was not bumped, matching the Codex legs above.
claude plugin uninstall "${plugin}"
claude plugin install "${plugin}" --scope user

printf '\nUpdating standalone skills in both Codex homes and Claude Code\n'
bash "${HOME}/.claude/plugins/marketplaces/${marketplace}/scripts/install-user-skills.sh"

printf '\nSuperpowers updated from %s in both Codex homes and Claude Code.\n' "${expected_source}"
