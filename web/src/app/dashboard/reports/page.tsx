"use client";

import { TrendingUp, Landmark, Calendar, FileText, Download, FileSpreadsheet } from "lucide-react";

export default function ReportsPage() {
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
            01 Oca - 31 Oca
          </div>
        </div>
      </div>

      {/* Top Value Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-card border-b-[3px] border-b-blue-600 border border-border rounded-xl p-6 shadow-sm relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">NET KAR</p>
            <TrendingUp size={20} className="text-blue-600" />
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺428,500</h2>
          <p className="text-xs font-medium"><span className="text-emerald-500 font-bold">+12.4%</span> <span className="text-muted">geçen aya göre</span></p>
        </div>

        <div className="bg-card border-b-[3px] border-b-red-700 border border-border rounded-xl p-6 shadow-sm relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">TOPLAM VERGİ</p>
            <Landmark size={20} className="text-red-700" />
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺82,140</h2>
          <p className="text-xs font-medium"><span className="text-red-500 font-bold">+3.1%</span> <span className="text-muted">öngörülen artış</span></p>
        </div>

        <div className="bg-card border-b-[3px] border-b-slate-600 border border-border rounded-xl p-6 shadow-sm relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">OPERASYONEL GİDERLER</p>
            <div className="bg-slate-100 dark:bg-slate-800 p-1 rounded-md">
              <svg className="w-5 h-5 text-slate-600 dark:text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺156,000</h2>
          <p className="text-xs font-medium"><span className="text-emerald-500 font-bold">-2.5%</span> <span className="text-muted">tasarruf sağlandı</span></p>
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
               {/* Curved placeholder SVG line chart representing "Zaman İçinde Harcama Analizi" */}
               <svg className="w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 100">
                  <path d="M0,80 C15,80 20,95 30,95 C45,95 40,40 55,40 C70,40 65,90 80,90 C90,90 95,20 100,20 L100,100 L0,100 Z" fill="rgba(37, 99, 235, 0.05)" className="dark:fill-blue-900/20" />
                  <path d="M0,80 C15,80 20,95 30,95 C45,95 40,40 55,40 C70,40 65,90 80,90 C90,90 95,20 100,20" fill="none" stroke="#2563eb" strokeWidth="2.5" strokeLinecap="round" />
               </svg>
            </div>
            <div className="relative z-10 w-full flex justify-between text-[10px] font-bold text-muted uppercase tracking-widest bottom-0 border-t border-border pt-3">
              <span>OCAK</span>
              <span>ŞUBAT</span>
              <span>MART</span>
              <span>NİSAN</span>
              <span>MAYIS</span>
              <span>HAZİRAN</span>
              <span>TEMMUZ</span>
            </div>
          </div>
        </div>

        {/* Category Breakdown (Donut Placeholder) */}
        <div className="bg-card border border-border rounded-2xl p-8 shadow-sm flex flex-col items-center">
          <div className="w-full text-left mb-6">
            <h3 className="text-lg font-bold text-foreground">Kategori Dağılımı</h3>
            <p className="text-sm font-medium text-muted mt-1">Harcamaların sektörel dağılımı</p>
          </div>
          
          {/* Donut Chart visual */}
          <div className="relative w-48 h-48 mb-8 flex-shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
              {/* Blue Arc */}
              <circle cx="50" cy="50" r="40" fill="none" stroke="#0f3d99" strokeWidth="14" strokeDasharray="251.2" strokeDashoffset="113" className="transition-all duration-1000 ease-out" />
              {/* Red Arc */}
              <circle cx="50" cy="50" r="40" fill="none" stroke="#8c2a00" strokeWidth="14" strokeDasharray="75.36 175.84" strokeDashoffset="-138.2" className="transition-all duration-1000 ease-out" />
              {/* Slate Arc */}
              <circle cx="50" cy="50" r="40" fill="none" stroke="#cbd5e1" strokeWidth="14" strokeDasharray="62.8 188.4" strokeDashoffset="-213.52" className="transition-all duration-1000 ease-out dark:stroke-slate-700" />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-xs font-bold text-muted mb-0.5">Toplam</span>
              <span className="text-2xl font-extrabold text-foreground">₺156k</span>
            </div>
          </div>

          <div className="w-full space-y-3 mt-auto">
            <div className="flex items-center justify-between text-sm font-bold">
              <div className="flex items-center gap-2">
                <div className="w-3.5 h-3.5 bg-[#0f3d99] rounded-sm"></div>
                Maaşlar
              </div>
              <span>45%</span>
            </div>
            <div className="flex items-center justify-between text-sm font-bold">
              <div className="flex items-center gap-2">
                <div className="w-3.5 h-3.5 bg-[#8c2a00] rounded-sm"></div>
                Kira
              </div>
              <span>30%</span>
            </div>
            <div className="flex items-center justify-between text-sm font-bold">
              <div className="flex items-center gap-2">
                <div className="w-3.5 h-3.5 bg-slate-300 dark:bg-slate-700 rounded-sm"></div>
                Faturalar
              </div>
              <span>25%</span>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Exported Reports */}
      <div className="bg-card border border-border rounded-2xl shadow-sm pb-2">
        <div className="p-6 border-b border-border flex justify-between items-center">
          <h3 className="text-lg font-bold text-foreground">Son Rapor Çıktıları</h3>
          <button className="text-sm font-bold text-blue-600 dark:text-blue-400 hover:opacity-80 transition-opacity">Tümünü Gör</button>
        </div>
        
        <table className="w-full text-left border-collapse mt-2">
          <thead>
            <tr className="border-b border-border bg-muted-bg/30">
              <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">RAPOR ADI</th>
              <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">TARİH</th>
              <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">DURUM</th>
              <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">DOSYA BOYUTU</th>
              <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider text-right"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            <tr className="hover:bg-muted-bg/30 transition-colors group cursor-pointer">
              <td className="px-6 py-4">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center shrink-0">
                    <FileText className="text-blue-600 w-5 h-5" />
                  </div>
                  <span className="font-bold text-foreground text-sm">Q3 Gelir Tablosu</span>
                </div>
              </td>
              <td className="px-6 py-4 font-medium text-sm text-muted">24 Eki 2023</td>
              <td className="px-6 py-4">
                <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold bg-muted-bg text-muted uppercase tracking-wide">
                  ONAYLANDI
                </span>
              </td>
              <td className="px-6 py-4 font-medium text-sm text-muted">2.4 MB</td>
              <td className="px-6 py-4 text-right">
                <button className="p-2 text-blue-600 hover:bg-blue-500/10 rounded-lg transition-colors inline-flex">
                  <Download size={20} />
                </button>
              </td>
            </tr>
            <tr className="hover:bg-muted-bg/30 transition-colors group cursor-pointer">
              <td className="px-6 py-4">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-xl bg-indigo-500/10 flex items-center justify-center shrink-0">
                    <FileSpreadsheet className="text-indigo-600 w-5 h-5" />
                  </div>
                  <span className="font-bold text-foreground text-sm">Vergi Optimizasyon Analizi</span>
                </div>
              </td>
              <td className="px-6 py-4 font-medium text-sm text-muted">18 Eki 2023</td>
              <td className="px-6 py-4">
                <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-bold bg-muted-bg text-muted uppercase tracking-wide">
                  İNCELENİYOR
                </span>
              </td>
              <td className="px-6 py-4 font-medium text-sm text-muted">1.1 MB</td>
              <td className="px-6 py-4 text-right">
                <button className="p-2 text-blue-600 hover:bg-blue-500/10 rounded-lg transition-colors inline-flex">
                  <Download size={20} />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
