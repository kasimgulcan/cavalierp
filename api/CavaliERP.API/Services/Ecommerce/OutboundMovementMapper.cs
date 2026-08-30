namespace CsmStok.Api.Services.Ecommerce;

public static class OutboundMovementMapper
{
    public const string EcommerceNote = "ecommerce";

    public static bool SkipBecauseEcommerce(string? note) =>
        string.Equals(note?.Trim(), EcommerceNote, StringComparison.OrdinalIgnoreCase);

    public static (string EventType, int Quantity)? FromSaleLine(string dml, int oldQuantity, int newQuantity)
    {
        return dml.ToUpperInvariant() switch
        {
            "INSERT" when newQuantity != 0 => ("sale.created", newQuantity),
            "DELETE" when oldQuantity != 0 => ("sale.deleted", oldQuantity),
            "UPDATE" => SignedUpdate("sale.updated", oldQuantity, newQuantity),
            _ => null,
        };
    }

    public static (string EventType, int Quantity)? FromStockEntry(string dml, int oldQuantity, int newQuantity)
    {
        return dml.ToUpperInvariant() switch
        {
            "INSERT" when newQuantity != 0 => ("stock.received", newQuantity),
            "DELETE" when oldQuantity != 0 => ("stock.deleted", oldQuantity),
            "UPDATE" => SignedUpdate("stock.updated", oldQuantity, newQuantity),
            _ => null,
        };
    }

    private static (string EventType, int Quantity)? SignedUpdate(string eventType, int oldQuantity, int newQuantity)
    {
        var delta = newQuantity - oldQuantity;
        return delta == 0 ? null : (eventType, delta);
    }
}
