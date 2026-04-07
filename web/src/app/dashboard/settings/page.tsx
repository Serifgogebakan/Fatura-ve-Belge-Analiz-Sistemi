"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { User as UserIcon, Shield, Bell, HelpCircle, Loader2, CheckCircle2 } from "lucide-react";
import Link from "next/link";

export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [user, setUser] = useState<any>(null);

  // Profile form state
  const [profile, setProfile] = useState({
    full_name: "",
    role: "",
    company_name: "",
    tax_id: "",
    trade_reg_no: "",
    address: "",
    subscription_plan: "free",
    subscription_renewal: "",
    document_limit: 100,
  });

  // Bildirim ayarları
  const [notifications, setNotifications] = useState({
    emailReports: true,
    instantNotifications: true,
    securityAlerts: true,
    marketingEmails: false,
  });

  // Belge istatistikleri
  const [docCount, setDocCount] = useState(0);

  useEffect(() => {
    loadProfile();
  }, []);

  async function loadProfile() {
    const { data: { user: authUser } } = await supabase.auth.getUser();
    if (!authUser) { router.push("/login"); return; }
    setUser(authUser);

    // Profili çek
    const { data: prof } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", authUser.id)
      .single();

    if (prof) {
      setProfile({
        full_name: prof.full_name || "",
        role: prof.role || "user",
        company_name: prof.company_name || "",
        tax_id: prof.tax_id || "",
        trade_reg_no: prof.trade_reg_no || "",
        address: prof.address || "",
        subscription_plan: prof.subscription_plan || "free",
        subscription_renewal: prof.subscription_renewal || "",
        document_limit: prof.document_limit || 100,
      });
    }

    // Belge sayısı
    const { count } = await supabase
      .from("documents")
      .select("*", { count: "exact", head: true })
      .eq("user_id", authUser.id);
    setDocCount(count ?? 0);

    setLoading(false);
  }

  async function saveProfile() {
    if (!user) return;
    setSaving(true);

    const { error } = await supabase
      .from("profiles")
      .update({
        full_name: profile.full_name,
        company_name: profile.company_name,
        tax_id: profile.tax_id,
        trade_reg_no: profile.trade_reg_no,
        address: profile.address,
        updated_at: new Date().toISOString(),
      })
      .eq("id", user.id);

    setSaving(false);
    if (!error) {
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } else {
      alert("Kayıt hatası: " + error.message);
    }
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const planDisplayName = profile.subscription_plan === "free" ? "Free" : 
    profile.subscription_plan === "premium" ? "Premium" : "Enterprise Plus";

  return (
    <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-500">
      {/* Toast */}
      {saved && (
        <div className="fixed top-6 right-6 z-50 flex items-center gap-3 bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-xl animate-in slide-in-from-top duration-300">
          <CheckCircle2 size={20} />
          <span className="font-semibold text-sm">Değişiklikler kaydedildi!</span>
        </div>
      )}

      <div>
        <h1 className="text-3xl font-extrabold text-foreground">Hesap Ayarları</h1>
        <p className="text-muted mt-2 font-medium">İşletme bilgilerinizi yönetin, aboneliğinizi kontrol edin ve bildirim tercihlerinizi özelleştirin.</p>
      </div>

      {/* Profile + Plan Row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
        {/* Profile Card */}
        <div className="bg-card border border-border rounded-xl p-8 flex flex-col items-center text-center shadow-sm">
          <div className="w-28 h-28 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center mb-6 overflow-hidden border-4 border-background shadow-sm">
            <UserIcon size={50} className="text-orange-900 dark:text-orange-300" />
          </div>
          <h2 className="text-xl font-extrabold text-foreground">{profile.full_name || "İsim belirtilmedi"}</h2>
          <p className="text-sm font-medium text-muted">{profile.role === "user" ? "Kullanıcı" : profile.role}</p>
          <button className="mt-6 w-full py-2.5 bg-blue-700 hover:bg-blue-800 text-white rounded-lg font-bold transition-colors">
            Fotoğrafı Güncelle
          </button>
        </div>

        {/* Plan Card */}
        <div className="md:col-span-2 bg-[#0C58D0] text-white rounded-xl p-8 relative overflow-hidden flex flex-col justify-between shadow-sm">
          <div className="absolute right-6 top-6 opacity-30">
             <Shield size={48} className="fill-white" />
          </div>
          <div>
            <span className="inline-block px-3 py-1 bg-white/20 rounded-full text-xs font-bold tracking-wider mb-4">AKTİF PLAN</span>
            <h2 className="text-3xl font-extrabold mb-2">{planDisplayName}</h2>
          </div>
          
          <div className="grid grid-cols-2 gap-8 mt-8">
            <div>
              <p className="text-white/70 text-xs font-bold uppercase mb-2 tracking-wider">YENİLEME TARİHİ</p>
              <p className="text-xl font-extrabold">{profile.subscription_renewal || "Belirtilmedi"}</p>
            </div>
            <div>
              <p className="text-white/70 text-xs font-bold uppercase mb-2 tracking-wider">KULLANIM</p>
              <p className="text-xl font-extrabold">{docCount} / {profile.document_limit} Belge</p>
            </div>
          </div>
          
          <div className="flex gap-4 mt-10">
            <button className="px-6 py-2.5 bg-white text-blue-700 rounded-lg font-bold text-sm hover:bg-slate-100 transition-colors">
              Planı Yükselt
            </button>
            <Link href="/dashboard/documents" className="px-6 py-2.5 bg-transparent border border-white/30 text-white rounded-lg font-bold text-sm hover:bg-white/10 transition-colors">
              Faturaları Görüntüle
            </Link>
          </div>
        </div>
      </div>

      {/* Company Info + Notifications */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Company Settings */}
        <div className="bg-card border border-border rounded-xl p-8 shadow-sm">
          <h3 className="text-lg font-bold flex items-center gap-2 mb-8">
            <svg className="text-blue-700 dark:text-blue-400 w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
            İşletme Bilgileri
          </h3>
          
          <div className="space-y-6">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">İŞLETME ADI</label>
              <input 
                type="text" 
                value={profile.company_name}
                onChange={(e) => setProfile(p => ({ ...p, company_name: e.target.value }))}
                placeholder="İşletme adınızı girin..."
                className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none focus:ring-2 focus:ring-accent/50" 
              />
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">VERGİ NUMARASI (TAX ID)</label>
                <input 
                  type="text" 
                  value={profile.tax_id}
                  onChange={(e) => setProfile(p => ({ ...p, tax_id: e.target.value }))}
                  placeholder="VKN"
                  className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none focus:ring-2 focus:ring-accent/50" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">TİCARET SİCİL NO</label>
                <input 
                  type="text" 
                  value={profile.trade_reg_no}
                  onChange={(e) => setProfile(p => ({ ...p, trade_reg_no: e.target.value }))}
                  placeholder="Sicil No"
                  className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none focus:ring-2 focus:ring-accent/50" 
                />
              </div>
            </div>
            
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-muted mb-2">ADRES</label>
              <textarea 
                value={profile.address}
                onChange={(e) => setProfile(p => ({ ...p, address: e.target.value }))}
                placeholder="İşletme adresi..."
                className="w-full bg-muted-bg border-none rounded-lg px-4 py-3 text-sm font-medium text-foreground outline-none resize-none h-24 focus:ring-2 focus:ring-accent/50" 
              />
            </div>

            <button 
              onClick={saveProfile}
              disabled={saving}
              className="w-full py-3 bg-muted-bg border border-border text-foreground rounded-lg font-bold hover:bg-border transition-colors mt-2 text-sm disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {saving && <Loader2 size={16} className="animate-spin" />}
              {saving ? "Kaydediliyor..." : "Değişiklikleri Kaydet"}
            </button>
          </div>
        </div>

        {/* Notifications */}
        <div className="bg-card border border-border rounded-xl p-8 shadow-sm">
          <h3 className="text-lg font-bold flex items-center gap-2 mb-8">
            <Bell className="text-blue-700 dark:text-blue-400" size={20} />
            Bildirim Ayarları
          </h3>
          
          <div className="space-y-8">
            {[
              { key: "emailReports", title: "E-Posta Raporları", desc: "Haftalık finansal özet raporlarını e-posta ile al." },
              { key: "instantNotifications", title: "Anlık Bildirimler", desc: "Yeni belge yüklendiğinde anında haber ver." },
              { key: "securityAlerts", title: "Güvenlik Uyarıları", desc: "Hesap girişlerini ve şifre değişikliklerini bildir." },
              { key: "marketingEmails", title: "Pazarlama İletişimi", desc: "Yeni özellikler ve güncellemeler hakkında bilgi al." },
            ].map((item) => {
              const isOn = notifications[item.key as keyof typeof notifications];
              return (
                <div key={item.key} className="flex items-center justify-between">
                  <div>
                    <p className="font-bold text-foreground text-sm">{item.title}</p>
                    <p className="text-xs text-muted font-medium mt-0.5">{item.desc}</p>
                  </div>
                  <button
                    onClick={() => setNotifications(n => ({ ...n, [item.key]: !isOn }))}
                    className={`w-12 h-6 rounded-full relative transition-colors shadow-inner ${
                      isOn ? "bg-blue-700" : "bg-muted-bg border border-border"
                    }`}
                  >
                    <div className={`w-5 h-5 rounded-full absolute top-0.5 transition-all shadow-sm ${
                      isOn ? "right-0.5 bg-white" : "left-0.5 bg-muted"
                    }`}></div>
                  </button>
                </div>
              );
            })}

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

      {/* Bottom Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pb-8">
        {/* Support Card */}
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

        {/* Freeze Account */}
         <div className="bg-card border border-border rounded-xl p-6 flex items-center justify-between shadow-sm">
          <div>
            <h3 className="font-bold text-foreground text-lg mb-1">Hesabı Dondur</h3>
            <p className="text-muted text-sm font-medium">Tüm verilerinizi saklayarak hesabınızı geçici olarak kapatın.</p>
          </div>
          <button className="px-6 py-2.5 bg-transparent border border-red-200 dark:border-red-800 text-red-600 font-bold rounded-lg text-sm hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
            Hesabı Yönet
          </button>
        </div>
      </div>
    </div>
  );
}
