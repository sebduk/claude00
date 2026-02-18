#!/usr/bin/env python3
"""
ICANN 2012 New gTLD Application Downloader & Parser.

Discovers all application IDs from the ICANN status page, downloads each
public-portion application (served as HTML), parses the fields directly
from the HTML, and writes everything to a CSV table.

Requirements:
    pip install requests beautifulsoup4

Usage:
    # Full run — discover IDs, download, parse, write CSV:
    python3 icann_gtld.py

    # Download only (no parsing):
    python3 icann_gtld.py --download-only

    # Parse already-downloaded files (no new downloads):
    python3 icann_gtld.py --parse-only

    # Process a subset of application IDs:
    python3 icann_gtld.py --ids 1001 1002 1003

    # Custom output locations:
    python3 icann_gtld.py -o ./applications --csv icann_table.csv

Output:
    downloads/          HTML files named {app_id}.html
    results.csv         Extracted field table (UTF-8)
"""

import argparse
import csv
import re
import sys
import time
from pathlib import Path
from typing import Optional

import requests

try:
    from bs4 import BeautifulSoup, Tag
    BS4_OK = True
except ImportError:
    BS4_OK = False

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE_URL = "https://gtldresult.icann.org"
LIST_URL = f"{BASE_URL}/applicationstatus/viewstatus"
DOWNLOAD_URL = (
    f"{BASE_URL}/applicationstatus/applicationdetails:downloadapplication"
    "/{{id}}?t:ac={{id}}"
)

BROWSER_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Referer": BASE_URL,
}

# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------


def make_session() -> requests.Session:
    """Session with browser-like headers and warmed-up cookies."""
    s = requests.Session()
    s.headers.update(BROWSER_HEADERS)
    try:
        s.get(BASE_URL, timeout=20)
        time.sleep(0.3)
    except requests.RequestException:
        pass
    return s


def _get(
    session: requests.Session,
    url: str,
    *,
    timeout: int = 60,
    max_attempts: int = 4,
) -> Optional[requests.Response]:
    """GET with exponential-backoff retry on network errors."""
    delay = 2
    for attempt in range(1, max_attempts + 1):
        try:
            resp = session.get(url, timeout=timeout)
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            return resp
        except requests.HTTPError as exc:
            print(f"  [HTTP {exc.response.status_code}] {url}")
            return None
        except requests.RequestException as exc:
            if attempt < max_attempts:
                print(f"  [retry {attempt}/{max_attempts - 1}] {exc} — waiting {delay}s")
                time.sleep(delay)
                delay *= 2
            else:
                print(f"  [failed] {exc}")
                return None
    return None


# ---------------------------------------------------------------------------
# Discover application IDs
# ---------------------------------------------------------------------------


_FALLBACK_RANGE = (1, 2000)  # covers all 1930 applications in the 2012 round


def discover_ids(session: requests.Session) -> list[int]:
    """
    Scrape the viewstatus page and return all application IDs found in links.
    Returns an empty list if the page is JS-rendered or unreachable.
    """
    print(f"Fetching application list: {LIST_URL}")
    resp = _get(session, LIST_URL)
    if resp is None:
        print("  [warn] Could not fetch the application list page.")
        return []

    ids: set[int] = set()
    if BS4_OK:
        soup = BeautifulSoup(resp.text, "html.parser")
        for tag in soup.find_all("a", href=True):
            m = re.search(r"/applicationdetails/(\d+)", tag["href"])
            if m:
                ids.add(int(m.group(1)))

    # Regex fallback (also works without bs4)
    if not ids:
        for m in re.finditer(r"/applicationdetails/(\d+)", resp.text):
            ids.add(int(m.group(1)))

    result = sorted(ids)
    print(f"Found {len(result)} application IDs.\n")
    return result


# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------


