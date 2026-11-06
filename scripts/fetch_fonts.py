#!/usr/bin/env python3
"""Downloads the real Amiri Quran font (SIL OFL) over the placeholder file."""
import sys
import urllib.request
from pathlib import Path

URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/AmiriQuran-Regular.ttf"
DEST = Path(__file__).resolve().parent.parent / "assets" / "fonts" / "AmiriQuran-Regular.ttf"
MAGIC = (b"\x00\x01\x00\x00", b"true", b"OTTO")

try:
    req = urllib.request.Request(URL, headers={"User-Agent": "lawh-build/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    if len(data) < 50_000 or data[:4] not in MAGIC:
        raise ValueError("downloaded file is not a valid font")
    DEST.write_bytes(data)
    print(f"Amiri Quran installed ({len(data)} bytes)")
except Exception as exc:  # noqa: BLE001
    print(f"::warning::Could not download Amiri Quran ({exc}). "
          "Using the Noto Naskh placeholder; Quran text will still render.")
    sys.exit(0)
