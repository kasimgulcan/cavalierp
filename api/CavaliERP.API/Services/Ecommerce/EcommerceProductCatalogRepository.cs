namespace CsmStok.Api.Services.Ecommerce;

public interface IEcommerceProductCatalogRepository
{
    Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken);
}

public sealed class EcommerceProductCatalogRepository(IConfiguration configuration) : IEcommerceProductCatalogRepository
{
    public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken)
    {
        _ = configuration;
        throw new NotImplementedException();
    }
}
