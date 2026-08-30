# V_Product / V_ProductSize Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `V_Product` ve `V_ProductSize` formüllerini `V_SKU` ile hizala; `V_ProductSize`'ı `V_Product`'tan türet; sütun isimlerini koru.

**Architecture:** `V_Product` variant grain ve `ProductCode` kaynağıdır. `V_ProductSize` `FROM V_Product LEFT JOIN Size` ile beden grain üretir; `Color` ve `SKU` burada hesaplanır. `V_SKU` bu turda silinmez; doğrulama kaynağıdır. Uygulama kodu ve SP imzaları değişmez.

**Tech Stack:** SQL Server (`CREATE OR ALTER VIEW`), script `sql/Refactor_V_Product_V_ProductSize.sql`, çalıştırma SSMS / `CavaliERP`.

**Spec:** `docs/superpowers/specs/2026-08-28-product-views-refactor-design.md`

## Global Constraints

- Sütun **isimleri** değişmez. `SELECT *` yok; `V_ProductSize` sütunları mevcut sırayla açık listelenir.
- `ProductCode` = `V_SKU.[FULL PRODUCT CODE]` (`FORMAT(a.ArticleId, '0000')`, StyleId değil).
- `Color` = `V_SKU.[PRODUCT COLOR NAME]` (`/` ayracı).
- `SKU` = `ProductCode + '_' + Size`. SOC→SOCS, sezon, beden replace, boşluk→`_` kalkar.
- `StyleCode`, `ArticleCode`, `FullArticleCode`, `VariantCode`, `FullVariantCode` dokunulmaz.
- Kullanılmayan join'ler (`WebCategory`, `ProductGroupWeb`, `ProductCategoryWeb`, `SizeChart`, `ModelReference`) `V_Product`'ta kalır.
- `V_SKU` silinmez. `v_fullproductcode` dokunulmaz.
- NULL birleşimi (`NULL + x = NULL`) düzeltilmez.
- C#, Flutter, SP gövdeleri değişmez.
- Commit yalnızca kullanıcı isterse. Aksi halde commit adımını atla.

---

## File Map

| Path | Sorumluluk |
|---|---|
| `sql/Refactor_V_Product_V_ProductSize.sql` | `ALTER` `V_Product`, `ALTER` `V_ProductSize`, doğrulama sorguları |
| `sql/Migrate_StoredProcedures.sql` | Salt okunur referans: SP'lerin kullandığı sütun isimleri |
| `docs/superpowers/specs/2026-08-28-product-views-refactor-design.md` | Onaylı spec |

Kaynak view tanımları (mevcut canlı kopya): `c:\Users\kasim\OneDrive\Desktop\view 3 topla.sql`

---

### Task 1: `V_Product` — ProductCode ArticleId

**Files:**
- Create: `sql/Refactor_V_Product_V_ProductSize.sql`

**Interfaces:**
- Consumes: mevcut `V_Product` tanımı (`view 3 topla.sql`); spec §3.1
- Produces: dosyada `CREATE OR ALTER VIEW dbo.V_Product`; `ProductCode` ArticleId kullanır; diğer sütunlar ve join'ler aynı

- [ ] **Step 1: Script başlığı ve `V_Product` view'ını yaz**

Create `sql/Refactor_V_Product_V_ProductSize.sql`:

