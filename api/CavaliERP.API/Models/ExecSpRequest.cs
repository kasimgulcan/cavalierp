namespace CsmStok.Api.Models;

public sealed class ExecSpRequest
{
    public required string Sp { get; init; }
    public Dictionary<string, object?>? Params { get; init; }
}
