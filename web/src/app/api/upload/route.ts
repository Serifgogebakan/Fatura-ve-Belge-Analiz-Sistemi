import { v2 as cloudinary } from "cloudinary";
import { NextResponse } from "next/server";

cloudinary.config({
  cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Bu route SADECE Cloudinary'ye yükler, Supabase kaydını client yapar
export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File;

    if (!file) {
      return NextResponse.json({ error: "Dosya bulunamadı" }, { status: 400 });
    }

    // Cloudinary'ye yükle
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

    // Sadece Cloudinary bilgilerini döndür
    return NextResponse.json({
      success: true,
      cloudinary: {
        public_id: uploadResult.public_id,
        url: uploadResult.url,
        secure_url: uploadResult.secure_url,
      },
      file: {
        name: file.name,
        type: file.type,
      },
    });
  } catch (err: any) {
    console.error("[Upload Error]", err);
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
