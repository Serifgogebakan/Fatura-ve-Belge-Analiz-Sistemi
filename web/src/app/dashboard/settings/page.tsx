"use client";

import { User as UserIcon, Shield, Bell, HelpCircle } from "lucide-react";
import Link from "next/link";

export default function SettingsPage() {
  return (
    <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-500">
      <div>
        <h1 className="text-3xl font-extrabold text-foreground">Hesap Ayarları</h1>
        <p className="text-muted mt-2 font-medium">İşletme bilgilerinizi yönetin, aboneliğinizi kontrol edin ve bildirim tercihlerinizi özelleştirin.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
        {/* Profile Card */}
        <div className="bg-card border border-border rounded-xl p-8 flex flex-col items-center text-center shadow-sm">
          <div className="w-28 h-28 rounded-full bg-orange-100 flex items-center justify-center mb-6 overflow-hidden border-4 border-background shadow-sm">
            {/* The mockup shows an avatar placeholder, we'll use a generic icon tinted to mimic the mockup colors */}
            <UserIcon size={50} className="text-orange-900" />
          </div>
          <h2 className="text-xl font-extrabold text-foreground">Caner Demir</h2>
          <p className="text-sm font-medium text-muted">Baş Finans Yöneticisi (CFO)</p>
          <button className="mt-6 w-full py-2.5 bg-blue-700 hover:bg-blue-800 text-white rounded-lg font-bold transition-colors">
            Fotoğrafı Güncelle
          </button>
        </div>

        {/* Plan Output */}
        <div className="md:col-span-2 bg-[#0C58D0] text-white rounded-xl p-8 relative overflow-hidden flex flex-col justify-between shadow-sm">
          <div className="absolute right-6 top-6 opacity-30">
             <Shield size={48} className="fill-white" />
          </div>
          <div>
            <span className="inline-block px-3 py-1 bg-white/20 rounded-full text-xs font-bold tracking-wider mb-4">AKTİF PLAN</span>
            <h2 className="text-3xl font-extrabold mb-2">Enterprise Plus</h2>
          </div>
          
          <div className="grid grid-cols-2 gap-8 mt-8">
            <div>
              <p className="text-white text-xs font-bold uppercase mb-2 tracking-wider">YENİLEME TARİHİ</p>
              <p className="text-xl font-extrabold">14 Eylül 2024</p>
            </div>
            <div>
              <p className="text-white text-xs font-bold uppercase mb-2 tracking-wider">KULLANIM</p>
              <p className="text-xl font-extrabold">850 / 1000 Belge</p>
            </div>
          </div>
          
          <div className="flex gap-4 mt-10">
            <button className="px-6 py-2.5 bg-white text-blue-700 rounded-lg font-bold text-sm hover:bg-slate-100 transition-colors">
              Planı Yükselt
            </button>
            <button className="px-6 py-2.5 bg-transparent border border-white/30 text-white rounded-lg font-bold text-sm hover:bg-white/10 transition-colors">
              Faturaları Görüntüle
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Company Settings */}
        <div className="bg-card border border-border rounded-xl p-8 shadow-sm">
          <h3 className="text-lg font-bold flex items-center gap-2 mb-8">
            <BuildingIcon />
            İşletme Bilgileri
          </h3>
          
          <div className="space-y-6">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">İŞLETME ADI</label>
              <input type="text" readOnly value="Architect Global Danışmanlık A.Ş." className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none" />
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">VERGİ NUMARASI (TAX ID)</label>
                <input type="text" readOnly value="8273019283" className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none" />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">TİCARET SİCİL NO</label>
                <input type="text" readOnly value="TR-99012" className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none" />
              </div>
            </div>
            
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">ADRES</label>
              <textarea readOnly value="Levent Plaza, Büyükdere Cad. No:173, Kat:12, Beşiktaş, İstanbul" className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none resize-none h-24" />
            </div>

            <button className="w-full py-3 bg-muted-bg border border-border text-foreground rounded-lg font-bold hover:bg-border transition-colors mt-2 text-sm">
              Değişiklikleri Kaydet
            </button>
          </div>
        </div>

        {/* Notifications */}
        <div className="bg-card border border-border rounded-xl p-8 shadow-sm">
          <h3 className="text-lg font-bold flex items-center gap-2 mb-8">
            <Bell className="text-blue-700" size={20} />
            Bildirim Ayarları
          </h3>
          
          <div className="space-y-8">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-bold text-foreground text-sm">E-Posta Raporları</p>
                <p className="text-xs text-muted font-medium mt-0.5">Haftalık finansal özet raporlarını e-posta ile al.</p>
              </div>
              <div className="w-12 h-6 bg-blue-700 rounded-full relative cursor-pointer shadow-inner">
                <div className="w-5 h-5 bg-white rounded-full absolute right-0.5 top-0.5 shadow-sm"></div>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <p className="font-bold text-foreground text-sm">Anlık Bildirimler</p>
                <p className="text-xs text-muted font-medium mt-0.5">Yeni belge yüklendiğinde anında haber ver.</p>
              </div>
              <div className="w-12 h-6 bg-blue-700 rounded-full relative cursor-pointer shadow-inner">
                <div className="w-5 h-5 bg-white rounded-full absolute right-0.5 top-0.5 shadow-sm"></div>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <p className="font-bold text-foreground text-sm">Güvenlik Uyarıları</p>
                <p className="text-xs text-muted font-medium mt-0.5">Hesap girişlerini ve şifre değişikliklerini bildir.</p>
              </div>
              <div className="w-12 h-6 bg-blue-700 rounded-full relative cursor-pointer shadow-inner">
                <div className="w-5 h-5 bg-white rounded-full absolute right-0.5 top-0.5 shadow-sm"></div>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <p className="font-bold text-foreground text-sm">Pazarlama İletişimi</p>
                <p className="text-xs text-muted font-medium mt-0.5">Yeni özellikler ve güncellemeler hakkında bilgi al.</p>
              </div>
              <div className="w-12 h-6 bg-muted-bg border border-border rounded-full relative cursor-pointer">
                <div className="w-5 h-5 bg-muted rounded-full absolute left-0.5 top-0.5"></div>
              </div>
            </div>

            <div className="bg-muted-bg/50 border border-border rounded-xl p-4 flex gap-3 mt-4">
               <div className="w-5 h-5 rounded-full bg-orange-700 text-white flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">i</div>
               <div>
                 <p className="text-xs font-bold text-foreground">Önemli Hatırlatma</p>
                 <p className="text-[11px] text-muted font-medium mt-1 leading-relaxed">Güvenlik ayarları kapatılamaz ve her zaman e-posta adresinize gönderilir.</p>
               </div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pb-8">
        {/* New Support Card */}
        <div className="bg-gradient-to-r from-blue-700 to-blue-600 rounded-xl p-6 flex items-center justify-between shadow-sm">
          <div>
            <h3 className="font-bold text-white text-lg flex items-center gap-2 mb-1">
              <HelpCircle size={20} />
              Destek Masası
            </h3>
            <p className="text-blue-100 text-sm font-medium">Bir problem mi var? Ekibimizle mesajlaşın.</p>
          </div>
          <Link href="/dashboard/support" className="px-6 py-2.5 bg-white text-blue-700 font-bold rounded-lg text-sm shadow-sm hover:bg-slate-50 transition-colors">
            Destek Al
          </Link>
        </div>

        {/* Freeze Account matching mockup */}
         <div className="bg-card border border-border rounded-xl p-6 flex items-center justify-between shadow-sm">
          <div>
            <h3 className="font-bold text-foreground text-lg mb-1">
              Hesabı Dondur
            </h3>
            <p className="text-muted text-sm font-medium">Tüm verilerinizi saklayarak hesabınızı geçici olarak kapatın.</p>
          </div>
          <button className="px-6 py-2.5 bg-transparent border border-red-200 text-red-600 font-bold rounded-lg text-sm hover:bg-red-50 transition-colors">
            Hesabı Yönet
          </button>
        </div>
      </div>

    </div>
  );
}

function BuildingIcon() {
  return (
    <svg className="text-blue-700 w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
    </svg>
  );
}
