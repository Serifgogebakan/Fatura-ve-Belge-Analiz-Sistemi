"use client";

import { Search, Download, Plus, MoreVertical, FileText, FileSpreadsheet, FileArchive, Zap } from "lucide-react";

export default function DocumentsPage() {
  const documents = [
    {
      id: "INV-2024-001",
      name: "Amazon AWS Sunucu Gideri",
      date: "12 Mart 2024",
      category: "YAZILIM",
      amount: "₺1,240.00",
      status: "Ödendi",
      statusColor: "text-emerald-600 bg-emerald-500/10",
      dotColor: "bg-emerald-500",
      icon: <FileText className="text-blue-600 w-6 h-6" />,
      bg: "bg-blue-500/10"
    },
    {
      id: "RCP-99231",
      name: "Starbucks Kahve - Toplantı",
      date: "10 Mart 2024",
      category: "TEMSİL",
      amount: "₺450.00",
      status: "Beklemede",
      statusColor: "text-amber-600 bg-amber-500/10",
      dotColor: "bg-amber-500",
      icon: <FileArchive className="text-orange-600 w-6 h-6" />,
      bg: "bg-orange-500/10"
    },
    {
      id: "INV-2024-042",
      name: "Apple Store - MacBook Pro",
      date: "08 Mart 2024",
      category: "DONANIM",
      amount: "₺84,999.00",
      status: "İncelemede",
      statusColor: "text-blue-600 bg-blue-500/10",
      dotColor: "bg-blue-500",
      icon: <FileSpreadsheet className="text-indigo-600 w-6 h-6" />,
      bg: "bg-indigo-500/10"
    },
    {
      id: "INV-2024-015",
      name: "Kira Dekontu - Ofis Mart",
      date: "05 Mart 2024",
      category: "OPERASYON",
      amount: "₺45,000.00",
      status: "Ödendi",
      statusColor: "text-emerald-600 bg-emerald-500/10",
      dotColor: "bg-emerald-500",
      icon: <FileText className="text-blue-600 w-6 h-6" />,
      bg: "bg-blue-500/10"
    }
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Belgelerim</h1>
          <p className="text-muted mt-1.5 font-medium">Finansal dökümanlarınızı buradan yönetin ve analiz edin.</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 px-4 py-2.5 bg-muted-bg text-foreground font-semibold rounded-xl hover:bg-border transition-colors text-sm border border-transparent hover:border-border">
            <Download size={18} />
            Tümünü İndir
          </button>
          <button className="flex items-center gap-2 px-5 py-2.5 bg-accent text-accent-fg font-semibold rounded-xl shadow-lg shadow-accent/20 hover:opacity-90 transition-all text-sm">
            <Plus size={18} />
            Yeni Yükle
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" size={18} />
          <input 
            type="text" 
            placeholder="Belge adı veya kategori ile ara..." 
            className="w-full bg-muted-bg/50 border border-border rounded-xl pl-10 pr-4 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-accent/50 transition-shadow"
          />
        </div>
        <div className="flex items-center bg-muted-bg/50 p-1 rounded-xl border border-border w-full md:w-auto">
          <button className="flex-1 md:flex-none px-6 py-2 bg-card text-foreground font-semibold rounded-lg shadow-sm text-sm">Tümü</button>
          <button className="flex-1 md:flex-none px-6 py-2 text-muted hover:text-foreground font-medium rounded-lg transition-colors text-sm">Faturalar</button>
          <button className="flex-1 md:flex-none px-6 py-2 text-muted hover:text-foreground font-medium rounded-lg transition-colors text-sm">Makbuzlar</button>
        </div>
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-border bg-muted-bg/30">
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">BELGE ADI</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">TARİH</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">KATEGORİ</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">TUTAR</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider">DURUM</th>
                <th className="px-6 py-4 text-xs font-bold text-muted uppercase tracking-wider text-right">İŞLEM</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {documents.map((doc, i) => (
                <tr key={i} className="hover:bg-muted-bg/30 transition-colors group cursor-pointer">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${doc.bg}`}>
                        {doc.icon}
                      </div>
                      <div>
                        <p className="font-bold text-foreground text-sm">{doc.name}</p>
                        <p className="text-xs text-muted font-medium mt-0.5">{doc.id}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 font-medium text-sm text-muted">{doc.date}</td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-muted-bg text-muted border border-border">
                      {doc.category}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-bold text-foreground text-sm">
                    {doc.amount}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${doc.statusColor}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${doc.dotColor}`}></span>
                      {doc.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button className="p-2 text-muted hover:text-foreground hover:bg-muted-bg rounded-lg transition-colors inline-flex opacity-0 group-hover:opacity-100 focus:opacity-100">
                      <MoreVertical size={18} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="px-6 py-4 border-t border-border flex items-center justify-between text-sm">
          <p className="text-muted font-medium">Toplam 48 belgeden 1-4 arası gösteriliyor</p>
          <div className="flex items-center gap-2">
            <button className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium">{"<"}</button>
            <button className="w-8 h-8 rounded-lg bg-accent text-accent-fg flex items-center justify-center font-bold shadow-sm">1</button>
            <button className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium">2</button>
            <button className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium">3</button>
            <button className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium">{">"}</button>
          </div>
        </div>
      </div>

      {/* Bottom Cards Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Smart Summary */}
        <div className="lg:col-span-2 bg-[#1C2333] text-white rounded-3xl p-8 relative overflow-hidden flex flex-col justify-between min-h-[220px]">
          <div className="absolute right-0 top-0 w-64 h-64 bg-slate-700/20 rounded-full blur-3xl -translate-y-1/4 translate-x-1/4 pointer-events-none" />
          
          <div className="relative z-10 max-w-md">
            <h3 className="text-2xl font-bold tracking-tight mb-2">Akıllı Özet</h3>
            <p className="text-slate-400 text-sm leading-relaxed mb-6">
              Bu ayki harcamalarınız geçen aya göre %12 daha düşük. Faturalarınızın %85'i zamanında ödendi.
            </p>
          </div>
          
          <div className="relative z-10 flex items-end gap-12">
            <div>
              <p className="text-slate-400 text-xs font-bold uppercase tracking-wider mb-2">TOPLAM GİDER</p>
              <p className="text-3xl font-extrabold text-white">₺132,450</p>
            </div>
            <div>
              <p className="text-amber-500/80 text-xs font-bold uppercase tracking-wider mb-2">BEKLEYEN</p>
              <p className="text-3xl font-extrabold text-amber-500">₺12,300</p>
            </div>
          </div>
          
          <div className="absolute right-10 bottom-10 opacity-30 pointer-events-none text-slate-400">
             {/* Fake bar chart icon */}
            <div className="flex items-end gap-2 h-20">
              <div className="w-6 h-10 bg-slate-400 rounded-t-sm" />
              <div className="w-6 h-6 bg-slate-400 rounded-t-sm" />
              <div className="w-6 h-16 bg-slate-400 rounded-t-sm" />
              <div className="w-6 h-12 bg-slate-400 rounded-t-sm" />
            </div>
          </div>
        </div>

        {/* Quick Scan */}
        <div className="bg-[#EAF1FF] dark:bg-blue-900/20 border border-blue-100 dark:border-blue-800/50 rounded-3xl p-8 flex flex-col justify-between">
          <div>
            <div className="w-12 h-12 bg-blue-600 text-white rounded-2xl flex items-center justify-center mb-6 shadow-md shadow-blue-500/20">
              <Zap size={24} className="fill-white" />
            </div>
            <h3 className="text-xl font-bold text-foreground mb-2">Hızlı Tarama</h3>
            <p className="text-muted text-sm leading-relaxed mb-6">
              Yeni belgeleri otomatik tarayın ve kategorize edin.
            </p>
          </div>
          <button className="text-blue-600 dark:text-blue-400 font-bold text-sm inline-flex items-center gap-2 hover:opacity-80 transition-opacity self-start">
            Hemen Başlat
            <span className="text-xl leading-none">→</span>
          </button>
        </div>
      </div>
    </div>
  );
}
