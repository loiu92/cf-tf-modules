#!/usr/bin/env python3
"""Shared modules declare provider requirements; credentials stay in app roots."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
failures = []
for module in sorted((root / "modules").iterdir()):
    if not module.is_dir():
        continue
    for filename in ("main.tf", "variables.tf", "outputs.tf", "versions.tf"):
        file = module / filename
        if not file.exists():
            failures.append(f"{file.relative_to(root)}: missing contract file")
    for file in sorted(module.glob("*.tf")):
        content = file.read_text()
        # Ignore full-line comments so the policy is about executable HCL.
        content = re.sub(r"(?m)^\s*#.*$", "", content)
        if re.search(r'(?m)^\s*provider\s+"', content):
            failures.append(f"{file.relative_to(root)}: provider configuration belongs in the consuming root")
        if re.search(r'(?m)^\s*(api_token|api_key|email)\s*=\s*"[^"$]', content):
            failures.append(f"{file.relative_to(root)}: do not embed provider credentials")
        if re.search(r'\bsource\s*=\s*"(?:git::|github::)[^"]*(?:\?ref=main|\?ref=master)"', content):
            failures.append(f"{file.relative_to(root)}: remote module sources must pin a release")
if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
print("Shared-module architecture checks passed")
