#!/usr/bin/env python3
"""
ICANN 2012 New gTLD Application Downloader & Parser.

HTML files are named  {Application-ID}_{STRING}.html  (e.g.
1-1062-36956_PRESS.html).  The parser splits on <h3> labels and
extracts answers from the following <div><pre>…</pre></div>.

Requirements:
    pip install requests

Usage:
    # Parse already-downloaded files in ./downloads, write results.csv:
    python3 icann_gtld.py --parse-only

    # Full run — auto-discover IDs, download, parse, write CSV:
    python3 icann_gtld.py

    # Specify an ID range if auto-discovery fails (JS-rendered list page):
    python3 icann_gtld.py --id-range 1 1930

    # Download only (no parsing):
    python3 icann_gtld.py --download-only

    # Process a subset of numeric row IDs:
    python3 icann_gtld.py --ids 1001 1002 1003

    # Custom locations:
    python3 icann_gtld.py -o ./applications --csv icann_table.csv

Output:
    downloads/   HTML files named {Application-ID}_{STRING}.html
    results.csv  Extracted field table (UTF-8, one row per application)
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
    from bs4 import BeautifulSoup  # noqa: F401 — imported only for install check
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

_FALLBACK_RANGE = (1, 2000)  # covers all ~1930 applications in the 2012 round

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
    """GET with exponential-backoff retry on transient network errors."""
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
# Discover numeric row IDs
# ---------------------------------------------------------------------------


def discover_ids(session: requests.Session) -> list[int]:
    """
    Scrape the viewstatus page and return all numeric row IDs found in links.
    Returns an empty list if the page is JS-rendered or unreachable.
    """
    print(f"Fetching application list: {LIST_URL}")
    resp = _get(session, LIST_URL)
    if resp is None:
        print("  [warn] Could not fetch the application list page.")
        return []

    ids: set[int] = set()
    for m in re.finditer(r"/applicationdetails/(\d+)", resp.text):
        ids.add(int(m.group(1)))

    result = sorted(ids)
    print(f"Found {len(result)} application IDs.\n")
    return result


# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------


def _derive_filename(html: str, numeric_id: int) -> str:
    """Build the canonical filename from the HTML content."""
    app_id = str(numeric_id)
    string_label = ""

    m = re.search(r'Application\s+ID\s*:\s*([\w-]+)', html, re.I)
    if m:
        app_id = m.group(1).strip()

    m = re.search(r'<h3[^>]*>\s*String\s*:\s*([^<\r\n]+)', html, re.I)
    if m:
        string_label = re.sub(r'[^\w]', '_', m.group(1).strip().upper()).strip('_')

    return f"{app_id}_{string_label}.html" if string_label else f"{app_id}.html"


def download_application(
    session: requests.Session,
    app_id: int,
    output_dir: Path,
    overwrite: bool = False,
) -> Optional[Path]:
    """
    Download the public-portion application HTML for the given numeric row ID.
    Saves as {Application-ID}_{STRING}.html.  Returns local path or None.
    """
    url = DOWNLOAD_URL.format(id=app_id)
    resp = _get(session, url)
    if resp is None:
        return None

    filename = _derive_filename(resp.text, app_id)
    dest = output_dir / filename

    if dest.exists() and not overwrite:
        print(f"  [skip] {dest.name} already exists")
        return dest

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


def _strip_tags(html: str) -> str:
    """Remove HTML tags, converting <br> to newline first."""
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.I)
    return re.sub(r'<[^>]+>', '', html)


def _unescape(text: str) -> str:
    text = text.replace('&amp;', '&')
    text = text.replace('&lt;', '<')
    text = text.replace('&gt;', '>')
    text = text.replace('&quot;', '"')
    text = text.replace('&#39;', "'")
    text = text.replace('\u2044', '/')   # fraction slash → solidus
    text = text.replace('&nbsp;', ' ')
    return text


def _extract_pre(html_fragment: str) -> str:
    """Extract and clean the text inside the first <pre>…</pre> block."""
    m = re.search(r'<pre[^>]*>(.*?)</pre>', html_fragment, re.DOTALL | re.I)
    if not m:
        return ''
    inner = _unescape(_strip_tags(m.group(1)))
    inner = re.sub(r'[ \t]+', ' ', inner)
    inner = re.sub(r'\n{3,}', '\n\n', inner)
    return inner.strip()


def _value_after_colon(label: str) -> str:
    _, _, after = label.partition(':')
    return after.strip()


def parse_application_html(html_path: Path) -> dict:
    """
    Parse one ICANN application HTML file.

    HTML structure (actual format served by ICANN):
        <h3>String: press</h3>
        <h3>Application ID: 1-1062-36956</h3>
        …
        <font color="DimGray"><h3>16. Describe …</h3></font>
        <div><pre>answer text</pre></div>

    Strategy: split the document on every <h3> tag to get
    (label, following_content) pairs, then extract the <pre> answer
    from each following block.
    """
    row: dict[str, str] = {
        "file":           html_path.name,
        "application_id": "",
        "applicant_name": "",
        "string":         "",
        "date_posted":    "",
        "q13":            "",
        "q16":            "",
        "q18a":           "",
        "q18b":           "",
        "q18c":           "",
        "q19":            "",
    }

    # Fall-back: derive application_id from filename (e.g. 1-1062-36956_PRESS.html)
    m = re.match(r'^(\d+-\d+-\d+)', html_path.stem)
    if m:
        row['application_id'] = m.group(1)

    try:
        html = html_path.read_text(encoding='utf-8', errors='replace')
    except OSError as exc:
        print(f"  [read error] {html_path.name}: {exc}")
        return row

    # Applicant name from <h2>…Submitted to ICANN by: NAME</h2>
    m = re.search(r'<h2[^>]*>[^<]*by:\s*(.*?)</h2>', html, re.DOTALL | re.I)
    if m:
        row['applicant_name'] = re.sub(r'\s+', ' ', _strip_tags(m.group(1))).strip()

    # Split on <h3> tags; re.split with a capture group gives:
    #   [before_0,  label_0, after_0,  label_1, after_1, …]
    parts = re.split(r'<h3[^>]*>(.*?)</h3>', html, flags=re.DOTALL | re.I)

    i = 1
    while i < len(parts) - 1:
        label_raw = parts[i]
        following = parts[i + 1]
        i += 2

        label  = re.sub(r'\s+', ' ', _strip_tags(label_raw)).strip()
        answer = _extract_pre(following)

        if   re.match(r'String\s*:',              label, re.I):
            row['string']         = _value_after_colon(label)
        elif re.match(r'Application\s+ID\s*:',    label, re.I):
            row['application_id'] = _value_after_colon(label)
        elif re.match(r'Originally\s+Posted\s*:', label, re.I):
            row['date_posted']    = _value_after_colon(label)
        elif re.match(r'13[\.\(]',                label):
            row['q13']            = answer
        elif re.match(r'16[\.\(]',                label):
            row['q16']            = answer
        elif re.match(r'18\s*\([aA]\)',           label):
            row['q18a']           = answer
        elif re.match(r'18\s*\([bB]\)',           label):
            row['q18b']           = answer
        elif re.match(r'18\s*\([cC]\)',           label):
            row['q18c']           = answer
        elif re.match(r'19[\.\(]',                label):
            row['q19']            = answer

    return row


# ---------------------------------------------------------------------------
# CSV output
# ---------------------------------------------------------------------------

CSV_FIELDNAMES = [
    "file",
    "application_id",
    "applicant_name",
    "string",
    "date_posted",
    "q13",
    "q16",
    "q18a",
    "q18b",
    "q18c",
    "q19",
]

CSV_HEADERS = {
    "file":           "Filename",
    "application_id": "Application ID",
    "applicant_name": "Applicant Name",
    "string":         "String (header)",
    "date_posted":    "Originally Posted",
    "q13":            "13. Applied-for gTLD string (U-label)",
    "q16": (
        "16. Describe the applicant's efforts to ensure that there are no known "
        "operational or rendering problems concerning the applied-for gTLD string."
    ),
    "q18a": "18(a). Describe the mission/purpose of your proposed gTLD.",
    "q18b": (
        "18(b). How do you expect that your proposed gTLD will benefit "
        "registrants, Internet users, and others?"
    ),
    "q18c": (
        "18(c). What operating rules will you adopt to eliminate or minimize "
        "social costs?"
    ),
    "q19": "19. Is the application for a community-based TLD?",
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
        help="Download/process only these numeric row IDs",
    )
    parser.add_argument(
        "--id-range",
        nargs=2,
        type=int,
        metavar=("START", "END"),
        help=(
            "Try all numeric row IDs from START to END inclusive "
            "(404s are silently skipped). "
            "Used automatically when the list page cannot be scraped."
        ),
    )
    parser.add_argument(
        "-o", "--output",
        metavar="DIR",
        default="downloads",
        help="Directory to store / read HTML files (default: ./downloads)",
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
    csv_path   = Path(args.csv)

    # ── 1. Collect files to parse or determine IDs to download ──────────────
    local_files: list[Path] = []

    if args.parse_only:
        local_files = sorted(output_dir.glob("*.html"))
        if not local_files:
            print(f"No HTML files found in {output_dir}/")
            sys.exit(1)
        print(f"Found {len(local_files)} HTML files in {output_dir}/\n")

    else:
        session = make_session()

        if args.ids:
            ids: list[int] = sorted(set(args.ids))
            print(f"Processing {len(ids)} specified IDs.")
        elif args.id_range:
            start, end = args.id_range
            ids = list(range(start, end + 1))
            print(f"Using ID range {start}–{end} ({len(ids)} candidates; 404s skipped).\n")
        else:
            ids = discover_ids(session)
            if not ids:
                start, end = _FALLBACK_RANGE
                ids = list(range(start, end + 1))
                print(
                    f"  [info] List page appears JS-rendered — no links found.\n"
                    f"  [info] Falling back to ID range {start}–{end}.\n"
                    f"  [info] You can also pass --id-range START END explicitly.\n"
                )

        if not ids:
            print("No application IDs found. Exiting.")
            sys.exit(1)

        # ── 2. Download ──────────────────────────────────────────────────────
        print(f"Downloading up to {len(ids)} applications → {output_dir}/\n")
        for i, app_id in enumerate(ids, 1):
            print(f"[{i:4d}/{len(ids)}] ID {app_id}")
            path = download_application(session, app_id, output_dir, args.overwrite)
            if path:
                local_files.append(path)
            if args.delay and i < len(ids):
                time.sleep(args.delay)

    if args.download_only:
        print(f"\nDownload complete.  {len(local_files)} files saved.")
        return

    # ── 3. Parse ─────────────────────────────────────────────────────────────
    if not local_files:
        print("No files to parse.")
        return

    print(f"Parsing {len(local_files)} file(s) …\n")
    rows: list[dict] = []

    for i, html_path in enumerate(local_files, 1):
        print(f"[{i:4d}/{len(local_files)}] {html_path.name}", end="  ")
        row = parse_application_html(html_path)
        rows.append(row)
        found = sum(
            1 for k in ("application_id", "string", "q16", "q18a", "q18b")
            if row.get(k)
        )
        print(f"({found}/5 key fields found)")

    # ── 4. Write CSV ──────────────────────────────────────────────────────────
    write_csv(rows, csv_path)


if __name__ == "__main__":
    main()
