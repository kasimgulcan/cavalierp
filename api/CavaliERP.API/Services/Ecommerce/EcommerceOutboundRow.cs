namespace CsmStok.Api.Services.Ecommerce;

public sealed record EcommerceOutboundRow
{
    public long OutboundId { get; init; }
    public Guid EventId { get; init; }
    public string EventType { get; init; } = string.Empty;
    public int SizeId { get; init; }
    public string SkuCode { get; init; } = string.Empty;
    public int Quantity { get; init; }
    public int OnHand { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    public int Attempts { get; init; }
}
