#!/usr/bin/env bash
# Praktikum 3 (BAB 3) — alat bantu: buktikan segmentasi tiga zona.
#
# Menjalankan lima uji yang sama setiap kali, sehingga mahasiswa punya
# perbandingan sebelum/sesudah yang konsisten dan dapat dilampirkan apa adanya.
#
# Pakai:
#   ./periksa_zona.sh                 # uji seluruh lima pemeriksaan
#   ./periksa_zona.sh ringkas         # hanya baris hasil
#
# CATATAN PENTING (hasil pengujian di mesin dosen, Docker 29.x):
#   Uji "web -> db" SELALU TERTUTUP, baik dengan maupun tanpa `internal: true`,
#   karena web dan db tidak berada di jaringan yang sama sehingga nama `db`
#   bahkan tidak dapat diresolusi. Jadi uji itu BUKAN pembanding Langkah 3.
#   Pembanding Langkah 4 yang benar adalah "db -> Internet":
#       dengan    internal: true  -> GAGAL
#       tanpa     internal: true  -> BERHASIL   <-- jalur eksfiltrasi terbuka
#   Itulah bukti bahwa satu opsi konfigurasi dapat membuka jalur serangan.

set -uo pipefail

RINGKAS=0
[[ "${1:-}" == "ringkas" ]] && RINGKAS=1

say() { [[ $RINGKAS -eq 0 ]] && printf '%s\n' "$*" || true; }
hasil() { printf '  %-34s %s\n' "$1" "$2"; }

say "=================================================================="
say " Periksa segmentasi tiga zona — Praktikum 3 (BAB 3)"
say "=================================================================="
say ""

for c in lab3-web lab3-app lab3-db lab3-admin; do
  if ! docker inspect -f '{{.State.Running}}' "$c" >/dev/null 2>&1; then
    printf 'Kontainer %s tidak berjalan. Jalankan dulu:\n  docker compose up -d\n' "$c"
    exit 1
  fi
done

DB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' lab3-db 2>/dev/null | awk '{print $1}')
say "IP kontainer db: ${DB_IP}"
say ""

say "--- 1. web -> db:5432  (harus TERTUTUP) ---"
hasil "web -> db:5432" "$(docker exec lab3-web sh -c 'nc -zv -w 3 db 5432 >/dev/null 2>&1 && echo TERBUKA || echo TERTUTUP')"

say "--- 2. app -> db:5432  (harus TERBUKA) ---"
hasil "app -> db:5432" "$(docker exec lab3-app sh -c 'nc -zv -w 3 db 5432 >/dev/null 2>&1 && echo TERBUKA || echo TERTUTUP')"

say "--- 3. admin -> db:5432  (harus TERTUTUP) ---"
# Catatan portabilitas: gunakan `grep -E` (bukan `grep '\|'`) karena grep BSD
# pada macOS tidak mendukung alternasi `\|` dalam mode BRE.
ADMIN_ZONA=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' lab3-admin 2>/dev/null | tr ' ' '\n' | grep -cE 'zona-web|zona-data')
ADMIN_ZONA=${ADMIN_ZONA:-0}
if [[ "${ADMIN_ZONA:-0}" -gt 0 ]]; then
  printf '%s\n' \
    "  CATATAN: override pemindaian sedang aktif — admin sengaja disambungkan" \
    "  ke zona-web/zona-data, jadi hasil di bawah WAJAR TERBUKA." \
    "  Kembalikan ke tiga zona terisolasi untuk mengukur keadaan sebenarnya:" \
    "    docker compose -f docker-compose.yml -f docker-compose.pindai.yml down" \
    "    docker compose up -d"
fi
hasil "admin -> db:5432" "$(docker exec lab3-admin sh -c "nc -zv -w 3 ${DB_IP} 5432 >/dev/null 2>&1 && echo TERBUKA || echo TERTUTUP")"

say "--- 4. host -> db:5432  (harus TERTUTUP) ---"
# Portabilitas: pada Linux, ${DB_IP} dapat diuji langsung dari host.
# Pada macOS (Docker Desktop / Darwin), subnet kontainer terisolasi di dalam VM,
# sehingga uji ini memeriksa apakah port dipublikasikan ke host (127.0.0.1) atau ada binding host.
HOST_TERBUKA="TERTUTUP"
if nc -zv -w 2 "${DB_IP}" 5432 >/dev/null 2>&1; then
  HOST_TERBUKA="TERBUKA"
elif nc -zv -w 2 127.0.0.1 5432 >/dev/null 2>&1; then
  HOST_TERBUKA="TERBUKA"
else
  PUBLISHED=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}{{end}}{{end}}' lab3-db 2>/dev/null | grep -o '5432' || true)
  [[ -n "$PUBLISHED" ]] && HOST_TERBUKA="TERBUKA" || HOST_TERBUKA="TERTUTUP"
fi
hasil "host -> db:5432" "$HOST_TERBUKA"

say "--- 5. db -> Internet  (internal:true -> GAGAL) ---"
hasil "db -> Internet" "$(docker exec lab3-db sh -c 'wget -qO- -T3 http://example.com >/dev/null 2>&1 && echo BERHASIL || echo GAGAL')"

say ""
say "Uji 5 adalah pembanding Langkah 4. Hentikan lab, hapus baris"
say "  internal: true"
say "pada jaringan zona-data, jalankan ulang, lalu ulangi skrip ini."
say "Nilai uji 5 akan berubah menjadi BERHASIL — artinya basis data dapat"
say "mengirim data ke luar. Simpan kedua keluaran sebagai bukti."
say ""
say "Uji 1 sampai 4 TIDAK berubah. Jelaskan mengapa di laporan Anda."
