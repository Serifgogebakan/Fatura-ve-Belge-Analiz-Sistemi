using BillMind.API.Services;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "BillMind API", Version = "v1", Description = "Fatura ve Belge Analiz Sistemi REST API" });
});

// CORS — Web (Next.js) ve Mobil'den gelen isteklere izin ver
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins(
                "http://localhost:3000",
                "http://localhost:3001",
                "https://billmind.app" // İlerideki production domain
            )
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// Bağımlılık Enjeksiyonu (DI)
builder.Services.AddSingleton<OcrService>();
builder.Services.AddSingleton<InvoiceParserService>();

// Büyük dosya yüklemeleri için
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(o =>
{
    o.MultipartBodyLengthLimit = 20 * 1024 * 1024; // 20 MB
});

var app = builder.Build();

// Swagger — sadece geliştirme ortamında
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "BillMind API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

// Sağlık kontrolü endpoint
app.MapGet("/health", () => Results.Ok(new { Status = "Sağlıklı", Timestamp = DateTime.UtcNow, Version = "1.0.0" }));

app.Run();
