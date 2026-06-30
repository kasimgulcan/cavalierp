namespace CsmStok.Api.Models;

public sealed record TokenResult(string AccessToken, string RefreshToken, DateTime ExpiresAt);
