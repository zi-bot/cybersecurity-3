# BAB 3 — Perangkat Praktikum Laboratorium Tiga Zona

Pendamping **Praktikum 3 — Laboratorium Tiga Zona: Default-Deny, Simulasi Serangan,
dan IDS/IPS** pada `Modul_Ajar_Cyber_Security.docx`, BAB 3 (Pekan 5–6) dan bahan ajar
`Bahan_Ajar_Pekan_5-6_Pengamanan_Jaringan.docx`. Menopang Lampiran **Tugas 3 — Firewall
dan simulasi serangan–pertahanan jaringan** (rubrik **C2**, 10% nilai akhir).

Dosen menyediakan **berkas `docker-compose.yml`** sebagai titik awal. Mahasiswa
melengkapinya menjadi tiga zona, menerapkan *default-deny*, memindai subnet lab
sendiri, menambahkan aturan IDS/IPS yang benar-benar memicu, lalu membuktikan
permukaan serang menyusut.

---

## 1. Topologi Arsitektur Tiga Zona & Penempatan Sensor

Laboratorium ini merefleksikan arsitektur jaringan pertahanan berlapis (*defense-in-depth*):

```text
       [ Host / Laptop Mahasiswa ] (127.0.0.1:8080)
                   │
                   ▼ (Port forwarding loopback saja)
       ┌─────────────────────────────────────────────────────────┐
       │   zona-web (DMZ Bridge)                                 │
       │   ├── lab3-web (Nginx Frontend, port 80)                │
       │   │     ▲                                               │
       │   │     │ (Meneruskan request ke backend)               │
       │   └───┬─┴───────────────────────────────────────────┐   │
       │       │ SENSOR IDS (Suricata menyadap paket di sini)│   │
       └───────┼─────────────────────────────────────────────┼───┘
               │                                             │
       ┌───────┼─────────────────────────────────────────────┴───┐
       │       ▼ (Dual-Homed: jembatan logika tunggal yang sah)  │
       │   zona-data (Internal Data Bridge, internal: true)      │
       │   ├── lab3-app (Alpine API service)                     │
       │   └── lab3-db  (PostgreSQL Database, port 5432)         │
       │         ✕ (TIDAK ADA gateway keluar ke Internet)        │
       └─────────────────────────────────────────────────────────┘
       ┌─────────────────────────────────────────────────────────┐
       │   zona-admin (Admin Management Bridge)                  │
       │   └── lab3-admin (Terisolasi dari web & db)             │
       └─────────────────────────────────────────────────────────┘
```

Prinsip Utama:
1. **Pemisahan Tingkat Jaringan:** Kontainer `web` dan `db` tidak berbagi jaringan sama sekali. Nama host `db` bahkan tidak dapat diresolusi oleh DNS internal dari `web`.
2. **Dual-Homed Application:** Hanya `app` yang berada pada `zona-web` dan `zona-data`. Kontainer `app` adalah satu-satunya gerbang menuju basis data.
3. **Default-Deny via `internal: true`:** Jaringan `zona-data` tidak memiliki rute default ke Internet luar, memutus jalur eksfiltrasi data secara mutlak.
4. **Posisi Sensor IDS:** Suricata menyadap antarmuka bridge `zona-web`. Sensor hanya dapat mendeteksi lalu lintas yang melintasi bridge tersebut.

---

## 2. Isi Folder

```
BAB3_Lab_Jaringan_Tiga_Zona/
├── README.md                       ← panduan praktikum (boleh dibagikan)
├── docker-compose.yml              ← KERANGKA dari dosen (dua zona)
├── docker-compose.pindai.yml       ← override sementara untuk fase pemindaian
├── periksa_zona.sh                 ← lima uji segmentasi (lintas platform)
├── periksa_ids.sh                  ← jalankan Suricata pada bridge lab
├── validate_submission.py          ← validasi mandiri laporan sebelum dikumpulkan
├── matriks_akses_template.md       ← matriks akses + ruang pengukuran
├── laporan_template.md             ← kerangka laporan terstruktur (Rubrik C2)
├── daftar_periksa.md               ← daftar periksa langkah praktikum
├── aturan_ids/
│   ├── suricata_local.rules        ← 5 aturan awal (SUDAH DIUJI memicu)
│   ├── README.md                   ← panduan Suricata vs fail2ban
│   ├── fail2ban_jail.local         ← konfigurasi jail fail2ban (bebas bug ignoreip)
    └── fail2ban_filter_lab3.conf   ← filter regex probe fail2ban

```

## Yang dibagikan ke mahasiswa

Seluruh berkas dan folder **kecuali** folder `INSTRUCTOR/`.

---

## 3. Penyiapan (Dosen, sekali saja sebelum praktikum)

```bash
cd BAB3_Lab_Jaringan_Tiga_Zona
docker pull nginx:alpine
docker pull alpine:latest
docker pull postgres:16-alpine
docker pull jasonish/suricata:latest     # untuk periksa_ids.sh
docker compose config --quiet            # pastikan berkas sah
```

---

## 4. Alur Kerja Mahasiswa

