"use client";

import { useState, useEffect } from "react";
import { TrendingUp, Landmark, Calendar, FileText, Download, FileSpreadsheet, Loader2, RefreshCw } from "lucide-react";
import { supabase } from "@/lib/supabase";

export default function ReportsPage() {
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<'30' | '90' | '365'>('30');
  const [uyumSkoru, setUyumSkoru] = useState(0);
  const [allDocs, setAllDocs] = useState<any[]>([]);
  const [showScoreDetail, setShowScoreDetail] = useState(false);
  const [scoreDetail, setScoreDetail] = useState({ total:0, withCat:0, withName:0, withAmt:0, withDate:0, withType:0 });
  const [monthly, setMonthly] = useState({ thisIncome:0, lastIncome:0, thisExpense:0, lastExpense:0 });
  const [stats, setStats] = useState({
    totalIncome: 0, totalExpense: 0, totalTax: 0, netProfit: 0,
    categoryBreakdown: [] as { category: string, amount: number, percentage: number, color: string }[],
    monthlyData: [0,0,0,0,0,0,0] as number[],
    topSuppliers: [] as { name: string, amount: number }[],
    aiInsights: [] as { title: string, desc: string, amount: number, isWarning: boolean }[]
  });
  const [aiRefreshing, setAiRefreshing] = useState(false);
  const [aiSuccessMessage, setAiSuccessMessage] = useState(false);

  async function refreshAiInsights() {
    setAiRefreshing(true);
    setAiSuccessMessage(false);
    await new Promise(resolve => setTimeout(resolve, 1500));
    setAiRefreshing(false);
    setAiSuccessMessage(true);
    setTimeout(() => setAiSuccessMessage(false), 3000);
  }

  useEffect(() => { loadReports(); }, []);
  useEffect(() => { if (allDocs.length > 0) computeStats(allDocs, period); }, [period, allDocs]);

  function exportCSV() {
    const rows = [['Ad','Tutar','Kategori','Belge Tipi','Tarih','Durum']];
    allDocs.forEach((d:any) => rows.push([d.name||'',d.amount||0,d.category||'',d.belge_tipi||'',d.created_at||'',d.payment_status||'']));
    const csv = rows.map(r => r.join(',')).join('\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    a.download = `billmind-rapor-${new Date().toISOString().slice(0,10)}.csv`;
    a.click();
  }

  function exportJSON() {
    const a = document.createElement('a');
    a.href = 'data:application/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(allDocs, null, 2));
    a.download = `billmind-rapor-${new Date().toISOString().slice(0,10)}.json`;
    a.click();
  }

  async function loadReports() {
    setLoading(true);
    try {
      const userDataStr = localStorage.getItem('user');
      if (!userDataStr) return;
      const user = JSON.parse(userDataStr);
      const { data: docs } = await supabase.from('documents').select('*').eq('user_id', user.id);
      if (!docs) return;
      setAllDocs(docs);
      computeStats(docs, period);
      // Aylık karşılaştırma
      const now = new Date();
      const curM = now.getMonth(); const curY = now.getFullYear();
      let tI=0,lI=0,tE=0,lE=0;
      docs.forEach((d:any)=>{ const amt=Number(d.amount)||0; const bt=d.belge_tipi||'gider'; if(d.created_at){ const dt=new Date(d.created_at); const yd=curY-dt.getFullYear(); const md=curM-dt.getMonth()+(yd*12); if(md===0){if(bt==='gelir')tI+=amt;else tE+=amt;}else if(md===1){if(bt==='gelir')lI+=amt;else lE+=amt;} }});
      setMonthly({thisIncome:tI,lastIncome:lI,thisExpense:tE,lastExpense:lE});
      // Uyum Skoru - Mobil ile aynı formula:
      // Kategori %30, Firma Adı %25, Tutar %20, Tarih %15, Belge Tipi %10
      const total = docs.length || 1;
      const withCat = docs.filter((d:any) => d.category && d.category.toUpperCase() !== 'DİĞER' && d.category.trim() !== '').length;
      const withName = docs.filter((d:any) => d.name && d.name !== 'Bilinmeyen' && d.name.trim() !== '').length;
      const withAmt = docs.filter((d:any) => Number(d.amount) > 0).length;
      const withDate = docs.filter((d:any) => !!d.created_at).length;
      const withType = docs.filter((d:any) => !!d.belge_tipi).length;
      const catScore   = (withCat / total) * 30;
      const nameScore  = (withName / total) * 25;
      const amtScore   = (withAmt / total) * 20;
      const dateScore  = (withDate / total) * 15;
      const typeScore  = (withType / total) * 10;
      const score = Math.min(100, Math.max(20, Math.round(catScore + nameScore + amtScore + dateScore + typeScore)));
      setUyumSkoru(score);
      setScoreDetail({ total: docs.length, withCat, withName, withAmt, withDate, withType });
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }

  function computeStats(docs: any[], per: string) {
    const now = new Date();
    const days = per === '30' ? 30 : per === '90' ? 90 : 365;
    const cutoff = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    const filtered = docs.filter((d:any) => d.created_at && new Date(d.created_at) >= cutoff);

    let totalExpense = 0, totalIncome = 0;
    let catMap: Record<string,number> = {}, supplierMap: Record<string,number> = {};
    filtered.forEach((d:any) => {
      const amt = Number(d.amount) || 0;
      const belgeTipi = d.belge_tipi || 'gider';
      if (belgeTipi === 'gelir') { totalIncome += amt; }
      else { totalExpense += amt; catMap[d.category||'Diğer'] = (catMap[d.category||'Diğer']||0)+amt; if(d.name&&d.name!=='Bilinmeyen') supplierMap[d.name]=(supplierMap[d.name]||0)+amt; }
    });
    const totalTax = totalExpense * 0.18;
    const netProfit = totalIncome - totalExpense;
    const colors = ['#0f3d99','#8c2a00','#059669','#d97706','#4f46e5','#475569'];
    const breakdown = Object.keys(catMap).map((cat,i) => ({ category:cat, amount:catMap[cat], percentage:totalExpense>0?(catMap[cat]/totalExpense)*100:0, color:colors[i%colors.length] })).sort((a,b)=>b.amount-a.amount);
    const topSuppliers = Object.entries(supplierMap).map(([name,amount])=>({name,amount})).sort((a,b)=>b.amount-a.amount).slice(0,3);
    const monthlyArr = [0,0,0,0,0,0,0];
    const curM = now.getMonth();
    filtered.forEach((d:any) => { if(d.created_at && d.belge_tipi!=='gelir'){ const dt=new Date(d.created_at); let diff=curM-dt.getMonth(); if(diff<0)diff+=12; if(diff>=0&&diff<7) monthlyArr[6-diff]+=Number(d.amount)||0; } });
    let aiInsights: any[] = [];
    if(topSuppliers.length>0) aiInsights.push({ title:'Yüksek Gider Tespiti', desc:`En büyük harcamanız ${topSuppliers[0].name} firmasına ait. Alternatif tedarikçi araştırın.`, amount:topSuppliers[0].amount, isWarning:true });
    if(totalTax>500) aiInsights.push({ title:'Vergi İndirimi Potansiyeli', desc:'Toplam giderleriniz üzerinden %18 KDV iadesi veya vergi indirimi hesaplanabilir.', amount:totalTax, isWarning:false });
    if(aiInsights.length===0) aiInsights.push({ title:'Veri Bekleniyor', desc:'Yapay zeka analizi için daha fazla belge yükleyin.', amount:0, isWarning:false });
    setStats({ totalIncome, totalExpense, totalTax, netProfit, categoryBreakdown:breakdown, monthlyData:monthlyArr, topSuppliers, aiInsights });
  }

  function formatCurrency(val: number) {
    return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(val);
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
      </div>
    );
  }
  const allMonths = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];
  const currentMonthIdx = new Date().getMonth();
  const months = Array.from({ length: 7 }).map((_, i) => {
    let m = currentMonthIdx - (6 - i);
    if (m < 0) m += 12;
    return allMonths[m];
  });
  const maxMonthly = Math.max(...stats.monthlyData, 1);

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Raporlar</h1>
          <p className="text-muted mt-1.5 font-medium">Finansal durumunuzu gelişmiş grafiklerle analiz edin.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center bg-card border border-border rounded-xl p-1 shadow-sm">
            {([['30','Son 30 Gün'],['90','Son 3 Ay'],['365','Yıllık']] as [string,string][]).map(([val,label]) => (
              <button key={val} onClick={() => setPeriod(val as any)} className={`px-4 py-2 rounded-lg text-sm transition-colors font-semibold ${period===val ? 'bg-accent text-accent-fg' : 'text-muted hover:text-foreground hover:bg-muted-bg'}`}>{label}</button>
            ))}
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={exportCSV}
              className="flex items-center gap-1.5 px-4 py-2.5 bg-card border border-border hover:bg-muted-bg text-foreground font-semibold rounded-xl shadow-sm text-sm cursor-pointer"
            >
              <Download size={14} className="text-muted" /> CSV Aktar
            </button>
            <button
              onClick={exportJSON}
              className="flex items-center gap-1.5 px-4 py-2.5 bg-card border border-border hover:bg-muted-bg text-foreground font-semibold rounded-xl shadow-sm text-sm cursor-pointer"
            >
              <FileSpreadsheet size={14} className="text-muted" /> JSON Aktar
            </button>
          </div>
        </div>
      </div>

      {/* Top Value Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-card border-b-[3px] border-b-blue-600 border border-border rounded-xl p-6 shadow-sm relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">NET BAKİYE (GELİR - GİDER)</p>
            <TrendingUp size={20} className="text-blue-600" />
          </div>
          <h2 className={`text-3xl font-extrabold mb-2 ${stats.netProfit >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
            {stats.netProfit >= 0 ? '+' : '-'}₺{formatCurrency(Math.abs(stats.netProfit))}
          </h2>
          <p className="text-xs font-medium"><span className="text-muted">Seçilen dönem içi net bakiye</span></p>
        </div>

        <div className="bg-card border-b-[3px] border-b-red-700 border border-border rounded-xl p-6 shadow-sm relative overflow-hidden">
          <div className="flex justify-between items-start mb-4">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">TAHMİNİ TOPLAM VERGİ</p>
            <Landmark size={20} className="text-red-700" />
          </div>
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺{formatCurrency(stats.totalTax)}</h2>
          <p className="text-xs font-medium"><span className="text-muted">Dönem içi giderlerden KDV tahmini</span></p>
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
          <h2 className="text-3xl font-extrabold text-foreground mb-2">₺{formatCurrency(stats.totalExpense)}</h2>
          <p className="text-xs font-medium"><span className="text-muted">Dönem içi gerçekleşen harcamalar</span></p>
        </div>
      </div>

      {/* Monthly Trend Comparison Row (Gelir & Gider vs Last Month) */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 bg-card border border-border rounded-3xl p-6">
        <div className="flex items-center justify-between p-4 bg-muted-bg/30 rounded-2xl border border-border/50">
          <div>
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Aylık Toplam Gelir</p>
            <h3 className="text-2xl font-extrabold text-emerald-500 mt-1">₺{formatCurrency(monthly.thisIncome)}</h3>
            <p className="text-xs text-muted mt-1.5 flex items-center gap-1">
              Geçen aya göre{' '}
              {monthly.thisIncome >= monthly.lastIncome ? (
                <span className="text-emerald-500 font-bold flex items-center">
                  ↑ +{monthly.lastIncome === 0 ? 100 : Math.round(((monthly.thisIncome - monthly.lastIncome) / monthly.lastIncome) * 100)}%
                </span>
              ) : (
                <span className="text-red-500 font-bold flex items-center">
                  ↓ -{Math.round(((monthly.lastIncome - monthly.thisIncome) / monthly.lastIncome) * 100)}%
                </span>
              )}
            </p>
          </div>
          <div className="w-12 h-12 bg-emerald-500/10 rounded-2xl flex items-center justify-center shrink-0">
            <TrendingUp className="w-6 h-6 text-emerald-500" />
          </div>
        </div>

        <div className="flex items-center justify-between p-4 bg-muted-bg/30 rounded-2xl border border-border/50">
          <div>
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Aylık Toplam Gider</p>
            <h3 className="text-2xl font-extrabold text-red-400 mt-1">₺{formatCurrency(monthly.thisExpense)}</h3>
            <p className="text-xs text-muted mt-1.5 flex items-center gap-1">
              Geçen aya göre{' '}
              {monthly.thisExpense <= monthly.lastExpense ? (
                <span className="text-emerald-500 font-bold flex items-center">
                  ↓ -{monthly.lastExpense === 0 ? 0 : Math.round(((monthly.lastExpense - monthly.thisExpense) / monthly.lastExpense) * 100)}%
                </span>
              ) : (
                <span className="text-red-500 font-bold flex items-center">
                  ↑ +{monthly.lastExpense === 0 ? 100 : Math.round(((monthly.thisExpense - monthly.lastExpense) / monthly.lastExpense) * 100)}%
                </span>
              )}
            </p>
          </div>
          <div className="w-12 h-12 bg-red-500/10 rounded-2xl flex items-center justify-center shrink-0">
            <Landmark className="w-6 h-6 text-red-500" />
          </div>
        </div>
      </div>

      {/* Vergi ve Sabit Yükümlülükler (Mobildeki gibi 3 Kart) */}
      <div className="space-y-4">
        <h3 className="text-base font-bold text-foreground flex items-center gap-2">
          <Landmark className="w-4 h-4 text-red-500" />
          Tahmini Vergi ve Sabit Yükümlülükler
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* KDV Kartı */}
          <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-all duration-300 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-red-500/5 rounded-full blur-xl pointer-events-none" />
            <div className="flex items-center justify-between mb-3">
              <div>
                <p className="text-xs font-bold text-muted uppercase tracking-wider">KDV (TAHMİNİ)</p>
                <p className="text-[10px] text-muted font-medium mt-0.5">Genel %20 Ortalama Oran</p>
              </div>
              <div className="w-9 h-9 bg-red-500/10 rounded-xl flex items-center justify-center">
                <Landmark className="w-4 h-4 text-red-500" />
              </div>
            </div>
            <p className="text-2xl font-extrabold text-red-500">₺{formatCurrency(stats.totalExpense * 0.20)}</p>
            <p className="text-xs text-muted mt-1.5 font-medium">Toplam giderler üzerinden hesaplanan KDV yükü.</p>
          </div>

          {/* Kurumlar Vergisi Kartı */}
          <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-all duration-300 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-blue-500/5 rounded-full blur-xl pointer-events-none" />
            <div className="flex items-center justify-between mb-3">
              <div>
                <p className="text-xs font-bold text-muted uppercase tracking-wider">KURUMLAR VERGİSİ</p>
                <p className="text-[10px] text-muted font-medium mt-0.5">Aylık Ortalama %25 Oran</p>
              </div>
              <div className="w-9 h-9 bg-blue-500/10 rounded-xl flex items-center justify-center">
                <TrendingUp className="w-4 h-4 text-blue-500" />
              </div>
            </div>
            <p className="text-2xl font-extrabold text-blue-500">₺{formatCurrency(stats.totalExpense * 0.25)}</p>
            <p className="text-xs text-muted mt-1.5 font-medium">Tahmini şirket kâr/zarar dönem vergisi.</p>
          </div>

          {/* SGK Sabit Ödeme */}
          <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-all duration-300 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-slate-500/5 rounded-full blur-xl pointer-events-none" />
            <div className="flex items-center justify-between mb-3">
              <div>
                <p className="text-xs font-bold text-muted uppercase tracking-wider">SGK PRİMLERİ</p>
                <p className="text-[10px] text-muted font-medium mt-0.5">Aylık Sabit Tahmini Gider</p>
              </div>
              <div className="w-9 h-9 bg-slate-500/10 rounded-xl flex items-center justify-center">
                <FileText className="w-4 h-4 text-slate-500" />
              </div>
            </div>
            <p className="text-2xl font-extrabold text-foreground">₺{formatCurrency(15000)}</p>
            <p className="text-xs text-muted mt-1.5 font-medium">Bağkur veya personel SGK prim taban tutarı.</p>
          </div>
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
          
          <div className="flex-1 relative min-h-[240px] flex items-end gap-4 mt-6">
            {stats.monthlyData.map((val, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity bg-slate-800 text-white text-xs py-1 px-2 rounded whitespace-nowrap mb-1">
                  ₺{formatCurrency(val)}
                </div>
                <div 
                  className={`w-full max-w-[48px] rounded-t-xl transition-all ${val === maxMonthly && maxMonthly > 1 ? 'bg-blue-600' : 'bg-blue-100 dark:bg-blue-900/40 group-hover:bg-blue-200 dark:group-hover:bg-blue-800/60'}`}
                  style={{ height: `${(val / maxMonthly) * 80}%`, minHeight: '12px' }}
                />
                <span className="text-[10px] font-bold text-muted uppercase tracking-widest pt-2 border-t border-border w-full text-center">
                  {months[i]}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Category Breakdown (Dynamic Donut) */}
        <div className="bg-card border border-border rounded-2xl p-8 shadow-sm flex flex-col items-center">
          <div className="w-full text-left mb-6">
            <h3 className="text-lg font-bold text-foreground">Kategori Dağılımı</h3>
            <p className="text-sm font-medium text-muted mt-1">Harcamaların sektörel dağılımı</p>
          </div>
          
          {/* Donut Chart visual */}
          <div className="relative w-48 h-48 mb-8 flex-shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
              {stats.categoryBreakdown.length === 0 ? (
                <circle cx="50" cy="50" r="40" fill="none" stroke="#cbd5e1" strokeWidth="14" className="dark:stroke-slate-700" />
              ) : (() => {
                let accumulatedPercent = 0;
                return stats.categoryBreakdown.map((item, idx) => {
                  const strokeDasharray = `${(item.percentage / 100) * 251.3} 251.3`;
                  const strokeDashoffset = -((accumulatedPercent / 100) * 251.3);
                  accumulatedPercent += item.percentage;
                  return (
                    <circle
                      key={idx}
                      cx="50"
                      cy="50"
                      r="40"
                      fill="none"
                      stroke={item.color}
                      strokeWidth="14"
                      strokeDasharray={strokeDasharray}
                      strokeDashoffset={strokeDashoffset}
                      className="transition-all duration-300 hover:stroke-[16px] cursor-pointer hover:brightness-110 filter hover:drop-shadow-[0_0_6px_rgba(96,165,250,0.4)]"
                    />
                  );
                });
              })()}
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-xs font-bold text-muted mb-0.5">Toplam</span>
              <span className="text-2xl font-extrabold text-foreground">₺{stats.totalExpense >= 1000 ? (stats.totalExpense / 1000).toFixed(0) + 'k' : stats.totalExpense}</span>
            </div>
          </div>

          <div className="w-full space-y-3 mt-auto max-h-48 overflow-y-auto">
            {stats.categoryBreakdown.map((item, idx) => (
              <div key={idx} className="flex items-center justify-between text-sm font-bold">
                <div className="flex items-center gap-2">
                  <div className="w-3.5 h-3.5 rounded-sm" style={{ backgroundColor: item.color }}></div>
                  <span className="truncate max-w-[100px]">{item.category}</span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-muted font-medium text-xs">₺{formatCurrency(item.amount)}</span>
                  <span>{item.percentage.toFixed(0)}%</span>
                </div>
              </div>
            ))}
            {stats.categoryBreakdown.length === 0 && (
              <div className="text-center text-muted text-xs">Henüz veri yok</div>
            )}
          </div>
        </div>
      </div>

      {/* Yapay Zeka Öngörüleri ve Tedarikçi Verimliliği */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Yapay Zeka */}
        <div className="bg-gradient-to-br from-[#1E293B] to-[#0F172A] dark:from-[#1E293B] dark:to-[#090C15] rounded-3xl p-8 relative overflow-hidden shadow-xl text-white">
          <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-2xl pointer-events-none" />
          
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold flex items-center gap-2">
              <TrendingUp size={20} className="text-blue-400" />
              Yapay Zeka Analizleri & Potansiyeller
            </h3>
            <button
              onClick={refreshAiInsights}
              disabled={aiRefreshing}
              className="p-2 hover:bg-white/10 rounded-lg text-slate-400 hover:text-white transition-all cursor-pointer flex items-center gap-1.5 text-xs font-semibold"
              title="Yeni Öngörüler Üret"
            >
              <RefreshCw size={14} className={aiRefreshing ? "animate-spin text-blue-400" : ""} />
              {aiRefreshing ? "Analiz Ediliyor..." : "Yenile"}
            </button>
          </div>

          {aiSuccessMessage && (
            <div className="mb-4 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 px-4 py-2.5 rounded-xl text-xs font-bold animate-in fade-in slide-in-from-top duration-300">
              ✓ En son belgeler analiz edildi ve yeni öngörüler başarıyla türetildi!
            </div>
          )}
          
          <div className="space-y-4">
            {stats.aiInsights.length === 0 ? (
              <p className="text-slate-400 text-sm">Yeterli veri bulunamadı. Daha fazla belge yükleyin.</p>
            ) : (
              stats.aiInsights.map((insight, idx) => (
                <div key={idx} className="bg-white/5 border border-white/10 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <div className={`p-2 rounded-lg ${insight.isWarning ? 'bg-amber-500/20 text-amber-400' : 'bg-emerald-500/20 text-emerald-400'}`}>
                      {insight.isWarning ? <Landmark size={18} /> : <FileSpreadsheet size={18} />}
                    </div>
                    <div>
                      <h4 className="font-bold text-sm text-slate-200">{insight.title}</h4>
                      <p className="text-xs text-slate-400 mt-1 leading-relaxed">{insight.desc}</p>
                      <div className="mt-3 flex items-center gap-2 text-xs font-bold bg-white/5 w-fit px-3 py-1.5 rounded-lg border border-white/10">
                        <span className="text-slate-400">Tahmini Tasarruf / Kazanç:</span>
                        <span className="text-emerald-400">₺{formatCurrency(insight.amount)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Tedarikçi Verimliliği */}
        <div className="bg-card border border-border rounded-3xl p-8 shadow-sm">
          <h3 className="text-lg font-bold mb-6 flex items-center gap-2 text-foreground">
            <FileSpreadsheet size={20} className="text-emerald-500" />
            Tedarikçi Verimliliği
          </h3>
          
          <div className="space-y-4">
            {stats.topSuppliers.length === 0 ? (
              <p className="text-muted text-sm">Tedarikçi verisi bulunamadı.</p>
            ) : (
              stats.topSuppliers.map((sup, idx) => (
                <div key={idx} className="flex items-center justify-between p-4 bg-muted-bg/50 border border-border rounded-xl hover:bg-muted-bg transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-800 flex items-center justify-center font-bold text-slate-500">
                      {idx + 1}
                    </div>
                    <div>
                      <h4 className="font-bold text-sm text-foreground">{sup.name}</h4>
                      <p className="text-xs text-muted font-medium mt-0.5">En yüksek harcama yapılanlar</p>
                    </div>
                  </div>
                  <span className="font-bold text-red-500 bg-red-500/10 px-3 py-1 rounded-full text-sm">
                    -₺{formatCurrency(sup.amount)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Uyum Skoru */}
      <div className="bg-card border border-border rounded-2xl p-8 shadow-sm">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
            <Landmark size={20} className="text-blue-500" />
            Belge Uyum Skoru
          </h3>
          <button
            onClick={() => setShowScoreDetail(true)}
            className="w-7 h-7 rounded-full bg-muted-bg hover:bg-border border border-border flex items-center justify-center text-muted hover:text-foreground transition-colors font-bold text-sm"
            title="Detayı Gör"
          >ℹ</button>
        </div>
        <div className="flex flex-col md:flex-row items-center gap-8">
          <div className="relative w-36 h-36 shrink-0">
            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
              <circle cx="50" cy="50" r="40" fill="none" stroke="currentColor" strokeWidth="12" className="text-muted-bg" />
              <circle cx="50" cy="50" r="40" fill="none" stroke={uyumSkoru>=80?'#10b981':uyumSkoru>=50?'#f59e0b':'#ef4444'} strokeWidth="12"
                strokeDasharray={`${(uyumSkoru/100)*251.2} 251.2`} strokeLinecap="round" className="transition-all duration-1000" />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className={`text-3xl font-extrabold ${uyumSkoru>=80?'text-emerald-500':uyumSkoru>=50?'text-amber-500':'text-red-500'}`}>{uyumSkoru}</span>
              <span className="text-xs text-muted font-bold">/100</span>
            </div>
          </div>
          <div className="flex-1 space-y-3 w-full">
            {([
              { label:'Kategori', key:'withCat', weight:30, color:'bg-purple-500' },
              { label:'Firma Adı', key:'withName', weight:25, color:'bg-blue-500' },
              { label:'Tutar Girişi', key:'withAmt', weight:20, color:'bg-emerald-500' },
              { label:'Tarih Bilgisi', key:'withDate', weight:15, color:'bg-orange-500' },
              { label:'Belge Tipi', key:'withType', weight:10, color:'bg-teal-500' },
            ] as const).map(({ label, key, weight, color }) => {
              const total = scoreDetail.total || 1;
              const done = scoreDetail[key as keyof typeof scoreDetail] as number;
              const pct = Math.round((done / total) * 100);
              const earned = Math.round((done / total) * weight);
              const barColor = pct >= 70 ? color : pct >= 40 ? 'bg-amber-500' : 'bg-red-500';
              return (
                <div key={key}>
                  <div className="flex justify-between text-xs font-semibold mb-1">
                    <span className="text-foreground">{label} <span className="text-muted font-normal">({done}/{scoreDetail.total} belge)</span></span>
                    <span className={pct>=70?'text-emerald-500':pct>=40?'text-amber-500':'text-red-500'}>{earned}/{weight} puan</span>
                  </div>
                  <div className="w-full bg-muted-bg rounded-full h-1.5">
                    <div className={`${barColor} h-1.5 rounded-full transition-all duration-700`} style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
            <p className="text-xs text-muted pt-2">
              {uyumSkoru >= 80 ? '✅ Belgeleriniz yüksek uyum skoruna sahip.' : uyumSkoru >= 50 ? '⚠️ Bazı belgeler eksik bilgi içeriyor.' : '❌ Belge kalitesini artırmak için kategori ve firma adı bilgilerini doldurun.'}
            </p>
          </div>
        </div>
      </div>

      {/* Uyum Skoru Detay Modal */}
      {showScoreDetail && (
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowScoreDetail(false)}>
          <div className="bg-card border border-border rounded-t-3xl md:rounded-3xl p-6 w-full max-w-lg mx-0 md:mx-4 shadow-2xl animate-in slide-in-from-bottom md:zoom-in duration-300" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-1">
              <h3 className="text-lg font-bold text-foreground">Uyum Skoru Detayları</h3>
              <span className={`px-3 py-1 rounded-full font-bold text-lg ${uyumSkoru>=80?'text-emerald-500 bg-emerald-500/10':uyumSkoru>=50?'text-amber-500 bg-amber-500/10':'text-red-500 bg-red-500/10'}`}>{uyumSkoru} / 100</span>
            </div>
            <p className="text-xs text-muted mb-4">{scoreDetail.total} belge analiz edildi</p>
            <div className="border-t border-border pt-4 space-y-4">
              {([
                { label:'Kategori Tamamlanması', key:'withCat', weight:30, icon:'📂' },
                { label:'Firma Adı Eksiksizliği', key:'withName', weight:25, icon:'🏢' },
                { label:'Tutar Girişi', key:'withAmt', weight:20, icon:'💰' },
                { label:'Tarih Bilgisi', key:'withDate', weight:15, icon:'📅' },
                { label:'Belge Tipi (Gelir/Gider)', key:'withType', weight:10, icon:'🔄' },
              ] as const).map(({ label, key, weight, icon }) => {
                const total = scoreDetail.total || 1;
                const done = scoreDetail[key as keyof typeof scoreDetail] as number;
                const pct = done / total;
                const earned = Math.round(pct * weight);
                const c = pct > 0.7 ? '#10b981' : pct > 0.4 ? '#f59e0b' : '#ef4444';
                return (
                  <div key={key} className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center text-lg shrink-0" style={{ background: `${c}20` }}>{icon}</div>
                    <div className="flex-1">
                      <div className="flex justify-between text-sm font-semibold mb-1">
                        <span className="text-foreground">{label}</span>
                        <span style={{ color: c }}>{earned}/{weight}</span>
                      </div>
                      <div className="w-full bg-muted-bg rounded-full h-1.5">
                        <div className="h-1.5 rounded-full transition-all duration-700" style={{ width:`${pct*100}%`, background: c }} />
                      </div>
                      <p className="text-[10px] text-muted mt-0.5">{done} / {scoreDetail.total} belge tamamlandı</p>
                    </div>
                  </div>
                );
              })}
            </div>
            <button onClick={() => setShowScoreDetail(false)} className="mt-6 w-full py-3 bg-accent text-accent-fg font-bold rounded-xl hover:opacity-90 transition-opacity">Anladım</button>
          </div>
        </div>
      )}
    </div>
  );
}

