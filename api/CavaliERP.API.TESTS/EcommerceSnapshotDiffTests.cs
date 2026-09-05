using CsmStok.Api.Models;
using CsmStok.Api.Services.Ecommerce;

namespace CsmStok.Api.Tests;

public class EcommerceSnapshotDiffTests
{
    [Fact]
    public void Compare_ReportsQuantityMismatchAndSkuOnlyOnOneSide()
    {
        var ours = new EcommerceStockSnapshotItem[]
        {
            new() { SkuCode = "A_XL", Quantity = 5 },
            new() { SkuCode = "B_M / 46", Quantity = -3 },
        };
        var theirs = new EcommerceStockSnapshotItem[]
        {
            new() { SkuCode = "A_XL", Quantity = 4 },
            new() { SkuCode = "C_6-7 Y", Quantity = 1 },
        };

        var diff = EcommerceSnapshotDiff.Compare(ours, theirs);

        Assert.Equal(3, diff.Count);
        Assert.Contains(diff, row => row.SkuCode == "A_XL" && row.Ours == 5 && row.Theirs == 4);
        Assert.Contains(diff, row => row.SkuCode == "B_M / 46" && row.Ours == -3 && row.Theirs is null);
        Assert.Contains(diff, row => row.SkuCode == "C_6-7 Y" && row.Ours is null && row.Theirs == 1);
    }

    [Fact]
    public void Compare_IgnoresMatchingRows()
    {
        var items = new EcommerceStockSnapshotItem[] { new() { SkuCode = "A_XL", Quantity = 2 } };
        Assert.Empty(EcommerceSnapshotDiff.Compare(items, items));
    }
}
