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

    Task MarkOutboundSentAsync(
        long outboundId,
        string? requestUrl,
        string? requestJson,
        int httpStatus,
        string? responseJson,
        CancellationToken cancellationToken);

    Task MarkOutboundAttemptAsync(
        long outboundId,
        string error,
        bool failed,
        string? requestUrl,
        string? requestJson,
        int? httpStatus,
        string? responseJson,
        CancellationToken cancellationToken);

    Task SaveInboundHttpAsync(
        Guid eventId,
        string? requestJson,
        int httpStatus,
        string? responseJson,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListInboundHttpAsync(int take, CancellationToken cancellationToken);

    Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListOutboundHttpAsync(int take, CancellationToken cancellationToken);
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

    public async Task MarkOutboundSentAsync(
        long outboundId,
        string? requestUrl,
        string? requestJson,
        int httpStatus,
        string? responseJson,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("API_WebHook_OutboundMarkSent", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@OutboundId", outboundId);
        AddOptional(command, "@RequestUrl", requestUrl);
        AddOptional(command, "@RequestJson", requestJson);
        command.Parameters.AddWithValue("@HttpStatus", httpStatus);
        AddOptional(command, "@ResponseJson", responseJson);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task MarkOutboundAttemptAsync(
        long outboundId,
        string error,
        bool failed,
        string? requestUrl,
        string? requestJson,
        int? httpStatus,
        string? responseJson,
        CancellationToken cancellationToken)
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
        AddOptional(command, "@RequestUrl", requestUrl);
        AddOptional(command, "@RequestJson", requestJson);
        command.Parameters.AddWithValue("@HttpStatus", httpStatus.HasValue ? httpStatus.Value : DBNull.Value);
        AddOptional(command, "@ResponseJson", responseJson);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task SaveInboundHttpAsync(
        Guid eventId,
        string? requestJson,
        int httpStatus,
        string? responseJson,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand("API_WebHook_InboundSaveHttp", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@EventId", eventId);
        AddOptional(command, "@RequestJson", requestJson);
        command.Parameters.AddWithValue("@HttpStatus", httpStatus);
        AddOptional(command, "@ResponseJson", responseJson);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListInboundHttpAsync(int take, CancellationToken cancellationToken) =>
        ListHttpAsync("API_WebHook_InboundListHttp", "inbound", take, cancellationToken);

    public Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListOutboundHttpAsync(int take, CancellationToken cancellationToken) =>
        ListHttpAsync("API_WebHook_OutboundListHttp", "outbound", take, cancellationToken);

    private async Task<IReadOnlyList<EcommerceWebhookHttpLog>> ListHttpAsync(
        string procedure,
        string direction,
        int take,
        CancellationToken cancellationToken)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand(procedure, connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@Take", take);

        var rows = new List<EcommerceWebhookHttpLog>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new EcommerceWebhookHttpLog
            {
                Id = Convert.ToInt64(reader.GetValue(reader.GetOrdinal("Id"))),
                EventId = reader.GetGuid(reader.GetOrdinal("EventId")),
                Direction = direction,
                EventType = ReadString(reader, "EventType"),
                SkuCode = ReadString(reader, "SkuCode"),
                RequestUrl = HasColumn(reader, "RequestUrl") ? ReadString(reader, "RequestUrl") : null,
                RequestJson = ReadString(reader, "RequestJson"),
                HttpStatus = ReadInt(reader, "HttpStatus"),
                ResponseJson = ReadString(reader, "ResponseJson"),
                At = ReadTimestamp(reader, "At"),
            });
        }

        return rows;
    }

    private static void AddOptional(SqlCommand command, string name, string? value) =>
        command.Parameters.AddWithValue(name, string.IsNullOrEmpty(value) ? DBNull.Value : value);

    private static bool HasColumn(SqlDataReader reader, string name)
    {
        for (var i = 0; i < reader.FieldCount; i++)
        {
            if (string.Equals(reader.GetName(i), name, StringComparison.OrdinalIgnoreCase))
                return true;
        }

        return false;
    }

    private static string? ReadString(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);
    }

    private static int? ReadInt(SqlDataReader reader, string name)
    {
        var ordinal = reader.GetOrdinal(name);
        return reader.IsDBNull(ordinal) ? null : Convert.ToInt32(reader.GetValue(ordinal));
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
