# Akıllı Belge Yönetimi ve Finansal Analiz Sistemi 🚀

> Küçük işletmelerin fiziksel ortamda sakladığı fatura, fiş ve finansal belgeleri dijital ortama taşıyan, OCR (Optik Karakter Tanıma) destekli belge yönetim ve analiz sistemi.

## 📌 Problem Tanımı
Küçük işletmeler, faturalarını, fişlerini ve çeşitli finansal belgelerini çoğu zaman fiziksel ortamda saklamaktadır. Bu durum belgelerin zamanla kaybolmasına ve finansal verilerin düzenli bir şekilde analiz edilememesine neden olmaktadır. Bu sorunları ortadan kaldırmak ve finansal yönetimi daha düzenli hale getirmek için **"Dijital Belge Yönetimi ve Finansal Analiz Sistemi"** geliştirilmesi hedeflenmiştir.

## 🛠️ Kullanılacak Teknolojiler (PDF Formatına Göre)
- **Web Paneli:** Next.js (React tabanlı framework)
- **Mobil Uygulama:** Flutter (iOS ve Android için cross-platform)
- **Backend (API Sunucusu):** .NET
- **Veritabanı ve Yetkilendirme (Auth):** Supabase (PostgreSQL tabanlı BaaS)

## 📅 Proje İş Takvimi (10 Hafta)

*(Not: PDF'teki haftalık akış mantığı korunarak, yazılım geliştirme sürecine daha uygun ve mantıklı bir sıraya getirilmiştir.)*

| Hafta | Aşama / Görev | İçerik ve Çıktılar |
| :--- | :--- | :--- |
| **1. Hafta** | **Tasarım & Planlama** | Sistem tasarımı, veritabanı (Supabase) şemasının planlanması ve GitHub proje iskeletinin kurulması. |
| **2. Hafta** | **Backend Temelleri** |  Next.js ile projenin web arayüzünün kodlanması, Supabase bağlantısının yapılması ve Kullanıcı Kayıt/Giriş (Auth)    sisteminin tasarlanması. |                     
| **3. Hafta** | **Mobil Temelleri** | Flutter projesinin oluşturulması, temel ekranların (giriş, anasayfa) tasarlanması ve Auth entegrasyonu. |
| **4. Hafta** | **Belge Yükleme** | Mobil tarafta (Flutter) kamera ve galeri erişimi ile belge seçme; resimleri sunucuya/Supabase Storage'a yükleme sistemi. |
| **5. Hafta** | **Web Paneli** | .NET backend API kurumu, yüklenmiş olan belgeleri liste halinde ulgörüntüleme ve yönetme (CRUD) ekranları. |
| **6. Hafta** | **Veri Analizi** | OCR'dan elde edilen metin yığınlarından düzenli fatura bilgilerini (Tutar, Tarih, VKN vb.) ayrıştırma (parse) ve veritabanına kaydetme. |
| **7. Hafta** | **OCR Entegrasyonu** | Yüklenen belge görsellerinden metin (text) çıkaran OCR sisteminin (Tesseract / Cloud Vision vb.) backend'e entegre edilmesi. |

| **8. Hafta** | **Finansal Grafikler** | Taranan fatura verilerine dayanarak harcama analiz grafikleri (pasta, çizgi grafikler) ve finansal raporlama ekranlarının yapılması. |
| **9. Hafta** | **Arama ve Filtreleme** | Hem mobilde hem web'de yüzlerce belge/fatura içinde metin bazlı, tarih veya tutara göre arama/filtreleme sisteminin geliştirilmesi. |
| **10. Hafta** | **Test & Sunum** | Tüm sistemin (Uçtan Uca) test edilmesi, tespit edilen hataların giderilmesi (Bugfix) ve final proje sunumu. |

---
**Git Kullanımı:** Her haftanın görevi için ayrı branch (dal) açılıp düzenli olarak `main` dalına merge edilecektir.