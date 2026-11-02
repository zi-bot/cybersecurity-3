# Laporan Praktikum 3 — Laboratorium Tiga Zona, Default-Deny, dan IDS/IPS

## 1. Identitas Mahasiswa

| Informasi | Keterangan |
|---|---|
| Nama Lengkap | <Nama Lengkap Mahasiswa> |
| NIM | <NIM Mahasiswa> |
| Kelas | <Kelas Cyber Security> |
| Tanggal Pelaksanaan | <DD-MM-YYYY> |
| Sistem Operasi Host | <Sistem Operasi Host> |
| Versi Docker & Compose | <Versi Docker & Docker Compose> |

---

## 2. Ketepatan Hasil (35 poin)

### 2.1 Bukti Segmentasi Lima Uji (Langkah 2)

Keluaran `./periksa_zona.sh` pada keadaan tiga zona terisolasi:

```text
(tempelkan seluruh keluaran ./periksa_zona.sh di sini)
```

### 2.2 Matriks Akses Tiga Zona (Langkah 3)

Lengkapi tabel matriks akses berikut beserta alasan teknis untuk setiap baris penolakan (prinsip *default-deny*):

| Sumber | Tujuan | Port | Protokol | Izin | Alasan Teknis |
|---|---|---|---|---|---|
| Internet | web | 80/443 | TCP | Ya | Melayani akses pengguna publik ke frontend |
| web | app | 8080 | TCP | Ya | Meneruskan permintaan pengguna ke backend lapisan bisnis |
| app | db | 5432 | TCP | Ya | Lapisan aplikasi memerlukan koneksi data operasional |
| web | db | 5432 | TCP | Tidak | <alasan teknis penolakan> |
| Internet | db | 5432 | TCP | Tidak | <alasan teknis penolakan> |
| app | Internet | – | – | Tidak | <alasan teknis penolakan> |
| admin | web | 80 | TCP | Tidak | <alasan teknis penolakan> |
| admin | app | – | – | Tidak | <alasan teknis penolakan> |
| admin | db | 5432 | TCP | Tidak | <alasan teknis penolakan> |
| db | Internet | – | – | Tidak | <alasan teknis penolakan> |
| web | Internet | – | – | Tidak | <alasan teknis penolakan> |

### 2.3 Pemindaian Permukaan Serang Awal (Langkah 5)

Hasil pemindaian subnet dengan Nmap dari kontainer `admin`:

| Port Target | Layanan | Status | Versi / Keterangan | Sumber Bukti |
|---|---|---|---|---|
| <port> | <layanan> | <status> | <keterangan layanan> | <perintah nmap yang dijalankan> |

```text
(tempelkan ringkasan atau bukti teks hasil pemindaian nmap di sini)
```

---

## 3. Metode & Pengamanan (25 poin)

### 3.1 docker-compose.yml Tiga Zona (Langkah 1)

Tempelkan berkas konfigurasi `docker-compose.yml` lengkap hasil penambahan jaringan `zona-admin` dan kontainer `admin`:

```yaml
(tempelkan isi docker-compose.yml lengkap Anda di sini)
```

### 3.2 Penjelasan Peran Segmentasi Aplikasi & Isolasi Admin

<uraian penjelasan mengapa kontainer app berada di dua jaringan, peran isolasi admin, dan loopback binding 127.0.0.1>

---

## 4. Verifikasi & Batasan (25 poin)

### 4.1 Uji Perbandingan Default-Deny (Langkah 4)

Tabel perbandingan hasil uji `./periksa_zona.sh` dengan dan tanpa `internal: true`:

| Indikator Uji | Dengan `internal: true` | Tanpa `internal: true` | Berubah? | Dampak Keamanan |
|---|---|---|---|---|
| 1. web → db:5432 | TERTUTUP | TERTUTUP | Tidak | Isolasi jaringan tetap memisahkan namespace |
| 2. app → db:5432 | TERBUKA | TERBUKA | Tidak | Akses aplikasi sah tidak terganggu |
| 3. admin → db:5432 | TERTUTUP | TERTUTUP | Tidak | Isolasi manajemen tetap tegak |
| 4. host → db:5432 | TERTUTUP | TERTUTUP | Tidak | Port basis data tetap tidak terikat ke host |
| 5. db → Internet | GAGAL | BERHASIL | YA | Jalur eksfiltrasi terbuka keluar |

### 4.2 Bukti Alert IDS/IPS Nyata (Langkah 6)

Keluaran ringkasan event alert yang benar-benar tercatat di `eve.json` / `fast.log`:

```text
(tempelkan keluaran ./periksa_ids.sh ringkas atau fast.log di sini)
```

### 4.3 Aturan Deteksi Tambahan Karya Mandiri

Aturan deteksi custom Suricata dengan SID 1000100 ke atas:

```text
<tuliskan aturan suricata buatan Anda sendiri di sini>
```

### 4.4 Rencana Pemulihan Konfigurasi (Rollback Plan)

<tuliskan langkah dan perintah pemulihan kembali ke tiga zona terisolasi di sini>

---

## 5. Penjelasan Individu (15 poin)

Tuliskan analisis komprehensif dengan kalimat Anda sendiri:
1. Mengapa penghapusan `internal: true` **hanya** mengubah uji `db -> Internet`, sedangkan uji `web -> db` tetap tertutup?
2. Bagaimana `internal: true` menggagalkan skenario eksfiltrasi data curian atau reverse shell oleh penyerang?
3. Mengapa penempatan sensor IDS pada jembatan `zona-web` menimbulkan titik buta (*sensor blind spot*) terhadap lalu lintas internal (`app -> db`), dan apa sisa batasan operasional segmentasi berbasis kontainer ini?

```text
(tulis analisis mendalam Anda di sini)
```