```sql
/*
================================================================================
 CavalierShop — V_Product / V_ProductSize formül hizalama
================================================================================
 Spec: docs/superpowers/specs/2026-08-28-product-views-refactor-design.md

 1) V_Product.ProductCode = V_SKU.[FULL PRODUCT CODE] (ArticleId)
 2) V_ProductSize FROM V_Product + Size
    Color  = V_SKU.[PRODUCT COLOR NAME]
    SKU    = ProductCode + '_' + Size

 Sütun isimleri değişmez. V_SKU silinmez.

 Kullanım: SSMS'te CavaliERP veritabanında sırayla Execute.
 Önce view bölümünü çalıştır, sonra doğrulama bölümünü çalıştır.
================================================================================
*/

USE [CavaliERP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[V_Product]
AS
SELECT
     s.StyleId
    ,s.ProductName
    ,a.ArticleId
    ,v.VariantId
    ,a.MainFabricId
    ,a.FabricMaterialId
    ,ProductId = v.VariantId
    ,ProductCode =
          mcat.MainCategoryCode + '.'
        + pg.ProductGroupCode
        + tg.TypeGenderCode + '_'
        + pc.ProductCategoryCode
        + FORMAT(a.ArticleId, '0000') + '_'
        + mf.MainFabricCode
        + fm.FabricMaterialCode
        + mc.ColorCode
        + sc.ColorCode
    ,mcat.MainCategoryName
    ,pg.ProductGroupName
    ,tg.TypeGenderName
    ,pc.ProductCategoryName
    ,s.StyleName
    ,StyleCode = REPLACE(s.StyleName, '-', '')
    ,sea.SeasonCode
    ,mf.MainFabricName
    ,mf.MainFabricCode
    ,fm.FabricMaterialName
    ,fm.FabricMaterialCode
    ,mcat.MainCategoryCode
    ,pg.ProductGroupCode
    ,tg.TypeGenderCode
    ,pc.ProductCategoryCode
    ,MainColorCode = mc.ColorCode
    ,MainColorName = mc.ColorName
    ,SecondaryColorCode = sc.ColorCode
    ,SecondaryColorName = sc.ColorName
    ,ArticleCode =
          sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode
    ,FullArticleCode =
          REPLACE(s.StyleName, '-', '') + '_'
        + sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode
    ,VariantCode = CASE
        WHEN mc.ColorCode = sc.ColorCode THEN mc.ColorCode
        ELSE mc.ColorCode + sc.ColorCode
      END
    ,FullVariantCode =
          REPLACE(s.StyleName, '-', '') + '_'
        + sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode + '_'
        + CASE
            WHEN mc.ColorCode = sc.ColorCode THEN mc.ColorCode
            ELSE mc.ColorCode + sc.ColorCode
          END
FROM Style s
LEFT JOIN MainCategory mcat ON mcat.MainCategoryId = s.MainCategoryId
LEFT JOIN WebCategory wcat ON wcat.WebCategoryId = s.WebCategoryId
LEFT JOIN ProductGroup pg ON pg.ProductGroupId = s.ProductGroupId
LEFT JOIN TypeGender tg ON tg.TypeGenderId = s.TypeGenderId
LEFT JOIN ProductCategory pc ON pc.ProductCategoryId = s.ProductCategoryId
LEFT JOIN ProductGroupWeb pgw ON pgw.ProductGroupId = pg.ProductGroupId AND pgw.WebCategoryId = wcat.WebCategoryId
LEFT JOIN ProductCategoryWeb pgc ON pgc.ProductCategoryId = pc.ProductCategoryId AND pgc.WebCategoryId = wcat.WebCategoryId
LEFT JOIN SizeChart sch ON sch.SizeChartId = s.SizeChartId
LEFT JOIN Article a ON a.StyleId = s.StyleId
LEFT JOIN MainFabric mf ON mf.MainFabricId = a.MainFabricId
LEFT JOIN Season sea ON sea.SeasonId = a.SeasonId
LEFT JOIN Variant v ON v.ArticleId = a.ArticleId
LEFT JOIN ModelReference mref ON mref.ModelReferenceId = v.ModelReferenceId
LEFT JOIN FabricMaterial fm ON fm.FabricMaterialId = a.FabricMaterialId
LEFT JOIN Color mc ON mc.ColorId = v.MainColorId
LEFT JOIN Color sc ON sc.ColorId = v.SecondaryColorId
GO
```

