#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
skill_paths = sorted((repo_root / "skills").glob("*/SKILL.md"))
errors = []

if not skill_paths:
    raise AssertionError("no bundled skills found")

for path in skill_paths:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(?P<frontmatter>.*?)\n---\n(?P<body>.*)\Z", text, re.DOTALL)
    if not match:
        errors.append(f"{path}: missing YAML frontmatter")
        continue

    description_match = re.search(
        r"^description:\s*[\"']?(.*?)[\"']?\s*$",
        match.group("frontmatter"),
        re.MULTILINE,
    )
    if not description_match:
        errors.append(f"{path}: missing one-line description")
        continue

    description = description_match.group(1)
    if not description.startswith("Opt-in only:"):
        errors.append(f"{path}: description must start with 'Opt-in only:'")
    if "explicitly" not in description:
        errors.append(f"{path}: description must require an explicit user request")
    if "Never auto-invoke" not in description:
        errors.append(f"{path}: description must prohibit automatic invocation")

    body = match.group("body")
    if "<OPT-IN-BOUNDARY>" not in body or "</OPT-IN-BOUNDARY>" not in body:
        errors.append(f"{path}: missing runtime OPT-IN-BOUNDARY")
    if (
        "Ask for permission before invoking another Superpowers workflow unless "
        "the user has already explicitly authorized chaining."
    ) not in body:
        errors.append(f"{path}: missing explicit chaining-consent rule")

bootstrap = (repo_root / "skills" / "using-superpowers" / "SKILL.md").read_text(
    encoding="utf-8"
)
for forbidden in (
    "starting any conversation",
    "1% chance a skill might apply",
    "Invoke relevant or requested skills BEFORE any response or action",
):
    if forbidden in bootstrap:
        errors.append(f"using-superpowers retains automatic trigger language: {forbidden!r}")

for required in ("Suite-wide opt-in", "Single-workflow opt-in", "Chaining permission"):
    if required not in bootstrap:
        errors.append(f"using-superpowers is missing the {required!r} rule")

manifest = json.loads(
    (repo_root / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8")
)
default_prompts = manifest.get("interface", {}).get("defaultPrompt", [])
if not default_prompts:
    errors.append("Codex manifest must provide explicit Superpowers prompts")
for prompt in default_prompts:
    if not prompt.lower().startswith("use superpowers"):
        errors.append(f"Codex default prompt is not explicit opt-in: {prompt!r}")

if errors:
    raise AssertionError("\n".join(errors))

print(f"Verified explicit opt-in contract for {len(skill_paths)} Superpowers skills")
PY
