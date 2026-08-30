using Microsoft.Data.SqlClient;

namespace CsmStok.Api.Services;

public sealed class SqlRefreshTokenStore(IConfiguration configuration) : IRefreshTokenStore
{
    public async Task SaveAsync(
        int userId,
        string token,
        DateTime expiresAt,
        CancellationToken cancellationToken = default)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string missing.");

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand(
            """
            INSERT INTO dbo.RefreshTokens (UserId, Token, ExpiresAt, CreatedAt)
            VALUES (@UserId, @Token, @ExpiresAt, GETDATE())
            """,
            connection);
        command.Parameters.AddWithValue("@UserId", userId);
        command.Parameters.AddWithValue("@Token", token);
        command.Parameters.AddWithValue("@ExpiresAt", expiresAt);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task RevokeAsync(string token, CancellationToken cancellationToken = default)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Connection string missing.");

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = new SqlCommand(
            "DELETE FROM dbo.RefreshTokens WHERE Token = @Token",
            connection);
        command.Parameters.AddWithValue("@Token", token);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
