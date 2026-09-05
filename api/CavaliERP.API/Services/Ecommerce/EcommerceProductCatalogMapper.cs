using System.Data;

namespace CsmStok.Api.Services.Ecommerce;

public sealed class EcommerceProductCatalogSnapshot
{
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> Skus { get; init; }
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> StyleModels { get; init; }
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> Models { get; init; }
}

public static class EcommerceProductCatalogMapper
{
    public const string WrongResultSetCountMessage = "GetSKUSnapshot must return 3 result sets.";

    public static EcommerceProductCatalogSnapshot FromResultSets(
        IReadOnlyList<IReadOnlyList<IReadOnlyDictionary<string, object?>>> sets)
    {
        if (sets.Count != 3)
            throw new InvalidOperationException(WrongResultSetCountMessage);

        return new EcommerceProductCatalogSnapshot
        {
            Skus = sets[0],
            StyleModels = sets[1],
            Models = sets[2],
        };
    }

    public static Dictionary<string, object?> ReadRow(IDataRecord record)
    {
        var row = new Dictionary<string, object?>(record.FieldCount, StringComparer.Ordinal);
        for (var i = 0; i < record.FieldCount; i++)
        {
            var value = record.GetValue(i);
            row[record.GetName(i)] = value is DBNull ? null : value;
        }

        return row;
    }
}
