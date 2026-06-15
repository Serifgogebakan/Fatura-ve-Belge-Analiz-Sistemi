"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { uploadDocument } from "@/lib/uploadDocument";
import { Search, Download, Plus, MoreVertical, FileText, FileSpreadsheet, FileArchive, Zap, X, Loader2, CheckCircle2, Trash2, ChevronDown } from "lucide-react";

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
  belge_tipi: string;
  created_at: string;
};

export default function DocumentsPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [documentToDelete, setDocumentToDelete] = useState<Document | null>(null);
  const [openDropdownId, setOpenDropdownId] = useState<string | null>(null);
  
  // Manuel Giriş State'leri
  const [manualEntryOpen, setManualEntryOpen] = useState(false);
  const [manualSaving, setManualSaving] = useState(false);
  const [manualForm, setManualForm] = useState({
    name: "",
    category: "Fatura",
    amount: "",
    currency: "TRY",
    payment_status: "beklemede",
    belge_tipi: "gider",
    created_at: new Date().toISOString().split("T")[0]
  });
  
  // Düzenleme State'leri
  const [isEditing, setIsEditing] = useState(false);
  const [editSaving, setEditSaving] = useState(false);
  const [editForm, setEditForm] = useState({
    name: "",
    category: "Fatura",
    amount: "",
    currency: "TRY",
    payment_status: "beklemede",
    belge_tipi: "gider",
    created_at: ""
  });

  // Detay Modalı State
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);

  const [filterType, setFilterType] = useState<"all" | "gelir" | "gider">("all");
  const [filterCategory, setFilterCategory] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const perPage = 4;

  useEffect(() => {
    fetchDocuments();
  }, []);

  async function fetchDocuments() {
    const userDataStr = localStorage.getItem('user');
    if (!userDataStr) { router.push("/login"); return; }
    
    const user = JSON.parse(userDataStr);
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5057';
      const res = await fetch(`${API_URL}/api/documents?userId=${user.id}`);
      if (res.ok) {
        const data = await res.json();
        // Backend'den dönen özellikleri eşleştir
        const mappedData = data.map((d: any) => ({
          id: d.id,
          name: d.fileName || "",
          original_filename: d.fileName || "",
          file_type: d.fileType || "pdf",
          category: d.category || "",
          cloudinary_secure_url: d.fileUrl || "",
          status: d.status || "",
          amount: d.totalAmount || 0,
          currency: d.currency || "TRY",
          payment_status: d.payment_status || d.status || "beklemede",
          belge_tipi: d.belge_tipi || "gider",
          created_at: d.uploadedAt || d.created_at || new Date().toISOString()
        }));
        setDocuments(mappedData);
      }
    } catch (err) {
      console.error("Belgeler alınamadı", err);
    }
    
    setLoading(false);
  }

  async function handleFileUpload(file: File) {
    setUploading(true);
    setUploadSuccess(false);

    const res = await uploadDocument(file);
    if (res.success) {
      setUploadSuccess(true);
      setTimeout(() => setUploadSuccess(false), 3000);
      fetchDocuments(); // Listeyi yenile
    } else {
      alert("Yükleme hatası: " + res.error);
    }
    
    setUploading(false);
  }

  async function handleStatusChange(docId: string, newStatus: string) {
    // Optimistic UI update
    setDocuments(docs => docs.map(d => d.id === docId ? { ...d, payment_status: newStatus } : d));
    
    // Update in Supabase
    const { error } = await supabase
      .from('documents')
      .update({ payment_status: newStatus })
      .eq('id', docId);
      
    if (error) {
      alert("Durum güncellenirken hata oluştu: " + error.message);
      fetchDocuments(); // revert
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

  async function deleteDocument() {
    if (!documentToDelete) return;

    try {
      const { error } = await supabase
        .from("documents")
        .delete()
        .eq("id", documentToDelete.id);

      if (error) {
        alert("Silme başarısız: " + error.message);
      } else {
        setDocuments(documents.filter(d => d.id !== documentToDelete.id));
      }
    } catch (err: any) {
      alert("Hata oluştu: " + err.message);
    } finally {
      setDeleteModalOpen(false);
      setDocumentToDelete(null);
    }
  }

  async function handleManualSubmit(e: React.FormEvent) {
    e.preventDefault();
    const userDataStr = localStorage.getItem('user');
    if (!userDataStr) return;
    const user = JSON.parse(userDataStr);

    setManualSaving(true);
    try {
      const { data, error } = await supabase
        .from('documents')
        .insert({
          user_id: user.id,
          name: manualForm.name,
          original_filename: manualForm.name,
          file_type: "manual",
          category: manualForm.category,
          belge_tipi: manualForm.belge_tipi,
          amount: parseFloat(manualForm.amount) || 0,
          currency: manualForm.currency,
          payment_status: manualForm.payment_status,
          status: "tamamlandı",
          created_at: manualForm.created_at
        })
        .select()
        .single();

      if (error) throw error;
      
      setUploadSuccess(true);
      setTimeout(() => setUploadSuccess(false), 3000);
      setManualEntryOpen(false);
      fetchDocuments();
    } catch (err: any) {
      alert("Kayıt sırasında hata oluştu: " + err.message);
    } finally {
      setManualSaving(false);
    }
  }

  const startEditing = () => {
    if (!selectedDocument) return;
    setEditForm({
      name: selectedDocument.name,
      category: selectedDocument.category || "Fatura",
      amount: selectedDocument.amount?.toString() || "0",
      currency: selectedDocument.currency || "TRY",
      payment_status: selectedDocument.payment_status || "beklemede",
      belge_tipi: selectedDocument.belge_tipi || "gider",
      created_at: selectedDocument.created_at ? new Date(selectedDocument.created_at).toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
    });
    setIsEditing(true);
  };

  async function handleEditSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedDocument) return;
    setEditSaving(true);
    try {
      const updatedFields = {
        name: editForm.name,
        category: editForm.category,
        amount: parseFloat(editForm.amount) || 0,
        currency: editForm.currency,
        payment_status: editForm.payment_status,
        belge_tipi: editForm.belge_tipi,
        created_at: new Date(editForm.created_at).toISOString()
      };

      const { error } = await supabase
        .from('documents')
        .update(updatedFields)
        .eq('id', selectedDocument.id);

      if (error) throw error;

      // Local state'i güncelle
      const updatedDoc = {
        ...selectedDocument,
        name: editForm.name,
        category: editForm.category,
        amount: parseFloat(editForm.amount) || 0,
        currency: editForm.currency,
        payment_status: editForm.payment_status,
        belge_tipi: editForm.belge_tipi,
        created_at: new Date(editForm.created_at).toISOString()
      };
      
      setSelectedDocument(updatedDoc);
      setDocuments(docs => docs.map(d => d.id === selectedDocument.id ? updatedDoc : d));
      setIsEditing(false);
    } catch (err: any) {
      alert("Güncelleme sırasında hata oluştu: " + err.message);
    } finally {
      setEditSaving(false);
    }
  }

  // Filtreleme ve arama
  const filtered = documents.filter((doc) => {
    const matchesType = filterType === "all" || doc.belge_tipi === filterType;
    const matchesCat = filterCategory === "all" || doc.category === filterCategory;
    const matchesSearch = !searchQuery || 
      doc.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.original_filename?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.category?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesType && matchesCat && matchesSearch;
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
      case "manual": return <FileSpreadsheet className="text-emerald-600 w-6 h-6" />;
      default: return <FileSpreadsheet className="text-indigo-600 w-6 h-6" />;
    }
  }

  function getDocBg(type: string) {
    switch (type) {
      case "pdf": return "bg-blue-500/10";
      case "image": return "bg-orange-500/10";
      case "manual": return "bg-emerald-500/10";
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
            <span className="hidden sm:inline">İndir</span>
          </button>
          
          <button 
            onClick={() => setManualEntryOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 font-semibold rounded-xl hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors text-sm"
          >
            <FileSpreadsheet size={18} />
            <span className="hidden sm:inline">Manuel Giriş</span>
          </button>

          <button 
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="flex items-center gap-2 px-5 py-2.5 bg-accent text-accent-fg font-semibold rounded-xl shadow-lg shadow-accent/20 hover:opacity-90 transition-all text-sm disabled:opacity-50"
          >
            {uploading ? <Loader2 size={18} className="animate-spin" /> : <Plus size={18} />}
            {uploading ? "Yükleniyor..." : <span className="hidden sm:inline">Yeni Yükle</span>}
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
        <div className="flex flex-col sm:flex-row items-center gap-3 w-full md:w-auto">
          {/* Gelir/Gider Filter */}
          <div className="flex items-center bg-muted-bg/50 p-1 rounded-xl border border-border w-full sm:w-auto">
            {(["all", "gelir", "gider"] as const).map((f) => (
              <button
                key={f}
                onClick={() => { setFilterType(f); setCurrentPage(1); }}
                className={`flex-1 sm:flex-none px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  filterType === f ? (f==='gelir' ? 'bg-emerald-500 text-white shadow-sm' : f==='gider' ? 'bg-red-500 text-white shadow-sm' : 'bg-card text-foreground shadow-sm') : "text-muted hover:text-foreground"
                }`}
              >
                {f === "all" ? "Tümü" : f === "gelir" ? "Gelir" : "Gider"}
              </button>
            ))}
          </div>
          {/* Kategori Seçici */}
          <select 
            value={filterCategory} 
            onChange={(e) => { setFilterCategory(e.target.value); setCurrentPage(1); }}
            className="w-full sm:w-auto bg-muted-bg/50 border border-border rounded-xl px-4 py-2.5 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-accent/50"
          >
            <option value="all">Tüm Kategoriler</option>
            {Array.from(new Set(documents.map(d => d.category).filter(Boolean))).map(c => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
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
                      <tr 
                        key={doc.id} 
                        onClick={() => setSelectedDocument(doc)}
                        className={`hover:bg-muted-bg/30 transition-colors group cursor-pointer ${doc.belge_tipi === 'gelir' ? 'border-l-2 border-l-emerald-500/50' : 'border-l-2 border-l-red-500/20'}`}
                      >
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
                        <td className="px-6 py-4 font-bold text-sm">
                          <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold ${
                            doc.belge_tipi === 'gelir'
                              ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20'
                              : 'bg-red-500/10 text-red-400 border border-red-500/20'
                          }`}>
                            {doc.belge_tipi === 'gelir' ? '+' : '-'}₺{formatCurrency(doc.amount || 0)}
                          </span>
                        </td>
                        <td className="px-6 py-4" onClick={(e) => e.stopPropagation()}>
                          <div className="relative">
                            <button 
                              onClick={(e) => { e.stopPropagation(); setOpenDropdownId(openDropdownId === doc.id ? null : doc.id); }}
                              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-border/50 bg-card hover:bg-muted-bg transition-colors shadow-sm cursor-pointer`}
                            >
                              <span className={`w-2 h-2 rounded-full ${payment.dot}`}></span>
                              <span className={`text-xs font-bold ${payment.color}`}>{payment.text}</span>
                              <ChevronDown size={14} className="text-muted ml-0.5" />
                            </button>
                            
                            {openDropdownId === doc.id && (
                              <div className="absolute top-10 left-0 w-36 bg-card border border-border rounded-xl shadow-xl overflow-hidden z-20 animate-in fade-in slide-in-from-top-2 duration-200">
                                <div className="py-1">
                                  {([
                                    { val: "beklemede", text: "Beklemede", color: "text-amber-600", dot: "bg-amber-500" },
                                    { val: "incelemede", text: "İncelemede", color: "text-blue-600", dot: "bg-blue-500" },
                                    { val: "ödendi", text: "Ödendi", color: "text-emerald-600", dot: "bg-emerald-500" }
                                  ]).map(opt => (
                                    <button
                                      key={opt.val}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        handleStatusChange(doc.id, opt.val);
                                        setOpenDropdownId(null);
                                      }}
                                      className={`w-full text-left px-4 py-2 text-xs font-bold ${opt.color} hover:bg-muted-bg transition-colors flex items-center gap-2`}
                                    >
                                      <span className={`w-1.5 h-1.5 rounded-full ${opt.dot}`}></span>
                                      {opt.text}
                                    </button>
                                  ))}
                                </div>
                              </div>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-right flex items-center justify-end gap-1">
                          {doc.cloudinary_secure_url && (
                            <a 
                              href={doc.cloudinary_secure_url} 
                              target="_blank" 
                              rel="noopener noreferrer"
                              className="p-2 text-muted hover:text-blue-600 hover:bg-blue-500/10 rounded-lg transition-colors inline-flex"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <Download size={18} />
                            </a>
                          )}
                          <button
                            className="p-2 text-muted hover:text-red-600 hover:bg-red-500/10 rounded-lg transition-colors inline-flex"
                            onClick={(e) => {
                              e.stopPropagation();
                              setDocumentToDelete(doc);
                              setDeleteModalOpen(true);
                            }}
                          >
                            <Trash2 size={18} />
                          </button>
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

      {/* Delete Confirmation Modal */}
      {deleteModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-sm w-full mx-4 animate-in fade-in zoom-in duration-200">
            <div className="w-12 h-12 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center mb-4 mx-auto">
               <Trash2 size={24} />
            </div>
            <h3 className="text-xl font-bold text-center text-foreground mb-2">Belgeyi Sil</h3>
            <p className="text-center text-muted mb-6 font-medium text-sm">
              <span className="font-bold text-foreground">{documentToDelete?.original_filename || documentToDelete?.name}</span> adlı belgeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.
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

      {/* Manual Entry Modal */}
      {manualEntryOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-md w-full animate-in fade-in zoom-in duration-200">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-bold text-foreground flex items-center gap-2">
                <FileSpreadsheet className="text-blue-600" size={24} />
                Manuel Veri Girişi
              </h3>
              <button onClick={() => setManualEntryOpen(false)} className="text-muted hover:text-foreground">
                <X size={24} />
              </button>
            </div>

            <form onSubmit={handleManualSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-muted mb-1.5">Kayıt / Belge Adı</label>
                <input 
                  required type="text" 
                  value={manualForm.name} onChange={(e) => setManualForm({...manualForm, name: e.target.value})}
                  className="w-full bg-muted-bg border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500" 
                  placeholder="Örn: Ofis Kırtasiye Gideri"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">Tutar</label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold">₺</span>
                    <input 
                      required type="number" step="0.01"
                      value={manualForm.amount} onChange={(e) => setManualForm({...manualForm, amount: e.target.value})}
                      className="w-full bg-muted-bg border-none rounded-xl pl-9 pr-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold" 
                      placeholder="0.00"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">İşlem Tipi</label>
                  <select 
                    value={manualForm.belge_tipi} onChange={(e) => setManualForm({...manualForm, belge_tipi: e.target.value})}
                    className="w-full bg-muted-bg border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold"
                  >
                    <option value="gider">Gider</option>
                    <option value="gelir">Gelir</option>
                  </select>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">Tarih</label>
                  <input 
                    required type="date" 
                    value={manualForm.created_at} onChange={(e) => setManualForm({...manualForm, created_at: e.target.value})}
                    className="w-full bg-muted-bg border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">Kategori</label>
                  <select 
                    value={manualForm.category} onChange={(e) => setManualForm({...manualForm, category: e.target.value})}
                    className="w-full bg-muted-bg border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold"
                  >
                    <option value="Maaş">Maaş</option>
                    <option value="Kira">Kira</option>
                    <option value="Fatura">Fatura</option>
                    <option value="Market">Market</option>
                    <option value="Vergi">Vergi</option>
                    <option value="Diğer">Diğer</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase text-muted mb-1.5">Ödeme Durumu</label>
                <select 
                  value={manualForm.payment_status} onChange={(e) => setManualForm({...manualForm, payment_status: e.target.value})}
                  className="w-full bg-muted-bg border-none rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold"
                >
                  <option value="ödendi">Ödendi</option>
                  <option value="beklemede">Beklemede</option>
                  <option value="incelemede">İncelemede</option>
                </select>
              </div>

              <div className="pt-4 flex gap-3">
                <button 
                  type="button" onClick={() => setManualEntryOpen(false)}
                  className="flex-1 py-3 rounded-xl font-bold bg-muted-bg hover:bg-border transition-colors text-foreground"
                >
                  İptal
                </button>
                <button 
                  type="submit" disabled={manualSaving}
                  className="flex-1 py-3 rounded-xl font-bold bg-blue-600 hover:bg-blue-700 transition-colors text-white shadow-lg shadow-blue-500/20 flex items-center justify-center gap-2"
                >
                  {manualSaving && <Loader2 size={18} className="animate-spin" />}
                  {manualSaving ? "Kaydediliyor..." : "Kaydet"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Document Detail Modal */}
      {selectedDocument && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-lg w-full animate-in fade-in zoom-in duration-200">
            {isEditing ? (
              <form onSubmit={handleEditSubmit} className="space-y-4">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="text-xl font-bold text-foreground flex items-center gap-2">
                    <FileSpreadsheet className="text-blue-600" size={24} />
                    Belgeyi Düzenle
                  </h3>
                  <button type="button" onClick={() => { setIsEditing(false); }} className="text-muted hover:text-foreground">
                    <X size={24} />
                  </button>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">Kayıt / Belge Adı</label>
                  <input 
                    required type="text" 
                    value={editForm.name} onChange={(e) => setEditForm({...editForm, name: e.target.value})}
                    className="w-full bg-muted-bg border border-border rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 text-foreground" 
                    placeholder="Örn: Ofis Kırtasiye Gideri"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase text-muted mb-1.5">Tutar</label>
                    <div className="relative">
                      <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold">₺</span>
                      <input 
                        required type="number" step="0.01"
                        value={editForm.amount} onChange={(e) => setEditForm({...editForm, amount: e.target.value})}
                        className="w-full bg-muted-bg border border-border rounded-xl pl-9 pr-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold text-foreground" 
                        placeholder="0.00"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase text-muted mb-1.5">İşlem Tipi</label>
                    <select 
                      value={editForm.belge_tipi} onChange={(e) => setEditForm({...editForm, belge_tipi: e.target.value})}
                      className="w-full bg-muted-bg border border-border rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold text-foreground"
                    >
                      <option value="gider">Gider</option>
                      <option value="gelir">Gelir</option>
                    </select>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase text-muted mb-1.5">Tarih</label>
                    <input 
                      required type="date" 
                      value={editForm.created_at} onChange={(e) => setEditForm({...editForm, created_at: e.target.value})}
                      className="w-full bg-muted-bg border border-border rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 text-foreground"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase text-muted mb-1.5">Kategori</label>
                    <select 
                      value={editForm.category} onChange={(e) => setEditForm({...editForm, category: e.target.value})}
                      className="w-full bg-muted-bg border border-border rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold text-foreground"
                    >
                      <option value="Maaş">Maaş</option>
                      <option value="Kira">Kira</option>
                      <option value="Fatura">Fatura</option>
                      <option value="Market">Market</option>
                      <option value="Vergi">Vergi</option>
                      <option value="Diğer">Diğer</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase text-muted mb-1.5">Ödeme Durumu</label>
                  <select 
                    value={editForm.payment_status} onChange={(e) => setEditForm({...editForm, payment_status: e.target.value})}
                    className="w-full bg-muted-bg border border-border rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-blue-500 font-bold text-foreground"
                  >
                    <option value="ödendi">Ödendi</option>
                    <option value="beklemede">Beklemede</option>
                    <option value="incelemede">İncelemede</option>
                  </select>
                </div>

                <div className="pt-4 flex gap-3">
                  <button 
                    type="button" onClick={() => { setIsEditing(false); }}
                    className="flex-1 py-3 rounded-xl font-bold bg-muted-bg hover:bg-border transition-colors text-foreground"
                  >
                    İptal
                  </button>
                  <button 
                    type="submit" disabled={editSaving}
                    className="flex-1 py-3 rounded-xl font-bold bg-blue-600 hover:bg-blue-700 transition-colors text-white shadow-lg shadow-blue-500/20 flex items-center justify-center gap-2"
                  >
                    {editSaving && <Loader2 size={18} className="animate-spin" />}
                    {editSaving ? "Kaydediliyor..." : "Kaydet"}
                  </button>
                </div>
              </form>
            ) : (
              <>
                <div className="flex justify-between items-start mb-6">
                  <div className="flex items-center gap-4">
                    <div className={`w-14 h-14 rounded-xl flex items-center justify-center shrink-0 ${getDocBg(selectedDocument.file_type)}`}>
                      {getDocIcon(selectedDocument.file_type)}
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-foreground mb-1">{selectedDocument.name}</h3>
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-muted-bg text-muted border border-border">
                        {selectedDocument.category || "DİĞER"}
                      </span>
                    </div>
                  </div>
                  <button onClick={() => { setSelectedDocument(null); }} className="text-muted hover:text-foreground">
                    <X size={24} />
                  </button>
                </div>

                <div className="space-y-4 mb-8">
                  <div className="bg-muted-bg/50 p-4 rounded-xl border border-border">
                    <p className="text-xs font-bold text-muted uppercase tracking-wider mb-1">Tutar & Tip</p>
                    <div className="flex items-end justify-between">
                      <p className="text-2xl font-extrabold text-foreground">₺{formatCurrency(selectedDocument.amount || 0)}</p>
                      <span className={`text-sm font-bold px-3 py-1 rounded-full ${selectedDocument.belge_tipi === 'gelir' ? 'bg-emerald-500/10 text-emerald-600' : 'bg-red-500/10 text-red-600'}`}>
                        {selectedDocument.belge_tipi === 'gelir' ? 'GELİR' : 'GİDER'}
                      </span>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="bg-muted-bg/30 p-4 rounded-xl border border-border">
                      <p className="text-xs font-bold text-muted uppercase tracking-wider mb-1">Tarih</p>
                      <p className="font-semibold text-foreground text-sm">{formatDate(selectedDocument.created_at)}</p>
                    </div>
                    <div className="bg-muted-bg/30 p-4 rounded-xl border border-border">
                      <p className="text-xs font-bold text-muted uppercase tracking-wider mb-1">Ödeme Durumu</p>
                      <div className="flex items-center gap-2">
                        <span className={`w-2 h-2 rounded-full ${getPaymentStyle(selectedDocument.payment_status).dot}`}></span>
                        <p className={`font-semibold text-sm ${getPaymentStyle(selectedDocument.payment_status).color}`}>
                          {getPaymentStyle(selectedDocument.payment_status).text}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex gap-3 pt-2 border-t border-border">
                  <button 
                    onClick={startEditing}
                    className="flex-1 py-3 rounded-xl font-bold bg-blue-600 hover:bg-blue-700 transition-colors text-white flex items-center justify-center gap-2"
                  >
                    Düzenle
                  </button>
                  {selectedDocument.cloudinary_secure_url && (
                    <a 
                      href={selectedDocument.cloudinary_secure_url} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="flex-1 py-3 rounded-xl font-bold bg-muted-bg hover:bg-border transition-colors text-foreground flex items-center justify-center gap-2 border border-border"
                    >
                      <Download size={18} />
                      İndir
                    </a>
                  )}
                  <button 
                    onClick={() => {
                      setDocumentToDelete(selectedDocument);
                      setSelectedDocument(null);
                      setDeleteModalOpen(true);
                    }}
                    className="py-3 px-4 rounded-xl font-bold bg-red-500/10 text-red-600 hover:bg-red-500/20 transition-colors flex items-center justify-center gap-2"
                    title="Sil"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
