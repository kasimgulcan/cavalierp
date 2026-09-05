# E-ticaret ürün kataloğu snapshot — Tasarım Spesifikasyonu

**Tarih:** 2026-09-05  
**Durum:** Onaylandı  
**Kapsam:** Site (reklam5) CavaliERP’den ürün kataloğunu çeker; kendi vitrininde create/update eder. Stok snapshot ve stok webhook sözleşmesi değişmez.

Karşı taraf sözleşmesi: `docs/ecommerce-product-catalog.md` (uygulama planında yazılır). Stok: `docs/ecommerce-stock-webhook.md` — kilitli.

---

## 1. Özet

Stok listesi `GET /integrations/ecommerce/stock/snapshot` ile zaten paylaşılmış ve kapanmıştır. Katalog ayrı kapıdır: site HMAC ile `GetSKUSnapshot` sonucunu çeker. CavaliERP ürün yazmaz, push etmez; site saparsa tekrar GET alır.

Canlı SP (2026-09-05): üç sonuç kümesi — 1311 SKU satırı (87 kolon), 364 stil–manken eşlemesi, 8 manken kartı.

---

## 2. Kararlar

| Konu | Karar |
|---|---|
| Stok snapshot | Dokunulmaz |
| Kapı | `GET /integrations/ecommerce/products/snapshot` |
| Kaynak | `dbo.GetSKUSnapshot` (içeride `GetSKU` + `GetSKU_ModelReference`) |
| Yön | Yalnızca çekme; ürün POST / outbox / trigger yok |
| HMAC | Mevcut ecommerce middleware; yeni secret yok |
| Enabled | `EcommerceSync:Enabled` (ayrı bayrak yok; appsettings `true`) |
| Dış sarmalayıcı | camelCase: `generatedAt`, `source`, `skus`, `styleModels`, `models` |
| Satır anahtarları | SQL kolon adı birebir (boşluk, `/`, Türkçe, sonda boşluklu barkod kolonu) |
| Filtre | Yok — SP ne dönerse o (`PUBLISH = 0` dahil) |
| Sayfalama | Yok; tek cevap |
| Değerler | SqlDataReader CLR tipi; `DBNull` → JSON `null` |
| Eksik/fazla result set | 500; yarım gövde yok |

---

## 3. Akış

```
Site HMAC GET /integrations/ecommerce/products/snapshot
  → EcommerceHmacMiddleware
  → EcommerceProductCatalogController
  → EXEC GetSKUSnapshot
  → result 1 → skus
  → result 2 → styleModels
  → result 3 → models
```

Stok path’leri (`/stock`, `/stock/snapshot`, outbound worker) bu akışta yoktur.

---

## 4. Endpoint

Production taban: `https://app.devcloud.com.tr/cavalierp/api`

| Method | Path |
|---|---|
| `GET` | `/integrations/ecommerce/products/snapshot` |

Mobil JWT yok. `EcommerceSync:Enabled = false` iken middleware tüm `/integrations/ecommerce` için 404 (mevcut davranış; katalog için ayrı kapatma yok).

---

## 5. HMAC

Stok GET ile aynı kurallar:

- Header: `X-CavaliERP-Timestamp` (Unix saniye UTC), `X-CavaliERP-Signature` (`sha256=<hex>`)
- Canonical: `{timestamp}.GET./integrations/ecommerce/products/snapshot`
- IIS path öneki imzada yok
- ±5 dk skew (`TimestampSkewMinutes`)
- Secret yok / imza yanlış → 401

POST 64 KB gövde tavanı bu GET’e uygulanmaz.

---

## 6. Cevap gövdesi

```json
{
  "generatedAt": "2026-09-05T09:00:00Z",
  "source": "cavalierp",
  "skus": [ { "SKU CODE": "H.RUGFL_FLC0001_FLC0001BLKRGL_S / COB", "STYLE NAME": "TORONTO", "PUBLISH": "1" } ],
  "styleModels": [ { "STYLE NAME": "ALASKA", "FULL PRODUCT CODE": "H.RUGFL_STR0005_RPS0003BLKBLK" } ],
  "models": [ { "MODEL NAME": "ALISA KAPTAN", "MODEL REFERENCE": "AK" } ]
}
```

`generatedAt` = cevap anı UTC. `source` sabit `"cavalierp"`.

Boş katalog: 200, üç dizi `[]`.

### 6.1 `skus` — `GetSKU` kolonları (sıra korunur)

