using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class SkuCodeMapperTests
{
    [Fact]
    public void FromProduct_JoinsProductCodeAndSize()
    {
        var sku = SkuCodeMapper.FromProduct("H.RUGFL_FLC0001_FLC0001GRNNAV", "XL");
        Assert.Equal("H.RUGFL_FLC0001_FLC0001GRNNAV_XL", sku);
    }

    [Fact]
    public void TryNormalize_TrimsAndAcceptsValidCode()
    {
        var ok = SkuCodeMapper.TryNormalize("  H.RUGFL_FLC0001_FLC0001GRNNAV_XL  ", out var normalized, out var error);
        Assert.True(ok);
        Assert.Equal("H.RUGFL_FLC0001_FLC0001GRNNAV_XL", normalized);
        Assert.Null(error);
    }

    [Fact]
    public void TryNormalize_RejectsEmpty()
    {
        var ok = SkuCodeMapper.TryNormalize("   ", out _, out var error);
        Assert.False(ok);
        Assert.Equal("skuCode is required.", error);
    }

    [Fact]
    public void TryNormalize_RejectsTooLong()
    {
        var ok = SkuCodeMapper.TryNormalize(new string('A', SkuCodeMapper.MaxLength + 1), out _, out var error);
        Assert.False(ok);
        Assert.Equal("skuCode is too long.", error);
    }
}
