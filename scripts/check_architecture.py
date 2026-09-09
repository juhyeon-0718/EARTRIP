"""Small dependency guard, run locally or in CI. No third-party dependencies."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
failures = []

for path in (root / "EARTrip" / "Models").glob("*.swift"):
    if re.search(r"^import (SwiftUI|UIKit|CoreLocation|MapKit|AVFoundation|Observation)\b", path.read_text(encoding="utf-8"), re.M):
        failures.append(f"{path.name}: domain models must not import platform/UI frameworks")

for path in (root / "EARTrip" / "Features").rglob("*.swift"):
    source = path.read_text(encoding="utf-8")
    if re.search(r"@Environment\(AudioService\.self\)", source):
        failures.append(f"{path.name}: playback commands must go through TripEngine")
    for line in source.splitlines():
        if "MockCatalog." in line and not line.lstrip().startswith("#Preview"):
            failures.append(f"{path.name}: fixtures belong to the composition root or previews")
    if "history.add(" in source or "history.recordCompletion(" in source:
        failures.append(f"{path.name}: a view must not save trip completion")

if failures:
    raise SystemExit("\n".join(failures))
print("Architecture boundaries: PASS")
