namespace CsmStok.Api.Services;

public sealed class SpWhitelist
{
    private static readonly IReadOnlyDictionary<string, SpDefinition> Definitions =
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
            ["Product.GetByBarcode"] = new("Product.GetByBarcode", "API_Product_GetByBarcode",
                new HashSet<string> { "Barcode", "CurrencyId" }, true, false, true),
            ["Product.List"] = new("Product.List", "API_Product_List",
                new HashSet<string> { "Search", "CurrencyId", "Page", "PageSize" }, true, false),
            ["GetCurrency"] = new("GetCurrency", "API_Get_Currency",
                new HashSet<string>(), true, false),
            ["Lookup.Customers"] = new("Lookup.Customers", "API_Lookup_Customers",
                new HashSet<string> { "Search" }, true, false),
            ["Lookup.PaymentTypes"] = new("Lookup.PaymentTypes", "API_Lookup_PaymentTypes",
                new HashSet<string>(), true, false),
            ["Sale.Create"] = new("Sale.Create", "API_Sale_Create",
                new HashSet<string> { "CurrencyId", "Customer", "PaymentTypeId", "Lines", "Note" }, true, true, true),
            ["OrderRequest.Create"] = new("OrderRequest.Create", "API_OrderRequest_Create",
                new HashSet<string> { "CurrencyId", "Customer", "Note", "Lines" }, true, true),
        };

    public bool TryGet(string alias, out SpDefinition? definition)
    {
        if (Definitions.TryGetValue(alias, out var def))
        {
            definition = def;
            return true;
        }

        definition = null;
        return false;
    }

    public string? ValidateParams(SpDefinition definition, Dictionary<string, object?>? parameters)
    {
        parameters ??= new Dictionary<string, object?>();
        var injected = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "UserId", "Culture"
        };

        foreach (var key in parameters.Keys)
        {
            if (injected.Contains(key))
                return $"Parameter '{key}' is not allowed from client.";

            if (!definition.AllowedParams.Contains(key))
                return $"Parameter '{key}' is not allowed for {definition.Alias}.";
        }

        return null;
    }
}
