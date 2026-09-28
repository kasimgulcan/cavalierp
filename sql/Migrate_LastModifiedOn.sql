-- LastModifiedOn for every table behind V_SKU / V_Product / V_ProductSize (07.09.2026)
-- INSERT: DEFAULT SYSUTCDATETIME()
-- UPDATE: trigger stamps SYSUTCDATETIME() (TRIGGER_NESTLEVEL avoids recursion)
-- Size: InStockQty-only updates do not bump LastModifiedOn (stock is not catalog)
-- Existing rows get the run-time UTC stamp (first since= still needs a full snapshot or this seed).

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Tables TABLE
(
    TableName sysname NOT NULL,
    PkColumn  sysname NOT NULL
);

INSERT INTO @Tables (TableName, PkColumn) VALUES
    (N'Style',               N'StyleId'),
    (N'Article',             N'ArticleId'),
    (N'Variant',             N'VariantId'),
    (N'Size',                N'SizeId'),
    (N'MainCategory',        N'MainCategoryId'),
    (N'WebCategory',         N'WebCategoryId'),
    (N'ProductGroup',        N'ProductGroupId'),
    (N'ProductGroupWeb',     N'ProductGroupWebId'),
    (N'TypeGender',          N'TypeGenderId'),
    (N'ProductCategory',     N'ProductCategoryId'),
    (N'ProductCategoryWeb',  N'ProductCategoryWebId'),
    (N'SizeChart',           N'SizeChartId'),
    (N'MainFabric',          N'MainFabricId'),
    (N'FabricMaterial',      N'FabricMaterialId'),
    (N'Season',              N'SeasonId'),
    (N'ModelReference',      N'ModelReferenceId'),
    (N'Color',               N'ColorId'),
    (N'SizeSet',             N'SizeSetId');

DECLARE
    @table sysname,
    @pk    sysname,
    @sql   nvarchar(max),
    @df    sysname,
    @tr    sysname;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, PkColumn FROM @Tables;

OPEN c;
FETCH NEXT FROM c INTO @table, @pk;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'dbo.' + @table, N'U') IS NULL
        THROW 50001, 'Expected catalog table is missing.', 1;

    IF COL_LENGTH(N'dbo.' + @table, N'LastModifiedOn') IS NULL
    BEGIN
        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@table)
            + N' ADD LastModifiedOn datetimeoffset(7) NULL;';
        EXEC sys.sp_executesql @sql;
    END;

    SET @sql = N'UPDATE dbo.' + QUOTENAME(@table)
        + N' SET LastModifiedOn = SYSUTCDATETIME() WHERE LastModifiedOn IS NULL;';
    EXEC sys.sp_executesql @sql;

    SET @df = N'DF_' + @table + N'_LastModifiedOn';
    IF NOT EXISTS (
        SELECT 1
        FROM sys.default_constraints dc
        INNER JOIN sys.tables t ON t.object_id = dc.parent_object_id
        WHERE t.name = @table
          AND SCHEMA_NAME(t.schema_id) = N'dbo'
          AND dc.name = @df
    )
    BEGIN
        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@table)
            + N' ADD CONSTRAINT ' + QUOTENAME(@df)
            + N' DEFAULT SYSUTCDATETIME() FOR LastModifiedOn;';
        EXEC sys.sp_executesql @sql;
    END;

    SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@table)
        + N' ALTER COLUMN LastModifiedOn datetimeoffset(7) NOT NULL;';
    EXEC sys.sp_executesql @sql;

    SET @tr = N'TR_' + @table + N'_LastModifiedOn';

    IF @table = N'Size'
    BEGIN
        SET @sql = N'
