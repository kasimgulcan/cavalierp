using System.Text;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CsmStok.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("tester")]
public sealed class EcommerceTesterController(
    EcommerceShopSimulator shop,
    EcommerceTesterInbox inbox,
    IOptions<EcommerceSyncOptions> options) : ControllerBase
{
    [HttpGet("api/info")]
    public IActionResult Info()
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        var opts = options.Value;
        var origin = $"{Request.Scheme}://{Request.Host}{Request.PathBase}".TrimEnd('/');
        return Ok(new
        {
            syncEnabled = opts.Enabled,
            testerEnabled = opts.TesterEnabled,
            subscriberUrl = $"{origin}/tester/stock-events/",
            configuredSubscriberUrl = opts.SubscriberUrl,
        });
    }

    [HttpPost("api/snapshot")]
    public async Task<IActionResult> Snapshot(CancellationToken ct)
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        var result = await shop.GetSnapshotAsync(ApiBase(), ct);
        return Proxy(result);
    }

    [HttpPost("api/product-catalog")]
    public async Task<IActionResult> ProductCatalog(CancellationToken ct)
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        var result = await shop.GetProductCatalogAsync(ApiBase(), ct);
        return Proxy(result);
    }

    [HttpPost("api/apply")]
    public async Task<IActionResult> Apply([FromBody] TesterApplyRequest request, CancellationToken ct)
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        var eventType = (request.EventType ?? "").Trim().ToLowerInvariant();
        if (eventType is not ("sale.created" or "return.created"))
            return BadRequest(new { success = false, error = "eventType must be sale.created or return.created." });

        var sku = (request.SkuCode ?? "").Trim();
        if (sku.Length == 0)
            return BadRequest(new { success = false, error = "skuCode is required." });

        if (request.Quantity is null or < 1)
            return BadRequest(new { success = false, error = "quantity must be at least 1." });

        var eventId = request.EventId is null || request.EventId == Guid.Empty
            ? Guid.NewGuid()
            : request.EventId.Value;

        var result = await shop.ApplyAsync(
            ApiBase(),
            eventType,
            sku,
            request.Quantity.Value,
            eventId,
            DateTimeOffset.UtcNow,
            ct);
        return Proxy(result);
    }

    [HttpGet("api/inbox")]
    public IActionResult Inbox()
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        return Ok(new { items = inbox.List() });
    }

    [HttpPost("stock-events")]
    public async Task<IActionResult> ReceivePush(CancellationToken ct)
    {
        if (Closed())
            return NotFound(new { success = false, error = "Not found." });

        using var reader = new StreamReader(Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true);
        var body = await reader.ReadToEndAsync(ct);

        var timestamp = Request.Headers[EcommerceHmac.TimestampHeader].ToString().Trim();
        var signature = Request.Headers[EcommerceHmac.SignatureHeader].ToString().Trim();
        var hmacValid = IsValidPost(timestamp, signature, body);
        var status = hmacValid ? StatusCodes.Status200OK : StatusCodes.Status401Unauthorized;

        inbox.Add(new EcommerceTesterInboxItem
        {
            ReceivedAt = DateTimeOffset.UtcNow,
            HmacValid = hmacValid,
            StatusCode = status,
            Body = body,
            Timestamp = timestamp,
            Signature = signature,
        });

        return StatusCode(status, new { success = hmacValid, error = hmacValid ? null : "Authentication required." });
    }

    private bool Closed() => !options.Value.TesterEnabled;

    private string ApiBase() => $"{Request.Scheme}://{Request.Host}{Request.PathBase}".TrimEnd('/');

    private IActionResult Proxy(ShopCallResult result) =>
        new ContentResult
        {
            StatusCode = result.StatusCode,
            ContentType = "application/json; charset=utf-8",
            Content = string.IsNullOrEmpty(result.Body) ? "{}" : result.Body,
        };

    private bool IsValidPost(string timestampHeader, string signatureHeader, string body)
    {
        var opts = options.Value;
        if (string.IsNullOrWhiteSpace(opts.SharedSecret))
            return false;
        if (!EcommerceHmac.TryParseTimestamp(timestampHeader, out var unixSeconds))
            return false;

        var skew = TimeSpan.FromMinutes(Math.Max(1, opts.TimestampSkewMinutes));
        if (!EcommerceHmac.IsTimestampFresh(unixSeconds, DateTimeOffset.UtcNow, skew))
            return false;

        var expected = EcommerceHmac.ComputeSignature(opts.SharedSecret, EcommerceHmac.CanonicalPost(timestampHeader, body));
        return EcommerceHmac.TryParseSignature(signatureHeader, out var actual)
            && EcommerceHmac.SignaturesEqual(expected, actual);
    }
}

public sealed class TesterApplyRequest
{
    public Guid? EventId { get; set; }
    public string? EventType { get; set; }
    public string? SkuCode { get; set; }
    public int? Quantity { get; set; }
}
