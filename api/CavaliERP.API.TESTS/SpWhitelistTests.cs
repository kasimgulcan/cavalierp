using CsmStok.Api.Services;
using Microsoft.Extensions.Configuration;

namespace CsmStok.Api.Tests;

public class SpWhitelistTests
{
    private static SpWhitelist CreateWhitelist() =>
        new(new ConfigurationBuilder().Build());

    private static ProcedureCatalogSnapshot CatalogWith(params string[] sqlNames)
    {
        var names = new HashSet<string>(sqlNames, StringComparer.OrdinalIgnoreCase);
        return new ProcedureCatalogSnapshot(names, new HashSet<string>(StringComparer.OrdinalIgnoreCase));
    }

    private sealed class FakeProcedureCatalog(ProcedureCatalogSnapshot snapshot) : IProcedureCatalog
    {
        public Task<ProcedureCatalogSnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(snapshot);
    }

    private static IProcedureCatalog EmptyCatalog() =>
        new FakeProcedureCatalog(ProcedureCatalogSnapshot.Empty);

    private static IProcedureCatalog Catalog(params string[] sqlNames) =>
        new FakeProcedureCatalog(CatalogWith(sqlNames));

    [Fact]
    public void ResolveSqlName_KnownAlias_ReturnsApiProcedureName()
    {
        Assert.Equal("API_Product_GetByBarcode", SpWhitelist.ResolveSqlName("Product.GetByBarcode"));
        Assert.Equal("API_Get_Currency", SpWhitelist.ResolveSqlName("GetCurrency"));
    }

    [Fact]
    public async Task TryResolve_GetCurrency_DoesNotRequireAuth()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync("GetCurrency", EmptyCatalog());
        Assert.True(found);
        Assert.False(def!.RequiresAuth);
    }

    [Fact]
    public async Task TryResolve_ProductList_DoesNotRequireAuth()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync("Product.List", EmptyCatalog());
        Assert.True(found);
        Assert.Equal("API_Product_List", def!.SqlName);
        Assert.False(def.RequiresAuth);
        Assert.Equal(SpParamPolicy.Open, def.ParamPolicy);
    }

    [Fact]
    public async Task TryResolve_ExplicitAuth_DoesNotRequireCatalog()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync("Auth.Login", EmptyCatalog());
        Assert.True(found);
        Assert.Equal("API_Auth_Login", def!.SqlName);
        Assert.False(def.RequiresAuth);
    }

    [Fact]
    public async Task TryResolve_UnknownAliasWithoutProcedure_ReturnsFalse()
    {
        var whitelist = CreateWhitelist();

        var (found, _) = await whitelist.TryResolveAsync("Evil.DropDatabase", EmptyCatalog());
        Assert.False(found);
    }

    [Fact]
    public async Task TryResolve_MembershipAlias_IsBlocked()
    {
        var whitelist = CreateWhitelist();

        var (found, _) = await whitelist.TryResolveAsync(
            "Membership.Approve",
            Catalog("API_Membership_Approve"));
        Assert.False(found);
    }

    [Fact]
    public async Task TryResolve_AutoResolvedProcedure_ReturnsOpenPolicy()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync(
            "OrderRequest.List",
            Catalog("API_OrderRequest_List"));
        Assert.True(found);
        Assert.Equal(SpParamPolicy.Open, def!.ParamPolicy);
        Assert.True(def.RequiresStaff);
    }

    [Fact]
    public async Task TryResolve_OrderRequestCreate_IsPublicDespitePrefix()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync(
            "OrderRequest.Create",
            Catalog("API_OrderRequest_Create"));
        Assert.True(found);
        Assert.False(def!.RequiresStaff);
    }

    [Fact]
    public async Task TryResolve_SalePrefix_RequiresStaff()
    {
        var whitelist = CreateWhitelist();

        var (found, def) = await whitelist.TryResolveAsync(
            "Sale.Create",
            Catalog("API_Sale_Create"));
        Assert.True(found);
        Assert.True(def!.RequiresStaff);
    }

    [Fact]
    public void ValidateParams_ExtraParam_ReturnsErrorForStrictAuth()
    {
        var whitelist = CreateWhitelist();
        var def = new SpDefinition(
            "Auth.Login",
            "API_Auth_Login",
            new HashSet<string> { "Email", "Password" },
            false,
            false);

        var error = whitelist.ValidateParams(def, new Dictionary<string, object?>
        {
            ["Email"] = "a@b.com",
            ["Password"] = "secret",
            ["UserId"] = 1,
        });

        Assert.NotNull(error);
        Assert.Contains("UserId", error);
    }

    [Fact]
    public void ValidateParams_OpenPolicy_AllowsUnknownClientParams()
    {
        var whitelist = CreateWhitelist();
        var def = new SpDefinition(
            "OrderRequest.List",
            "API_OrderRequest_List",
            new HashSet<string>(),
            true,
            false,
            RequiresStaff: true,
            ParamPolicy: SpParamPolicy.Open);

        var error = whitelist.ValidateParams(def, new Dictionary<string, object?>
        {
            ["DateFrom"] = "2026-01-01",
            ["Page"] = 1,
        });

        Assert.Null(error);
    }
}
