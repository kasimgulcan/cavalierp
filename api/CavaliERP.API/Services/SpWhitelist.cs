namespace CsmStok.Api.Services;

/// <summary>
/// Resolves mobile aliases (e.g. OrderRequest.List) to dbo.API_* procedures.
/// Auth endpoints and SQL name overrides stay explicit; everything else auto-resolves
/// when the procedure exists in SQL Server.
/// </summary>
public sealed class SpWhitelist(IConfiguration configuration)
{
    private static readonly HashSet<string> InjectedParams = new(StringComparer.OrdinalIgnoreCase)
    {
        "UserId",
        "Culture",
    };

    private static readonly string[] DefaultBlockedPrefixes =
    [
        "Membership.",
    ];

    private static readonly string[] DefaultStaffAliasPrefixes =
    [
        "Sale.",
        "OrderRequest.",
    ];

    private static readonly string[] DefaultPublicAliases =
    [
        "OrderRequest.Create",
    ];

    private static readonly string[] DefaultStaffExactAliases =
    [
        "Product.GetByBarcode",
    ];

    private static readonly IReadOnlyDictionary<string, SpDefinition> ExplicitDefinitions =
        new Dictionary<string, SpDefinition>(StringComparer.OrdinalIgnoreCase)
        {
            ["Auth.Register"] = new("Auth.Register", "API_Auth_Register",
                new HashSet<string> { "Email", "Password", "AcceptedTerms" }, false, false),
            ["Auth.Login"] = new("Auth.Login", "API_Auth_Login",
                new HashSet<string> { "Email", "Password" }, false, false),
            ["Auth.RefreshToken"] = new("Auth.RefreshToken", "API_Auth_RefreshToken",
                new HashSet<string> { "RefreshToken" }, false, false),
            ["Auth.DeleteAccount"] = new("Auth.DeleteAccount", "API_Auth_DeleteAccount",
                new HashSet<string>(), true, true),
            ["Auth.GetProfile"] = new("Auth.GetProfile", "API_Auth_GetProfile",
                new HashSet<string>(), true, true),
            ["GetCurrency"] = new("GetCurrency", "API_Get_Currency",
                new HashSet<string>(), false, false, false, SpParamPolicy.Open),
            ["Product.List"] = new("Product.List", "API_Product_List",
                new HashSet<string>(), false, false, false, SpParamPolicy.Open),
        };

    private readonly HashSet<string> _staffExactAliases = BuildStaffExactAliases(configuration);
    private readonly string[] _staffAliasPrefixes = BuildStaffAliasPrefixes(configuration);
    private readonly HashSet<string> _publicAliases = BuildPublicAliases(configuration);
    private readonly HashSet<string> _blockedPrefixes = BuildBlockedPrefixes(configuration);
    private readonly Dictionary<string, string> _sqlNameOverrides = BuildSqlNameOverrides(configuration);

    public async Task<(bool Found, SpDefinition? Definition)> TryResolveAsync(
        string alias,
        IProcedureCatalog catalog,
        CancellationToken cancellationToken = default)
    {
        if (IsBlocked(alias))
            return (false, null);

        if (ExplicitDefinitions.TryGetValue(alias, out var explicitDef))
            return (true, explicitDef);

        var sqlName = ResolveSqlNameForAlias(alias);
        var snapshot = await catalog.GetSnapshotAsync(cancellationToken);
        if (!snapshot.Exists(sqlName))
            return (false, null);

        var requiresUserId = snapshot.HasUserIdParameter(sqlName);
        var requiresStaff = RequiresStaff(alias);

        var autoDef = new SpDefinition(
            Alias: alias,
            SqlName: sqlName,
            AllowedParams: new HashSet<string>(StringComparer.OrdinalIgnoreCase),
            RequiresAuth: true,
            RequiresUserId: requiresUserId,
            RequiresStaff: requiresStaff,
            ParamPolicy: SpParamPolicy.Open);

        return (true, autoDef);
    }

    public string? ValidateParams(SpDefinition definition, Dictionary<string, object?>? parameters)
    {
        parameters ??= new Dictionary<string, object?>();

        foreach (var key in parameters.Keys)
        {
            if (InjectedParams.Contains(key))
                return $"Parameter '{key}' is not allowed from client.";

            if (definition.ParamPolicy == SpParamPolicy.Open)
                continue;

            if (!definition.AllowedParams.Contains(key))
                return $"Parameter '{key}' is not allowed for {definition.Alias}.";
        }

        return null;
    }

    public static string ResolveSqlName(string alias)
    {
        if (ExplicitDefinitions.TryGetValue(alias, out var explicitDef))
            return explicitDef.SqlName;

        return $"API_{alias.Replace('.', '_')}";
    }

    private string ResolveSqlNameForAlias(string alias)
    {
        if (_sqlNameOverrides.TryGetValue(alias, out var sqlName))
            return sqlName;

        return ResolveSqlName(alias);
    }

    private bool RequiresStaff(string alias)
    {
        if (_publicAliases.Contains(alias))
            return false;

        if (_staffExactAliases.Contains(alias))
            return true;

        foreach (var prefix in _staffAliasPrefixes)
        {
            if (alias.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                return true;
        }

        return false;
    }

    private bool IsBlocked(string alias)
    {
        foreach (var prefix in _blockedPrefixes)
        {
            if (alias.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                return true;
        }

        return false;
    }

    private static HashSet<string> BuildStaffExactAliases(IConfiguration configuration)
    {
        var aliases = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var alias in DefaultStaffExactAliases)
            aliases.Add(alias);

        var fromConfig = configuration.GetSection("SpGateway:StaffAliases").Get<string[]>();
        if (fromConfig is not null)
        {
            foreach (var alias in fromConfig)
                aliases.Add(alias);
        }

        return aliases;
    }

    private static string[] BuildStaffAliasPrefixes(IConfiguration configuration)
    {
        var fromConfig = configuration.GetSection("SpGateway:StaffAliasPrefixes").Get<string[]>();
        if (fromConfig is not null && fromConfig.Length > 0)
            return fromConfig;

        return DefaultStaffAliasPrefixes;
    }

    private static HashSet<string> BuildPublicAliases(IConfiguration configuration)
    {
        var aliases = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var alias in DefaultPublicAliases)
            aliases.Add(alias);

        var fromConfig = configuration.GetSection("SpGateway:PublicAliases").Get<string[]>();
        if (fromConfig is not null)
        {
            foreach (var alias in fromConfig)
                aliases.Add(alias);
        }

        return aliases;
    }

    private static HashSet<string> BuildBlockedPrefixes(IConfiguration configuration)
    {
        var prefixes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var prefix in DefaultBlockedPrefixes)
            prefixes.Add(prefix);

        var fromConfig = configuration.GetSection("SpGateway:BlockedAliasPrefixes").Get<string[]>();
        if (fromConfig is not null)
        {
            foreach (var prefix in fromConfig)
                prefixes.Add(prefix);
        }

        return prefixes;
    }

    private static Dictionary<string, string> BuildSqlNameOverrides(IConfiguration configuration)
    {
        var overrides = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var section = configuration.GetSection("SpGateway:SqlNameOverrides");
        foreach (var child in section.GetChildren())
        {
            if (!string.IsNullOrWhiteSpace(child.Value))
                overrides[child.Key] = child.Value;
        }

        return overrides;
    }
}
