# Matriks Akses — Praktikum 3 (BAB 3)

Isi tabel ini **sebelum** menulis aturan apa pun. Prinsipnya: **tolak semua,
izinkan seperlunya** (default-deny).

Setiap baris "Tidak" **wajib** punya alasan. Aturan tanpa alasan akan dihapus
saat audit. Tiga baris pertama sudah diisi sebagai contoh; lanjutkan sisanya.

| Sumber | Tujuan | Port | Protokol | Izin | Alasan |
|---|---|---|---|---|---|
| Internet | web | 80/443 | TCP | Ya | Melayani pengguna |
| web | app | 8080 | TCP | Ya | Meneruskan permintaan |
| app | db | 5432 | TCP | Ya | Hanya lapisan aplikasi boleh akses data |
| web | db | 5432 | TCP | Tidak | Melewati lapisan aplikasi |
| Internet | db | 5432 | TCP | Tidak | Basis data tidak boleh terekspos |
| app | Internet | – | – | Tidak | Mencegah eksfiltrasi data |
| admin | web | 80 | TCP | | |
| admin | app | – | – | | |
| admin | db | 5432 | TCP | | |
| db | Internet | – | – | | |
| web | Internet | – | – | | |

## Pertanyaan yang harus Anda jawab di laporan

1. Baris mana yang **tidak dapat** ditegakkan hanya dengan `internal: true`
   dan pemisahan jaringan Docker? Mengapa?
2. Untuk baris `admin → db`, apa alasan Anda mengizinkan atau menolaknya?
   Kaitkan dengan prinsip hak akses paling sedikit (*least privilege*).
3. Bila `zona-data` dijalankan **tanpa** `internal: true`, baris mana yang
   berubah statusnya? Buktikan dengan keluaran perintah.

## Ruang untuk catatan

Catat di sini hasil pengukuran Anda (sebelum/sesudah) agar mudah dipindahkan ke
tabel permukaan serang di laporan.

| Uji | Sebelum | Sesudah | Perintah pembuktian |
|---|---|---|---|
| web → db:5432 | | | `docker compose exec web sh -c "nc -zv db 5432 \|\| echo TERTUTUP"` |
| app → db:5432 | | | `docker compose exec app sh -c "nc -zv db 5432 && echo TERBUKA"` |
| host → db:5432 | | | `nc -zv <ip-db> 5432` |
| db → Internet | | | `docker compose exec db sh -c "wget -qO- -T3 http://example.com \|\| echo GAGAL"` |
