#!/usr/bin/env python3
"""
Praktikum 3 (BAB 3) — Validator Pengumpulan Laporan Mahasiswa.

Jalankan skrip ini dari folder BAB3_Lab_Jaringan_Tiga_Zona Anda sebelum mengumpulkan:
    python3 validate_submission.py
"""

from __future__ import annotations

import pathlib
import re
import sys

REQUIRED_SECTIONS = [
    ("1. Identitas", r"(?i)##\s*1\.\s*identitas"),
    ("2. Ketepatan Hasil (35 poin)", r"(?i)##\s*2\.\s*ketepatan\s*hasil"),
    ("3. Metode & Pengamanan (25 poin)", r"(?i)##\s*3\.\s*metode\s*&\s*pengamanan"),
    ("4. Verifikasi & Batasan (25 poin)", r"(?i)##\s*4\.\s*verifikasi\s*&\s*batasan"),
    ("5. Penjelasan Individu (15 poin)", r"(?i)##\s*5\.\s*penjelasan\s*individu"),
]

SUBSECTIONS_CHECK = [
    ("2.1 Bukti Segmentasi", r"(?i)###\s*2\.1"),
    ("2.2 Matriks Akses", r"(?i)###\s*2\.2"),
    ("3.1 docker-compose.yml Tiga Zona", r"(?i)###\s*3\.1"),
    ("4.1 Uji Perbandingan Default-Deny", r"(?i)###\s*4\.1"),
    ("4.2 Bukti Alert IDS/IPS", r"(?i)###\s*4\.2"),
]


def check_report(report_path: pathlib.Path) -> list[str]:
    issues: list[str] = []
    if not report_path.exists():
        return [f"Berkas laporan tidak ditemukan: {report_path.name}"]

    content = report_path.read_text(encoding="utf-8", errors="replace")

    if len(content.strip()) < 300:
        issues.append(f"{report_path.name} terlalu pendek atau belum diisi (panjang < 300 karakter).")

    # Periksa bagian-bagian wajib Rubrik C2
    for sec_name, pattern in REQUIRED_SECTIONS:
        if not re.search(pattern, content):
            issues.append(f"{report_path.name}: Bagian wajib hilang -> '{sec_name}'")

    for sub_name, pattern in SUBSECTIONS_CHECK:
        if not re.search(pattern, content):
            issues.append(f"{report_path.name}: Sub-bagian penting belum tercantum -> '{sub_name}'")

    # Periksa penampung template yang belum diedit
    placeholders = re.findall(r"<[A-Za-z0-9_\-\s:|/]+>", content)
    # Filter out valid markdown / html if any
    suspicious_ph = [p for p in placeholders if any(w in p.lower() for w in ("nama", "nim", "kelas", "alasan", "dd-mm", "port", "layanan"))]
    if suspicious_ph:
        issues.append(f"{report_path.name}: Masih terdapat placeholder template yang belum diisi: {suspicious_ph[:3]}")

    if "(tempel" in content.lower():
        unfilled_pastes = re.findall(r"\(tempel[^\)]*\)", content, flags=re.IGNORECASE)
        if unfilled_pastes:
            issues.append(f"{report_path.name}: Masih ada instruksi tempel yang belum diganti: {unfilled_pastes[:2]}")

    # Periksa larangan kunci privat mentah
    banned_tag = "BEGIN" + " PRIVATE " + "KEY"
    if banned_tag in content:
        issues.append(f"{report_path.name}: PERINGATAN KRITIS - memuat kunci privat mentah!")

    return issues


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent
    print(f"=== Validasi Pengumpulan Praktikum 3 ({root.name}) ===\n")

    # Cari laporan praktikum
    candidates = [
        root / "laporan_praktikum.md",
        root / "laporan_template.md",
        root / "laporan.md",
    ]
    target_report = None
    for cand in candidates:
        if cand.exists():
            target_report = cand
            break

    if target_report is None:
        print("  ❌ FAIL: Berkas laporan tidak ditemukan!")
        print("     Harap buat berkas 'laporan_praktikum.md' (bisa menyalin dari 'laporan_template.md').")
        return 1

    print(f"  • Memeriksa berkas: {target_report.name}")
    issues = check_report(target_report)

    if not issues:
        print(f"  ✅ PASS: Seluruh dimensi Rubrik C2 dan kelengkapan bukti terpenuhi!")
        print("\nBerkas Anda siap dikumpulkan ke LMS sesuai arahan dosen.")
        return 0
    else:
        print("  ❌ FAIL: Ditemukan kekurangan pada berkas pengumpulan:")
        for iss in issues:
            print(f"     - {iss}")
        print("\nHarap lengkapi poin-poin di atas sebelum mengumpulkan laporan.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
