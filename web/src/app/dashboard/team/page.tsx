export default function TeamPage() {
  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div>
        <h1 className="text-3xl font-bold text-foreground">Ekip Yönetimi</h1>
        <p className="text-muted mt-2">İşletmenizde belge erişimine ve sisteme dahil olan ekip üyeleri.</p>
      </div>
      <div className="bg-card border border-border rounded-xl p-12 text-center flex flex-col items-center justify-center min-h-[300px]">
        <h2 className="text-xl font-semibold mb-2">Henüz Ekip Üyesi Yok</h2>
        <p className="text-muted mb-6">İş arkadaşlarınızı davet ederek harcamaları birlikte yönetebilirsiniz.</p>
        <button className="px-5 py-2 bg-accent text-accent-fg rounded-lg font-medium">Davet Gönder</button>
      </div>
    </div>
  );
}
