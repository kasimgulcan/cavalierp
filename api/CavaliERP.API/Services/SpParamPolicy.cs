namespace CsmStok.Api.Services;

public enum SpParamPolicy
{
    /// <summary>Only parameters listed on the definition are accepted.</summary>
    Strict,

    /// <summary>Any client parameter is accepted except injected ones (UserId, Culture).</summary>
    Open,
}
