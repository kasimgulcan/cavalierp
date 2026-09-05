# E-ticaret ürün kataloğu snapshot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Site HMAC ile `GET /integrations/ecommerce/products/snapshot` çekerek `GetSKUSnapshot` üç sonuç kümesini JSON olarak alır; stok snapshot sözleşmesi değişmez.

**Architecture:** Yeni controller + repository `EXEC GetSKUSnapshot` çalıştırır. Üç result set `skus` / `styleModels` / `models` olur; satır key’leri SQL kolon adıdır. Mevcut HMAC middleware `/integrations/ecommerce` altını korur. Stok controller, stock SP ve outbound worker dokunulmaz.

**Tech Stack:** ASP.NET Core, Microsoft.Data.SqlClient, SQL Server, xUnit, `/tester/` HTML.

## Global Constraints

- Stok path’leri ve `docs/ecommerce-stock-webhook.md` stok maddeleri kilitli; yalnızca tek cümlelik katalog linki eklenir
- Kapı: `GET /integrations/ecommerce/products/snapshot`
- SP adı: `GetSKUSnapshot` (`GetSKU` / `GetSKU_ModelReference` değiştirilmez)
- HMAC canonical: `{timestamp}.GET./integrations/ecommerce/products/snapshot`
- Ayrı Enabled bayrağı yok; `EcommerceSync:Enabled` (appsettings `true`)
- Dış sarmalayıcı camelCase; satır anahtarları SQL birebir
- Result set sayısı ≠ 3 → 500, yarım gövde yok
- Hata gövdesi: `{ "success": false, "error": "Unable to load product catalog." }`
- CommandTimeout 120 saniye
- Secrets commit edilmez
- Namespace: API `CsmStok.Api.*`, test `CsmStok.Api.Tests`

## File map

| File | Responsibility |
|---|---|
| `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogMapper.cs` | 3 küme doğrula; `IDataRecord` → dictionary |
| `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs` | `EXEC GetSKUSnapshot` |
| `api/CavaliERP.API/Controllers/EcommerceProductCatalogController.cs` | GET snapshot JSON |
| `api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs` | Mapper + controller |
| `api/CavaliERP.API.TESTS/EcommerceHmacTests.cs` | Yeni path canonical |
| `api/CavaliERP.API.TESTS/EcommerceShopSimulatorTests.cs` | Tester HMAC GET |
| `api/CavaliERP.API/Services/Ecommerce/EcommerceShopSimulator.cs` | `ProductCatalogPath` |
| `api/CavaliERP.API/Controllers/EcommerceTesterController.cs` | `POST tester/api/product-catalog` |
| `api/CavaliERP.API/wwwroot/tester/index.html` | Yeni katalog kartı |
| `api/CavaliERP.API/Program.cs` | DI + tester HttpClient 120s |
| `sql/Migrate_EcommerceProductCatalog.sql` | `CREATE OR ALTER GetSKUSnapshot` |
| `docs/ecommerce-product-catalog.md` | Karşı taraf sözleşmesi |
| `docs/ecommerce-stock-webhook.md` | Tek cümle + link |

Do **not** modify: `EcommerceStockController.cs`, `EcommerceStockRepository.cs`, `API_WebHook_StockSnapshot`, HMAC canonical helpers (only add a test).

---

### Task 1: Catalog mapper

**Files:**
- Create: `api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs`
- Create: `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogMapper.cs`

**Interfaces:**
- Consumes: nothing
- Produces: `EcommerceProductCatalogMapper.FromResultSets`, `ReadRow`; `EcommerceProductCatalogSnapshot` with `Skus`, `StyleModels`, `Models` as `IReadOnlyList<IReadOnlyDictionary<string, object?>>`

- [ ] **Step 1: Write the failing tests**

Create `api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs`:

