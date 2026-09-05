using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("integrations/ecommerce/products")]
public sealed class EcommerceProductCatalogController(
    IEcommerceProductCatalogRepository repository,
    ILogger<EcommerceProductCatalogController> logger) : ControllerBase
{
    [HttpGet("snapshot")]
    public async Task<IActionResult> Snapshot(CancellationToken ct)
    {
        try
        {
            var snapshot = await repository.GetSnapshotAsync(ct);
            return Ok(new
            {
                generatedAt = DateTimeOffset.UtcNow,
                source = "cavalierp",
                skus = snapshot.Skus,
                styleModels = snapshot.StyleModels,
                models = snapshot.Models,
            });
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unable to load product catalog.");
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                success = false,
                error = "Unable to load product catalog.",
            });
        }
    }
}