def download_application(
    session: requests.Session,
    app_id: int,
    output_dir: Path,
    overwrite: bool = False,
) -> Optional[Path]:
    """
    Download the public-portion application HTML for app_id.
    Saves to output_dir/{app_id}.html.  Returns local path or None.
    """
    dest = output_dir / f"{app_id}.html"
    if dest.exists() and not overwrite:
        print(f"  [skip] {dest.name} already exists")
        return dest

    url = DOWNLOAD_URL.format(id=app_id)
    resp = _get(session, url)
    if resp is None:
        return None

    output_dir.mkdir(parents=True, exist_ok=True)
    try:
        dest.write_text(resp.text, encoding="utf-8")
    except OSError as exc:
        print(f"  [write error] {exc}")
        dest.unlink(missing_ok=True)
        return None

    print(f"  [done] {dest.name}  ({len(resp.content):,} bytes)")
    return dest


# ---------------------------------------------------------------------------
# HTML parsing
# ---------------------------------------------------------------------------

# Question numbers we care about — matched against the start of a question div.
# Keys map to CSV field names.
_QUESTION_MATCHERS: list[tuple[str, re.Pattern]] = [
    ("q14a",  re.compile(r"^\s*14\s*[Aa][\.\)]", re.I)),
    ("q16",   re.compile(r"^\s*16[\.\)]",         re.I)),
    ("q18a",  re.compile(r"^\s*18\s*[Aa][\.\)]", re.I)),
    ("q18b",  re.compile(r"^\s*18\s*[Bb][\.\)]", re.I)),
    ("q18c",  re.compile(r"^\s*18\s*[Cc][\.\)]", re.I)),
]

# Simple "Key: Value" fields in question divs
_SIMPLE_MATCHERS: list[tuple[str, re.Pattern]] = [
    ("string",         re.compile(r"^\s*String\s*:", re.I)),
    ("application_id", re.compile(r"^\s*Application\s+ID\s*:", re.I)),
]