```csharp
using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using CsmStok.Api.Controllers;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;

namespace CsmStok.Api.Tests;

public class EcommerceProductCatalogTests
{
    [Fact]
    public void FromResultSets_MapsThreeSets_PreservesSqlColumnNames()
    {
        var barcodeKey = "BARCODE GS1/EAN ";
        var skus = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?>
            {
                ["SKU CODE"] = "H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB",
                ["STYLE NAME"] = "TORONTO",
                [barcodeKey] = "8683711000211",
                ["SKU ID"] = 5,
            },
        };
        var styleModels = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?> { ["STYLE NAME"] = "ALASKA" },
        };
        var models = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?> { ["MODEL NAME"] = "ALISA KAPTAN" },
        };

        var snapshot = EcommerceProductCatalogMapper.FromResultSets([skus, styleModels, models]);

        Assert.Equal("TORONTO", snapshot.Skus[0]["STYLE NAME"]);
        Assert.Equal("H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB", snapshot.Skus[0]["SKU CODE"]);
        Assert.Equal("8683711000211", snapshot.Skus[0][barcodeKey]);
        Assert.Equal("ALASKA", snapshot.StyleModels[0]["STYLE NAME"]);
        Assert.Equal("ALISA KAPTAN", snapshot.Models[0]["MODEL NAME"]);
    }

    [Fact]
    public void FromResultSets_EmptySets_AreAllowed()
    {
        var empty = new List<IReadOnlyDictionary<string, object?>>();
        var snapshot = EcommerceProductCatalogMapper.FromResultSets([empty, empty, empty]);
        Assert.Empty(snapshot.Skus);
        Assert.Empty(snapshot.StyleModels);
        Assert.Empty(snapshot.Models);
    }

    [Fact]
    public void FromResultSets_NotThreeSets_Throws()
    {
        var empty = new List<IReadOnlyDictionary<string, object?>>();
        var ex = Assert.Throws<InvalidOperationException>(
            () => EcommerceProductCatalogMapper.FromResultSets([empty, empty]));
        Assert.Equal("GetSKUSnapshot must return 3 result sets.", ex.Message);
    }

    [Fact]
    public void ReadRow_PreservesColumnNameWithTrailingSpace_AndNulls()
    {
        var table = new DataTable();
        table.Columns.Add("SKU CODE", typeof(string));
        table.Columns.Add("BARCODE GS1/EAN ", typeof(string));
        table.Columns.Add("SKU ID", typeof(int));
        var row = table.NewRow();
        row["SKU CODE"] = "ABC";
        row["BARCODE GS1/EAN "] = DBNull.Value;
        row["SKU ID"] = 9;
        table.Rows.Add(row);

        using var reader = table.CreateDataReader();
        Assert.True(reader.Read());
        var mapped = EcommerceProductCatalogMapper.ReadRow(reader);

        Assert.Equal("ABC", mapped["SKU CODE"]);
        Assert.Null(mapped["BARCODE GS1/EAN "]);
        Assert.Equal(9, mapped["SKU ID"]);
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~EcommerceProductCatalogTests"
```

Expected: FAIL — `EcommerceProductCatalogMapper` does not exist.

- [ ] **Step 3: Write the mapper**

Create `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogMapper.cs`:

