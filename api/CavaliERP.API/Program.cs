using System.Text;
using CsmStok.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

var jwtSection = builder.Configuration.GetSection("Jwt");
var signingKey = new SymmetricSecurityKey(
    Encoding.UTF8.GetBytes(jwtSection["SigningKey"]!));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSection["Issuer"],
            ValidAudience = jwtSection["Audience"],
            IssuerSigningKey = signingKey,
            ClockSkew = TimeSpan.FromMinutes(2),
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                if (!string.IsNullOrEmpty(context.Token))
                    return Task.CompletedTask;

                // IIS / proxy Authorization düşürürse yedek header
                var alt = context.Request.Headers["X-Authorization"].FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(alt) && alt.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                    context.Token = alt["Bearer ".Length..].Trim();

                return Task.CompletedTask;
            },
            OnChallenge = async context =>
            {
                context.HandleResponse();
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new
                {
                    success = false,
                    error = "Authentication required."
                });
            }
        };
    });
builder.Services.AddAuthorization();

builder.Services.AddHttpClient(ProductImageCatalog.HttpClientName, client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
}).ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    AutomaticDecompression = System.Net.DecompressionMethods.GZip | System.Net.DecompressionMethods.Deflate,
});
builder.Services.AddSingleton<ProductImageCatalog>();
builder.Services.AddSingleton<SqlProcedureCatalog>();
builder.Services.AddSingleton<SpWhitelist>();
builder.Services.AddSingleton<SqlSpExecutor>();
builder.Services.AddSingleton<JwtTokenService>();
builder.Services.AddSingleton<ExecSpService>();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
app.MapGet("/health/db", async (IConfiguration config) =>
{
    var connectionString = config.GetConnectionString("Default");
    if (string.IsNullOrWhiteSpace(connectionString))
        return Results.Json(new { ok = false, error = "ConnectionStrings:Default is missing." }, statusCode: 503);

    try
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        return Results.Ok(new { ok = true });
    }
    catch (Exception ex)
    {
        return Results.Json(new { ok = false, error = ex.Message }, statusCode: 503);
    }
});

app.Run();
