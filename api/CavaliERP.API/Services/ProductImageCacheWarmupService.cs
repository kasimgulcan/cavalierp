namespace CsmStok.Api.Services;

public sealed class ProductImageCacheWarmupService(
    ProductImageCatalog productImageCatalog,
    ILogger<ProductImageCacheWarmupService> logger) : IHostedService
{
    public Task StartAsync(CancellationToken cancellationToken)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await productImageCatalog.GetImagesAsync(cancellationToken);
                logger.LogInformation("Product image feed cache warmed on startup.");
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                // App shutting down during warmup.
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Product image feed warmup failed; will retry on demand.");
            }
        }, cancellationToken);

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
