# Product Requirement Document (PRD) - KosFinder (v1)

## 1. Masalah dan Tujuan Terukur
### Masalah
- Pencari kos kesulitan membandingkan harga dan ketersediaan kamar karena informasi tersebar di berbagai platform tanpa format yang seragam.
- Banyak platform mewajibkan registrasi akun hanya untuk melihat detail kos dan kontak pemilik.

### Tujuan Terukur
- **100% Akses Terbuka**: Pencari kos dapat mencari, memfilter, dan melihat detail kontak tanpa kewajiban login (0-login barrier).
- **Standarisasi Harga**: 100% listing kos menyajikan tarif tunggal dalam skema bulanan (Rupiah).
- **Efisiensi Pencarian**: Pencari kos dapat menemukan kontak kos yang relevan dalam $\le 3$ langkah (Buka App $\rightarrow$ Filter/Cari $\rightarrow$ Salin Kontak).
- **Kecepatan Penerbitan**: Pemilik kos dapat menerbitkan listing baru dalam waktu $\le 3$ menit.

---

## 2. Pengguna (User Persona)
1. **Pencari Kos**:
   - Pengguna umum tanpa akun (guest/unauthenticated).
   - Membutuhkan akses cepat ke informasi harga bulanan, tipe kos, fasilitas, sisa kamar, dan nomor kontak pemilik.
2. **Pemilik Kos**:
   - Pengguna terdaftar dan terautentikasi (authenticated user via Supabase Auth).
   - Memiliki dan mengelola listing kos miliknya (tambah, ubah, hapus) serta keluar dari sesi akun (logout).

---

## 3. Scope Versi 1 (MVP)
### Dalam Scope (In-Scope)
- **Pencari Kos**:
  - Melihat daftar seluruh kos yang tersedia.
  - Mencari kos berdasarkan pencocokan teks bebas *case-insensitive* pada nama area/alamat.
  - Menyaring (filter) kos berdasarkan rentang harga maksimal, tipe kos (*Putra*, *Putri*, *Campur*), dan fasilitas pilihan tetap (*Wi-Fi*, *Kasur*, *Lemari*, *Kamar Mandi Dalam*, *AC*, *Parkir Motor*).
  - Melihat halaman detail informasi kos lengkap.
  - Menyalin nomor WhatsApp pemilik ke *clipboard* dengan satu ketukan tombol.
- **Pemilik Kos**:
  - Pendaftaran (Sign Up), Masuk (Log In), dan Keluar (Log Out) dengan Email dan Password via Supabase Auth.
  - Menambah listing kos (Nama, Area/Alamat, Harga Bulanan, Tipe, Fasilitas via *predefined checklist*, Sisa Kamar, Nama Kontak, Nomor WhatsApp).
  - Mengubah informasi listing kos milik sendiri.
  - Menghapus listing kos milik sendiri.
- **Tampilan**:
  - UI berbasis teks bersih, Material Icons, dan Badge/Chip kategori (tanpa elemen gambar).

### Di Luar Scope (Out-of-Scope)
- Fitur ubah kata sandi / reset password pemilik kos.
- Pembayaran online / transaksi sewa in-app.
- Fitur chat langsung di dalam aplikasi maupun pembukaan otomatis aplikasi eksternal (URL launcher).
- Upload foto, input URL gambar, maupun gambar *placeholder*.
- Integrasi peta digital (Google Maps/OpenStreetMap) dan geolokasi GPS.
- Sistem ulasan, rating, dan komentar.
- Rekomendasi berbasis AI/algoritma cerdas.
- Verifikasi identitas pemilik (KTP/dokumen resmi).
- Fitur draft, toggle sembunyikan, atau nonaktifkan sementara listing.
- Manajemen multi-kamar/multi-tipe dalam satu listing.
- Manajemen profil terpisah untuk pemilik kos.

---

## 4. Non-Functional Requirements (NFR)
1. **Keamanan**:
   - **NFR-SEC-1**: Data listing publik hanya memiliki izin baca (`SELECT`).
   - **NFR-SEC-2**: Operasi `INSERT`, `UPDATE`, dan `DELETE` listing wajib dilindungi Supabase Row Level Security (RLS) di mana `auth.uid() == owner_id`.
   - **NFR-SEC-3**: Password pemilik dienkripsi dan dikelola aman oleh Supabase Auth.
2. **Keandalan**:
   - **NFR-REL-1**: Ketika terjadi kegagalan jaringan, aplikasi menampilkan pesan error yang informatif dan tombol "Coba Lagi" tanpa mengalami *crash*.
   - **NFR-REL-2**: Kolom jumlah kamar divalidasi pada level database dengan batasan bilangan bulat non-negatif (`kamar >= 0`).
