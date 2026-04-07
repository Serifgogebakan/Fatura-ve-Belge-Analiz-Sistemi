"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { TrendingUp, Landmark, Calendar, FileText, Download, FileSpreadsheet } from "lucide-react";

export default function AnalyticsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalAmount: 0,
    totalTax: 0,
    totalExpenses: 0,
    amountChange: 0,
    docCount: 0,
  });
  const [categoryData, setCategoryData] = useState<{ label: string; amount: number; percent: number; color: string }[]>([]);
  const [recentReports, setRecentReports] = useState<any[]>([]);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  async function fetchAnalytics() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { router.push("/login"); return; }

    // Tüm belgeler
    const { data: docs } = await supabase
      .from("documents")
      .select("*")
      .eq("user_id", user.id);

    if (docs) {
      const total = docs.reduce((s, d) => s + (Number(d.amount) || 0), 0);
      const tax = total * 0.18; // Tahmini KDV
      const expenses = docs.filter(d => d.category === "FATURA").reduce((s, d) => s + (Number(d.amount) || 0), 0);

      setStats({
        totalAmount: total,
        totalTax: tax,
        totalExpenses: expenses,
        amountChange: 12.4,
        docCount: docs.length,
      });

      // Kategori dağılımı
      const catMap: Record<string, number> = {};
      docs.forEach(d => {
        const cat = d.category || "DİĞER";
        catMap[cat] = (catMap[cat] || 0) + (Number(d.amount) || 0);
      });

      const colors = ["text-[#0f3d99] dark:text-blue-500", "text-[#8c2a00] dark:text-orange-500", "text-slate-300 dark:text-slate-600", "text-emerald-600 dark:text-emerald-400"];
      const dotColors = ["bg-[#0f3d99] dark:bg-blue-500", "bg-[#8c2a00] dark:bg-orange-500", "bg-slate-300 dark:bg-slate-600", "bg-emerald-600 dark:bg-emerald-400"];
      const entries = Object.entries(catMap).sort((a, b) => b[1] - a[1]);
      const catTotal = entries.reduce((s, e) => s + e[1], 0) || 1;

      setCategoryData(entries.map(([label, amount], i) => ({
        label,
        amount,
        percent: Math.round((amount / catTotal) * 100),
        color: dotColors[i % dotColors.length],
      })));

      // Son tamamlanan belgeler (rapor çıktısı gibi)
      const completed = docs
        .filter(d => d.status === "tamamlandı")
        .slice(0, 3);
      setRecentReports(completed);
    }

    setLoading(false);
  }

  function fmt(val: number) {
    return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 0 }).format(val);
  }

  function fmtDate(d: string) {
    return new Date(d).toLocaleDateString("tr-TR", { day: "2-digit", month: "short", year: "numeric" });
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Donut chart hesaplama
  const circumference = 2 * Math.PI * 40; // ~251.2
  let accumulated = 0;
  const donutArcs = categoryData.map((cat, i) => {
    const arcLength = (cat.percent / 100) * circumference;
    const offset = -accumulated;
    accumulated += arcLength;
    const strokeColors = ["#0f3d99", "#8c2a00", "#cbd5e1", "#059669"];
    return { arcLength, offset, stroke: strokeColors[i % strokeColors.length] };
  });

  // Geçerli ayın ilk ve son gününü bul
  const today = new Date();
  const firstDay = new Date(today.getFullYear(), today.getMonth(), 1).toLocaleDateString("tr-TR", { day: '2-digit', month: 'short' });
  const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0).toLocaleDateString("tr-TR", { day: '2-digit', month: 'short' });
  const currentMonthRange = `${firstDay} - ${lastDay}`;

  // Zaman içindeki harcama grafiği için dinamik ay isimleri (Son 7 ay)
  const allMonths = ["OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN", "TEMMUZ", "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"];
  const currentMonthIdx = today.getMonth();
  const graphMonths = Array.from({ length: 7 }).map((_, i) => {
    let m = currentMonthIdx - (6 - i);
    if (m < 0) m += 12;
    return allMonths[m];
  });

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Raporlar ve Analizler</h1>
          <p className="text-muted mt-1.5 font-medium">Finansal performansınızı ve harcamalarınızı detaylıca inceleyin.</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center bg-card border border-border rounded-xl p-1 shadow-sm">
            <button className="px-4 py-2 bg-muted-bg text-foreground font-semibold rounded-lg text-sm transition-colors">Son 30 Gün</button>
            <button className="px-4 py-2 text-muted hover:text-foreground font-medium rounded-lg text-sm transition-colors">Son 3 Ay</button>
            <button className="px-4 py-2 text-muted hover:text-foreground font-medium rounded-lg text-sm transition-colors">Yıllık</button>
          </div>
          <div className="flex items-center gap-2 px-4 py-2.5 bg-card border border-border text-foreground font-medium rounded-xl shadow-sm text-sm">
            <Calendar size={16} className="text-muted" />
            {currentMonthRange}
          </div>
        </div>
      </div>

      {/* Top Value Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-card border-b-[3px] border-b-blue-600 border border-border rounded-xl p-6 shadow-sm">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">NET KAR</p>
            <TrendingUp size={20} className="text-blue-600" />
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺{fmt(stats.totalAmount)}</h2>
          <p className="text-xs font-medium">
            <span className="text-emerald-500 font-bold">+{stats.amountChange}%</span>{" "}
            <span className="text-muted">geçen aya göre</span>
          </p>
        </div>

        <div className="bg-card border-b-[3px] border-b-red-700 border border-border rounded-xl p-6 shadow-sm">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">TOPLAM VERGİ</p>
            <Landmark size={20} className="text-red-700" />
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺{fmt(Math.round(stats.totalTax))}</h2>
          <p className="text-xs font-medium">
            <span className="text-red-500 font-bold">+3.1%</span>{" "}
            <span className="text-muted">öngörülen artış</span>
          </p>
        </div>

        <div className="bg-card border-b-[3px] border-b-slate-600 border border-border rounded-xl p-6 shadow-sm">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">OPERASYONEL GİDERLER</p>
            <div className="bg-slate-100 dark:bg-slate-800 p-1 rounded-md">
              <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺{fmt(stats.totalExpenses)}</h2>
          <p className="text-xs font-medium">
            <span className="text-emerald-500 font-bold">-2.5%</span>{" "}
            <span className="text-muted">tasarruf sağlandı</span>
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Spending Analysis Chart */}
        <div className="lg:col-span-2 bg-card border border-border rounded-2xl p-8 shadow-sm flex flex-col">
          <div className="flex justify-between items-start mb-8">
            <div>
              <h3 className="text-lg font-bold text-foreground">Zaman İçinde Harcama Analizi</h3>
              <p className="text-sm font-medium text-muted mt-1">Aylık bazda nakit çıkışı ve trend takibi</p>
            </div>
            <div className="flex items-center gap-4 text-xs font-bold">
              <div className="flex items-center gap-1.5 text-muted">
                <div className="w-3 h-3 rounded-full bg-blue-600"></div>
                Giderler
              </div>
              <div className="flex items-center gap-1.5 text-muted">
                <div className="w-3 h-3 rounded-full bg-blue-100 dark:bg-blue-900/50"></div>
                Tahmin
              </div>
            </div>
          </div>
          
          <div className="flex-1 relative min-h-[240px] flex items-end">
            <div className="absolute inset-0" aria-hidden="true">
               <svg className="w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 100">
                  <path d="M0,80 C15,80 20,95 30,95 C45,95 40,40 55,40 C70,40 65,90 80,90 C90,90 95,20 100,20 L100,100 L0,100 Z" className="fill-blue-600/5 dark:fill-blue-500/10" />
                  <path d="M0,80 C15,80 20,95 30,95 C45,95 40,40 55,40 C70,40 65,90 80,90 C90,90 95,20 100,20" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" className="text-blue-600 dark:text-blue-500" />
               </svg>
            </div>
            <div className="relative z-10 w-full flex justify-between text-[10px] font-bold text-muted uppercase tracking-widest bottom-0 border-t border-border pt-3">
              {graphMonths.map(m => <span key={m}>{m}</span>)}
            </div>
          </div>
        </div>

        {/* Category Breakdown */}
        <div className="bg-card border border-border rounded-2xl p-8 shadow-sm flex flex-col items-center">
          <div className="w-full text-left mb-6">
            <h3 className="text-lg font-bold text-foreground">Kategori Dağılımı</h3>
            <p className="text-sm font-medium text-muted mt-1">Harcamaların sektörel dağılımı</p>
          </div>
          
          <div className="relative w-48 h-48 mb-8 flex-shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
              {donutArcs.length > 0 ? donutArcs.map((arc, i) => (
                <circle key={i} cx="50" cy="50" r="40" fill="none" stroke={arc.stroke} strokeWidth="14"
                  strokeDasharray={`${arc.arcLength} ${circumference - arc.arcLength}`}
                  strokeDashoffset={arc.offset}
                  className="transition-all duration-1000 ease-out" />
              )) : (
                <circle cx="50" cy="50" r="40" fill="none" stroke="currentColor" strokeWidth="14" className="text-muted-bg" />
              )}
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-xs font-bold text-muted mb-0.5">Toplam</span>
              <span className="text-2xl font-extrabold text-foreground">₺{fmt(stats.totalAmount > 1000 ? Math.round(stats.totalAmount / 1000) : stats.totalAmount)}{stats.totalAmount > 1000 ? "k" : ""}</span>
            </div>
          </div>

          <div className="w-full space-y-3 mt-auto">
            {categoryData.length > 0 ? categoryData.map((cat, i) => {
              const dotColors = ["bg-[#0f3d99]", "bg-[#8c2a00]", "bg-slate-300 dark:bg-slate-700", "bg-emerald-600"];
              return (
                <div key={cat.label} className="flex items-center justify-between text-sm font-bold">
                  <div className="flex items-center gap-2">
                    <div className={`w-3.5 h-3.5 rounded-sm ${dotColors[i % dotColors.length]}`}></div>
                    {cat.label}
                  </div>
                  <span>{cat.percent}%</span>
                </div>
              );
            }) : (
              <p className="text-center text-muted text-sm">Henüz veri yok</p>
            )}
          </div>
        </div>
      </div>

      {/* Recent Reports */}
      <div className="bg-card border border-border rounded-2xl shadow-sm pb-2">
        <div className="p-6 border-b border-border flex justify-between items-center">
          <h3 className="text-lg font-bold text-foreground">Son Rapor Çıktıları</h3>
          <button className="text-sm font-bold text-blue-600 dark:text-blue-400 hover:opacity-80 transition-opacity">Tümünü Gör</button>
        </div>
        
        {recentReports.length > 0 ? (
          <table className="w-full text-left border-collapse mt-2">
            <thead>
              <tr className="border-b border-border bg-muted-bg/30">
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">RAPOR ADI</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">TARİH</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">DURUM</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider text-right"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {recentReports.map((doc) => (
                <tr key={doc.id} className="hover:bg-muted-bg/30 transition-colors cursor-pointer">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center shrink-0">
                        <FileText className="text-blue-600 w-5 h-5" />
                      </div>
                      <span className="font-bold text-foreground text-sm">{doc.name}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 font-medium text-sm text-muted">{fmtDate(doc.created_at)}</td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-500/10 text-emerald-600 uppercase">TAMAMLANDI</span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    {doc.cloudinary_secure_url && (
                      <a href={doc.cloudinary_secure_url} target="_blank" className="p-2 text-blue-600 hover:bg-blue-500/10 rounded-lg transition-colors inline-flex">
                        <Download size={20} />
                      </a>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="py-12 text-center">
            <p className="text-muted font-medium">Henüz tamamlanmış rapor bulunmuyor.</p>
          </div>
        )}
      </div>
    </div>
  );
}
