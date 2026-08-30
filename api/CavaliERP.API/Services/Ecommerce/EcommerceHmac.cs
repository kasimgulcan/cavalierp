using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace CsmStok.Api.Services.Ecommerce;

public static class EcommerceHmac
{
    public const string TimestampHeader = "X-CavaliERP-Timestamp";
    public const string SignatureHeader = "X-CavaliERP-Signature";

    public static string CanonicalPost(string timestamp, string body) =>
        $"{timestamp}.{body}";

    public static string CanonicalGet(string timestamp, string path)
    {
        var normalized = NormalizePath(path);
        return $"{timestamp}.GET.{normalized}";
    }

    public static string NormalizePath(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
            return "/";

        var trimmed = path.Trim();
        if (!trimmed.StartsWith('/'))
            trimmed = "/" + trimmed;

        if (trimmed.Length > 1)
            trimmed = trimmed.TrimEnd('/');

        return trimmed;
    }

    public static byte[] ComputeSignature(string secret, string canonical)
    {
        var key = Encoding.UTF8.GetBytes(secret);
        var data = Encoding.UTF8.GetBytes(canonical);
        return HMACSHA256.HashData(key, data);
    }

    public static string FormatSignatureHeader(byte[] signature) =>
        "sha256=" + Convert.ToHexString(signature).ToLowerInvariant();

    public static bool TryParseSignature(string? header, out byte[] signature)
    {
        signature = [];
        if (string.IsNullOrWhiteSpace(header))
            return false;

        var value = header.Trim();
        if (value.StartsWith("sha256=", StringComparison.OrdinalIgnoreCase))
            value = value["sha256=".Length..].Trim();

        if (value.Length is 0 || value.Length % 2 != 0)
            return false;

        try
        {
            signature = Convert.FromHexString(value);
            return signature.Length == 32;
        }
        catch (FormatException)
        {
            signature = [];
            return false;
        }
    }

    public static bool SignaturesEqual(byte[] expected, byte[] actual)
    {
        if (expected.Length != actual.Length)
        {
            CryptographicOperations.FixedTimeEquals(expected, expected);
            return false;
        }

        return CryptographicOperations.FixedTimeEquals(expected, actual);
    }

    public static string UnixTimestamp(DateTimeOffset utc) =>
        utc.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture);

    public static bool TryParseTimestamp(string? header, out long unixSeconds)
    {
        unixSeconds = 0;
        if (string.IsNullOrWhiteSpace(header))
            return false;

        return long.TryParse(header.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out unixSeconds);
    }

    public static bool IsTimestampFresh(long unixSeconds, DateTimeOffset now, TimeSpan skew)
    {
        var timestamp = DateTimeOffset.FromUnixTimeSeconds(unixSeconds);
        var delta = now - timestamp;
        if (delta < TimeSpan.Zero)
            delta = -delta;
        return delta <= skew;
    }
}
