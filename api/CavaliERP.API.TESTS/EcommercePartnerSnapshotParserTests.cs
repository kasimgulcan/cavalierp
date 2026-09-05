using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommercePartnerSnapshotParserTests
{
    [Fact]
    public void Parse_UnwrapsJsonStringEnvelope()
    {
        var body = "\"{\\\"generatedAt\\\":\\\"2026-08-28T00:00:00Z\\\",\\\"source\\\":\\\"ecommerce\\\",\\\"items\\\":[{\\\"skuCode\\\":\\\"R.TOPKG_CPL0153_TJR0016CELCEL_6-7 Y\\\",\\\"quantity\\\":3}]}\"";

        var snapshot = EcommercePartnerSnapshotParser.Parse(body);

        Assert.Equal("ecommerce", snapshot.Source);
        Assert.Equal(new DateTimeOffset(2026, 8, 28, 0, 0, 0, TimeSpan.Zero), snapshot.GeneratedAt);
        var item = Assert.Single(snapshot.Items);
        Assert.Equal("R.TOPKG_CPL0153_TJR0016CELCEL_6-7 Y", item.SkuCode);
        Assert.Equal(3, item.Quantity);
    }

    [Fact]
    public void Parse_AcceptsPlainJsonObject()
    {
        var body = """{"generatedAt":"2026-08-28T00:00:00Z","source":"ecommerce","items":[{"skuCode":"ABC_XL","quantity":0}]}""";

        var snapshot = EcommercePartnerSnapshotParser.Parse(body);

        var item = Assert.Single(snapshot.Items);
        Assert.Equal("ABC_XL", item.SkuCode);
        Assert.Equal(0, item.Quantity);
    }

    [Fact]
    public void Parse_ThrowsOnInvalidPayload()
    {
        Assert.Throws<InvalidOperationException>(() => EcommercePartnerSnapshotParser.Parse("not-json"));
    }
}
