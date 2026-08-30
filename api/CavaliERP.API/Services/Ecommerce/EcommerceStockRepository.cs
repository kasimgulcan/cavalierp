using System.Data;
using CsmStok.Api.Models;
using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services.Ecommerce;

public interface IEcommerceStockRepository
{
    Task<EcommerceStockApplyResult> ApplyMovementAsync(
        Guid eventId,
        string eventType,
        string skuCode,
        int quantity,
        int? actorUserId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken);

    Task<IReadOnlyList<EcommerceOutboundRow>> DequeuePendingAsync(int take, CancellationToken cancellationToken);

    Task MarkOutboundSentAsync(long outboundId, CancellationToken cancellationToken);

    Task MarkOutboundAttemptAsync(long outboundId, string error, bool failed, CancellationToken cancellationToken);
}

public sealed class EcommerceStockRepository(IConfiguration configuration) : IEcommerceStockRepository
{
    private string ConnectionString => configuration.GetConnectionString("Default")
        ?? throw new InvalidOperationException("Connection string missing.");

    public async Task<EcommerceStockApplyResult> ApplyMovementAsync(
        Guid eventId,
        string eventType,
        string skuCode,
        int quantity,
        int? actorUserId,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand("API_WebHook_ApplyStock", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@EventId", eventId);
        command.Parameters.AddWithValue("@EventType", eventType);
        command.Parameters.AddWithValue("@SkuCode", skuCode);
        command.Parameters.AddWithValue("@Quantity", quantity);
        command.Parameters.AddWithValue("@UserId", actorUserId.HasValue ? actorUserId.Value : DBNull.Value);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
            return EcommerceStockApplyResult.Fail(StatusCodes.Status500InternalServerError, "Unable to apply stock.");

        var resultCode = reader.GetInt32(reader.GetOrdinal("ResultCode"));
        var resultType = reader.IsDBNull(reader.GetOrdinal("EventType"))
            ? eventType
            : reader.GetString(reader.GetOrdinal("EventType"));
        var resultSku = reader.IsDBNull(reader.GetOrdinal("SkuCode"))
            ? skuCode
            : reader.GetString(reader.GetOrdinal("SkuCode"));
        var resultQty = reader.IsDBNull(reader.GetOrdinal("Quantity"))
            ? quantity
            : Convert.ToInt32(reader.GetValue(reader.GetOrdinal("Quantity")));
        var onHand = reader.IsDBNull(reader.GetOrdinal("OnHand"))
            ? 0
            : Convert.ToInt32(reader.GetValue(reader.GetOrdinal("OnHand")));
        var error = reader.IsDBNull(reader.GetOrdinal("ErrorMessage"))
            ? null
            : reader.GetString(reader.GetOrdinal("ErrorMessage"));

        if (resultCode is >= 200 and < 300)
            return EcommerceStockApplyResult.Ok(resultType, resultSku, resultQty, onHand);

        return EcommerceStockApplyResult.Fail(
            resultCode,
            string.IsNullOrWhiteSpace(error) ? "Unable to apply stock." : error,
            resultType,
            resultSku,
            resultQty,
            onHand);
    }

    public async Task<IReadOnlyList<EcommerceStockSnapshotItem>> GetSnapshotAsync(CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand("API_WebHook_StockSnapshot", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        var items = new List<EcommerceStockSnapshotItem>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            items.Add(new EcommerceStockSnapshotItem
            {
                SkuCode = reader.GetString(reader.GetOrdinal("SkuCode")),
                Quantity = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("Quantity"))),
            });
        }

        return items;
    }

    public async Task<IReadOnlyList<EcommerceOutboundRow>> DequeuePendingAsync(int take, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("API_WebHook_OutboundDequeue", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@Take", take);

        var rows = new List<EcommerceOutboundRow>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new EcommerceOutboundRow
            {
                OutboundId = Convert.ToInt64(reader.GetValue(reader.GetOrdinal("OutboundId"))),
                EventId = reader.GetGuid(reader.GetOrdinal("EventId")),
                EventType = reader.GetString(reader.GetOrdinal("EventType")),
                SizeId = reader.GetInt32(reader.GetOrdinal("SizeId")),
                SkuCode = reader.GetString(reader.GetOrdinal("SkuCode")),
                Quantity = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("Quantity"))),
                OnHand = Convert.ToInt32(reader.GetValue(reader.GetOrdinal("OnHand"))),
                CreatedAt = ReadTimestamp(reader, "CreatedAt"),
                Attempts = reader.GetInt32(reader.GetOrdinal("Attempts")),
            });
        }

        return rows;
    }

    public async Task MarkOutboundSentAsync(long outboundId, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("API_WebHook_OutboundMarkSent", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@OutboundId", outboundId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task MarkOutboundAttemptAsync(long outboundId, string error, bool failed, CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("API_WebHook_OutboundMarkAttempt", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@OutboundId", outboundId);
        command.Parameters.AddWithValue("@Error", (object?)error ?? DBNull.Value);
        command.Parameters.AddWithValue("@Failed", failed);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static DateTimeOffset ReadTimestamp(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        if (reader.IsDBNull(ordinal))
            return DateTimeOffset.UtcNow;

        var value = reader.GetValue(ordinal);
        return value switch
        {
            DateTimeOffset dto => dto,
            DateTime dt => new DateTimeOffset(DateTime.SpecifyKind(dt, DateTimeKind.Utc)),
            _ => DateTimeOffset.UtcNow,
        };
    }
}
