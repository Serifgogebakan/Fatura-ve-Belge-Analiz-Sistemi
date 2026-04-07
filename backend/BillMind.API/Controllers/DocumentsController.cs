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
    private readonly ILogger<DocumentsController> _logger;

    // İzin verilen dosya türleri
    private static readonly string[] AllowedTypes = ["image/jpeg", "image/png", "application/pdf"];
    private const long MaxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

    public DocumentsController(OcrService ocr, InvoiceParserService parser, ILogger<DocumentsController> logger)
    {
        _ocr = ocr;
        _parser = parser;
        _logger = logger;
    }

    /// <summary>
    /// Fatura veya belge yükler, OCR ile analiz eder ve sonuçları döner.
    /// POST /api/documents/upload
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<ActionResult<DocumentUploadResponse>> Upload([FromForm] IFormFile file)
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

        // TODO: Supabase Storage'a kaydet ve DB'ye yaz (ilerleyen aşamada)
        var response = new DocumentUploadResponse
        {
            DocumentId = docId,
            FileName = file.FileName,
            Status = "ONAYLANDI",
            Message = "Belge başarıyla analiz edildi.",
            ParsedData = parsedData
        };

        _logger.LogInformation("Belge işlendi. ID: {Id}, Firma: {Company}", docId, parsedData.CompanyName);
        return Ok(response);
    }

    /// <summary>
    /// Tüm belgeleri listeler (şimdilik mock data).
    /// GET /api/documents
    /// </summary>
    [HttpGet]
    public ActionResult<IEnumerable<object>> GetAll()
    {
        // TODO: Supabase'den gerçek veri çekilecek
        var mockList = new[]
        {
            new { Id = Guid.NewGuid(), FileName = "Q1_Audit_Report.pdf", Status = "ONAYLANDI", UploadedAt = DateTime.UtcNow.AddHours(-2), Category = "Denetim" },
            new { Id = Guid.NewGuid(), FileName = "Server_Maintenance_Inv_04.jpg", Status = "BEKLEMEDE", UploadedAt = DateTime.UtcNow.AddDays(-1), Category = "Faturalar" },
            new { Id = Guid.NewGuid(), FileName = "Payroll_Summary_March.xlsx", Status = "ONAYLANDI", UploadedAt = DateTime.UtcNow.AddDays(-2), Category = "Bordro" },
        };
        return Ok(mockList);
    }

    /// <summary>
    /// Belirli bir belgeyi getirir.
    /// GET /api/documents/{id}
    /// </summary>
    [HttpGet("{id:guid}")]
    public ActionResult<object> GetById(Guid id)
    {
        // TODO: Supabase'den gerçek veri
        return Ok(new { Id = id, Message = "Belge burada gelecek." });
    }
}
