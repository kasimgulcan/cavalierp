using CsmStok.Api.Models;
using CsmStok.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CsmStok.Api.Controllers;

[ApiController]
[Route("exec")]
[Authorize]
public sealed class ExecController(ExecSpService execSpService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Execute([FromBody] ExecSpRequest request, CancellationToken ct)
    {
        var (status, body) = await execSpService.ExecuteAsync(request, User, ct);
        return StatusCode(status, body);
    }
}