```csharp
using System.Data;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceProductCatalogSnapshot
{
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> Skus { get; init; }
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> StyleModels { get; init; }
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> Models { get; init; }
}

public static class EcommerceProductCatalogMapper
{
    public const string WrongResultSetCountMessage = "GetSKUSnapshot must return 3 result sets.";

    public static EcommerceProductCatalogSnapshot FromResultSets(
        IReadOnlyList<IReadOnlyList<IReadOnlyDictionary<string, object?>>> sets)
    {
        if (sets.Count != 3)
            throw new InvalidOperationException(WrongResultSetCountMessage);

        return new EcommerceProductCatalogSnapshot
        {
            Skus = sets[0],
            StyleModels = sets[1],
            Models = sets[2],
        };
    }

    public static Dictionary<string, object?> ReadRow(IDataRecord record)
    {
        var row = new Dictionary<string, object?>(record.FieldCount, StringComparer.Ordinal);
        for (var i = 0; i < record.FieldCount; i++)
        {
            var value = record.GetValue(i);
            row[record.GetName(i)] = value is DBNull ? null : value;
        }

        return row;
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run the same `dotnet test` filter.

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```powershell
git add api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogMapper.cs
git commit -m "feat: map GetSKUSnapshot result sets with SQL column names"
```

---

### Task 2: HMAC path + catalog controller

**Files:**
- Modify: `api/CavaliERP.API.TESTS/EcommerceHmacTests.cs` (add one Fact after `CanonicalGet_UsesMethodAndNormalizedPath`)
- Modify: `api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs` (add controller tests)
- Create: `api/CavaliERP.API/Controllers/EcommerceProductCatalogController.cs`

**Interfaces:**
- Consumes: `EcommerceProductCatalogSnapshot`; `IEcommerceProductCatalogRepository.GetSnapshotAsync(CancellationToken)`
- Produces: `GET /integrations/ecommerce/products/snapshot` → `{ generatedAt, source: "cavalierp", skus, styleModels, models }`; SQL/mapper errors → 500 with fixed error string

- [ ] **Step 1: Write the failing HMAC test**

In `api/CavaliERP.API.TESTS/EcommerceHmacTests.cs`, after `CanonicalGet_UsesMethodAndNormalizedPath`, add:

```csharp
    [Fact]
    public void CanonicalGet_ProductCatalogSnapshotPath()
    {
        var canonical = EcommerceHmac.CanonicalGet("1700000000", "/integrations/ecommerce/products/snapshot/");
        Assert.Equal("1700000000.GET./integrations/ecommerce/products/snapshot", canonical);
    }
```

- [ ] **Step 2: Run HMAC test — this one should already pass**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~CanonicalGet_ProductCatalogSnapshotPath"
```

Expected: PASS (`NormalizePath` already strips trailing slash). This locks the contract path. Do not change `EcommerceHmac.cs`.

- [ ] **Step 3: Write failing controller tests**

Append to `EcommerceProductCatalogTests.cs` (same class):

```csharp
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    [Fact]
    public async Task Snapshot_ReturnsWrapperAndSqlKeys()
    {
        var repo = new StubCatalogRepository(EcommerceProductCatalogMapper.FromResultSets(
        [
            [new Dictionary<string, object?> { ["SKU CODE"] = "SKU1", ["STYLE NAME"] = "TORONTO" }],
            [new Dictionary<string, object?> { ["STYLE NAME"] = "ALASKA" }],
            [new Dictionary<string, object?> { ["MODEL NAME"] = "ALISA KAPTAN" }],
        ]));
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        var result = await controller.Snapshot(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(StatusCodes.Status200OK, ok.StatusCode ?? 200);
        var json = JsonSerializer.Serialize(ok.Value, JsonOptions);
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        Assert.Equal("cavalierp", root.GetProperty("source").GetString());
        Assert.True(root.TryGetProperty("generatedAt", out _));
        Assert.Equal("SKU1", root.GetProperty("skus")[0].GetProperty("SKU CODE").GetString());
        Assert.Equal("TORONTO", root.GetProperty("skus")[0].GetProperty("STYLE NAME").GetString());
        Assert.Equal("ALASKA", root.GetProperty("styleModels")[0].GetProperty("STYLE NAME").GetString());
        Assert.Equal("ALISA KAPTAN", root.GetProperty("models")[0].GetProperty("MODEL NAME").GetString());
    }

    [Fact]
    public async Task Snapshot_WhenRepositoryThrows_Returns500WithoutSqlText()
    {
        var repo = new ThrowingCatalogRepository(new InvalidOperationException("GetSKUSnapshot must return 3 result sets."));
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        var result = await controller.Snapshot(CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status500InternalServerError, obj.StatusCode);
        var json = JsonSerializer.Serialize(obj.Value, JsonOptions);
        Assert.Contains("Unable to load product catalog.", json);
        Assert.DoesNotContain("GetSKUSnapshot must return 3 result sets.", json);
    }

    private sealed class StubCatalogRepository(EcommerceProductCatalogSnapshot snapshot) : IEcommerceProductCatalogRepository
    {
        public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken) =>
            Task.FromResult(snapshot);
    }

    private sealed class ThrowingCatalogRepository(Exception exception) : IEcommerceProductCatalogRepository
    {
        public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken) =>
            Task.FromException<EcommerceProductCatalogSnapshot>(exception);
    }
```

