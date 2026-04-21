using static Supabase.Postgrest.Constants;

namespace BillMind.API.Services;

/// <summary>
/// Supabase veritabanı ve kimlik doğrulama servisi.
/// Backend ile Supabase arasındaki tüm iletişimi yönetir.
/// </summary>
public class SupabaseService
{
    private readonly Supabase.Client _client;
    private readonly ILogger<SupabaseService> _logger;

    public SupabaseService(IConfiguration config, ILogger<SupabaseService> logger)
    {
        _logger = logger;

        var url = config["Supabase:Url"] ?? throw new ArgumentNullException("Supabase:Url ayarı eksik.");
        var key = config["Supabase:AnonKey"] ?? throw new ArgumentNullException("Supabase:AnonKey ayarı eksik.");

        _client = new Supabase.Client(url, key, new Supabase.SupabaseOptions
        {
            AutoRefreshToken = true,
            AutoConnectRealtime = false
        });

        _logger.LogInformation("Supabase bağlantısı başlatılıyor: {Url}", url);
    }

    /// <summary>
    /// Supabase client'ı başlatır (uygulama ayağa kalkarken çağrılmalı).
    /// </summary>
    public async Task InitializeAsync()
    {
        await _client.InitializeAsync();
        _logger.LogInformation("Supabase bağlantısı başarılı.");
    }

    /// <summary>
    /// Supabase Client nesnesini döner.
    /// </summary>
    public Supabase.Client GetClient() => _client;

    // ────────────────────── BELGELER (Documents) ──────────────────────

    /// <summary>
    /// Yeni belgeyi veritabanına kaydeder.
    /// </summary>
    public async Task<bool> SaveDocumentAsync(Models.Document doc)
    {
        try
        {
            var row = new Models.DocumentRow
            {
                Id = doc.Id.ToString(),
                UserId = doc.UserId,
                Name = doc.FileName,
                OriginalFilename = doc.FileName,
                FileType = doc.FileType?.Contains("pdf") == true ? "pdf" : doc.FileType?.Contains("image") == true ? "image" : "other",
                Category = doc.ParsedData?.Category ?? "FATURA",
                CloudinarySecureUrl = doc.FileUrl,
                Status = doc.Status,
                Amount = doc.ParsedData?.TotalAmount ?? 0,
                Currency = doc.ParsedData?.Currency ?? "TRY",
                PaymentStatus = "beklemede",
                CreatedAt = doc.UploadedAt.ToString("o")
            };

            await _client.From<Models.DocumentRow>().Insert(row);
            _logger.LogInformation("Belge kaydedildi. ID: {Id}", doc.Id);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Belge kaydedilemedi. ID: {Id}", doc.Id);
            return false;
        }
    }

