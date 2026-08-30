using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class OutboundMovementMapperTests
{
    [Fact]
    public void SkipBecauseEcommerce_IgnoresCaseAndTrim()
    {
        Assert.True(OutboundMovementMapper.SkipBecauseEcommerce(" ecommerce "));
        Assert.True(OutboundMovementMapper.SkipBecauseEcommerce("Ecommerce"));
        Assert.False(OutboundMovementMapper.SkipBecauseEcommerce("pos"));
        Assert.False(OutboundMovementMapper.SkipBecauseEcommerce(null));
    }

    [Fact]
    public void FromSaleLine_InsertDeleteUpdate()
    {
        Assert.Equal(("sale.created", 2), OutboundMovementMapper.FromSaleLine("INSERT", 0, 2));
        Assert.Equal(("sale.deleted", 2), OutboundMovementMapper.FromSaleLine("DELETE", 2, 0));
        Assert.Equal(("sale.updated", 3), OutboundMovementMapper.FromSaleLine("UPDATE", 2, 5));
        Assert.Equal(("sale.updated", -2), OutboundMovementMapper.FromSaleLine("UPDATE", 5, 3));
        Assert.Null(OutboundMovementMapper.FromSaleLine("UPDATE", 4, 4));
    }

    [Fact]
    public void FromStockEntry_InsertDeleteUpdate()
    {
        Assert.Equal(("stock.received", 10), OutboundMovementMapper.FromStockEntry("INSERT", 0, 10));
        Assert.Equal(("stock.deleted", 10), OutboundMovementMapper.FromStockEntry("DELETE", 10, 0));
        Assert.Equal(("stock.updated", -2), OutboundMovementMapper.FromStockEntry("UPDATE", 10, 8));
        Assert.Null(OutboundMovementMapper.FromStockEntry("INSERT", 0, 0));
    }
}
