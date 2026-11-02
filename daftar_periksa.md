# Daftar Periksa — Praktikum 3 (BAB 3)

Centang setiap butir **sebelum** mengumpulkan. Butir bertanda **[wajib]** masuk
langsung ke penilaian rubrik C2.

## Persiapan

- [ ] `docker --version` dan `docker compose version` berjalan
- [ ] Keempat citra tersedia: `nginx:alpine`, `alpine:latest`,
      `postgres:16-alpine`, `jasonish/suricata:latest`
- [ ] `docker compose config --quiet` tidak mengeluarkan galat
- [ ] `lembar_izin_laboratorium.md` (folder `00_Lintas_BAB/`) sudah ditandatangani

## Arsitektur

- [ ] `docker-compose.yml` sudah dilengkapi menjadi **tiga** jaringan:
      `zona-web`, `zona-data`, `zona-admin` **[wajib]**
- [ ] Ada **empat** kontainer: `web`, `app`, `db`, `admin` **[wajib]**
- [ ] `zona-data` memakai `internal: true` **[wajib]**
- [ ] `admin` hanya berada di `zona-admin` **[wajib]**
- [ ] Port `web` tetap terikat `127.0.0.1` (tidak diubah ke `0.0.0.0`)

## Bukti segmentasi

- [ ] `./periksa_zona.sh` dijalankan dan keluarannya disimpan
- [ ] `web -> db` terbukti TERTUTUP **[wajib]**
- [ ] `app -> db` terbukti TERBUKA **[wajib]**
- [ ] `admin -> db` terbukti TERTUTUP **[wajib]**
- [ ] Matriks akses lengkap, setiap baris "Tidak" punya alasan **[wajib]**

## Default-deny

- [ ] Perbandingan dengan/tanpa `internal: true` sudah diukur **[wajib]**
- [ ] Anda dapat menjelaskan mengapa **hanya `db -> Internet`** yang berubah
- [ ] Anda dapat menjelaskan mengapa `web -> db` tetap TERTUTUP pada kedua keadaan

## Fase serangan dan IDS/IPS

- [ ] Pemindaian hanya menyasar subnet lab sendiri **[wajib]**
- [ ] Keluaran `nmap -sS -p-` dan `nmap -sV -sC` tersimpan sebagai bukti
- [ ] Tabel permukaan serang sebelum/sesudah terisi **[wajib]**
- [ ] Minimal **satu alert IDS/IPS benar-benar tercatat** **[wajib]**
- [ ] Ada minimal satu aturan IDS tambahan karya Anda sendiri
- [ ] Tidak ada baris `E: detect: error parsing` pada log IDS

## Tangkapan paket

- [ ] Bukti tangkapan paket untuk koneksi diizinkan tersimpan
- [ ] Bukti tangkapan paket untuk koneksi ditolak tersimpan

## Kebersihan dan keamanan

- [ ] **Tidak ada kredensial** tertulis di laporan, termasuk yang dummy **[wajib]**
- [ ] Override pemindaian sudah dihapus; lab kembali ke tiga zona terisolasi **[wajib]**
- [ ] IDS dimatikan (`./periksa_ids.sh hentikan`)
- [ ] `docker compose down --volumes --remove-orphans` dijalankan
- [ ] `docker ps -a --filter name=lab3` kosong
- [ ] Rencana pemulihan konfigurasi tersedia **[wajib]**
- [ ] Satu kelemahan rancangan sendiri disebutkan beserta perbaikannya **[wajib]**

## Bila sesuatu gagal

| Gejala | Kemungkinan penyebab | Tindakan |
|---|---|---|
| `docker compose up` gagal, nama kontainer bentrok | Sisa sesi sebelumnya | `docker compose down --remove-orphans` |
| `nc: bad address 'db'` dari `app` | `app` tidak berada di `zona-data` | periksa blok `networks:` pada `app` |
| `nmap: not found` di kontainer admin | Paket belum terpasang | tunggu instalasi selesai; tambahkan `nmap-scripts` |
| `NSE: failed to initialize` | `nmap-scripts` belum dipasang | `apk add nmap-scripts` |
| Suricata keluar seketika | Mount aturan `:ro` memblokir `chown` pada entrypoint | lepas penanda `:ro` |
| Suricata tidak mencatat apa pun | Antarmuka salah, atau pemindaian tidak menyentuh bridge itu | periksa `Bridge:` dari `periksa_ids.sh mulai` |
| `E: detect: error parsing` | Titik koma di dalam `content` tidak ditulis `\;` | perbaiki sintaks, jalankan ulang |
| fail2ban tidak pernah memban | `logpath` belum benar-benar ditulis | lihat `aturan_ids/README.md` |
