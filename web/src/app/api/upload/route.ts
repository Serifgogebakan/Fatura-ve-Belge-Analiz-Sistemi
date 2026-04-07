import { v2 as cloudinary } from "cloudinary";
import { supabase } from "@/lib/supabase";
import { NextResponse } from "next/server";

cloudinary.config({
  cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File;

    if (!file) {
      return NextResponse.json({ error: "Dosya bulunamadı" }, { status: 400 });
    }

    // 1. Cloudinary'ye yükle
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    const uploadResult = await new Promise<any>((resolve, reject) => {
      cloudinary.uploader
        .upload_stream(
          {
            folder: "billmind/documents",
            resource_type: "auto",
          },
          (err, result) => {
            if (err) reject(err);
            else resolve(result);
          }
        )
        .end(buffer);
    });

    // 2. Oturumdaki kullanıcıyı al
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Oturum bulunamadı" }, { status: 401 });
    }

    const fileType = file.type.includes("pdf")
      ? "pdf"
      : file.type.includes("image")
      ? "image"
      : "other";

    // 3. Supabase'e metadata kaydet
    const { data, error } = await supabase
      .from("documents")
      .insert({
        user_id: user.id,
        name: file.name.replace(/\.[^/.]+$/, ""),
        original_filename: file.name,
        file_type: fileType,
        cloudinary_public_id: uploadResult.public_id,
        cloudinary_url: uploadResult.url,
        cloudinary_secure_url: uploadResult.secure_url,
        status: "beklemede",
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true, document: data });
  } catch (err: any) {
    console.error("[Upload Error]", err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