`ProductId = v.VariantId` bilinçli: orijinal `ProductId = VariantId` (niteliksiz) ile aynı kaynak. `FORMAT(s.StyleId, '0000')` bu dosyada **olmamalı**.

- [ ] **Step 2: Statik kontrol**

Repo içinde `Refactor_V_Product_V_ProductSize.sql` için:

- `FORMAT(s.StyleId` yok
- `FORMAT(a.ArticleId, '0000')` var
- `LEFT JOIN WebCategory`, `ProductGroupWeb`, `ProductCategoryWeb`, `SizeChart`, `ModelReference` duruyor
- `V_SKU` için `DROP` yok

- [ ] **Step 3: Commit (yalnızca kullanıcı istediyse)**

```bash
git add sql/Refactor_V_Product_V_ProductSize.sql
git commit -m "sql: align V_Product.ProductCode with V_SKU ArticleId formula"
```

---

### Task 2: `V_ProductSize` — `V_Product` + Size

**Files:**
- Modify: `sql/Refactor_V_Product_V_ProductSize.sql` (Task 1 view'ından hemen sonra, doğrulama sorgularından önce)

**Interfaces:**
- Consumes: `dbo.V_Product` sütunları (Task 1); `Size` (`SizeId`, `Size`, `Barcode`, `VariantId`)
- Produces: `CREATE OR ALTER VIEW dbo.V_ProductSize` — mevcut sütun sırası, `ProductId` yok

Orijinal `V_ProductSize` sütun sırası (korunacak):

`StyleId`, `ProductName`, `StyleName`, `ArticleId`, `VariantId`, `SizeId`, `Size`, `MainFabricId`, `FabricMaterialId`, `ProductCode`, `MainCategoryName`, `ProductGroupName`, `TypeGenderName`, `ProductCategoryName`, `StyleCode`, `SeasonCode`, `MainFabricName`, `MainFabricCode`, `FabricMaterialName`, `FabricMaterialCode`, `MainCategoryCode`, `ProductGroupCode`, `TypeGenderCode`, `ProductCategoryCode`, `MainColorCode`, `MainColorName`, `SecondaryColorCode`, `SecondaryColorName`, `ArticleCode`, `FullArticleCode`, `VariantCode`, `Color`, `FullVariantCode`, `SKU`, `Barcode`

- [ ] **Step 1: `V_ProductSize` view'ını aynı dosyaya ekle**

Task 1'deki `V_Product` `GO` satırından sonra ekle:

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[V_ProductSize]
AS
SELECT
     p.StyleId
    ,p.ProductName
    ,p.StyleName
    ,p.ArticleId
    ,p.VariantId
    ,si.SizeId
    ,si.Size
    ,p.MainFabricId
    ,p.FabricMaterialId
    ,p.ProductCode
    ,p.MainCategoryName
    ,p.ProductGroupName
    ,p.TypeGenderName
    ,p.ProductCategoryName
    ,p.StyleCode
    ,p.SeasonCode
    ,p.MainFabricName
    ,p.MainFabricCode
    ,p.FabricMaterialName
    ,p.FabricMaterialCode
    ,p.MainCategoryCode
    ,p.ProductGroupCode
    ,p.TypeGenderCode
    ,p.ProductCategoryCode
    ,p.MainColorCode
    ,p.MainColorName
    ,p.SecondaryColorCode
    ,p.SecondaryColorName
    ,p.ArticleCode
    ,p.FullArticleCode
    ,p.VariantCode
    ,Color = CASE
        WHEN p.MainColorName = p.SecondaryColorName THEN p.MainColorName
        ELSE p.MainColorName + ISNULL('/' + p.SecondaryColorName, '')
      END
    ,p.FullVariantCode
    ,SKU = p.ProductCode + '_' + si.Size
    ,si.Barcode
FROM dbo.V_Product p
LEFT JOIN dbo.Size si ON si.VariantId = p.VariantId
GO
```

Yasaklar (bu view gövdesinde olmamalı):

- `SOC` / `SOCS`
- `SizeId in (284`
- `s.StyleId in (94`
- `REPLACE(..., ' ', '_')`
- `FROM Style s` (yalnızca `FROM dbo.V_Product`)
- `p.ProductId` (bu view'da yok)

- [ ] **Step 2: Sütun sırasını orijinal listeyle karşılaştır**

Yukarıdaki 35 isim, SELECT listesiyle birebir aynı sırada olmalı.

- [ ] **Step 3: Commit (yalnızca kullanıcı istediyse)**

```bash
git add sql/Refactor_V_Product_V_ProductSize.sql
git commit -m "sql: derive V_ProductSize from V_Product with V_SKU Color and SKU"
```

---

### Task 3: Doğrulama sorguları

**Files:**
- Modify: `sql/Refactor_V_Product_V_ProductSize.sql` (view tanımlarından sonra)

**Interfaces:**
- Consumes: `dbo.V_Product`, `dbo.V_ProductSize`, `dbo.V_SKU` (silinmemiş)
- Produces: yorumla ayrılmış doğrulama batch'leri; beklenen sonuç her biri 0 fark satırı / eşleşen sütun kümesi

- [ ] **Step 1: Doğrulama bölümünü dosya sonuna ekle**

View `GO`'larından sonra:

```sql
/*
================================================================================
 Doğrulama — view'lar alter edildikten sonra bu bölümü çalıştır.
 V_SKU hâlâ duruyor olmalı.
 Beklenen: her sonuç kümesinde 0 satır (sütun kümesi sorgusu hariç).
================================================================================
*/

-- A) V_ProductSize sütun isimleri (beklenen 35 ad, bu sıra)
SELECT c.name, c.column_id
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(N'dbo.V_ProductSize')
ORDER BY c.column_id;
-- Beklenen name sırası:
-- StyleId, ProductName, StyleName, ArticleId, VariantId, SizeId, Size,
-- MainFabricId, FabricMaterialId, ProductCode, MainCategoryName, ProductGroupName,
-- TypeGenderName, ProductCategoryName, StyleCode, SeasonCode, MainFabricName,
-- MainFabricCode, FabricMaterialName, FabricMaterialCode, MainCategoryCode,
-- ProductGroupCode, TypeGenderCode, ProductCategoryCode, MainColorCode,
-- MainColorName, SecondaryColorCode, SecondaryColorName, ArticleCode,
-- FullArticleCode, VariantCode, Color, FullVariantCode, SKU, Barcode

-- B) ProductCode ≠ [FULL PRODUCT CODE] (VariantId)
SELECT
     p.VariantId
    ,p.ProductCode
    ,k.[FULL PRODUCT CODE] AS SkuFullProductCode
FROM dbo.V_Product p
INNER JOIN (
    SELECT VariantId, MIN([FULL PRODUCT CODE]) AS [FULL PRODUCT CODE]
    FROM dbo.V_SKU
    GROUP BY VariantId
) k ON k.VariantId = p.VariantId
WHERE ISNULL(p.ProductCode, N'') <> ISNULL(k.[FULL PRODUCT CODE], N'');
-- Beklenen: 0 satır

-- C) SKU ≠ [SKU CODE] (SizeId)
SELECT
     ps.SizeId
    ,ps.SKU
    ,k.[SKU CODE] AS SkuCode
