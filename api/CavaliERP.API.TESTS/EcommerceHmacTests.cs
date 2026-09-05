using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceHmacTests
{
    private const string Secret = "test-shared-secret-value-32chars!!";

    [Fact]
    public void CanonicalPost_JoinsTimestampAndBody()
    {
        Assert.Equal("1700000000.{\"a\":1}", EcommerceHmac.CanonicalPost("1700000000", "{\"a\":1}"));
    }

    [Fact]
    public void CanonicalGet_UsesMethodAndNormalizedPath()
    {
        var canonical = EcommerceHmac.CanonicalGet("1700000000", "/integrations/ecommerce/stock/snapshot/");
        Assert.Equal("1700000000.GET./integrations/ecommerce/stock/snapshot", canonical);
    }

    [Fact]
    public void CanonicalGet_ProductCatalogSnapshotPath()
    {
        var canonical = EcommerceHmac.CanonicalGet("1700000000", "/integrations/ecommerce/products/snapshot/");
        Assert.Equal("1700000000.GET./integrations/ecommerce/products/snapshot", canonical);
    }

    [Fact]
    public void CanonicalGet_IgnoresQueryStringOnPartnerSnapshotPath()
    {
        var path = new Uri("https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-stock-snapshot")
            .AbsolutePath;
        var canonical = EcommerceHmac.CanonicalGet("1700000000", path);
        Assert.Equal("1700000000.GET./en/data/plugin/get.ciqra", canonical);
    }

    [Fact]
    public void AppendAuthQuery_KeepsExistingParamsAndUrlEncodesSignature()
    {
        var uri = new Uri("https://staging.cavaliersanmarco.it/en/data/plugin/get.ciqra?pluginName=cavalierp-stock-snapshot");
        var signed = EcommerceHmac.AppendAuthQuery(uri, "1700000000", "sha256=abcd");

        Assert.Equal("/en/data/plugin/get.ciqra", signed.AbsolutePath);
        var query = Microsoft.AspNetCore.WebUtilities.QueryHelpers.ParseQuery(signed.Query);
        Assert.Equal("cavalierp-stock-snapshot", query["pluginName"].ToString());
        Assert.Equal("1700000000", query[EcommerceHmac.TimestampHeader].ToString());
        Assert.Equal("sha256=abcd", query[EcommerceHmac.SignatureHeader].ToString());
        Assert.Contains("sha256%3Dabcd", signed.Query, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void SignaturesEqual_AcceptsMatchingHmac()
    {
        var canonical = EcommerceHmac.CanonicalPost("1700000000", "{}");
        var signature = EcommerceHmac.ComputeSignature(Secret, canonical);
        var header = EcommerceHmac.FormatSignatureHeader(signature);

        Assert.True(EcommerceHmac.TryParseSignature(header, out var parsed));
        Assert.True(EcommerceHmac.SignaturesEqual(signature, parsed));
    }

    [Fact]
    public void SignaturesEqual_RejectsTamperedPayload()
    {
        var expected = EcommerceHmac.ComputeSignature(Secret, EcommerceHmac.CanonicalPost("1700000000", "{}"));
        var actual = EcommerceHmac.ComputeSignature(Secret, EcommerceHmac.CanonicalPost("1700000000", "{\"x\":1}"));
        Assert.False(EcommerceHmac.SignaturesEqual(expected, actual));
    }

    [Fact]
    public void TryParseSignature_RejectsGarbage()
    {
        Assert.False(EcommerceHmac.TryParseSignature("sha256=not-hex", out _));
        Assert.False(EcommerceHmac.TryParseSignature("", out _));
    }

    [Fact]
    public void IsTimestampFresh_RejectsReplayOutsideSkew()
    {
        var now = DateTimeOffset.FromUnixTimeSeconds(1_700_000_000);
        Assert.True(EcommerceHmac.IsTimestampFresh(1_700_000_000, now, TimeSpan.FromMinutes(5)));
        Assert.False(EcommerceHmac.IsTimestampFresh(1_700_000_000 - 301, now, TimeSpan.FromMinutes(5)));
        Assert.False(EcommerceHmac.IsTimestampFresh(1_700_000_000 + 301, now, TimeSpan.FromMinutes(5)));
    }
}
