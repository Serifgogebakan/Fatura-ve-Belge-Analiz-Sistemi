export default function SupportPage() {
  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div>
        <h1 className="text-3xl font-bold text-foreground">Destek ve Yardım</h1>
        <p className="text-muted mt-2">Sistemde yaşadığınız hatalar veya genel talepler için bize ulaşın.</p>
      </div>
      <div className="bg-card border border-border rounded-xl p-8 max-w-2xl">
        <h2 className="text-xl font-semibold mb-4">Yeni Talep Oluştur</h2>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Konu</label>
            <input type="text" className="w-full bg-muted-bg border border-border rounded-lg px-4 py-2" placeholder="Örn: Fatura okuma hatası..." />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Mesajınız</label>
            <textarea className="w-full bg-muted-bg border border-border rounded-lg px-4 py-2 min-h-[120px]" placeholder="Detayları buraya yazınız..."></textarea>
          </div>
          <button type="button" className="px-5 py-2 bg-accent text-accent-fg rounded-lg font-medium w-full mt-4">Talebi Gönder</button>
        </form>
      </div>
    </div>
  );
}