- [ ] **Step 4: Run controller tests to verify they fail**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~EcommerceProductCatalogTests.Snapshot"
```

Expected: FAIL — `EcommerceProductCatalogController` / `IEcommerceProductCatalogRepository` missing.

- [ ] **Step 5: Write the interface and controller**

Add to `EcommerceProductCatalogMapper.cs` (same file, below the mapper) **or** keep interface in the repository file created in this step. Create the interface in `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs` (implementation body in Task 3; interface now):

```csharp
namespace CsmStok.Api.Services.Ecommerce;

public interface IEcommerceProductCatalogRepository
{
    Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken);
}

public sealed class EcommerceProductCatalogRepository(IConfiguration configuration) : IEcommerceProductCatalogRepository
{
    public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken) =>
        throw new NotImplementedException();
}
```

Create `api/CavaliERP.API/Controllers/EcommerceProductCatalogController.cs`:

```csharp
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("integrations/ecommerce/products")]
public sealed class EcommerceProductCatalogController(
    IEcommerceProductCatalogRepository repository,
    ILogger<EcommerceProductCatalogController> logger) : ControllerBase
{
    [HttpGet("snapshot")]
    public async Task<IActionResult> Snapshot(CancellationToken ct)
    {
        try
        {
            var snapshot = await repository.GetSnapshotAsync(ct);
            return Ok(new
            {
                generatedAt = DateTimeOffset.UtcNow,
                source = "cavalierp",
                skus = snapshot.Skus,
                styleModels = snapshot.StyleModels,
                models = snapshot.Models,
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unable to load product catalog.");
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                success = false,
                error = "Unable to load product catalog.",
            });
        }
    }
}
```

- [ ] **Step 6: Run catalog + HMAC tests**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~EcommerceProductCatalogTests|FullyQualifiedName~CanonicalGet_ProductCatalogSnapshotPath"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add api/CavaliERP.API.TESTS/EcommerceHmacTests.cs api/CavaliERP.API.TESTS/EcommerceProductCatalogTests.cs api/CavaliERP.API/Controllers/EcommerceProductCatalogController.cs api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs
git commit -m "feat: add HMAC product catalog snapshot endpoint"
```

---

### Task 3: SQL migrate, repository, DI

**Files:**
- Create: `sql/Migrate_EcommerceProductCatalog.sql`
- Modify: `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs` (replace `NotImplementedException`)
- Modify: `api/CavaliERP.API/Program.cs` (register repository)

**Interfaces:**
- Consumes: `EcommerceProductCatalogMapper.ReadRow`, `FromResultSets`; connection string `Default`
- Produces: live `EXEC GetSKUSnapshot` with `CommandTimeout = 120`; exactly the result sets the SP returns

- [ ] **Step 1: Write the migrate script**

Create `sql/Migrate_EcommerceProductCatalog.sql`:

```sql
-- Ecommerce product catalog snapshot (05.09.2026)
-- Wrapper: GetSKU + GetSKU_ModelReference (üç result set).

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.GetSKUSnapshot
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.GetSKU;
    EXEC dbo.GetSKU_ModelReference;
END
GO
```

Do not alter `GetSKU` or `GetSKU_ModelReference`. Do not touch `API_WebHook_StockSnapshot`.

- [ ] **Step 2: Implement the repository**

Replace `EcommerceProductCatalogRepository` in `api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs` with:

```csharp
using System.Data;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services.Ecommerce;

public interface IEcommerceProductCatalogRepository
{
    Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken);
}

public sealed class EcommerceProductCatalogRepository(IConfiguration configuration) : IEcommerceProductCatalogRepository
{
    private string ConnectionString => configuration.GetConnectionString("Default")
        ?? throw new InvalidOperationException("Connection string missing.");

    public async Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand("GetSKUSnapshot", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 120,
        };

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var sets = new List<IReadOnlyList<IReadOnlyDictionary<string, object?>>>();
        do
        {
            var rows = new List<IReadOnlyDictionary<string, object?>>();
            while (await reader.ReadAsync(cancellationToken))
                rows.Add(EcommerceProductCatalogMapper.ReadRow(reader));
            sets.Add(rows);
        }
        while (await reader.NextResultAsync(cancellationToken));

        return EcommerceProductCatalogMapper.FromResultSets(sets);
    }
}
```

