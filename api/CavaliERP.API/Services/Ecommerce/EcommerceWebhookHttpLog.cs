namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceWebhookHttpLog
{
    public long Id { get; init; }
    public Guid EventId { get; init; }
    public string Direction { get; init; } = string.Empty;
    public string? EventType { get; init; }
    public string? SkuCode { get; init; }
    public string? RequestUrl { get; init; }
    public string? RequestJson { get; init; }
    public int? HttpStatus { get; init; }
    public string? ResponseJson { get; init; }
    public DateTimeOffset At { get; init; }
}
