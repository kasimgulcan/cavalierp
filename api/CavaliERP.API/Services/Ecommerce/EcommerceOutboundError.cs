using System.Net;
using System.Text.RegularExpressions;

namespace CsmStok.Api.Services.Ecommerce;

public static class EcommerceOutboundError
{
    public const int MaxLength = 4000;

    public static string FormatHttp(HttpStatusCode statusCode, string? body) =>
        FormatHttp((int)statusCode, body);

    public static string FormatHttp(int statusCode, string? body)
    {
        var detail = Collapse(StripTags(body));
        if (string.IsNullOrWhiteSpace(detail))
            return $"HTTP {statusCode}";

        return Truncate($"HTTP {statusCode}: {detail}");
    }

    public static string FormatException(Exception exception)
    {
        ArgumentNullException.ThrowIfNull(exception);
        var inner = exception.InnerException is null
            ? ""
            : " | " + exception.InnerException.GetType().Name + ": " + exception.InnerException.Message;
        return Truncate($"{exception.GetType().Name}: {exception.Message}{inner}");
    }

    private static string StripTags(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return "";

        var stripped = Regex.Replace(text, "<[^>]+>", " ", RegexOptions.Singleline);
        return WebUtility.HtmlDecode(stripped);
    }

    private static string Collapse(string text) =>
        Regex.Replace(text, @"\s+", " ").Trim();

    private static string Truncate(string text) =>
        text.Length <= MaxLength ? text : text[..MaxLength];
}