- [ ] **Step 3: Register DI**

In `api/CavaliERP.API/Program.cs`, immediately after:

```csharp
builder.Services.AddSingleton<IEcommerceStockRepository, EcommerceStockRepository>();
```

add:

```csharp
builder.Services.AddSingleton<IEcommerceProductCatalogRepository, EcommerceProductCatalogRepository>();
```

Do not change stock registrations, HMAC middleware, or `UseWhen` path prefix (already `/integrations/ecommerce`).

- [ ] **Step 4: Run unit tests (no live DB required)**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~Ecommerce"
```

Expected: PASS. Stock tests still pass. `GetSnapshotAsync` on the real repository is not unit-tested against SQL.

- [ ] **Step 5: Commit**

```powershell
git add sql/Migrate_EcommerceProductCatalog.sql api/CavaliERP.API/Services/Ecommerce/EcommerceProductCatalogRepository.cs api/CavaliERP.API/Program.cs
git commit -m "feat: load product catalog from GetSKUSnapshot"
```

SSMS: run `sql/Migrate_EcommerceProductCatalog.sql` on `CavaliERP` if the live proc differs. Live DB already has this wrapper; script is the repo source of truth.

---

### Task 4: Tester HMAC GET

**Files:**
- Modify: `api/CavaliERP.API.TESTS/EcommerceShopSimulatorTests.cs`
- Modify: `api/CavaliERP.API/Services/Ecommerce/EcommerceShopSimulator.cs`
- Modify: `api/CavaliERP.API/Controllers/EcommerceTesterController.cs`
- Modify: `api/CavaliERP.API/wwwroot/tester/index.html`
- Modify: `api/CavaliERP.API/Program.cs` (ShopSimulator timeout 120s)

**Interfaces:**
- Consumes: `EcommerceShopSimulator.ProductCatalogPath = "/integrations/ecommerce/products/snapshot"`
- Produces: `GetProductCatalogAsync`; tester `POST /tester/api/product-catalog` proxies signed GET; UI action `product-catalog`

- [ ] **Step 1: Write the failing simulator test**

In `EcommerceShopSimulatorTests.cs`, after `GetSnapshot_SendsSignedGet`, add:

```csharp
    [Fact]
    public async Task GetProductCatalog_SendsSignedGet()
    {
        var handler = new CaptureHandler("""{"generatedAt":"2026-09-05T00:00:00Z","source":"cavalierp","skus":[],"styleModels":[],"models":[]}""");
        var simulator = Create(handler);

        var result = await simulator.GetProductCatalogAsync(BaseUrl);

        Assert.Equal(200, result.StatusCode);
        Assert.Equal(HttpMethod.Get, handler.Method);
        Assert.Equal("http://localhost:5160/integrations/ecommerce/products/snapshot", handler.Url);
        AssertSigned(handler, EcommerceHmac.CanonicalGet(handler.Timestamp, "/integrations/ecommerce/products/snapshot"));
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~GetProductCatalog_SendsSignedGet"
```

Expected: FAIL — `GetProductCatalogAsync` missing.

- [ ] **Step 3: Implement simulator method**

In `EcommerceShopSimulator.cs`, next to `SnapshotPath`, add:

```csharp
    public const string ProductCatalogPath = "/integrations/ecommerce/products/snapshot";
```

Next to `GetSnapshotAsync`, add:

```csharp
    public Task<ShopCallResult> GetProductCatalogAsync(string apiBaseUrl, CancellationToken ct = default) =>
        SendAsync(HttpMethod.Get, Combine(apiBaseUrl, ProductCatalogPath), body: null, canonicalPath: ProductCatalogPath, ct);
```

Do not change `SnapshotPath` or `GetSnapshotAsync`.

- [ ] **Step 4: Tester API + timeout**

In `Program.cs`, change the existing ShopSimulator client from 30s to 120s:

```csharp
builder.Services.AddHttpClient<EcommerceShopSimulator>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(120);
});
```

In `EcommerceTesterController.cs`, after `Snapshot`, add:

```csharp
    [HttpPost("api/product-catalog")]
    public async Task<IActionResult> ProductCatalog(CancellationToken ct)
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        var result = await shop.GetProductCatalogAsync(ApiBase(), ct);
        return Proxy(result);
    }
