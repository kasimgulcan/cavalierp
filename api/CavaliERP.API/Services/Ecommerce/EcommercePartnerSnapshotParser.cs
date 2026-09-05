using System.Text.Json;
using CsmStok.Api.Models;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommercePartnerSnapshot
{
    public DateTimeOffset GeneratedAt { get; init; }
    public string Source { get; init; } = string.Empty;
    public IReadOnlyList<EcommerceStockSnapshotItem> Items { get; init; } = [];
}

public static class EcommercePartnerSnapshotParser
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public static EcommercePartnerSnapshot Parse(string body)
    {
        if (string.IsNullOrWhiteSpace(body))
            throw new InvalidOperationException("Partner snapshot body is empty.");

        try
        {
            using var first = JsonDocument.Parse(body);
            var json = first.RootElement.ValueKind == JsonValueKind.String
                ? first.RootElement.GetString() ?? throw new InvalidOperationException("Partner snapshot envelope is empty.")
                : body;
            var parsed = JsonSerializer.Deserialize<Envelope>(json, JsonOptions)
                ?? throw new InvalidOperationException("Partner snapshot JSON is empty.");
            return new EcommercePartnerSnapshot
            {
                GeneratedAt = parsed.GeneratedAt,
                Source = parsed.Source ?? string.Empty,
                Items = parsed.Items ?? [],
            };
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException("Unable to parse partner snapshot.", ex);
        }
    }

    private sealed class Envelope
    {
        public DateTimeOffset GeneratedAt { get; set; }
        public string? Source { get; set; }
        public List<EcommerceStockSnapshotItem>? Items { get; set; }
    }
}
