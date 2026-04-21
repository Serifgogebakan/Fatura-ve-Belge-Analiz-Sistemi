using BillMind.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace BillMind.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReportsController : ControllerBase
{
    private readonly SupabaseService _supabase;
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(SupabaseService supabase, ILogger<ReportsController> logger)
    {
        _supabase = supabase;
        _logger = logger;
    }

    /// <summary>
    /// Dashboard için aylık harcama özeti.
    /// GET /api/reports/monthly-summary?userId={userId}&year={year}
    /// </summary>
    [HttpGet("monthly-summary")]
    public async Task<ActionResult<object>> GetMonthlySummary([FromQuery] string? userId, [FromQuery] int year = 0)
    {
        if (string.IsNullOrEmpty(userId))
            return BadRequest(new { message = "userId parametresi gerekli." });

        if (year == 0) year = DateTime.UtcNow.Year;

        var summary = await _supabase.GetMonthlySummaryAsync(userId, year);

        if (summary == null)
        {
            return StatusCode(500, new { message = "Rapor oluşturulurken bir hata oluştu." });
        }

        return Ok(summary);
    }

    /// <summary>
    /// Kategori bazında harcama dağılımı — Supabase'den hesaplanır.
    /// GET /api/reports/category-breakdown?userId={userId}
    /// </summary>
    [HttpGet("category-breakdown")]
    public async Task<ActionResult<object>> GetCategoryBreakdown([FromQuery] string? userId)
    {
        if (string.IsNullOrEmpty(userId))
            return BadRequest(new { message = "userId parametresi gerekli." });

        var documents = await _supabase.GetDocumentsByUserAsync(userId);

        if (documents == null)
        {
            return StatusCode(500, new { message = "Veriler yüklenirken bir hata oluştu." });
        }

        var breakdown = documents
            .GroupBy(d => d.ContainsKey("category") ? d["category"]?.ToString() ?? "Diğer" : "Diğer")
            .Select(g =>
            {
                var amount = g.Sum(d =>
                {
                    if (d.ContainsKey("totalAmount") && decimal.TryParse(d["totalAmount"]?.ToString(), out var a))
                        return a;
                    return 0m;
                });

                return new
                {
                    Category = g.Key,
                    Amount = amount,
                    Count = g.Count()
                };
            })
            .OrderByDescending(x => x.Amount)
            .ToList();

        var total = breakdown.Sum(b => b.Amount);
        var result = breakdown.Select(b => new
        {
            b.Category,
            b.Amount,
            b.Count,
            Percentage = total > 0 ? Math.Round((double)(b.Amount / total) * 100, 1) : 0
        });

        return Ok(result);
    }
}
