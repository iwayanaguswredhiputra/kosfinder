# Panduan Kerja Agen AI (AGENTS.md)

Dokumen ini berisi aturan kerja dan pedoman standar bagi agen AI yang berkontribusi pada pengembangan proyek **KosFinder**.

---

## 1. Konteks Proyek & Dokumen Acuan

Pengembangan fitur dan perbaikan harus selalu mengacu pada dokumentasi berikut:
- [docs/PRD.md](file:///d:/flutter_project/kosfinder/docs/PRD.md) – Kebutuhan produk dan spesifikasi fitur.
- [docs/ARCHITECTURE.md](file:///d:/flutter_project/kosfinder/docs/ARCHITECTURE.md) – Arsitektur sistem, struktur folder, dan pola desain.
- [docs/TASKS.md](file:///d:/flutter_project/kosfinder/docs/TASKS.md) – Daftar tugas terperinci dan status pengerjaan.

---

## 2. Cara Kerja & Batasan Perubahan

- **Satu task per permintaan:** Fokus selesaikan satu tugas dalam satu waktu.
- **Batasan cakupan:** Dilarang mengubah file di luar cakupan task yang sedang dikerjakan.
- **Perencanaan:** Selalu buat rencana/konfirmasi terlebih dahulu sebelum melakukan perubahan skala besar.
- **Prinsip kesederhanaan:** Pilih pendekatan atau solusi yang paling sederhana dan mudah dipelihara (*Keep It Simple*).
- **Manajemen dependensi:** Jangan menambahkan package/dependensi baru tanpa persetujuan eksplisit dari user.

---

## 3. Teknologi & Stack Utama

- **Framework:** Flutter
- **State Management:** Provider
- **Backend & Database:** Supabase

---

## 4. Keamanan (Security)

- **Kerahasiaan Kredensial:** Dilarang keras menaruh API key, secret, password, atau kredensial sensitif langsung di dalam kode (*no hardcoded secrets*).
- **Role Supabase:** `service_role` key **tidak boleh** digunakan di dalam aplikasi klien. Gunakan hanya `anon` key.
- **Otorisasi Data:** Seluruh pembatasan hak akses wajib ditegakkan di level database menggunakan **Row Level Security (RLS)** di Supabase.

---

## 5. Konvensi Git

- **Struktur Commit:** Satu task dikaitkan dengan satu commit.
- **Pesan Commit:** Wajib mencantumkan ID task secara jelas (contoh: `feat(TASK-01): implement login with email`).
- **Verifikasi:** Jangan melakukan git commit otomatis tanpa pemeriksaan atau persetujuan user.

---

## 6. Definition of Done (DoD)

Sebuah task dianggap selesai jika memenuhi kriteria berikut:
1. `flutter analyze` bersih (tidak ada error atau warning).
2. `flutter test` berhasil dan lulus seluruh pengujian terkait.
3. Aplikasi berhasil dijalankan dan diverifikasi di target device/emulator.
4. Memberikan laporan ringkas mengenai apa saja yang sudah diuji dan apa yang belum diuji.

---

## 7. Ketentuan Khusus Aplikasi

- **Informasi Pemilik/Developer:** Pada halaman **About**, wajib menampilkan identitas:
  - **NIM & Nama:** `2415051007 - I Wayan Agus Wredhi Putra`
