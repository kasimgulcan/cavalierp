using CsmStok.Api.Services;

namespace CsmStok.Api.Tests;

public class SqlSpExecutorTests
{
    [Fact]
    public void BuildParameter_JsonElement_ConvertsToString()
    {
        var json = System.Text.Json.JsonDocument.Parse("\"8690\"").RootElement;
        var value = SqlSpExecutor.ConvertParameter(json);
        Assert.Equal("8690", value);
    }
}
