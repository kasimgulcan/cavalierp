namespace CsmStok.Api.Services;

public sealed class ProductImageCatalog(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    ILogger<ProductImageCatalog> logger)
{
    public const string HttpClientName = "ProductImageCatalog";

    private readonly SemaphoreSlim _refreshLock = new(1, 1);
    private Dictionary<string, string>? _cache;
    private DateTime _expiresAtUtc = DateTime.MinValue;

    public IReadOnlyDictionary<string, string>? TryGetCached()
    {
        if (_cache is not null && DateTime.UtcNow < _expiresAtUtc)
            return _cache;

        return null;
    }

    public void ScheduleRefreshIfStale()
    {
        if (TryGetCached() is not null)
            return;

        _ = Task.Run(async () =>
        {
            try
            {
                await GetImagesAsync(CancellationToken.None);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background product image feed refresh failed.");
            }
        });
    }

    public async Task<IReadOnlyDictionary<string, string>> GetImagesAsync(CancellationToken ct = default)
    {
        var cached = TryGetCached();
        if (cached is not null)
            return cached;

        await _refreshLock.WaitAsync(ct);
        try
        {
            cached = TryGetCached();
            if (cached is not null)
                return cached;

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
        string? productCode)
    {
        if (string.IsNullOrWhiteSpace(productCode))
            return null;

        return images.TryGetValue(productCode.Trim(), out var url) ? url : null;
    }
}
