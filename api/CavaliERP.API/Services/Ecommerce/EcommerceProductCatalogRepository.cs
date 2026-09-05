using System.Data;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services.Ecommerce;

public interface IEcommerceProductCatalogRepository
{
    Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken);
}

public sealed class EcommerceProductCatalogRepository(IConfiguration configuration) : IEcommerceProductCatalogRepository
{
    private string ConnectionString => configuration.GetConnectionString("Default")
        ?? throw new InvalidOperationException("Connection string missing.");

    public async Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand("GetSKUSnapshot", connection)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 120,
        };

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var sets = new List<IReadOnlyList<IReadOnlyDictionary<string, object?>>>();
        do
        {
            var rows = new List<IReadOnlyDictionary<string, object?>>();
            while (await reader.ReadAsync(cancellationToken))
                rows.Add(EcommerceProductCatalogMapper.ReadRow(reader));
            sets.Add(rows);
        }
        while (await reader.NextResultAsync(cancellationToken));

        return EcommerceProductCatalogMapper.FromResultSets(sets);
    }
}
