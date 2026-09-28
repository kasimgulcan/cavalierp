using System.Net;
using System.Text;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommerceShopSimulatorTests
{
    private const string Secret = "test-shared-secret-value-32chars!!";
    private const string BaseUrl = "http://localhost:5160";

    [Fact]
    public async Task GetSnapshot_SendsSignedGet()
    {
        var handler = new CaptureHandler("""{"generatedAt":"2026-08-28T00:00:00Z","source":"cavalierp","items":[]}""");
        var simulator = Create(handler);

        var result = await simulator.GetSnapshotAsync(BaseUrl);

        Assert.Equal(200, result.StatusCode);
        Assert.Equal(HttpMethod.Get, handler.Method);
        Assert.Equal("http://localhost:5160/integrations/ecommerce/stock/snapshot", handler.Url);
        AssertSigned(handler, EcommerceHmac.CanonicalGet(handler.Timestamp, "/integrations/ecommerce/stock/snapshot"));
    }

    [Fact]
    public async Task GetProductCatalog_SendsSignedGet()
    {
        var handler = new CaptureHandler("""{"generatedAt":"2026-09-05T00:00:00Z","source":"cavalierp","skus":[],"styleModels":[],"models":[]}""");
        var simulator = Create(handler);

        var result = await simulator.GetProductCatalogAsync(BaseUrl);

        Assert.Equal(200, result.StatusCode);
        Assert.Equal(HttpMethod.Get, handler.Method);
        Assert.Equal("http://localhost:5160/integrations/ecommerce/products/snapshot", handler.Url);
        AssertSigned(handler, EcommerceHmac.CanonicalGet(handler.Timestamp, "/integrations/ecommerce/products/snapshot"));
    }

    [Fact]
    public async Task GetProductCatalog_WithSince_AppendsQueryAndKeepsCanonicalPath()
    {
        var handler = new CaptureHandler("""{"generatedAt":"2026-09-05T00:00:00Z","source":"cavalierp","skus":[],"styleModels":[],"models":[]}""");
        var simulator = Create(handler);
        var since = DateTimeOffset.Parse("2026-09-07T17:00:00Z");

        var result = await simulator.GetProductCatalogAsync(BaseUrl, since);

        Assert.Equal(200, result.StatusCode);
        Assert.Contains("since=", handler.Url, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("2026-09-07", handler.Url);
        Assert.DoesNotContain("since", EcommerceHmac.CanonicalGet(handler.Timestamp, "/integrations/ecommerce/products/snapshot"));
        AssertSigned(handler, EcommerceHmac.CanonicalGet(handler.Timestamp, "/integrations/ecommerce/products/snapshot"));
    }

    [Fact]
    public async Task Apply_SendsSignedSalePost()
    {
        var handler = new CaptureHandler("""{"success":true}""");
        var simulator = Create(handler);
        var eventId = Guid.Parse("3fa85f64-5717-4562-b3fc-2c963f66afa6");
        var now = DateTimeOffset.Parse("2026-08-28T12:00:00Z");

        var result = await simulator.ApplyAsync(BaseUrl, "sale.created", "SKU_XL", 2, eventId, now);

        Assert.Equal(200, result.StatusCode);
        Assert.Equal(HttpMethod.Post, handler.Method);
        Assert.Equal("http://localhost:5160/integrations/ecommerce/stock", handler.Url);
        Assert.Equal(
            "{\"eventId\":\"3fa85f64-5717-4562-b3fc-2c963f66afa6\",\"eventType\":\"sale.created\",\"occurredAt\":\"2026-08-28T12:00:00Z\",\"source\":\"ecommerce\",\"item\":{\"skuCode\":\"SKU_XL\",\"quantity\":2}}",
            handler.Body);
        AssertSigned(handler, EcommerceHmac.CanonicalPost(handler.Timestamp, handler.Body));
    }

    private static EcommerceShopSimulator Create(CaptureHandler handler)
    {
        var http = new HttpClient(handler);
        var options = Options.Create(new EcommerceSyncOptions
        {
            Enabled = true,
            TesterEnabled = true,
            SharedSecret = Secret,
        });
        return new EcommerceShopSimulator(http, options);
    }

    private static void AssertSigned(CaptureHandler handler, string canonical)
    {
        var expected = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));
        Assert.False(string.IsNullOrWhiteSpace(handler.Timestamp));
        Assert.Equal(expected, handler.Signature);
    }

    private sealed class CaptureHandler(string responseBody) : HttpMessageHandler
    {
        public HttpMethod? Method { get; private set; }
        public string? Url { get; private set; }
        public string Timestamp { get; private set; } = "";
        public string Signature { get; private set; } = "";
        public string Body { get; private set; } = "";

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Method = request.Method;
            Url = request.RequestUri?.ToString();
            Timestamp = request.Headers.TryGetValues(EcommerceHmac.TimestampHeader, out var ts) ? ts.First() : "";
            Signature = request.Headers.TryGetValues(EcommerceHmac.SignatureHeader, out var sig) ? sig.First() : "";
            if (request.Content is not null)
                Body = await request.Content.ReadAsStringAsync(cancellationToken);

            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(responseBody, Encoding.UTF8, "application/json"),
            };
        }
    }
}
