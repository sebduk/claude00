#!/usr/bin/env python3
"""
Batch file downloader.

Usage:
  # Download URLs listed in a file (one per line):
  python3 downloader.py -f urls.txt

  # Download URLs passed directly:
  python3 downloader.py https://example.com/file1.zip https://example.com/file2.zip

  # Specify output directory and overwrite existing files:
  python3 downloader.py -f urls.txt -o ./downloads --overwrite
"""

import argparse
import os
import sys
import time
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError


def parse_url_file(path: str) -> list[str]:
    """Read URLs from a text file, one per line. Skips blank lines and comments."""
    urls = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                urls.append(line)
    return urls


def filename_from_url(url: str) -> str:
    """Derive a local filename from a URL."""
    parsed = urlparse(url)
    name = Path(parsed.path).name
    return name if name else "download"


def download_file(url: str, dest: Path, overwrite: bool = False, retries: int = 3) -> bool:
    """
    Download a single URL to dest.
    Returns True on success, False on failure.
    """
    if dest.exists() and not overwrite:
        print(f"  [skip] {dest.name} already exists")
        return True

    headers = {"User-Agent": "Mozilla/5.0 batch-downloader/1.0"}
    delay = 2

    for attempt in range(1, retries + 1):
        try:
            req = Request(url, headers=headers)
            with urlopen(req, timeout=30) as response:
                total = int(response.headers.get("Content-Length", 0))
                dest.parent.mkdir(parents=True, exist_ok=True)
                downloaded = 0
                with open(dest, "wb") as f:
                    while chunk := response.read(65536):
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total:
                            pct = downloaded * 100 // total
                            print(f"\r  {pct:3d}%  {dest.name}", end="", flush=True)
                print(f"\r  [done] {dest.name} ({downloaded:,} bytes)")
                return True
        except HTTPError as e:
            print(f"  [error] HTTP {e.code} for {url}")
            return False
        except URLError as e:
            if attempt < retries:
                print(f"  [retry {attempt}/{retries}] {e.reason} — waiting {delay}s")
                time.sleep(delay)
                delay *= 2
            else:
                print(f"  [failed] {e.reason}")
                return False
    return False


def main():
    parser = argparse.ArgumentParser(description="Download files from a list of URLs.")
    parser.add_argument(
        "urls", nargs="*", metavar="URL",
        help="URLs to download (alternative to -f)"
    )
    parser.add_argument(
        "-f", "--file", metavar="FILE",
        help="Text file with one URL per line"
    )
    parser.add_argument(
        "-o", "--output", metavar="DIR", default="downloads",
        help="Output directory (default: ./downloads)"
    )
    parser.add_argument(
        "--overwrite", action="store_true",
        help="Re-download and overwrite existing files"
    )
    args = parser.parse_args()

    urls: list[str] = list(args.urls)
    if args.file:
        urls += parse_url_file(args.file)

    if not urls:
        parser.print_help()
        sys.exit(1)

    output_dir = Path(args.output)
    print(f"Saving to: {output_dir.resolve()}")
    print(f"Files to download: {len(urls)}\n")

    success, failure = 0, 0
    for url in urls:
        filename = filename_from_url(url)
        dest = output_dir / filename
        print(f"-> {url}")
        if download_file(url, dest, overwrite=args.overwrite):
            success += 1
        else:
            failure += 1

    print(f"\nDone. {success} succeeded, {failure} failed.")
    if failure:
        sys.exit(1)


if __name__ == "__main__":
    main()
