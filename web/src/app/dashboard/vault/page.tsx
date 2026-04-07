export default function VaultPage() {
  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div>
        <h1 className="text-3xl font-bold text-foreground">Güvenlik Kasası</h1>
        <p className="text-muted mt-2">Şifrelenmiş özel veriler ve yetki gerektiren hassas dokümanlar.</p>
      </div>
      <div className="bg-card border border-border rounded-xl p-12 text-center flex flex-col items-center justify-center min-h-[300px]">
        <h2 className="text-xl font-semibold mb-2">Kasa Kilitli</h2>
        <p className="text-muted mb-6">Buraya sadece 2 Aşamalı Doğrulama (2FA) ile erişilebilir.</p>
        <button className="px-5 py-2 bg-accent text-accent-fg rounded-lg font-medium">Kimliği Doğrula</button>
      </div>
    </div>
  );
}
