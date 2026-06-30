using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class SpWhitelistTests
{
    [Fact]
    public void TryGet_KnownAlias_ReturnsDefinition()
    {
        var whitelist = new SpWhitelist();
        var found = whitelist.TryGet("Product.GetByBarcode", out var def);
        Assert.True(found);
        Assert.Equal("API_Product_GetByBarcode", def!.SqlName);
    }

    [Fact]
    public void TryGet_UnknownAlias_ReturnsFalse()
    {
        var whitelist = new SpWhitelist();
        var found = whitelist.TryGet("Evil.DropDatabase", out _);
        Assert.False(found);
    }

    [Fact]
    public void ValidateParams_ExtraParam_ReturnsError()
    {
        var whitelist = new SpWhitelist();
        whitelist.TryGet("Product.GetByBarcode", out var def);
        var error = whitelist.ValidateParams(def!, new Dictionary<string, object?>
        {
            ["Barcode"] = "123",
            ["UserId"] = 1
        });
        Assert.NotNull(error);
        Assert.Contains("UserId", error);
    }
}
