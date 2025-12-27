# GoGizi - Aplikasi Edukasi & Monitoring Gizi Mahasiswa

Aplikasi Android berbasis Flutter untuk edukasi dan monitoring gizi mahasiswa dengan fokus pada kebiasaan jajan sehat.

## Fitur Utama

### 🏠 Home
- Sapaan personal berdasarkan waktu
- Ringkasan kebutuhan gizi harian (kalori, protein, karbohidrat, lemak)
- CTA untuk Scan Jajanan dan Rekomendasi Menu
- Progress card Tantangan 7 Hari Sehat

### 📸 Scan Jajanan
- Scan jajanan menggunakan kamera atau galeri
- Analisis kandungan gizi (kalori, makronutrien)
- Analisis risiko edukatif (kadar gula, risiko obesitas/diabetes/ginjal)
- Rekomendasi alternatif lebih sehat
- Simpan hasil scan ke riwayat

### 🍽️ Rekomendasi Menu
- Menu sehat personal dengan AI-Optimized badge
- Filter chips (Murah, Tinggi Protein, Rendah Gula, Rendah Lemak, Cepat Saji Sehat)
- Estimasi makronutrien per menu
- Alasan singkat rekomendasi
- Alternatif jajanan lokal

### 📊 Profil
- Form validasi data diri:
  - Umur
  - Gender (Laki-laki/Perempuan)
  - Tinggi Badan (cm)
  - Berat Badan (kg)
  - Level Stres (slider 1-5)
  - Tingkat Aktivitas (Rendah/Sedang/Tinggi)
- Kalkulator kebutuhan gizi harian
- Tampilan hasil kebutuhan gizi
- Tombol ke Detail Kebutuhan Gizi

### 📈 Detail Kebutuhan Gizi
- Detail lengkap kebutuhan gizi harian
- Penjelasan fungsi setiap nutrisi
- Catatan disclaimer (estimasi, bukan pengganti konsultasi)
- CTA ke Rekomendasi Menu

### 📅 Riwayat
- Daftar scan per tanggal
- Filter (Semua/Makanan/Minuman/Minuman Manis)
- Thumbnail dan label scan
- Badge "Minuman Manis" untuk item terdeteksi
- Detail read-only per item

### 🏆 Tantangan 7 Hari Sehat
- Progress 0-7 hari
- Checklist harian
- Status scan hari ini
- Deteksi minuman manis
- Aturan reset streak (opsional toggle)
- Achievement badge dengan tanggal tercapai
- CTA Mulai/Ulangi

### 🔐 Autentikasi
- Login dengan email + password
- Register dengan validasi
- Placeholder login Google (Coming Soon)
- Onboarding 3 layar:
  1. Kenali Jajananmu (scan)
  2. Hitung Kebutuhan Gizi Harian
  3. Tantangan 7 Hari Sehat

### 👨‍💼 Admin Dashboard (Opsional)
- Count total user
- Statistik scan
- Top label terdeteksi
- Chart placeholder untuk statistik 7 hari terakhir

## Desain

### Color Palette
- **Primary Orange**: `#FF7A00`
- **Background Light Orange**: `#FFF3E6`
- **Accent Dark Orange**: `#E66A00`
- **Card White**: `#FFFFFF`
- **Card Gray**: `#F5F5F5`
- **Success Green**: `#4CAF50`
- **Warning Red**: `#FF5252`

### Typography
- Font: Inter (Google Fonts)
- Clean sans-serif untuk readability

### Komponen UI
- Material Design 3
- Card-based layout
- Progress rings/bars
- Category chips
- Clear CTAs
- Modern outline icons

## Struktur Data

### Models
- `UserProfile`: Data profil user dengan kebutuhan gizi
- `ScanResult`: Hasil scan dengan analisis risiko
- `DailyHistory`: Riwayat harian dengan total nutrisi
- `ChallengeStatus`: Status tantangan 7 hari sehat

Semua model dilengkapi dengan dummy data dan siap untuk integrasi dengan API/DB cloud.

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  image_picker: ^1.0.7
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  table_calendar: ^3.0.9
  google_fonts: ^6.1.0
```

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Run aplikasi:
```bash
flutter run
```

## Navigasi

Bottom Navigation dengan 6 tab:
1. **Home** - Dashboard utama
2. **Scan** - Scan jajanan
3. **Rekomendasi** - Menu rekomendasi
4. **Riwayat** - History scan
5. **Tantangan** - Gamifikasi 7 Hari Sehat
6. **Profil** - Profil dan kalkulator gizi

## Catatan

- Hasil scan adalah estimasi untuk tujuan edukatif
- Bukan pengganti konsultasi dengan ahli gizi atau dokter
- Siap untuk integrasi dengan backend API/cloud database
- Admin dashboard tersedia sebagai placeholder

## Lisensi

Proyek ini dibuat untuk tujuan edukasi dan monitoring gizi mahasiswa.
