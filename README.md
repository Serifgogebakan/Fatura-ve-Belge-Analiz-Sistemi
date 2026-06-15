# BillMind - Akıllı Fatura ve Belge Analiz Sistemi 🚀

> Küçük işletmelerin ve bireysel kullanıcıların fiziksel fatura, fiş ve finansal belgelerini dijital ortama taşıyan; OCR (Optik Karakter Tanıma) ve Yapay Zeka destekli modern belge yönetim ve finansal analiz sistemi.

---

## 📌 Proje Hakkında

**BillMind**, işletmelerin finansal belgelerini tarayarak metin verilerini otomatik olarak çıkaran, bu verileri yapay zeka ile anlamlandırıp kategorize eden ve dinamik grafiklerle raporlayan bütünsel bir çözümdür. 

Sistem; ofis içi yönetim için gelişmiş bir **Web Dashboard**, sahada anlık belge yükleme ve yapay zeka asistanıyla sohbet için **Mobil Uygulama** ve tüm işlemleri koordine eden **.NET Backend** servisinden oluşmaktadır.

---

## ✨ Ana Özellikler

### 📱 Mobil Uygulama (Flutter)
- **Kamera ile Belge Tarama:** Fatura veya fişlerinizi doğrudan kamerayla çekerek sisteme yükleyin.
- **Yapay Zeka Destekli Sohbet (AI Chat):** Finansal durumunuz, harcamalarınız veya yüklediğiniz belgeler hakkında Groq API destekli yapay zeka asistanına sorular sorun.
- **Hızlı ve Manuel Belge Girişi:** Otomatik taramaya alternatif olarak hızlıca manuel belge kaydı ekleme.
- **Bütçe Takibi ve Limit Tanımlama:** Kategorilere göre bütçe limitleri tanımlayın, harcamalarınızı bu limitlere göre takip edin.
- **Bildirim ve Hatırlatıcılar:** Ödeme tarihleri yaklaşan faturalar için anlık bildirimler alın.
- **Profil ve Tema Yönetimi:** Karanlık/Açık tema desteği, profil ve şirket bilgileri güncelleme.

### 💻 Web Yönetim Paneli (Next.js)
- **Gelişmiş Finansal Analiz & Özet:** İşletmenizin nakit akışını, gelir/gider dengesini ve bütçe durumunu modern grafiklerle izleyin.
- **Belge Yönetim Paneli (CRUD):** Tüm belgelerinizi listeleyin, filtreleyin, detaylarını inceleyin ve düzenleyin.
- **PDF ve Excel Dışa Aktarım:** Finansal raporlarınızı tek tıkla dışa aktarın.
- **Kategori Bazlı Bütçe Yönetimi:** Dinamik olarak bütçe oluşturup harcama limitlerinizi yönetin.
- **Güvenli Giriş & Kayıt Sistemi:** Supabase Auth entegrasyonu ile güvenli kullanıcı yönetimi.

### ⚙️ Backend Servisi (.NET API)
- **OCR Entegrasyonu:** Yüklenen belgelerin üzerindeki metinleri otomatik olarak okuma.
- **Akıllı Bilgi Ayrıştırma:** OCR çıktılarındaki tutar, KDV, VKN, tarih ve tedarikçi bilgilerini ayrıştırarak yapılandırılmış veri haline getirme.
- **Supabase Entegrasyonu:** Tüm veri saklama, dosya yükleme (Storage) ve profil işlemlerinin Supabase API'leri üzerinden yönetimi.

---

## 🛠️ Teknoloji Yığını

- **Web Paneli:** Next.js (React), TailwindCSS, Chart.js / Recharts
- **Mobil Uygulama:** Flutter, Supabase SDK, SharedPreferences, Cloudinary (Avatar Yönetimi)
- **Backend (API):** .NET (C#), Supabase C# Client, OCR ve LLM Servisleri
- **Veritabanı & Altyapı:** Supabase (PostgreSQL, RLS - Satır Bazlı Güvenlik, Storage Buckets)

---

## 📂 Proje Yapısı

```text
Fatura-ve-Belge-Analiz-Sistemi/
├── backend/                  # .NET Web API Backend Projesi
│   └── BillMind.API/         # API Modülleri, Servisler ve Controller'lar
├── mobile/                   # Flutter Mobil Uygulaması
│   ├── lib/                  # Dart Kodları (Ekranlar, Servisler)
│   └── android/ios/          # Platforma Özel Yapılandırmalar
├── web/                      # Next.js Web Dashboard Uygulaması
│   └── src/                  # React Bileşenleri, Sayfalar ve API Entegrasyonu
└── README.md                 # Proje Genel Dokümantasyonu
```

---

## 🚀 Kurulum ve Çalıştırma

### 1. Ön Gereksinimler
Projenin tüm servislerinin çalışması için bir **Supabase** projesine, **Cloudinary** hesabına ve yapay zeka özellikleri için **Groq API** anahtarına ihtiyacınız vardır.

### 2. Backend Çalıştırma
```bash
cd backend/BillMind.API
dotnet restore
dotnet run
```

### 3. Web Panelini Çalıştırma
```bash
cd web
npm install
npm run dev
```
Uygulama varsayılan olarak `http://localhost:3000` adresinde çalışacaktır.

### 4. Mobil Uygulamayı Çalıştırma
`mobile/.env` dosyasını oluşturup gerekli API anahtarlarınızı girdikten sonra:
```bash
cd mobile
flutter pub get
flutter run
```

---

## 🔒 Lisans ve Güvenlik
Bu proje, Supabase RLS (Satır Bazlı Güvenlik) politikaları kullanılarak korunmaktadır. Her kullanıcı yalnızca kendi yüklediği belgelere ve profil verilerine erişebilir.