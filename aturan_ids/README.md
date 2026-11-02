# Alternatif fail2ban — Praktikum 3 (BAB 3)

Modul mengizinkan salah satu dari **Suricata, Snort, atau fail2ban**.
Jalur yang **sudah diuji** pada kit ini adalah **Suricata** (lihat `periksa_ids.sh`).
Berkas di folder ini adalah jalur alternatif bila Anda lebih memilih fail2ban.

## Perbedaan pendekatan

| | Suricata | fail2ban |
|---|---|---|
| Sumber bukti | Menyadap paket di antarmuka bridge lab | Membaca **berkas log** layanan |
| Perlu | `NET_RAW` + `NET_ADMIN` | Berkas log yang benar-benar ditulis ke disk |
| Keluaran | `eve.json` / `fast.log` berisi alert | Aturan ban pada `iptables`/`nftables` |
| Cocok untuk | Membuktikan pemindaian terdeteksi | Membuktikan percobaan berulang diblokir |

## Prasyarat yang harus Anda siapkan sendiri

fail2ban **tidak** bisa bekerja tanpa sumber log. Citra `nginx:alpine` resmi
menulis log ke stdout, bukan ke berkas. Karena itu, agar jalur ini berjalan
Anda perlu lebih dahulu membuat berkas log yang nyata, misalnya dengan
menambahkan konfigurasi nginx:

```nginx
# /etc/nginx/conf.d/default.conf (di dalam kontainer web)
access_log /var/log/nginx/access.log combined;
```

lalu memasang volume agar berkas itu terlihat oleh fail2ban. Bila langkah ini
belum Anda lakukan, fail2ban akan berjalan tanpa pernah memicu apa pun — dan
itu **bukan** bukti yang sah.

## Pemakaian

```bash
# 1. Pastikan /var/log/lab3/access.log benar-benar terisi:
docker exec lab3-web sh -c "wget -qO- http://localhost/ >/dev/null; tail -1 /var/log/nginx/access.log"

# 2. Jalankan fail2ban dengan filter dan jail di bawah:
docker run -d --name lab3-fail2ban --net=host --cap-add=NET_ADMIN \
  -v "$PWD/aturan_ids/fail2ban_jail.local:/etc/fail2ban/jail.local:ro" \
  -v "$PWD/aturan_ids/fail2ban_filter_lab3.conf:/etc/fail2ban/filter.d/lab3-probe.conf:ro" \
  -v /var/log/lab3:/var/log/lab3:ro \
  crazymax/fail2ban:latest

# 3. Picu percobaan berulang, lalu periksa status ban:
for i in $(seq 1 12); do
  docker exec lab3-admin sh -c "nc -z -w1 lab3-web 80 >/dev/null 2>&1"
done
docker exec lab3-fail2ban fail2ban-client status lab3-probe
```

## Kejujuran hasil

Jalur fail2ban ini **belum diuji** pada mesin dosen, karena memerlukan
penyesuaian log nginx lebih dahulu. Bila Anda memilihnya, simpan keluaran
`fail2ban-client status` sebagai bukti — dan pastikan jumlah ban bertambah
setelah percobaan berulang dijalankan. Bila tidak bertambah, berarti
lingkup/jail Anda belum tepat; perbaiki sebelum melaporkan.
