#!/usr/bin/env python3
"""Download the 604 page word sequence for the Madinah Mushaf (Hafs).

Source: ouryhamdalaye/madinah-mushaf-json, pages/page-NNN.json.
The source provides the exact verse/word order for each page. The app lays
these words out responsively; it does not claim a pixel-identical page scan.
"""
import concurrent.futures
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data" / "mushaf_pages.json"
BASE = "https://raw.githubusercontent.com/ouryhamdalaye/madinah-mushaf-json/main/pages/page-{page:03d}.json"

def get_page(page):
    req = urllib.request.Request(BASE.format(page=page), headers={"User-Agent": "Lawh-build/1.0"})
    with urllib.request.urlopen(req, timeout=45) as response:
        data = json.loads(response.read().decode("utf-8"))
    if data.get("page") != page or not isinstance(data.get("verses"), list):
        raise ValueError(f"Invalid Mushaf page {page}")
    return data

def main():
    pages = [None] * 604
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
        futures = {pool.submit(get_page, page): page for page in range(1, 605)}
        for future in concurrent.futures.as_completed(futures):
            page = futures[future]
            pages[page - 1] = future.result()
            if page % 50 == 0:
                print(f"Downloaded {page}/604 pages")
    if any(page is None for page in pages):
        raise RuntimeError("Mushaf page data is incomplete")
    total_words = sum(len(v.get("words", [])) for p in pages for v in p["verses"])
    if total_words < 70000:
        raise RuntimeError(f"Unexpectedly low word count: {total_words}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(pages, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(pages)} pages and {total_words} words to {OUT}")

if __name__ == "__main__":
    main()
