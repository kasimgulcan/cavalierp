# CavalierShop — Müşteri Sipariş & Personel Satış Uygulaması

**Tarih:** 2026-06-30  
**Durum:** Onaylandı  
**Dağıtım:** App Store + Google Play (public)  
**Marka:** Cavalier San Marco (Cavalier) — at ve yarış malzemeleri

---

## 1. Özet

**CavalierShop**, Cavalier müşterilerinin üye olup ürün kataloğunu gezip **sipariş talebi** gönderebildiği; Cavalier personelinin (**Staff**) ise barkod ile **doğrudan satış** kaydı girebildiği tek mağazalı mobil uygulamadır.

- **OrganizationId / TenantId yok** — tek işletme, tek katalog, tek veritabanı.
- **Currency, PaymentTypes** ortak lookup tabloları (org ayrımı yok).
- Mağaza konumu: markalı **sipariş uygulaması** (iç stok aracı değil).

---

## 2. Mağaza uyumu

| Gereksinim | Karşılık |
|------------|----------|
| Herkese açık değer | Üye ol → katalog → sipariş talebi |
| Tek marka | CavalierShop = Cavalier vitrini (Nike app modeli) |
| İnceleme hesabı | `review@cavalier...` + onaylı Member; isteğe bağlı Staff |
| Hesap / gizlilik | Kayıt, silme, privacy ekranı |
| Ekran görüntüleri | Katalog, sepet, talep onayı — barkod öne çıkmaz |

---

## 3. Marka (mobil)

| Öğe | Değer |
|-----|--------|
| Uygulama adı | **CavalierShop** |
| Paket adı (öneri) | `com.cavalier.shop` veya `com.cavaliersanmarco.shop` |
| Slogan | “At ve yarış malzemeleri — sipariş verin” |
| Giriş ekranı | CavalierShop + kısa açıklama |
| `main.dart` title | CavalierShop |

---

## 4. Roller

| Rol | Kim | Yetki |
|-----|-----|--------|
| **Member** | Müşteri (yarışçı, antrenör, ahır vb.) | Katalog, arama, sepet, **sipariş talebi** |
| **Staff** | Cavalier personeli | Member + **barkod**, **Sale.Create**, stok düşümü |
| **Admin** | Masaüstü | Üyelik onayı, rol atama (`Member` / `Staff`) |

JWT claim: `role` = `Member` | `Staff` (varsayılan `Member`).

Kayıt → `Pending` → `API_Membership_Approve` → `Approved` + rol.

---

## 5. Akışlar

### 5.1 Member — Sipariş talebi

```
Giriş → Ürünler (liste/arama) → Sepet → Talep gönder → “Talebiniz alındı”
```

- Stok düşmez.
- v1: talep geçmişi listesi yok.

### 5.2 Staff — Satış

```
Giriş → Barkod (veya katalog) → Sepet → Satışı tamamla
```

- Mevcut `Sale.Create` akışı.
- Barkod sekmesi **yalnızca Staff**.

### 5.3 Navigasyon

| Sekme | Member | Staff |
|-------|--------|-------|
| Ürünler | ✓ | ✓ |
| Sepet | ✓ (Talep gönder) | ✓ (Satış tamamla) |
| Barkod | — | ✓ |
| Profil | ✓ | ✓ |

---

## 6. Veri modeli

**OrganizationId kullanılmaz.** Mevcut tenant’sız şema korunur.

### 6.1 Users (güncelleme)

```sql
Users: + Role NVARCHAR(20) NOT NULL DEFAULT 'Member'
       CHECK (Role IN ('Member', 'Staff'))
```

- `TenantId` / `OrganizationId` **yok**.

### 6.2 OrderRequests (yeni)

```sql
OrderRequests (
  OrderRequestId, UserId, CurrencyId, Customer, Note,
  Status, CreatedAt
)
OrderRequestLines (
  OrderRequestLineId, OrderRequestId, SizeId, Product,
  Quantity, UnitPrice, ListPrice
)
```

`Status`: `Pending` | `Accepted` | `Rejected` | `Converted`

### 6.3 Mevcut tablolar

- `Sales`, `SaleLines`, `StockEntries` — org kolonu yok (mevcut hali).
- `Currencies`, `PaymentTypes` — ortak.
- Ürünler: `V_ProductSize`, `Style`, `SizePrices` (ERP).

---

## 7. API

| Alias | SP | Auth | Role |
|-------|-----|------|------|
| `Product.List` | `API_Product_List` | ✓ | Member+ |
| `Product.GetByBarcode` | `API_Product_GetByBarcode` | ✓ | **Staff** |
| `OrderRequest.Create` | `API_OrderRequest_Create` | ✓ | Member+ |
| `Sale.Create` | `API_Sale_Create` | ✓ | **Staff** |
| `GetCurrency` | `API_Get_Currency` | ✓ | Member+ |
| `Lookup.PaymentTypes` | `API_Lookup_PaymentTypes` | ✓ | Member+ |

API enjeksiyonu:

- `UserId` — yalnızca SP tanımında `RequiresUserId` ise.
- `role` — JWT’den; `Sale.Create` / `Product.GetByBarcode` Staff gate.

`API_Membership_Approve`: `@UserId`, `@Role` (TenantId/OrganizationId yok).

---

## 8. Mağaza incelemesi

- Onaylı **Member** test hesabı (gerçek veya seed katalog).
- Store notes: giriş bilgisi + “Browse products and submit an order request”.
- Staff hesabı inceleme notlarında opsiyonel; screenshot’larda kullanılmaz.

---

## 9. Mobil değişiklikler

1. Marka: CSM.Stok → **CavalierShop** (login, title, auth layout).
2. **Ürün listesi** ekranı (yeni) + arama.
3. Sepet: Member → **Talep gönder**; Staff → **Satış tamamla**.
4. Barkod: Staff only.
5. Rol bazlı `home_shell` sekmeleri.

---

## 10. Kapsam dışı (v1)

- OrganizationId / çok mağaza.
- Uygulama içi ödeme.
- Talep listesi / push.
- Talepten otomatik satış.
- Çevrimdışı.

---

## 11. Uygulama sırası

1. SQL: `Users.Role`, `OrderRequests`, `API_Product_List`, `API_OrderRequest_Create`, Membership Approve güncelleme
2. API: JWT `role`, Staff gate, whitelist
3. Mobil: marka, ürün listesi, talep akışı, rol bazlı nav
4. Mağaza metadata + inceleme hesabı

---

## 12. Kilitlenen kararlar

| Karar |
|--------|
| Uygulama adı: **CavalierShop** |
| Tek mağaza; **OrganizationId yok** |
| Müşteri: sipariş talebi; Staff: barkod + satış |
| Barkod yalnızca Staff |
| Talep sonrası: “Talebiniz alındı” yeterli |
| Currency / PaymentTypes ortak |

---

## 13. Sonraki adım

`writing-plans` ile implementation plan (`docs/superpowers/plans/2026-06-30-cavalier-shop.md`).