3. **Kemudahan Pakai (Usability)**:
   - **NFR-USE-1**: Mengetuk tombol salin kontak memicu umpan balik visual (*Snackbar*) "Nomor WhatsApp berhasil disalin" dalam waktu $< 200$ ms.
   - **NFR-USE-2**: Status ketersediaan kamar memiliki kontras visual yang tegas antara *Tersedia* dan *Penuh*.
4. **Performa**:
   - **NFR-PERF-1**: Waktu muat daftar kos pertama kali $\le 2$ detik pada koneksi 4G standar.
   - **NFR-PERF-2**: Respon filter lokal dan pembaruan tampilan daftar kos berlangsung $\le 500$ ms.
5. **Privasi**:
   - **NFR-PRI-1**: Email akun pemilik kos tidak dipublikasikan ke pencari kos; hanya nama kontak dan nomor WhatsApp yang diisi pada listing yang dapat dilihat publik.

---

## 5. User Stories & Acceptance Criteria

### US01: Menjelajah dan Mencari Kos (dari I-01)
> Sebagai **Pencari Kos**, saya ingin **melihat dan mencari daftar kos berdasarkan teks area**, agar **saya dapat menemukan kos di lokasi yang saya inginkan**.

- **US01-AC1: Menampilkan daftar kos tersedia**
  - **Given** aplikasi dibuka oleh pencari kos dan koneksi internet aktif.
  - **When** halaman utama dimuat.
  - **Then** sistem menampilkan daftar kartu kos berisi nama, area, harga/bulan, tipe kos, dan badge sisa kamar.
- **US01-AC2: Pencarian teks bebas case-insensitive area**
  - **Given** pencari kos berada di kolom pencarian.
  - **When** mengetikkan "KUKUSAN" atau "kukusan" pada area kos "Kukusan, Beji".
  - **Then** sistem menampilkan seluruh kos yang mencakup kata kunci tersebut tanpa terpengaruh huruf besar/kecil.
- **US01-AC3: Pencarian area tidak ditemukan (Data Kosong)**
  - **Given** pencari kos berada di halaman utama.
  - **When** mengetikkan kata kunci area yang tidak cocok dengan data apa pun.
  - **Then** sistem menampilkan pesan "Tidak ada kos yang ditemukan di area ini".
- **US01-AC4: Kegagalan koneksi saat memuat daftar**
  - **Given** perangkat tidak memiliki koneksi internet.
  - **When** halaman utama mencoba mengambil data dari Supabase.
  - **Then** sistem menampilkan status error "Gagal memuat data, periksa koneksi Anda" beserta tombol "Coba Lagi".

---

### US02: Menyaring Kos (dari I-02, I-03)
> Sebagai **Pencari Kos**, saya ingin **menyaring kos berdasarkan rentang harga, tipe kos, dan fasilitas checklist**, agar **saya memperoleh hasil yang sesuai anggaran dan preferensi saya**.

- **US02-AC1: Hasil filter sesuai kriteria checklist dan harga**
  - **Given** pencari kos membuka panel filter.
  - **When** memilih tipe "Putri", batas harga maksimal "Rp 1.000.000", serta mencentang fasilitas "Wi-Fi" dan "AC", lalu menekan "Terapkan".
  - **Then** sistem hanya menampilkan kos tipe Putri dengan harga $\le 1.000.000$ yang memiliki fasilitas Wi-Fi dan AC.
- **US02-AC2: Hasil filter kosong**
  - **Given** pencari kos menerapkan kombinasi filter yang sangat spesifik.
  - **When** tidak ada data yang memenuhi seluruh kriteria tersebut.
  - **Then** sistem menampilkan pesan "Tidak ada kos yang cocok dengan kriteria filter Anda" dan opsi "Reset Filter".

---

### US03: Melihat Detail Kos & Menyalin Kontak (dari I-04, I-05)
> Sebagai **Pencari Kos**, saya ingin **melihat detail spesifikasi kos dan menyalin nomor WhatsApp pemilik**, agar **saya dapat menghubungi pemilik kos secara mandiri**.

- **US03-AC1: Detail kos dan indikator kamar penuh**
  - **Given** pencari kos memilih salah satu kos dengan sisa kamar = 0.
  - **When** halaman detail kos terbuka.
  - **Then** sistem menampilkan seluruh detail (nama, area, harga/bulan, tipe, badge fasilitas tetap, nama pemilik, nomor WhatsApp) dan status "Penuh".
- **US03-AC2: Menyalin nomor WhatsApp ke clipboard**
  - **Given** pencari kos berada di halaman detail kos.
  - **When** menekan tombol "Salin Nomor" di samping teks nomor WhatsApp.
  - **Then** nomor WhatsApp tersimpan di *clipboard* sistem dan muncul notifikasi Snackbar "Nomor WhatsApp berhasil disalin".