FROM dbo.V_ProductSize ps
INNER JOIN dbo.V_SKU k ON k.SizeId = ps.SizeId
WHERE ISNULL(ps.SKU, N'') <> ISNULL(k.[SKU CODE], N'');
-- Beklenen: 0 satır

-- D) Color ≠ [PRODUCT COLOR NAME] (SizeId)
SELECT
     ps.SizeId
    ,ps.Color
    ,k.[PRODUCT COLOR NAME] AS SkuColor
FROM dbo.V_ProductSize ps
INNER JOIN dbo.V_SKU k ON k.SizeId = ps.SizeId
WHERE ISNULL(ps.Color, N'') <> ISNULL(k.[PRODUCT COLOR NAME], N'');
-- Beklenen: 0 satır

-- E) SizeId satır sayısı (V_ProductSize vs V_SKU)
SELECT
     (SELECT COUNT(*) FROM dbo.V_ProductSize WHERE SizeId IS NOT NULL) AS ProductSizeRows
    ,(SELECT COUNT(*) FROM dbo.V_SKU WHERE SizeId IS NOT NULL) AS SkuRows;
-- Beklenen: iki sayı eşit (join farkı varsa dur ve kullanıcıya sor; sessizce düzeltme)
```

- [ ] **Step 2: Script'i kullanıcıya bırak**

Bu workspace SQL Server'a bağlı değil. Script'i SSMS'te `CavaliERP` üzerinde çalıştırma kullanıcıya ait.

Söylem: view bölümünü çalıştır → doğrulama A–E. B/C/D 0 satır değilse dur; tahminle düzeltme.

- [ ] **Step 3: Commit (yalnızca kullanıcı istediyse)**

```bash
git add sql/Refactor_V_Product_V_ProductSize.sql
git commit -m "sql: add V_Product/V_ProductSize verification queries against V_SKU"
```

---

### Task 4: SP sütun sözleşmesi — dokunulmadığını doğrula

**Files:**
- Read: `sql/Migrate_StoredProcedures.sql` (değiştirme)
- Read: `sql/Refactor_V_Product_V_ProductSize.sql`

**Interfaces:**
- Consumes: SP'lerin `V_ProductSize` sütunları: `SizeId`, `Barcode`, `StyleName`, `ProductName`, `Color`, `Size`, `ProductCode`
- Produces: script SELECT listesinde bu 7 isim var; SP dosyası değişmemiş

- [ ] **Step 1: SP dosyasında `V_ProductSize` sütun kullanımlarını tara**

```powershell
Select-String -Path sql/Migrate_StoredProcedures.sql -Pattern "V_ProductSize|ss\.(SizeId|Barcode|StyleName|ProductName|Color|Size|ProductCode)|ps\.(SizeId|Barcode|StyleName|ProductName|Color|Size|ProductCode)"
```

Beklenen: join/filtre bu isimlerle; `SKU` sütununa referans yok. `SkuCode = ProductCode + '_' + Size` duruyor.

- [ ] **Step 2: Yeni view SELECT listesinde bu 7 isim var mı bak**

`sql/Refactor_V_Product_V_ProductSize.sql` içinde `V_ProductSize` SELECT'i `p.ProductCode`, `si.Size`, `Color =`, `si.Barcode`, `p.StyleName`, `p.ProductName`, `si.SizeId` içerir.

- [ ] **Step 3: Uygulama koduna dokunulmadığını doğrula**

`api/CavaliERP.API/Services/Ecommerce/SkuCodeMapper.cs` ve `sql/Migrate_StoredProcedures.sql` bu işte değişmez.

---

## Spec coverage

| Spec | Task |
|---|---|
| `ProductCode` ArticleId / `[FULL PRODUCT CODE]` | 1, 3B |
| `Color` `/` ayracı / `[PRODUCT COLOR NAME]` | 2, 3D |
| `SKU = ProductCode + '_' + Size` | 2, 3C |
| `V_ProductSize` ← `V_Product` + Size | 2 |
| Sütun isimleri + sıra, `SELECT *` yok | 2, 3A |
| Kullanılmayan join'ler kalır | 1 |
| `StyleCode` vb. dokunulmaz | 1 |
| `V_SKU` silinmez | 1, 3 |
| SP tüketicileri kırılmaz | 4 |
| Teslimat `sql/` script | 1–3 |
| C# / Flutter / SP değişmez | 4 |
| Ecommerce SKU migrate (kapsam dışı) | yok |
| `V_SKU` drop (kapsam dışı) | yok |
