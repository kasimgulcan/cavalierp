using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommerceStockServiceTests
{
    [Fact]
    public void Validate_RejectsMissingEventIdAndQuantity()
    {
        Assert.Equal("eventId is required.", EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventType = EcommerceStockService.SaleCreated,
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 1 },
        }));

        Assert.Equal("quantity is required.", EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = EcommerceStockService.SaleCreated,
            Item = new EcommerceStockItem { SkuCode = "ABC_XL" },
        }));

        Assert.Equal("quantity must be at least 1.", EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = EcommerceStockService.SaleCreated,
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 0 },
        }));
    }

    [Fact]
    public void Validate_RejectsLegacyStockUpdated()
    {
        var error = EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = "stock.updated",
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 8 },
        });

        Assert.Equal("eventType must be sale.created or return.created.", error);
    }

    [Fact]
    public void Validate_AcceptsSaleAndReturn()
    {
        Assert.Null(EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = "sale.created",
            Source = "ecommerce",
            Item = new EcommerceStockItem { SkuCode = "H.RUGFL_FLC0001_FLC0001GRNNAV_XL", Quantity = 1 },
        }));

        Assert.Null(EcommerceStockService.Validate(new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = "return.created",
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 2 },
        }));
    }

    [Fact]
    public async Task ApplyAsync_DoesNotCallRepository_WhenInvalid()
    {
        var repo = new FakeRepository();
        var service = new EcommerceStockService(repo, Options.Create(new EcommerceSyncOptions()));

        var result = await service.ApplyAsync(new EcommerceStockUpdatedRequest(), CancellationToken.None);

        Assert.Equal(StatusCodes.Status400BadRequest, result.StatusCode);
        Assert.Empty(repo.Calls);
    }

    [Fact]
    public async Task ApplyAsync_PassesEventTypeToRepository()
    {
        var eventId = Guid.NewGuid();
        var repo = new FakeRepository();
        var service = new EcommerceStockService(repo, Options.Create(new EcommerceSyncOptions()));
        var request = new EcommerceStockUpdatedRequest
        {
            EventId = eventId,
            EventType = EcommerceStockService.ReturnCreated,
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 4 },
        };

        var first = await service.ApplyAsync(request, CancellationToken.None);
        var second = await service.ApplyAsync(request, CancellationToken.None);

        Assert.True(first.Success);
        Assert.True(second.Success);
        Assert.Equal(4, second.Quantity);
        Assert.Equal(-3, second.OnHand);
        Assert.Equal(2, repo.Calls.Count);
        Assert.All(repo.Calls, call =>
        {
            Assert.Equal(eventId, call.EventId);
            Assert.Equal(EcommerceStockService.ReturnCreated, call.EventType);
        });
    }

    [Fact]
    public async Task ApplyAsync_PassesUserId7_WhenActorUserIdUnconfigured()
    {
        var repo = new FakeRepository();
        var service = new EcommerceStockService(
            repo,
            Options.Create(new EcommerceSyncOptions { ActorUserId = null }));
        var request = new EcommerceStockUpdatedRequest
        {
            EventId = Guid.NewGuid(),
            EventType = EcommerceStockService.SaleCreated,
            Item = new EcommerceStockItem { SkuCode = "ABC_XL", Quantity = 1 },
        };

        await service.ApplyAsync(request, CancellationToken.None);

        Assert.Single(repo.Calls);
        Assert.Equal(7, repo.Calls[0].ActorUserId);
    }

    private sealed class FakeRepository : IEcommerceStockRepository
    {
        public List<(Guid EventId, string EventType, string SkuCode, int Quantity, int? ActorUserId)> Calls { get; } = [];
        private readonly Dictionary<Guid, EcommerceStockApplyResult> _byEvent = new();

        public Task<EcommerceStockApplyResult> ApplyMovementAsync(
            Guid eventId,
            string eventType,
            string skuCode,
            int quantity,
            int? actorUserId,
            CancellationToken cancellationToken)
        {
            Calls.Add((eventId, eventType, skuCode, quantity, actorUserId));
            if (_byEvent.TryGetValue(eventId, out var existing))
                return Task.FromResult(existing);

            var result = EcommerceStockApplyResult.Ok(eventType, skuCode, quantity, onHand: -3);
            _byEvent[eventId] = result;
            return Task.FromResult(result);
        }

        public Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceStockSnapshotItem>>([
                new EcommerceStockSnapshotItem { SkuCode = "ABC_XL", Quantity = 4 },
            ]);

        public Task<IReadOnlyList<EcommerceOutboundRow>> DequeuePendingAsync(int take, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<EcommerceOutboundRow>>([]);

        public Task MarkOutboundSentAsync(long outboundId, CancellationToken cancellationToken) =>
            Task.CompletedTask;

        public Task MarkOutboundAttemptAsync(long outboundId, string error, bool failed, CancellationToken cancellationToken) =>
            Task.CompletedTask;
    }
}
