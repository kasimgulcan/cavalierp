using System.Data;
using System.Text.Json;
using CsmStok.Api.Controllers;
using CsmStok.Api.Services.Ecommerce;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;

namespace CsmStok.Api.Tests;

public class EcommerceProductCatalogTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

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

    [Fact]
    public async Task Snapshot_ReturnsWrapperAndSqlKeys()
    {
        var repo = new StubCatalogRepository(EcommerceProductCatalogMapper.FromResultSets(
        [
            [new Dictionary<string, object?> { ["SKU CODE"] = "SKU1", ["STYLE NAME"] = "TORONTO" }],
            [new Dictionary<string, object?> { ["STYLE NAME"] = "ALASKA" }],
            [new Dictionary<string, object?> { ["MODEL NAME"] = "ALISA KAPTAN" }],
        ]));
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        var result = await controller.Snapshot(since: null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(StatusCodes.Status200OK, ok.StatusCode ?? 200);
        var json = JsonSerializer.Serialize(ok.Value, JsonOptions);
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        Assert.Equal("cavalierp", root.GetProperty("source").GetString());
        Assert.True(root.TryGetProperty("generatedAt", out _));
        Assert.Equal("SKU1", root.GetProperty("skus")[0].GetProperty("SKU CODE").GetString());
        Assert.Equal("TORONTO", root.GetProperty("skus")[0].GetProperty("STYLE NAME").GetString());
        Assert.Equal("ALASKA", root.GetProperty("styleModels")[0].GetProperty("STYLE NAME").GetString());
        Assert.Equal("ALISA KAPTAN", root.GetProperty("models")[0].GetProperty("MODEL NAME").GetString());
    }

    [Fact]
    public async Task Snapshot_WhenRepositoryThrows_Returns500WithoutSqlText()
    {
        var repo = new ThrowingCatalogRepository(new InvalidOperationException("GetSKUSnapshot must return 3 result sets."));
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        var result = await controller.Snapshot(since: null, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status500InternalServerError, obj.StatusCode);
        var json = JsonSerializer.Serialize(obj.Value, JsonOptions);
        Assert.Contains("Unable to load product catalog.", json);
        Assert.DoesNotContain("GetSKUSnapshot must return 3 result sets.", json);
    }

    [Fact]
    public async Task Snapshot_WhenSinceOmitted_PassesNullToRepository()
    {
        var repo = new RecordingCatalogRepository();
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        await controller.Snapshot(since: null, CancellationToken.None);

        Assert.Null(repo.LastSince);
    }

    [Fact]
    public async Task Snapshot_WhenSinceProvided_PassesDateToRepository()
    {
        var since = DateTimeOffset.Parse("2026-09-07T17:00:00Z");
        var repo = new RecordingCatalogRepository();
        var controller = new EcommerceProductCatalogController(
            repo,
            NullLogger<EcommerceProductCatalogController>.Instance);

        await controller.Snapshot(since, CancellationToken.None);

        Assert.Equal(since, repo.LastSince);
    }

    private sealed class StubCatalogRepository(EcommerceProductCatalogSnapshot snapshot) : IEcommerceProductCatalogRepository
    {
        public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(
            DateTimeOffset? since,
            CancellationToken cancellationToken) =>
            Task.FromResult(snapshot);
    }

    private sealed class ThrowingCatalogRepository(Exception exception) : IEcommerceProductCatalogRepository
    {
        public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(
            DateTimeOffset? since,
            CancellationToken cancellationToken) =>
            Task.FromException<EcommerceProductCatalogSnapshot>(exception);
    }

    private sealed class RecordingCatalogRepository : IEcommerceProductCatalogRepository
    {
        public DateTimeOffset? LastSince { get; private set; }

        public Task<EcommerceProductCatalogSnapshot> GetSnapshotAsync(
            DateTimeOffset? since,
            CancellationToken cancellationToken)
        {
            LastSince = since;
            return Task.FromResult(EcommerceProductCatalogMapper.FromResultSets(
            [
                new List<IReadOnlyDictionary<string, object?>>(),
                new List<IReadOnlyDictionary<string, object?>>(),
                new List<IReadOnlyDictionary<string, object?>>(),
            ]));
        }
    }
}
