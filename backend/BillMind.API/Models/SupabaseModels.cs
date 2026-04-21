using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;

namespace BillMind.API.Models;

/// <summary>
/// Supabase 'documents' tablosu için satır modeli.
/// </summary>
[Table("documents")]
public class DocumentRow : BaseModel
{
    [PrimaryKey("id", false)]
    [Column("id")]
    public string? Id { get; set; }

    [Column("user_id")]
    public string? UserId { get; set; }

    [Column("name")]
    public string? Name { get; set; }

    [Column("original_filename")]
    public string? OriginalFilename { get; set; }

    [Column("file_type")]
    public string? FileType { get; set; }

    [Column("category")]
    public string? Category { get; set; }

    [Column("cloudinary_public_id")]
    public string? CloudinaryPublicId { get; set; }

    [Column("cloudinary_url")]
    public string? CloudinaryUrl { get; set; }

    [Column("cloudinary_secure_url")]
    public string? CloudinarySecureUrl { get; set; }

    [Column("status")]
    public string? Status { get; set; }

    [Column("amount")]
    public decimal? Amount { get; set; }

    [Column("currency")]
    public string? Currency { get; set; }

    [Column("payment_status")]
    public string? PaymentStatus { get; set; }

    [Column("created_at")]
    public string? CreatedAt { get; set; }
    
    [Column("updated_at")]
    public string? UpdatedAt { get; set; }
}

/// <summary>
/// Supabase 'profiles' tablosu için satır modeli.
/// </summary>
[Table("profiles")]
public class ProfileRow : BaseModel
{
    [PrimaryKey("id", false)]
    [Column("id")]
    public string? Id { get; set; }

    [Column("full_name")]
    public string? FullName { get; set; }

    [Column("email")]
    public string? Email { get; set; }

    [Column("avatar_cloudinary_url")]
    public string? AvatarUrl { get; set; }

    [Column("company_name")]
    public string? CompanyName { get; set; }

    [Column("created_at")]
    public string? CreatedAt { get; set; }

    [Column("role")]
    public string? Role { get; set; }

    [Column("tax_id")]
    public string? TaxId { get; set; }

    [Column("trade_reg_no")]
    public string? TradeRegNo { get; set; }

    [Column("address")]
    public string? Address { get; set; }

    [Column("subscription_plan")]
    public string? SubscriptionPlan { get; set; }

    [Column("subscription_renewal")]
    public string? SubscriptionRenewal { get; set; }

    [Column("document_limit")]
    public int? DocumentLimit { get; set; }
}
