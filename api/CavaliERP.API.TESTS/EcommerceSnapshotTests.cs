using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommerceSnapshotTests
{
    [Fact]
    public async Task GetSnapshotAsync_ReturnsSkuCodeAndQuantityOnly()
    {
        var service = new EcommerceStockService(
            new SnapshotRepository(),
            Options.Create(new EcommerceSyncOptions()));
        var items = await service.GetSnapshotAsync(CancellationToken.None);

        Assert.Equal(2, items.Count);
        Assert.Equal("H.RUGFL_FLC0001_FLC0001GRNNAV_XL", items[0].SkuCode);
        Assert.Equal(8, items[0].Quantity);
        Assert.All(items, item => Assert.False(string.IsNullOrWhiteSpace(item.SkuCode)));
    }

    private sealed class SnapshotRepository : IEcommerceStockRepository
    {
        public Task<EcommerceStockApplyResult> ApplyMovementAsync(
            Guid eventId,
            string eventType,
            string skuCode,
            int quantity,
            int? actorUserId,
            CancellationToken cancellationToken) =>
            Task.FromResult(EcommerceStockApplyResult.Ok(eventType, skuCode, quantity, 8));

        public Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceStockSnapshotItem>>([
                new() { SkuCode = "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", Quantity = 8 },
                new() { SkuCode = "H.RUGFL_FLC0001_FLC0001GRNNAV_M", Quantity = 0 },
            ]);

        public Task<IReadOnlyList<EcommerceOutboundRow>> DequeuePendingAsync(int take, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceOutboundRow>>([]);

        public Task MarkOutboundSentAsync(
            long outboundId, string? requestUrl, string? requestJson, int httpStatus, string? responseJson, CancellationToken cancellationToken) =>
            Task.CompletedTask;

        public Task MarkOutboundAttemptAsync(
            long outboundId, string error, bool failed, string? requestUrl, string? requestJson, int? httpStatus, string? responseJson, CancellationToken cancellationToken) =>
            Task.CompletedTask;

        public Task SaveInboundHttpAsync(
            Guid eventId, string? requestJson, int httpStatus, string? responseJson, CancellationToken cancellationToken) =>
            Task.CompletedTask;

        public Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListInboundHttpAsync(int take, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceWebhookHttpLog>>([]);

        public Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListOutboundHttpAsync(int take, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceWebhookHttpLog>>([]);
    }
}
