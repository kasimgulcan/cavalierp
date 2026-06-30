# IIS Deployment — CSM.Stok API

**Production base URL:** `https://app.devcloud.com.tr/cavalierp/api`

IIS uygulaması `/cavalierp/api` altında çalışır. API route'ları bu path'in **altında** tanımlıdır (`/health`, `/auth/exec`, `/exec`).

| Endpoint | Tam URL |
|---|---|
| Health | `https://app.devcloud.com.tr/cavalierp/api/health` |
| DB health | `https://app.devcloud.com.tr/cavalierp/api/health/db` |
| Auth exec | `https://app.devcloud.com.tr/cavalierp/api/auth/exec` |
| Business exec | `https://app.devcloud.com.tr/cavalierp/api/exec` |

## Prerequisites

- Windows Server with IIS
- ASP.NET Core Hosting Bundle (.NET 10)
- SQL Server reachable from the server
- HTTPS certificate bound in IIS

## Publish

```powershell
cd api\CsmStok.Api
dotnet publish -c Release -o .\publish
```

Copy `publish/` contents to the IIS site physical path (include `web.config`), then recycle the app pool.

## IIS Site Setup

1. Application Pool: **No Managed Code**
2. Site/application virtual path: `/cavalierp/api`
3. Physical path: publish klasörü
4. HTTPS binding (TLS 1.2+)

## Configuration

Edit `appsettings.json` on the server (publish klasöründeki dosya — **localhost + Trusted_Connection IIS'te çalışmaz**):

```json
{
  "ConnectionStrings": {
    "Default": "Server=SQL_SUNUCU_ADI;Database=VERITABANI;User Id=API_KULLANICI;Password=SIFRE;TrustServerCertificate=True;Connect Timeout=5"
  },
  "Jwt": {
    "SigningKey": "en_az_32_karakter_guclu_bir_anahtar_!!"
  }
}
```

- `ConnectionStrings:Default` — SQL Server adı, veritabanı, SQL kullanıcı/şifre (app pool `Trusted_Connection` ile SQL'e bağlanamaz)
- `Jwt:SigningKey` — strong secret (min 32 chars)
- `Membership:RequireApproval` — `false` for store review, `true` for production

## Verify

**Health (API ayakta, DB kontrolü yok):**

```powershell
Invoke-RestMethod https://app.devcloud.com.tr/cavalierp/api/health
```

**DB bağlantısı (500 kayıt hatalarında önce bunu çalıştırın):**

```powershell
Invoke-RestMethod https://app.devcloud.com.tr/cavalierp/api/health/db
```

`ok: false` ve `error` alanında SQL bağlantı hatasını görürsünüz. IIS logunda ~15 sn süren istekler tipik olarak connection timeout'tur.

**Auth gateway:**

```powershell
Invoke-RestMethod -Uri "https://app.devcloud.com.tr/cavalierp/api/auth/exec" `
  -Method Post -ContentType "application/json" `
  -Body '{"sp":"Evil.Test","params":{}}'
```

Expected: `403` — `SP not allowed.`

**Register test (hata gövdesini görmek için `Invoke-WebRequest`):**

```powershell
$body = '{"sp":"Auth.Register","params":{"Email":"test@example.com","Password":"Test123!","AcceptedTerms":true}}'
try {
  Invoke-RestMethod -Uri "https://app.devcloud.com.tr/cavalierp/api/auth/exec" `
    -Method Post -ContentType "application/json" -Body $body
} catch {
  $resp = $_.Exception.Response
  if ($resp) {
    $reader = [System.IO.StreamReader]::new($resp.GetResponseStream())
  Write-Host $reader.ReadToEnd()
  } else {
    Write-Host $_.Exception.Message
  }
}
```

## Mobile

```powershell
flutter run --dart-define=API_BASE_URL=https://app.devcloud.com.tr/cavalierp/api
```
