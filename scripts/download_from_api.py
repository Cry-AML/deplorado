#!/usr/bin/env python3
"""Download DepMap files by resolving fresh URLs from the DepMap download API.

The DepMap portal exposes a file index at ``/portal/api/download/files`` that
maps every filename to a freshly signed download URL plus an MD5 checksum.
Resolving links through that index avoids the expired signed URLs that older
shell scripts baked in, and lets large retries verify integrity automatically.

The portal currently sits behind a browser verification challenge for some
automated clients; when that happens the index request returns HTML instead of
CSV and this script reports it rather than writing garbage to disk.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import sys
from pathlib import Path

import requests

DEFAULT_API_URL = "https://depmap.org/portal/api/download/files"
DOWNLOAD_TIMEOUT_SECONDS = 300
CHUNK_SIZE_BYTES = 8 * 1024 * 1024

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]

TARGET_FILES = [
    "CCLE_miRNA_MIMAT.csv",
    "harmonized_MS_CCLE_Gygi.csv",
    "metmap500_metastatic_potential_matrix.csv",
    "metmap500_penetrance_matrix.csv",
    "CCLE_GlobalChromatinProfiling_20181130.csv",
    "CCLE_RRBS_TSS1kb_20181022.txt.gz",
    "sanger_combination_library_viability_breadbox_data.csv",
    "sanger_combination_anchor_viability_breadbox_data.csv",
    "sanger_combination_combo_viability_breadbox_data.csv",
    "sanger_combination_library_fit_breadbox_data.csv",
    "sanger_combination_combo_fit_breadbox_data.csv",
    "Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv",
]

MANUAL_DOWNLOADS = {
    "metmap125_metastatic_potential_matrix.csv": {
        "url": "https://ndownloader.figshare.com/files/24009335",
        "note": "Distributed as Excel by Figshare; requires conversion to CSV.",
    },
    "sanger-dose-response.csv": {
        "url": "https://zenodo.org/records/7051876/files/sanger-dose-response.zip",
        "note": "Not in the DepMap index; requires download and extraction.",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=REPOSITORY_ROOT / "depmap_data",
        help="Directory to write downloaded files into (default: <repo>/depmap_data).",
    )
    parser.add_argument(
        "--log-dir",
        type=Path,
        default=REPOSITORY_ROOT / "download_logs",
        help="Directory for per-file logs (default: <repo>/download_logs).",
    )
    parser.add_argument(
        "--api-url",
        default=DEFAULT_API_URL,
        help=f"DepMap download index URL (default: {DEFAULT_API_URL}).",
    )
    parser.add_argument(
        "--list-only",
        action="store_true",
        help="Only print the resolved targets without downloading.",
    )
    return parser.parse_args()


def fetch_file_index(api_url: str) -> list[dict[str, str]]:
    print(f"Fetching file index from {api_url} ...")
    try:
        response = requests.get(
            api_url, timeout=30, headers={"Accept": "text/csv, */*"}
        )
        response.raise_for_status()
    except requests.RequestException as error:
        print(f"ERROR: failed to fetch file index: {error}")
        sys.exit(1)

    if response.text.lstrip().startswith("<"):
        print(
            "ERROR: the DepMap index returned HTML instead of CSV. The portal is "
            "likely serving a browser verification challenge to this client; "
            "resolve it interactively or download through the portal UI."
        )
        sys.exit(2)

    reader = csv.DictReader(response.text.splitlines())
    files = list(reader)
    print(f"Found {len(files)} files in the index")
    return files


def find_target_files(file_index: list[dict[str, str]]) -> list[dict[str, str]]:
    target_names = set(TARGET_FILES)
    matches = [entry for entry in file_index if entry.get("filename") in target_names]

    found_names = {entry["filename"] for entry in matches}
    missing = target_names - found_names
    if missing:
        print(f"WARNING: not found in index: {sorted(missing)}")

    return matches


def calculate_md5(file_path: Path) -> str:
    digest = hashlib.md5()
    with open(file_path, "rb") as handle:
        for chunk in iter(lambda: handle.read(CHUNK_SIZE_BYTES), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_file(url: str, local_path: Path, expected_md5: str | None = None) -> bool:
    print(f"  downloading: {local_path.name}")
    print(f"  url: {url[:96]}...")

    try:
        with requests.get(
            url, stream=True, timeout=DOWNLOAD_TIMEOUT_SECONDS, allow_redirects=True
        ) as response:
            response.raise_for_status()

            if response.url != url:
                print(f"  redirected to: {response.url[:96]}...")

            content_length = response.headers.get("content-length")
            if content_length:
                print(f"  size: {int(content_length) / 1024 / 1024:.1f} MiB")

            downloaded = 0
            with open(local_path, "wb") as handle:
                for chunk in response.iter_content(chunk_size=CHUNK_SIZE_BYTES):
                    if chunk:
                        handle.write(chunk)
                        downloaded += len(chunk)

        actual_size = local_path.stat().st_size
        print(f"  downloaded: {actual_size / 1024 / 1024:.1f} MiB")

        if actual_size == 0:
            print("  ERROR: file is empty")
            return False

        if expected_md5 and not verify_md5(local_path, expected_md5):
            return False

        return True
    except requests.RequestException as error:
        print(f"  ERROR: {error}")
        return False
    except OSError as error:
        print(f"  ERROR: failed to write file: {error}")
        return False


def verify_md5(file_path: Path, expected_md5: str) -> bool:
    actual_md5 = calculate_md5(file_path)
    if actual_md5.lower() == expected_md5.lower():
        print(f"  md5 verified: {expected_md5}")
        return True
    print(f"  ERROR: md5 mismatch (expected {expected_md5}, got {actual_md5})")
    return False


def download_targets(
    out_dir: Path, log_dir: Path, api_url: str, list_only: bool
) -> tuple[int, int]:
    file_index = fetch_file_index(api_url)
    matched = find_target_files(file_index)

    if not matched:
        print("No matching files found in the index.")
        return 0, 0

    print(f"\nMatched {len(matched)} target files:")
    for entry in matched:
        print(f"  - {entry['filename']} ({entry.get('release', 'unknown release')})")

    if list_only:
        return 0, 0

    out_dir.mkdir(parents=True, exist_ok=True)
    log_dir.mkdir(parents=True, exist_ok=True)

    print("\n" + "=" * 60)
    print("Downloading files ...")
    print("=" * 60)

    success_count = 0
    failure_count = 0

    for entry in matched:
        filename = entry["filename"]
        url = entry.get("url", "")
        expected_md5 = entry.get("md5_hash") or None
        local_path = out_dir / filename

        if local_path.exists() and local_path.stat().st_size > 0:
            print(f"\n[SKIP] {filename} (already present)")
            success_count += 1
            continue

        print(f"\n[{filename}] release={entry.get('release', 'unknown')}")

        if not url:
            print("  ERROR: no URL available for this file")
            failure_count += 1
            continue

        if download_file(url, local_path, expected_md5):
            print(f"  [OK] {filename}")
            success_count += 1
        else:
            print(f"  [FAIL] {filename}")
            failure_count += 1

    return success_count, failure_count


def print_manual_downloads() -> None:
    print("\n" + "=" * 60)
    print("Files requiring special handling:")
    print("=" * 60)
    for filename, info in MANUAL_DOWNLOADS.items():
        print(f"\n{filename}:")
        print(f"  URL: {info['url']}")
        print(f"  Note: {info['note']}")


def main() -> int:
    args = parse_args()

    print("=" * 60)
    print("DepMap file downloader (index-driven)")
    print("=" * 60)

    success_count, failure_count = download_targets(
        args.out_dir, args.log_dir, args.api_url, args.list_only
    )

    if not args.list_only:
        print_manual_downloads()

    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Successful: {success_count}")
    print(f"Failed: {failure_count}")
    print(f"Output directory: {args.out_dir}")

    return 1 if failure_count else 0


if __name__ == "__main__":
    sys.exit(main())
