"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import { Wallet, TrendingUp, AlertTriangle, Loader2, Target, Plus, X } from "lucide-react";

const CATEGORIES = ['Fatura', 'Fiş', 'Sözleşme', 'Sağlık', 'Finans', 'Lojistik', 'Personel', 'Vergi', 'Diğer'];
const DEFAULT_LIMITS: Record<string, number> = {
  'Fatura': 10000.0, 'Fiş': 5000.0, 'Sözleşme': 8000.0,
  'Sağlık': 3000.0, 'Finans': 15000.0, 'Lojistik': 12000.0,
  'Personel': 50000.0, 'Vergi': 20000.0, 'Diğer': 5000.0,
};

export default function BudgetPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [limits, setLimits] = useState<Record<string, number>>({});
  const [spendings, setSpendings] = useState<Record<string, number>>({});
  
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editCategory, setEditCategory] = useState("");
  const [editLimitStr, setEditLimitStr] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    const userDataStr = localStorage.getItem('user');
    if (!userDataStr) {
      router.push("/login");
      return;
    }
    const user = JSON.parse(userDataStr);
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    try {
      // 1. Harcamaları (Giderleri) documents tablosundan çek
      const { data: docs } = await supabase
        .from('documents')
        .select('category, amount, belge_tipi')
        .eq('user_id', user.id)
        .gte('created_at', firstDay);

      const sp: Record<string, number> = {};
      if (docs) {
        for (const doc of docs) {
          const tipi = (doc.belge_tipi || 'gider').toLowerCase();
          if (tipi === 'gelir') continue;
          const cat = doc.category || 'Diğer';
          sp[cat] = (sp[cat] || 0) + (Number(doc.amount) || 0);
        }
      }

      // 2. Limitleri budgets tablosundan çek
      const { data: bgs } = await supabase
        .from('budgets')
        .select('category, amount_limit')
        .eq('user_id', user.id)
        .eq('month', now.getMonth() + 1)
        .eq('year', now.getFullYear());

      const dbLimits: Record<string, number> = {};
      if (bgs) {
        for (const b of bgs) {
          dbLimits[b.category] = Number(b.amount_limit);
        }
      }

      const finalLimits: Record<string, number> = {};
      const finalSpendings: Record<string, number> = {};

      for (const cat of CATEGORIES) {
        finalLimits[cat] = dbLimits[cat] ?? DEFAULT_LIMITS[cat] ?? 5000;
        finalSpendings[cat] = sp[cat] ?? 0;
      }

      // Supabase'de var olan ama default kategorilerde olmayanları da ekleyelim (eğer varsa)
      if (bgs) {
        for (const b of bgs) {
          if (!CATEGORIES.includes(b.category)) {
             finalLimits[b.category] = Number(b.amount_limit);
             finalSpendings[b.category] = sp[b.category] ?? 0;
          }
        }
      }

      setLimits(finalLimits);
      setSpendings(finalSpendings);

    } catch (err) {
      console.error("Bütçe verileri alınamadı", err);
    }
    setLoading(false);
  }

  function openEditModal(cat: string, currentLimit: number) {
    setEditCategory(cat);
    setEditLimitStr(currentLimit.toString());
    setEditModalOpen(true);
  }

  async function handleSaveLimit(e: React.FormEvent) {
    e.preventDefault();
    const userDataStr = localStorage.getItem('user');
    if (!userDataStr) return;
    const user = JSON.parse(userDataStr);
    
    const val = parseFloat(editLimitStr);
    if (isNaN(val) || val <= 0) return;

    setSaving(true);
    const now = new Date();
    const m = now.getMonth() + 1;
    const y = now.getFullYear();

    try {
      const { data: existing } = await supabase
        .from('budgets')
        .select('id')
        .eq('user_id', user.id)
        .eq('category', editCategory)
        .eq('month', m)
        .eq('year', y)
        .single();

      if (existing) {
        await supabase.from('budgets').update({ amount_limit: val }).eq('id', existing.id);
      } else {
        await supabase.from('budgets').insert({
          user_id: user.id,
          category: editCategory,
          amount_limit: val,
          month: m,
          year: y
        });
      }

      setLimits(prev => ({...prev, [editCategory]: val}));
      setEditModalOpen(false);
    } catch (err: any) {
      alert("Hata oluştu: " + err.message);
    } finally {
      setSaving(false);
    }
  }

  function formatCurrency(val: number) {
    if (val >= 1000000) return (val / 1000000).toFixed(1) + 'M';
    if (val >= 1000) return (val / 1000).toFixed(1) + 'K';
    return val.toFixed(0);
  }

  if (loading) {
    return (
      <div className="min-h-64 flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
      </div>
    );
  }

  const allCats = Object.keys(limits);
  const totalLimit = allCats.reduce((acc, cat) => acc + (limits[cat] || 0), 0);
  const totalSpending = allCats.reduce((acc, cat) => acc + (spendings[cat] || 0), 0);
  const totalPct = totalLimit > 0 ? Math.min(totalSpending / totalLimit, 1) : 0;

  return (
    <div className="space-y-8 animate-in fade-in duration-500 max-w-5xl mx-auto">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground tracking-tight">Bütçe Takibi</h1>
          <p className="text-muted mt-1.5 font-medium">Aylık kategori bazlı harcama limitlerinizi ve durumunuzu izleyin.</p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2.5 bg-card border border-border text-foreground font-medium rounded-xl shadow-sm text-sm">
          <Target size={16} className="text-blue-600" />
          {new Date().toLocaleString('tr-TR', { month: 'long', year: 'numeric' })} Bütçesi
        </div>
      </div>

      {/* Genel Özet Kartı */}
      <div className="bg-gradient-to-br from-blue-700 to-blue-900 rounded-3xl p-8 text-white relative overflow-hidden shadow-lg shadow-blue-900/20">
        <div className="absolute right-0 top-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-1/4 translate-x-1/4 pointer-events-none" />
        <div className="relative z-10">
          <p className="text-blue-200 text-xs font-bold tracking-widest uppercase mb-4">Aylık Genel Bütçe</p>
          <div className="flex flex-col md:flex-row justify-between md:items-end gap-6 mb-8">
            <div>
              <div className="flex items-end gap-3 mb-1">
                <span className="text-5xl font-extrabold tracking-tight">₺{totalSpending.toLocaleString('tr-TR', {maximumFractionDigits:0})}</span>
                <span className="text-blue-200 font-medium mb-1.5">/ ₺{totalLimit.toLocaleString('tr-TR', {maximumFractionDigits:0})}</span>
              </div>
              <p className="text-blue-300 text-sm font-medium">Toplam Harcama / Toplam Limit</p>
            </div>
            <div className="bg-white/10 border border-white/20 backdrop-blur-md rounded-2xl p-4 flex items-center justify-center min-w-[120px]">
              <div className="text-center">
                <span className="block text-2xl font-black text-white">%{(totalPct * 100).toFixed(0)}</span>
                <span className="text-[10px] uppercase font-bold text-blue-200 tracking-wider">Kullanım</span>
              </div>
            </div>
          </div>

          <div className="w-full bg-blue-950/50 rounded-full h-3 overflow-hidden border border-white/10">
            <div 
              className={`h-full rounded-full transition-all duration-1000 ease-out ${totalPct >= 0.9 ? 'bg-red-500' : totalPct >= 0.7 ? 'bg-amber-400' : 'bg-emerald-400'}`}
              style={{ width: `${totalPct * 100}%` }}
            />
          </div>
          <div className="mt-4 flex justify-between text-sm font-medium">
            <span className={totalPct >= 0.9 ? "text-red-300 font-bold flex items-center gap-1" : "text-blue-200"}>
              {totalPct >= 0.9 ? <><AlertTriangle size={14}/> Bütçe sınırına yaklaşıldı!</> : "Durum normal"}
            </span>
            <span className="text-blue-200 font-bold">₺{(totalLimit - totalSpending > 0 ? totalLimit - totalSpending : 0).toLocaleString('tr-TR', {maximumFractionDigits:0})} Kalan</span>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between mt-12 mb-6">
        <h2 className="text-xl font-bold text-foreground">Kategori Bütçeleri</h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {allCats.map(kat => {
          const limit = limits[kat] || 5000;
          const spent = spendings[kat] || 0;
          const pct = limit > 0 ? Math.min(spent / limit, 1) : 0;
          const isOver = pct >= 0.9;
          const barColor = isOver ? "bg-red-500" : pct >= 0.7 ? "bg-amber-500" : "bg-blue-600 dark:bg-blue-500";

          return (
            <div 
              key={kat} 
              onClick={() => openEditModal(kat, limit)}
              className="bg-card border border-border hover:border-blue-500/50 rounded-2xl p-6 shadow-sm hover:shadow-md transition-all cursor-pointer group"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2">
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${isOver ? 'bg-red-500/10 text-red-600' : 'bg-blue-500/10 text-blue-600'}`}>
                    <Wallet size={16} />
                  </div>
                  <h3 className="font-bold text-foreground">{kat}</h3>
                </div>
                {isOver && <AlertTriangle size={16} className="text-red-500 animate-pulse" />}
              </div>
              
              <div className="flex justify-between items-end mb-2">
                <span className="text-xs font-bold text-muted uppercase tracking-wider">Harcama</span>
                <span className="text-sm font-bold text-foreground">₺{formatCurrency(spent)} <span className="text-muted font-medium">/ ₺{formatCurrency(limit)}</span></span>
              </div>
              
              <div className="w-full bg-muted-bg rounded-full h-2 mb-3 overflow-hidden">
                <div 
                  className={`h-full rounded-full transition-all duration-500 ${barColor}`}
                  style={{ width: `${pct * 100}%` }}
                />
              </div>

              <div className="flex justify-between items-center text-xs">
                <span className={`font-bold ${isOver ? 'text-red-500' : 'text-muted'}`}>
                  {isOver ? 'Limit Aşıldı!' : `₺${formatCurrency(limit - spent)} kaldı`}
                </span>
                <span className={`font-black ${isOver ? 'text-red-500' : 'text-foreground'}`}>%{(pct * 100).toFixed(0)}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Edit Limit Modal */}
      {editModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-sm w-full animate-in fade-in zoom-in duration-200">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-bold text-foreground">{editCategory} Limiti</h3>
              <button onClick={() => setEditModalOpen(false)} className="text-muted hover:text-foreground">
                <X size={24} />
              </button>
            </div>
            
            <p className="text-sm text-muted mb-6 font-medium">Bu kategori için aylık harcama hedefinizi güncelleyin.</p>

            <form onSubmit={handleSaveLimit} className="space-y-6">
              <div>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold text-xl">₺</span>
                  <input 
                    required type="number" step="0.01"
                    value={editLimitStr} onChange={(e) => setEditLimitStr(e.target.value)}
                    className="w-full bg-muted-bg border-none rounded-xl pl-10 pr-4 py-4 text-xl focus:ring-2 focus:ring-blue-500 font-extrabold text-foreground" 
                  />
                </div>
              </div>

              <div className="flex gap-3">
                <button 
                  type="button" onClick={() => setEditModalOpen(false)}
                  className="flex-1 py-3.5 rounded-xl font-bold bg-muted-bg hover:bg-border transition-colors text-foreground"
                >
                  İptal
                </button>
                <button 
                  type="submit" disabled={saving}
                  className="flex-1 py-3.5 rounded-xl font-bold bg-blue-600 hover:bg-blue-700 transition-colors text-white shadow-lg shadow-blue-500/20 flex items-center justify-center gap-2"
                >
                  {saving && <Loader2 size={18} className="animate-spin" />}
                  {saving ? "Kaydediliyor..." : "Kaydet"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
