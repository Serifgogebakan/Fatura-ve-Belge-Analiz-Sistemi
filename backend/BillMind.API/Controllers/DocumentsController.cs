using BillMind.API.Models;
using BillMind.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace BillMind.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DocumentsController : ControllerBase
{
    private readonly OcrService _ocr;
    private readonly InvoiceParserService _parser;
    private readonly SupabaseService _supabase;
    private readonly ILogger<DocumentsController> _logger;

    // İzin verilen dosya türleri
    private static readonly string[] AllowedTypes = ["image/jpeg", "image/png", "application/pdf"];
    private const long MaxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

    public DocumentsController(OcrService ocr, InvoiceParserService parser, SupabaseService supabase, ILogger<DocumentsController> logger)
    {
        _ocr = ocr;
        _parser = parser;
        _supabase = supabase;
        _logger = logger;
    }

    /// <summary>
    /// Fatura veya belge yükler, OCR ile analiz eder ve Supabase'e kaydeder.
    /// POST /api/documents/upload
    /// </summary>
    public class DocumentMetadataDto
    {
        public string UserId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string FileType { get; set; } = string.Empty;
        public string CloudinaryUrl { get; set; } = string.Empty;
        public string CloudinarySecureUrl { get; set; } = string.Empty;
        public string CloudinaryPublicId { get; set; } = string.Empty;
    }

    /// <summary>
    /// Frontend Cloudinary yüklemesi sonrası metadata kaydetmek için kullanılır.
    /// POST /api/documents/metadata
    /// </summary>
    [HttpPost("metadata")]
    public async Task<ActionResult<object>> SaveMetadata([FromBody] DocumentMetadataDto dto)
    {
        var docId = Guid.NewGuid();
        var doc = new Document
        {
            Id = docId,
            UserId = dto.UserId,
            FileName = dto.FileName,
            FileUrl = dto.CloudinarySecureUrl,
            FileType = dto.FileType,
            FileSizeBytes = 0,
            Status = "beklemede",
            UploadedAt = DateTime.UtcNow,
            ParsedData = new InvoiceData 
            {
                Category = dto.FileType == "image" ? "MAKBUZ" : "FATURA",
                TotalAmount = 0
            }
        };

        var saved = await _supabase.SaveDocumentAsync(doc);
        if (!saved) return BadRequest(new { message = "Veritabanına kaydedilemedi." });

        return Ok(new { success = true, documentId = docId });
    }

    [HttpPost("upload")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<ActionResult<DocumentUploadResponse>> Upload([FromForm] IFormFile file, [FromForm] string? userId)
    {
        _logger.LogInformation("Dosya yükleme isteği alındı: {FileName}", file?.FileName);

        // Validasyon
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Dosya boş olamaz." });

        if (file.Length > MaxFileSizeBytes)
            return BadRequest(new { message = "Dosya boyutu 20 MB'ı geçemez." });

        if (!AllowedTypes.Contains(file.ContentType.ToLower()))
            return BadRequest(new { message = "Sadece JPEG, PNG ve PDF dosyaları kabul edilir." });

        // Dosyayı belleğe al
        byte[] fileBytes;
        using (var ms = new MemoryStream())
        {
            await file.CopyToAsync(ms);
            fileBytes = ms.ToArray();
        }

        var docId = Guid.NewGuid();

        // OCR işlemi
        var rawText = await _ocr.ExtractTextAsync(fileBytes, file.ContentType);

        // Parse işlemi
        var parsedData = _parser.Parse(rawText);

        // Supabase'e kaydet
        var doc = new Document
        {
            Id = docId,
            UserId = userId ?? "anonymous",
            FileName = file.FileName,
            FileUrl = "", // Cloudinary URL ileride eklenecek
            FileType = file.ContentType,
            FileSizeBytes = file.Length,
            Status = "tamamlandı",
            UploadedAt = DateTime.UtcNow,
            ParsedData = parsedData
        };

        var saved = await _supabase.SaveDocumentAsync(doc);

        var response = new DocumentUploadResponse
        {
            DocumentId = docId,
            FileName = file.FileName,
            Status = saved ? "tamamlandı" : "HATA",
            Message = saved ? "Belge başarıyla analiz edildi ve veritabanına kaydedildi." : "Belge analiz edildi ancak veritabanına kaydedilemedi.",
            ParsedData = parsedData
        };

        _logger.LogInformation("Belge işlendi. ID: {Id}, Firma: {Company}, DB: {Saved}", docId, parsedData.CompanyName, saved);
        return Ok(response);
    }

    /// <summary>
    /// Kullanıcının tüm belgelerini Supabase'den getirir.
    /// GET /api/documents?userId={userId}
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<object>> GetAll([FromQuery] string? userId)
    {
        if (string.IsNullOrEmpty(userId))
        {
            return BadRequest(new { message = "userId parametresi gerekli." });
        }

        var documents = await _supabase.GetDocumentsByUserAsync(userId);

        if (documents == null)
        {
            return StatusCode(500, new { message = "Belgeler yüklenirken bir hata oluştu." });
        }

        return Ok(documents);
    }

    /// <summary>
    /// Belirli bir belgeyi Supabase'den getirir.
    /// GET /api/documents/{id}
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<object>> GetById(Guid id)
    {
        var document = await _supabase.GetDocumentByIdAsync(id.ToString());

        if (document == null)
        {
            return NotFound(new { message = "Belge bulunamadı." });
        }

        return Ok(document);
    }
}
