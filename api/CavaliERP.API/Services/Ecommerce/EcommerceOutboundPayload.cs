using System.Globalization;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace CsmStok.Api.Services.Ecommerce;

public static class EcommerceOutboundPayload
{
    private static readonly JsonSerializerOptions JsonOptions = CreateOptions();

    public static string ToJson(EcommerceOutboundRow row)
    {
        var payload = new OutboundBody
        {
            EventId = row.EventId,
            EventType = row.EventType,
            OccurredAt = row.CreatedAt,
            Source = "cavalierp",
            Item = new OutboundItem
            {
                SkuCode = row.SkuCode,
                Quantity = row.Quantity,
                OnHand = row.OnHand,
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

    private sealed class OutboundBody
    {
        public Guid EventId { get; set; }
        public string EventType { get; set; } = string.Empty;
        public DateTimeOffset OccurredAt { get; set; }
        public string Source { get; set; } = "cavalierp";
        public OutboundItem Item { get; set; } = new();
    }

    private sealed class OutboundItem
    {
        public string SkuCode { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public int OnHand { get; set; }
    }
}

internal sealed class UtcIso8601DateTimeOffsetConverter : JsonConverter<DateTimeOffset>
{
    private const string Format = "yyyy-MM-dd'T'HH:mm:ss'Z'";

    public override DateTimeOffset Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        var text = reader.GetString();
        if (string.IsNullOrWhiteSpace(text))
            return default;
        return DateTimeOffset.Parse(text, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal);
    }

    public override void Write(Utf8JsonWriter writer, DateTimeOffset value, JsonSerializerOptions options) =>
        writer.WriteStringValue(value.UtcDateTime.ToString(Format, CultureInfo.InvariantCulture));
}
