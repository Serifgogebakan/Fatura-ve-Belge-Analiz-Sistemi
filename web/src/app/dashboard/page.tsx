"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "../../lib/supabase";
import { BarChart3, Upload, FileText, TrendingUp, MoreVertical } from "lucide-react";

const mockDocuments = [
  { name: "Q1_Audit_Report.pdf", size: "2.4 MB", time: "2 SAAT ÖNCE", tag: "Denetim", tagColor: "blue" },
  { name: "Server_Maintenance_Inv_04.jpg", size: "840 KB", time: "DÜN", tag: "Faturalar", tagColor: "orange" },
  { name: "Payroll_Summary_March.xlsx", size: "1.2 MB", time: "2 GÜN ÖNCE", tag: "Bordro", tagColor: "gray" },
];

const monthlyData = [15, 32, 88, 45, 60, 38]; 
const months = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ"];

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        router.push("/login");
      } else {
        setUser(session.user);
        setLoading(false);
      }
    });
  }, [router]);

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const maxBar = Math.max(...monthlyData);

  return (
    <div className="space-y-8">
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
          <button className="ml-2 flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-muted border border-border hover:border-muted transition-colors">
            Kategoriler
          </button>
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
                <TrendingUp className="w-3 h-3" /> +12.4% vs Geçen Yıl
              </span>
            </div>
            <p className="text-slate-300 text-sm font-medium mb-1">Toplam Giderler</p>
            <p className="text-4xl font-extrabold tracking-tight mb-4 text-white">
              ₺42.890<span className="text-2xl font-bold text-slate-400">,50</span>
            </p>
            <div className="flex items-center justify-between">
              <div className="flex -space-x-2">
                {["B", "A", "C"].map((l, i) => (
                  <div key={i} className={`w-8 h-8 rounded-full border-2 border-slate-800 flex items-center justify-center text-xs font-bold ${i === 0 ? 'bg-indigo-500 text-white' : i === 1 ? 'bg-emerald-500 text-white' : 'bg-orange-500 text-white'}`}>{l}</div>
                ))}
                <div className="w-8 h-8 rounded-full bg-slate-700 border-2 border-slate-800 flex items-center justify-center text-xs font-bold text-white">+5</div>
              </div>
              <span className="text-slate-400 text-xs font-medium">2 dk önce güncel</span>
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
          <div className="flex-1 flex flex-col items-center justify-center border-2 border-dashed border-border rounded-2xl p-8 text-center hover:border-accent hover:bg-accent/5 transition-all cursor-pointer group">
            <div className="w-14 h-14 bg-muted-bg group-hover:bg-accent group-hover:text-accent-fg rounded-2xl flex items-center justify-center mb-4 transition-colors">
              <Upload className="w-7 h-7 text-muted group-hover:text-accent-fg transition-colors" />
            </div>
            <p className="font-semibold text-foreground mb-1">Belgeleri Sürükle & Bırak</p>
            <p className="text-xs text-muted">PDF, JPEG veya PNG, 20MB'a kadar</p>
            <button className="mt-4 px-4 py-2 text-sm bg-muted-bg hover:bg-border text-foreground rounded-xl font-medium transition-colors">
              Dosya Seç
            </button>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="lg:col-span-3 bg-card rounded-3xl p-6 border border-border">
          <div className="flex justify-between items-center mb-5">
            <h3 className="font-semibold text-foreground">Son Belgeler</h3>
            <button className="text-sm text-accent hover:opacity-80 transition-opacity font-medium">
              Tümünü Gör
            </button>
          </div>
          <div className="space-y-3">
            {mockDocuments.map((doc, i) => (
              <div key={i} className="flex items-center gap-4 p-3 rounded-2xl hover:bg-muted-bg transition-colors group">
                <div className="w-12 h-12 bg-muted-bg rounded-xl flex items-center justify-center shrink-0">
                  <FileText className="w-5 h-5 text-muted" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate text-foreground">{doc.name}</p>
                  <p className="text-xs text-muted font-medium mt-0.5">{doc.size} • {doc.time}</p>
                </div>
                <span className={`text-xs font-semibold px-3 py-1 rounded-full shrink-0 ${
                  doc.tagColor === 'blue' ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400' :
                  doc.tagColor === 'orange' ? 'bg-orange-500/10 text-orange-600 dark:text-orange-400' :
                  'bg-slate-500/10 text-slate-600 dark:text-slate-400'
                }`}>
                  {doc.tag}
                </span>
                <button className="opacity-0 group-hover:opacity-100 p-2 rounded-lg hover:bg-border transition-all">
                  <MoreVertical className="w-4 h-4 text-muted" />
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
