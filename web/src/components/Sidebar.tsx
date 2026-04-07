"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { 
  Building2, 
  LayoutDashboard, 
  LineChart, 
  FolderDown, 
  LockKeyhole, 
  Users, 
  LogOut,
  Settings
} from "lucide-react";

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const [userProfile, setUserProfile] = useState<{name: string, role: string, initials: string}>({name: "Kullanıcı", role: "Üye", initials: "K"});

  useEffect(() => {
    async function loadUser() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        let name = user.user_metadata?.full_name || "Yeni Kullanıcı";
        let role = "Üye";

        const { data: prof } = await supabase.from("profiles").select("full_name, role").eq("id", user.id).single();
        if (prof?.full_name) name = prof.full_name;
        if (prof?.role) role = prof.role === "user" ? "Kullanıcı" : prof.role;
        
        setUserProfile({
          name,
          role,
          initials: name.substring(0, 1).toUpperCase()
        });
      }
    }
    loadUser();
  }, []);

  const navItems = [
    { href: "/dashboard", label: "Genel Bakış", icon: LayoutDashboard },
    { href: "/dashboard/analytics", label: "Analitik", icon: LineChart },
    { href: "/dashboard/documents", label: "Belgeler Arşivi", icon: FolderDown },
    { href: "/dashboard/vault", label: "Kasa (Vault)", icon: LockKeyhole },
    { href: "/dashboard/team", label: "Ekip", icon: Users },
  ];

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push("/login");
  };

  return (
    <>
      <aside className="w-68 bg-sidebar border-r border-border flex flex-col transition-colors duration-200 shrink-0">
        <div className="h-[76px] flex items-center px-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-accent flex items-center justify-center text-accent-fg shadow-sm">
              <Building2 size={20} />
            </div>
            <div>
              <h1 className="font-extrabold text-[15px] tracking-tight leading-tight text-foreground">BillMind App</h1>
              <p className="text-[10px] text-muted font-bold uppercase tracking-wider mt-0.5">Premium Tier</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 px-4 py-8 space-y-1 overflow-y-auto">
          <p className="px-3 text-xs font-bold text-muted mb-4 tracking-widest uppercase">Pano & Analiz</p>
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link 
                key={item.href}
                href={item.href} 
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all font-semibold text-sm ${
                  isActive 
                    ? "bg-accent/10 text-accent" 
                    : "text-muted hover:text-foreground hover:bg-muted-bg"
                }`}
              >
                <item.icon size={18} />
                <span>{item.label}</span>
              </Link>
            );
          })}

          <p className="px-3 text-xs font-bold text-muted mt-8 mb-4 tracking-widest uppercase">Sistem</p>
          <Link 
            href="/dashboard/settings" 
            className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all font-semibold text-sm ${
              pathname === "/dashboard/settings" ? "bg-accent/10 text-accent" : "text-muted hover:text-foreground hover:bg-muted-bg"
            }`}
          >
            <Settings size={18} />
            <span>Ayarlar</span>
          </Link>
        </nav>

        <div className="p-4 border-t border-border">
          {/* User Profile Mini */}
          <div className="flex items-center gap-3 p-3 mb-4 rounded-xl border border-border bg-muted-bg/50">
            <div className="w-9 h-9 rounded-full bg-accent/20 flex items-center justify-center text-accent shrink-0">
              <span className="font-bold text-sm">{userProfile.initials}</span>
            </div>
            <div className="overflow-hidden">
              <p className="font-bold text-sm text-foreground truncate">{userProfile.name}</p>
              <p className="text-xs text-muted truncate">{userProfile.role}</p>
            </div>
          </div>

          <div className="space-y-1">
            <button 
              onClick={() => setShowLogoutModal(true)}
              className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-muted hover:text-red-600 hover:bg-red-500/10 transition-all font-semibold text-sm"
            >
              <LogOut size={18} />
              <span>Güvenli Çıkış</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Modern Logout Modal */}
      {showLogoutModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-card border border-border p-6 rounded-2xl shadow-2xl max-w-sm w-full mx-4 animate-in fade-in zoom-in duration-200">
            <div className="w-12 h-12 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center mb-4 mx-auto">
              <LogOut size={24} />
            </div>
            <h3 className="text-xl font-bold text-center text-foreground mb-2">Çıkış Yap</h3>
            <p className="text-center text-muted mb-6 font-medium">Hesabınızdan çıkış yapmak istediğinize emin misiniz?</p>
            <div className="flex gap-3">
              <button 
                onClick={() => setShowLogoutModal(false)}
                className="flex-1 py-2.5 rounded-xl font-bold bg-muted-bg hover:bg-border text-foreground transition-colors"
              >
                İptal
              </button>
              <button 
                onClick={handleLogout}
                className="flex-1 py-2.5 rounded-xl font-bold bg-red-600 hover:bg-red-700 text-white transition-colors shadow-lg shadow-red-600/20"
              >
                Evet, Çıkış Yap
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
