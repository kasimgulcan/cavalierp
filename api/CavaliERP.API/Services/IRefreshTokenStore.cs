namespace CsmStok.Api.Services;

public interface IRefreshTokenStore
{
    Task SaveAsync(int userId, string token, DateTime expiresAt, CancellationToken cancellationToken = default);
    Task RevokeAsync(string token, CancellationToken cancellationToken = default);
}
