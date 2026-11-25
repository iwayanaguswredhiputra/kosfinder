# Daftar Tugas Pengembangan KosFinder (TASKS.md)

Dokumen ini memuat rincian tugas terstruktur dalam bentuk *vertical slice* mengacu pada [PRD.md](file:///d:/flutter_project/kosfinder/docs/PRD.md), [ARCHITECTURE.md](file:///d:/flutter_project/kosfinder/docs/ARCHITECTURE.md), dan aturan [AGENTS.md](file:///d:/flutter_project/kosfinder/AGENTS.md).

Setiap slice menghasilkan aplikasi yang dapat dijalankan (*runnable*).

---

## Slice 1: Daftar dan Detail Kos (Public Read & Contact)
*Hasil akhir slice: Pengguna dapat membuka aplikasi, melihat daftar kos dari Supabase, membuka detail kos, menyalin kontak WA ke clipboard, dan melihat identitas pengembang di halaman About.*

| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T01 | Konfigurasi dependensi provider & supabase_flutter serta buat data model KosModel | US01-AC1 | `pubspec.yaml`, `lib/models/kos_model.dart` | `flutter test test/models/kos_model_test.dart` & `flutter analyze` | Selesai |
| T02 | Implementasi KosRepository untuk mengambil daftar kos dari Supabase dan menangani error koneksi | US01-AC1, US01-AC4 | `lib/repositories/kos_repository.dart` | `flutter test test/repositories/kos_repository_test.dart` & `flutter analyze` | Selesai |
| T03 | Implementasi KosProvider untuk mengelola state data kos, loading, dan pesan kesalahan | US01-AC1, US01-AC4 | `lib/providers/kos_provider.dart` | `flutter test test/providers/kos_provider_test.dart` & `flutter analyze` | Selesai |
| T04 | Implementasi KosListScreen untuk menampilkan daftar kartu kos dan tombol coba lagi saat gagal muat | US01-AC1, US01-AC4 | `lib/screens/kos_list_screen.dart`, `lib/widgets/kos_card.dart`, `lib/main.dart` | `flutter run` verifikasi kartu kos tampil di layar dan tombol coba lagi berfungsi | Selesai |
| T05 | Implementasi KosDetailScreen dengan informasi spesifikasi lengkap dan tombol salin nomor WhatsApp | US03-AC1, US03-AC2 | `lib/screens/kos_detail_screen.dart`, `lib/screens/kos_list_screen.dart` | `flutter test test/screens/kos_detail_screen_test.dart` & tap salin nomor lalu cek snackbar | Selesai |
| T06 | Implementasi AboutScreen menampilkan identitas developer (2415051007 - I Wayan Agus Wredhi Putra) | AGENTS.md Rule 7 | `lib/screens/about_screen.dart`, `lib/screens/kos_list_screen.dart` | `flutter run`, buka ikon Info di AppBar dan periksa kesesuaian teks identitas | Selesai |

---

## Slice 2: Pencarian dan Filter
*Hasil akhir slice: Pengguna dapat mencari kos berdasarkan nama area secara case-insensitive dan menyaring berdasarkan harga maksimal, tipe kos, serta checklist fasilitas.*

| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T07 | Implementasi logika filter dan pencarian area case-insensitive pada KosProvider | US01-AC2, US02-AC1 | `lib/providers/kos_provider.dart` | `flutter test test/providers/kos_search_filter_test.dart` & `flutter analyze` | Selesai |
| T08 | Implementasi kolom search bar area dan tampilan status kosong jika tidak ditemukan di KosListScreen | US01-AC2, US01-AC3 | `lib/screens/kos_list_screen.dart` | `flutter run`, ketik area di kolom pencarian dan verifikasi tampilan hasil / pesan kosong | Selesai |
| T09 | Implementasi modal filter (tipe kos, slider/input harga maksimal, checklist fasilitas) dan reset filter | US02-AC1, US02-AC2 | `lib/widgets/filter_modal.dart`, `lib/screens/kos_list_screen.dart` | `flutter run`, terapkan filter spesifik dan verifikasi hasil filter serta fungsi reset | Selesai |

---

## Slice 3: Login Pemilik
*Hasil akhir slice: Pemilik kos dapat mendaftarkan akun baru, login dengan email/password, melihat dashboard awal, dan logout.*

| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T10 | Implementasi AuthRepository untuk register, login, logout, dan memantau sesi auth Supabase | US04-AC1, US04-AC4 | `lib/repositories/auth_repository.dart` | `flutter test test/repositories/auth_repository_test.dart` & `flutter analyze` | Selesai |
| T11 | Implementasi AuthProvider untuk mengelola status autentikasi dan integrasikan di main.dart | US04-AC1, US04-AC2, US04-AC3, US04-AC4 | `lib/providers/auth_provider.dart`, `lib/main.dart` | `flutter test test/providers/auth_provider_test.dart` & `flutter analyze` | Selesai |
| T12 | Implementasi AuthScreen (tab Login dan Registrasi) dengan validasi form dan pesan error | US04-AC1, US04-AC2, US04-AC3 | `lib/screens/auth_screen.dart`, `lib/screens/kos_list_screen.dart`, `test/screens/auth_screen_test.dart` | `flutter test test/screens/auth_screen_test.dart` & `flutter analyze` | Selesai |
| T13 | Implementasi kerangka OwnerDashboardScreen dengan tombol logout dan pesan jika belum ada listing | US04-AC4, US06-AC4 | `lib/screens/owner_dashboard_screen.dart`, `lib/screens/auth_screen.dart` | `flutter test test/screens/auth_screen_test.dart test/screens/owner_dashboard_screen_test.dart`, `flutter analyze` | Selesai |

---

## Slice 4: Tambah, Ubah, Hapus Kos Milik Sendiri
*Hasil akhir slice: Pemilik kos dapat menerbitkan listing baru, memperbarui listing miliknya, dan menghapus listing dengan konfirmasi.*

| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T14 | Implementasi method tambah, ubah, dan hapus kos pada KosRepository & KosProvider | US05-AC1, US06-AC1, US06-AC2, US06-AC3 | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart` | `flutter test test/repositories/kos_crud_test.dart` & `flutter analyze` | Selesai |
| T15 | Implementasi KosFormScreen untuk tambah listing kos baru dengan validasi dan checklist fasilitas | US05-AC1, US05-AC2 | `lib/screens/kos_form_screen.dart`, `lib/screens/owner_dashboard_screen.dart` | `flutter test test/screens/kos_form_screen_test.dart test/screens/owner_dashboard_screen_test.dart`, `flutter analyze`, `flutter test` | Selesai |
| T16 | Implementasi mode edit pada KosFormScreen dan dialog konfirmasi hapus di OwnerDashboardScreen | US06-AC1, US06-AC2 | `lib/screens/owner_dashboard_screen.dart`, `lib/screens/kos_form_screen.dart` | `flutter test test/screens/kos_form_screen_test.dart test/screens/owner_dashboard_screen_test.dart`, `flutter analyze`, `flutter test` | Selesai |

---

## Slice 5 (Bonus): Ketersediaan Kamar
*Hasil akhir slice: Visualisasi ketersediaan kamar yang tegas dan pembaruan sisa kamar secara cepat.*

| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T17 | Implementasi badge ketersediaan kamar kontras tegas (Tersedia vs Penuh) di kartu dan detail kos | US03-AC1, NFR-USE-2 | `lib/widgets/kos_card.dart`, `lib/screens/kos_detail_screen.dart` | Widget test kartu dan detail memverifikasi badge hijau/merah berkontras; `flutter analyze`, `flutter test` | Selesai |
| T18 | Implementasi kontrol cepat pengubahan sisa kamar langsung dari OwnerDashboardScreen | US06-AC1 | `lib/screens/owner_dashboard_screen.dart`, `lib/providers/kos_provider.dart` | `flutter run`, kurangi kamar hingga 0 di dashboard dan verifikasi status langsung jadi Penuh | Pending |
