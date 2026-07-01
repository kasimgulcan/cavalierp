using System.Security.Claims;
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

        try
        {
            var result = await executor.ExecuteAsync(def, spParams, ct);
            if (result.Success)
            {
                result = EnrichAuthResponse(request.Sp, result);
                result = await EnrichProductResponseAsync(request.Sp, result, ct);
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
                return ExecSpResponse.Fail("Invalid email or password.");

            return result;
        }

        var row = rows[0];
        if (!row.TryGetValue("UserId", out var userIdObj) || userIdObj is null)
            return result;

        var userId = Convert.ToInt32(userIdObj);
        var email = row.GetValueOrDefault("Email")?.ToString() ?? string.Empty;
        var role = row.GetValueOrDefault("Role")?.ToString() ?? "Member";

        var tokens = jwtTokenService.CreateTokens(userId, email, role);
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

        try
        {
            var images = await productImageCatalog.GetImagesAsync(ct);
            foreach (var row in rows)
            {
                var variantCode = row.GetValueOrDefault("VariantCode")?.ToString();
                var imageUrl = ProductImageCatalog.ResolveImageUrl(images, variantCode);
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
}