`BARCODE GS1/EAN`, `ART. #`, `STYLE NAME`, `PRODUCT NAME`, `PRODUCT CODE`, `SIZE`, `MAIN CATEGORY`, `WEB CATEGORY`, `PRODUCT GROUP`, `TYPE / GENDER`, `PRODUCT CATEGORY`, `SEASON`, `MAIN FABRIC`, `MAIN COLOR`, `SECONDARY COLOR`, `PRODUCT COLOR NAME`, `MODEL CODE`, `FABRIC + COLOR CODE`, `FULL PRODUCT CODE`, `SKU CODE`, `BARCODE GS1/EAN ` (sonda boşluk; ayrı key), `COLOR VARIANTS OF STYLE`, `SIZE RANGE OF STYLE`, `MAIN PHOTO` … `PHOTO 6`, `VIDEO`, `EXTRA MEDIA`, `PRODUCT TITLE`, `PRODUCT DESCRIPTION`, `PRODUCT FEATURES`, `CARE INSTRUCTIONS`, `ÜRÜN ADI`, `ÜRÜN AÇIKLAMASI`, `ÜRÜN ÖZELLİKLERİ`, `YIKAMA TALİMATLARI`, `TITOLO DEL PRODOTTO`, `DESCRIZIONE DEL PRODOTTO`, `CARATTERISTICHE DEL PRODOTTO`, `ISTRUZIONI PER LA CURA`, `PRODUKTTITEL`, `PRODUKT BESCHREIBUNG`, `PRODUKT MERKMALE`, `PFLEGEHINWEISE`, `ALSO IN THE PHOTO 1` … `5`, `RELATED PRODUCTS 1` … `5`, `MAIN CATEGORY ID`, `WEB CATEGORY ID`, `PRODUCT GROUP ID`, `TYPE/GRENDER ID`, `PRODUCT CATEGORY ID`, `ATTRIBUTES (EX-PRODUCT CAT) ID`, `NEW IN`, `BESTSELLERS`, `SHOP THE LOOK`, `COMPETITION`, `OUTLET`, `TBF X SANMARCO`, `TOTAL CATEGORIES`, `ADDITIONAL (MANUAL) CAT.`, `VARIANTS`, `PRICE EURO`, `PRICE TL`, `PRICE USD`, `INITIAL STOCK QTY`, `SOLD QTY`, `IN-STOCK QTY`, `PUBLISH`, `MODEL REFERENCE`, `SIZE CHART REFERENCE`, `MADE IN ITALY LOGO`, `UPDATE`, `NOTES`, `THE AFTER COLLECTION`, `MODEL SIZE INFO`, `SKU ID`.

### 6.2 `styleModels`

`STYLE NAME`, `PRODUCT NAME`, `PRODUCT CODE`, `MAIN COLOR`, `SECONDARY COLOR`, `FULL PRODUCT CODE`, `MODEL REFERENCE`.

### 6.3 `models`

`MODEL NAME`, `MODEL REFERENCE`, `MODEL GENDER`, `MODEL AGE`, `MODEL ORIGIN`, `MODEL AGENCY`, `CAPTION`, `HEIGHT`, `WEIGHT`, `CHEST`, `WAIST`, `HIPS`, `SHOE SIZE`.

JSON UTF-8. Kolon adı rename / camelCase yok.

---

## 7. SQL

`GetSKUSnapshot` canlıda vardır; repo’ya migrate script eklenir (isim değişmez):

```sql
CREATE OR ALTER PROCEDURE dbo.GetSKUSnapshot
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.GetSKU;
    EXEC dbo.GetSKU_ModelReference;
END
```

`GetSKU` ve `GetSKU_ModelReference` bu işte değiştirilmez. `API_WebHook_StockSnapshot` değiştirilmez.

---

## 8. API kodu

Yeni, stok dosyalarından ayrı:

| Birim | Görev |
|---|---|
| `EcommerceProductCatalogController` | `GET snapshot` → sarmalayıcı JSON |
| Repository (katalog) | `EXEC GetSKUSnapshot`, `NextResult`, satır → `Dictionary<string, object?>` |
| Tester | HMAC GET; `skus` sayısı + örnek satır |

`EcommerceStockController`, stock service/repository, outbound dispatcher, HMAC sınıfı (canonical kuralı) değişmez. Middleware zaten `/integrations/ecommerce` altını imzalar; yeni path otomatik korumalıdır.

CommandTimeout: 120 saniye.

Dış sarmalayıcı özellikleri camelCase (`PropertyNamingPolicy.CamelCase`). Dictionary key’ler policy’den geçmez; SQL adları kalır.

---

## 9. Hatalar

| Durum | HTTP | Gövde |
|---|---|---|
| HMAC yok / yanlış / skew / IP | 401 | mevcut middleware |
| `Enabled: false` | 404 | mevcut middleware |
| SQL hata / timeout | 500 | `{ "success": false, "error": "Unable to load product catalog." }` |
| Result set sayısı ≠ 3 | 500 | aynı hata gövdesi; yarım JSON yok |
| Boş kümeler | 200 | boş diziler |

İç exception loglanır; SQL metni client’a gitmez.

---

## 10. Test istemcisi

`/tester/` stok kartına dokunulmaz. Ayrı kontrol: “Ürün kataloğu çek” → HMAC GET yeni path. Trafik günlüğünde `action: product-catalog`, `skus` uzunluğu.

---

## 11. Testler (davranış)

- Canonical GET path `/integrations/ecommerce/products/snapshot` (trailing slash normalize)
- Mock SP: üç küme; cevapta `skus` / `styleModels` / `models`
- Satır key `SKU CODE`, `STYLE NAME`; sonda boşluklu `BARCODE GS1/EAN ` key olarak durur
- İki küme dönen mock → 500
- Stok snapshot testleri aynı kalır (skuCode + quantity)

---

## 12. Dışında (bu iş değil)

- Stok snapshot veya stok POST/push değişikliği
- Katalog inbound POST, outbox, ürün trigger
- `PUBLISH` filtresi, sayfalama
- Kolon adı camelCase eşlemesi
- `GetSKU` / `GetSKU_ModelReference` yeniden yazımı
- Partner’ın katalog snapshot URL’sini CavaliERP’nin okuması
