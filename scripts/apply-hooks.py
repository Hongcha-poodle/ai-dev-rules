from __future__ import annotations

import sys
from pathlib import Path

from hooks_common import apply_hooks_settings, build_hooks_settings, read_json, write_json


quality_path = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".ai/config/quality.yaml").resolve()
settings_path = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path(".claude/settings.json").resolve()

generated = build_hooks_settings(quality_path)
existing = read_json(settings_path) if settings_path.exists() else {}
merged = apply_hooks_settings(existing, generated)
write_json(settings_path, merged)
print(f"Applied generated hooks to {settings_path}")
