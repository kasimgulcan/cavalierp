using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class ShopCallResult
{
    public int StatusCode { get; init; }
    public string Body { get; init; } = string.Empty;
}

public sealed class EcommerceShopSimulator(
    HttpClient http,
    IOptions<EcommerceSyncOptions> options)
{
    public const string HttpClientName = "EcommerceShopSimulator";
    public const string StockPath = "/integrations/ecommerce/stock";
    public const string SnapshotPath = "/integrations/ecommerce/stock/snapshot";
    public const string ProductCatalogPath = "/integrations/ecommerce/products/snapshot";

    public Task<ShopCallResult> GetSnapshotAsync(string apiBaseUrl, CancellationToken ct = default) =>
        SendAsync(HttpMethod.Get, Combine(apiBaseUrl, SnapshotPath), body: null, canonicalPath: SnapshotPath, ct);

    public Task<ShopCallResult> GetProductCatalogAsync(string apiBaseUrl, CancellationToken ct = default) =>
        SendAsync(HttpMethod.Get, Combine(apiBaseUrl, ProductCatalogPath), body: null, canonicalPath: ProductCatalogPath, ct);

    public Task<ShopCallResult> ApplyAsync(
        string apiBaseUrl,
        string eventType,
        string skuCode,
        int quantity,
        Guid eventId,
        DateTimeOffset occurredAt,
        CancellationToken ct = default)
    {
        var body = EcommerceInboundPayload.ToJson(eventId, eventType, occurredAt, skuCode, quantity);
        return SendAsync(HttpMethod.Post, Combine(apiBaseUrl, StockPath), body, canonicalPath: StockPath, ct);
    }

    private async Task<ShopCallResult> SendAsync(
        HttpMethod method,
        Uri url,
        string? body,
        string canonicalPath,
        CancellationToken ct)
    {
        var secret = options.Value.SharedSecret;
        var timestamp = EcommerceHmac.UnixTimestamp(DateTimeOffset.UtcNow);
        var canonical = method == HttpMethod.Get
            ? EcommerceHmac.CanonicalGet(timestamp, canonicalPath)
            : EcommerceHmac.CanonicalPost(timestamp, body ?? "");
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(secret, canonical));

        using var message = new HttpRequestMessage(method, url);
        message.Headers.TryAddWithoutValidation(EcommerceHmac.TimestampHeader, timestamp);
        message.Headers.TryAddWithoutValidation(EcommerceHmac.SignatureHeader, signature);
        message.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        if (body is not null)
            message.Content = new StringContent(body, Encoding.UTF8, "application/json");

        using var response = await http.SendAsync(message, ct);
        var responseBody = await response.Content.ReadAsStringAsync(ct);
        return new ShopCallResult
        {
            StatusCode = (int)response.StatusCode,
            Body = responseBody,
        };
    }

    public static Uri Combine(string baseUrl, string path)
    {
        var trimmedBase = baseUrl.Trim().TrimEnd('/');
        var trimmedPath = path.StartsWith('/') ? path : "/" + path;
        return new Uri(trimmedBase + trimmedPath, UriKind.Absolute);
    }
}
