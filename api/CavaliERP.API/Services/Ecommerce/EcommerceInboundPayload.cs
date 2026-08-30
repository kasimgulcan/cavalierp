using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace CsmStok.Api.Services.Ecommerce;

public static class EcommerceInboundPayload
{
    private static readonly JsonSerializerOptions JsonOptions = CreateOptions();

    public static string ToJson(
        Guid eventId,
        string eventType,
        DateTimeOffset occurredAt,
        string skuCode,
        int quantity)
    {
        var payload = new InboundBody
        {
            EventId = eventId,
            EventType = eventType,
            OccurredAt = occurredAt,
            Source = "ecommerce",
            Item = new InboundItem
            {
                SkuCode = skuCode,
                Quantity = quantity,
            },
        };
        return JsonSerializer.Serialize(payload, JsonOptions);
    }

    private static JsonSerializerOptions CreateOptions()
    {
        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = JsonIgnoreCondition.Never,
            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
            WriteIndented = false,
        };
        options.Converters.Add(new UtcIso8601DateTimeOffsetConverter());
        return options;
    }

    private sealed class InboundBody
    {
        public Guid EventId { get; set; }
        public string EventType { get; set; } = string.Empty;
        public DateTimeOffset OccurredAt { get; set; }
        public string Source { get; set; } = "ecommerce";
        public InboundItem Item { get; set; } = new();
    }

    private sealed class InboundItem
    {
        public string SkuCode { get; set; } = string.Empty;
        public int Quantity { get; set; }
    }
}
