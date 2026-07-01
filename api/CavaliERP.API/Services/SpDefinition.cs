namespace CsmStok.Api.Services;

public sealed record SpDefinition(
    string Alias,
    string SqlName,
    IReadOnlySet<string> AllowedParams,
    bool RequiresAuth,
    bool RequiresUserId,
    bool RequiresStaff = false,
    SpParamPolicy ParamPolicy = SpParamPolicy.Strict);
