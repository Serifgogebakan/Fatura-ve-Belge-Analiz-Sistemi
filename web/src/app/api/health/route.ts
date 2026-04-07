import { supabase } from "@/lib/supabase";
import { NextResponse } from "next/server";

export async function GET() {
  const results: Record<string, any> = {};

  try {
    // 1. profiles tablosu kontrol
    const { data: profiles, error: profErr } = await supabase
      .from("profiles")
      .select("id")
      .limit(1);
    results.profiles = profErr ? `❌ HATA: ${profErr.message}` : `✅ Tablo mevcut (${profiles?.length ?? 0} kayıt)`;

    // 2. documents tablosu kontrol
    const { data: docs, error: docErr } = await supabase
      .from("documents")
      .select("id")
      .limit(1);
    results.documents = docErr ? `❌ HATA: ${docErr.message}` : `✅ Tablo mevcut (${docs?.length ?? 0} kayıt)`;

    // 3. extracted_data tablosu kontrol
    const { data: extracted, error: extErr } = await supabase
      .from("extracted_data")
      .select("id")
      .limit(1);
    results.extracted_data = extErr ? `❌ HATA: ${extErr.message}` : `✅ Tablo mevcut (${extracted?.length ?? 0} kayıt)`;

    // 4. support_tickets tablosu kontrol
    const { data: tickets, error: tickErr } = await supabase
      .from("support_tickets")
      .select("id")
      .limit(1);
    results.support_tickets = tickErr ? `❌ HATA: ${tickErr.message}` : `✅ Tablo mevcut (${tickets?.length ?? 0} kayıt)`;

    // 5. Cloudinary env değişkenleri kontrol
    const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    results.cloudinary = {
      cloud_name: cloudName ? `✅ Ayarlı (${cloudName})` : "❌ EKSİK",
      api_key: apiKey ? `✅ Ayarlı (${apiKey.slice(0, 6)}...)` : "❌ EKSİK",
      api_secret: apiSecret ? "✅ Ayarlı (***gizli***)" : "❌ EKSİK",
    };

    return NextResponse.json({ status: "Kontrol tamamlandı", results });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
