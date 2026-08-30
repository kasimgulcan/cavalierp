# V_Product / V_ProductSize refactor — Tasarım Spesifikasyonu

**Tarih:** 2026-08-28  
**Durum:** Onaylandı  
**Kapsam:** SQL Server view'ları `V_Product`, `V_ProductSize`. `V_SKU` bu turda durur; silme ayrı iş.

---

## 1. Özet

Üç view aynı kod formüllerini farklı sütun isimleri ve farklı kurallarla üretiyor. Doğru formüller `V_SKU` içinde. `V_Product` ve `V_ProductSize` korunacak; formüller `V_SKU` ile hizalanacak; sütun **isimleri** değişmeyecek (SP'ler kırılmasın). `V_SKU` en sonda, ayrı bir işte silinecek.

**Kararlar:**

| Konu | Karar |
|---|---|
| Kaynak formül | `V_SKU` |
| Korunan view'lar | `V_Product`, `V_ProductSize` |
| Silinecek (sonra) | `V_SKU` |
| Sütun isimleri | Değişmez |
| `ProductCode` | `FORMAT(a.ArticleId, '0000')` — `StyleId` değil |
| `Color` | `V_Product`'ta hesaplanır (`V_SKU.[PRODUCT COLOR NAME]`, `/` ayracı); `V_ProductSize` miras alır |
| `SKU` | `ProductCode + '_' + Size` — özel istisnalar kalkar |
| Mimari | `V_ProductSize` `V_Product`'tan türer |
| Kullanılmayan join'ler | Dokunulmaz |

---

## 2. Mimari

```
Style → Article → Variant          →  V_Product          (variant satırı)
                      └→ Size      →  V_ProductSize      (beden satırı)
                                      FROM V_Product
                                      LEFT JOIN Size
```

**`V_Product`:** variant grain. `ProductCode` ve `Color` dahil variant formülleri yalnız burada durur. Mevcut sütunlar aynı kalır; `Color` sona eklenir (mevcut sütun sırası kaymaz).

**`V_ProductSize`:** size grain. `FROM V_Product p LEFT JOIN Size si ON si.VariantId = p.VariantId`. `V_Product` sütunlarını `ProductId` hariç olduğu gibi geçirir (`ProductId` bu view'da zaten yok). `Color` `p.Color` olarak gelir. Ek sütunlar: `SizeId`, `Size`, `Barcode`, `SKU`.

**`V_SKU`:** bu turda durur. Karşılaştırma kaynağı olarak kullanılır.

SP'ler aynı sütun isimlerini okumaya devam eder. `ProductCode` ve `Color` **içerik** olarak değişir (bilinçli).

---

## 3. Formüller

Yalnızca bu üç ifade değişir. Diğer sütunlar (`StyleCode`, `ArticleCode`, `FullArticleCode`, `VariantCode`, `FullVariantCode`, ham kod/isim alanları) dokunulmaz.

### 3.1 `V_Product.ProductCode`

`V_SKU.[FULL PRODUCT CODE]` ile aynı. `V_ProductSize` bunu miras alır.

```sql
mcat.MainCategoryCode + '.'
+ pg.ProductGroupCode
+ tg.TypeGenderCode + '_'
+ pc.ProductCategoryCode
+ FORMAT(a.ArticleId, '0000') + '_'
+ mf.MainFabricCode
+ fm.FabricMaterialCode
+ mc.ColorCode
+ sc.ColorCode
```

Eski kural `FORMAT(s.StyleId, '0000')` idi. Tek kasıtlı fark budur.

### 3.2 `V_Product.Color`

`V_SKU.[PRODUCT COLOR NAME]` ile aynı. `V_ProductSize` `p.Color` olarak miras alır.

```sql
CASE
  WHEN mc.ColorName = sc.ColorName THEN mc.ColorName
  ELSE mc.ColorName + ISNULL('/' + sc.ColorName, '')
END
```

### 3.3 `V_ProductSize.SKU`

`V_SKU.[SKU CODE]` ile aynı.

```sql
p.ProductCode + '_' + si.Size
```

Kalkan özel kurallar: SOC→SOCS, belirli `StyleId`'lerde sezon kodu, beden replace, boşluk→`_`.

SP'ler `SKU` sütununu zaten kullanmıyor; `ProductCode + '_' + Size` üretiyorlar. Yeni `SKU` bu üretime denk düşer.

---

## 4. Sütun sözleşmesi

### `V_Product` (mevcut liste + sonda `Color`)

`StyleId`, `ProductName`, `ArticleId`, `VariantId`, `MainFabricId`, `FabricMaterialId`, `ProductId`, `ProductCode`, `MainCategoryName`, `ProductGroupName`, `TypeGenderName`, `ProductCategoryName`, `StyleName`, `StyleCode`, `SeasonCode`, `MainFabricName`, `MainFabricCode`, `FabricMaterialName`, `FabricMaterialCode`, `MainCategoryCode`, `ProductGroupCode`, `TypeGenderCode`, `ProductCategoryCode`, `MainColorCode`, `MainColorName`, `SecondaryColorCode`, `SecondaryColorName`, `ArticleCode`, `FullArticleCode`, `VariantCode`, `FullVariantCode`, **`Color`** (yeni, sonda)

### `V_ProductSize` (aynı liste)

`V_Product` sütunları **eksi** `ProductId`, **artı** `SizeId`, `Size`, `SKU`, `Barcode`. `Color` `V_Product`'tan gelir; `V_ProductSize` çıktı sırasındaki yeri değişmez (`VariantCode` ile `FullVariantCode` arası).

`SELECT *` kullanılmaz. Sütunlar mevcut `V_ProductSize` sırasıyla açık listelenir (SP'ler isimle seçiyor; sıra yine de korunur).

---

## 5. Tüketiciler (kırılmamalı)

Bu repoda `V_Product` kullanılmıyor. `V_ProductSize` şu sütunlarla kullanılıyor (`sql/Migrate_StoredProcedures.sql`):

| Sütun | Kullanım |
|---|---|
| `SizeId` | join, varlık kontrolü, webhook eşleme |
| `Barcode` | barkod arama |
| `StyleName`, `ProductName` | arama / gösterim |
| `Color` | gösterim (içerik değişir: `/` ayracı) |
| `Size` | gösterim; SKU üretimi |
| `ProductCode` | gösterim; webhook `SkuCode = ProductCode + '_' + Size` (içerik değişir: ArticleId) |

`API_WebHook_ApplyStock` ve `API_WebHook_StockSnapshot` SKU'yu `ProductCode + '_' + Size` ile üretir/eşler. `ProductCode` değişince canlı ecommerce SKU kodları değişir — bu istenen düzeltmedir.

---

## 6. Uygulama sırası

1. `ALTER VIEW dbo.V_Product` — `ProductCode` formülü; `Color` sona eklenir. Kullanılmayan join'ler olduğu gibi kalır.
2. Doğrulama: `V_Product.ProductCode` = `V_SKU.[FULL PRODUCT CODE]`; `V_Product.Color` = `V_SKU.[PRODUCT COLOR NAME]` (VariantId).
3. `ALTER VIEW dbo.V_ProductSize` — `FROM V_Product` + `Size`; `Color` miras; `SKU` yeni formül.
4. Doğrulama: `V_ProductSize` sütun isimleri aynı; `SKU` = `[SKU CODE]`; `Color` = `[PRODUCT COLOR NAME]`; satır sayısı.
5. `V_SKU` durur.

SQL script repoya yazılır; kullanıcı SQL Server'da çalıştırır.

---

## 7. Doğrulama sorguları

Karşılaştırma anahtarı `SizeId` / `VariantId`. `V_SKU` silinmeden önce çalışır.

- `V_ProductSize` sütun isimleri, alter öncesi/sonrası aynı küme.
- `SizeId IS NOT NULL` satır sayısı değişmez (join aynı kaldığı sürece).
- VariantId: `V_Product.ProductCode` = `V_SKU.[FULL PRODUCT CODE]`.
- VariantId: `V_Product.Color` = `V_SKU.[PRODUCT COLOR NAME]`.
- SizeId: `V_ProductSize.SKU` = `V_SKU.[SKU CODE]`.
- SizeId: `V_ProductSize.Color` = `V_SKU.[PRODUCT COLOR NAME]`.
- Uyuşmayan satırlar listelenir; sıfır fark beklenir.

NULL birleşimi bug'ı (`NULL + x = NULL`) kasıtlı olarak düzeltilmez; mevcut davranış korunur.

---

## 8. Bilinçli olarak kapsam dışı

- `V_SKU` silme ve tüketicilerini `V_ProductSize`'a taşıma.
- `v_fullproductcode` ve `V_SKU`'nun web katalog sütunları.
- Kullanılmayan join temizliği.
- `StyleCode` / `ArticleCode` / `FullArticleCode` / `VariantCode` / `FullVariantCode` hizalama.
- Ecommerce tarafta eski StyleId-tabanlı SKU'ları migrate etme (kod değişimi view ile gelir; harici sistemler ayrı iş).

---

## 9. Teslimat

- `sql/` altında `ALTER VIEW` + doğrulama sorguları script'i.
- View tanımları bu script'tedir; uygulama kodu (`SkuCodeMapper`, SP imzaları) değişmez.
