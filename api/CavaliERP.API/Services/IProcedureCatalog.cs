namespace CsmStok.Api.Services;

public interface IProcedureCatalog
{
    Task<ProcedureCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default);
}
