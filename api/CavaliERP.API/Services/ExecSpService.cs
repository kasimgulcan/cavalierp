using System.Security.Claims;
using System.Text.Json;
using CsmStok.Api.Models;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services;

public sealed class ExecSpService(
    SpWhitelist whitelist,
    SqlProcedureCatalog procedureCatalog,
    SqlSpExecutor executor,
    JwtTokenService jwtTokenService,
    ProductImageCatalog productImageCatalog,
    ILogger<ExecSpService> logger)
{
    public async Task<(int StatusCode, ExecSpResponse Body)> ExecuteAsync(
        ExecSpRequest request,
        ClaimsPrincipal? user,
        CancellationToken ct)
    {
        var (found, def) = await whitelist.TryResolveAsync(request.Sp, procedureCatalog, ct);
        if (!found || def is null)
            return (StatusCodes.Status403Forbidden, ExecSpResponse.Fail("SP not allowed."));

        var paramError = whitelist.ValidateParams(def, request.Params);
        if (paramError is not null)
            return (StatusCodes.Status400BadRequest, ExecSpResponse.Fail(paramError));

        if (def.RequiresAuth && user?.Identity?.IsAuthenticated != true)
            return (StatusCodes.Status401Unauthorized, ExecSpResponse.Fail("Authentication required."));

        var spParams = new Dictionary<string, object?>(request.Params ?? []);

        if (def.RequiresUserId)
        {
            var userIdClaim = user?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim is null)
                return (StatusCodes.Status401Unauthorized, ExecSpResponse.Fail("Authentication required."));

            spParams["UserId"] = int.Parse(userIdClaim);
        }

        if (def.RequiresStaff)
        {
            var role = user?.FindFirst("role")?.Value
                ?? user?.FindFirst(ClaimTypes.Role)?.Value;
            if (!string.Equals(role, "Staff", StringComparison.OrdinalIgnoreCase))
                return (StatusCodes.Status403Forbidden, ExecSpResponse.Fail("Staff access required."));
        }

        if (def.InlineHandler)
            return await ExecuteInlineAsync(def, ct);

        try
        {
            var result = await executor.ExecuteAsync(def, spParams, ct);
            if (result.Success)
            {
                result = EnrichAuthResponse(request.Sp, result);
                result = await EnrichProductResponseAsync(request.Sp, result, ct);
                result = await EnrichOrderRequestResponseAsync(request.Sp, result, ct);
            }

            return (StatusCodes.Status200OK, result);
        }
        catch (SqlException ex)
        {
            return (StatusCodes.Status400BadRequest, ExecSpResponse.Fail(ex.Message));
        }
        catch (Exception ex)
        {
            return (StatusCodes.Status500InternalServerError, ExecSpResponse.Fail(ex.Message));
        }
    }

    private ExecSpResponse EnrichAuthResponse(string spAlias, ExecSpResponse result)
    {
        if (!spAlias.Equals("Auth.Login", StringComparison.OrdinalIgnoreCase)
            && !spAlias.Equals("Auth.Register", StringComparison.OrdinalIgnoreCase))
        {
            return result;
        }

        if (result.Data is not List<Dictionary<string, object?>> rows || rows.Count == 0)
        {
            if (spAlias.Equals("Auth.Login", StringComparison.OrdinalIgnoreCase))
                return ExecSpResponse.Fail("Geçersiz kullanıcı adı veya şifre.");

            return result;
        }

        var row = rows[0];
        if (!row.TryGetValue("UserId", out var userIdObj) || userIdObj is null)
            return result;

        var userId = Convert.ToInt32(userIdObj);
        var username = row.GetValueOrDefault("Username")?.ToString() ?? string.Empty;
        var role = row.GetValueOrDefault("Role")?.ToString() ?? "Member";

        var tokens = jwtTokenService.CreateTokens(userId, username, role);
        return ExecSpResponse.Ok(new
        {
            user = row,
            accessToken = tokens.AccessToken,
            refreshToken = tokens.RefreshToken,
            expiresAt = tokens.ExpiresAt
        });
    }

    private async Task<ExecSpResponse> EnrichProductResponseAsync(
        string spAlias,
        ExecSpResponse result,
        CancellationToken ct)
    {
        if (!spAlias.Equals("Product.List", StringComparison.OrdinalIgnoreCase)
            && !spAlias.Equals("Product.GetByBarcode", StringComparison.OrdinalIgnoreCase))
        {
            return result;
        }

        if (result.Data is not List<Dictionary<string, object?>> rows || rows.Count == 0)
            return result;

        var isList = spAlias.Equals("Product.List", StringComparison.OrdinalIgnoreCase);

        IReadOnlyDictionary<string, string>? images;
        if (isList)
        {
            images = productImageCatalog.TryGetCached();
            if (images is null)
                productImageCatalog.ScheduleRefreshIfStale();
        }
        else
        {
            images = await productImageCatalog.GetImagesAsync(ct);
        }

        if (images is null)
            return result;

        try
        {
            foreach (var row in rows)
            {
                var productCode = row.GetValueOrDefault("ProductCode")?.ToString();
                var imageUrl = ProductImageCatalog.ResolveImageUrl(images, productCode);
                if (imageUrl is not null)
                    row["ImageUrl"] = imageUrl;
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Product image feed could not be loaded; returning products without images.");
        }

        return result;
    }

    private async Task<ExecSpResponse> EnrichOrderRequestResponseAsync(
        string spAlias,
        ExecSpResponse result,
        CancellationToken ct)
    {
        if (!spAlias.Equals("OrderRequest.Get", StringComparison.OrdinalIgnoreCase)
            && !spAlias.Equals("OrderRequest.GetMine", StringComparison.OrdinalIgnoreCase))
        {
            return result;
        }

        if (result.Data is not List<Dictionary<string, object?>> rows || rows.Count == 0)
            return result;

        IReadOnlyDictionary<string, string> images;
        try
        {
            images = await productImageCatalog.GetImagesAsync(ct);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Order request image enrichment skipped.");
            return result;
        }

        foreach (var row in rows)
        {
            if (!row.TryGetValue("Lines", out var linesObj) || linesObj is null)
                continue;

            var linesJson = linesObj.ToString();
            if (string.IsNullOrWhiteSpace(linesJson))
                continue;

            try
            {
                using var document = JsonDocument.Parse(linesJson);
                if (document.RootElement.ValueKind != JsonValueKind.Array)
                    continue;

                var enriched = new List<Dictionary<string, object?>>();
                foreach (var line in document.RootElement.EnumerateArray())
                {
                    var item = JsonSerializer.Deserialize<Dictionary<string, object?>>(line.GetRawText())
                        ?? new Dictionary<string, object?>();

                    var productCode = item.GetValueOrDefault("ProductCode")?.ToString();
                    var imageUrl = ProductImageCatalog.ResolveImageUrl(images, productCode);
                    if (imageUrl is not null)
                        item["ImageUrl"] = imageUrl;

                    enriched.Add(item);
                }

                row["Lines"] = JsonSerializer.Serialize(enriched);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Order request line image enrichment failed.");
            }
        }

        return result;
    }

    private async Task<(int StatusCode, ExecSpResponse Body)> ExecuteInlineAsync(
        SpDefinition def,
        CancellationToken ct)
    {
        if (!def.Alias.Equals("Product.Images", StringComparison.OrdinalIgnoreCase))
            return (StatusCodes.Status403Forbidden, ExecSpResponse.Fail("SP not allowed."));

        try
        {
            var images = await productImageCatalog.GetImagesAsync(ct);
            var rows = images
                .GroupBy(pair => pair.Key, StringComparer.OrdinalIgnoreCase)
                .Select(group => group.First())
                .Select(pair => new Dictionary<string, object?>
                {
                    ["ProductCode"] = pair.Key,
                    ["ImageUrl"] = pair.Value,
                })
                .ToList();

            return (StatusCodes.Status200OK, ExecSpResponse.Ok(rows));
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Product.Images inline handler failed.");
            return (StatusCodes.Status200OK, ExecSpResponse.Ok(Array.Empty<object>()));
        }
    }
}
