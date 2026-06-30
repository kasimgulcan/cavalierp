# CSM.Stok Mobil Uygulama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter mobil uygulama ve ASP.NET Core generic SP gateway API'sini oluşturarak barkod okuma, sepet ve satış kaydı akışını internet üzerinden SQL Server `API_*` stored procedure'leri ile çalışır hale getirmek.

**Architecture:** Ayrı `api/` (ASP.NET Core, IIS) ve `mobile/` (Flutter) projeleri. API yalnızca whitelist'teki `API_*` SP'leri parametreli `SqlCommand` ile çağırır; `TenantId`/`UserId` JWT'den enjekte edilir. İş kuralları SQL'de; mobil tüm çağrıları `SpClient.exec(alias, params)` üzerinden yapar.

**Tech Stack:** Flutter 3.x, Riverpod, Dio, go_router, mobile_scanner · ASP.NET Core 8, Microsoft.Data.SqlClient, JWT Bearer · SQL Server (SP'ler `API_` öneki)

## Global Constraints

- Tüm mobil SP'ler SQL'de `API_{Modül}_{Eylem}` adıyla oluşturulur.
- API dinamik SQL kullanmaz; yalnızca whitelist'teki sabit SP adları çağrılır.
- `TenantId` ve `UserId` istemciden kabul edilmez; JWT'den server-side enjekte edilir.
- Çevrimdışı mod yok; bağlantı yoksa işlem yapılamaz.
- `Membership:RequireApproval` config varsayılan `false` (mağaza incelemesi).
- Masaüstü onay modülü bu workspace dışında; yalnızca `API_Membership_*` SP script'leri sağlanır.
- Mevcut kullanıcı/müşteri/ödeme tabloları kullanılır; SQL script'lerde `TODO-ADAPT` yorumları ile işaretlenen tablo adları gerçek şemaya uyarlanır.

---

## File Map

| Path | Sorumluluk |
|---|---|
| `sql/API_Auth_*.sql` | Auth SP'leri |
| `sql/API_Lookup_*.sql` | Müşteri/ödeme listeleri |
| `sql/API_Product_*.sql` | Barkod sorgusu |
| `sql/API_Sale_*.sql` | Satış oluşturma |
| `sql/API_Membership_*.sql` | Masaüstü onay modülü SP'leri |
| `api/CsmStok.Api/` | ASP.NET Core Web API |
| `api/CsmStok.Api/Models/` | Request/response DTO'lar |
| `api/CsmStok.Api/Services/SpWhitelist.cs` | Alias → SP eşlemesi + parametre şeması |
| `api/CsmStok.Api/Services/SqlSpExecutor.cs` | Parametreli SP çalıştırma |
| `api/CsmStok.Api/Services/JwtTokenService.cs` | Token üretim/doğrulama |
| `api/CsmStok.Api/Controllers/AuthExecController.cs` | `POST /api/auth/exec` |
| `api/CsmStok.Api/Controllers/ExecController.cs` | `POST /api/exec` |
| `api/CsmStok.Api.Tests/` | API unit testleri |
| `mobile/lib/core/network/sp_client.dart` | Generic exec wrapper |
| `mobile/lib/features/auth/` | Login, register, profile |
| `mobile/lib/features/sale/` | Scanner, cart, checkout |

---

### Task 1: Repository scaffolding

**Files:**
- Create: `sql/.gitkeep`
- Create: `api/.gitkeep`
- Create: `mobile/.gitkeep`
- Create: `README.md`

**Interfaces:**
- Produces: Boş klasör yapısı `CSM.Stok/{sql,api,mobile,docs}`

- [ ] **Step 1: Klasörleri oluştur**

```powershell
cd c:\Users\KasimGulcan\Desktop\CSM.Stok
New-Item -ItemType Directory -Force -Path sql, api, mobile
```

- [ ] **Step 2: README yaz**

Create `README.md`:

```markdown
# CSM.Stok

Mobil satış uygulaması (Flutter) + SP gateway API (ASP.NET Core).

- `mobile/` — Flutter iOS/Android uygulaması
- `api/` — IIS üzerinde çalışan Web API
- `sql/` — `API_*` stored procedure script'leri
- `docs/superpowers/specs/` — Tasarım spesifikasyonu
```

- [ ] **Step 3: Doğrula**

Run: `Get-ChildItem -Name`
Expected: `api`, `mobile`, `sql`, `docs`, `README.md`

---

### Task 2: API proje iskeleti

**Files:**
- Create: `api/CsmStok.Api/CsmStok.Api.csproj`
- Create: `api/CsmStok.Api/Program.cs`
- Create: `api/CsmStok.Api/appsettings.json`
- Create: `api/CsmStok.Api/appsettings.Development.json`
- Create: `api/CsmStok.sln`

**Interfaces:**
- Produces: Çalışan boş Web API, `GET /health` → `200 OK`

- [ ] **Step 1: Solution ve proje oluştur**

```powershell
cd c:\Users\KasimGulcan\Desktop\CSM.Stok\api
dotnet new sln -n CsmStok
dotnet new webapi -n CsmStok.Api --no-openapi
dotnet sln add CsmStok.Api/CsmStok.Api.csproj
cd CsmStok.Api
dotnet add package Microsoft.Data.SqlClient
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

- [ ] **Step 2: appsettings.json yapılandır**

Create `api/CsmStok.Api/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "Default": "Server=localhost;Database=CsmStok;Trusted_Connection=True;TrustServerCertificate=True"
  },
  "Jwt": {
    "Issuer": "CsmStok",
    "Audience": "CsmStok.Mobile",
    "SigningKey": "DEV_ONLY_CHANGE_IN_PRODUCTION_MIN_32_CHARS!!",
    "AccessTokenMinutes": 15,
    "RefreshTokenDays": 30
  },
  "Membership": {
    "RequireApproval": false
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

- [ ] **Step 3: Program.cs — health endpoint**

Replace `api/CsmStok.Api/Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddAuthentication().AddJwtBearer();
builder.Services.AddAuthorization();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Run();
```

- [ ] **Step 4: Çalıştır ve doğrula**

```powershell
cd c:\Users\KasimGulcan\Desktop\CSM.Stok\api\CsmStok.Api
dotnet run
```

Run (ayrı terminal): `curl http://localhost:5000/health` veya launchSettings portu
Expected: `{"status":"healthy"}`

---

### Task 3: ExecSP DTO modelleri

**Files:**
- Create: `api/CsmStok.Api/Models/ExecSpRequest.cs`
- Create: `api/CsmStok.Api/Models/ExecSpResponse.cs`

**Interfaces:**
- Produces: `ExecSpRequest { string Sp, Dictionary<string, object?>? Params }`
- Produces: `ExecSpResponse { bool Success, object? Data, string? Error }`

- [ ] **Step 1: Request model**

Create `api/CsmStok.Api/Models/ExecSpRequest.cs`:

```csharp
namespace CsmStok.Api.Models;

public sealed class ExecSpRequest
{
    public required string Sp { get; init; }
    public Dictionary<string, object?>? Params { get; init; }
}
```

- [ ] **Step 2: Response model**

Create `api/CsmStok.Api/Models/ExecSpResponse.cs`:

```csharp
namespace CsmStok.Api.Models;

public sealed class ExecSpResponse
{
    public bool Success { get; init; }
    public object? Data { get; init; }
    public string? Error { get; init; }

    public static ExecSpResponse Ok(object? data) => new() { Success = true, Data = data };
    public static ExecSpResponse Fail(string error) => new() { Success = false, Error = error };
}
```

- [ ] **Step 3: Build doğrula**

Run: `dotnet build`
Expected: Build succeeded

---

### Task 4: SP Whitelist servisi (TDD)

**Files:**
- Create: `api/CsmStok.Api/Services/SpDefinition.cs`
- Create: `api/CsmStok.Api/Services/SpWhitelist.cs`
- Create: `api/CsmStok.Api.Tests/CsmStok.Api.Tests.csproj`
- Create: `api/CsmStok.Api.Tests/SpWhitelistTests.cs`
- Modify: `api/CsmStok.Api/Program.cs`

**Interfaces:**
- Produces: `SpDefinition { string Alias, string SqlName, IReadOnlySet<string> AllowedParams, bool RequiresAuth, bool RequiresTenant }`
- Produces: `SpWhitelist.TryGet(string alias, out SpDefinition? def)` → bool
- Produces: `SpWhitelist.ValidateParams(SpDefinition def, Dictionary<string, object?>? params)` → `string?` error veya null

- [ ] **Step 1: Test projesi oluştur**

```powershell
cd c:\Users\KasimGulcan\Desktop\CSM.Stok\api
dotnet new xunit -n CsmStok.Api.Tests
dotnet sln add CsmStok.Api.Tests/CsmStok.Api.Tests.csproj
dotnet add CsmStok.Api.Tests/CsmStok.Api.Tests.csproj reference CsmStok.Api/CsmStok.Api.csproj
```

- [ ] **Step 2: Failing test yaz**

Create `api/CsmStok.Api.Tests/SpWhitelistTests.cs`:

```csharp
using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class SpWhitelistTests
{
    [Fact]
    public void TryGet_KnownAlias_ReturnsDefinition()
    {
        var whitelist = new SpWhitelist();
        var found = whitelist.TryGet("Product.GetByBarcode", out var def);
        Assert.True(found);
        Assert.Equal("API_Product_GetByBarcode", def!.SqlName);
    }

    [Fact]
    public void TryGet_UnknownAlias_ReturnsFalse()
    {
        var whitelist = new SpWhitelist();
        var found = whitelist.TryGet("Evil.DropDatabase", out _);
        Assert.False(found);
    }

    [Fact]
    public void ValidateParams_ExtraParam_ReturnsError()
    {
        var whitelist = new SpWhitelist();
        whitelist.TryGet("Product.GetByBarcode", out var def);
        var error = whitelist.ValidateParams(def!, new Dictionary<string, object?>
        {
            ["Barcode"] = "123",
            ["TenantId"] = 1
        });
        Assert.NotNull(error);
        Assert.Contains("TenantId", error);
    }
}
```

- [ ] **Step 3: Testi çalıştır — fail beklenir**

Run: `dotnet test api/CsmStok.Api.Tests --filter SpWhitelistTests -v n`
Expected: FAIL — `SpWhitelist` not found

- [ ] **Step 4: SpDefinition ve SpWhitelist implement et**

Create `api/CsmStok.Api/Services/SpDefinition.cs`:

```csharp
namespace CsmStok.Api.Services;

public sealed record SpDefinition(
    string Alias,
    string SqlName,
    IReadOnlySet<string> AllowedParams,
    bool RequiresAuth,
    bool RequiresTenant);
```

Create `api/CsmStok.Api/Services/SpWhitelist.cs`:

```csharp
namespace CsmStok.Api.Services;

public sealed class SpWhitelist
{
    private static readonly IReadOnlyDictionary<string, SpDefinition> Definitions =
        new Dictionary<string, SpDefinition>(StringComparer.OrdinalIgnoreCase)
        {
            ["Auth.Register"] = new("Auth.Register", "API_Auth_Register",
                new HashSet<string> { "Email", "Password", "AcceptedTerms" }, false, false),
            ["Auth.Login"] = new("Auth.Login", "API_Auth_Login",
                new HashSet<string> { "Email", "Password" }, false, false),
            ["Auth.RefreshToken"] = new("Auth.RefreshToken", "API_Auth_RefreshToken",
                new HashSet<string> { "RefreshToken" }, false, false),
            ["Auth.DeleteAccount"] = new("Auth.DeleteAccount", "API_Auth_DeleteAccount",
                new HashSet<string>(), true, false),
            ["Auth.GetProfile"] = new("Auth.GetProfile", "API_Auth_GetProfile",
                new HashSet<string>(), true, false),
            ["Product.GetByBarcode"] = new("Product.GetByBarcode", "API_Product_GetByBarcode",
                new HashSet<string> { "Barcode" }, true, true),
            ["Lookup.Customers"] = new("Lookup.Customers", "API_Lookup_Customers",
                new HashSet<string> { "Search" }, true, true),
            ["Lookup.PaymentTypes"] = new("Lookup.PaymentTypes", "API_Lookup_PaymentTypes",
                new HashSet<string>(), true, true),
            ["Sale.Create"] = new("Sale.Create", "API_Sale_Create",
                new HashSet<string> { "CustomerId", "PaymentTypeId", "Lines", "Note" }, true, true),
        };

    public bool TryGet(string alias, out SpDefinition? definition)
    {
        if (Definitions.TryGetValue(alias, out var def))
        {
            definition = def;
            return true;
        }
        definition = null;
        return false;
    }

    public string? ValidateParams(SpDefinition definition, Dictionary<string, object?>? parameters)
    {
        parameters ??= new Dictionary<string, object?>();
        var injected = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { "UserId", "TenantId", "Culture" };
        foreach (var key in parameters.Keys)
        {
            if (injected.Contains(key))
                return $"Parameter '{key}' is not allowed from client.";
            if (!definition.AllowedParams.Contains(key))
                return $"Parameter '{key}' is not allowed for {definition.Alias}.";
        }
        return null;
    }
}
```

- [ ] **Step 5: Program.cs'e servis kaydı**

Add to `Program.cs` before `var app = builder.Build();`:

```csharp
builder.Services.AddSingleton<SpWhitelist>();
```

- [ ] **Step 6: Testleri çalıştır**

Run: `dotnet test api/CsmStok.Api.Tests --filter SpWhitelistTests -v n`
Expected: PASS (3 tests)

---

### Task 5: SqlSpExecutor (TDD)

**Files:**
- Create: `api/CsmStok.Api/Services/SqlSpExecutor.cs`
- Create: `api/CsmStok.Api.Tests/SqlSpExecutorTests.cs`
- Modify: `api/CsmStok.Api/Program.cs`

**Interfaces:**
- Consumes: `SpDefinition`, connection string `ConnectionStrings:Default`
- Produces: `Task<ExecSpResponse> SqlSpExecutor.ExecuteAsync(SpDefinition def, Dictionary<string, object?> spParams, CancellationToken ct)`

- [ ] **Step 1: Failing test (mock connection ile interface test)**

Create `api/CsmStok.Api.Tests/SqlSpExecutorTests.cs`:

```csharp
using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class SqlSpExecutorTests
{
    [Fact]
    public void BuildParameter_JsonElement_ConvertsToString()
    {
        var json = System.Text.Json.JsonDocument.Parse("\"8690\"").RootElement;
        var value = SqlSpExecutor.ConvertParameter(json);
        Assert.Equal("8690", value);
    }
}
```

- [ ] **Step 2: Test fail**

Run: `dotnet test api/CsmStok.Api.Tests --filter SqlSpExecutorTests -v n`
Expected: FAIL

- [ ] **Step 3: SqlSpExecutor implement et**

Create `api/CsmStok.Api/Services/SqlSpExecutor.cs`:

```csharp
using System.Data;
using System.Text.Json;
using CsmStok.Api.Models;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services;

public sealed class SqlSpExecutor(IConfiguration configuration)
{
    private string ConnectionString => configuration.GetConnectionString("Default")
        ?? throw new InvalidOperationException("Connection string missing.");

    public async Task<ExecSpResponse> ExecuteAsync(
        SpDefinition definition,
        Dictionary<string, object?> parameters,
        CancellationToken cancellationToken = default)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(definition.SqlName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        foreach (var (key, value) in parameters)
        {
            command.Parameters.AddWithValue($"@{key}", ConvertParameter(value) ?? DBNull.Value);
        }

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<Dictionary<string, object?>>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var row = new Dictionary<string, object?>();
            for (var i = 0; i < reader.FieldCount; i++)
                row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            rows.Add(row);
        }
        return ExecSpResponse.Ok(rows);
    }

    public static object? ConvertParameter(object? value)
    {
        if (value is JsonElement element)
        {
            return element.ValueKind switch
            {
                JsonValueKind.String => element.GetString(),
                JsonValueKind.Number => element.TryGetInt64(out var l) ? l : element.GetDecimal(),
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                JsonValueKind.Null => null,
                _ => element.GetRawText()
            };
        }
        return value;
    }
}
```

Register in `Program.cs`:

```csharp
builder.Services.AddSingleton<SqlSpExecutor>();
```

- [ ] **Step 4: Test pass**

Run: `dotnet test api/CsmStok.Api.Tests --filter SqlSpExecutorTests -v n`
Expected: PASS

---

### Task 6: JWT Token servisi

**Files:**
- Create: `api/CsmStok.Api/Services/JwtTokenService.cs`
- Create: `api/CsmStok.Api/Models/TokenResult.cs`
- Modify: `api/CsmStok.Api/Program.cs`

**Interfaces:**
- Produces: `TokenResult { string AccessToken, string RefreshToken, DateTime ExpiresAt }`
- Produces: `JwtTokenService.CreateTokens(int userId, int? tenantId, string email)`
- Produces: `JwtTokenService.ValidateAccessToken(string token)` → `ClaimsPrincipal?`

- [ ] **Step 1: TokenResult model**

Create `api/CsmStok.Api/Models/TokenResult.cs`:

```csharp
namespace CsmStok.Api.Models;

public sealed record TokenResult(string AccessToken, string RefreshToken, DateTime ExpiresAt);
```

- [ ] **Step 2: JwtTokenService**

Create `api/CsmStok.Api/Services/JwtTokenService.cs`:

```csharp
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using CsmStok.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace CsmStok.Api.Services;

public sealed class JwtTokenService(IConfiguration configuration)
{
    public TokenResult CreateTokens(int userId, int? tenantId, string email)
    {
        var jwt = configuration.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["SigningKey"]!));
        var expires = DateTime.UtcNow.AddMinutes(int.Parse(jwt["AccessTokenMinutes"]!));

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Email, email),
        };
        if (tenantId.HasValue)
            claims.Add(new Claim("tenant_id", tenantId.Value.ToString()));

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        var accessToken = new JwtSecurityTokenHandler().WriteToken(token);
        var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        return new TokenResult(accessToken, refreshToken, expires);
    }
}
```

- [ ] **Step 3: JWT middleware yapılandırması**

Replace auth section in `Program.cs`:

```csharp
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
            IssuerSigningKey = signingKey
        };
    });
builder.Services.AddSingleton<JwtTokenService>();
```

Add usings: `Microsoft.AspNetCore.Authentication.JwtBearer`, `Microsoft.IdentityModel.Tokens`, `System.Text`

- [ ] **Step 4: Build**

Run: `dotnet build api/CsmStok.Api`
Expected: Build succeeded

---

### Task 7: Exec controller'lar

**Files:**
- Create: `api/CsmStok.Api/Controllers/AuthExecController.cs`
- Create: `api/CsmStok.Api/Controllers/ExecController.cs`
- Create: `api/CsmStok.Api/Services/ExecSpService.cs`

**Interfaces:**
- Consumes: `SpWhitelist`, `SqlSpExecutor`, `JwtTokenService`, `IConfiguration` (`Membership:RequireApproval`)
- Produces: `POST /api/auth/exec` ve `POST /api/exec` endpoint'leri

- [ ] **Step 1: ExecSpService — ortak iş mantığı**

Create `api/CsmStok.Api/Services/ExecSpService.cs`:

```csharp
using System.Security.Claims;
using CsmStok.Api.Models;

namespace CsmStok.Api.Services;

public sealed class ExecSpService(
    SpWhitelist whitelist,
    SqlSpExecutor executor,
    IConfiguration configuration)
{
    public async Task<(int StatusCode, ExecSpResponse Body)> ExecuteAsync(
        ExecSpRequest request,
        ClaimsPrincipal? user,
        CancellationToken ct)
    {
        if (!whitelist.TryGet(request.Sp, out var def))
            return (StatusCodes.Status403Forbidden, ExecSpResponse.Fail("SP not allowed."));

        var paramError = whitelist.ValidateParams(def!, request.Params);
        if (paramError is not null)
            return (StatusCodes.Status400BadRequest, ExecSpResponse.Fail(paramError));

        if (def!.RequiresAuth && user?.Identity?.IsAuthenticated != true)
            return (StatusCodes.Status401Unauthorized, ExecSpResponse.Fail("Authentication required."));

        var spParams = new Dictionary<string, object?>(request.Params ?? []);
        if (def.RequiresTenant)
        {
            var tenantClaim = user?.FindFirst("tenant_id")?.Value;
            if (configuration.GetValue<bool>("Membership:RequireApproval") && tenantClaim is null)
                return (StatusCodes.Status403Forbidden, ExecSpResponse.Fail("Account pending approval."));
            if (tenantClaim is not null)
                spParams["TenantId"] = int.Parse(tenantClaim);
        }

        if (user?.FindFirst(ClaimTypes.NameIdentifier)?.Value is { } userId)
            spParams["UserId"] = int.Parse(userId);

        try
        {
            var result = await executor.ExecuteAsync(def, spParams, ct);
            return (StatusCodes.Status200OK, result);
        }
        catch (Exception ex)
        {
            return (StatusCodes.Status500InternalServerError, ExecSpResponse.Fail(ex.Message));
        }
    }
}
```

Register: `builder.Services.AddSingleton<ExecSpService>();`

- [ ] **Step 2: AuthExecController**

Create `api/CsmStok.Api/Controllers/AuthExecController.cs`:

```csharp
using CsmStok.Api.Models;
using CsmStok.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[Route("api/auth/exec")]
public sealed class AuthExecController(ExecSpService execSpService) : ControllerBase
{
    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Execute([FromBody] ExecSpRequest request, CancellationToken ct)
    {
        var (status, body) = await execSpService.ExecuteAsync(request, User, ct);
        return StatusCode(status, body);
    }
}
```

- [ ] **Step 3: ExecController**

Create `api/CsmStok.Api/Controllers/ExecController.cs`:

```csharp
using CsmStok.Api.Models;
using CsmStok.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[Route("api/exec")]
[Authorize]
public sealed class ExecController(ExecSpService execSpService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Execute([FromBody] ExecSpRequest request, CancellationToken ct)
    {
        var (status, body) = await execSpService.ExecuteAsync(request, User, ct);
        return StatusCode(status, body);
    }
}
```

- [ ] **Step 4: Manuel smoke test**

Run API, then:

```powershell
curl -X POST http://localhost:5000/api/auth/exec -H "Content-Type: application/json" -d "{\"sp\":\"Evil.Drop\",\"params\":{}}"
```

Expected: `403` — `SP not allowed`

---

### Task 8: SQL Auth stored procedure'leri

**Files:**
- Create: `sql/API_Auth_Register.sql`
- Create: `sql/API_Auth_Login.sql`
- Create: `sql/API_Auth_RefreshToken.sql`
- Create: `sql/API_Auth_GetProfile.sql`
- Create: `sql/API_Auth_DeleteAccount.sql`

**Interfaces:**
- Produces: SP'ler `Email`, `Password`, `UserId` parametreleri ile çalışır; `API_Auth_Login` satır döner: `UserId`, `Email`, `TenantId`, `Status`

- [ ] **Step 1: API_Auth_Register**

Create `sql/API_Auth_Register.sql`:

```sql
CREATE OR ALTER PROCEDURE dbo.API_Auth_Register
    @Email NVARCHAR(256),
    @Password NVARCHAR(256),
    @AcceptedTerms BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @AcceptedTerms <> 1
    BEGIN
        RAISERROR('Terms must be accepted.', 16, 1);
        RETURN;
    END
    -- TODO-ADAPT: Replace Users table/columns with existing schema
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
    BEGIN
        RAISERROR('Email already registered.', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.Users (Email, PasswordHash, Status, CreatedAt)
    VALUES (@Email, HASHBYTES('SHA2_256', @Password), 'Pending', SYSUTCDATETIME());

    SELECT SCOPE_IDENTITY() AS UserId, @Email AS Email, 'Pending' AS Status;
END
```

- [ ] **Step 2: API_Auth_Login**

Create `sql/API_Auth_Login.sql`:

```sql
CREATE OR ALTER PROCEDURE dbo.API_Auth_Login
    @Email NVARCHAR(256),
    @Password NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Match existing password hash method
    SELECT u.UserId, u.Email, u.TenantId, u.Status
    FROM dbo.Users u
    WHERE u.Email = @Email
      AND u.PasswordHash = HASHBYTES('SHA2_256', @Password)
      AND u.Status <> 'Rejected';
END
```

- [ ] **Step 3: Kalan auth SP'leri**

`API_Auth_GetProfile.sql` — `@UserId` alır, profil döner.
`API_Auth_DeleteAccount.sql` — `@UserId` alır, soft-delete veya hard-delete.
`API_Auth_RefreshToken.sql` — `@RefreshToken` alır; refresh token tablosu TODO-ADAPT.

- [ ] **Step 4: SQL script'leri SSMS'te çalıştır ve login test et**

Expected: `API_Auth_Login` test kullanıcısı satır döner.

---

### Task 9: SQL iş SP'leri (ürün, lookup, satış)

**Files:**
- Create: `sql/API_Product_GetByBarcode.sql`
- Create: `sql/API_Lookup_Customers.sql`
- Create: `sql/API_Lookup_PaymentTypes.sql`
- Create: `sql/API_Sale_Create.sql`
- Create: `sql/API_Membership_ListPending.sql`
- Create: `sql/API_Membership_Approve.sql`
- Create: `sql/API_Membership_Reject.sql`

**Interfaces:**
- `API_Product_GetByBarcode` → `@TenantId INT, @Barcode NVARCHAR(50)` → `ProductId, Name, Barcode, UnitPrice, StockQty`
- `API_Sale_Create` → `@TenantId, @UserId, @CustomerId, @PaymentTypeId, @Lines NVARCHAR(MAX), @Note` → `SaleId, SaleNo, TotalAmount`

- [ ] **Step 1: API_Product_GetByBarcode**

```sql
CREATE OR ALTER PROCEDURE dbo.API_Product_GetByBarcode
    @TenantId INT,
    @Barcode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Products table
    SELECT p.ProductId, p.Name, p.Barcode, p.UnitPrice, p.StockQty
    FROM dbo.Products p
    WHERE p.TenantId = @TenantId AND p.Barcode = @Barcode;
END
```

- [ ] **Step 2: Lookup SP'leri**

`API_Lookup_Customers` — `@TenantId`, opsiyonel `@Search`; `CustomerId, Name` döner.
`API_Lookup_PaymentTypes` — `@TenantId`; `PaymentTypeId, Name` döner.

- [ ] **Step 3: API_Sale_Create**

```sql
CREATE OR ALTER PROCEDURE dbo.API_Sale_Create
    @TenantId INT,
    @UserId INT,
    @CustomerId INT = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX),
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    -- TODO-ADAPT: Parse @Lines JSON, insert Sales + SaleLines, decrement stock
    -- RETURN SaleId, SaleNo, TotalAmount
    COMMIT TRANSACTION;
END
```

- [ ] **Step 4: Membership SP'leri (masaüstü)**

`API_Membership_ListPending`, `API_Membership_Approve` (`@UserId`, `@TenantId`), `API_Membership_Reject` (`@UserId`, `@Reason`).

---

### Task 10: Flutter proje iskeleti

**Files:**
- Create: `mobile/` (flutter create)
- Modify: `mobile/pubspec.yaml`

**Interfaces:**
- Produces: Çalışan `flutter run` ile boş uygulama

- [ ] **Step 1: Flutter projesi oluştur**

```powershell
cd c:\Users\KasimGulcan\Desktop\CSM.Stok
flutter create mobile --org com.csmstok --project-name csm_stok_mobile
```

- [ ] **Step 2: Bağımlılıkları ekle**

`mobile/pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  dio: ^5.7.0
  go_router: ^14.6.2
  mobile_scanner: ^6.0.2
  flutter_secure_storage: ^9.2.2
  connectivity_plus: ^6.1.0
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.2
```

Run: `cd mobile && flutter pub get`
Expected: Got dependencies

- [ ] **Step 3: Çalıştır**

Run: `flutter run -d windows` (veya emulator)
Expected: Default counter app açılır

---

### Task 11: Flutter SpClient ve auth altyapısı

**Files:**
- Create: `mobile/lib/core/config/api_config.dart`
- Create: `mobile/lib/core/network/sp_client.dart`
- Create: `mobile/lib/core/network/auth_interceptor.dart`
- Create: `mobile/lib/core/storage/token_storage.dart`
- Create: `mobile/lib/core/models/exec_sp_response.dart`
- Create: `mobile/test/core/sp_client_test.dart`

**Interfaces:**
- Produces: `SpClient.exec(String sp, Map<String, dynamic>? params, {bool auth = true})` → `Future<ExecSpResponse>`
- Produces: `TokenStorage.saveTokens(access, refresh)` / `getAccessToken()` / `clear()`

- [ ] **Step 1: Failing test**

Create `mobile/test/core/sp_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:csm_stok_mobile/core/models/exec_sp_response.dart';

void main() {
  test('ExecSpResponse fromJson success', () {
    final r = ExecSpResponse.fromJson({'success': true, 'data': [], 'error': null});
    expect(r.success, isTrue);
  });
}
```

Run: `flutter test test/core/sp_client_test.dart`
Expected: FAIL

- [ ] **Step 2: ExecSpResponse model**

Create `mobile/lib/core/models/exec_sp_response.dart`:

```dart
class ExecSpResponse {
  final bool success;
  final dynamic data;
  final String? error;

  ExecSpResponse({required this.success, this.data, this.error});

  factory ExecSpResponse.fromJson(Map<String, dynamic> json) => ExecSpResponse(
        success: json['success'] as bool,
        data: json['data'],
        error: json['error'] as String?,
      );
}
```

- [ ] **Step 3: SpClient**

Create `mobile/lib/core/network/sp_client.dart`:

```dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/exec_sp_response.dart';

class SpClient {
  SpClient(this._dio);
  final Dio _dio;

  Future<ExecSpResponse> exec(
    String sp,
    Map<String, dynamic>? params, {
    bool auth = true,
  }) async {
    final path = auth ? '/api/exec' : '/api/auth/exec';
    final response = await _dio.post(path, data: {'sp': sp, 'params': params});
    return ExecSpResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
```

Create `mobile/lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localhost:5001',
  );
}
```

- [ ] **Step 4: Test pass**

Run: `flutter test test/core/sp_client_test.dart`
Expected: PASS

---

### Task 12: Flutter auth ekranları

**Files:**
- Create: `mobile/lib/features/auth/login_screen.dart`
- Create: `mobile/lib/features/auth/register_screen.dart`
- Create: `mobile/lib/features/auth/auth_provider.dart`
- Create: `mobile/lib/app_router.dart`
- Modify: `mobile/lib/main.dart`

**Interfaces:**
- Consumes: `SpClient.exec('Auth.Login', {'Email': e, 'Password': p}, auth: false)`
- Consumes: `SpClient.exec('Auth.Register', {...}, auth: false)`
- Produces: Login başarılı → token kaydet → `/home` yönlendir

- [ ] **Step 1: Auth provider (Riverpod)**

`auth_provider.dart` — login/register fonksiyonları, token storage entegrasyonu.

- [ ] **Step 2: Login ekranı**

Email, password TextField; Giriş butonu; Kayıt ol linki; hata mesajı gösterimi.

- [ ] **Step 3: Register ekranı**

Email, password, kullanım şartları Checkbox; Kayıt ol butonu.

- [ ] **Step 4: go_router yapılandırması**

Routes: `/`, `/login`, `/register`, `/home` (auth guard ile).

- [ ] **Step 5: Widget test**

Create `mobile/test/features/auth/login_screen_test.dart` — form alanları render edilir.

Run: `flutter test test/features/auth/`
Expected: PASS

---

### Task 13: Flutter satış akışı (barkod → sepet → ödeme)

**Files:**
- Create: `mobile/lib/features/sale/scanner_screen.dart`
- Create: `mobile/lib/features/sale/cart_screen.dart`
- Create: `mobile/lib/features/sale/checkout_screen.dart`
- Create: `mobile/lib/features/sale/sale_summary_screen.dart`
- Create: `mobile/lib/features/sale/cart_provider.dart`
- Create: `mobile/lib/features/sale/models/cart_line.dart`
- Create: `mobile/lib/features/sale/models/product.dart`

**Interfaces:**
- Consumes: `SpClient.exec('Product.GetByBarcode', {'Barcode': code})`
- Consumes: `SpClient.exec('Lookup.Customers', {'Search': q})`
- Consumes: `SpClient.exec('Lookup.PaymentTypes', {})`
- Consumes: `SpClient.exec('Sale.Create', {'CustomerId': id, 'PaymentTypeId': pt, 'Lines': lines, 'Note': note})`
- Produces: `CartNotifier` — `addLine`, `removeLine`, `updateQuantity`, `clear`

- [ ] **Step 1: Product ve CartLine modelleri**

```dart
class Product {
  final int productId;
  final String name;
  final String barcode;
  final double unitPrice;
  final double stockQty;
  // fromJson constructor
}

class CartLine {
  final Product product;
  int quantity;
  double unitPrice;
  double get lineTotal => quantity * unitPrice;
}
```

- [ ] **Step 2: Scanner ekranı**

`mobile_scanner` ile barkod okuma; okunan kod → API sorgusu → ürün bulunamazsa snackbar.

- [ ] **Step 3: Sepet ekranı**

Satır listesi, adet düzenleme, toplam tutar, "Ödemeye Geç" butonu.

- [ ] **Step 4: Checkout ekranı**

Opsiyonel müşteri Dropdown (API_Lookup_Customers), ödeme tipi Dropdown (API_Lookup_PaymentTypes), not alanı, "Satışı Tamamla".

- [ ] **Step 5: Satış özeti ekranı**

SaleId, SaleNo, TotalAmount göster; yeni satış butonu.

- [ ] **Step 6: Cart provider test**

```dart
test('addLine increases cart total', () { ... });
```

Run: `flutter test test/features/sale/`
Expected: PASS

---

### Task 14: Mağaza uyumu ve bağlantı kontrolü

**Files:**
- Create: `mobile/lib/features/auth/profile_screen.dart`
- Create: `mobile/lib/core/network/connectivity_guard.dart`
- Create: `mobile/lib/features/auth/privacy_policy_screen.dart`

**Interfaces:**
- Consumes: `SpClient.exec('Auth.DeleteAccount', {})`
- Consumes: `SpClient.exec('Auth.GetProfile', {})`
- Produces: Bağlantı yoksa global banner "İnternet bağlantısı gerekli"

- [ ] **Step 1: Connectivity guard**

`connectivity_plus` ile stream dinle; bağlantı yoksa `ConnectivityBanner` widget göster.

- [ ] **Step 2: Profil ekranı**

Kullanıcı bilgisi, gizlilik politikası linki, hesap silme butonu (onay dialog ile).

- [ ] **Step 3: Hesap silme akışı**

Dialog onayı → `Auth.DeleteAccount` → token temizle → login'e yönlendir.

- [ ] **Step 4: Kamera izni metinleri**

`mobile/ios/Runner/Info.plist` — `NSCameraUsageDescription`
`mobile/android/app/src/main/AndroidManifest.xml` — `CAMERA` permission

---

### Task 15: IIS deployment yapılandırması

**Files:**
- Create: `api/CsmStok.Api/web.config`
- Create: `docs/deploy-iis.md`

**Interfaces:**
- Produces: `dotnet publish` çıktısı IIS'te çalışır

- [ ] **Step 1: Publish profili**

```powershell
cd api/CsmStok.Api
dotnet publish -c Release -o ./publish
```

- [ ] **Step 2: web.config**

IIS ASP.NET Core Module v2 yapılandırması; `stdoutLogEnabled`, `processPath="dotnet"`.

- [ ] **Step 3: deploy-iis.md**

HTTPS binding, app pool (.NET CLR = No Managed Code), connection string production, JWT signing key rotation notları.

---

## Spec Coverage Self-Review

| Spec bölümü | Task |
|---|---|
| Generic ExecSP + whitelist | Task 4, 7 |
| `API_*` SP isimlendirme | Task 8, 9 |
| JWT auth + refresh | Task 6, 8 |
| Multi-tenant injection | Task 7 (ExecSpService) |
| RequireApproval config | Task 7 |
| Flutter Riverpod/Dio/go_router/mobile_scanner | Task 10–14 |
| Sepet satış akışı | Task 13 |
| Mağaza uyumu (kayıt, silme, gizlilik) | Task 12, 14 |
| Çevrimdışı yok | Task 14 (connectivity guard) |
| Membership onay (masaüstü) | Task 9 (SP scripts only) |
| IIS deploy | Task 15 |
| v1 dışı (satış geçmişi, push, pinning) | Bilinçli olarak task yok |

Placeholder scan: `TODO-ADAPT` yalnızca SQL script'lerde mevcut şema adaptasyonu için; implementasyon detayı değil, bilinçli entegrasyon noktası.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-29-csm-stok-mobile.md`. Two execution options:

**1. Subagent-Driven (recommended)** — Her task için ayrı subagent; task'lar arası review, hızlı iterasyon

**2. Inline Execution** — Bu oturumda `executing-plans` skill ile batch çalışma, checkpoint'lerde review

Which approach?
