using System.Net;
using System.Text;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommercePartnerSnapshotClientTests
{
    private const string Secret = "test-shared-secret-value-32chars!!";
    private const string SnapshotUrl =
        "https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-stock-snapshot";

    [Fact]
    public async Task FetchAsync_SignsGetViaQueryStringNotHeaders()
    {
        var innerJson =
            """{"generatedAt":"2026-08-28T00:00:00Z","source":"ecommerce","items":[{"skuCode":"ABC_XL","quantity":4}]}""";
        var handler = new CaptureHandler("\"" + innerJson.Replace("\"", "\\\"") + "\"");
        var client = Create(handler);

        var snapshot = await client.FetchAsync();

        Assert.Equal(HttpMethod.Get, handler.Method);
        Assert.StartsWith(
            "https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?",
            handler.Url,
            StringComparison.Ordinal);
        Assert.Contains("pluginName=cavalierp-stock-snapshot", handler.Url, StringComparison.Ordinal);
        Assert.True(string.IsNullOrEmpty(handler.HeaderTimestamp));
        Assert.True(string.IsNullOrEmpty(handler.HeaderSignature));

        var uri = new Uri(handler.Url!);
        var query = Microsoft.AspNetCore.WebUtilities.QueryHelpers.ParseQuery(uri.Query);
        var timestamp = query[EcommerceHmac.TimestampHeader].ToString();
        var signature = query[EcommerceHmac.SignatureHeader].ToString();
        var expected = EcommerceHmac.FormatSignatureHeader(
            EcommerceHmac.ComputeSignature(Secret, EcommerceHmac.CanonicalGet(timestamp, uri.AbsolutePath)));
        Assert.Equal(expected, signature);
        Assert.Equal("/en/data/plugin/get.ciqra", uri.AbsolutePath);

        var item = Assert.Single(snapshot.Items);
        Assert.Equal("ABC_XL", item.SkuCode);
        Assert.Equal(4, item.Quantity);
    }

    [Fact]
    public async Task FetchAsync_Throws_WhenUrlMissing()
    {
        var client = Create(new CaptureHandler("{}"), snapshotUrl: "");
        await Assert.ThrowsAsync<InvalidOperationException>(() => client.FetchAsync());
    }

    [Fact]
    public async Task FetchAsync_Throws_WhenHttpNotSuccess()
    {
        var handler = new CaptureHandler("no", HttpStatusCode.Unauthorized);
        var client = Create(handler);
        await Assert.ThrowsAsync<HttpRequestException>(() => client.FetchAsync());
    }

    private static EcommercePartnerSnapshotClient Create(
        CaptureHandler handler,
        string snapshotUrl = SnapshotUrl)
    {
        var http = new HttpClient(handler);
        var options = Options.Create(new EcommerceSyncOptions
        {
            Enabled = true,
            SharedSecret = Secret,
            PartnerSnapshotUrl = snapshotUrl,
        });
        return new EcommercePartnerSnapshotClient(http, options);
    }

    private sealed class CaptureHandler(string responseBody, HttpStatusCode status = HttpStatusCode.OK) : HttpMessageHandler
    {
        public HttpMethod? Method { get; private set; }
        public string? Url { get; private set; }
        public string HeaderTimestamp { get; private set; } = "";
        public string HeaderSignature { get; private set; } = "";

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Method = request.Method;
            Url = request.RequestUri?.ToString();
            HeaderTimestamp = request.Headers.TryGetValues(EcommerceHmac.TimestampHeader, out var ts) ? ts.First() : "";
            HeaderSignature = request.Headers.TryGetValues(EcommerceHmac.SignatureHeader, out var sig) ? sig.First() : "";
            return Task.FromResult(new HttpResponseMessage(status)
            {
                Content = new StringContent(responseBody, Encoding.UTF8, "application/json"),
            });
        }
    }
}
