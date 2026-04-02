"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "../../lib/supabase";
import { BarChart3, Bell, Settings, Search, Upload, FileText, ChevronDown, TrendingUp, TrendingDown, MoreVertical, LayoutDashboard, Archive, Shield, Users, LogOut } from "lucide-react";

const mockDocuments = [
  { name: "Q1_Audit_Report.pdf", size: "2.4 MB", time: "2 SAAT ÖNCE", tag: "Denetim", tagColor: "blue" },
  { name: "Server_Maintenance_Inv_04.jpg", size: "840 KB", time: "DÜN", tag: "Faturalar", tagColor: "orange" },
  { name: "Payroll_Summary_March.xlsx", size: "1.2 MB", time: "2 GÜN ÖNCE", tag: "Bordro", tagColor: "gray" },
];

const monthlyData = [15, 32, 88, 45, 60, 38]; // Ocak-Haziran sahte veri
const months = ["OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ"];

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeNav, setActiveNav] = useState("overview");

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

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push("/login");
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0B1121] flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const navItems = [
    { id: "overview", label: "Genel Bakış", icon: LayoutDashboard },
    { id: "analytics", label: "Analitik", icon: BarChart3 },
    { id: "archive", label: "Arşiv", icon: Archive },
    { id: "vault", label: "Kasa", icon: Shield },
    { id: "team", label: "Ekip", icon: Users },
  ];

  const maxBar = Math.max(...monthlyData);

  return (
    <div className="min-h-screen bg-[#0B1121] text-white flex flex-col" style={{ fontFamily: "'Inter', sans-serif" }}>
      {/* TOP NAVBAR */}
      <header className="flex items-center justify-between px-6 py-4 border-b border-gray-800/60 bg-[#0B1121]/90 backdrop-blur-md sticky top-0 z-50">
        {/* Logo */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <span className="font-bold text-lg tracking-tight">BillMind</span>
        </div>

        {/* Center Nav */}
        <nav className="hidden md:flex items-center gap-1 text-sm">
          {["Dashboard", "Documents", "Reports", "Upload"].map((item) => (
            <Link
              key={item}
              href="#"
              className={`px-4 py-2 rounded-lg transition-colors ${
                item === "Dashboard"
                  ? "text-blue-400 border-b-2 border-blue-400 rounded-none font-semibold"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              {item}
            </Link>
          ))}
        </nav>

        {/* Right side */}
        <div className="flex items-center gap-3">
          <div className="hidden lg:flex items-center gap-2 bg-[#151C2C] border border-gray-800 rounded-xl px-3 py-2 text-sm text-gray-400">
            <Search className="w-4 h-4" />
            <span>İşlem ara...</span>
          </div>
          <button className="relative p-2 rounded-xl hover:bg-gray-800 transition-colors">
            <Bell className="w-5 h-5 text-gray-400" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-blue-500 rounded-full" />
          </button>
          <button className="p-2 rounded-xl hover:bg-gray-800 transition-colors">
            <Settings className="w-5 h-5 text-gray-400" />
          </button>
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-sm font-bold">
            {user?.email?.[0]?.toUpperCase() ?? "U"}
          </div>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* SIDEBAR */}
        <aside className="hidden lg:flex flex-col w-56 border-r border-gray-800/60 bg-[#0D1526] p-4 gap-1 shrink-0">
          {/* User Card */}
          <div className="flex items-center gap-3 p-3 mb-4 bg-[#151C2C] rounded-2xl border border-gray-800">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center font-bold text-sm shrink-0">
              {user?.email?.[0]?.toUpperCase() ?? "U"}
            </div>
            <div className="overflow-hidden">
              <div className="font-semibold text-sm truncate">{user?.user_metadata?.full_name ?? "Kullanıcı"}</div>
              <div className="text-xs text-blue-400 font-medium">PREMIUM ÜYE</div>
            </div>
          </div>

          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveNav(item.id)}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all w-full text-left ${
                activeNav === item.id
                  ? "bg-blue-600/20 text-blue-400 border border-blue-500/30"
                  : "text-gray-400 hover:text-white hover:bg-gray-800/50"
              }`}
            >
              <item.icon className="w-4 h-4" />
              {item.label}
            </button>
          ))}

          <div className="mt-auto">
            <button
              onClick={handleLogout}
              className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-gray-500 hover:text-red-400 hover:bg-red-900/10 transition-all w-full text-left"
            >
              <LogOut className="w-4 h-4" />
              Çıkış Yap
            </button>
          </div>
        </aside>

        {/* MAIN CONTENT */}
        <main className="flex-1 overflow-y-auto p-6 lg:p-8">
          {/* Page Header */}
          <div className="flex items-start justify-between mb-8">
            <div>
              <p className="text-xs text-gray-500 uppercase tracking-widest mb-1 font-medium">Finansal İstihbarat</p>
              <h1 className="text-3xl font-bold tracking-tight">Genel Bakış Paneli</h1>
            </div>
            <div className="flex items-center gap-2">
              {["Aylık", "Çeyreklik", "Yıllık"].map((p) => (
                <button
                  key={p}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                    p === "Aylık"
                      ? "bg-white text-gray-900"
                      : "text-gray-400 hover:text-white"
                  }`}
                >
                  {p}
                </button>
              ))}
              <button className="ml-2 flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-gray-400 border border-gray-700 hover:border-gray-500 transition-colors">
                <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z" /></svg>
                Kategoriler
              </button>
            </div>
          </div>

          {/* Cards Row */}
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-5 mb-6">
            {/* Total Expenses Card */}
            <div className="lg:col-span-2 bg-gradient-to-br from-blue-500 to-blue-700 rounded-3xl p-6 relative overflow-hidden shadow-xl shadow-blue-900/30">
              <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
              <div className="absolute bottom-0 left-0 w-24 h-24 bg-white/5 rounded-full translate-y-1/2 -translate-x-1/2" />
              <div className="relative z-10">
                <div className="flex justify-between items-start mb-4">
                  <div className="bg-white/20 rounded-xl p-2.5">
                    <BarChart3 className="w-5 h-5 text-white" />
                  </div>
                  <span className="flex items-center gap-1 text-xs bg-white/20 text-white px-2.5 py-1 rounded-full font-semibold">
                    <TrendingUp className="w-3 h-3" /> +12.4% vs Geçen Yıl
                  </span>
                </div>
                <p className="text-blue-100 text-sm font-medium mb-1">Toplam Giderler</p>
                <p className="text-4xl font-extrabold tracking-tight mb-4">
                  ₺42.890<span className="text-2xl font-bold text-blue-200">,50</span>
                </p>
                <div className="flex items-center justify-between">
                  <div className="flex -space-x-2">
                    {["B", "A", "C"].map((l, i) => (
                      <div key={i} className={`w-8 h-8 rounded-full border-2 border-blue-600 flex items-center justify-center text-xs font-bold ${i === 0 ? 'bg-indigo-400' : i === 1 ? 'bg-green-400' : 'bg-orange-400'}`}>{l}</div>
                    ))}
                    <div className="w-8 h-8 rounded-full bg-white/20 border-2 border-blue-600 flex items-center justify-center text-xs font-bold text-white">+5</div>
                  </div>
                  <span className="text-blue-200 text-xs">2 dk önce güncellendi</span>
                </div>
              </div>
            </div>

            {/* Spending Velocity Chart */}
            <div className="lg:col-span-3 bg-[#111827] rounded-3xl p-6 border border-gray-800">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h3 className="font-semibold text-white">Harcama Hızı</h3>
                  <p className="text-xs text-gray-500 mt-0.5">Son 30 günlük işlem akışı</p>
                </div>
                <span className="flex items-center gap-1.5 text-xs text-green-400 bg-green-900/30 px-2.5 py-1 rounded-full font-semibold border border-green-800/50">
                  <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
                  AKTİF OTURUM
                </span>
              </div>
              {/* Bar Chart */}
              <div className="flex items-end gap-3 h-28">
                {monthlyData.map((val, i) => (
                  <div key={i} className="flex-1 flex flex-col items-center gap-1">
                    <div
                      className={`w-full rounded-lg transition-all ${val === maxBar ? 'bg-blue-500' : 'bg-gray-700 hover:bg-gray-600'}`}
                      style={{ height: `${(val / maxBar) * 100}%`, minHeight: "8px" }}
                    />
                    <span className="text-[10px] text-gray-500 font-medium">{months[i]}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Bottom Row */}
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-5">
            {/* Document Upload */}
            <div className="lg:col-span-2 bg-[#111827] rounded-3xl p-6 border border-gray-800 flex flex-col">
              <h3 className="font-semibold text-white mb-4">Belge Yönetimi</h3>
              <div className="flex-1 flex flex-col items-center justify-center border-2 border-dashed border-gray-700 rounded-2xl p-8 text-center hover:border-blue-500/50 hover:bg-blue-900/10 transition-all cursor-pointer group">
                <div className="w-14 h-14 bg-gray-800 group-hover:bg-blue-900/40 rounded-2xl flex items-center justify-center mb-4 transition-colors">
                  <Upload className="w-7 h-7 text-gray-400 group-hover:text-blue-400 transition-colors" />
                </div>
                <p className="font-semibold text-gray-300 mb-1">Belgeleri Sürükle & Bırak</p>
                <p className="text-xs text-gray-500">PDF, JPEG veya PNG, 20MB'a kadar</p>
                <button className="mt-4 px-4 py-2 text-sm bg-gray-700 hover:bg-gray-600 rounded-xl font-medium transition-colors">
                  Dosya Seç
                </button>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="lg:col-span-3 bg-[#111827] rounded-3xl p-6 border border-gray-800">
              <div className="flex justify-between items-center mb-5">
                <h3 className="font-semibold text-white">Son Aktivite</h3>
                <button className="text-sm text-blue-400 hover:text-blue-300 transition-colors font-medium">
                  Tümünü Gör
                </button>
              </div>
              <div className="space-y-3">
                {mockDocuments.map((doc, i) => (
                  <div key={i} className="flex items-center gap-4 p-3 rounded-2xl hover:bg-gray-800/50 transition-colors group">
                    <div className="w-10 h-10 bg-gray-800 rounded-xl flex items-center justify-center shrink-0">
                      <FileText className="w-5 h-5 text-gray-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate">{doc.name}</p>
                      <p className="text-xs text-gray-500">{doc.size} • {doc.time}</p>
                    </div>
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-lg shrink-0 ${
                      doc.tagColor === 'blue' ? 'bg-blue-900/40 text-blue-300' :
                      doc.tagColor === 'orange' ? 'bg-orange-900/40 text-orange-300' :
                      'bg-gray-700 text-gray-300'
                    }`}>
                      {doc.tag}
                    </span>
                    <button className="opacity-0 group-hover:opacity-100 p-1 rounded-lg hover:bg-gray-700 transition-all">
                      <MoreVertical className="w-4 h-4 text-gray-400" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* New Transaction FAB */}
          <div className="fixed bottom-8 left-1/2 -translate-x-1/2 lg:left-auto lg:translate-x-0 lg:bottom-8 lg:right-8">
            <button className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-2xl shadow-xl shadow-blue-900/50 font-semibold text-sm transition-all hover:-translate-y-0.5">
              <span className="text-lg font-bold">+</span>
              Yeni İşlem
            </button>
          </div>
        </main>
      </div>
    </div>
  );
}
