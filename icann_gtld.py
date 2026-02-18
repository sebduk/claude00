#!/usr/bin/env python3
"""
ICANN 2012 New gTLD Application Downloader & Parser.

Discovers all application IDs from the ICANN status page, downloads each
public-portion PDF, scrapes structured fields from the HTML detail page,
extracts long-form narrative sections from the PDF text, and writes
everything to a CSV table.

Requirements:
    pip install requests beautifulsoup4 pdfplumber

Usage:
    # Full run — discover IDs, download PDFs, parse, write CSV:
    python3 icann_gtld.py

    # Download PDFs only (no parsing):
    python3 icann_gtld.py --download-only

    # Parse already-downloaded PDFs (no new downloads):
    python3 icann_gtld.py --parse-only

    # Process a subset of application IDs:
    python3 icann_gtld.py --ids 1001 1002 1003

    # Custom output locations:
    python3 icann_gtld.py -o ./pdfs --csv icann_table.csv

Output:
    downloads/          PDF files named {app_id}.pdf
    results.csv         Extracted field table (UTF-8)
"""

import argparse
import csv
import re
import sys
import time
from pathlib import Path

import requests

try:
    from bs4 import BeautifulSoup
    BS4_OK = True
except ImportError:
    BS4_OK = False

try:
    import pdfplumber
    PDF_BACKEND = "pdfplumber"
