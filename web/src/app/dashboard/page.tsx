"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "../../lib/supabase";
import { uploadDocument } from "@/lib/uploadDocument";
import { BarChart3, Upload, FileText, TrendingUp, MoreVertical, Loader2, CheckCircle2, Trash2 } from "lucide-react";

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [documentToDelete, setDocumentToDelete] = useState<any>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  // Supabase'den çekilen veriler
  const [stats, setStats] = useState({
    totalDocuments: 0,
    totalAmount: 0,
    pendingCount: 0,
    completedCount: 0,
  });
  const [recentDocs, setRecentDocs] = useState<any[]>([]);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        router.push("/login");
      } else {
        setUser(session.user);
        fetchDashboardData(session.user.id);
      }
    });
  }, [router]);

  async function fetchDashboardData(userId: string) {
    try {
      // Toplam belge sayısı
      const { count: totalDocuments } = await supabase
        .from("documents")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId);

      // Toplam tutar
      const { data: amountData } = await supabase
        .from("documents")
        .select("amount")
        .eq("user_id", userId)
        .not("amount", "is", null);

      const totalAmount = amountData?.reduce((sum, d) => sum + (Number(d.amount) || 0), 0) ?? 0;

      // Bekleyen belgeler
      const { count: pendingCount } = await supabase
        .from("documents")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("payment_status", "beklemede");

      // Tamamlanan belgeler
      const { count: completedCount } = await supabase
        .from("documents")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("status", "tamamlandı");

      setStats({
        totalDocuments: totalDocuments ?? 0,
        totalAmount,
        pendingCount: pendingCount ?? 0,
        completedCount: completedCount ?? 0,
      });

      // Son 5 belge
      const { data: docs } = await supabase
        .from("documents")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(5);

      setRecentDocs(docs ?? []);
    } catch (err) {
      console.error("Dashboard veri çekme hatası:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleUpload(file: File) {
    setUploading(true);
    setUploadSuccess(false);

    const res = await uploadDocument(file);
    if (res.success) {
      setUploadSuccess(true);
      setTimeout(() => setUploadSuccess(false), 3000);
      if (user) fetchDashboardData(user.id); // Yenile
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
      const { error } = await supabase
        .from("documents")
        .delete()
        .eq("id", documentToDelete.id);

      if (error) {
        alert("Silme başarısız: " + error.message);
      } else {
        fetchDashboardData(user.id);
      }
    } catch (err: any) {
      alert("Hata oluştu: " + err.message);
    } finally {
      setDeleteModalOpen(false);
      setDocumentToDelete(null);
    }
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Aylık mock veri (gerçek aylık dağılım yerine geçici)
  const monthlyData = [15, 32, 88, 45, 60, stats.totalDocuments || 38];
  
  // Dinamik ay isimleri (Son 6 ay)
  const allMonths = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ", "TEM", "AĞU", "EYL", "EKİ", "KAS", "ARA"];
  const currentMonthIdx = new Date().getMonth();
  const months = Array.from({ length: 6 }).map((_, i) => {
    let m = currentMonthIdx - (5 - i);
    if (m < 0) m += 12;
    return allMonths[m];
  });

  const maxBar = Math.max(...monthlyData);

  function formatCurrency(val: number) {
    return new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val);
  }

  function timeAgo(dateStr: string) {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins} dk önce`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours} saat önce`;
    const days = Math.floor(hours / 24);
    return `${days} gün önce`;
  }

  function fileTypeTag(type: string | null) {
    switch (type) {
      case "pdf": return { label: "PDF", color: "blue" };
      case "image": return { label: "Görsel", color: "orange" };
      case "excel": return { label: "Excel", color: "green" };
      default: return { label: "Belge", color: "gray" };
    }
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

      {/* Hidden File Input */}
      <input ref={fileInputRef} type="file" accept=".pdf,.png,.jpg,.jpeg" className="hidden" onChange={onFileSelect} />

      {/* Page Header */}
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-muted font-bold uppercase tracking-widest mb-1">Finansal İstihbarat</p>
          <h1 className="text-3xl font-bold tracking-tight text-foreground">Genel Bakış Paneli</h1>
        </div>
        <div className="flex items-center gap-2">
          {["Aylık", "Çeyreklik", "Yıllık"].map((p) => (
            <button
              key={p}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                p === "Aylık"
                  ? "bg-accent text-accent-fg"
                  : "text-muted hover:text-foreground hover:bg-muted-bg"
              }`}
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      {/* Cards Row */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Total Expenses Card */}
        <div className="lg:col-span-2 bg-gradient-to-br from-[#1E293B] to-[#0F172A] dark:from-[#1E293B] dark:to-[#090C15] rounded-3xl p-6 relative overflow-hidden shadow-xl">
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
            <p className="text-slate-300 text-sm font-medium mb-1">Toplam Giderler</p>
            <p className="text-4xl font-extrabold tracking-tight mb-4 text-white">
              ₺{formatCurrency(stats.totalAmount)}
            </p>
            <div className="flex items-center justify-between">
              <div className="flex gap-4 text-xs text-slate-400 font-medium">
                <span>Bekleyen: <span className="text-amber-400 font-bold">{stats.pendingCount}</span></span>
                <span>Tamamlanan: <span className="text-emerald-400 font-bold">{stats.completedCount}</span></span>
              </div>
              <span className="text-slate-400 text-xs font-medium">Anlık veri</span>
            </div>
          </div>
        </div>

        {/* Spending Velocity Chart */}
        <div className="lg:col-span-3 bg-card rounded-3xl p-6 border border-border">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="font-semibold text-foreground">Harcama Hızı</h3>
              <p className="text-xs text-muted mt-0.5">Son 30 günlük işlem akışı</p>
            </div>
            <span className="flex items-center gap-1.5 text-xs text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full font-semibold border border-emerald-500/20">
              <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />
              AKTİF OTURUM
            </span>
          </div>
          {/* Bar Chart */}
          <div className="flex items-end gap-3 h-28">
            {monthlyData.map((val, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-1">
                <div
                  className={`w-full rounded-t-lg transition-all ${val === maxBar ? 'bg-accent' : 'bg-muted-bg/80 hover:bg-muted'}`}
                  style={{ height: `${(val / maxBar) * 100}%`, minHeight: "8px" }}
                />
                <span className="text-[10px] text-muted font-bold tracking-wider">{months[i]}</span>
              </div>
            ))}
          </div>
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

        {/* Recent Activity - Supabase'den gerçek veri */}
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
                const tag = fileTypeTag(doc.file_type);
                return (
                  <div key={i} className="flex items-center gap-4 p-3 rounded-2xl hover:bg-muted-bg transition-colors group">
                    <div className="w-12 h-12 bg-muted-bg rounded-xl flex items-center justify-center shrink-0">
                      <FileText className="w-5 h-5 text-muted" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate text-foreground">{doc.original_filename || doc.name}</p>
                      <p className="text-xs text-muted font-medium mt-0.5">
                        {doc.amount ? `₺${formatCurrency(doc.amount)}` : "Tutar yok"} • {timeAgo(doc.created_at)}
                      </p>
                    </div>
                    <span className={`text-xs font-semibold px-3 py-1 rounded-full shrink-0 ${
                      tag.color === 'blue' ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400' :
                      tag.color === 'orange' ? 'bg-orange-500/10 text-orange-600 dark:text-orange-400' :
                      tag.color === 'green' ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400' :
                      'bg-slate-500/10 text-slate-600 dark:text-slate-400'
                    }`}>
                      {tag.label}
                    </span>
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full shrink-0 ${
                      doc.status === 'tamamlandı' ? 'bg-emerald-500/10 text-emerald-600' :
                      doc.status === 'beklemede' ? 'bg-amber-500/10 text-amber-600' :
                      doc.status === 'işleniyor' ? 'bg-blue-500/10 text-blue-600' :
                      'bg-red-500/10 text-red-600'
                    }`}>
                      {doc.status}
                    </span>
                    <button 
                      className="opacity-0 group-hover:opacity-100 p-2 rounded-lg hover:bg-red-500/10 hover:text-red-600 transition-all text-muted"
                      onClick={(e) => {
                        e.stopPropagation();
                        setDocumentToDelete(doc);
                        setDeleteModalOpen(true);
                      }}
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                );
              })
            )}
          </div>
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
    </div>
  );
}
