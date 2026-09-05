using System.Text;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceHmacMiddleware(
    RequestDelegate next,
    IOptions<EcommerceSyncOptions> options,
    ILogger<EcommerceHmacMiddleware> logger)
{
    public const int MaxBodyBytes = 64 * 1024;
    public const string RawBodyItemsKey = "EcommerceRawBody";

    public async Task InvokeAsync(HttpContext context)
    {
        var opts = options.Value;
        if (!opts.Enabled)
        {
            await WriteJsonAsync(context, StatusCodes.Status404NotFound, "Not found.");
            return;
        }

        if (string.IsNullOrWhiteSpace(opts.SharedSecret))
        {
            logger.LogWarning("EcommerceSync is enabled but SharedSecret is missing.");
            await WriteUnauthorizedAsync(context);
            return;
        }

        if (!EcommerceIpAllowlist.IsAllowed(context.Connection.RemoteIpAddress, opts.AllowedCidrs))
        {
            await WriteUnauthorizedAsync(context);
            return;
        }

        var timestampHeader = context.Request.Headers[EcommerceHmac.TimestampHeader].ToString().Trim();
        if (!EcommerceHmac.TryParseTimestamp(timestampHeader, out var unixSeconds))
        {
            await WriteUnauthorizedAsync(context);
            return;
        }

        var skew = TimeSpan.FromMinutes(Math.Max(1, opts.TimestampSkewMinutes));
        if (!EcommerceHmac.IsTimestampFresh(unixSeconds, DateTimeOffset.UtcNow, skew))
        {
            await WriteUnauthorizedAsync(context);
            return;
        }

        string canonical;

        if (HttpMethods.IsGet(context.Request.Method))
        {
            canonical = EcommerceHmac.CanonicalGet(timestampHeader, context.Request.Path.Value ?? "/");
        }
        else if (HttpMethods.IsPost(context.Request.Method))
        {
            if (context.Request.ContentLength > MaxBodyBytes)
            {
                await WriteJsonAsync(context, StatusCodes.Status400BadRequest, "Request body too large.");
                return;
            }

            context.Request.EnableBuffering();
            using var reader = new StreamReader(context.Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, bufferSize: 1024, leaveOpen: true);
            var body = await reader.ReadToEndAsync(context.RequestAborted);
            if (Encoding.UTF8.GetByteCount(body) > MaxBodyBytes)
            {
                await WriteJsonAsync(context, StatusCodes.Status400BadRequest, "Request body too large.");
                return;
            }

            context.Request.Body.Position = 0;
            context.Items[RawBodyItemsKey] = body;
            canonical = EcommerceHmac.CanonicalPost(timestampHeader, body);
        }
        else
        {
            await WriteUnauthorizedAsync(context);
            return;
        }

        var expected = EcommerceHmac.ComputeSignature(opts.SharedSecret, canonical);
        if (!EcommerceHmac.TryParseSignature(context.Request.Headers[EcommerceHmac.SignatureHeader], out var actual)
            || !EcommerceHmac.SignaturesEqual(expected, actual))
        {
            await WriteUnauthorizedAsync(context);
            return;
        }

        await next(context);
    }

    private static Task WriteUnauthorizedAsync(HttpContext context) =>
        WriteJsonAsync(context, StatusCodes.Status401Unauthorized, "Authentication required.");

    private static async Task WriteJsonAsync(HttpContext context, int statusCode, string error)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { success = false, error });
    }
}
