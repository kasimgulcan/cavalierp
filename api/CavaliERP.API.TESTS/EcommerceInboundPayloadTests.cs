using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceInboundPayloadTests
{
    [Fact]
    public void ToJson_MatchesWebsiteSaleContract()
    {
        var json = EcommerceInboundPayload.ToJson(
            Guid.Parse("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
            "sale.created",
            DateTimeOffset.Parse("2026-08-28T12:00:00Z"),
            "H.RUGFL_FLC0001_FLC0001GRNNAV_XL",
            1);

        Assert.Equal(
            "{\"eventId\":\"3fa85f64-5717-4562-b3fc-2c963f66afa6\",\"eventType\":\"sale.created\",\"occurredAt\":\"2026-08-28T12:00:00Z\",\"source\":\"ecommerce\",\"item\":{\"skuCode\":\"H.RUGFL_FLC0001_FLC0001GRNNAV_XL\",\"quantity\":1}}",
            json);
    }
}