def _inner_text(element) -> str:
    """Return stripped text content of an element, collapsing whitespace."""
    text = element.get_text(separator="\n")
    text = re.sub(r" {2,}", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _value_after_colon(text: str) -> str:
    """Given 'Key: value text', return 'value text'."""
    _, _, after = text.partition(":")
    return after.strip()


def _collect_answer(question_div: Tag) -> str:
    """
    Gather answer text that follows a question div.
    Tries multiple HTML patterns used by ICANN:

    Pattern A — answer is inside the same div after the question label:
        <div class="question">16. Describe... <p>Answer paragraph 1</p> <p>...</p></div>

    Pattern B — answer is in immediately following sibling elements
    until the next question div:
        <div class="question">16. Describe...</div>
        <p>Answer paragraph 1</p>
        ...
        <div class="question">17. Next question...</div>

    Pattern C — answer div follows the question div:
        <div class="question">16. Describe...</div>
        <div class="answer">...</div>
    """
    parts: list[str] = []

    # Pattern A: child paragraphs / text nodes inside the question div itself
    children = [c for c in question_div.children if isinstance(c, Tag)]
    # Skip any element that contains the question label (usually the first child)
    skip_first = bool(children and re.search(r"^\s*\d{1,2}", children[0].get_text()))
    for i, child in enumerate(children):
        if i == 0 and skip_first:
            continue
        parts.append(_inner_text(child))

    if parts:
        return "\n\n".join(p for p in parts if p)

    # Pattern B/C: collect following siblings until the next question div
    for sibling in question_div.find_next_siblings():
        if not isinstance(sibling, Tag):
            continue
        sib_class = " ".join(sibling.get("class", []))
        sib_text = sibling.get_text(strip=True)

        # Stop at the next question
        if "question" in sib_class and re.search(r"^\s*\d{1,2}", sib_text):
            break

        t = _inner_text(sibling)
        if t:
            parts.append(t)

    return "\n\n".join(parts)


def parse_application_html(app_id: int, html_path: Path) -> dict:
    """
    Parse an ICANN application HTML file and return a flat dict for CSV output.
    """
    row: dict[str, str] = {
        "app_id": str(app_id),
        "string": "",
        "application_id": "",
        "q14a": "",
        "q16": "",
        "q18a": "",
        "q18b": "",
        "q18c": "",
    }

    try:
        html = html_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"  [read error] {html_path.name}: {exc}")
        return row

    if BS4_OK:
        soup = BeautifulSoup(html, "html.parser")
        question_divs = soup.find_all("div", class_="question")

        for div in question_divs:
            text = div.get_text(separator=" ", strip=True)

            # Simple key: value fields
            for field, pat in _SIMPLE_MATCHERS:
                if not row[field] and pat.match(text):
                    row[field] = _value_after_colon(text)
                    break

            # Numbered question fields
            for field, pat in _QUESTION_MATCHERS:
                if not row[field] and pat.match(text):
                    row[field] = _collect_answer(div)
                    break
    else:
        # Regex-only fallback (no bs4)
        # Simple fields
        for field, label in [("string", "String"), ("application_id", "Application ID")]:
            m = re.search(
                rf'class="question"[^>]*>\s*{label}\s*:\s*([^<]+)',
                html, re.I,
            )
            if m:
                row[field] = m.group(1).strip()

        # Numbered sections — capture everything between question divs
        for field, label_pat in [
            ("q14a",  r"14\s*[Aa][\.\)]"),
            ("q16",   r"16[\.\)]"),
            ("q18a",  r"18\s*[Aa][\.\)]"),
            ("q18b",  r"18\s*[Bb][\.\)]"),
            ("q18c",  r"18\s*[Cc][\.\)]"),
        ]:
            m = re.search(
                rf'class="question"[^>]*>\s*{label_pat}[^<]*</div>(.*?)'
                r'(?=<div[^>]*class="question"[^>]*>\s*\d|\Z)',
                html, re.DOTALL | re.I,
            )
            if m:
                # Strip HTML tags from the captured block
                raw = re.sub(r"<[^>]+>", " ", m.group(1))
                raw = re.sub(r"\s{2,}", " ", raw).strip()
                row[field] = raw

    # Tidy up all field values
    for key in row:
        if key != "app_id":
            row[key] = re.sub(r"\n{3,}", "\n\n", row[key].strip())

    return row


# ---------------------------------------------------------------------------
# CSV output
# ---------------------------------------------------------------------------

CSV_FIELDNAMES = [
    "app_id",
    "string",
    "application_id",
    "q14a",
    "q16",
    "q18a",
    "q18b",
    "q18c",
]

CSV_HEADERS = {
    "app_id": "App ID (numeric)",
    "string": "String",
    "application_id": "Application ID",
    "q14a": (
        "14A. If applying for an IDN, provide the A-label (beginning with \"xn--\")."
    ),
    "q16": (
        "16. Describe the applicant's efforts to ensure that there are no known "
        "operational or rendering problems concerning the applied-for gTLD string. "
        "If such issues are known, describe steps that will be taken to mitigate "
        "these issues in software and other applications."
    ),
    "q18a": "18A. Describe the mission/purpose of your proposed gTLD.",
    "q18b": (
        "18B. How do you expect that your proposed gTLD will benefit registrants, "
        "Internet users, and others?"
    ),
    "q18c": (
        "18C. What operating rules will you adopt to eliminate or minimize social "
        "costs (e.g., time or financial resource costs, as well as various types of "
        "consumer vulnerabilities)? What other steps will you take to minimize "
        "negative consequences/costs imposed upon consumers?"
    ),
}