---

### US04: Registrasi, Login, & Logout Pemilik Kos [asumsi]
> Sebagai **Pemilik Kos**, saya ingin **mendaftar, masuk, dan keluar dari akun saya menggunakan email dan password**, agar **saya dapat mengelola properti kos saya dengan aman**.

- **US04-AC1: Registrasi dan login berhasil**
  - **Given** pemilik kos berada pada halaman login/registrasi.
  - **When** memasukkan format email valid dan password minimal 6 karakter, lalu menekan tombol submit.
  - **Then** sistem membuat sesi autentikasi Supabase dan mengarahkan pengguna ke halaman kelola kos (dashboard pemilik).
- **US04-AC2: Validasi input gagal / kredensial salah**
  - **Given** pemilik kos mencoba login dengan password salah.
  - **When** menekan tombol login.
  - **Then** sistem menampilkan pesan kesalahan "Email atau kata sandi tidak valid" tanpa berpindah halaman.
- **US04-AC3: Gangguan jaringan saat autentikasi**
  - **Given** tidak ada koneksi internet saat submit login/registrasi.
  - **When** formulir dikirimkan.
  - **Then** sistem menampilkan pesan "Koneksi internet terputus, silakan coba beberapa saat lagi".
- **US04-AC4: Logout akun berhasil**
  - **Given** pemilik kos dalam keadaan masuk (logged in) di dashboard pemilik.
  - **When** menekan tombol "Keluar / Logout".
  - **Then** sistem menghapus sesi autentikasi Supabase aktif dan mengarahkan kembali ke halaman beranda/login tanpa akses ke fitur kelola kos.

---

### US05: Menambah Listing Kos Baru [asumsi]
> Sebagai **Pemilik Kos**, saya ingin **menambahkan data listing kos baru dengan checklist fasilitas**, agar **kos saya dapat dilihat oleh pencari kos**.

- **US05-AC1: Penambahan listing berhasil**
  - **Given** pemilik kos telah login dan berada di formulir tambah kos.
  - **When** mengisi nama, area, harga bulanan, tipe kos, memilih fasilitas dari checklist tetap (*Wi-Fi*, *Kasur*, *Lemari*, *Kamar Mandi Dalam*, *AC*, *Parkir Motor*), sisa kamar $\ge 0$, nama kontak, no. WA, lalu menekan "Simpan".
  - **Then** listing tersimpan di database dengan `owner_id` pemilik saat ini dan muncul di daftar kos miliknya.
- **US05-AC2: Validasi form kosong atau tidak valid**
  - **Given** formulir tambah kos terbuka.
  - **When** pemilik mengosongkan nama kos atau memasukkan nilai kamar negatif (< 0).
  - **Then** sistem mencegah pengiriman data dan memunculkan pesan validasi pada masing-masing field yang bermasalah.

---

### US06: Mengelola Listing Kos Sendiri (Ubah & Hapus) (dari I-06)
> Sebagai **Pemilik Kos**, saya ingin **mengubah data dan menghapus listing kos milik saya**, agar **informasi kos saya selalu akurat atau dapat dihentikan saat tidak disewakan lagi**.

- **US06-AC1: Pemilik mengubah data listing miliknya**
  - **Given** pemilik kos membuka listing miliknya dan mengubah sisa kamar menjadi 0.
  - **When** menekan tombol "Perbarui".
  - **Then** perubahan tersimpan dan status listing langsung berubah menjadi "Penuh".
- **US06-AC2: Pemilik menghapus listing miliknya**
  - **Given** pemilik kos berada di daftar kos miliknya.
  - **When** memilih opsi "Hapus" dan mengonfirmasi dialog peringatan.
  - **Then** data listing terhapus dari sistem dan tidak muncul lagi di pencarian publik.
- **US06-AC3: Penolakan akses mengubah listing orang lain**
  - **Given** Pengguna A terautentikasi sebagai pemilik kos.
  - **When** terjadi manipulasi kueri/akses untuk mengubah atau menghapus listing milik Pengguna B.
  - **Then** Supabase RLS menolak permintaan dengan error *Unauthorized / Forbidden* (kode 403 / policy violation) dan data Pengguna B tetap aman.
- **US06-AC4: Dashboard pemilik baru tanpa listing (Data Kosong)**
  - **Given** pemilik kos baru saja mendaftar dan belum menambahkan kos.
  - **When** masuk ke menu "Kos Saya".
  - **Then** sistem menampilkan halaman kosong dengan pesan "Anda belum memiliki listing kos" dan tombol "Tambah Kos Sekarang".