```

- [ ] **Step 5: Tester UI card**

In `api/CavaliERP.API/wwwroot/tester/index.html`:

1. After the “Bizim stok (site)” `</section>` (before “Site stok (reklam5)”), insert a new card. Do not change stock buttons, apply form, or partner snapshot table.

```html
    <section class="card">
      <h2>Ürün kataloğu</h2>
      <p class="hint">HMAC GET <code>/integrations/ecommerce/products/snapshot</code> — stok snapshot’ına dokunmaz.</p>
      <div class="row">
        <button type="button" class="gold" id="btnProductCatalog">Ürün kataloğu çek</button>
      </div>
      <div class="status" id="catalogStatus"></div>
    </section>
```

2. In the script, after `partnerSnapshot()`, add:

```javascript
    async function productCatalog() {
      setBusy(true);
      const catalogStatusEl = document.getElementById("catalogStatus");
      catalogStatusEl.textContent = "Ürün kataloğu alınıyor…";
      try {
        const res = await post("api/product-catalog");
        const parsed = tryParse(res.text);
        recordTraffic({ at: new Date().toISOString(), action: "product-catalog", request: { url: "api/product-catalog" }, status: res.status, response: parsed });
        log("PRODUCT CATALOG HTTP " + res.status, res.pretty);
        if (res.status >= 200 && res.status < 300 && parsed && Array.isArray(parsed.skus)) {
          const sample = parsed.skus[0] ? (parsed.skus[0]["SKU CODE"] || parsed.skus[0]["STYLE NAME"] || "") : "";
          catalogStatusEl.innerHTML = '<span class="ok">' + parsed.skus.length + " SKU" + (sample ? " · " + sample : "") + "</span>";
        } else {
          catalogStatusEl.innerHTML = '<span class="bad">HTTP ' + res.status + "</span>";
        }
      } catch (err) {
        log("PRODUCT CATALOG HATA", String(err));
        catalogStatusEl.innerHTML = '<span class="bad">Bağlantı hatası</span>';
      } finally {
        setBusy(false);
      }
    }
```

3. Next to `btnSnapshot` listener, add:

```javascript
    document.getElementById("btnProductCatalog").addEventListener("click", productCatalog);
```

Leave `btnSnapshot` / stock `snapshot()` unchanged.

- [ ] **Step 6: Run tester-related tests**

Run:

```powershell
dotnet test "api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj" --filter "FullyQualifiedName~EcommerceShopSimulatorTests|FullyQualifiedName~EcommerceProductCatalogTests|FullyQualifiedName~EcommerceSnapshotTests"
```

Expected: PASS. `EcommerceSnapshotTests` still only cares about `skuCode` + `quantity`.

- [ ] **Step 7: Commit**

```powershell
git add api/CavaliERP.API.TESTS/EcommerceShopSimulatorTests.cs api/CavaliERP.API/Services/Ecommerce/EcommerceShopSimulator.cs api/CavaliERP.API/Controllers/EcommerceTesterController.cs api/CavaliERP.API/wwwroot/tester/index.html api/CavaliERP.API/Program.cs
git commit -m "feat: add tester pull for product catalog snapshot"
```

---

### Task 5: Partner contract docs

**Files:**
- Create: `docs/ecommerce-product-catalog.md`
- Modify: `docs/ecommerce-stock-webhook.md` (line 3 only)

**Interfaces:**
- Consumes: spec `docs/superpowers/specs/2026-09-05-ecommerce-product-catalog-design.md`
- Produces: reklam5-facing catalog contract; stock doc points at it

- [ ] **Step 1: Write `docs/ecommerce-product-catalog.md`**

```markdown
# CavaliERP — E-ticaret ürün kataloğu

