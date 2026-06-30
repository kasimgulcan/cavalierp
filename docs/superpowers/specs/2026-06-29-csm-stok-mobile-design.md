# CSM.Stok Mobil Uygulama — Tasarım Spesifikasyonu

**Tarih:** 2026-06-29  
**Durum:** Onaylandı (brainstorming)  
**Kapsam:** Flutter mobil uygulama + ASP.NET Core API (IIS) + SQL Server `API_*` stored procedure'leri

---

## 1. Özet

CSM.Stok, mevcut Windows masaüstü (.NET/C#) stok yönetim sisteminin mobil uzantısıdır. Mobil uygulama barkod okur, ürün bilgisini API üzerinden sorgular, sepete ekler ve satış kaydı oluşturur. Ürün tanımları, stoklar ve barkodlar masaüstü/SQL Server tarafında yönetilir; mobil yalnızca API ile konuşur.

**Temel kararlar:**

| Konu | Karar |
|---|---|
| Mobil teknoloji | Flutter (iOS + Android) |
| Masaüstü | .NET/C# (mevcut, ayrı solution) |
| API | ASP.NET Core, IIS üzerinde Windows Server |
| Veritabanı | SQL Server |
| API deseni | Generic `ExecSP` + whitelist; iş mantığı `API_*` SP'lerde |
| Erişim | İnternet üzerinden |
| Tenant modeli | Multi-tenant; firma ataması yönetici onayında |
| Kayıt | Herkese açık (mağaza uyumu); onay modülü masaüstünde |
| Onay modu | İnceleme: tam erişim; canlı: onay bekletme (config ile) |
| Satış | Sepet modeli; opsiyonel müşteri/ödeme tipi; POS entegrasyonu yok |
| Çevrimdışı | Yok — bağlantı zorunlu |
| Auth DB | Mevcut kullanıcı tabloları kullanılır |

---

## 2. Sistem Mimarisi

```
┌─────────────────┐     HTTPS      ┌──────────────────┐     EXEC      ┌─────────────┐
│  Flutter Mobil  │ ──────────────▶│  ASP.NET Core    │ ────────────▶│  SQL Server │
│  (iOS/Android)  │◀──────────────│  API (IIS)       │◀────────────│  API_* SP   │
└─────────────────┘     JSON       └──────────────────┘     JSON      └─────────────┘
                                              │
┌─────────────────┐                           │
│  .NET Masaüstü  │ ─── doğrudan DB/SP ───────┘
│  (onay modülü)  │
└─────────────────┘
```

### Repo organizasyonu (bu workspace)

```
CSM.Stok/
├── mobile/              # Flutter uygulaması
├── api/                 # ASP.NET Core Web API (IIS deploy)
└── docs/
    └── superpowers/
        └── specs/       # Tasarım dokümanları
```

Masaüstü uygulama ve mevcut SQL şeması ayrı solution/repo'da kalır. `API_*` stored procedure'ler ortak sözleşmedir.

### Yaklaşım

**Ayrı API solution + ince SP gateway** (onaylandı):

- API ayrı ASP.NET Core projesi; her istek whitelist'teki bir `API_*` SP'yi çağırır.
- Masaüstü mevcut DB/SP erişimine devam eder.
- Mobil yalnızca API üzerinden erişir.
- İş kuralları SQL Server SP'lerinde merkezileştirilir.

---

## 3. API Tasarımı — Generic SP Executor

### 3.1 Endpoint'ler

| Endpoint | Kategori | JWT | Tenant enjeksiyonu |
|---|---|---|---|
| `POST /api/auth/exec` | Auth SP'leri | Opsiyonel (login/register hariç) | Hayır |
| `POST /api/exec` | İş SP'leri | Zorunlu | Evet (`TenantId`, `UserId`) |

İleride admin SP'leri için `POST /api/admin/exec` eklenebilir; v1'de onay işlemleri masaüstünden yapılır.

### 3.2 İstek formatı

```http
POST /api/exec
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "sp": "Product.GetByBarcode",
  "params": {
    "Barcode": "8690123456789"
  }
}
```

- `sp`: Mobil alias (whitelist'te tanımlı kısa ad)
- `params`: SP parametreleri (tenant/user hariç)
- `TenantId` ve `UserId` istemciden **kabul edilmez**; API JWT'den enjekte eder

### 3.3 Yanıt formatı

```json
{
  "success": true,
  "data": [ ... ],
  "error": null
}
```

Hata durumunda anlamlı HTTP status kodu + `error` mesajı döner.

### 3.4 SP isimlendirme

SQL Server'da tüm mobil SP'ler `API_` öneki ile oluşturulur:

```
API_{Modül}_{Eylem}
```

Mobil alias → SQL SP eşlemesi API katmanında yapılır:

| Mobil alias | SQL SP |
|---|---|
| `Auth.Register` | `API_Auth_Register` |
| `Auth.Login` | `API_Auth_Login` |
| `Auth.RefreshToken` | `API_Auth_RefreshToken` |
| `Auth.DeleteAccount` | `API_Auth_DeleteAccount` |
| `Auth.GetProfile` | `API_Auth_GetProfile` |
| `Product.GetByBarcode` | `API_Product_GetByBarcode` |
| `Lookup.Customers` | `API_Lookup_Customers` |
| `Lookup.PaymentTypes` | `API_Lookup_PaymentTypes` |
| `Sale.Create` | `API_Sale_Create` |

Masaüstü onay modülü (mobil API'ye dahil değil):

| SQL SP | Amaç |
|---|---|
| `API_Membership_ListPending` | Bekleyen üyelik talepleri |
| `API_Membership_Approve` | Tenant ata + onayla |
| `API_Membership_Reject` | Reddet |

### 3.5 Güvenlik (ExecSP)

1. **Whitelist** — yalnızca kayıtlı alias'lar çağrılabilir; listede yoksa `403`
2. **SP adı doğrulama** — yalnızca `API_%` pattern; dinamik SQL ile SP çalıştırma yok
3. **Parametre şeması** — SP başına izinli parametre listesi; fazla parametre reddedilir
4. **Server-side injection** — `TenantId`, `UserId`, `Culture` JWT'den gelir
5. **DB yetkisi** — API DB kullanıcısı yalnızca `API_*` SP'lerine `EXECUTE` yetkisine sahip
6. **Rate limiting** — login/register endpoint'lerinde

### 3.6 İstek işleme akışı

```
İstek → JWT doğrula → SP whitelist kontrolü → Parametre şeması kontrolü
      → TenantId/UserId enjekte et → Parametreli SqlCommand ile SP çalıştır → JSON döndür
```

---

## 4. Kimlik Doğrulama ve Multi-Tenant

### 4.1 Auth mekanizması

- Mevcut kullanıcı tabloları kullanılır (yeni auth şeması oluşturulmaz)
- JWT access token (kısa ömür, ~15 dk) + refresh token (~30 gün, DB'de)
- HTTPS zorunlu (IIS, TLS 1.2+)

### 4.2 Kayıt ve onay akışı

```
Kullanıcı kayıt olur (API_Auth_Register)
    → Kullanıcı Pending durumunda oluşur, tenant yok
    → Yönetici masaüstünden talebi görür (API_Membership_ListPending)
    → Onaylarken tenant atar (API_Membership_Approve)
    → Kullanıcı JWT'de TenantId alır
```

### 4.3 Kullanıcı durumları

| Durum | TenantId | Davranış (inceleme modu) | Davranış (canlı mod) |
|---|---|---|---|
| Pending, tenant yok | `null` | Tam erişim | Satış kilitli, "onay bekleniyor" |
| Approved, tenant var | dolu | Tam erişim | Tam erişim |
| Rejected | — | Giriş engelli | Giriş engelli |

Config (`appsettings.json`):

```json
{
  "Membership": {
    "RequireApproval": false
  }
}
```

Mağaza incelemesi: `false` (tam akış görünür). Canlıya geçiş: `true`.

### 4.4 Tenant izolasyonu

Tüm iş SP'leri `@TenantId` parametresi alır. SQL sorgularında `WHERE TenantId = @TenantId` zorunludur. TenantId yalnızca JWT'den gelir; istemci override edemez.

---

## 5. Mobil Uygulama

### 5.1 Teknoloji

| Bileşen | Seçim |
|---|---|
| Framework | Flutter |
| State management | Riverpod |
| HTTP | Dio |
| Navigasyon | go_router |
| Barkod | mobile_scanner |

### 5.2 Proje yapısı

```
lib/
├── core/          # dio, auth interceptor, SpClient (exec wrapper)
├── features/
│   ├── auth/      # login, register, profile, delete account
│   └── sale/      # scanner, cart, checkout, summary
└── shared/        # widgets, theme, constants
```

Tüm API çağrıları tek `SpClient.exec('Product.GetByBarcode', params)` üzerinden gider.

### 5.3 Ekran akışı

```
[Splash]
   ↓
[Giriş] ←→ [Kayıt] → [Kayıt başarılı]
   ↓
[Ana shell]
   ├── [Yeni Satış]     ← ana akış
   ├── [Satış Geçmişi]  (v1 dışı, kolayca eklenebilir)
   └── [Profil / Ayarlar]
```

**Satış akışı:**

```
[Barkod Tara] → API_Product_GetByBarcode
       ↓
[Ürün kartı] → adet + birim fiyat → [Sepete Ekle]
       ↓
[Sepet] → opsiyonel müşteri (API_Lookup_Customers)
        → opsiyonel ödeme tipi (API_Lookup_PaymentTypes)
        → [Satışı Tamamla] → API_Sale_Create
       ↓
[Satış özeti]
```

Bağlantı yoksa: "İnternet bağlantısı gerekli" — işlem yapılamaz.

### 5.4 Mağaza uyumu ekranları

| Öğe | Detay |
|---|---|
| Kayıt | E-posta, şifre, kullanım şartları onayı |
| Gizlilik politikası | WebView veya harici link |
| Hesap silme | Profil → `API_Auth_DeleteAccount` |
| Kamera izni | Barkod tarama açıklama metni |
| Apple Sign In | Gerekmez (kendi auth sistemi) |

İnceleme için test hesabı bilgisi mağaza notlarında sağlanır.

---

## 6. Satış Veri Modeli

### 6.1 API_Sale_Create parametreleri

```json
{
  "CustomerId": null,
  "PaymentTypeId": 2,
  "Lines": [
    {
      "ProductId": 101,
      "Barcode": "8690123456789",
      "Quantity": 2,
      "UnitPrice": 49.90
    }
  ],
  "Note": ""
}
```

SP içinde (tek transaction):
- Satış başlık kaydı
- Satır kayıtları
- Stok düşümü
- TenantId doğrulaması

Müşteri ve ödeme tipleri mevcut DB tablolarından `API_Lookup_*` SP'leri ile listelenir.

---

## 7. Güvenlik Özeti

| Katman | Önlem |
|---|---|
| Transport | HTTPS zorunlu, TLS 1.2+ |
| Auth | JWT + refresh token |
| API | SP whitelist, parametre şeması, rate limiting |
| SQL | API DB user: yalnızca `API_*` EXECUTE; dinamik SQL yok |
| Tenant | JWT'den enjeksiyon; client override yok |
| Certificate pinning | v1.1 (opsiyonel) |

---

## 8. Test Stratejisi

| Katman | Kapsam |
|---|---|
| SQL | SP unit testleri — tenant izolasyonu, stok düşümü, transaction |
| API | Whitelist, JWT, parametre validasyonu, tenant enjeksiyonu |
| Flutter | Widget testleri; integration test (mock API) |
| E2E | Gerçek cihazda barkod tarama + satış akışı |

---

## 9. v1 Kapsam Dışı

- Çevrimdışı mod / senkron kuyruk
- Satış geçmişi ekranı
- Push bildirim (onay geldi vb.)
- Certificate pinning
- Şifremi unuttum (`API_Auth_RequestPasswordReset` — v1.1 önerilir)
- Admin exec endpoint (onay masaüstünden)

---

## 10. Uygulama Sırası (yüksek seviye)

1. SQL: `API_*` SP'leri (auth, lookup, product, sale)
2. API: ASP.NET Core proje, ExecSP gateway, JWT, whitelist
3. Flutter: auth ekranları, SpClient, barkod + sepet + satış
4. Masaüstü: üyelik onay modülü
5. IIS deploy + mağaza yayın hazırlığı

---

## 11. Onay Geçmişi

| Tarih | Bölüm | Durum |
|---|---|---|
| 2026-06-29 | Yaklaşım 1 (ayrı API + SP gateway) | Onaylandı |
| 2026-06-29 | Generic ExecSP + `API_*` isimlendirme | Onaylandı |
| 2026-06-29 | SP haritası ve mobil ekran akışları | Onaylandı |
| 2026-06-29 | Güvenlik, multi-tenant, mağaza checklist | Onaylandı |
