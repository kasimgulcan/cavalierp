using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("integrations/ecommerce/stock")]
public sealed class EcommerceStockController(EcommerceStockService stockService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Apply([FromBody] EcommerceStockUpdatedRequest request, CancellationToken ct)
    {
        try
        {
            var result = await stockService.ApplyAsync(request, ct);
            return StatusCode(result.StatusCode, ToBody(result));
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                success = false,
                error = "Unable to apply stock.",
            });
        }
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
