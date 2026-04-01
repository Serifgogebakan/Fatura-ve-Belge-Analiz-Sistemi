import React from "react";
import Link from "next/link";
import { Shield, FileText, Zap, Eye, Search, BarChart3, LockKeyhole, FileCheck2 } from "lucide-react";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-[#F8FAFC] dark:bg-[#0B1121] text-gray-900 dark:text-gray-100 font-sans transition-colors duration-300 overflow-x-hidden relative scroll-smooth">

      {/* Background Glows (Fixed to viewport to prevent scroll stretching) */}
      <div className="fixed top-0 left-[-10vw] w-[50vw] h-[50vh] rounded-full bg-blue-500/20 blur-[150px] pointer-events-none -z-10"></div>
      <div className="fixed bottom-[-10vh] right-[-10vw] w-[60vw] h-[60vh] rounded-full bg-indigo-600/20 blur-[150px] pointer-events-none hidden lg:block -z-10"></div>

      {/* Navbar Minimal */}
      <nav className="w-full relative z-50 flex items-center justify-between p-6 lg:px-20 bg-white/50 dark:bg-[#0B1121]/50 backdrop-blur-md sticky top-0 border-b border-gray-200/50 dark:border-gray-800/50">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center text-white">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
          </div>
          <span className="font-bold text-xl tracking-tight hidden sm:block">Akıllı Belge Yönetimi</span>
        </div>
        <div className="hidden md:flex gap-8 text-sm font-medium text-gray-500 dark:text-gray-400">
          <a href="#ozellikler" className="hover:text-blue-600 dark:hover:text-blue-400 transition-colors">Özellikler</a>
          <a href="#nasil-calisir" className="hover:text-blue-600 dark:hover:text-blue-400 transition-colors">Nasıl Çalışır?</a>
          <a href="#guvenlik" className="hover:text-blue-600 dark:hover:text-blue-400 transition-colors">Güvenlik</a>
        </div>
        <div className="flex gap-3">
          <Link href="/login" className="hidden sm:inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium transition-colors text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400">
            Giriş Yap
          </Link>
          <Link href="/register" className="inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium bg-blue-600 text-white rounded-xl shadow-lg shadow-blue-500/30 hover:bg-blue-700 transition-colors">
            Kayıt Ol
          </Link>
        </div>
      </nav>

      <main className="relative z-10 w-full">
        {/* --- HERO SECTION --- */}
        <section className="max-w-7xl mx-auto px-6 lg:px-20 pt-20 pb-24 flex flex-col items-center text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-xs font-semibold uppercase tracking-widest mb-8 border border-blue-100 dark:border-blue-800">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
            </span>
            Finansal analiz devrimi başladı
          </div>

          <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-8 max-w-4xl leading-[1.1]">
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 dark:from-white dark:to-gray-400">Faturalarınızı. Belgelerinizi.</span><br />
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-500">Finansal Geleceğinizi.</span><br />
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 dark:from-white dark:to-gray-400">Yönetin.</span>
          </h1>

          <p className="text-lg md:text-xl text-gray-500 dark:text-gray-400 max-w-2xl mb-12 leading-relaxed">
            İşletmeniz için tasarlanmış tam otonom belge entegrasyonu. Yüzlerce faturayı saniyeler içinde analiz edin, yapay zeka ile raporlayın ve güvenle depolayın.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
            <Link href="/register" className="inline-flex items-center justify-center px-8 py-4 text-base font-medium bg-blue-600 text-white rounded-xl shadow-xl shadow-blue-500/20 hover:bg-blue-700 hover:-translate-y-0.5 transition-all">
              Ücretsiz Hesap Oluştur
            </Link>
            <Link href="/login" className="inline-flex items-center justify-center px-8 py-4 text-base font-medium bg-white dark:bg-[#151C2C] text-gray-900 dark:text-white rounded-xl border border-gray-200 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-[#1E273C] transition-colors">
              Sisteme Giriş
            </Link>
          </div>

          <div className="relative mt-20 w-full max-w-5xl aspect-video rounded-3xl overflow-hidden border border-gray-200 dark:border-gray-800 shadow-2xl">
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-white dark:to-[#0B1121] z-10 opacity-30 pointer-events-none"></div>
            <img src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=2000&auto=format&fit=crop" className="w-full h-full object-cover dark:opacity-40" alt="Dashboard Preview" />
            <div className="absolute inset-0 bg-blue-900/10 dark:bg-blue-900/30 mix-blend-overlay"></div>
          </div>
        </section>

        {/* --- ÖZELLİKLER (FEATURES) SECTION --- */}
        <section id="ozellikler" className="max-w-7xl mx-auto px-6 lg:px-20 py-24 border-t border-gray-200/50 dark:border-gray-800/50">
          <div className="mb-16">
            <h2 className="text-3xl font-bold tracking-tight mb-4">Hassas Mühendislik. <span className="text-blue-600 dark:text-blue-400">Otonom Analiz.</span></h2>
            <p className="text-gray-500 dark:text-gray-400 max-w-xl">Karmaşık finansal tabloları analiz edebilmeniz için kurumsal seviyede tasarlanmış tam entegre modüller.</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-white dark:bg-[#151C2C] p-8 rounded-3xl border border-gray-100 dark:border-gray-800 shadow-sm transition-transform hover:-translate-y-1 group">
              <div className="w-12 h-12 bg-blue-50 dark:bg-blue-900/30 rounded-2xl flex items-center justify-center text-blue-600 dark:text-blue-400 mb-6 group-hover:scale-110 transition-transform">
                <ScanIcon />
              </div>
              <h3 className="text-xl font-bold mb-3">AI Belge Tarama</h3>
              <p className="text-gray-500 dark:text-gray-400 text-sm leading-relaxed mb-6">En karmaşık faturalardan bile yapay zeka ve OCR motoruyla tam doğrulukta kritik finansal verileri çekin.</p>
              <div className="w-full h-24 bg-gradient-to-r from-blue-100 to-indigo-100 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl overflow-hidden relative">
                <div className="absolute top-0 left-0 h-full w-[2px] bg-blue-500 animate-[scan_2s_ease-in-out_infinite]"></div>
              </div>
            </div>

            <div className="bg-white dark:bg-[#151C2C] p-8 rounded-3xl border border-gray-100 dark:border-gray-800 shadow-sm transition-transform hover:-translate-y-1 group lg:col-span-2">
              <div className="w-12 h-12 bg-indigo-50 dark:bg-indigo-900/30 rounded-2xl flex items-center justify-center text-indigo-600 dark:text-indigo-400 mb-6 group-hover:scale-110 transition-transform">
                <BarChart3 className="w-6 h-6" />
              </div>
              <div className="flex flex-col md:flex-row justify-between w-full gap-8">
                <div className="md:w-1/2">
                  <h3 className="text-xl font-bold mb-3">Gelişmiş Gider Analitiği</h3>
                  <p className="text-gray-500 dark:text-gray-400 text-sm leading-relaxed mb-6">Şirketinizin anlık nakit akışını ve gider projeksiyonlarını görselleştirerek yatırım odaklarınızı doğru hedeflere yönlendirin.</p>
                  <ul className="space-y-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                    <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500"></div> Gerçek zamanlı grafikler</li>
                    <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-500"></div> Özel Raporlama</li>
                  </ul>
                </div>
                <div className="md:w-1/2 h-32 md:h-auto border-l border-gray-100 dark:border-gray-800 pl-8 flex items-end gap-3 opacity-60">
                  {/* Graphic Bars Mockup */}
                  <div className="w-1/4 bg-gray-300 dark:bg-gray-600 rounded-t-lg h-[40%] hover:h-[50%] transition-all"></div>
                  <div className="w-1/4 bg-blue-400 dark:bg-blue-600 rounded-t-lg h-[75%] hover:h-[85%] transition-all scale-105"></div>
                  <div className="w-1/4 bg-gray-300 dark:bg-gray-600 rounded-t-lg h-[30%] hover:h-[40%] transition-all"></div>
                  <div className="w-1/4 bg-blue-500 dark:bg-blue-700 rounded-t-lg h-[90%] hover:h-[100%] transition-all"></div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* --- NASIL ÇALIŞIR (HOW IT WORKS) SECTION --- */}
        <section id="nasil-calisir" className="w-full bg-blue-50/50 dark:bg-[#0f172a] py-24 border-y border-gray-200/50 dark:border-gray-800/50">
          <div className="max-w-7xl mx-auto px-6 lg:px-20">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold tracking-tight mb-4">Kurumsal süreçleri <span className="text-blue-600 dark:text-blue-400">basitleştirdik.</span></h2>
              <p className="text-gray-500 dark:text-gray-400 max-w-xl mx-auto">Sadece belgeyi sisteme yükleyin, geri kalan tüm sınıflandırma ve analiz süreçlerini yapay zeka halletsin.</p>
            </div>

            <div className="grid md:grid-cols-3 gap-8 relative">
              {/* Connecting Line */}
              <div className="hidden md:block absolute top-[45px] left-1/6 right-1/6 h-[2px] bg-gradient-to-r from-blue-200 via-indigo-300 to-blue-200 dark:from-blue-900/50 dark:via-indigo-600/50 dark:to-blue-900/50"></div>

              <div className="relative text-center z-10 flex flex-col items-center">
                <div className="w-24 h-24 rounded-full bg-white dark:bg-[#151C2C] border-4 border-blue-50 dark:border-[#0B1121] shadow-xl flex items-center justify-center mb-6">
                  <span className="text-2xl font-bold text-blue-600 dark:text-blue-500">1</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Belge Yükleme</h3>
                <p className="text-gray-500 dark:text-gray-400 text-sm">Web üzerinden PDF sürükleyin veya mobil uygulama ile faturanın fotoğrafını çekin.</p>
              </div>

              <div className="relative text-center z-10 flex flex-col items-center">
                <div className="w-24 h-24 rounded-full bg-white dark:bg-[#151C2C] border-4 border-blue-50 dark:border-[#0B1121] shadow-xl flex items-center justify-center mb-6">
                  <span className="text-2xl font-bold text-indigo-600 dark:text-indigo-400">2</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Akıllı OCR İşleme</h3>
                <p className="text-gray-500 dark:text-gray-400 text-sm">Tesseract ve AI ile belgelerdeki tüm kelimeler Tutar, VKN ve Tarih olarak kategorize edilsin.</p>
              </div>

              <div className="relative text-center z-10 flex flex-col items-center">
                <div className="w-24 h-24 rounded-full bg-white dark:bg-[#151C2C] border-4 border-blue-50 dark:border-[#0B1121] shadow-xl flex items-center justify-center mb-6">
                  <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">3</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Analiz ve Rapor</h3>
                <p className="text-gray-500 dark:text-gray-400 text-sm">İşlenen faturalar veritabanına kaydedilir ve saniyeler içinde zengin grafikli raporlara dönüşür.</p>
              </div>
            </div>
          </div>
        </section>

        {/* --- GÜVENLİK (SECURITY) SECTION --- */}
        <section id="guvenlik" className="max-w-7xl mx-auto px-6 lg:px-20 py-24">
          <div className="bg-white dark:bg-[#111827] border border-gray-100 dark:border-gray-800 rounded-[2.5rem] p-10 md:p-16 flex flex-col lg:flex-row gap-16 items-center shadow-xl relative overflow-hidden">
            <div className="absolute right-0 top-0 w-1/3 h-full bg-blue-600/5 dark:bg-blue-600/10 skew-x-12 translate-x-1/2"></div>

            <div className="w-full lg:w-1/2 relative z-10">
              <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/40 rounded-2xl flex items-center justify-center text-blue-600 mb-8 border border-blue-100 dark:border-blue-800">
                <LockKeyhole className="w-8 h-8" />
              </div>
              <h2 className="text-3xl font-bold tracking-tight mb-6">Bankacılık Standartlarında<br /><span className="text-blue-600 dark:text-blue-400">Veri Güvenliği (Kasa)</span></h2>
              <p className="text-gray-500 dark:text-gray-400 mb-8">
                Şirketinizin finansal kaleleri çok katmanlı şifreleme ve sürekli izleme ile korunuyor. Güvenlik bir seçenek değil, mimarimizin temelidir.
              </p>
              <div className="flex flex-col gap-4">
                <div className="flex items-start gap-4">
                  <div className="mt-1 bg-green-100 dark:bg-green-900/30 text-green-600 rounded-full p-1"><FileCheck2 className="w-4 h-4" /></div>
                  <div>
                    <h4 className="font-semibold text-gray-900 dark:text-white mb-1">AES-256 Bit Şifreleme</h4>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Dinlenmedeki ve aktarımdaki tüm fatura verileriniz uluslararası standartlarda kilitlenir.</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <div className="mt-1 bg-green-100 dark:bg-green-900/30 text-green-600 rounded-full p-1"><Shield className="w-4 h-4" /></div>
                  <div>
                    <h4 className="font-semibold text-gray-900 dark:text-white mb-1">Sinirsel Düğüm Denetimi (7/24)</h4>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Veritabanı trafiği yersiz dışarı aktarımlara karşı yapay zeka denetim mekanizması ile izlenir.</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="w-full lg:w-1/2 relative z-10 flex justify-center">
              {/* Mockup Security Key Lock */}
              <div className="w-64 h-80 rounded-3xl bg-gray-900 border-4 border-gray-800 p-8 flex flex-col justify-end shadow-2xl relative">
                <div className="absolute top-6 left-6 text-2xl font-mono text-gray-600 font-bold tracking-widest">NOCTURNAL</div>
                <div className="flex items-center justify-center flex-1">
                  <div className="w-24 h-24 rounded-full border-2 border-blue-500 flex items-center justify-center relative shadow-[0_0_30px_rgba(59,130,246,0.3)]">
                    <LockKeyhole className="w-10 h-10 text-blue-500" />
                    <div className="absolute inset-0 border-2 border-blue-400/30 rounded-full animate-ping"></div>
                  </div>
                </div>
                <div className="w-full h-1 bg-gray-800 rounded overflow-hidden">
                  <div className="w-full h-full bg-blue-500 shadow-[0_0_10px_rgba(59,130,246,0.5)]"></div>
                </div>
                <p className="text-center text-xs text-blue-400 mt-4 font-mono uppercase tracking-widest">Sistem Güvende</p>
              </div>
            </div>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer className="w-full py-8 border-t border-gray-200 dark:border-gray-800 text-center text-sm text-gray-500 dark:text-gray-400">
        <p>© 2026 Akıllı Belge Analizi & Yönetim Sistemi. Tüm hakları saklıdır.</p>
      </footer>
    </div>
  );
}

// Minimal Scan Icon SVG component
function ScanIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="4 8 4 4 8 4"></polyline>
      <polyline points="20 8 20 4 16 4"></polyline>
      <polyline points="16 20 20 20 20 16"></polyline>
      <polyline points="8 20 4 20 4 16"></polyline>
      <circle cx="12" cy="12" r="3"></circle>
    </svg>
  )
}
