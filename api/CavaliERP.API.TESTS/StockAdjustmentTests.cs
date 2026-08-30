using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class StockAdjustmentTests
{
    [Fact]
    public void ForTarget_Increase_WritesStockEntry()
    {
        var adjustment = StockAdjustment.ForTarget(currentQty: 3, targetQty: 8);
        Assert.Equal(StockAdjustmentKind.StockEntry, adjustment.Kind);
        Assert.Equal(5, adjustment.Quantity);
    }

    [Fact]
    public void ForTarget_Decrease_WritesSaleLine()
    {
        var adjustment = StockAdjustment.ForTarget(currentQty: 10, targetQty: 4);
        Assert.Equal(StockAdjustmentKind.SaleLine, adjustment.Kind);
        Assert.Equal(6, adjustment.Quantity);
    }

    [Fact]
    public void ForTarget_SameQuantity_NoWrite()
    {
        var adjustment = StockAdjustment.ForTarget(currentQty: 4, targetQty: 4);
        Assert.Equal(StockAdjustmentKind.None, adjustment.Kind);
        Assert.Equal(0, adjustment.Quantity);
    }

    [Fact]
    public void ForTarget_FromZeroToPositive_WritesStockEntry()
    {
        var adjustment = StockAdjustment.ForTarget(currentQty: 0, targetQty: 2);
        Assert.Equal(StockAdjustmentKind.StockEntry, adjustment.Kind);
        Assert.Equal(2, adjustment.Quantity);
    }
}
