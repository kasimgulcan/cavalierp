# CavaliERP

Personel satış ve müşteri talep uygulaması: Flutter (iOS/Android) + ASP.NET Core API + SQL Server.

Canlı API: `https://app.devcloud.com.tr/cavalierp/api`

## Yapı

| Klasör | İçerik |
|--------|--------|
| `mobile/` | Flutter uygulaması (`cavalierp`) |
| `api/CavaliERP.API/` | SP gateway, auth, e-ticaret stok webhook |
| `api/CavaliERP.API.TESTS/` | API birim testleri |
| `sql/` | Şema ve incremental migration |
| `docs/` | IIS, webhook ve tasarım notları |

Solution: `api/CavaliERP.API.slnx`

## Geliştirme

### API

```powershell
cd api\CavaliERP.API
dotnet run --launch-profile http
```

Health: `http://localhost:5160/health`

Yerel ayar için `appsettings.Development.example.json` dosyasını `appsettings.Development.json` olarak kopyalayın.

### Mobil

```powershell
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:5160
```

Canlı API:

```powershell
flutter run --dart-define=API_BASE_URL=https://app.devcloud.com.tr/cavalierp/api
```

### SQL

| Dosya | Ne zaman |
|-------|----------|
| `sql/db.sql` | Tam şema (yeni ortam) |
| `sql/Migrate_MobileSaleUx.sql` | Mevcut DB üzerine satış UX güncellemesi |

### Test

```powershell
dotnet test api\CavaliERP.API.slnx
cd mobile; flutter test
```

E-ticaret simülatörü (API ile birlikte, `EcommerceSync:TesterEnabled` açık olmalı): `/tester/`

## Yayın

IIS adımları: [docs/deploy-iis.md](docs/deploy-iis.md)

```powershell
.\scripts\publish-api.ps1
```
