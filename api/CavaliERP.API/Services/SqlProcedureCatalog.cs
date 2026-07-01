using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services;

public sealed class SqlProcedureCatalog(IConfiguration configuration, ILogger<SqlProcedureCatalog> logger)
    : IProcedureCatalog
{
    private readonly SemaphoreSlim _lock = new(1, 1);
    private ProcedureCatalogSnapshot? _snapshot;
    private DateTime _loadedAtUtc;

    public async Task<ProcedureCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default)
    {
        var cacheMinutes = configuration.GetValue("SpGateway:CacheMinutes", 5);
        var snapshot = _snapshot;
        if (snapshot is not null && DateTime.UtcNow - _loadedAtUtc < TimeSpan.FromMinutes(cacheMinutes))
            return snapshot;

        await _lock.WaitAsync(cancellationToken);
        try
        {
            snapshot = _snapshot;
            if (snapshot is not null && DateTime.UtcNow - _loadedAtUtc < TimeSpan.FromMinutes(cacheMinutes))
                return snapshot;

            snapshot = await LoadFromDatabaseAsync(cancellationToken);
            _snapshot = snapshot;
            _loadedAtUtc = DateTime.UtcNow;
            return snapshot;
        }
        finally
        {
            _lock.Release();
        }
    }

    public void Invalidate() => _snapshot = null;

    private async Task<ProcedureCatalogSnapshot> LoadFromDatabaseAsync(CancellationToken cancellationToken)
    {
        var connectionString = configuration.GetConnectionString("Default");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            logger.LogWarning("SpGateway: connection string missing; auto-resolved API procedures disabled.");
            return ProcedureCatalogSnapshot.Empty;
        }

        const string sql = """
            SELECT
                p.name AS ProcedureName,
                HasUserId = CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM sys.parameters pr
                        WHERE pr.object_id = p.object_id
                          AND pr.name = '@UserId'
                    ) THEN 1
                    ELSE 0
                END
            FROM sys.procedures p
            WHERE SCHEMA_NAME(p.schema_id) = 'dbo'
              AND p.name LIKE 'API[_]%'
            """;

        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var withUserId = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        try
        {
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = new SqlCommand(sql, connection);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var name = reader.GetString(0);
                names.Add(name);
                if (reader.GetInt32(1) == 1)
                    withUserId.Add(name);
            }

            logger.LogInformation("SpGateway catalog loaded: {Count} API_* procedures.", names.Count);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "SpGateway catalog could not be loaded; auto-resolved API procedures disabled.");
            return ProcedureCatalogSnapshot.Empty;
        }

        return new ProcedureCatalogSnapshot(names, withUserId);
    }
}

public sealed class ProcedureCatalogSnapshot
{
    public static ProcedureCatalogSnapshot Empty { get; } =
        new(new HashSet<string>(StringComparer.OrdinalIgnoreCase),
            new HashSet<string>(StringComparer.OrdinalIgnoreCase));

    public ProcedureCatalogSnapshot(
        IReadOnlySet<string> procedureNames,
        IReadOnlySet<string> proceduresWithUserId)
    {
        ProcedureNames = procedureNames;
        ProceduresWithUserId = proceduresWithUserId;
    }

    public IReadOnlySet<string> ProcedureNames { get; }
    public IReadOnlySet<string> ProceduresWithUserId { get; }

    public bool Exists(string sqlName) => ProcedureNames.Contains(sqlName);

    public bool HasUserIdParameter(string sqlName) => ProceduresWithUserId.Contains(sqlName);
}
