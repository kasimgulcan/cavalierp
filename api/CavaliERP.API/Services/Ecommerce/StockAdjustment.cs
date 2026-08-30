namespace CsmStok.Api.Services.Ecommerce;

public enum StockAdjustmentKind
{
    None,
    StockEntry,
    SaleLine,
}

public readonly record struct StockAdjustment(StockAdjustmentKind Kind, int Quantity)
{
    public static StockAdjustment ForTarget(int currentQty, int targetQty)
    {
        var delta = targetQty - currentQty;
        if (delta > 0)
            return new(StockAdjustmentKind.StockEntry, delta);
        if (delta < 0)
            return new(StockAdjustmentKind.SaleLine, -delta);
        return new(StockAdjustmentKind.None, 0);
    }
}