except ImportError:
    try:
        import pypdf  # noqa: F401
        PDF_BACKEND = "pypdf"
    except ImportError:
        PDF_BACKEND = None

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE_URL = "https://gtldresult.icann.org"
LIST_URL = f"{BASE_URL}/applicationstatus/viewstatus"
DETAIL_URL = f"{BASE_URL}/applicationstatus/applicationdetails/{{id}}"
DOWNLOAD_URL = (
    f"{BASE_URL}/applicationstatus/applicationdetails:downloadapplication/{{id}}?t:ac={{id}}"
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
# HTTP session
# ---------------------------------------------------------------------------


def make_session() -> requests.Session:
    """Create a requests Session with browser-like headers and warmed-up cookies."""
    s = requests.Session()
    s.headers.update(BROWSER_HEADERS)
    # Warm up: visit root to collect any session/tracking cookies.
    try:
        s.get(BASE_URL, timeout=20)
        time.sleep(0.3)
    except requests.RequestException:
        pass
    return s


def _get_with_retry(
    session: requests.Session,
    url: str,
    *,
    timeout: int = 30,
    max_attempts: int = 4,
    stream: bool = False,
) -> requests.Response | None:
    """GET with exponential-backoff retry on network errors."""
    delay = 2
    for attempt in range(1, max_attempts + 1):
        try:
            resp = session.get(url, timeout=timeout, stream=stream)
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


def discover_ids(session: requests.Session) -> list[int]:
    """
    Scrape the viewstatus page and return all application IDs found in links.
    The page contains anchor tags pointing to /applicationdetails/{id}.
    """
    print(f"Fetching application list: {LIST_URL}")
    resp = _get_with_retry(session, LIST_URL, timeout=60)
    if resp is None:
        print("ERROR: Could not fetch the application list page.", file=sys.stderr)
        sys.exit(1)

    # Collect IDs — prefer BeautifulSoup if available, else regex over raw HTML
    ids: set[int] = set()
    if BS4_OK:
        soup = BeautifulSoup(resp.text, "html.parser")
        for tag in soup.find_all("a", href=True):
            m = re.search(r"/applicationdetails/(\d+)", tag["href"])
            if m:
                ids.add(int(m.group(1)))

    # Fallback / bs4 unavailable: scan raw HTML text
    if not ids:
        for m in re.finditer(r"/applicationdetails/(\d+)", resp.text):
            ids.add(int(m.group(1)))

    result = sorted(ids)
    print(f"Found {len(result)} application IDs.\n")
    return result


# ---------------------------------------------------------------------------
# Scrape HTML detail page for structured fields
# ---------------------------------------------------------------------------


def _text_after_label(soup: BeautifulSoup, label_re: re.Pattern) -> str:
    """
    Find a table cell / dt / span whose text matches label_re and return the
    text of the adjacent value element.  Returns "" if not found.
    """
    for tag in soup.find_all(string=label_re):
        parent = tag.parent
        # Try <td> sibling
        sibling = parent.find_next_sibling()
        if sibling:
            return sibling.get_text(" ", strip=True)
        # Try next <td> in the same <tr>
        td = parent.find_parent("td")
        if td:
            nxt = td.find_next_sibling("td")
            if nxt:
                return nxt.get_text(" ", strip=True)
    return ""


def scrape_detail_page(session: requests.Session, app_id: int) -> dict:
    """
    Fetch the HTML detail page and extract:
      - String (gTLD applied for)
      - Application ID (e.g. 1-1311-58570)
      - 14A A-label (IDN xn-- form)
    Returns a dict with keys: string, application_id, alabel_14a
    """
    url = DETAIL_URL.format(id=app_id)
    resp = _get_with_retry(session, url)
    result = {"string": "", "application_id": "", "alabel_14a": ""}
    if resp is None:
        return result

    page_text = resp.text

    if BS4_OK:
        soup = BeautifulSoup(page_text, "html.parser")

        # --- String ---
        for pat in [
            re.compile(r"applied.for\s+string", re.I),
            re.compile(r"^string$", re.I),
        ]:
            val = _text_after_label(soup, pat)
            if val:
                result["string"] = val
                break

        # Fallback: h1 often contains the string
        if not result["string"]:
            h1 = soup.find("h1")
            if h1:
                result["string"] = h1.get_text(" ", strip=True)

        # --- Application ID ---
        for pat in [
            re.compile(r"application\s+id", re.I),
            re.compile(r"application\s+number", re.I),
        ]:
            val = _text_after_label(soup, pat)
            if val:
                result["application_id"] = val
                break

        # --- 14A A-label ---
        for pat in [
            re.compile(r"14\s*a\.?\s*.*?a.label", re.I),
            re.compile(r"a-label", re.I),
        ]:
            val = _text_after_label(soup, pat)
            if val:
                result["alabel_14a"] = val
                break

    # Regex fallbacks (work without bs4)
    if not result["application_id"]:
        m = re.search(r"\b(1-\d{4}-\d{5})\b", page_text)
        if m:
            result["application_id"] = m.group(1)

    if not result["alabel_14a"]:
        m = re.search(r"\b(xn--[a-z0-9\-]+)\b", page_text, re.I)
        if m:
            result["alabel_14a"] = m.group(1)

    return result


# ---------------------------------------------------------------------------
# Download PDFs
# ---------------------------------------------------------------------------


def download_pdf(
    session: requests.Session,
    app_id: int,
    output_dir: Path,
    overwrite: bool = False,
) -> Path | None:
    """Download the public-portion PDF for app_id.  Returns local path or None."""
    dest = output_dir / f"{app_id}.pdf"
    if dest.exists() and not overwrite:
        print(f"  [skip] {dest.name} already exists")
        return dest

    url = DOWNLOAD_URL.format(id=app_id)
    resp = _get_with_retry(session, url, timeout=120, stream=True)
    if resp is None:
        return None

    ct = resp.headers.get("Content-Type", "")
    if "html" in ct.lower():
        # Server returned an error page as HTML
        print(f"  [warn] Got HTML instead of PDF for ID {app_id} — skipping")
        return None

    output_dir.mkdir(parents=True, exist_ok=True)
    downloaded = 0
    try:
        with open(dest, "wb") as fh:
            for chunk in resp.iter_content(65_536):
                if chunk:
                    fh.write(chunk)
                    downloaded += len(chunk)
    except OSError as exc:
        print(f"  [write error] {exc}")
        dest.unlink(missing_ok=True)
        return None

    print(f"  [done] {dest.name}  ({downloaded:,} bytes)")
    return dest


# ---------------------------------------------------------------------------
# PDF text extraction
# ---------------------------------------------------------------------------


def _extract_text_pdfplumber(pdf_path: Path) -> str:
    import pdfplumber

    pages = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            t = page.extract_text(x_tolerance=2, y_tolerance=2)
            if t:
                pages.append(t)
    return "\n".join(pages)


def _extract_text_pypdf(pdf_path: Path) -> str:
    import pypdf

    reader = pypdf.PdfReader(str(pdf_path))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def extract_pdf_text(pdf_path: Path) -> str:
    if PDF_BACKEND == "pdfplumber":
        return _extract_text_pdfplumber(pdf_path)
    if PDF_BACKEND == "pypdf":
        return _extract_text_pypdf(pdf_path)
    raise RuntimeError(
        "No PDF library available. Install one:\n  pip install pdfplumber"
    )


# ---------------------------------------------------------------------------
# Parse narrative sections from PDF text
# ---------------------------------------------------------------------------

# Each ICANN application PDF uses numbered question headings.
# We capture the text after the heading up to the next numbered question.
# The patterns are intentionally loose to handle minor OCR / layout variation.

_Q_BOUNDARY = r"(?=\n\s*\d{1,2}[A-Za-z]?[\.\)])"  # lookahead: next question

_SECTION_PATTERNS: dict[str, re.Pattern] = {
    # Question 16
    "q16": re.compile(
        r"16[\.\)]\s+Describe\s+the\s+applicant[^\n]*\n(.*?)" + _Q_BOUNDARY,
        re.DOTALL | re.IGNORECASE,
    ),
    # Question 18A
    "q18a": re.compile(
        r"18\s*[Aa][\.\)]\s+Describe\s+the\s+mission[^\n]*\n(.*?)" + _Q_BOUNDARY,
        re.DOTALL | re.IGNORECASE,
    ),
    # Question 18B
    "q18b": re.compile(
        r"18\s*[Bb][\.\)]\s+How\s+do\s+you\s+expect[^\n]*\n(.*?)" + _Q_BOUNDARY,
        re.DOTALL | re.IGNORECASE,
    ),
    # Question 18C
    "q18c": re.compile(
        r"18\s*[Cc][\.\)]\s+What\s+operating\s+rules[^\n]*\n(.*?)"
        r"(?=" + _Q_BOUNDARY[3:] + r"|\Z)",
        re.DOTALL | re.IGNORECASE,
    ),
    # 14A inside the PDF (fallback if not found in HTML)
    "q14a": re.compile(
        r"14\s*[Aa][\.\)]\s+If\s+applying[^\n]*\n(.*?)" + _Q_BOUNDARY,
        re.DOTALL | re.IGNORECASE,
    ),
}

# Also try to pick up String / Application ID from the PDF header section
_HEADER_PATTERNS: dict[str, re.Pattern] = {
    "string": re.compile(
        r"(?:Applied.for\s+)?String\s*[:\>]\s*(.+?)$",
        re.IGNORECASE | re.MULTILINE,
    ),
    "application_id": re.compile(
        r"Application\s+ID\s*[:\>]\s*(.+?)$",
        re.IGNORECASE | re.MULTILINE,
    ),
    "alabel_14a_inline": re.compile(
        r"(xn--[A-Za-z0-9\-]+)",
    ),
}


def _clean(text: str) -> str:
    """Strip leading/trailing whitespace; collapse excessive blank lines."""
    text = text.strip()
    text = re.sub(r" {2,}", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def parse_pdf(app_id: int, pdf_path: Path, html_fields: dict) -> dict:
    """
    Extract all required fields for one application.

    html_fields: pre-scraped dict from scrape_detail_page().
    Returns a flat dict ready for CSV output.
    """
    row: dict[str, str] = {
        "app_id": str(app_id),
        "string": html_fields.get("string", ""),
        "application_id": html_fields.get("application_id", ""),
        "14a_alabel": html_fields.get("alabel_14a", ""),
        "q16": "",
        "q18a": "",
        "q18b": "",
        "q18c": "",
    }

    if PDF_BACKEND is None:
        return row

    try:
        text = extract_pdf_text(pdf_path)
    except Exception as exc:
        print(f"  [parse error] {pdf_path.name}: {exc}")
        return row

    # Fill narrative sections
    for field, pat in _SECTION_PATTERNS.items():
        m = pat.search(text)
        if m:
            value = _clean(m.group(1))
            if field == "q14a" and not row["14a_alabel"]:
                # Extract xn-- label from the section text
                xn = re.search(r"(xn--[A-Za-z0-9\-]+)", value, re.I)
                row["14a_alabel"] = xn.group(1) if xn else _clean(value)
            else:
                row[field] = value

    # Fallback: try to get String / Application ID from PDF text if still empty
    for key, pat in _HEADER_PATTERNS.items():
        if key == "alabel_14a_inline":
            if not row["14a_alabel"]:
                m = pat.search(text)
                if m:
                    row["14a_alabel"] = m.group(1)
        elif key == "string" and not row["string"]:
            m = pat.search(text)
            if m:
                row["string"] = _clean(m.group(1))
        elif key == "application_id" and not row["application_id"]:
            m = pat.search(text)
            if m:
                row["application_id"] = _clean(m.group(1))

    return row


# ---------------------------------------------------------------------------
# CSV output
# ---------------------------------------------------------------------------

CSV_FIELDNAMES = [
    "app_id",
    "string",
    "application_id",
    "14a_alabel",
    "q16",
    "q18a",
    "q18b",
    "q18c",
]

CSV_HEADERS = {
    "app_id": "App ID (numeric)",
    "string": "String",
    "application_id": "Application ID",
    "14a_alabel": "14A. A-label (IDN xn-- form)",
    "q16": (
        "16. Describe the applicant's efforts to ensure that there are no known "
        "operational or rendering problems concerning the applied-for gTLD string."
    ),
    "q18a": "18A. Describe the mission/purpose of your proposed gTLD.",
    "q18b": (
        "18B. How do you expect that your proposed gTLD will benefit registrants, "
        "Internet users, and others?"
    ),
    "q18c": (
        "18C. What operating rules will you adopt to eliminate or minimize social "
        "costs?"
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
    missing = []
    if not BS4_OK:
        missing.append("beautifulsoup4")
    if PDF_BACKEND is None:
        missing.append("pdfplumber")
    if missing:
        print(
            f"WARNING: Missing optional libraries: {', '.join(missing)}\n"
            "         Install them for full functionality:\n"
            f"           pip install {' '.join(missing)}\n"
            "         PDFs will be downloaded; HTML scraping / PDF parsing may be skipped.\n"
        )

    parser = argparse.ArgumentParser(
        description="Download and parse ICANN 2012 gTLD application PDFs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--download-only",
        action="store_true",
        help="Download PDFs without parsing or writing CSV",
    )
    parser.add_argument(
        "--parse-only",
        action="store_true",
        help="Parse already-downloaded PDFs; skip new downloads",
    )
    parser.add_argument(
        "--ids",
        nargs="+",
        type=int,
        metavar="ID",
        help="Process only these numeric application IDs",
    )
    parser.add_argument(
        "-o",
        "--output",
        metavar="DIR",
        default="downloads",
        help="Directory to store PDFs (default: ./downloads)",
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
        help="Re-download PDFs that already exist locally",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=0.5,
        metavar="SECS",
        help="Pause between HTTP requests in seconds (default: 0.5)",
    )
    parser.add_argument(
        "--no-html-scrape",
        action="store_true",
        help="Skip scraping HTML detail pages; rely on PDF text only",
    )
    args = parser.parse_args()

    output_dir = Path(args.output)
    csv_path = Path(args.csv)

    session = make_session()

    # ── 1. Determine which IDs to process ───────────────────────────────────
    if args.ids:
        ids = sorted(set(args.ids))
        print(f"Processing {len(ids)} specified IDs.")
    elif args.parse_only:
        ids = sorted(
            int(p.stem) for p in output_dir.glob("*.pdf") if p.stem.isdigit()
        )
        print(f"Found {len(ids)} PDFs in {output_dir}/")
    else:
        ids = discover_ids(session)

    if not ids:
        print("No application IDs found. Exiting.")
        sys.exit(1)

    # ── 2. Download PDFs ─────────────────────────────────────────────────────
    local_pdfs: dict[int, Path] = {}

    if not args.parse_only:
        print(f"Downloading {len(ids)} PDFs → {output_dir}/\n")
        for i, app_id in enumerate(ids, 1):
            print(f"[{i:4d}/{len(ids)}] ID {app_id}")
            path = download_pdf(session, app_id, output_dir, overwrite=args.overwrite)
            if path:
                local_pdfs[app_id] = path
            if args.delay and i < len(ids):
                time.sleep(args.delay)
    else:
        for app_id in ids:
            p = output_dir / f"{app_id}.pdf"
            if p.exists():
                local_pdfs[app_id] = p
            else:
                print(f"  [missing] {p} — skipping")

    if args.download_only:
        print(f"\nDownload-only mode complete.  {len(local_pdfs)} files saved.")
        return

    # ── 3. Parse ─────────────────────────────────────────────────────────────
    if not local_pdfs:
        print("No PDFs to parse.")
        return

    print(f"\nParsing {len(local_pdfs)} applications …\n")
    rows: list[dict] = []
    items = sorted(local_pdfs.items())

    for i, (app_id, pdf_path) in enumerate(items, 1):
        print(f"[{i:4d}/{len(items)}] {pdf_path.name}", end="")

        # Optionally scrape HTML detail page for structured fields
        if not args.no_html_scrape:
            html_fields = scrape_detail_page(session, app_id)
            if args.delay:
                time.sleep(args.delay)
        else:
            html_fields = {}

        row = parse_pdf(app_id, pdf_path, html_fields)
        rows.append(row)

        # Progress summary on same line
        found = sum(1 for k in ("string", "application_id", "14a_alabel", "q16", "q18a") if row.get(k))
        print(f"  ({found}/5 fields found)")

    # ── 4. Write CSV ──────────────────────────────────────────────────────────
    write_csv(rows, csv_path)


if __name__ == "__main__":
    main()
