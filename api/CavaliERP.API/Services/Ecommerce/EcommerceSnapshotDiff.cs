using CsmStok.Api.Models;

namespace CsmStok.Api.Services.Ecommerce;

public sealed record EcommerceSnapshotDiffRow(string SkuCode, int? Ours, int? Theirs);

public static class EcommerceSnapshotDiff
{
    public static IReadOnlyList<EcommerceSnapshotDiffRow> Compare(
        IReadOnlyList<EcommerceStockSnapshotItem> ours,
        IReadOnlyList<EcommerceStockSnapshotItem> theirs)
    {
        var ourMap = ToMap(ours);
        var theirMap = ToMap(theirs);
        var rows = new List<EcommerceSnapshotDiffRow>();
        foreach (var sku in ourMap.Keys.Union(theirMap.Keys, StringComparer.Ordinal).OrderBy(s => s, StringComparer.Ordinal))
        {
            ourMap.TryGetValue(sku, out var oursQty);
            theirMap.TryGetValue(sku, out var theirsQty);
            var oursValue = ourMap.ContainsKey(sku) ? oursQty : (int?)null;
            var theirsValue = theirMap.ContainsKey(sku) ? theirsQty : (int?)null;
            if (oursValue == theirsValue)
                continue;
            rows.Add(new EcommerceSnapshotDiffRow(sku, oursValue, theirsValue));
        }

        return rows;
    }

    private static Dictionary<string, int> ToMap(IReadOnlyList<EcommerceStockSnapshotItem> items)
    {
        var map = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var item in items)
        {
            if (string.IsNullOrWhiteSpace(item.SkuCode))
                continue;
            map[item.SkuCode] = item.Quantity;
        }

        return map;
    }
}
