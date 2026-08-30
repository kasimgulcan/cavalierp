using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceOutboundPayloadTests
{
    [Fact]
    public void ToJson_OmitsSizeIdAndUsesCompactContract()
    {
        var json = EcommerceOutboundPayload.ToJson(new EcommerceOutboundRow
        {
            EventId = Guid.Parse("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
            EventType = "sale.created",
            SizeId = 99,
            SkuCode = "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
            Quantity = 2,
            OnHand = 10,
            CreatedAt = DateTimeOffset.Parse("2026-08-28T12:05:00Z"),
        });

        Assert.Equal(
            "{\"eventId\":\"3fa85f64-5717-4562-b3fc-2c963f66afa6\",\"eventType\":\"sale.created\",\"occurredAt\":\"2026-08-28T12:05:00Z\",\"source\":\"cavalierp\",\"item\":{\"skuCode\":\"H.RUGFL_FLC0001_FLC0001GRNNAV_XL\",\"quantity\":2,\"onHand\":10}}",
            json);
        Assert.DoesNotContain("sizeId", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("99", json);
    }
}
