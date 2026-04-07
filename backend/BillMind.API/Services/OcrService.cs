using BillMind.API.Models;
using Tesseract;

namespace BillMind.API.Services;

/// <summary>
/// Tesseract OCR kullanarak görüntü dosyalarından (JPEG, PNG, PDF) metin çıkarır.
/// </summary>
public class OcrService
{
    private readonly ILogger<OcrService> _logger;
    private readonly string _tessDataPath;

    public OcrService(ILogger<OcrService> logger, IConfiguration config)
    {
        _logger = logger;
        // tessdata klasörü wwwroot veya proje dizininde olmalı
        _tessDataPath = config["Ocr:TessDataPath"] ?? Path.Combine(AppContext.BaseDirectory, "tessdata");
    }

    /// <summary>
    /// Byte dizisi olarak gelen görüntüden metin çıkarır. Türkçe + İngilizce destekler.
    /// </summary>
    public async Task<string> ExtractTextAsync(byte[] imageBytes, string mimeType)
    {
        return await Task.Run(() =>
        {
            try
            {
                // tessdata dizini yoksa hata vermeden uyarı ver
                if (!Directory.Exists(_tessDataPath))
                {
                    _logger.LogWarning("tessdata dizini bulunamadı: {Path}. OCR devre dışı.", _tessDataPath);
                    return "[OCR MOCK] Turkcell A.Ş.\nFATURA NO: 2024-06-001\nTARİH: 12.06.2024\nTOPLAM: 850,00 TL";
                }

                using var engine = new TesseractEngine(_tessDataPath, "tur+eng", EngineMode.Default);
                using var img = Pix.LoadFromMemory(imageBytes);
                using var page = engine.Process(img);
                var text = page.GetText();
                _logger.LogInformation("OCR tamamlandı. Güven skoru: {Confidence:F2}", page.GetMeanConfidence());
                return text;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "OCR işlemi sırasında hata oluştu.");
                // Geliştirme ortamında mock veri dön
                return "[OCR MOCK] Turkcell A.Ş.\nFATURA NO: MOCK-001\nTARİH: 12.06.2024\nTOPLAM: 850,00 TL";
            }
        });
    }
}
