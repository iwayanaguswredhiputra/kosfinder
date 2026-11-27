# Arsitektur Aplikasi KosFinder (v1)

Dokumen ini mendefinisikan arsitektur sistem, komponen aplikasi, skema database, konfigurasi, dan alur rilis KosFinder MVP sesuai [PRD.md](file:///d:/flutter_project/kosfinder/docs/PRD.md) dan [AGENTS.md](file:///d:/flutter_project/kosfinder/AGENTS.md).

---

## 1. Komponen Aplikasi & Pola Desain

Aplikasi menerapkan pola arsitektur berlapis: **Screen $\rightarrow$ Provider $\rightarrow$ Repository $\rightarrow$ Supabase Client**.

```
[Screen (UI)] <---> [Provider (State)] <---> [Repository (Data)] <---> [Supabase Backend]
```

| Lapisan / Komponen | Peran & Tanggung Jawab | Story Terkait |
| :--- | :--- | :--- |
| **Screen (UI)** | Menampilkan tampilan antarmuka, menerima input pengguna, menampilkan umpan balik (Snackbar/Dialog), dan menangani navigasi antar layar. | US01, US02, US03, US04, US05, US06, About |
| **Provider (State)** | Mengelola state aplikasi (pencarian, filter, status auth, form), memanggil repository, dan memperbarui UI secara reaktif via `ChangeNotifier`. | US01, US02, US03, US04, US05, US06 |
| **Repository (Data)** | Abstraksi akses data, menangani pemetaan model Dart (`KosModel`) $\leftrightarrow$ data Supabase, serta penanganan error jaringan. | US01, US02, US03, US04, US05, US06 |
| **Supabase Client** | Menangani sesi autentikasi pengguna (`GoTrueClient`) dan kueri PostgreSQL via REST API (`PostgrestClient`). | US01 - US06 |

---

## 2. Daftar Layar & Alur Navigasi

Navigasi menggunakan `Navigator` bawaan Flutter (declarative/named route sederhana tanpa package tambahan):

1. **`KosListScreen`** (US01, US02): Beranda pencari kos dengan kolom pencarian area, tombol filter (bottom sheet/dialog), indikator jumlah total kos yang sesuai saat filter aktif (US02-AC3), dan daftar kartu kos.
2. **`KosDetailScreen`** (US03): Menampilkan spesifikasi kos, fasilitas, status kamar (Tersedia/Penuh), dan tombol salin nomor WhatsApp ke *clipboard* (menggunakan `Clipboard` dari `flutter/services.dart`).
3. **`AuthScreen`** (US04): Tab login & registrasi email/password untuk pemilik kos.
4. **`OwnerDashboardScreen`** (US04, US06): Menampilkan daftar listing milik akun terautentikasi dan opsi kelola (ubah, hapus, logout).
5. **`KosFormScreen`** (US05, US06): Formulir tambah atau edit data kos beserta checklist fasilitas dan validasi input.
6. **`AboutScreen`** (Aturan AGENTS.md): Menampilkan informasi developer: `2415051007 - I Wayan Agus Wredhi Putra`.

### Alur Navigasi:
- **Pencari Kos:** `KosListScreen` $\rightarrow$ (Tap Card) $\rightarrow$ `KosDetailScreen`.
- **Informasi Developer:** `KosListScreen` (Ikon Info AppBar) $\rightarrow$ `AboutScreen`.
- **Pemilik Kos (Masuk):** `KosListScreen` (Ikon Akun AppBar) $\rightarrow$ `AuthScreen` $\rightarrow$ `OwnerDashboardScreen`.
- **Pemilik Kos (Kelola Kos):** `OwnerDashboardScreen` $\rightarrow$ (FAB Tambah / Tombol Edit) $\rightarrow$ `KosFormScreen` $\rightarrow$ Simpan/Kembali $\rightarrow$ `OwnerDashboardScreen`.
- **Pemilik Kos (Keluar):** `OwnerDashboardScreen` $\rightarrow$ Logout $\rightarrow$ `KosListScreen`.

---

## 3. Rencana Database & Aturan Akses (RLS)

Backend menggunakan database PostgreSQL di Supabase.

### Skema Tabel: `kos`

| Kolom | Tipe Data | Keterangan & Batasan | Story |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | Primary Key, `DEFAULT gen_random_uuid()` | US01 - US06 |
| `owner_id` | `UUID` | Foreign Key ke `auth.users(id)` ON DELETE CASCADE | US04 - US06 |
| `name` | `TEXT` | Nama kos (NOT NULL) | US01, US03, US05 |
| `area` | `TEXT` | Nama area/alamat kos (NOT NULL) | US01, US03, US05 |
| `price` | `BIGINT` | **Harga bulanan bertipe angka** (NOT NULL, `CHECK (price >= 0)`) | US01, US02, US05 |
| `type` | `TEXT` | `CHECK (type IN ('Putra', 'Putri', 'Campur'))` | US01, US02, US05 |
| `facilities` | `TEXT[]` | Array string checklist fasilitas (NOT NULL, `DEFAULT '{}'`) | US02, US03, US05 |
| `rooms_available`| `INTEGER`| Jumlah sisa kamar (NOT NULL, `CHECK (rooms_available >= 0)`) | US01, US03, US05, US06 |
| `contact_name` | `TEXT` | Nama kontak pemilik (NOT NULL) | US03, US05 |
| `contact_phone`| `TEXT` | Nomor kontak WhatsApp (NOT NULL) | US03, US05 |
| `created_at` | `TIMESTAMPTZ`| Waktu pembuatan, `DEFAULT now()` | US01 |
| `updated_at` | `TIMESTAMPTZ`| Waktu update terakhir, `DEFAULT now()` | US06 |

### Aturan Akses Data (Row Level Security / RLS)

RLS diaktifkan penuh pada tabel `kos`:
- **SELECT (Melihat):** Publik (siapa saja, anon dan authenticated) diizinkan membaca seluruh data listing kos (`USING (true)`). *(US01, US02, US03, US06)*
- **INSERT (Menambah):** Hanya pengguna login yang menambahkan data atas namanya sendiri (`auth.uid() = owner_id`). *(US05)*
- **UPDATE (Mengubah):** Hanya pemilik yang berhak mengubah listing miliknya (`auth.uid() = owner_id`). *(US06)*
- **DELETE (Menghapus):** Hanya pemilik yang berhak menghapus listing miliknya (`auth.uid() = owner_id`). *(US06)*

---

## 4. Konfigurasi Kredensial

Sesuai aturan keamanan tanpa hardcoded secret:
- Kredensial dibaca saat inisialisasi aplikasi via `String.fromEnvironment`:
  ```dart
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  ```
- Eksekusi lokal dan pengujian dijalankan dengan menyertakan argumen `--dart-define`:
  ```bash
  flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
  ```

---

## 5. Cara Rilis

1. **Build APK Release:**
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://xyz.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
   Output biner berada di: `build/app/outputs/flutter-apk/app-release.apk`.
2. **GitHub Release:**
   - Buat tag versi Git (misal: `v1.0.0`).
   - Buat Release baru di repositori GitHub dengan melampirkan file `app-release.apk` dan catatan rilis (Changelog MVP).

---

## 6. Daftar Package Eksternal yang Dibutuhkan

Mempertahankan kesederhanaan (*Keep It Simple*) dengan hanya menggunakan 2 dependensi utama:

| Package | Alasan Kebutuhan | Story Terkait |
| :--- | :--- | :--- |
| **`provider`** | State management standar dan reaktif untuk memisahkan UI dan business logic (AuthProvider, KosProvider). | US01 - US06 |
| **`supabase_flutter`** | SDK resmi Supabase untuk autentikasi pemilik kos (email/password) dan operasi CRUD database dengan proteksi RLS. | US01 - US06 |

*Catatan: Fitur salin kontak (US03) tidak membutuhkan package tambahan, cukup menggunakan `Clipboard` bawaan Flutter SDK (`flutter/services.dart`).*

---

## 7. Keputusan

### K1: Otorisasi Data melalui Row Level Security (RLS) Supabase
- **Alasan:** Penegakan hak akses langsung di level database menjamin keamanan data terpusat dan mencegah manipulasi tidak sah dari sisi klien.
- **Konsekuensi:** Aturan akses untuk operasi INSERT, UPDATE, dan DELETE wajib dikonfigurasi melalui kebijakan RLS di Supabase, serta pengujian mutasi data memerlukan sesi autentikasi pengguna yang valid.

### K2: State Management Menggunakan Provider
- **Alasan:** Provider merupakan solusi manajemen state yang sederhana, efisien untuk skala MVP, serta memisahkan logika bisnis dari antarmuka tanpa boilerplate berlebih.
- **Konsekuensi:** Pembaruan UI bergantung pada `ChangeNotifier` dan struktur widget tree yang perlu ditata dengan cermat agar menghindari rebuild yang tidak diperlukan.

### K3: Penyaringan Data di Sisi Klien Setelah Pengambilan Daftar Kos
- **Alasan:** Volume data pada tahap MVP relatif kecil sehingga pemfilteran di sisi klien memberikan respons pencarian instan tanpa perlu melakukan kueri berulang ke server.
- **Konsekuensi:** Seluruh data kos publik dimuat ke memori perangkat di awal, dan mekanisme ini harus dimigrasikan ke kueri server atau paginasi jika volume data meningkat secara signifikan.

### K4: Konfigurasi Kredensial melalui `--dart-define`
- **Alasan:** Pendekatan ini mencegah kebocoran kredensial sensitif di repositori kode sumber sesuai prinsip *no hardcoded secrets* dengan menyuntikkan nilai saat proses kompilasi.
- **Konsekuensi:** Perintah *run*, *test*, dan *build* wajib menyertakan parameter `--dart-define` yang sesuai agar aplikasi dapat menginisialisasi koneksi ke Supabase.
