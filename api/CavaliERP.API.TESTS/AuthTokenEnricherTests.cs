using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class AuthTokenEnricherTests
{
    [Fact]
    public void IsAuthTokenAlias_LoginRegisterRefresh_AreTrue()
    {
        Assert.True(AuthTokenEnricher.IsAuthTokenAlias("Auth.Login"));
        Assert.True(AuthTokenEnricher.IsAuthTokenAlias("Auth.Register"));
        Assert.True(AuthTokenEnricher.IsAuthTokenAlias("Auth.RefreshToken"));
        Assert.False(AuthTokenEnricher.IsAuthTokenAlias("Auth.GetProfile"));
    }

    [Fact]
    public void IncomingRefreshToken_OnlyForRefreshAlias()
    {
        var token = AuthTokenEnricher.IncomingRefreshToken(
            "Auth.RefreshToken",
            new Dictionary<string, object?> { ["RefreshToken"] = "abc" });
        Assert.Equal("abc", token);

        Assert.Null(AuthTokenEnricher.IncomingRefreshToken(
            "Auth.Login",
            new Dictionary<string, object?> { ["RefreshToken"] = "abc" }));
    }
}