CREATE OR ALTER TRIGGER ' + QUOTENAME(@tr) + N'
ON dbo.Size
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
       AND NOT EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON d.SizeId = i.SizeId
            WHERE ISNULL(i.Size, N'''') <> ISNULL(d.Size, N'''')
               OR ISNULL(i.Barcode, N'''') <> ISNULL(d.Barcode, N'''')
               OR ISNULL(i.VariantId, -1) <> ISNULL(d.VariantId, -1)
       )
        RETURN;

    UPDATE t
    SET LastModifiedOn = SYSUTCDATETIME()
    FROM dbo.Size t
    INNER JOIN inserted i ON i.SizeId = t.SizeId;
END;';
    END
    ELSE
    BEGIN
        SET @sql = N'
CREATE OR ALTER TRIGGER ' + QUOTENAME(@tr) + N'
ON dbo.' + QUOTENAME(@table) + N'
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE t
    SET LastModifiedOn = SYSUTCDATETIME()
    FROM dbo.' + QUOTENAME(@table) + N' t
    INNER JOIN inserted i ON i.' + QUOTENAME(@pk) + N' = t.' + QUOTENAME(@pk) + N';
END;';
    END;

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM c INTO @table, @pk;
END;

CLOSE c;
DEALLOCATE c;
GO

-- V_SKU.LastModifiedOn = MAX of catalog tables behind the row (07.09.2026)
-- Requires LastModifiedOn columns from the batch above.
-- SizeSet is included because GetSKU SIZE RANGE comes from SizeSet.

CREATE OR ALTER VIEW dbo.V_SKU
AS
SELECT
     [BARCODE GS1/EAN] = ps.Barcode
    ,[ART. #] = FORMAT(ps.ArticleId, '0000')
    ,[STYLE NAME] = ps.StyleName
    ,[PRODUCT NAME] = ps.ProductName
    ,[PRODUCT CODE] = ps.StyleName + ' / '
        + ps.MainFabricCode
        + ps.FabricMaterialCode
        + ps.MainColorCode
        + ps.SecondaryColorCode
    ,SIZE = ps.Size
    ,ps.SizeId
    ,[MAIN CATEGORY] = ps.MainCategoryName
    ,[WEB CATEGORY] = wcat.WebCategoryName
    ,[PRODUCT GROUP] = ps.ProductGroupName
    ,[TYPE / GENDER] = ps.TypeGenderName
    ,[PRODUCT CATEGORY] = ps.ProductCategoryName
    ,[SEASON] = ps.SeasonCode
    ,[MAIN FABRIC] = ps.MainFabricName
    ,[MAIN COLOR] = ps.MainColorName
    ,[SECONDARY COLOR] = ps.SecondaryColorName
    ,[PRODUCT COLOR NAME] = ps.Color
    ,[MODEL CODE] =
          ps.MainCategoryCode + '.'
        + ps.ProductGroupCode
        + ps.TypeGenderCode + '_'
        + ps.ProductCategoryCode
        + FORMAT(ps.ArticleId, '0000')
    ,[FABRIC + COLOR CODE] =
          ps.MainFabricCode
        + ps.FabricMaterialCode
        + ps.MainColorCode
        + ps.SecondaryColorCode
    ,[FULL PRODUCT CODE] = ps.ProductCode
    ,[SKU CODE] = ps.SKU
    ,[MAIN PHOTO] = v.MainPhoto
    ,[PHOTO 2] = v.Photo2
    ,[PHOTO 3] = v.Photo3
    ,[PHOTO 4] = v.Photo4
    ,[PHOTO 5] = v.Photo5
    ,[PHOTO 6] = v.Photo6
    ,[VIDEO] = v.Video
    ,[EXTRA MEDIA] = v.ExtraMedia
    ,[PRODUCT TITLE] = ps.StyleName + ' ' + ps.Color + ' ' + ps.ProductName + ' '
    ,[PRODUCT DESCRIPTION] = s.ProductDescription
    ,[PRODUCT FEATURES] = s.ProductFeatures
    ,[CARE INSTRUCTIONS] = s.CareInstructions
    ,[ÜRÜN ADI] = ps.StyleName + ' ' + ps.Color + ' ' + s.UrunAdi + ' '
    ,[ÜRÜN AÇIKLAMASI] = s.UrunAciklamasi
    ,[ÜRÜN ÖZELLİKLERİ] = s.UrunOzellikleri
    ,[YIKAMA TALİMATLARI] = s.YikamaTalimatlari
    ,[TITOLO DEL PRODOTTO] = ps.StyleName + ' ' + ps.Color + ' ' + s.NomeDelProdotto + ' '
    ,[DESCRIZIONE DEL PRODOTTO] = s.DescrizioneDelProdotto
    ,[CARATTERISTICHE DEL PRODOTTO] = s.CaratteristicheDelProdotto
    ,[ISTRUZIONI PER LA CURA] = s.IstruzioniPerLaCura
    ,[PRODUKTTITEL] = ps.StyleName + ' ' + ps.Color + ' ' + s.Produktname + ' '
    ,[PRODUKT BESCHREIBUNG] = s.Produktbeschreibung
    ,[PRODUKT MERKMALE] = s.Produktmerkmale
    ,[PFLEGEHINWEISE] = s.Pflegehinweise
    ,[ALSO IN THE PHOTO 1] = c1.FullProductCode
    ,[ALSO IN THE PHOTO 2] = c2.FullProductCode
    ,[ALSO IN THE PHOTO 3] = c3.FullProductCode
    ,[ALSO IN THE PHOTO 4] = c4.FullProductCode
    ,[ALSO IN THE PHOTO 5] = c5.FullProductCode
    ,[RELATED PRODUCTS 1] = v.RelatedProducts1
    ,[RELATED PRODUCTS 2] = v.RelatedProducts2
    ,[RELATED PRODUCTS 3] = v.RelatedProducts3
    ,[RELATED PRODUCTS 4] = v.RelatedProducts4
    ,[RELATED PRODUCTS 5] = v.RelatedProducts5
    ,[MAIN CATEGORY ID] = mcat.WebSiteCode
    ,[WEB CATEGORY ID] = wcat.WebSiteCode
    ,[PRODUCT GROUP ID] = pgw.WebSiteCode
    ,[TYPE/GRENDER ID] = tg.TypeGenderId
    ,[PRODUCT CATEGORY ID] = pgc.WebSiteCode
    ,[ATTRIBUTES (EX-PRODUCT CAT) ID] = NULL
    ,[NEW IN] = CASE WHEN v.NewIn = 1 THEN 75 ELSE NULL END
    ,[BESTSELLERS] = CASE WHEN v.Bestsellers = 1 THEN 204 ELSE NULL END
    ,[SHOP THE LOOK] = ''
    ,[COMPETITION] = CASE WHEN v.[Competition] = 1 THEN 21 ELSE NULL END
    ,[OUTLET] = ''
    ,[TBF X SANMARCO] = CASE WHEN v.TBFXSanMarco = 1 THEN 206 ELSE NULL END
    ,[ADDITIONAL (MANUAL) CAT.] = v.WebSiteAdditionalCategories
    ,[VARIANTS] = v.WebSiteVariant
    ,[PRICE EURO] = FORMAT(PriceEUR, 'N', 'en-US')
    ,[PRICE TL] = FORMAT(PriceTL, 'N', 'en-US')
    ,[PRICE USD] = FORMAT(PriceUSD, 'N', 'en-US')
    ,[INITIAL STOCK QTY] = NULL
    ,[SOLD QTY] = NULL
    ,[IN-STOCK QTY] = ps.InStockQty
    ,[PUBLISH] = CASE WHEN ISNULL(v.Publish, 0) = 0 THEN '0' ELSE '1' END
    ,[MODEL REFERENCE] = mref.WebSiteCode
    ,[SIZE CHART REFERENCE] = sch.SizeChartCode
    ,[MADE IN ITALY LOGO] = CASE WHEN s.MadeInItalyLogo = 1 THEN '1' ELSE '' END
    ,[UPDATE] = NULL
    ,[NOTES] = NULL
    ,s.SizeSetId
    ,ps.StyleId
    ,[THE AFTER COLLECTION] = CASE WHEN v.TheAfterCollection = 1 THEN '242' ELSE NULL END
    ,[MODEL SIZE INFO] = mref.Caption
    ,LastModifiedOn = (
        SELECT MAX(d)
        FROM (VALUES
            (s.LastModifiedOn),
            (a.LastModifiedOn),
            (v.LastModifiedOn),
            (si.LastModifiedOn),
            (mcat.LastModifiedOn),
            (wcat.LastModifiedOn),
            (pg.LastModifiedOn),
            (pgw.LastModifiedOn),
            (tg.LastModifiedOn),
            (pc.LastModifiedOn),
            (pgc.LastModifiedOn),
            (sch.LastModifiedOn),
            (mf.LastModifiedOn),
            (fm.LastModifiedOn),
            (sea.LastModifiedOn),
            (mref.LastModifiedOn),
            (mc.LastModifiedOn),
            (sc.LastModifiedOn),
            (szs.LastModifiedOn)
        ) AS x(d)
    )
FROM dbo.V_ProductSize ps
LEFT JOIN dbo.Style s ON s.StyleId = ps.StyleId
LEFT JOIN dbo.Article a ON a.ArticleId = ps.ArticleId
LEFT JOIN dbo.Variant v ON v.VariantId = ps.VariantId
LEFT JOIN dbo.Size si ON si.SizeId = ps.SizeId
LEFT JOIN dbo.MainCategory mcat ON mcat.MainCategoryId = s.MainCategoryId
LEFT JOIN dbo.WebCategory wcat ON wcat.WebCategoryId = s.WebCategoryId
LEFT JOIN dbo.ProductGroup pg ON pg.ProductGroupId = s.ProductGroupId
LEFT JOIN dbo.ProductGroupWeb pgw ON pgw.ProductGroupId = s.ProductGroupId AND pgw.WebCategoryId = wcat.WebCategoryId
LEFT JOIN dbo.TypeGender tg ON tg.TypeGenderId = s.TypeGenderId
LEFT JOIN dbo.ProductCategory pc ON pc.ProductCategoryId = s.ProductCategoryId
LEFT JOIN dbo.ProductCategoryWeb pgc ON pgc.ProductCategoryId = s.ProductCategoryId AND pgc.WebCategoryId = wcat.WebCategoryId
LEFT JOIN dbo.SizeChart sch ON sch.SizeChartId = s.SizeChartId
LEFT JOIN dbo.MainFabric mf ON mf.MainFabricId = a.MainFabricId
LEFT JOIN dbo.FabricMaterial fm ON fm.FabricMaterialId = a.FabricMaterialId
LEFT JOIN dbo.Season sea ON sea.SeasonId = a.SeasonId
LEFT JOIN dbo.ModelReference mref ON mref.ModelReferenceId = v.ModelReferenceId
LEFT JOIN dbo.Color mc ON mc.ColorId = v.MainColorId
LEFT JOIN dbo.Color sc ON sc.ColorId = v.SecondaryColorId
LEFT JOIN dbo.SizeSet szs ON szs.SizeSetId = s.SizeSetId
LEFT JOIN dbo.V_FullProductCode c1 ON c1.VariantId = v.AlsoInThePhoto1
LEFT JOIN dbo.V_FullProductCode c2 ON c2.VariantId = v.AlsoInThePhoto2
LEFT JOIN dbo.V_FullProductCode c3 ON c3.VariantId = v.AlsoInThePhoto3
LEFT JOIN dbo.V_FullProductCode c4 ON c4.VariantId = v.AlsoInThePhoto4
LEFT JOIN dbo.V_FullProductCode c5 ON c5.VariantId = v.AlsoInThePhoto5
GO

-- GetSKU: optional @Since; COLOR VARIANTS / SIZE RANGE still from the full catalog.
-- LastModifiedOn is appended; existing column order is unchanged.

CREATE OR ALTER PROCEDURE dbo.GetSKU
    @Since datetimeoffset(7) = NULL
AS
SELECT *
INTO #x
FROM dbo.V_SKU;

WITH d AS
(
    SELECT DISTINCT
        [STYLE NAME],
        [PRODUCT COLOR NAME]
    FROM #x
)
SELECT
    [STYLE NAME],
    STRING_AGG([PRODUCT COLOR NAME], ';') WITHIN GROUP (ORDER BY [PRODUCT COLOR NAME]) AS [COLOR VARIANTS OF STYLE]
INTO #Colors
FROM d
GROUP BY [STYLE NAME];

WITH d AS
(
    SELECT DISTINCT
        [STYLE NAME],
        SizeSetId,
        [SIZE]
    FROM #x
)
SELECT
    [STYLE NAME],
    d.SizeSetId,
    STRING_AGG([SIZE], ';') WITHIN GROUP (ORDER BY v.Pos, d.[SIZE]) AS [SIZE RANGE OF STYLE]
INTO #sizes
FROM d
INNER JOIN V_SizeSetSize v
    ON v.SizeSetId = d.SizeSetId
   AND v.SizeValue = d.[SIZE]
GROUP BY [STYLE NAME], d.SizeSetId;

SELECT
     s.[BARCODE GS1/EAN]
    ,s.[ART. #]
    ,s.[STYLE NAME]
    ,s.[PRODUCT NAME]
    ,s.[PRODUCT CODE]
    ,s.SIZE
    ,s.[MAIN CATEGORY]
    ,s.[WEB CATEGORY]
    ,s.[PRODUCT GROUP]
    ,s.[TYPE / GENDER]
    ,s.[PRODUCT CATEGORY]
    ,s.[SEASON]
    ,s.[MAIN FABRIC]
    ,s.[MAIN COLOR]
    ,s.[SECONDARY COLOR]
    ,s.[PRODUCT COLOR NAME]
    ,s.[MODEL CODE]
    ,s.[FABRIC + COLOR CODE]
    ,s.[FULL PRODUCT CODE]
    ,s.[SKU CODE]
    ,[BARCODE GS1/EAN ] = s.[BARCODE GS1/EAN]
    ,c.[COLOR VARIANTS OF STYLE]
    ,si.[SIZE RANGE OF STYLE]
    ,s.[MAIN PHOTO]
    ,s.[PHOTO 2]
    ,s.[PHOTO 3]
    ,s.[PHOTO 4]
    ,s.[PHOTO 5]
    ,s.[PHOTO 6]
    ,s.[VIDEO]
    ,s.[EXTRA MEDIA]
    ,s.[PRODUCT TITLE]
    ,s.[PRODUCT DESCRIPTION]
    ,s.[PRODUCT FEATURES]
    ,s.[CARE INSTRUCTIONS]
    ,s.[ÜRÜN ADI]
    ,s.[ÜRÜN AÇIKLAMASI]
    ,s.[ÜRÜN ÖZELLİKLERİ]
    ,s.[YIKAMA TALİMATLARI]
    ,s.[TITOLO DEL PRODOTTO]
    ,s.[DESCRIZIONE DEL PRODOTTO]
    ,s.[CARATTERISTICHE DEL PRODOTTO]
    ,s.[ISTRUZIONI PER LA CURA]
    ,s.[PRODUKTTITEL]
    ,s.[PRODUKT BESCHREIBUNG]
    ,s.[PRODUKT MERKMALE]
    ,s.[PFLEGEHINWEISE]
    ,s.[ALSO IN THE PHOTO 1]
    ,s.[ALSO IN THE PHOTO 2]
    ,s.[ALSO IN THE PHOTO 3]
    ,s.[ALSO IN THE PHOTO 4]
    ,s.[ALSO IN THE PHOTO 5]
    ,s.[RELATED PRODUCTS 1]
    ,s.[RELATED PRODUCTS 2]
    ,s.[RELATED PRODUCTS 3]
    ,s.[RELATED PRODUCTS 4]
    ,s.[RELATED PRODUCTS 5]
    ,s.[MAIN CATEGORY ID]
    ,s.[WEB CATEGORY ID]
    ,s.[PRODUCT GROUP ID]
    ,s.[TYPE/GRENDER ID]
    ,s.[PRODUCT CATEGORY ID]
    ,s.[ATTRIBUTES (EX-PRODUCT CAT) ID]
    ,s.[NEW IN]
    ,s.[BESTSELLERS]
    ,s.[SHOP THE LOOK]
    ,s.[COMPETITION]
    ,s.[OUTLET]
    ,s.[TBF X SANMARCO]
    ,[TOTAL CATEGORIES] = (
            SELECT STRING_AGG(val, ';') WITHIN GROUP (ORDER BY min_ord)
            FROM (
                SELECT val, MIN(ord) AS min_ord
                FROM (VALUES
                    (1, CAST(s.[MAIN CATEGORY ID] AS VARCHAR(50))),
                    (2, CAST(s.[WEB CATEGORY ID] AS VARCHAR(50))),
                    (3, CAST(s.[PRODUCT GROUP ID] AS VARCHAR(50))),
                    (4, CAST(s.[PRODUCT CATEGORY ID] AS VARCHAR(50))),
                    (5, CAST(s.[NEW IN] AS VARCHAR(50))),
                    (6, CAST(s.BESTSELLERS AS VARCHAR(50))),
                    (7, CAST(s.[SHOP THE LOOK] AS VARCHAR(50))),
                    (8, CAST(s.COMPETITION AS VARCHAR(50))),
                    (9, CAST(s.OUTLET AS VARCHAR(50))),
                    (10, CAST(s.[TBF X SANMARCO] AS VARCHAR(50))),
                    (11, CAST(s.[ADDITIONAL (MANUAL) CAT.] AS VARCHAR(50))),
                    (12, CAST(s.[THE AFTER COLLECTION] AS VARCHAR(50)))
                ) AS t(ord, val)
                WHERE NULLIF(val, '') IS NOT NULL
                GROUP BY val
            ) v
        )
    ,s.[ADDITIONAL (MANUAL) CAT.]
    ,s.[VARIANTS]
    ,s.[PRICE EURO]
    ,s.[PRICE TL]
    ,s.[PRICE USD]
    ,s.[INITIAL STOCK QTY]
    ,s.[SOLD QTY]
    ,s.[IN-STOCK QTY]
    ,s.[PUBLISH]
    ,s.[MODEL REFERENCE]
    ,s.[SIZE CHART REFERENCE]
    ,s.[MADE IN ITALY LOGO]
    ,s.[UPDATE]
    ,s.[NOTES]
    ,s.[THE AFTER COLLECTION]
    ,s.[MODEL SIZE INFO]
    ,[SKU ID] = s.SizeId
    ,s.LastModifiedOn
FROM #x s
LEFT JOIN #Colors c ON c.[STYLE NAME] = s.[STYLE NAME]
LEFT JOIN #sizes si ON si.[STYLE NAME] = s.[STYLE NAME]
WHERE @Since IS NULL OR s.LastModifiedOn >= @Since
ORDER BY s.StyleId;
GO

-- GetSKU_ModelReference: LastModifiedOn on both snapshot result sets (07.09.2026)
-- styleModels: MAX(V_SKU.LastModifiedOn) per existing DISTINCT grain (sizes must not duplicate rows).
-- models: ModelReference.LastModifiedOn.

CREATE OR ALTER PROCEDURE dbo.GetSKU_ModelReference
    @Since datetimeoffset(7) = NULL
AS
SELECT
     [STYLE NAME]
    ,[PRODUCT NAME]
    ,[PRODUCT CODE]
    ,[MAIN COLOR]
    ,[SECONDARY COLOR]
    ,[FULL PRODUCT CODE]
    ,[MODEL REFERENCE]
    ,LastModifiedOn = MAX(LastModifiedOn)
FROM dbo.V_SKU
GROUP BY
     [STYLE NAME]
    ,[PRODUCT NAME]
    ,[PRODUCT CODE]
    ,[MAIN COLOR]
    ,[SECONDARY COLOR]
    ,[FULL PRODUCT CODE]
    ,[MODEL REFERENCE]
HAVING @Since IS NULL OR MAX(LastModifiedOn) >= @Since;

SELECT
     [MODEL NAME] = ModelName
    ,[MODEL REFERENCE] = WebSiteCode
    ,[MODEL GENDER] = ModelGender
    ,[MODEL AGE] = ModelAge
    ,[MODEL ORIGIN] = ModelOrigin
    ,[MODEL AGENCY] = ModelAgency
    ,[CAPTION] = Caption
    ,[HEIGHT] = CONCAT(HeightCm, CASE WHEN HeightCm IS NULL THEN '' ELSE ' CM' END)
    ,[WEIGHT] = CONCAT(WeightKg, CASE WHEN WeightKg IS NULL THEN '' ELSE ' KM' END)
    ,[CHEST] = CONCAT(ChestCm, CASE WHEN ChestCm IS NULL THEN '' ELSE ' CM' END)
    ,[WAIST] = CONCAT(WaistCm, CASE WHEN WaistCm IS NULL THEN '' ELSE ' CM' END)
    ,[HIPS] = CONCAT(HipsCm, CASE WHEN HipsCm IS NULL THEN '' ELSE ' CM' END)
    ,[SHOE SIZE] = CONCAT(ShoeSizeEU, CASE WHEN ShoeSizeEU IS NULL THEN '' ELSE ' EU' END)
    ,LastModifiedOn
FROM dbo.ModelReference
WHERE @Since IS NULL OR LastModifiedOn >= @Since;
GO

CREATE OR ALTER PROCEDURE dbo.GetSKUSnapshot
    @Since datetimeoffset(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.GetSKU @Since = @Since;
    EXEC dbo.GetSKU_ModelReference @Since = @Since;
END
GO
