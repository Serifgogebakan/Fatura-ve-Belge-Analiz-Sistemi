import { supabase } from "@/lib/supabase";

export async function uploadDocument(file: File): Promise<{ success: boolean; error?: string; document?: any }> {
  try {
    // 1. Kullanıcıyı kontrol et (client-side, oturum var)
    const userDataStr = localStorage.getItem('user');
    if (!userDataStr) {
      return { success: false, error: "Oturum bulunamadı. Lütfen tekrar giriş yapın." };
    }
    const user = JSON.parse(userDataStr);

    // 2. Cloudinary'ye yükle (API route üzerinden)
    const formData = new FormData();
    formData.append("file", file);

    const res = await fetch("/api/upload", { method: "POST", body: formData });
    const json = await res.json();

    if (!json.success) {
      return { success: false, error: json.error || "Cloudinary yükleme hatası" };
    }

    // 3. Supabase'e metadata kaydet (.NET backend üzerinden)
    const fileType = file.type.includes("pdf") ? "pdf" : file.type.includes("image") ? "image" : "other";

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5057';
    const metadataRes = await fetch(`${API_URL}/api/documents/metadata`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        userId: user.id,
        fileName: file.name.replace(/\.[^/.]+$/, ""),
        fileType: fileType,
        cloudinaryUrl: json.cloudinary.url,
        cloudinarySecureUrl: json.cloudinary.secure_url,
        cloudinaryPublicId: json.cloudinary.public_id
      })
    });

    if (!metadataRes.ok) {
      return { success: false, error: "Veritabanına kaydedilemedi." };
    }

    const metadataJson = await metadataRes.json();

    return { success: true, document: { id: metadataJson.documentId } };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
}
