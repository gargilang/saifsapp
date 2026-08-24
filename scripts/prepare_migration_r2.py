#!/usr/bin/env python3
"""Generate or independently verify the r2 migration preview workbook."""

from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path
import sys

from migration_r2 import build_dataset, verify_preview, write_preview


ROOT = Path(__file__).resolve().parents[1]


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=ROOT / "ref" / "DAFTAR KREDIT BARANG r2.xlsx",
        help="workbook r2 dari klien",
    )
    parser.add_argument(
        "--legacy-preview",
        type=Path,
        default=ROOT / "ref" / "PREVIEW_MIGRASI.xlsx",
        help="preview lama untuk mapping jenis dan label yang sudah dirapikan",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "ref" / "PREVIEW_MIGRASI_R2.xlsx",
        help="lokasi preview hasil",
    )
    parser.add_argument(
        "--cutoff",
        type=date.fromisoformat,
        default=date(2026, 8, 24),
        help="tanggal batas validasi dalam format YYYY-MM-DD",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="muat ulang dan verifikasi output tanpa membaca workbook sumber",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.verify_only:
            report = verify_preview(args.output)
        else:
            dataset = build_dataset(args.input, args.legacy_preview, cutoff=args.cutoff)
            report = dataset.validation
            if report.ok:
                write_preview(dataset, args.output)
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if not report.ok:
        for error in report.errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(report.summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