| Langkah modul | Perintah inti |
|---|---|
| 1 — siapkan lab | lengkapi `docker-compose.yml` menjadi tiga zona; `docker compose up -d` |
| 2 — buktikan segmentasi | `./periksa_zona.sh` |
| 3 — matriks akses | lengkapi `matriks_akses_template.md` beserta alasan tiap Deny |
| 4 — default-deny | hapus `internal: true`, jalankan ulang, bandingkan **uji 5 (db → Internet)** |
| 5 — fase serangan | `docker compose -f docker-compose.yml -f docker-compose.pindai.yml up -d` lalu `docker exec lab3-admin nmap -sS -p 1-3000 lab3-web` |
| 6 — IDS/IPS | `./periksa_ids.sh mulai` → pindai → `./periksa_ids.sh ringkas` |
| 7 — uji ulang | pindai ulang, isi tabel sebelum/sesudah di `laporan_template.md` |
| 8 — tangkap lalu lintas | `docker run --rm --net=host --cap-add=NET_RAW nicolaka/netshoot tcpdump -i any -c 20 -nn port 5432` |
| 9 — rencana pemulihan | kembalikan lab ke status isolasi bersih, susun rencana rollback |
| 10 — validasi | `python3 validate_submission.py` |

---

## 5. Hasil Pengukuran Terverifikasi (Docker 29.x)

Lima uji segmentasi pada keadaan tiga zona yang benar:

```text
web   -> db:5432   TERTUTUP    (tidak ada jaringan bersama; DNS gagal resolusi)
app   -> db:5432   TERBUKA     (satu-satunya jalur sah ke data)
admin -> db:5432   TERTUTUP    (zona admin terisolasi)
host  -> db:5432   TERTUTUP    (port basis data tidak dipublikasikan ke host)
db    -> Internet  GAGAL       (internal: true memblokir koneksi keluar)
```

Alert IDS nyata yang tercatat saat `nmap -sS -p 1-3000 lab3-web` dijalankan:

```text
402  LAB3 Pemindaian port terdeteksi (SYN masif)          sid 1000001
150  LAB3 Percobaan koneksi berulang (indikasi brute force) sid 1000005
 29  LAB3 Nmap Scripting Engine (NSE) terdeteksi          sid 1000002
 29  LAB3 Probe HTTP tanpa User-Agent (nmap)              sid 1000003
```

---

## 6. Eksperimen Mendalam: Simulasi Eksfiltrasi Data & Titik Buta Sensor

### A. Bahaya Nyata Ketiadaan Default-Deny (Eksfiltrasi Data)
Pada Langkah 4, uji `db -> Internet` bukan sekadar tes koneksi web biasa. Uji ini membuktikan pencegahan **eksfiltrasi data curian**:
- Saat `internal: true` **dihapus**, penyerang yang berhasil menyusup ke database dapat mengeksfiltrasi data sensitif secara langsung ke server penyerang di Internet:
  ```bash
  # Uji eksfiltrasi data saat internal: true dihapus (BERHASIL)
  docker exec lab3-db sh -c "wget -qO- -T3 'http://example.com' && echo 'DATA BERHASIL DIEKSFILTRASI KE LUAR!'"
  ```
- Saat `internal: true` **diterapkan**, upaya koneksi keluar langsung diblokir (*connection timed out*), menggagalkan komunikasi C2 (*Command & Control*).

### B. Titik Buta Sensor (*Sensor Blind Spot*)
Suricata pada `periksa_ids.sh` dipasang pada bridge `zona-web`.
- Jika Anda menjalankan pemindaian dari `admin` ke `web`, alert IDS tercatat banyak (sid 1000001, 1000002).
- Namun jika Anda melakukan koneksi dari `app` ke `db` (`zona-data`), **tidak ada alert yang muncul pada IDS `zona-web`**.
- **Pelajaran Keamanan:** IDS bersifat pasif dan hanya mendeteksi paket yang melintasi kabel/antarmuka yang disadapnya. Mengamankan jaringan internal membutuhkan sensor tambahan di segmen *East-West traffic* (`zona-data`).

---

## 7. Panduan Pemecahan Masalah Cepat (*Troubleshooting Guide*)

| Gejala Uji | Kemungkinan Penyebab | Tindakan Perbaikan |
|---|---|---|
| `admin -> db` terbaca **TERBUKA** | Override pemindaian `docker-compose.pindai.yml` masih aktif | Matikan override: `docker compose -f docker-compose.yml -f docker-compose.pindai.yml down`, lalu jalankan `docker compose up -d`. |
| `app -> db` terbaca **TERTUTUP** | Kontainer `app` belum dimasukkan ke `zona-data` | Periksa blok `networks:` pada kontainer `app`, pastikan memuat kedua jaringan: `[zona-web, zona-data]`. |
| `periksa_zona.sh` error `kontainer tidak berjalan` | Penamaan kontainer berbeda dengan standar | Pastikan nama kontainer pada compose sesuai instruksi: `lab3-web`, `lab3-app`, `lab3-db`, `lab3-admin`. |
| Suricata keluar seketika / log kosong | Izin tulis folder log atau mount `:ro` | Jalankan `chmod 777 log_ids/` dan pastikan mount aturan tidak memakai opsi read-only `:ro`. |
| `fail2ban` tidak memblokir serangan | Menggunakan konfigurasi lama dengan `ignoreip` subnet Docker | Pastikan memakai berkas `fail2ban_jail.local` terbaru yang tidak memuat `172.16.0.0/12` pada `ignoreip`. |

---

## Batas yang Tidak Boleh Dilanggar

- Hanya pada **kontainer/VM milik Anda sendiri**. Pemindaian hanya pada subnet lab Anda sendiri.
- Dilarang memindai jaringan kampus, alamat publik, layanan pihak ketiga, atau sistem milik orang lain — meskipun hanya mencoba.
- Port `web` diikat ke `127.0.0.1` agar lab tidak terekspos ke jaringan kampus. Jangan mengubahnya menjadi `0.0.0.0`.
- Jangan menuliskan kredensial apa pun ke laporan — **termasuk yang dummy**.
- Suricata dipasang **hanya** pada antarmuka bridge laboratorium, sehingga lalu lintas rumah/kampus Anda tidak ikut dianalisis.
