using System.Text.Json;
using System.Text.Json.Serialization;
using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("integrations/ecommerce/stock")]
public sealed class EcommerceStockController(
    EcommerceStockService stockService,
    IEcommerceStockRepository repository,
    ILogger<EcommerceStockController> logger) : ControllerBase
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    [HttpPost]
    public async Task<IActionResult> Apply([FromBody] EcommerceStockUpdatedRequest request, CancellationToken ct)
    {
        object body;
        int status;
        try
        {
            var result = await stockService.ApplyAsync(request, ct);
            status = result.StatusCode;
            body = ToBody(result);
        }
        catch (Exception)
        {
            status = StatusCodes.Status500InternalServerError;
            body = new { success = false, error = "Unable to apply stock." };
        }

        await SaveInboundHttpAsync(request, status, body, ct);
        return StatusCode(status, body);
    }

    [HttpGet("snapshot")]
    public async Task<IActionResult> Snapshot(CancellationToken ct)
    {
        try
        {
            var items = await stockService.GetSnapshotAsync(ct);
            return Ok(new
            {
                generatedAt = DateTimeOffset.UtcNow,
                source = "cavalierp",
                items,
            });
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                success = false,
                error = "Unable to load snapshot.",
            });
        }
    }

    private async Task SaveInboundHttpAsync(
        EcommerceStockUpdatedRequest? request,
        int status,
        object responseBody,
        CancellationToken cancellationToken)
    {
        var eventId = request?.EventId;
        if (eventId is null || eventId == Guid.Empty)
            return;

        try
        {
            var requestJson = HttpContext.Items[EcommerceHmacMiddleware.RawBodyItemsKey] as string
                ?? JsonSerializer.Serialize(request, JsonOptions);
            var responseJson = JsonSerializer.Serialize(responseBody, JsonOptions);
            await repository.SaveInboundHttpAsync(eventId.Value, requestJson, status, responseJson, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to persist inbound webhook HTTP log for {EventId}.", eventId);
        }
    }

    private static object ToBody(EcommerceStockApplyResult result)
    {
        if (result.Success)
        {
            return new
            {
                success = true,
                eventType = result.EventType,
                skuCode = result.SkuCode,
                quantity = result.Quantity,
                onHand = result.OnHand,
            };
        }

        return new
        {
            success = false,
            error = result.Error,
        };
    }
}
