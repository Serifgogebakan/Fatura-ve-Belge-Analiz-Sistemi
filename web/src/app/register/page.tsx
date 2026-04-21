"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { register } from "../../lib/api";

export default function RegisterPage() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccessMsg(null);

    const { data, error: apiError } = await register(fullName, email, password);

    if (apiError) {
      setError(apiError);
    } else if (data) {
      // Token'ları kaydet
      localStorage.setItem('access_token', data.accessToken);
      localStorage.setItem('refresh_token', data.refreshToken);
      localStorage.setItem('user', JSON.stringify(data.user));
      
      setSuccessMsg('Hesabınız oluşturuldu! Yönlendiriliyorsunuz...');
      setTimeout(() => {
        router.push('/dashboard');
      }, 1500);
    }

    setLoading(false);
  };

  return (
    <div className="min-h-screen flex flex-col lg:flex-row bg-[#F8FAFC] dark:bg-[#0B1121] text-gray-900 dark:text-gray-100 font-sans transition-colors duration-300">
      
      {/* Sol Kısım - Marka & Bilgi */}
      <div className="lg:w-1/2 flex flex-col justify-center p-8 lg:p-20 relative overflow-hidden hidden lg:flex">
        <div className="absolute top-0 left-0 w-full h-full opacity-30 dark:opacity-10 pointer-events-none">
           <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] rounded-full bg-blue-500 blur-[120px]"></div>
           <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] rounded-full bg-indigo-600 blur-[150px]"></div>
        </div>

        <div className="relative z-10 max-w-lg mx-auto w-full">
          <div className="flex items-center gap-2 mb-12">
            <span className="text-blue-600 dark:text-blue-500 font-bold text-xl tracking-tight">Akıllı Mimari</span>
          </div>

          <h1 className="text-5xl font-extrabold tracking-tight mb-6 leading-[1.1]">
            Güvenlik & <br />
            <span className="text-blue-600 dark:text-blue-400">Mutlak Güven.</span>
          </h1>
          <p className="text-lg text-gray-500 dark:text-gray-400 mb-12 leading-relaxed max-w-md">
            Verileriniz çok katmanlı şifreleme ve kesintisiz izleme ile korunur. Derin analiz, üst düzey koruma ile buluşuyor.
          </p>

          <div className="space-y-4">
            <div className="bg-white dark:bg-[#151C2C] border border-gray-100 dark:border-gray-800 p-6 rounded-2xl shadow-sm transition-transform hover:-translate-y-1">
              <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center mb-4 text-blue-600 dark:text-blue-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              </div>
              <h3 className="font-semibold text-lg mb-1">Banka Düzeyinde</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Verileriniz için AES-256 bit şifreleme sınıfı güvenlik.</p>
            </div>

            <div className="bg-white dark:bg-[#151C2C] border border-gray-100 dark:border-gray-800 p-6 rounded-2xl shadow-sm transition-transform hover:-translate-y-1">
              <div className="w-10 h-10 rounded-full bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center mb-4 text-indigo-600 dark:text-indigo-400">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
              </div>
              <h3 className="font-semibold text-lg mb-1">7/24 Gözlem</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">Yapay zeka altyapısıyla anlık anormallik tespiti.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Sağ Kısım - Form */}
      <div className="lg:w-1/2 flex items-center justify-center p-8 bg-white dark:bg-[#0B1121] border-l border-gray-100 dark:border-gray-800 relative z-20">
        
        <div className="absolute top-8 left-8 flex items-center lg:hidden">
            <span className="text-blue-600 dark:text-blue-500 font-bold text-xl tracking-tight">Akıllı Mimari</span>
        </div>

        <div className="w-full max-w-md mt-16 lg:mt-0">
          <div className="mb-10 text-center lg:text-left">
            <h2 className="text-3xl font-bold mb-2">Hesap Oluştur</h2>
            <p className="text-gray-500 dark:text-gray-400 text-sm">2,500+ kurumsal iş ortağına katılın.</p>
          </div>

          <div className="flex gap-4 mb-8">
            <button type="button" className="flex-1 flex items-center justify-center gap-2 bg-gray-50 hover:bg-gray-100 dark:bg-[#151C2C] dark:hover:bg-[#1E273C] text-gray-700 dark:text-gray-200 py-3 px-4 rounded-xl font-medium transition-colors border border-gray-200 dark:border-gray-800">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
              Google
            </button>
            <button type="button" className="flex-1 flex items-center justify-center gap-2 bg-gray-50 hover:bg-gray-100 dark:bg-[#151C2C] dark:hover:bg-[#1E273C] text-gray-700 dark:text-gray-200 py-3 px-4 rounded-xl font-medium transition-colors border border-gray-200 dark:border-gray-800">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.166 6.839 9.489.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.603-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.462-1.11-1.462-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.268 2.75 1.022A9.606 9.606 0 0112 6.82c.85.004 1.705.115 2.504.337 1.909-1.29 2.747-1.022 2.747-1.022.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.161 22 16.416 22 12c0-5.523-4.477-10-10-10z"/></svg>
              Github
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

          {successMsg && (
            <div className="mb-4 text-sm text-green-600 bg-green-100 dark:text-green-400 dark:bg-green-900/30 p-3 rounded-xl border border-green-200 dark:border-green-800">
              {successMsg}
            </div>
          )}

          {/* Form */}
          <form className="space-y-5" onSubmit={handleRegister}>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-1.5 opacity-80">Ad Soyad</label>
              <input 
                type="text" 
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Örn: Ahmet Yılmaz" 
                required
                className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl px-4 py-3 outline-none text-gray-900 dark:text-white transition-all"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-1.5 opacity-80">E-Posta Adresi</label>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="a.yilmaz@sirket.com" 
                required
                className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl px-4 py-3 outline-none text-gray-900 dark:text-white transition-all"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-1.5 opacity-80">Şifre</label>
              <div className="relative">
                <input 
                  type={showPassword ? "text" : "password"} 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••" 
                  required
                  className="w-full bg-transparent dark:bg-[#151C2C] border border-gray-300 dark:border-gray-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 dark:focus:ring-blue-500 rounded-xl px-4 py-3 outline-none text-gray-900 dark:text-white transition-all pr-12"
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
              <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-2">En az 6 karakter (harf ve rakam karışık) tavsiye edilir.</p>
            </div>

            <div className="flex items-start gap-3 mt-6">
              <input type="checkbox" id="terms" required className="mt-1 rounded bg-gray-100 border-transparent focus:ring-blue-500 dark:bg-[#151C2C] dark:border-gray-800 text-blue-600 cursor-pointer" />
              <label htmlFor="terms" className="text-sm text-gray-600 dark:text-gray-400 leading-tight">
                Verilerimin işlenmesiyle ilgili <span className="text-blue-600 dark:text-blue-400 font-medium hover:underline cursor-pointer">Kullanım Şartları</span>'nı ve <span className="text-blue-600 dark:text-blue-400 font-medium hover:underline cursor-pointer">Gizlilik Politikası</span>'nı kabul ediyorum.
              </label>
            </div>

            <button 
              type="submit" 
              disabled={loading}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3.5 rounded-xl transition-colors shadow-lg shadow-blue-500/30 flex justify-center items-center gap-2 mt-6 disabled:opacity-50"
            >
              {loading ? "Hesap Oluşturuluyor..." : "Hesap Oluştur"}
              {!loading && <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 5l7 7m0 0l-7 7m7-7H3" /></svg>}
            </button>
          </form>

          <p className="text-center text-sm text-gray-500 dark:text-gray-400 mt-8">
            Zaten kurumsal hesabınız var mı? <Link href="/login" className="text-blue-600 dark:text-blue-400 font-semibold hover:underline">Giriş Yapın</Link>
          </p>
          
          <div className="mt-12 text-center flex items-center justify-center gap-2 text-xs text-gray-400 dark:text-gray-500">
            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" /></svg>
            256-BIT ŞİFRELEME İLE KORUNMAKTADIR
          </div>
        </div>
      </div>
    </div>
  );
}
