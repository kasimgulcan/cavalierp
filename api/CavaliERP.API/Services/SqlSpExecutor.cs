using System.Data;
using System.Text.Json;
using CsmStok.Api.Models;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services;

public sealed class SqlSpExecutor(IConfiguration configuration)
{
    private string ConnectionString => configuration.GetConnectionString("Default")
        ?? throw new InvalidOperationException("Connection string missing.");

    public async Task<ExecSpResponse> ExecuteAsync(
        SpDefinition definition,
        Dictionary<string, object?> parameters,
        CancellationToken cancellationToken = default)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(definition.SqlName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        foreach (var (key, value) in parameters)
        {
            command.Parameters.AddWithValue($"@{key}", ConvertParameter(value) ?? DBNull.Value);
        }

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<Dictionary<string, object?>>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var row = new Dictionary<string, object?>();
            for (var i = 0; i < reader.FieldCount; i++)
                row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            rows.Add(row);
        }

        return ExecSpResponse.Ok(rows);
    }

    public static object? ConvertParameter(object? value)
    {
        if (value is JsonElement element)
        {
            return element.ValueKind switch
            {
                JsonValueKind.String => element.GetString(),
                JsonValueKind.Number => element.TryGetInt64(out var l) ? l : element.GetDecimal(),
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                JsonValueKind.Null => null,
                _ => element.GetRawText()
            };
        }

        return value;
    }
}
