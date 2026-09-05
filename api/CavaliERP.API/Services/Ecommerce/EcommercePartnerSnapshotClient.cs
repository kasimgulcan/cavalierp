using Microsoft.Extensions.Options;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommercePartnerSnapshotClient(
    HttpClient http,
    IOptions<EcommerceSyncOptions> options)
{
    public const string HttpClientName = "EcommercePartnerSnapshot";

    public async Task<EcommercePartnerSnapshot> FetchAsync(CancellationToken cancellationToken = default)
    {
        var opts = options.Value;
        if (string.IsNullOrWhiteSpace(opts.PartnerSnapshotUrl) || string.IsNullOrWhiteSpace(opts.SharedSecret))
            throw new InvalidOperationException("Partner snapshot URL or shared secret is missing.");

        if (!Uri.TryCreate(opts.PartnerSnapshotUrl.Trim(), UriKind.Absolute, out var baseUri))
            throw new InvalidOperationException("Partner snapshot URL is invalid.");

        var timestamp = EcommerceHmac.UnixTimestamp(DateTimeOffset.UtcNow);
        var canonical = EcommerceHmac.CanonicalGet(timestamp, baseUri.AbsolutePath);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(opts.SharedSecret, canonical));
        var url = EcommerceHmac.AppendAuthQuery(baseUri, timestamp, signature);

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Accept.ParseAdd("application/json");
        using var response = await http.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"Partner snapshot HTTP {(int)response.StatusCode}: {TrimBody(body)}");

        return EcommercePartnerSnapshotParser.Parse(body);
    }

    private static string TrimBody(string body)
    {
        var trimmed = body.ReplaceLineEndings(" ").Trim();
        return trimmed.Length <= 400 ? trimmed : trimmed[..400];
    }
}
