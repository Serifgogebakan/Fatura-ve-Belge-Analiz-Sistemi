"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { Search, Download, Plus, MoreVertical, FileText, FileSpreadsheet, FileArchive, Zap, X, Loader2, CheckCircle2 } from "lucide-react";

type Document = {
  id: string;
  name: string;
  original_filename: string;
  file_type: string;
  category: string;
  cloudinary_secure_url: string;
  status: string;
  amount: number | null;
  currency: string;
  payment_status: string;
  created_at: string;
};

export default function DocumentsPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [filter, setFilter] = useState<"all" | "FATURA" | "MAKBUZ">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const perPage = 4;

  useEffect(() => {
    fetchDocuments();
  }, []);

  async function fetchDocuments() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { router.push("/login"); return; }

    const { data, error } = await supabase
      .from("documents")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false });

    if (!error && data) setDocuments(data);
    setLoading(false);
  }

  async function handleFileUpload(file: File) {
    setUploading(true);
    setUploadSuccess(false);

    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await fetch("/api/upload", { method: "POST", body: formData });
      const json = await res.json();

      if (json.success) {
        setUploadSuccess(true);
        setTimeout(() => setUploadSuccess(false), 3000);
        fetchDocuments(); // Listeyi yenile
      } else {
        alert("Yükleme hatası: " + json.error);
      }
    } catch (err: any) {
      alert("Yükleme başarısız: " + err.message);
    } finally {
      setUploading(false);
    }
  }

  function onFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFileUpload(file);
    e.target.value = "";
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) handleFileUpload(file);
  }

  // Filtreleme ve arama
  const filtered = documents.filter((doc) => {
    const matchesFilter = filter === "all" || doc.category === filter;
    const matchesSearch = !searchQuery || 
      doc.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.original_filename?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.category?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / perPage));
  const paginated = filtered.slice((currentPage - 1) * perPage, currentPage * perPage);

  const totalAmount = documents.reduce((s, d) => s + (Number(d.amount) || 0), 0);
  const pendingAmount = documents.filter(d => d.payment_status === "beklemede").reduce((s, d) => s + (Number(d.amount) || 0), 0);

  function formatCurrency(val: number) {
    return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 0 }).format(val);
  }

  function formatDate(dateStr: string) {
    return new Date(dateStr).toLocaleDateString("tr-TR", { day: "2-digit", month: "short", year: "numeric" });
  }

  function getDocIcon(type: string) {
    switch (type) {
      case "pdf": return <FileText className="text-blue-600 w-6 h-6" />;
      case "image": return <FileArchive className="text-orange-600 w-6 h-6" />;
      default: return <FileSpreadsheet className="text-indigo-600 w-6 h-6" />;
    }
  }

  function getDocBg(type: string) {
    switch (type) {
      case "pdf": return "bg-blue-500/10";
      case "image": return "bg-orange-500/10";
      default: return "bg-indigo-500/10";
    }
  }

  function getStatusStyle(status: string) {
    switch (status) {
      case "tamamlandı": return { text: "Tamamlandı", color: "text-emerald-600 bg-emerald-500/10", dot: "bg-emerald-500" };
      case "beklemede": return { text: "Beklemede", color: "text-amber-600 bg-amber-500/10", dot: "bg-amber-500" };
      case "işleniyor": return { text: "İşleniyor", color: "text-blue-600 bg-blue-500/10", dot: "bg-blue-500" };
      default: return { text: status, color: "text-muted bg-muted-bg", dot: "bg-muted" };
    }
  }

  function getPaymentStyle(status: string) {
    switch (status) {
      case "ödendi": return { text: "Ödendi", color: "text-emerald-600", dot: "bg-emerald-500" };
      case "beklemede": return { text: "Beklemede", color: "text-amber-600", dot: "bg-amber-500" };
      case "incelemede": return { text: "İncelemede", color: "text-blue-600", dot: "bg-blue-500" };
      default: return { text: status, color: "text-muted", dot: "bg-muted" };
    }
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* Upload Success Toast */}
      {uploadSuccess && (
        <div className="fixed top-6 right-6 z-50 flex items-center gap-3 bg-emerald-600 text-white px-5 py-3 rounded-xl shadow-xl animate-in slide-in-from-top duration-300">
          <CheckCircle2 size={20} />
          <span className="font-semibold text-sm">Belge başarıyla yüklendi!</span>
        </div>
      )}

      {/* Hidden file input */}
      <input ref={fileInputRef} type="file" accept=".pdf,.png,.jpg,.jpeg" className="hidden" onChange={onFileSelect} />

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
          <button 
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="flex items-center gap-2 px-5 py-2.5 bg-accent text-accent-fg font-semibold rounded-xl shadow-lg shadow-accent/20 hover:opacity-90 transition-all text-sm disabled:opacity-50"
          >
            {uploading ? <Loader2 size={18} className="animate-spin" /> : <Plus size={18} />}
            {uploading ? "Yükleniyor..." : "Yeni Yükle"}
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" size={18} />
          <input 
            type="text"
            value={searchQuery}
            onChange={(e) => { setSearchQuery(e.target.value); setCurrentPage(1); }}
            placeholder="Belge adı veya kategori ile ara..." 
            className="w-full bg-muted-bg/50 border border-border rounded-xl pl-10 pr-4 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-accent/50 transition-shadow"
          />
        </div>
        <div className="flex items-center bg-muted-bg/50 p-1 rounded-xl border border-border w-full md:w-auto">
          {(["all", "FATURA", "MAKBUZ"] as const).map((f) => (
            <button
              key={f}
              onClick={() => { setFilter(f); setCurrentPage(1); }}
              className={`flex-1 md:flex-none px-6 py-2 rounded-lg text-sm font-semibold transition-colors ${
                filter === f ? "bg-card text-foreground shadow-sm" : "text-muted hover:text-foreground"
              }`}
            >
              {f === "all" ? "Tümü" : f === "FATURA" ? "Faturalar" : "Makbuzlar"}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden shadow-sm">
        {paginated.length === 0 ? (
          <div 
            className="flex flex-col items-center justify-center py-16 cursor-pointer hover:bg-muted-bg/30 transition-colors"
            onDrop={handleDrop}
            onDragOver={(e) => e.preventDefault()}
            onClick={() => fileInputRef.current?.click()}
          >
            <div className="w-16 h-16 bg-muted-bg rounded-2xl flex items-center justify-center mb-4">
              <FileText className="w-8 h-8 text-muted" />
            </div>
            <p className="font-bold text-foreground mb-1">Henüz belge yok</p>
            <p className="text-sm text-muted mb-4">Buraya sürükleyerek veya tıklayarak yükleyin</p>
          </div>
        ) : (
          <>
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
                  {paginated.map((doc) => {
                    const payment = getPaymentStyle(doc.payment_status);
                    return (
                      <tr key={doc.id} className="hover:bg-muted-bg/30 transition-colors group cursor-pointer">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-4">
                            <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${getDocBg(doc.file_type)}`}>
                              {getDocIcon(doc.file_type)}
                            </div>
                            <div>
                              <p className="font-bold text-foreground text-sm">{doc.name}</p>
                              <p className="text-xs text-muted font-medium mt-0.5">{doc.original_filename}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 font-medium text-sm text-muted">{formatDate(doc.created_at)}</td>
                        <td className="px-6 py-4">
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-muted-bg text-muted border border-border">
                            {doc.category || "DİĞER"}
                          </span>
                        </td>
                        <td className="px-6 py-4 font-bold text-foreground text-sm">
                          {doc.amount ? `₺${formatCurrency(doc.amount)}` : "—"}
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center gap-1.5 text-xs font-bold`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${payment.dot}`}></span>
                            <span className={payment.color}>{payment.text}</span>
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          {doc.cloudinary_secure_url && (
                            <a 
                              href={doc.cloudinary_secure_url} 
                              target="_blank" 
                              rel="noopener noreferrer"
                              className="p-2 text-muted hover:text-foreground hover:bg-muted-bg rounded-lg transition-colors inline-flex"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <Download size={18} />
                            </a>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div className="px-6 py-4 border-t border-border flex items-center justify-between text-sm">
              <p className="text-muted font-medium">Toplam {filtered.length} belgeden {(currentPage-1)*perPage+1}-{Math.min(currentPage*perPage, filtered.length)} arası gösteriliyor</p>
              <div className="flex items-center gap-2">
                <button onClick={() => setCurrentPage(p => Math.max(1, p-1))} disabled={currentPage === 1} className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium disabled:opacity-30">{"<"}</button>
                {Array.from({ length: totalPages }, (_, i) => (
                  <button
                    key={i}
                    onClick={() => setCurrentPage(i + 1)}
                    className={`w-8 h-8 rounded-lg flex items-center justify-center font-bold text-sm ${
                      currentPage === i + 1 ? "bg-accent text-accent-fg shadow-sm" : "text-muted hover:bg-muted-bg"
                    }`}
                  >
                    {i + 1}
                  </button>
                ))}
                <button onClick={() => setCurrentPage(p => Math.min(totalPages, p+1))} disabled={currentPage === totalPages} className="w-8 h-8 rounded-lg flex items-center justify-center text-muted hover:bg-muted-bg transition-colors font-medium disabled:opacity-30">{">"}</button>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Bottom Cards Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Smart Summary */}
        <div className="lg:col-span-2 bg-[#1C2333] text-white rounded-3xl p-8 relative overflow-hidden flex flex-col justify-between min-h-[220px]">
          <div className="absolute right-0 top-0 w-64 h-64 bg-slate-700/20 rounded-full blur-3xl -translate-y-1/4 translate-x-1/4 pointer-events-none" />
          <div className="relative z-10 max-w-md">
            <h3 className="text-2xl font-bold tracking-tight mb-2">Akıllı Özet</h3>
            <p className="text-slate-400 text-sm leading-relaxed mb-6">
              {documents.length > 0
                ? `Toplam ${documents.length} belgeniz var. Faturalarınızın durumunu kontrol edin.`
                : "Henüz belge yüklenmedi. İlk belgenizi yükleyerek başlayın."
              }
            </p>
          </div>
          <div className="relative z-10 flex items-end gap-12">
            <div>
              <p className="text-slate-400 text-xs font-bold uppercase tracking-wider mb-2">TOPLAM GİDER</p>
              <p className="text-3xl font-extrabold text-white">₺{formatCurrency(totalAmount)}</p>
            </div>
            <div>
              <p className="text-amber-500/80 text-xs font-bold uppercase tracking-wider mb-2">BEKLEYEN</p>
              <p className="text-3xl font-extrabold text-amber-500">₺{formatCurrency(pendingAmount)}</p>
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
          <button 
            onClick={() => fileInputRef.current?.click()}
            className="text-blue-600 dark:text-blue-400 font-bold text-sm inline-flex items-center gap-2 hover:opacity-80 transition-opacity self-start"
          >
            Hemen Başlat
            <span className="text-xl leading-none">→</span>
          </button>
        </div>
      </div>
    </div>
  );
}
