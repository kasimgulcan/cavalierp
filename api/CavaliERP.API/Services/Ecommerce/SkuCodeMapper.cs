namespace CsmStok.Api.Services.Ecommerce;

public static class SkuCodeMapper
{
    public const int MaxLength = 200;

    public static string FromProduct(string productCode, string size)
    {
        var code = productCode.Trim();
        var sizeLabel = size.Trim();
        return $"{code}_{sizeLabel}";
    }

    public static bool TryNormalize(string? skuCode, out string normalized, out string? error)
    {
        normalized = string.Empty;
        if (string.IsNullOrWhiteSpace(skuCode))
        {
            error = "skuCode is required.";
            return false;
        }

        normalized = skuCode.Trim();
        if (normalized.Length > MaxLength)
        {
            error = "skuCode is too long.";
            return false;
        }

        error = null;
        return true;
    }
}
