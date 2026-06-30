namespace CsmStok.Api.Services;

public sealed class ProductImageCatalog(IHttpClientFactory httpClientFactory, IConfiguration configuration)
{
    public const string HttpClientName = "ProductImageCatalog";

    private readonly SemaphoreSlim _refreshLock = new(1, 1);
    private Dictionary<string, string>? _cache;
    private DateTime _expiresAtUtc = DateTime.MinValue;

    public async Task<IReadOnlyDictionary<string, string>> GetImagesAsync(CancellationToken ct = default)
    {
        if (_cache is not null && DateTime.UtcNow < _expiresAtUtc)
            return _cache;

        await _refreshLock.WaitAsync(ct);
        try
        {
            if (_cache is not null && DateTime.UtcNow < _expiresAtUtc)
                return _cache;

            var feedUrl = configuration["ProductImages:FeedUrl"]
                ?? "https://www.cavaliersanmarco.it/xml/wc6srwwper";
            var client = httpClientFactory.CreateClient(HttpClientName);
            using var response = await client.GetAsync(feedUrl, ct);
            response.EnsureSuccessStatusCode();

            var xml = await response.Content.ReadAsStringAsync(ct);
            _cache = ProductImageFeedParser.Parse(xml);

            var cacheMinutes = configuration.GetValue("ProductImages:CacheMinutes", 60);
            _expiresAtUtc = DateTime.UtcNow.AddMinutes(cacheMinutes);
            return _cache;
        }
        finally
        {
            _refreshLock.Release();
        }
    }

    public static string? ResolveImageUrl(
        IReadOnlyDictionary<string, string> images,
        string? variantCode)
    {
        if (string.IsNullOrWhiteSpace(variantCode))
            return null;

        return images.TryGetValue(variantCode.Trim(), out var url) ? url : null;
    }
}