Karşı tarafa verilecek sözleşme. Site kataloğu **çeker**; CavaliERP ürün create/update kabul etmez.

Stok kanalı ayrı ve kilitlidir: `docs/ecommerce-stock-webhook.md`.

## Endpoint

Production taban: `https://app.devcloud.com.tr/cavalierp/api`

| Method | Path |
|---|---|
| `GET` | `/integrations/ecommerce/products/snapshot` |

Örnek: `https://app.devcloud.com.tr/cavalierp/api/integrations/ecommerce/products/snapshot`

Mobil JWT yok. `EcommerceSync:Enabled: false` → 404 (tüm `/integrations/ecommerce`).

## HMAC

Stok GET ile aynı secret ve header’lar:

- `X-CavaliERP-Timestamp` — Unix saniye UTC
- `X-CavaliERP-Signature` — `sha256=<hex>`
- Canonical: `{timestamp}.GET./integrations/ecommerce/products/snapshot` (IIS öneki imzada yok)
- ±5 dk skew

## Cevap

```json
{
  "generatedAt": "2026-09-05T09:00:00Z",
  "source": "cavalierp",
  "skus": [ { "SKU CODE": "H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB", "STYLE NAME": "TORONTO", "PUBLISH": "1" } ],
  "styleModels": [ { "STYLE NAME": "ALASKA", "FULL PRODUCT CODE": "H.RUGFL_STR0005_RPS0003BLKBLK" } ],
  "models": [ { "MODEL NAME": "ALISA KAPTAN", "MODEL REFERENCE": "AK" } ]
}
```

- `skus` = `GetSKU` satırları (87 kolon; anahtar = SQL kolon adı, `SKU CODE` eşleme anahtarı)
- `styleModels` / `models` = `GetSKU_ModelReference` kümeleri
- Filtre ve sayfalama yok
- Boş liste: 200, diziler `[]`
- SP/SQL hata: 500 `{ "success": false, "error": "Unable to load product catalog." }`

Kaynak SP: `dbo.GetSKUSnapshot`.

## Tester

`https://app.devcloud.com.tr/cavalierp/api/tester/` — “Ürün kataloğu çek”.
```

- [ ] **Step 2: One sentence on the stock doc**

Replace line 3 of `docs/ecommerce-stock-webhook.md`:

From:

```markdown
Karşı tarafa verilecek sözleşme. Stok hareketi; ürün katalog create/update yok.
```

To:

```markdown
Karşı tarafa verilecek sözleşme. Stok hareketi. Ürün kataloğu ayrı kapı: `docs/ecommerce-product-catalog.md`.
```

Do not change stock endpoints, HMAC stock canonical, POST examples, or snapshot `items` shape.

- [ ] **Step 3: Commit**

```powershell
git add docs/ecommerce-product-catalog.md docs/ecommerce-stock-webhook.md
git commit -m "docs: publish product catalog snapshot contract"
```

---

## Spec coverage

| Spec § | Task |
|---|---|
| Stok dokunulmaz | 2–5 (stock files listed as do-not-modify); stock tests in Task 4 filter |
| Path + HMAC | Task 2 HMAC Fact; Task 4 simulator |
| `GetSKUSnapshot` üç küme | Task 1 mapper; Task 3 repo + SQL |
| camelCase wrapper / SQL keys | Task 1 + 2 JSON asserts |
| 500 + no SQL leak | Task 2 controller test |
| Empty 200 | Task 1 empty sets |
| Timeout 120 | Task 3 CommandTimeout; Task 4 HttpClient |
| Tester | Task 4 |
| Docs | Task 5 |
| No product POST/push | no tasks add them |

## Execution notes

- Work from repo root `D:\KocaPanda\Projeler\KocaPandaGit\CavaliERP.Mobile`
- After all tasks: `dotnet test api/CavaliERP.API.TESTS/CavaliERP.API.Test.csproj`
- Manual: HMAC GET snapshot; confirm stock snapshot JSON still `{ generatedAt, source, items: [{ skuCode, quantity }] }`
