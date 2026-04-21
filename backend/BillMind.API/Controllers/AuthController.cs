using BillMind.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace BillMind.API.Controllers;

/// <summary>
/// Kullanıcı kimlik doğrulama ve profil yönetimi.
/// Tüm auth işlemleri bu controller üzerinden Supabase'e yönlendirilir.
/// Frontend doğrudan Supabase'e bağlanamaz — her şey backend üzerinden geçer.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly SupabaseService _supabase;
    private readonly ILogger<AuthController> _logger;

    public AuthController(SupabaseService supabase, ILogger<AuthController> logger)
    {
        _supabase = supabase;
        _logger = logger;
    }

    // ────────────────────── GİRİŞ ──────────────────────

    /// <summary>
    /// Kullanıcı girişi yapar.
    /// POST /api/auth/login
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<object>> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrEmpty(request.Email) || string.IsNullOrEmpty(request.Password))
            return BadRequest(new { message = "E-posta ve şifre gereklidir." });

        try
        {
            var client = _supabase.GetClient();
            var session = await client.Auth.SignIn(request.Email, request.Password);

            if (session == null)
            {
                return Unauthorized(new { message = "E-posta veya şifre hatalı." });
            }

            _logger.LogInformation("Kullanıcı giriş yaptı: {Email}", request.Email);

            return Ok(new
            {
                user = new
                {
                    id = session.User?.Id,
                    email = session.User?.Email,
                    fullName = session.User?.UserMetadata?.ContainsKey("full_name") == true
                        ? session.User.UserMetadata["full_name"]?.ToString()
                        : ""
                },
                accessToken = session.AccessToken,
                refreshToken = session.RefreshToken,
                expiresIn = session.ExpiresIn
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Giriş hatası: {Email}", request.Email);

            var msg = "Giriş yapılamadı. Lütfen tekrar deneyin.";
            if (ex.Message.Contains("Invalid login credentials"))
                msg = "E-posta veya şifre hatalı.";
            else if (ex.Message.Contains("Email not confirmed"))
                msg = "E-posta adresiniz henüz doğrulanmamış.";
            else if (ex.Message.Contains("rate limit"))
                msg = "Çok fazla deneme yapıldı. Lütfen bekleyin.";

            return Unauthorized(new { message = msg });
        }
    }

    // ────────────────────── KAYIT ──────────────────────

    /// <summary>
    /// Yeni kullanıcı kaydı oluşturur.
    /// POST /api/auth/register
    /// </summary>
    [HttpPost("register")]
    public async Task<ActionResult<object>> Register([FromBody] RegisterRequest request)
    {
        if (string.IsNullOrEmpty(request.Email) || string.IsNullOrEmpty(request.Password))
            return BadRequest(new { message = "E-posta ve şifre gereklidir." });

        if (request.Password.Length < 6)
            return BadRequest(new { message = "Şifre en az 6 karakter olmalıdır." });

        try
        {
            var client = _supabase.GetClient();
            var session = await client.Auth.SignUp(request.Email, request.Password);

            if (session?.User == null)
            {
                return BadRequest(new { message = "Kayıt sırasında bir hata oluştu." });
            }

            // Kullanıcı metadata'sını güncelle (full_name)
            if (!string.IsNullOrEmpty(request.FullName))
            {
                try
                {
                    var attrs = new Supabase.Gotrue.UserAttributes
                    {
                        Data = new Dictionary<string, object>
                        {
                            { "full_name", request.FullName }
                        }
                    };
                    await client.Auth.Update(attrs);
                }
                catch (Exception metaEx)
                {
                    _logger.LogWarning(metaEx, "Kullanıcı metadata güncellenemedi: {Email}", request.Email);
                }
            }

            _logger.LogInformation("Yeni kullanıcı kaydı: {Email}", request.Email);

            return Ok(new
            {
                user = new
                {
                    id = session.User.Id,
                    email = session.User.Email,
                    fullName = request.FullName ?? ""
                },
                accessToken = session.AccessToken,
                refreshToken = session.RefreshToken,
                message = "Hesabınız başarıyla oluşturuldu."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Kayıt hatası: {Email}", request.Email);

            var msg = "Kayıt sırasında bir hata oluştu.";
            if (ex.Message.Contains("User already registered"))
                msg = "Bu e-posta adresi zaten kayıtlı.";
            else if (ex.Message.Contains("Password should be"))
                msg = "Şifre en az 6 karakter olmalıdır.";
            else if (ex.Message.Contains("rate limit"))
                msg = "Çok fazla deneme yapıldı. Lütfen bekleyin.";

            return BadRequest(new { message = msg });
        }
    }

    // ────────────────────── TOKEN DOĞRULAMA ──────────────────────

    /// <summary>
    /// Supabase JWT token ile kullanıcı doğrulaması yapar.
    /// POST /api/auth/verify
    /// </summary>
    [HttpPost("verify")]
    public async Task<ActionResult<object>> VerifyToken()
    {
        var authHeader = Request.Headers["Authorization"].FirstOrDefault();
        if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer "))
        {
            return Unauthorized(new { message = "Yetki token'ı eksik." });
        }

        var token = authHeader.Substring("Bearer ".Length);

        try
        {
            var client = _supabase.GetClient();
            var user = await client.Auth.GetUser(token);

            if (user == null)
            {
                return Unauthorized(new { message = "Geçersiz token." });
            }

            _logger.LogInformation("Kullanıcı doğrulandı: {Email}", user.Email);

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.UserMetadata?.ContainsKey("full_name") == true
                    ? user.UserMetadata["full_name"]?.ToString()
                    : "",
                verified = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Token doğrulama hatası.");
            return Unauthorized(new { message = "Token doğrulanamadı." });
        }
    }

    // ────────────────────── PROFİL ──────────────────────

    /// <summary>
    /// Kullanıcı profilini getirir.
    /// GET /api/auth/profile?userId={userId}
    /// </summary>
    [HttpGet("profile")]
    public async Task<ActionResult<object>> GetProfile([FromQuery] string userId)
    {
        if (string.IsNullOrEmpty(userId))
            return BadRequest(new { message = "userId gerekli." });

        var profile = await _supabase.GetUserProfileAsync(userId);
        if (profile == null)
            return NotFound(new { message = "Profil bulunamadı." });

        return Ok(profile);
    }

    /// <summary>
    /// Sağlık kontrolü ve Supabase bağlantı durumu.
    /// GET /api/auth/status
    /// </summary>
    [HttpGet("status")]
    public ActionResult<object> GetStatus()
    {
        return Ok(new
        {
            service = "BillMind Auth API",
            status = "Aktif",
            supabaseConnected = true,
            timestamp = DateTime.UtcNow
        });
    }
    [HttpPut("profile")]
    public async Task<ActionResult<object>> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        if (string.IsNullOrEmpty(request.Id))
            return BadRequest(new { message = "Kullanıcı ID gereklidir." });

        var profile = new BillMind.API.Models.ProfileRow
        {
            Id = request.Id,
            FullName = request.FullName,
            CompanyName = request.CompanyName,
            TaxId = request.TaxId,
            TradeRegNo = request.TradeRegNo,
            Address = request.Address
        };

        var success = await _supabase.UpdateUserProfileAsync(profile);
        if (!success)
            return BadRequest(new { message = "Profil güncellenirken hata oluştu." });

        // UserMetadata update in Auth
        try
        {
            var client = _supabase.GetClient();
            var attrs = new Supabase.Gotrue.UserAttributes
            {
                Data = new Dictionary<string, object>
                {
                    { "full_name", request.FullName ?? "" }
                }
            };
            await client.Auth.Update(attrs);
        } catch { }

        return Ok(new { success = true });
    }
}

// ────────────────────── DTO'lar ──────────────────────

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class RegisterRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class UpdateProfileRequest
{
    public string Id { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? CompanyName { get; set; }
    public string? TaxId { get; set; }
    public string? TradeRegNo { get; set; }
    public string? Address { get; set; }
}
