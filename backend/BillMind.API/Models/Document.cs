namespace BillMind.API.Models;

public class Document
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public string FileType { get; set; } = string.Empty;   // pdf, jpeg, png
    public long FileSizeBytes { get; set; }
    public string Status { get; set; } = "BEKLEMEDE";      // BEKLEMEDE, İŞLENİYOR, ONAYLANDI, HATA
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public InvoiceData? ParsedData { get; set; }
}

public class InvoiceData
{
    public string? CompanyName { get; set; }       // Turkcell A.Ş.
    public string? InvoiceNumber { get; set; }     // Fatura numarası
    public DateTime? InvoiceDate { get; set; }     // Fatura tarihi
    public decimal? TotalAmount { get; set; }      // Toplam tutar
    public string? Currency { get; set; } = "TRY"; // Para birimi
    public string? Category { get; set; }          // Fatura, Fiş, Sipariş...
    public string? RawOcrText { get; set; }        // Ham OCR metni
}

public class DocumentUploadResponse
{
    public Guid DocumentId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public InvoiceData? ParsedData { get; set; }
}
