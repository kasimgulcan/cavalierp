using System.Net;
using System.Text;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Tests;

public class EcommerceHmacMiddlewareTests
{
    private const string Secret = "test-shared-secret-value-32chars!!";

    [Fact]
    public async Task Disabled_Returns404_AndDoesNotCallNext()
    {
        var (called, status) = await InvokeAsync(
            new EcommerceSyncOptions { Enabled = false, SharedSecret = Secret },
            "GET",
            "/integrations/ecommerce/stock/snapshot",
            body: "",
            sign: false);

        Assert.False(called);
        Assert.Equal(StatusCodes.Status404NotFound, status);
    }

    [Fact]
    public async Task MissingSignature_Returns401()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var (called, status) = await InvokeAsync(
            EnabledOptions(),
            "POST",
            "/integrations/ecommerce/stock",
            body: "{}",
            sign: false,
            timestamp: timestamp);

        Assert.False(called);
        Assert.Equal(StatusCodes.Status401Unauthorized, status);
    }

    [Fact]
    public async Task FakeSignature_Returns401()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var (called, status) = await InvokeAsync(
            EnabledOptions(),
            "POST",
            "/integrations/ecommerce/stock",
            body: "{}",
            sign: false,
            timestamp: timestamp,
            signature: "sha256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");

        Assert.False(called);
        Assert.Equal(StatusCodes.Status401Unauthorized, status);
    }

    [Fact]
    public async Task ExpiredTimestamp_Returns401()
    {
        var timestamp = DateTimeOffset.UtcNow.AddMinutes(-10).ToUnixTimeSeconds().ToString();
        var body = "{}";
        var canonical = EcommerceHmac.CanonicalPost(timestamp, body);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));

        var (called, status) = await InvokeAsync(
            EnabledOptions(),
            "POST",
            "/integrations/ecommerce/stock",
            body,
            sign: false,
            timestamp: timestamp,
            signature: signature);

        Assert.False(called);
        Assert.Equal(StatusCodes.Status401Unauthorized, status);
    }

    [Fact]
    public async Task ValidPostSignature_CallsNext()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var body = """{"eventId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","item":{"skuCode":"ABC_XL","quantity":1}}""";
        var canonical = EcommerceHmac.CanonicalPost(timestamp, body);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));

        var (called, status) = await InvokeAsync(
            EnabledOptions(),
            "POST",
            "/integrations/ecommerce/stock",
            body,
            sign: false,
            timestamp: timestamp,
            signature: signature,
            nextStatus: StatusCodes.Status200OK);

        Assert.True(called);
        Assert.Equal(StatusCodes.Status200OK, status);
    }

    [Fact]
    public async Task ValidPostSignature_StoresRawBodyInHttpContext()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var body = """{"eventId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","item":{"skuCode":"ABC_XL","quantity":1}}""";
        var canonical = EcommerceHmac.CanonicalPost(timestamp, body);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));
        object? stored = null;

        RequestDelegate next = ctx =>
        {
            stored = ctx.Items[EcommerceHmacMiddleware.RawBodyItemsKey];
            ctx.Response.StatusCode = StatusCodes.Status200OK;
            return Task.CompletedTask;
        };

        var middleware = new EcommerceHmacMiddleware(
            next,
            Options.Create(EnabledOptions()),
            NullLogger<EcommerceHmacMiddleware>.Instance);

        var context = new DefaultHttpContext();
        context.Request.Method = "POST";
        context.Request.Path = "/integrations/ecommerce/stock";
        context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body));
        context.Request.ContentLength = Encoding.UTF8.GetByteCount(body);
        context.Response.Body = new MemoryStream();
        context.Connection.RemoteIpAddress = IPAddress.Loopback;
        context.Request.Headers[EcommerceHmac.TimestampHeader] = timestamp;
        context.Request.Headers[EcommerceHmac.SignatureHeader] = signature;

        await middleware.InvokeAsync(context);

        Assert.Equal(body, stored);
    }

    [Fact]
    public async Task ValidGetSignature_CallsNext()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var path = "/integrations/ecommerce/stock/snapshot";
        var canonical = EcommerceHmac.CanonicalGet(timestamp, path);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));

        var (called, status) = await InvokeAsync(
            EnabledOptions(),
            "GET",
            path,
            body: "",
            sign: false,
            timestamp: timestamp,
            signature: signature,
            nextStatus: StatusCodes.Status200OK);

        Assert.True(called);
        Assert.Equal(StatusCodes.Status200OK, status);
    }

    [Fact]
    public async Task IpAllowlist_BlocksOtherAddress()
    {
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var body = "{}";
        var canonical = EcommerceHmac.CanonicalPost(timestamp, body);
        var signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));

        var (called, status) = await InvokeAsync(
            new EcommerceSyncOptions
            {
                Enabled = true,
                SharedSecret = Secret,
                AllowedCidrs = ["10.0.0.0/8"],
            },
            "POST",
            "/integrations/ecommerce/stock",
            body,
            sign: false,
            timestamp: timestamp,
            signature: signature,
            remoteIp: IPAddress.Parse("203.0.113.9"));

        Assert.False(called);
        Assert.Equal(StatusCodes.Status401Unauthorized, status);
    }

    private static EcommerceSyncOptions EnabledOptions() => new()
    {
        Enabled = true,
        SharedSecret = Secret,
        TimestampSkewMinutes = 5,
    };

    private static async Task<(bool NextCalled, int StatusCode)> InvokeAsync(
        EcommerceSyncOptions options,
        string method,
        string path,
        string body,
        bool sign,
        string? timestamp = null,
        string? signature = null,
        int nextStatus = StatusCodes.Status204NoContent,
        IPAddress? remoteIp = null)
    {
        var nextCalled = false;
        RequestDelegate next = ctx =>
        {
            nextCalled = true;
            ctx.Response.StatusCode = nextStatus;
            return Task.CompletedTask;
        };

        var middleware = new EcommerceHmacMiddleware(
            next,
            Options.Create(options),
            NullLogger<EcommerceHmacMiddleware>.Instance);

        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Path = path;
        context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(body));
        context.Request.ContentLength = Encoding.UTF8.GetByteCount(body);
        context.Response.Body = new MemoryStream();
        context.Connection.RemoteIpAddress = remoteIp ?? IPAddress.Loopback;

        timestamp ??= DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        context.Request.Headers[EcommerceHmac.TimestampHeader] = timestamp;

        if (sign)
        {
            var canonical = method == "GET"
                ? EcommerceHmac.CanonicalGet(timestamp, path)
                : EcommerceHmac.CanonicalPost(timestamp, body);
            signature = EcommerceHmac.FormatSignatureHeader(EcommerceHmac.ComputeSignature(Secret, canonical));
        }

        if (signature is not null)
            context.Request.Headers[EcommerceHmac.SignatureHeader] = signature;

        await middleware.InvokeAsync(context);
        return (nextCalled, context.Response.StatusCode);
    }
}
