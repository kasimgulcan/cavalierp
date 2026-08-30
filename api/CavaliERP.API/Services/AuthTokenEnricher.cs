using CsmStok.Api.Models;

namespace CsmStok.Api.Services;

public static class AuthTokenEnricher
{
    public static bool IsAuthTokenAlias(string spAlias) =>
        spAlias.Equals("Auth.Login", StringComparison.OrdinalIgnoreCase)
        || spAlias.Equals("Auth.Register", StringComparison.OrdinalIgnoreCase)
        || spAlias.Equals("Auth.RefreshToken", StringComparison.OrdinalIgnoreCase);

    public static string? IncomingRefreshToken(
        string spAlias,
        Dictionary<string, object?>? parameters)
    {
        if (!spAlias.Equals("Auth.RefreshToken", StringComparison.OrdinalIgnoreCase))
            return null;
        if (parameters is null)
            return null;
        if (!parameters.TryGetValue("RefreshToken", out var value) || value is null)
            return null;
        var token = value.ToString();
        return string.IsNullOrWhiteSpace(token) ? null : token;
    }
}
