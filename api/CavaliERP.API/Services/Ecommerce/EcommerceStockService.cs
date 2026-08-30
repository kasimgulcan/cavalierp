using CsmStok.Api.Models;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceStockService(
    IEcommerceStockRepository repository,
    IOptions<EcommerceSyncOptions> options)
{
    public const string SaleCreated = "sale.created";
    public const string ReturnCreated = "return.created";
    public const int EcommerceUserId = 7;

    public async Task<EcommerceStockApplyResult> ApplyAsync(
        EcommerceStockUpdatedRequest? request,
        CancellationToken cancellationToken)
    {
        var error = Validate(request);
        if (error is not null)
            return EcommerceStockApplyResult.Fail(StatusCodes.Status400BadRequest, error);

        var eventType = NormalizeEventType(request!.EventType)!;
        return await repository.ApplyMovementAsync(
            request.EventId!.Value,
            eventType,
            request.Item!.SkuCode!.Trim(),
            request.Item.Quantity!.Value,
            options.Value.ActorUserId ?? EcommerceUserId,
            cancellationToken);
    }

    public Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken) =>
        repository.GetSnapshotAsync(cancellationToken);

    public static string? Validate(EcommerceStockUpdatedRequest? request)
    {
        if (request is null)
            return "Request body is required.";

        if (request.EventId is null || request.EventId == Guid.Empty)
            return "eventId is required.";

        if (NormalizeEventType(request.EventType) is null)
            return "eventType must be sale.created or return.created.";

        if (request.Item is null)
            return "item is required.";

        if (!SkuCodeMapper.TryNormalize(request.Item.SkuCode, out _, out var skuError))
            return skuError;

        if (request.Item.Quantity is null)
            return "quantity is required.";

        if (request.Item.Quantity < 1)
            return "quantity must be at least 1.";

        return null;
    }

    public static string? NormalizeEventType(string? eventType)
    {
        if (string.IsNullOrWhiteSpace(eventType))
            return null;

        var trimmed = eventType.Trim();
        if (string.Equals(trimmed, SaleCreated, StringComparison.OrdinalIgnoreCase))
            return SaleCreated;
        if (string.Equals(trimmed, ReturnCreated, StringComparison.OrdinalIgnoreCase))
            return ReturnCreated;
        return null;
    }
}
