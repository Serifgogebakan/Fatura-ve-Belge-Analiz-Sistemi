"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { login } from "../../lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email || !password) {
      setError("Lütfen e-posta ve şifrenizi girin.");
      return;
    }

    setLoading(true);

    const { data, error: apiError } = await login(email, password);

    if (apiError) {
      setError(apiError);
    } else if (data) {
      // Token'ları kaydet
      localStorage.setItem('access_token', data.accessToken);
      localStorage.setItem('refresh_token', data.refreshToken);
      localStorage.setItem('user', JSON.stringify(data.user));
      router.push('/dashboard');
    }

    setLoading(false);
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
            <span className="text-gray-900 dark:text-white font-bold text-xl tracking-tight">BillMind</span>
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
          <span className="text-blue-600 dark:text-blue-500 font-bold text-xl tracking-tight">BillMind</span>
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
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl pl-12 pr-12 py-3.5 outline-none text-gray-900 dark:text-white transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                  tabIndex={-1}
                >
                  {showPassword ? (
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L6.59 6.59m7.532 7.532l3.29 3.29M3 3l18 18" /></svg>
                  ) : (
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                  )}
                </button>
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
            © 2026 BillMind Sistemi. Tüm hakları saklıdır.<br />
            <Link href="#" className="hover:text-blue-500">Gizlilik Politikası</Link> • <Link href="#" className="hover:text-blue-500">Kullanım Şartları</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
