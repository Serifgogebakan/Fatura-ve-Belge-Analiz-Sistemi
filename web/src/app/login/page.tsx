"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "../../lib/supabase";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        setError(error.message);
      } else if (data.session) {
        // Başarılı giriş
        router.push("/");
      }
    } catch (err: any) {
      setError("Bir hata oluştu. Lütfen tekrar deneyin.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col lg:flex-row bg-[#F8FAFC] dark:bg-[#0B1121] text-gray-900 dark:text-gray-100 font-sans transition-colors duration-300">

      {/* Sol Kısım - Görsel / Marka */}
      <div className="lg:w-1/2 flex flex-col justify-between p-8 lg:p-16 relative overflow-hidden hidden lg:flex bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-[#0f172a] dark:to-[#0B1121]">

        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-12">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center text-white">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
            </div>
            <span className="text-gray-900 dark:text-white font-bold text-xl tracking-tight">Fatura Analiz</span>
            <span className="text-xs uppercase tracking-widest text-gray-500 ml-2 mt-1 hidden xl:inline-block">Akıllı Belge Yönetimi</span>
          </div>
        </div>

        {/* Soyut Veri Görseli Mokup */}
        <div className="relative flex-1 flex items-center justify-center my-8 z-10 w-full max-w-md mx-auto">
          <div className="w-full aspect-[4/5] bg-black rounded-3xl overflow-hidden shadow-2xl relative border border-gray-800">
            <div className="absolute inset-0 bg-gradient-to-t from-black to-transparent z-10"></div>
            <div className="grid grid-cols-6 gap-2 p-6 opacity-40">
              {Array.from({ length: 60 }).map((_, i) => (
                <div key={i} className={`text-[10px] font-mono ${i % 7 === 0 ? 'text-blue-500' : i % 5 === 0 ? 'text-red-500' : i % 3 === 0 ? 'text-green-500' : 'text-gray-600'}`}>
                  {Math.floor(Math.random() * 900) + 100}
                </div>
              ))}
            </div>
            <div className="absolute bottom-8 left-8 z-20">
              <div className="text-white font-mono text-xl tracking-widest">ANALİZ %99.8</div>
            </div>
          </div>

          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] bg-blue-600/20 blur-[100px] -z-10 rounded-full pointer-events-none"></div>
        </div>

        <div className="relative z-10 mt-8 max-w-md mx-auto">
          <svg className="w-8 h-8 text-blue-500 mb-4" fill="currentColor" viewBox="0 0 24 24"><path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z" /></svg>
          <p className="text-lg text-gray-800 dark:text-gray-200 font-medium leading-relaxed italic mb-6">
            "Sistem, karmaşık belgelerimizi ve faturalarımızı milisaniyeler içinde sınıflandırarak iş yükümüzü %80 oranında azalttı."
          </p>
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-gray-300 dark:bg-gray-700 flex-shrink-0">
            </div>
            <div>
              <div className="font-bold text-gray-900 dark:text-white">Ahmet Yılmaz</div>
              <div className="text-sm text-gray-500 dark:text-gray-400">Finans Müdürü, ABC A.Ş.</div>
            </div>
          </div>
        </div>
      </div>

      {/* Sağ Kısım - Form */}
      <div className="lg:w-1/2 flex items-center justify-center p-8 bg-white dark:bg-[#0B1121] relative z-20">

        <div className="absolute top-8 left-8 flex items-center lg:hidden">
          <span className="text-blue-600 dark:text-blue-500 font-bold text-xl tracking-tight">Fatura Analiz</span>
        </div>

        <div className="absolute top-8 right-8 hidden lg:block text-sm">
          <span className="text-gray-500 dark:text-gray-400">Hesabınız yok mu? </span>
          <Link href="/register" className="text-blue-600 dark:text-blue-400 hover:text-blue-700 font-medium">Kayıt Ol</Link>
        </div>

        <div className="w-full max-w-sm mt-16 lg:mt-0">
          <div className="mb-10 text-center lg:text-left">
            <h2 className="text-3xl font-bold mb-2">Tekrar Hoş Geldiniz</h2>
            <p className="text-gray-500 dark:text-gray-400 text-sm">Finansal gösterge panelinize güvenle giriş yapın.</p>
          </div>

          {/* Sosyal Girişler (İleride bağlanabilir, şimdilik UI olarak kalıyor) */}
          <div className="flex gap-4 mb-8">
            <button type="button" className="flex-1 flex items-center justify-center gap-2 bg-gray-50 hover:bg-gray-100 dark:bg-[#151C2C] dark:hover:bg-[#1E273C] text-gray-700 dark:text-gray-200 py-3 px-4 rounded-xl font-medium transition-colors border border-gray-200 dark:border-gray-800">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" /><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" /><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" /><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" /></svg>
              Google
            </button>
            <button type="button" className="flex-1 flex items-center justify-center gap-2 bg-gray-50 hover:bg-gray-100 dark:bg-[#151C2C] dark:hover:bg-[#1E273C] text-gray-700 dark:text-gray-200 py-3 px-4 rounded-xl font-medium transition-colors border border-gray-200 dark:border-gray-800">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.166 6.839 9.489.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.603-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.462-1.11-1.462-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.268 2.75 1.022A9.606 9.606 0 0112 6.82c.85.004 1.705.115 2.504.337 1.909-1.29 2.747-1.022 2.747-1.022.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.161 22 16.416 22 12c0-5.523-4.477-10-10-10z" /></svg>
              Apple
            </button>
          </div>

          <div className="flex items-center mb-8">
            <div className="flex-1 border-t border-gray-200 dark:border-gray-800"></div>
            <span className="px-4 text-xs text-gray-400 dark:text-gray-500 font-medium uppercase tracking-wider">veya e-posta ile</span>
            <div className="flex-1 border-t border-gray-200 dark:border-gray-800"></div>
          </div>

          {error && (
            <div className="mb-4 text-sm text-red-500 bg-red-100 dark:bg-red-900/30 p-3 rounded-xl border border-red-200 dark:border-red-800">
              {error}
            </div>
          )}

          {/* Form */}
          <form className="space-y-6" onSubmit={handleLogin}>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-1.5 opacity-80">E-Posta Adresi</label>
              <div className="relative">
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="isim@sirket.com"
                  required
                  className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl pl-12 pr-4 py-3.5 outline-none text-gray-900 dark:text-white transition-all"
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide opacity-80">Şifre</label>
                <Link href="#" className="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 font-medium">Şifremi Unuttum?</Link>
              </div>
              <div className="relative">
                <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" /></svg>
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  required
                  className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl pl-12 pr-4 py-3.5 outline-none text-gray-900 dark:text-white transition-all"
                />
              </div>
            </div>

            <div className="flex items-center gap-3">
              <input type="checkbox" id="remember" className="mt-0.5 rounded bg-gray-100 border-transparent focus:ring-blue-500 dark:bg-[#151C2C] dark:border-gray-800 text-blue-600 cursor-pointer" />
              <label htmlFor="remember" className="text-sm text-gray-600 dark:text-gray-400 cursor-pointer select-none">
                Beni hatırla
              </label>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3.5 rounded-xl transition-colors shadow-lg shadow-blue-500/30 disabled:opacity-50"
            >
              {loading ? "Giriş yapılıyor..." : "Giriş Yap"}
            </button>
          </form>

          <p className="mt-12 text-center text-xs text-gray-500 dark:text-gray-500">
            © 2026 Fatura Analiz Sistemi. Tüm hakları saklıdır.<br />
            <Link href="#" className="hover:text-blue-500">Gizlilik Politikası</Link> • <Link href="#" className="hover:text-blue-500">Kullanım Şartları</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
