using Microsoft.AspNetCore.Mvc;

namespace BillMind.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReportsController : ControllerBase
{
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(ILogger<ReportsController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Dashboard için aylık harcama özeti.
    /// GET /api/reports/monthly-summary
    /// </summary>
    [HttpGet("monthly-summary")]
    public ActionResult<object> GetMonthlySummary([FromQuery] int year = 0)
    {
        if (year == 0) year = DateTime.UtcNow.Year;

        // TODO: Gerçek veri Supabase'den çekilecek
        var mockData = new
        {
            Year = year,
            TotalExpenses = 42890.50m,
            Currency = "TRY",
            ChangePercent = 12.4,
            MonthlyBreakdown = new[]
            {
                new { Month = "Ocak",   Amount = 5200m },
                new { Month = "Şubat",  Amount = 8100m },
                new { Month = "Mart",   Amount = 15600m },
                new { Month = "Nisan",  Amount = 4300m },
                new { Month = "Mayıs",  Amount = 6200m },
                new { Month = "Haziran",Amount = 3490.50m },
            }
        };

        return Ok(mockData);
    }

    /// <summary>
    /// Kategori bazında harcama dağılımı.
    /// GET /api/reports/category-breakdown
    /// </summary>
    [HttpGet("category-breakdown")]
    public ActionResult<object> GetCategoryBreakdown()
    {
        // TODO: Gerçek veri Supabase'den çekilecek
        var mockData = new[]
        {
            new { Category = "Fatura",    Amount = 18500m, Percentage = 43.1 },
            new { Category = "Fiş",       Amount = 9200m,  Percentage = 21.4 },
            new { Category = "Sipariş",   Amount = 8900m,  Percentage = 20.7 },
            new { Category = "İrsaliye",  Amount = 4100m,  Percentage = 9.6  },
            new { Category = "Diğer",     Amount = 2190m,  Percentage = 5.1  },
        };

        return Ok(mockData);
    }
}
