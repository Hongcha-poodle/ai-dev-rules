from __future__ import annotations

import json
import sys
from pathlib import Path

from hooks_common import build_hooks_settings, write_json


quality_path = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".ai/config/quality.yaml").resolve()
output_path = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 and sys.argv[2] else None
settings = build_hooks_settings(quality_path)

if output_path:
    write_json(output_path, settings)
else:
    sys.stdout.write(json.dumps(settings, indent=2) + "\n")
