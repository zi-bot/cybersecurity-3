#!/usr/bin/env bash
# Praktikum 3 (BAB 3) — jalankan IDS pada lalu lintas laboratorium.
#
# Menjalankan Suricata di atas antarmuka bridge laboratorium (bukan seluruh
# jaringan Anda), memuat aturan lokal, lalu merangkum alert yang benar-benar
# tercatat. Inilah bukti yang diminta Langkah 6 modul: alert nyata, bukan
# sekadar berkas konfigurasi aturan.
#
# Pakai:
#   ./periksa_ids.sh mulai       # nyalakan IDS pada bridge zona-web
#   ./periksa_ids.sh ringkas     # tampilkan alert yang sudah tercatat
#   ./periksa_ids.sh hentikan    # matikan IDS
#
# Setelah IDS menyala, jalankan pemindaian dari kontainer admin, misalnya:
#   docker exec lab3-admin nmap -sS -p 1-3000 lab3-web
#   docker exec lab3-admin nmap -sV -sC -p 80 lab3-web
#
# Hasil pengujian pada mesin dosen (Docker 29.x, Suricata 8.0.6):
#   nmap -sS -p 1-3000  -> sid 1000001 (202 alert) + sid 1000005 (75 alert)
#   nmap -sV -sC -p 80  -> sid 1000002 (29 alert) + sid 1000003 (29 alert)
#
# Catatan: Suricata hanya melihat lalu lintas pada antarmuka yang dipasang.
# Bridge zona-web memuat seluruh lalu lintas pemindaian, jadi itu yang dipakai.
# Untuk cakupan penuh, jalankan instance lain pada bridge zona-data dengan
# mengganti nilai JARINGAN di bawah menjadi zona-data.

set -uo pipefail

JARINGAN="${JARINGAN:-zona-web}"
NAMA_IDS="lab3-ids"
LOG_DIR="$(pwd)/log_ids"
ATURAN_DIR="$(pwd)/aturan_ids"
GAMBAR="jasonish/suricata:latest"

say() { printf '%s\n' "$*"; }

cari_bridge() {
  local net id
  net=$(docker network ls --filter "name=${JARINGAN}" --format '{{.Name}}' | head -1)
  if [[ -z "$net" ]]; then
    say "Jaringan '${JARINGAN}' tidak ditemukan. Nyalakan laboratorium dulu:"
    say "  docker compose -f docker-compose.yml -f docker-compose.pindai.yml up -d"
    exit 1
  fi
  id=$(docker network inspect -f '{{.Id}}' "$net")
  printf 'br-%s' "${id:0:12}"
}

mulai() {
  local br
  br=$(cari_bridge)
  say "Jaringan : ${JARINGAN}"
  say "Bridge   : ${br}"
  mkdir -p "$LOG_DIR"
  chmod 777 "$LOG_DIR" 2>/dev/null || true
  docker rm -f "$NAMA_IDS" >/dev/null 2>&1
  docker run -d --name "$NAMA_IDS" \
    --net=host \
    --cap-add=NET_RAW --cap-add=NET_ADMIN --cap-add=SYS_NICE \
    -v "${ATURAN_DIR}:/etc/suricata/rules" \
    -v "${LOG_DIR}:/var/log/suricata" \
    "$GAMBAR" -i "$br" -S /etc/suricata/rules/suricata_local.rules >/dev/null

  say "Menunggu mesin IDS siap..."
  for _ in $(seq 1 30); do
    sleep 2
    if grep -q "Engine started" "${LOG_DIR}/suricata.log" 2>/dev/null; then break; fi
  done

  if ! docker ps --filter "name=${NAMA_IDS}" --format '{{.Names}}' | grep -q "$NAMA_IDS"; then
    say "GAGAL: kontainer IDS tidak berjalan. Periksa:"
    say "  docker logs ${NAMA_IDS}"
    exit 1
  fi

  local gagal
  gagal=$(grep -c "error parsing" "${LOG_DIR}/suricata.log" 2>/dev/null)
  gagal=${gagal:-0}
  say "Aturan dimuat  : $(grep -o '[0-9]* rules successfully loaded' "${LOG_DIR}/suricata.log" 2>/dev/null | tail -1)"
  say "Aturan gagal   : ${gagal}   <-- harus 0; perbaiki sintaks bila tidak"
  say ""
  say "IDS menyala. Sekarang jalankan pemindaian dari kontainer admin:"
  say "  docker exec lab3-admin nmap -sS -p 1-3000 lab3-web"
  say "  docker exec lab3-admin nmap -sV -sC -p 80 lab3-web"
  say "lalu:  ./periksa_ids.sh ringkas"
}

ringkas() {
  local eve="${LOG_DIR}/eve.json"
  if [[ ! -f "$eve" ]]; then
    say "Belum ada ${eve}. Jalankan: ./periksa_ids.sh mulai"
    exit 1
  fi
  say "=== Alert yang benar-benar tercatat ==="
  if ! grep -q '"event_type":"alert"' "$eve" 2>/dev/null; then
    say "  (belum ada alert — jalankan pemindaian lebih dahulu)"
    exit 0
  fi
  grep -o '"signature":"[^"]*"' "$eve" | sort | uniq -c | sort -rn | \
    while read -r n s; do printf '  %-5s %s\n' "$n" "$s"; done
  say ""
  say "Simpan keluaran ini (dan ${LOG_DIR}/fast.log) sebagai bukti alert."
  say "Ini bukti NYATA: alert muncul karena lalu lintas pemindaian, bukan"
  say "karena berkas aturan tersimpan."
}

hentikan() {
  docker rm -f "$NAMA_IDS" >/dev/null 2>&1 && say "IDS dimatikan." || say "IDS tidak sedang berjalan."
}

case "${1:-mulai}" in
  mulai)    mulai ;;
  ringkas)  ringkas ;;
  hentikan) hentikan ;;
  *) say "Pakai: $0 {mulai|ringkas|hentikan}"; exit 2 ;;
esac