def write_csv(rows: list[dict], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_FIELDNAMES, extrasaction="ignore")
        writer.writerow(CSV_HEADERS)
        writer.writerows(rows)
    print(f"\nTable written → {output_path}  ({len(rows)} rows)")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    if not BS4_OK:
        print(
            "WARNING: beautifulsoup4 not found — falling back to regex parsing.\n"
            "         Install for better results:  pip install beautifulsoup4\n"
        )

    parser = argparse.ArgumentParser(
        description="Download and parse ICANN 2012 gTLD application HTML files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--download-only",
        action="store_true",
        help="Download HTML files without parsing or writing CSV",
    )
    parser.add_argument(
        "--parse-only",
        action="store_true",
        help="Parse already-downloaded HTML files; skip new downloads",
    )
    parser.add_argument(
        "--ids",
        nargs="+",
        type=int,
        metavar="ID",
        help="Process only these numeric application IDs",
    )
    parser.add_argument(
        "--id-range",
        nargs=2,
        type=int,
        metavar=("START", "END"),
        help=(
            "Try all IDs from START to END inclusive "
            "(404s are silently skipped). "
            "Used automatically when the list page cannot be scraped."
        ),
    )
    parser.add_argument(
        "-o", "--output",
        metavar="DIR",
        default="downloads",
        help="Directory to store HTML files (default: ./downloads)",
    )
    parser.add_argument(
        "--csv",
        metavar="FILE",
        default="results.csv",
        help="Output CSV file path (default: results.csv)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Re-download files that already exist locally",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.5,
        metavar="SECS",
        help="Pause between requests in seconds (default: 0.5)",
    )
    args = parser.parse_args()

    output_dir = Path(args.output)
    csv_path = Path(args.csv)

    session = make_session()

    # ── 1. Determine IDs ────────────────────────────────────────────────────
    if args.ids:
        ids = sorted(set(args.ids))
        print(f"Processing {len(ids)} specified IDs.")
    elif args.parse_only:
        ids = sorted(
            int(p.stem) for p in output_dir.glob("*.html") if p.stem.isdigit()
        )
        print(f"Found {len(ids)} HTML files in {output_dir}/")
    elif args.id_range:
        start, end = args.id_range
        ids = list(range(start, end + 1))
        print(f"Using ID range {start}–{end} ({len(ids)} candidates; 404s will be skipped).\n")
    else:
        ids = discover_ids(session)
        if not ids:
            start, end = _FALLBACK_RANGE
            ids = list(range(start, end + 1))
            print(
                f"  [info] List page appears to be JavaScript-rendered — no links found.\n"
                f"  [info] Falling back to ID range {start}–{end}.\n"
                f"  [info] You can also pass --id-range START END explicitly.\n"
            )

    if not ids:
        print("No application IDs found. Exiting.")
        sys.exit(1)

    # ── 2. Download ──────────────────────────────────────────────────────────
    local_files: dict[int, Path] = {}

    if not args.parse_only:
        print(f"Downloading {len(ids)} applications → {output_dir}/\n")
        for i, app_id in enumerate(ids, 1):
            print(f"[{i:4d}/{len(ids)}] ID {app_id}")
            path = download_application(session, app_id, output_dir, args.overwrite)
            if path:
                local_files[app_id] = path
            if args.delay and i < len(ids):
                time.sleep(args.delay)
    else:
        for app_id in ids:
            p = output_dir / f"{app_id}.html"
            if p.exists():
                local_files[app_id] = p
            else:
                print(f"  [missing] {p} — skipping")

    if args.download_only:
        print(f"\nDownload-only mode complete.  {len(local_files)} files saved.")
        return

    # ── 3. Parse ─────────────────────────────────────────────────────────────
    if not local_files:
        print("No files to parse.")
        return

    print(f"\nParsing {len(local_files)} applications …\n")
    rows: list[dict] = []

    for i, (app_id, html_path) in enumerate(sorted(local_files.items()), 1):
        print(f"[{i:4d}/{len(local_files)}] {html_path.name}", end="")
        row = parse_application_html(app_id, html_path)
        rows.append(row)
        found = sum(1 for k in ("string", "application_id", "q16", "q18a", "q18b") if row.get(k))
        print(f"  ({found}/5 key fields found)")

    # ── 4. Write CSV ──────────────────────────────────────────────────────────
    write_csv(rows, csv_path)


if __name__ == "__main__":
    main()
