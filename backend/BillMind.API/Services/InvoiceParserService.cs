using System.Text.RegularExpressions;
using BillMind.API.Models;

namespace BillMind.API.Services;

/// <summary>
/// OCR ile çıkarılan ham metinden fatura verilerini (tutar, tarih, firma) parse eder.
/// </summary>
public class InvoiceParserService
{
    private readonly ILogger<InvoiceParserService> _logger;

    public InvoiceParserService(ILogger<InvoiceParserService> logger)
    {
        _logger = logger;
    }

    public InvoiceData Parse(string rawText)
    {
        _logger.LogInformation("Fatura metni parse ediliyor. Metin uzunluğu: {Length}", rawText.Length);

        var data = new InvoiceData
        {
            RawOcrText = rawText,
            CompanyName = ExtractCompanyName(rawText),
            InvoiceDate = ExtractDate(rawText),
            TotalAmount = ExtractAmount(rawText),
            InvoiceNumber = ExtractInvoiceNumber(rawText),
            Category = DetermineCategory(rawText),
            Currency = DetectCurrency(rawText),
        };

        _logger.LogInformation("Parse tamamlandı. Firma: {Company}, Tutar: {Amount}", data.CompanyName, data.TotalAmount);
        return data;
    }

    // Tutar çıkarma — "TOPLAM", "GENEL TOPLAM", "KDV DAHİL" ibarelerinden sonraki sayıyı alır
    private decimal? ExtractAmount(string text)
    {
        var patterns = new[]
        {
            @"(?:TOPLAM|GENEL TOPLAM|KDV DAHİL|ÖDENECEK TUTAR|TOTAL)[^\d]*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))",
            @"(\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:TL|TRY|₺)",
            @"₺\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)",
        };

        foreach (var pattern in patterns)
        {
            var match = Regex.Match(text, pattern, RegexOptions.IgnoreCase);
            if (match.Success)
            {
                var raw = match.Groups[1].Value.Replace(".", "").Replace(",", ".");
                if (decimal.TryParse(raw, System.Globalization.NumberStyles.Any,
                    System.Globalization.CultureInfo.InvariantCulture, out var amount))
                    return amount;
            }
        }
        return null;
    }

    // Tarih çıkarma — GG.AA.YYYY, YYYY-AA-GG, GG/AA/YYYY formatları
    private DateTime? ExtractDate(string text)
    {
        var patterns = new[]
        {
            @"\b(\d{2})[./](\d{2})[./](\d{4})\b",
            @"\b(\d{4})-(\d{2})-(\d{2})\b",
        };

        foreach (var pattern in patterns)
        {
            var match = Regex.Match(text, pattern);
            if (match.Success)
            {
                if (pattern.StartsWith(@"\b(\d{4})"))
                {
                    if (DateTime.TryParse(match.Value, out var d)) return d;
                }
                else
                {
                    var day = int.Parse(match.Groups[1].Value);
                    var month = int.Parse(match.Groups[2].Value);
                    var year = int.Parse(match.Groups[3].Value);
                    if (day is >= 1 and <= 31 && month is >= 1 and <= 12 && year > 2000)
                        return new DateTime(year, month, day);
                }
            }
        }
        return null;
    }

    // Fatura numarası çıkarma
    private string? ExtractInvoiceNumber(string text)
    {
        var match = Regex.Match(text, @"(?:FATURA NO|INV NO|INVOICE|BELGE NO)[:\s#]*([A-Z0-9\-\/]+)", RegexOptions.IgnoreCase);
        return match.Success ? match.Groups[1].Value.Trim() : null;
    }

    // İlk büyük harfli satırı firma adı ola kabul eder (basit heuristic)
    private string? ExtractCompanyName(string text)
    {
        var lines = text.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        foreach (var line in lines.Take(10))
        {
            var trimmed = line.Trim();
            if (trimmed.Length > 3 && trimmed.Length < 80 && char.IsUpper(trimmed[0]))
                return trimmed;
        }
        return null;
    }

    // Anahtar kelimelere göre kategori belirleme
    private string DetermineCategory(string text)
    {
        var lower = text.ToLower();
        if (lower.Contains("fatura") || lower.Contains("invoice")) return "Fatura";
        if (lower.Contains("fiş") || lower.Contains("receipt")) return "Fiş";
        if (lower.Contains("sipariş") || lower.Contains("order")) return "Sipariş";
        if (lower.Contains("irsaliye")) return "İrsaliye";
        return "Diğer";
    }

    // Para birimi tespiti
    private string DetectCurrency(string text)
    {
        if (text.Contains("USD") || text.Contains("$")) return "USD";
        if (text.Contains("EUR") || text.Contains("€")) return "EUR";
        return "TRY";
    }
}
