#!/usr/bin/env python3
"""
Builds assets/data/quran.json with the COMPLETE Quran (6,236 verses),
Hafs 'an 'Asim, Uthmani script with full tashkeel.

Sources are tried in order (first one that validates wins):
  1. api.alquran.cloud   (edition quran-uthmani)
  2. fawazahmed0/quran-api via jsDelivr (edition ara-quranuthmanihaf)

Juz numbers are computed locally from the standard juz boundaries, so they
do not depend on the source. The result is validated against
assets/data/surahs.json (114 surahs, per-surah verse counts, 6,236 total).

Usage:
  python3 scripts/build_quran_data.py              # download + build
  python3 scripts/build_quran_data.py --input f.json --format alquran
"""
import argparse
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data" / "quran.json"
SURAHS = ROOT / "assets" / "data" / "surahs.json"

SOURCES = [
    ("alquran", "https://api.alquran.cloud/v1/quran/quran-uthmani"),
    ("fawaz", "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranuthmanihaf.json"),
]

# First (surah, ayah) of each juz 1..30
JUZ_STARTS = [
    (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111),
    (7, 88), (8, 41), (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75),
    (21, 1), (23, 1), (25, 21), (27, 56), (29, 46), (33, 31), (36, 28),
    (39, 32), (41, 47), (46, 1), (51, 31), (58, 1), (67, 1), (78, 1),
]

EXCEPTIONS = {
    "الرحمن", "رحمن", "ذلك", "ذلكم", "ذلكما", "هذا", "هذه", "هذان", "هؤلاء",
    "اله", "الاه", "لكن", "لكنه", "اولئك", "طه", "يس",
}


def juz_of(surah, ayah):
    juz = 1
    for i, start in enumerate(JUZ_STARTS):
        if (surah, ayah) >= start:
            juz = i + 1
    return juz


def normalize(text):
    """Same rules as lib/services/text_normalizer.dart (informational copy)."""
    text = re.sub(r"[ۖ-ۭ۞۟؀-؅۝]", "", text)
    text = re.sub(r"وٰ", "ا", text)
    text = re.sub(r"[آأإٱٲٳ]", "ا", text)
    text = text.replace("ة", "ه")
    text = re.sub(r"[ىی]", "ي", text)
    text = text.replace("ـ", "")
    text = re.sub(r"[ً-ٟ]", "", text)
    words = []
    for w in text.split():
        stripped = w.replace("ٰ", "")
        words.append(stripped if stripped in EXCEPTIONS else w.replace("ٰ", "ا"))
    text = " ".join(words)
    text = re.sub(r"[ً-ٰٟ]", "", text)
    return re.sub(r"\s+", " ", text).strip()


def fetch(url, retries=3):
    last = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "lawh-build/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            last = exc
            print(f"  attempt {attempt} failed: {exc}", file=sys.stderr)
            time.sleep(2 * attempt)
    raise RuntimeError(f"could not download {url}: {last}")


def parse(kind, data):
    """Returns a list of (surah, ayah, text)."""
    rows = []
    if kind == "alquran":
        for s in data["data"]["surahs"]:
            for a in s["ayahs"]:
                rows.append((int(s["number"]), int(a["numberInSurah"]), a["text"]))
    elif kind == "fawaz":
        for v in data["quran"]:
            rows.append((int(v["chapter"]), int(v["verse"]), v["text"]))
    else:
        raise ValueError(kind)
    return rows


def strip_bismillah(surah, ayah, text):
    """Some sources prepend the basmala to verse 1 of every surah."""
    text = text.replace("﻿", "").strip()
    if ayah == 1 and surah not in (1, 9):
        words = text.split()
        head = [normalize(w) for w in words[:4]]
        if head == ["بسم", "الله", "الرحمن", "الرحيم"] and len(words) > 4:
            text = " ".join(words[4:])
    return re.sub(r"\s+", " ", text).strip()


def build(rows, validate=True):
    rows = sorted(rows, key=lambda r: (r[0], r[1]))
    out = []
    for surah, ayah, text in rows:
        text = strip_bismillah(surah, ayah, text)
        out.append({
            "surah": surah,
            "ayah": ayah,
            "text": text,
            "normalized": normalize(text),
            "juz": juz_of(surah, ayah),
        })
    if validate:
        surahs = json.loads(SURAHS.read_text(encoding="utf-8"))
        expected = {s["id"]: s["ayahsCount"] for s in surahs}
        counts = {}
        for v in out:
            counts[v["surah"]] = counts.get(v["surah"], 0) + 1
        problems = []
        if len(out) != 6236:
            problems.append(f"total verses {len(out)} != 6236")
        for sid, n in expected.items():
            if counts.get(sid) != n:
                problems.append(f"surah {sid}: {counts.get(sid)} != {n}")
        for v in out:
            if not v["text"] or not v["normalized"]:
                problems.append(f"empty text at {v['surah']}:{v['ayah']}")
                break
        # surahs.json startJuz must agree with our juz table
        for s in surahs:
            if juz_of(s["id"], 1) != s["startJuz"] and s["id"] not in {x[0] for x in JUZ_STARTS}:
                problems.append(f"startJuz mismatch for surah {s['id']}")
        if problems:
            raise RuntimeError("validation failed: " + "; ".join(problems[:8]))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", help="local JSON file instead of downloading")
    ap.add_argument("--format", choices=["alquran", "fawaz"], default="alquran")
    ap.add_argument("--no-validate", action="store_true", help="for tests only")
    args = ap.parse_args()

    if args.input:
        data = json.loads(Path(args.input).read_text(encoding="utf-8"))
        result = build(parse(args.format, data), validate=not args.no_validate)
    else:
        result = None
        errors = []
        for kind, url in SOURCES:
            print(f"Trying {kind}: {url}")
            try:
                result = build(parse(kind, fetch(url)))
                print(f"  OK ({kind})")
                break
            except Exception as exc:  # noqa: BLE001
                errors.append(f"{kind}: {exc}")
                print(f"  failed: {exc}", file=sys.stderr)
        if result is None:
            sys.exit("All sources failed:\n  " + "\n  ".join(errors))

    OUT.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(result)} verses to {OUT}")


if __name__ == "__main__":
    main()
