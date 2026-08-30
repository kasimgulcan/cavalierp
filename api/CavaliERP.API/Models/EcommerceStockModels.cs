namespace CsmStok.Api.Models;

public sealed class EcommerceStockUpdatedRequest
{
    public Guid? EventId { get; set; }
    public string? EventType { get; set; }
    public DateTimeOffset? OccurredAt { get; set; }
    public string? Source { get; set; }
    public EcommerceStockItem? Item { get; set; }
}

public sealed class EcommerceStockItem
{
    public string? SkuCode { get; set; }
    public int? Quantity { get; set; }
}

public sealed class EcommerceStockApplyResult
{
    public int StatusCode { get; init; }
    public bool Success { get; init; }
    public string? EventType { get; init; }
    public string? SkuCode { get; init; }
    public int? Quantity { get; init; }
    public int? OnHand { get; init; }
    public string? Error { get; init; }

    public static EcommerceStockApplyResult Ok(string eventType, string skuCode, int quantity, int onHand) => new()
    {
        StatusCode = StatusCodes.Status200OK,
        Success = true,
        EventType = eventType,
        SkuCode = skuCode,
        Quantity = quantity,
        OnHand = onHand,
    };

    public static EcommerceStockApplyResult Fail(
        int statusCode,
        string error,
        string? eventType = null,
        string? skuCode = null,
        int? quantity = null,
        int? onHand = null) => new()
    {
        StatusCode = statusCode,
        Success = false,
        EventType = eventType,
        SkuCode = skuCode,
        Quantity = quantity,
        OnHand = onHand,
        Error = error,
    };
}

public sealed class EcommerceStockSnapshotItem
{
    public string SkuCode { get; init; } = string.Empty;
    public int Quantity { get; init; }
}
