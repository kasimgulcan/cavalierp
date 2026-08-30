using System.Net;
using System.Text;
using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommerceOutboundDispatcherTests
{
    private const string Secret = "test-shared-secret-value-32chars!!";

    [Fact]
    public async Task ProcessOnce_DoesNothing_WhenSubscriberUrlMissing()
    {
        var repo = new FakeOutboundRepo();
        var dispatcher = Create(repo, subscriberUrl: "");
        await dispatcher.ProcessOnceAsync(CancellationToken.None);
        Assert.Equal(0, repo.DequeueCalls);
    }

    [Fact]
    public async Task ProcessOnce_MarksSent_OnHttp2xx()
    {
        var repo = new FakeOutboundRepo { Rows = [SampleRow()] };
        var dispatcher = Create(repo, subscriberUrl: "https://reklam5.example/stock-events", status: HttpStatusCode.OK);
        await dispatcher.ProcessOnceAsync(CancellationToken.None);
        Assert.Contains(1, repo.SentIds);
        Assert.Empty(repo.FailedIds);
    }

    [Fact]
    public async Task ProcessOnce_MarksFailed_OnThirdAttempt()
    {
        var repo = new FakeOutboundRepo
        {
            Rows = [SampleRow() with { Attempts = 2 }],
        };
        var dispatcher = Create(repo, subscriberUrl: "https://reklam5.example/stock-events", status: HttpStatusCode.InternalServerError);
        await dispatcher.ProcessOnceAsync(CancellationToken.None);
        Assert.Contains(1, repo.FailedIds);
        Assert.Empty(repo.SentIds);
    }

    [Fact]
    public async Task ProcessOnce_StoresHttpStatusAndResponseBody_OnFailure()
    {
        var repo = new FakeOutboundRepo { Rows = [SampleRow()] };
        var dispatcher = Create(
            repo,
            subscriberUrl: "https://reklam5.example/stock-events",
            status: HttpStatusCode.InternalServerError,
            responseBody: "<html><title>AmbiguousMatchException</title><body>matched multiple endpoints</body></html>");
        await dispatcher.ProcessOnceAsync(CancellationToken.None);

        Assert.Single(repo.Errors);
        Assert.StartsWith("HTTP 500:", repo.Errors[0]);
        Assert.Contains("AmbiguousMatchException", repo.Errors[0]);
        Assert.Contains("matched multiple endpoints", repo.Errors[0]);
    }

    private static EcommerceOutboundRow SampleRow() => new()
    {
        OutboundId = 1,
        EventId = Guid.Parse("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
        EventType = "sale.created",
        SizeId = 7,
        SkuCode = "ABC_XL",
        Quantity = 1,
        OnHand = 9,
        CreatedAt = DateTimeOffset.Parse("2026-08-28T12:00:00Z"),
        Attempts = 0,
    };

    private static EcommerceOutboundDispatcher Create(
        FakeOutboundRepo repo,
        string subscriberUrl,
        HttpStatusCode status = HttpStatusCode.OK,
        string responseBody = "{}")
    {
        var factory = new StubFactory(status, responseBody);
        return new EcommerceOutboundDispatcher(
            repo,
            factory,
            Options.Create(new EcommerceSyncOptions
            {
                Enabled = true,
                SharedSecret = Secret,
                SubscriberUrl = subscriberUrl,
            }),
            NullLogger<EcommerceOutboundDispatcher>.Instance);
    }

    private sealed class StubFactory(HttpStatusCode status, string responseBody) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) =>
            new(new StubHandler(status, responseBody)) { Timeout = TimeSpan.FromSeconds(10) };
    }

    private sealed class StubHandler(HttpStatusCode status, string responseBody) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(status)
            {
                Content = new StringContent(responseBody, Encoding.UTF8, "text/html"),
            });
    }

    private sealed class FakeOutboundRepo : IEcommerceStockRepository
    {
        public List<EcommerceOutboundRow> Rows { get; set; } = [];
        public int DequeueCalls { get; private set; }
        public List<long> SentIds { get; } = [];
        public List<long> FailedIds { get; } = [];
        public List<string> Errors { get; } = [];

        public Task<EcommerceStockApplyResult> ApplyMovementAsync(
            Guid eventId, string eventType, string skuCode, int quantity, int? actorUserId, CancellationToken cancellationToken) =>
            throw new NotSupportedException();

        public Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken) =>
            throw new NotSupportedException();

        public Task<IReadOnlyList<EcommerceOutboundRow>> DequeuePendingAsync(int take, CancellationToken cancellationToken)
        {
            DequeueCalls++;
            return Task.FromResult<IReadOnlyList<EcommerceOutboundRow>>(Rows);
        }

        public Task MarkOutboundSentAsync(long outboundId, CancellationToken cancellationToken)
        {
            SentIds.Add(outboundId);
            return Task.CompletedTask;
        }

        public Task MarkOutboundAttemptAsync(long outboundId, string error, bool failed, CancellationToken cancellationToken)
        {
            Errors.Add(error);
            if (failed)
                FailedIds.Add(outboundId);
            return Task.CompletedTask;
        }
    }
}
