namespace CsmStok.Api.Models;

public sealed class ExecSpResponse
{
    public bool Success { get; init; }
    public object? Data { get; init; }
    public string? Error { get; init; }

    public static ExecSpResponse Ok(object? data) => new() { Success = true, Data = data };
    public static ExecSpResponse Fail(string error) => new() { Success = false, Error = error };
}
