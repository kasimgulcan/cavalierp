# CavaliERP API — IIS publish paketi oluşturur.
# Kullanım: .\scripts\publish-api.ps1
# Çıktı: api\CavaliERP.API\publish\

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$projectDir = Join-Path $repoRoot "api\CavaliERP.API"
$publishDir = Join-Path $projectDir "publish"

Write-Host "==> CavaliERP API publish" -ForegroundColor Cyan
Write-Host "    Proje : $projectDir"
Write-Host "    Çıktı : $publishDir"
Write-Host ""

if (Test-Path $publishDir) {
    Write-Host "==> Eski publish klasörü temizleniyor..."
    Remove-Item $publishDir -Recurse -Force
}

Push-Location $projectDir
try {
    dotnet publish .\CavaliERP.API.csproj -c Release -o $publishDir
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish başarısız (exit $LASTEXITCODE)"
    }
}
finally {
    Pop-Location
}

$dll = Join-Path $publishDir "CavaliERP.API.dll"
$webConfig = Join-Path $publishDir "web.config"
if (-not (Test-Path $dll)) {
    throw "Beklenen DLL bulunamadı: $dll"
}
if (-not (Test-Path $webConfig)) {
    throw "web.config publish çıktısında yok"
}

Write-Host ""
Write-Host "==> Publish tamam" -ForegroundColor Green
Write-Host "    DLL      : $dll"
Write-Host "    web.config: $webConfig"
Write-Host ""
Write-Host "Sonraki adımlar:" -ForegroundColor Yellow
Write-Host "  1. publish\ klasörünü IIS fiziksel yoluna kopyalayın"
Write-Host "  2. Sunucudaki appsettings.json içinde ConnectionStrings ve Jwt:SigningKey doldurun"
Write-Host "  3. App pool recycle"
Write-Host "  4. Doğrulama: Invoke-RestMethod https://app.devcloud.com.tr/cavalierp/api/health"
Write-Host ""
Write-Host "Ayrıntılar: docs\deploy-iis.md"
