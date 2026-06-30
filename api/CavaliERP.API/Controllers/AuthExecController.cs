using CsmStok.Api.Models;
using CsmStok.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[Route("auth/exec")]
public sealed class AuthExecController(ExecSpService execSpService) : ControllerBase
{
    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Execute([FromBody] ExecSpRequest request, CancellationToken ct)
    {
        var (status, body) = await execSpService.ExecuteAsync(request, User, ct);
        return StatusCode(status, body);
    }
}
