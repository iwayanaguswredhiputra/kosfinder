# KosFinder

KosFinder membantu pencari kos menemukan dan membandingkan kos bulanan, serta
membantu pemilik mengelola listing kos melalui Supabase.

Rilis ini menargetkan **v0.1.0** dengan cakupan MVP versi 1.

## Fitur

- Jelajahi daftar kos dan cari berdasarkan nama area/alamat.
- Filter berdasarkan harga maksimal, tipe kos, dan fasilitas.
- Lihat detail kos, ketersediaan kamar, serta salin nomor WhatsApp pemilik.
- Daftar dan masuk sebagai pemilik untuk menambah, mengubah, dan menghapus
  listing milik sendiri.
- Kebijakan akses listing pemilik dilindungi Row Level Security (RLS) di
  Supabase.

## Persiapan

- Flutter SDK yang sesuai dengan batas SDK pada `pubspec.yaml`.
- Proyek Supabase dengan skema dan izin dari migrasi
  `supabase/migrations/001_init.sql` dan `supabase/migrations/002_grant_permissions.sql`
  yang sudah diterapkan.
- URL proyek Supabase dan **anon/public key**. Jangan gunakan `service_role` key.

Ambil URL dan anon key dari pengaturan proyek Supabase. Masukkan nilai milik
sendiri saat menjalankan aplikasi; nilai contoh di bawah hanyalah placeholder,
bukan kredensial yang dapat digunakan:

```shell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Jangan menyimpan key, password, atau kredensial proyek di README, source
control, maupun riwayat commit. Fitur autentikasi dan pengelolaan listing
memerlukan konfigurasi Supabase yang valid.

## Pengujian

```shell
flutter analyze
flutter test
```

## Batasan cakupan versi 1

Versi 1 berfokus pada pencarian kos, kontak pemilik, dan pengelolaan listing
dasar. Versi ini belum mencakup:

- Pembayaran atau transaksi sewa di aplikasi.
- Chat langsung atau membuka aplikasi WhatsApp; kontak hanya dapat disalin.
- Foto kos, peta, atau geolokasi.
- Ulasan, rating, rekomendasi otomatis, atau verifikasi identitas pemilik.
- Reset password, draft/nonaktifkan listing, pengelolaan banyak kamar per
  listing, atau profil pemilik terpisah.
