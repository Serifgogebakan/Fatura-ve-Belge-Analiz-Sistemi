"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { uploadDocument } from "@/lib/uploadDocument";
import { BarChart3, Upload, FileText, TrendingUp, Loader2, CheckCircle2, Trash2, Landmark, X, Download } from "lucide-react";

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [documentToDelete, setDocumentToDelete] = useState<any>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  const [stats, setStats] = useState({
    totalDocuments: 0, totalIncome: 0, totalExpense: 0,
    netBalance: 0, pendingAmount: 0, completedAmount: 0, taxLiability: 0,
  });
  const [trends, setTrends] = useState({ income: 0, expense: 0, docs: 0, pending: 0 });
  const [monthlyChartData, setMonthlyChartData] = useState<number[]>([0,0,0,0,0,0]);
  const [recentDocs, setRecentDocs] = useState<any[]>([]);
  const [pendingPayments, setPendingPayments] = useState<any[]>([]);
  const [quickEntryOpen, setQuickEntryOpen] = useState(false);
  const [quickForm, setQuickForm] = useState({ name: '', amount: '', belge_tipi: 'gider', category: 'FATURA' });
  const [quickSaving, setQuickSaving] = useState(false);
  const [selectedDoc, setSelectedDoc] = useState<any>(null);

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    const userData = localStorage.getItem('user');
    
    if (!token || !userData) {
      router.push("/login");
    } else {
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      fetchDashboardData(parsedUser.id);
    }
  }, [router]);

  async function fetchDashboardData(userId: string) {
    try {
      // Doğrudan Supabase'den çek (field isimleri kesin doğru)
      const { data: docs, error } = await supabase
        .from('documents')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error || !docs) {
        console.error("Supabase hata:", error);
        setLoading(false);
        return;
      }

      let totalIncome = 0, totalExpense = 0, pendingAmount = 0, completedAmount = 0;
      let thisMonthIncome = 0, lastMonthIncome = 0;
      let thisMonthExpense = 0, lastMonthExpense = 0;
      let thisMonthDocs = 0, lastMonthDocs = 0;
      let thisMonthPending = 0, lastMonthPending = 0;
      
      const monthlyArr = [0,0,0,0,0,0];
      const now = new Date();
      const currentMonthIdx = now.getMonth();
      const currentYear = now.getFullYear();

      docs.forEach((d: any) => {
        const amt = Number(d.amount) || 0;
        const belgeTipi = d.belge_tipi || 'gider';
        if (belgeTipi === 'gelir') totalIncome += amt; else totalExpense += amt;
        const ps = (d.payment_status || '').toLowerCase();
        if (ps === 'beklemede' || ps === 'incelemede') pendingAmount += amt;
        else if (ps === 'ödendi') completedAmount += amt;

        if (d.created_at) {
          try {
            const dDate = new Date(d.created_at);
            const yearDiff = currentYear - dDate.getFullYear();
            const mDiff = currentMonthIdx - dDate.getMonth() + (yearDiff * 12);
            if (mDiff >= 0 && mDiff < 6) monthlyArr[5 - mDiff] += amt;
            if (mDiff === 0) {
              thisMonthDocs++;
              if (belgeTipi === 'gelir') thisMonthIncome += amt; else thisMonthExpense += amt;
              if (ps === 'beklemede' || ps === 'incelemede') thisMonthPending += amt;
            } else if (mDiff === 1) {
              lastMonthDocs++;
              if (belgeTipi === 'gelir') lastMonthIncome += amt; else lastMonthExpense += amt;
              if (ps === 'beklemede' || ps === 'incelemede') lastMonthPending += amt;
            }
          } catch {}
        }
      });

      const trendPct = (cur: number, prev: number) => prev === 0 ? (cur > 0 ? 100 : 0) : Math.round(((cur - prev) / prev) * 100);
      setTrends({
        income: trendPct(thisMonthIncome, lastMonthIncome),
        expense: trendPct(thisMonthExpense, lastMonthExpense),
        docs: trendPct(thisMonthDocs, lastMonthDocs),
        pending: trendPct(thisMonthPending, lastMonthPending),
      });

      const taxLiability = totalExpense * 0.18;
      const netBalance = totalIncome - totalExpense;
      setStats({ totalDocuments: docs.length, totalIncome, totalExpense, netBalance, pendingAmount, completedAmount, taxLiability });
      setMonthlyChartData(monthlyArr);
      setRecentDocs(docs.slice(0, 5));
      setPendingPayments(docs.filter((d: any) => { const ps=(d.payment_status||'').toLowerCase(); return ps==='beklemede'||ps==='incelemede'; }).slice(0, 4));
    } catch (err) {
      console.error("Dashboard veri çekme hatası:", err);
    } finally {
      setLoading(false);
    }
  }

  async function markAsPaid(docId: string) {
    try {
      await supabase
        .from('documents')
        .update({ payment_status: 'ödendi' })
        .eq('id', docId);
      if (user) fetchDashboardData(user.id);
    } catch (err) {
      console.error("Ödeme güncelleme hatası:", err);
    }
  }

  async function handleUpload(file: File) {
    setUploading(true);
    setUploadSuccess(false);
    const res = await uploadDocument(file);
    if (res.success) {
      setUploadSuccess(true);
      setTimeout(() => setUploadSuccess(false), 3000);
      if (user) fetchDashboardData(user.id);
    } else {
      alert("Yükleme hatası: " + res.error);
    }
    setUploading(false);
  }

  function onFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleUpload(file);
    e.target.value = "";
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) handleUpload(file);
  }

  async function deleteDocument() {
    if (!documentToDelete || !user) return;
    try {
      await supabase.from('documents').delete().eq('id', documentToDelete.id);
      fetchDashboardData(user.id);
    } catch (err: any) {
      alert("Hata oluştu: " + err.message);
    } finally {
      setDeleteModalOpen(false);
      setDocumentToDelete(null);
    }
  }

  async function saveQuickEntry() {
    if (!user || !quickForm.name || !quickForm.amount) return;
    setQuickSaving(true);
    try {
      await supabase.from('documents').insert({
        user_id: user.id,
        name: quickForm.name,
        amount: Number(quickForm.amount),
        belge_tipi: quickForm.belge_tipi,
        category: quickForm.category,
        payment_status: 'beklemede',
        file_type: 'manual',
        status: 'tamamlandı',
        created_at: new Date().toISOString(),
      });
      setQuickEntryOpen(false);
      setQuickForm({ name: '', amount: '', belge_tipi: 'gider', category: 'FATURA' });
      fetchDashboardData(user.id);
    } catch (err: any) { alert('Hata: ' + err.message); }
    setQuickSaving(false);
  }

  function TrendBadge({ val }: { val: number }) {
    if (val === 0) return <span className="text-[10px] text-muted">Veri yok</span>;
    const up = val > 0;
    return (
      <span className={`text-[10px] font-bold flex items-center gap-0.5 ${up ? 'text-emerald-500' : 'text-red-500'}`}>
        {up ? '↑' : '↓'} {Math.abs(val)}%
        <span className="text-muted font-normal ml-0.5">geçen aya</span>
      </span>
    );
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const allMonths = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ", "TEM", "AĞU", "EYL", "EKİ", "KAS", "ARA"];
  const currentMonthIdx = new Date().getMonth();
  const months = Array.from({ length: 6 }).map((_, i) => {
    let m = currentMonthIdx - (5 - i);
    if (m < 0) m += 12;
    return allMonths[m];
  });



  const maxBar = Math.max(...monthlyChartData, 1);

  function formatCurrency(val: number) {
    return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val);
  }

  function timeAgo(dateStr: string) {
    if (!dateStr) return "Bilinmiyor";
    try {
      const diff = Date.now() - new Date(dateStr).getTime();
      if (isNaN(diff)) return "Bilinmiyor";
      const mins = Math.floor(diff / 60000);
      if (mins < 1) return "Az önce";
      if (mins < 60) return `${mins} dk önce`;
      const hours = Math.floor(mins / 60);
      if (hours < 24) return `${hours} saat önce`;
      const days = Math.floor(hours / 24);
      return `${days} gün önce`;
    } catch {
      return "Bilinmiyor";
    }
  }

  function getDocLabel(fileType: string | null) {
    const t = (fileType || '').toLowerCase();
    if (t.includes('pdf')) return { label: "PDF", bg: "bg-blue-500/10", text: "text-blue-500" };
    if (t.includes('image') || t.includes('jpg') || t.includes('png')) return { label: "Görsel", bg: "bg-orange-500/10", text: "text-orange-500" };
    if (t.includes('excel') || t.includes('xlsx')) return { label: "Excel", bg: "bg-emerald-500/10", text: "text-emerald-500" };
    return { label: "Belge", bg: "bg-slate-500/10", text: "text-slate-500" };
  }

  function getPaymentBadge(status: string) {
    const s = (status || '').toLowerCase();
    if (s === 'ödendi') return { label: "Ödendi", bg: "bg-emerald-500/10", text: "text-emerald-500" };
    if (s === 'incelemede') return { label: "İncelemede", bg: "bg-blue-500/10", text: "text-blue-500" };
    return { label: "Beklemede", bg: "bg-amber-500/10", text: "text-amber-500" };
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* Toast */}
      {uploadSuccess && (
        <div className="fixed top-6 right-6 z-50 flex items-center gap-3 bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-xl animate-in slide-in-from-top duration-300">
          <CheckCircle2 size={20} />
          <span className="font-semibold text-sm">Belge başarıyla yüklendi!</span>
        </div>
      )}

      <input ref={fileInputRef} type="file" accept=".pdf,.png,.jpg,.jpeg" className="hidden" onChange={onFileSelect} />

      {/* Page Header */}
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-muted font-bold uppercase tracking-widest mb-1">Finansal Analiz & Özet</p>
          <h1 className="text-3xl font-bold tracking-tight text-foreground">Genel Bakış Paneli</h1>
          <p className="text-sm text-muted mt-1">
            {new Date().toLocaleDateString('tr-TR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setQuickEntryOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-accent text-accent-fg font-bold text-sm rounded-xl shadow-lg shadow-accent/20 hover:opacity-90 transition-opacity"
          >
            <span className="text-lg leading-none">+</span> Hızlı Ekle
          </button>
          <div className="hidden md:flex items-center gap-2 bg-card border border-border rounded-2xl px-4 py-2.5 shadow-sm">
            <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
            <span className="text-xs font-semibold text-muted">Canlı Veri</span>
          </div>
        </div>
      </div>

      {/* 4 Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-3">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Toplam Belge</p>
            <div className="w-8 h-8 bg-blue-500/10 rounded-xl flex items-center justify-center">
              <FileText className="w-4 h-4 text-blue-500" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-foreground">{stats.totalDocuments}</p>
          <TrendBadge val={trends.docs} />
        </div>
        <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-3">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Toplam Gelir</p>
            <div className="w-8 h-8 bg-emerald-500/10 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-4 h-4 text-emerald-500" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-emerald-500">+₺{formatCurrency(stats.totalIncome)}</p>
          <TrendBadge val={trends.income} />
        </div>
        <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-3">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Toplam Gider</p>
            <div className="w-8 h-8 bg-red-500/10 rounded-xl flex items-center justify-center">
              <Landmark className="w-4 h-4 text-red-500" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-red-400">-₺{formatCurrency(stats.totalExpense)}</p>
          <TrendBadge val={-trends.expense} />
        </div>
        <div className="bg-card border border-border rounded-2xl p-5 hover:shadow-md transition-shadow">
          <div className="flex items-center justify-between mb-3">
            <p className="text-xs font-bold text-muted uppercase tracking-wider">Bekleyen</p>
            <div className="w-8 h-8 bg-amber-500/10 rounded-xl flex items-center justify-center">
              <BarChart3 className="w-4 h-4 text-amber-500" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-amber-500">₺{formatCurrency(stats.pendingAmount)}</p>
          <TrendBadge val={-trends.pending} />
        </div>
      </div>

      {/* Cards Row */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Net Bakiye Card */}
        <div className="lg:col-span-2 bg-gradient-to-br from-[#1E293B] to-[#0F172A] rounded-3xl p-6 relative overflow-hidden shadow-xl">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-2xl" />
          <div className="absolute bottom-0 left-0 w-24 h-24 bg-accent/20 rounded-full translate-y-1/2 -translate-x-1/2 blur-2xl" />
          <div className="relative z-10">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-white/10 rounded-xl p-2.5 backdrop-blur-sm">
                <BarChart3 className="w-5 h-5 text-white" />
              </div>
              <span className="flex items-center gap-1 text-xs bg-green-500/20 text-green-400 px-2.5 py-1 rounded-full font-semibold border border-green-500/20">
                <TrendingUp className="w-3 h-3" /> {stats.totalDocuments} Belge
              </span>
            </div>
            <p className="text-slate-300 text-sm font-medium mb-1">Net Bakiye</p>
            <p className={`text-4xl font-extrabold tracking-tight mb-4 ${stats.netBalance >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
              {stats.netBalance >= 0 ? '+' : ''}₺{formatCurrency(stats.netBalance)}
            </p>
            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between text-xs text-slate-400 font-medium">
                <span>Gelir: <span className="text-emerald-400 font-bold">₺{formatCurrency(stats.totalIncome)}</span></span>
                <span>Gider: <span className="text-red-400 font-bold">₺{formatCurrency(stats.totalExpense)}</span></span>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-400 font-medium mt-1 pt-3 border-t border-white/10">
                <span className="flex items-center gap-1.5"><Landmark className="w-3.5 h-3.5" /> Tahmini Vergi Yükümlülüğü (%18):</span>
                <span className="text-red-400 font-bold">₺{formatCurrency(stats.taxLiability)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Spending Velocity Chart */}
        <div className="lg:col-span-3 bg-card rounded-3xl p-6 border border-border">
          <div className="flex justify-between items-center mb-2">
            <div>
              <h3 className="font-semibold text-foreground">Harcama Hızı</h3>
              <p className="text-xs text-muted mt-0.5">Son 6 aylık gider akışı</p>
            </div>
            <div className="text-right">
              <p className="text-xs text-muted font-medium">Toplam Gider</p>
              <p className="text-sm font-extrabold text-red-400">
                -₺{formatCurrency(monthlyChartData.reduce((a, b) => a + b, 0))}
              </p>
            </div>
          </div>

          {monthlyChartData.every(v => v === 0) ? (
            <div className="flex flex-col items-center justify-center h-36 gap-2">
              <div className="w-12 h-12 bg-muted-bg rounded-2xl flex items-center justify-center">
                <BarChart3 className="w-6 h-6 text-muted" />
              </div>
              <p className="text-sm text-muted font-medium">Grafik için belge yükleyin</p>
              <p className="text-xs text-muted">Belge ekledikçe ödemeler burada görünecek</p>
            </div>
          ) : (
            <>
              {/* Y Axis + Bars */}
              <div className="flex gap-3 mt-4">
                {/* Y Axis Labels */}
                <div className="flex flex-col justify-between text-right pb-5" style={{ minWidth: 44 }}>
                  {[100, 75, 50, 25, 0].map(pct => (
                    <span key={pct} className="text-[9px] text-muted font-medium leading-none">
                      {pct > 0 ? `₺${formatCurrency((maxBar * pct) / 100)}` : '0'}
                    </span>
                  ))}
                </div>

                {/* Bars area with grid */}
                <div className="flex-1 relative">
                  {/* Grid lines */}
                  <div className="absolute inset-0 pb-5 flex flex-col justify-between pointer-events-none">
                    {[0,1,2,3,4].map(i => (
                      <div key={i} className="w-full border-t border-border/40" />
                    ))}
                  </div>

                  {/* Bars */}
                  <div className="relative flex items-end gap-2 h-36 pb-5">
                    {monthlyChartData.map((val, i) => {
                      const heightPct = maxBar > 0 ? (val / maxBar) * 100 : 0;
                      const isMax = val === maxBar && maxBar > 0;
                      const isZero = val === 0;
                      return (
                        <div key={i} className="flex-1 flex flex-col items-center justify-end gap-1 group relative h-full">
                          {/* Tooltip */}
                          {!isZero && (
                            <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 bg-slate-900 text-white text-[10px] py-1.5 px-2.5 rounded-lg opacity-0 group-hover:opacity-100 transition-all duration-200 pointer-events-none z-20 whitespace-nowrap shadow-xl border border-white/10">
                              <span className="font-bold">₺{formatCurrency(val)}</span>
                              <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-slate-900" />
                            </div>
                          )}

                          {/* Bar */}
                          {isZero ? (
                            <div className="w-1.5 h-1.5 rounded-full bg-muted-bg mb-0.5" />
                          ) : (
                            <div
                              className={`w-full rounded-t-lg transition-all duration-300 ease-out origin-bottom cursor-pointer hover:scale-y-[1.04] hover:shadow-lg hover:shadow-accent/40 hover:brightness-110 active:scale-y-95 relative overflow-hidden ${
                                isMax ? 'shadow-lg shadow-accent/30' : ''
                              }`}
                              style={{
                                height: `${Math.max(heightPct, 6)}%`,
                                background: isMax
                                  ? 'linear-gradient(to top, #2563eb, #60a5fa)'
                                  : 'linear-gradient(to top, #334155, #475569)'
                              }}
                            >
                              {isMax && (
                                <div className="absolute inset-0 bg-white/10 animate-pulse" />
                              )}
                            </div>
                          )}

                          <span className={`text-[9px] font-bold tracking-wider uppercase ${
                            isMax ? 'text-accent' : 'text-muted'
                          }`}>{months[i]}</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Document Upload */}
        <div className="lg:col-span-2 bg-card rounded-3xl p-6 border border-border flex flex-col">
          <h3 className="font-semibold text-foreground mb-4">Hızlı Yükleme</h3>
          <div 
            className="flex-1 flex flex-col items-center justify-center border-2 border-dashed border-border rounded-2xl p-8 text-center hover:border-accent hover:bg-accent/5 transition-all cursor-pointer group"
            onClick={() => fileInputRef.current?.click()}
            onDrop={handleDrop}
            onDragOver={(e) => e.preventDefault()}
          >
            <div className="w-14 h-14 bg-muted-bg group-hover:bg-accent group-hover:text-accent-fg rounded-2xl flex items-center justify-center mb-4 transition-colors">
              {uploading ? (
                <Loader2 size={28} className="text-muted group-hover:text-accent-fg animate-spin" />
              ) : (
                <Upload className="w-7 h-7 text-muted group-hover:text-accent-fg transition-colors" />
              )}
            </div>
            <p className="font-semibold text-foreground mb-1">Belgeleri Sürükle & Bırak</p>
            <p className="text-xs text-muted">PDF, JPEG veya PNG, 20MB'a kadar</p>
            <button disabled={uploading} className="mt-4 px-4 py-2 text-sm bg-muted-bg hover:bg-border text-foreground rounded-xl font-medium transition-colors disabled:opacity-50">
              {uploading ? "Yükleniyor..." : "Dosya Seç"}
            </button>
          </div>
        </div>

        {/* Recent Documents */}
        <div className="lg:col-span-3 bg-card rounded-3xl p-6 border border-border">
          <div className="flex justify-between items-center mb-5">
            <h3 className="font-semibold text-foreground">Son Belgeler</h3>
            <button
              onClick={() => router.push("/dashboard/documents")}
              className="text-sm text-accent hover:opacity-80 transition-opacity font-medium"
            >
              Tümünü Gör
            </button>
          </div>
          <div className="space-y-3">
            {recentDocs.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="w-16 h-16 bg-muted-bg rounded-2xl flex items-center justify-center mb-4">
                  <FileText className="w-8 h-8 text-muted" />
                </div>
                <p className="font-semibold text-foreground mb-1">Henüz belge yok</p>
                <p className="text-xs text-muted">Yukarıdaki alandan ilk belgenizi yükleyin.</p>
              </div>
            ) : (
              recentDocs.map((doc, i) => {
                const tag = getDocLabel(doc.file_type);
                const payment = getPaymentBadge(doc.payment_status);
                const belgeTipi = doc.belge_tipi || 'gider';
                const docName = doc.name || doc.original_filename || "Belge";
                return (
                  <div key={i} className="flex items-center gap-4 p-3 rounded-2xl hover:bg-muted-bg transition-colors group cursor-pointer" onClick={() => setSelectedDoc(doc)}>
                    <div className={`w-12 h-12 ${tag.bg} rounded-xl flex items-center justify-center shrink-0`}>
                      <FileText className={`w-5 h-5 ${tag.text}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate text-foreground">{docName}</p>
                      <p className="text-xs text-muted font-medium mt-0.5">
                        <span className={belgeTipi === 'gelir' ? 'text-emerald-500 font-bold' : 'text-red-400 font-bold'}>
                          {belgeTipi === 'gelir' ? '+' : '-'}₺{formatCurrency(Number(doc.amount) || 0)}
                        </span>
                        {' '}• {timeAgo(doc.created_at)}
                      </p>
                    </div>
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full shrink-0 ${payment.bg} ${payment.text}`}>
                      {payment.label}
                    </span>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* Ödeme Hatırlatıcıları */}
      <div className="bg-card rounded-3xl p-6 border border-border">
        <div className="flex justify-between items-center mb-5">
          <div>
            <h3 className="font-semibold text-foreground flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
              Ödeme Hatırlatıcıları
            </h3>
            <p className="text-xs text-muted mt-0.5">Vadesi yaklaşan veya beklemede olan ödemeleriniz</p>
          </div>
        </div>
        
        {pendingPayments.length === 0 ? (
          <div className="py-8 text-center bg-muted-bg/50 rounded-2xl">
            <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2 opacity-50" />
            <p className="font-semibold text-sm text-foreground">Tüm ödemeleriniz tamamlandı!</p>
            <p className="text-xs text-muted">Bekleyen hiçbir ödemeniz bulunmuyor.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {pendingPayments.map((p, i) => {
              const docName = p.name || p.original_filename || "Belge";
              return (
                <div key={i} className="bg-amber-500/5 border border-amber-500/20 rounded-2xl p-4 flex flex-col hover:bg-amber-500/10 transition-colors">
                  <div className="flex justify-between items-start mb-3">
                    <div className="w-8 h-8 rounded-lg bg-amber-500/20 text-amber-600 flex items-center justify-center shrink-0">
                      <FileText size={16} />
                    </div>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-amber-600 bg-amber-500/10 px-2 py-1 rounded-md">
                      {(p.payment_status || 'beklemede').toLowerCase() === 'incelemede' ? 'İnceleniyor' : 'Bekliyor'}
                    </span>
                  </div>
                  <h4 className="font-bold text-sm text-foreground truncate mb-1">{docName}</h4>
                  <p className="text-lg font-extrabold text-foreground mb-3">₺{formatCurrency(Number(p.amount) || 0)}</p>
                  <button 
                    className="mt-auto w-full py-2 bg-amber-500 text-white text-xs font-bold rounded-xl hover:bg-amber-600 transition-colors shadow-lg shadow-amber-500/20"
                    onClick={() => markAsPaid(p.id)}
                  >
                    Ödendi Olarak İşaretle
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {deleteModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-sm w-full mx-4 animate-in fade-in zoom-in duration-200">
            <div className="w-12 h-12 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center mb-4 mx-auto">
               <Trash2 size={24} />
            </div>
            <h3 className="text-xl font-bold text-center text-foreground mb-2">Belgeyi Sil</h3>
            <p className="text-center text-muted mb-6 font-medium text-sm">
              <span className="font-bold text-foreground">{documentToDelete?.name || documentToDelete?.original_filename}</span> adlı belgeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.
            </p>
            <div className="flex gap-3">
              <button 
                onClick={() => { setDeleteModalOpen(false); setDocumentToDelete(null); }}
                className="flex-1 py-2.5 rounded-xl font-bold bg-muted-bg hover:bg-border text-foreground transition-colors"
              >
                İptal
              </button>
              <button 
                onClick={deleteDocument}
                className="flex-1 py-2.5 rounded-xl font-bold bg-red-600 hover:bg-red-700 text-white transition-colors shadow-lg shadow-red-600/20"
              >
                Sil
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Quick Entry Modal */}
      {quickEntryOpen && (
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setQuickEntryOpen(false)}>
          <div className="bg-card border border-border rounded-t-3xl md:rounded-3xl p-6 w-full max-w-md mx-0 md:mx-4 shadow-2xl animate-in slide-in-from-bottom md:zoom-in duration-300" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-foreground mb-1">Hızlı Kayıt</h3>
            <p className="text-xs text-muted mb-5">Yeni bir gelir veya gider ekleyin</p>

            {/* Gelir/Gider Toggle */}
            <div className="flex bg-muted-bg rounded-xl p-1 mb-4">
              {(['gider','gelir'] as const).map(t => (
                <button key={t} onClick={() => setQuickForm(f => ({...f, belge_tipi: t}))}
                  className={`flex-1 py-2 rounded-lg text-sm font-bold transition-all ${quickForm.belge_tipi === t
                    ? t === 'gelir' ? 'bg-emerald-500 text-white shadow' : 'bg-red-500 text-white shadow'
                    : 'text-muted hover:text-foreground'}`}>
                  {t === 'gelir' ? '↑ Gelir' : '↓ Gider'}
                </button>
              ))}
            </div>

            <div className="space-y-3">
              <input
                type="text" placeholder="Açıklama / Firma adı"
                value={quickForm.name}
                onChange={e => setQuickForm(f => ({...f, name: e.target.value}))}
                className="w-full px-4 py-3 bg-muted-bg border border-border rounded-xl text-sm text-foreground placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent"
              />
              <input
                type="number" placeholder="Tutar (₺)"
                value={quickForm.amount}
                onChange={e => setQuickForm(f => ({...f, amount: e.target.value}))}
                className="w-full px-4 py-3 bg-muted-bg border border-border rounded-xl text-sm text-foreground placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent"
              />
              <select
                value={quickForm.category}
                onChange={e => setQuickForm(f => ({...f, category: e.target.value}))}
                className="w-full px-4 py-3 bg-muted-bg border border-border rounded-xl text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-accent"
              >
                {['FATURA','KİRA','PERSONEL','YAZILIM','PAZARLAMA','LOJİSTİK','VERGİ','DİĞER'].map(c => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>

            <div className="flex gap-3 mt-5">
              <button onClick={() => setQuickEntryOpen(false)} className="flex-1 py-3 rounded-xl font-bold bg-muted-bg hover:bg-border text-foreground transition-colors">İptal</button>
              <button onClick={saveQuickEntry} disabled={quickSaving || !quickForm.name || !quickForm.amount}
                className={`flex-1 py-3 rounded-xl font-bold text-white transition-all shadow-lg disabled:opacity-50 ${
                  quickForm.belge_tipi === 'gelir' ? 'bg-emerald-500 hover:bg-emerald-600 shadow-emerald-500/20' : 'bg-red-500 hover:bg-red-600 shadow-red-500/20'
                }`}>
                {quickSaving ? 'Kaydediliyor...' : `${quickForm.belge_tipi === 'gelir' ? 'Gelir' : 'Gider'} Ekle`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Quick View Document Detail Modal */}
      {selectedDoc && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4" onClick={() => setSelectedDoc(null)}>
          <div className="bg-card border border-border p-6 rounded-3xl shadow-2xl max-w-md w-full animate-in fade-in zoom-in duration-200" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between items-start mb-6">
              <div className="flex items-center gap-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${getDocLabel(selectedDoc.file_type).bg}`}>
                  <FileText className={`w-5 h-5 ${getDocLabel(selectedDoc.file_type).text}`} />
                </div>
                <div>
                  <h3 className="font-bold text-foreground text-base truncate max-w-[200px]">{selectedDoc.name || selectedDoc.original_filename || "Belge"}</h3>
                  <span className="inline-flex items-center px-2 py-0.5 rounded-lg text-[10px] font-extrabold bg-muted-bg text-muted border border-border uppercase tracking-wide">
                    {selectedDoc.category || "DİĞER"}
                  </span>
                </div>
              </div>
              <button onClick={() => setSelectedDoc(null)} className="text-muted hover:text-foreground">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4 mb-6">
              <div className="bg-muted-bg/50 p-4 rounded-2xl border border-border/60">
                <p className="text-[10px] font-bold text-muted uppercase tracking-wider mb-1">Tutar & Tip</p>
                <div className="flex items-end justify-between">
                  <p className="text-2xl font-extrabold text-foreground">₺{formatCurrency(Number(selectedDoc.amount) || 0)}</p>
                  <span className={`text-xs font-black px-2.5 py-1 rounded-full ${selectedDoc.belge_tipi === 'gelir' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-red-500/10 text-red-400'}`}>
                    {selectedDoc.belge_tipi === 'gelir' ? 'GELİR' : 'GİDER'}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="bg-muted-bg/30 p-3 rounded-2xl border border-border/60">
                  <p className="text-[10px] font-bold text-muted uppercase tracking-wider mb-1">Tarih</p>
                  <p className="font-bold text-foreground text-xs">{new Date(selectedDoc.created_at).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })}</p>
                </div>
                <div className="bg-muted-bg/30 p-3 rounded-2xl border border-border/60">
                  <p className="text-[10px] font-bold text-muted uppercase tracking-wider mb-1">Ödeme Durumu</p>
                  <div className="flex items-center gap-1.5 mt-0.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${
                      (selectedDoc.payment_status || '').toLowerCase() === 'ödendi' ? 'bg-emerald-500' : (selectedDoc.payment_status || '').toLowerCase() === 'incelemede' ? 'bg-blue-500' : 'bg-amber-500'
                    }`}></span>
                    <p className={`font-bold text-xs ${
                      (selectedDoc.payment_status || '').toLowerCase() === 'ödendi' ? 'text-emerald-500' : (selectedDoc.payment_status || '').toLowerCase() === 'incelemede' ? 'text-blue-500' : 'text-amber-500'
                    }`}>
                      {getPaymentBadge(selectedDoc.payment_status).label}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex gap-2 pt-4 border-t border-border/60">
              {selectedDoc.fileUrl || selectedDoc.cloudinary_secure_url ? (
                <a
                  href={selectedDoc.fileUrl || selectedDoc.cloudinary_secure_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 py-3 rounded-2xl font-bold bg-blue-600 hover:bg-blue-700 transition-colors text-white text-xs shadow-lg shadow-blue-500/20 flex items-center justify-center gap-1.5"
                >
                  <Download size={14} /> Dosyayı Aç
                </a>
              ) : null}
              <button
                onClick={() => {
                  setDocumentToDelete(selectedDoc);
                  setSelectedDoc(null);
                  setDeleteModalOpen(true);
                }}
                className="flex-1 py-3 rounded-2xl font-bold bg-red-500/10 text-red-500 hover:bg-red-500/20 transition-colors text-xs flex items-center justify-center gap-1.5"
              >
                <Trash2 size={14} /> Sil
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
