using System.Net;
using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceIpAllowlistTests
{
    [Fact]
    public void EmptyList_AllowsAny()
    {
        Assert.True(EcommerceIpAllowlist.IsAllowed(IPAddress.Parse("8.8.8.8"), []));
        Assert.True(EcommerceIpAllowlist.IsAllowed(null, []));
    }

    [Fact]
    public void Cidr_AllowsAddressInRange()
    {
        Assert.True(EcommerceIpAllowlist.IsAllowed(IPAddress.Parse("192.168.1.20"), ["192.168.1.0/24"]));
        Assert.False(EcommerceIpAllowlist.IsAllowed(IPAddress.Parse("10.0.0.1"), ["192.168.1.0/24"]));
    }

    [Fact]
    public void ExactIp_Matches()
    {
        Assert.True(EcommerceIpAllowlist.IsAllowed(IPAddress.Parse("203.0.113.4"), ["203.0.113.4"]));
        Assert.False(EcommerceIpAllowlist.IsAllowed(IPAddress.Parse("203.0.113.5"), ["203.0.113.4"]));
    }
}
