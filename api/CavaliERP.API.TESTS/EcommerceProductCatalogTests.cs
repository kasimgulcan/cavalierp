using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using CsmStok.Api.Controllers;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;

namespace CsmStok.Api.Tests;

public class EcommerceProductCatalogTests
{
    [Fact]
    public void FromResultSets_MapsThreeSets_PreservesSqlColumnNames()
    {
        var barcodeKey = "BARCODE GS1/EAN ";
        var skus = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?>
            {
                ["SKU CODE"] = "H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB",
                ["STYLE NAME"] = "TORONTO",
                [barcodeKey] = "8683711000211",
                ["SKU ID"] = 5,
            },
        };
        var styleModels = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?> { ["STYLE NAME"] = "ALASKA" },
        };
        var models = new List<IReadOnlyDictionary<string, object?>>
        {
            new Dictionary<string, object?> { ["MODEL NAME"] = "ALISA KAPTAN" },
        };

        var snapshot = EcommerceProductCatalogMapper.FromResultSets([skus, styleModels, models]);

        Assert.Equal("TORONTO", snapshot.Skus[0]["STYLE NAME"]);
        Assert.Equal("H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB", snapshot.Skus[0]["SKU CODE"]);
        Assert.Equal("8683711000211", snapshot.Skus[0][barcodeKey]);
        Assert.Equal("ALASKA", snapshot.StyleModels[0]["STYLE NAME"]);
        Assert.Equal("ALISA KAPTAN", snapshot.Models[0]["MODEL NAME"]);
    }

    [Fact]
    public void FromResultSets_EmptySets_AreAllowed()
    {
        var empty = new List<IReadOnlyDictionary<string, object?>>();
        var snapshot = EcommerceProductCatalogMapper.FromResultSets([empty, empty, empty]);
        Assert.Empty(snapshot.Skus);
        Assert.Empty(snapshot.StyleModels);
        Assert.Empty(snapshot.Models);
    }

    [Fact]
    public void FromResultSets_NotThreeSets_Throws()
    {
        var empty = new List<IReadOnlyDictionary<string, object?>>();
        var ex = Assert.Throws<InvalidOperationException>(
            () => EcommerceProductCatalogMapper.FromResultSets([empty, empty]));
        Assert.Equal("GetSKUSnapshot must return 3 result sets.", ex.Message);
    }

    [Fact]
    public void ReadRow_PreservesColumnNameWithTrailingSpace_AndNulls()
    {
        var table = new DataTable();
        table.Columns.Add("SKU CODE", typeof(string));
        table.Columns.Add("BARCODE GS1/EAN ", typeof(string));
        table.Columns.Add("SKU ID", typeof(int));
        var row = table.NewRow();
        row["SKU CODE"] = "ABC";
        row["BARCODE GS1/EAN "] = DBNull.Value;
        row["SKU ID"] = 9;
        table.Rows.Add(row);

        using var reader = table.CreateDataReader();
        Assert.True(reader.Read());
        var mapped = EcommerceProductCatalogMapper.ReadRow(reader);

        Assert.Equal("ABC", mapped["SKU CODE"]);
        Assert.Null(mapped["BARCODE GS1/EAN "]);
        Assert.Equal(9, mapped["SKU ID"]);
    }
}
