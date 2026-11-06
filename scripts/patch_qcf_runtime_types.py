#!/usr/bin/env python3
"""Apply a small runtime type-inference compatibility fix to qcf_quran_plus 0.1.1.

The package reads ayah text through dynamically typed model fields. Without an
explicit String type, split()/where() can receive a (dynamic) => dynamic
predicate, which fails at runtime when Iterable.where expects String => bool.
"""
from pathlib import Path
import sys

cache = Path.home() / ".pub-cache" / "hosted" / "pub.dev"
packages = sorted(cache.glob("qcf_quran_plus-*/lib/src/widgets/quran_page"))
if not packages:
    print("qcf_quran_plus source was not found in the pub cache", file=sys.stderr)
    sys.exit(1)

patched = 0
for package_dir in packages:
    targets = [
        package_dir / "quran_repository.dart",
        package_dir / "parsed_quran_data.dart",
    ]
    for path in targets:
        if not path.exists():
            continue
        source = path.read_text(encoding="utf-8")
        updated = source.replace(
            "final ayaText = ayah.ayah.replaceAll('\\n', ' ').trim();",
            "final String ayaText = ayah.ayah.replaceAll('\\n', ' ').trim();",
        )
        updated = updated.replace(
            ".where((w) => w.isNotEmpty && !digitsRegex.hasMatch(w))",
            ".where((String w) => w.isNotEmpty && !digitsRegex.hasMatch(w))",
        )
        updated = updated.replace(
            "final logicalWords = ayaText.split(_wordSplitRegex).where((w) {",
            "final List<String> logicalWords = ayaText.split(_wordSplitRegex).where((String w) {",
        )
        if updated != source:
            path.write_text(updated, encoding="utf-8")
            patched += 1

if patched != 2:
    print(f"Expected to patch 2 qcf source files, patched {patched}", file=sys.stderr)
    sys.exit(1)

print("Patched qcf_quran_plus dynamic where() predicates in 2 source files.")