    /// <summary>
    /// Kullanıcının tüm belgelerini getirir.
    /// </summary>
    public async Task<List<Dictionary<string, object>>?> GetDocumentsByUserAsync(string userId)
    {
        try
        {
            var result = await _client
                .From<Models.DocumentRow>()
                .Filter("user_id", Operator.Equals, userId)
                .Order("created_at", Ordering.Descending)
                .Get();

            _logger.LogInformation("Kullanıcının belgeleri çekildi. UserID: {UserId}, Adet: {Count}", userId, result.Models.Count);

            return result.Models.Select(m => new Dictionary<string, object>
            {
                { "id", m.Id ?? "" },
                { "fileName", m.Name ?? "" },
                { "fileUrl", m.CloudinarySecureUrl ?? "" },
                { "status", m.Status ?? "" },
                { "uploadedAt", m.CreatedAt ?? "" },
                { "category", m.Category ?? "" },
                { "totalAmount", m.Amount },
                { "currency", m.Currency ?? "TRY" },
                { "paymentStatus", m.PaymentStatus ?? "" },
                { "payment_status", m.PaymentStatus ?? "" }
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Belgeler çekilemedi. UserID: {UserId}", userId);
            return null;
        }
    }

    /// <summary>
    /// Belirli bir belgeyi ID ile getirir.
    /// </summary>
    public async Task<Dictionary<string, object>?> GetDocumentByIdAsync(string documentId)
    {
        try
        {
            var result = await _client
                .From<Models.DocumentRow>()
                .Filter("id", Operator.Equals, documentId)
                .Single();

            if (result == null) return null;

            return new Dictionary<string, object>
            {
                { "id", result.Id ?? "" },
                { "fileName", result.Name ?? "" },
                { "fileUrl", result.CloudinarySecureUrl ?? "" },
                { "fileType", result.FileType ?? "" },
                { "status", result.Status ?? "" },
                { "uploadedAt", result.CreatedAt ?? "" },
                { "category", result.Category ?? "" },
                { "totalAmount", result.Amount },
                { "currency", result.Currency ?? "TRY" }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Belge bulunamadı. ID: {Id}", documentId);
            return null;
        }
    }

    // ────────────────────── KULLANICI PROFİLİ ──────────────────────

    /// <summary>
    /// Kullanıcı profilini Supabase'den getirir.
    /// </summary>
    public async Task<Dictionary<string, object>?> GetUserProfileAsync(string userId)
    {
        try
        {
            var result = await _client
                .From<Models.ProfileRow>()
                .Filter("id", Operator.Equals, userId)
                .Single();

            if (result == null) return null;

            return new Dictionary<string, object>
            {
                { "id", result.Id ?? "" },
                { "fullName", result.FullName ?? "" },
                { "email", result.Email ?? "" },
                { "avatarUrl", result.AvatarUrl ?? "" },
                { "companyName", result.CompanyName ?? "" },
                { "createdAt", result.CreatedAt ?? "" },
                { "role", result.Role ?? "user" },
                { "taxId", result.TaxId ?? "" },
                { "tradeRegNo", result.TradeRegNo ?? "" },
                { "address", result.Address ?? "" },
                { "subscriptionPlan", result.SubscriptionPlan ?? "free" },
                { "subscriptionRenewal", result.SubscriptionRenewal ?? "" },
                { "documentLimit", result.DocumentLimit }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Profil çekilemedi. UserID: {UserId}", userId);
            return null;
        }
    }

    public async Task<bool> UpdateUserProfileAsync(Models.ProfileRow profile)
    {
        try
        {
            var existingProfile = await _client.From<Models.ProfileRow>().Filter("id", Operator.Equals, profile.Id!).Single();
            if (existingProfile != null)
            {
                existingProfile.FullName = profile.FullName ?? existingProfile.FullName;
                existingProfile.CompanyName = profile.CompanyName ?? existingProfile.CompanyName;
                existingProfile.TaxId = profile.TaxId ?? existingProfile.TaxId;
                existingProfile.TradeRegNo = profile.TradeRegNo ?? existingProfile.TradeRegNo;
                existingProfile.Address = profile.Address ?? existingProfile.Address;
                
                await _client.From<Models.ProfileRow>().Update(existingProfile);
            }
            else 
            {
                await _client.From<Models.ProfileRow>().Insert(profile);
            }
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Profil güncellenemedi. UserID: {UserId}", profile.Id);
            return false;
        }
    }

    // ────────────────────── RAPORLAR ──────────────────────

    /// <summary>
    /// Kullanıcının aylık harcama özetini veritabanından çeker.
    /// </summary>
    public async Task<object?> GetMonthlySummaryAsync(string userId, int year)
    {
        try
        {
            var result = await _client
                .From<Models.DocumentRow>()
                .Filter("user_id", Operator.Equals, userId)
                .Get();

            var docs = result.Models
                .Where(d => !string.IsNullOrEmpty(d.CreatedAt) && DateTime.TryParse(d.CreatedAt, out var dt) && dt.Year == year)
                .ToList();

            var monthlyBreakdown = docs
                .GroupBy(d => DateTime.Parse(d.CreatedAt!).Month)
                .Select(g => new
                {
                    Month = g.Key,
                    Amount = g.Sum(d => d.Amount)
                })
                .OrderBy(x => x.Month)
                .ToList();

            var total = monthlyBreakdown.Sum(m => m.Amount);

            return new
            {
                Year = year,
                TotalExpenses = total,
                Currency = "TRY",
                DocumentCount = docs.Count,
                MonthlyBreakdown = monthlyBreakdown
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Aylık özet alınamadı. UserID: {UserId}", userId);
            return null;
        }
    }
}
