# CSM.Stok

Mobil satış uygulaması (Flutter) + SP gateway API (ASP.NET Core).

## Yapı

- `mobile/` — Flutter iOS/Android uygulaması
- `api/` — IIS üzerinde çalışan Web API
- `sql/` — `API_*` stored procedure script'leri
- `docs/superpowers/specs/` — Tasarım spesifikasyonu
- `docs/superpowers/plans/` — Implementation plan
- `docs/deploy-iis.md` — IIS deployment rehberi

## Geliştirme

### API

```powershell
cd api\CsmStok.Api
dotnet run --launch-profile http
```

Health: `http://localhost:5160/health` (local)

Production: `https://app.devcloud.com.tr/cavalierp/api/health`

### Mobil

```powershell
cd mobile
# Local
flutter run --dart-define=API_BASE_URL=http://localhost:5160
# Production
flutter run --dart-define=API_BASE_URL=https://app.devcloud.com.tr/cavalierp/api
```

### SQL

**Tek migration dosyası:**

```powershell
# SSMS: sql/Migration.sql dosyasını açıp F5 ile çalıştırın
```

`sql/Migration.sql` — DROP + CREATE tablolar + view + tüm `API_*` SP'leri (CavalierShop).

Ürün spec: `docs/superpowers/specs/2026-06-30-cavalier-shop-design.md`

> **Uyarı:** DROP bölümü Users, Sales, OrderRequests, StockEntries, PaymentTypes vb. tabloları ve verilerini siler.  
> Products, Sizes, Customers, **Currencies**, **SizePrices**, Style, V_ProductSize mevcut ERP tablolarıdır; script oluşturmaz.

Ayrı script dosyaları `sql/` ve `sql/Tables/` altında referans olarak duruyor.

## Test

```powershell
dotnet test api\CsmStok.Api.Tests
cd mobile && flutter test
```
