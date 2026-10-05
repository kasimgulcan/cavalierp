-- Ürün listesi sayfası beden satırında kesilmesin.
-- Sayfaya giren bir ProductCode'un diğer bedenleri de aynı cevapta döner.
-- Böylece 30 satırlık sayfa M'de bölünse bile L ve XL ilk istekte gelir.
-- Sıra, filtre ve Pos aynı kalır. Uygulama aynı SizeId'yi yok sayar.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Product_List]
    @Search NVARCHAR(100) = NULL,
    @CurrencyId INT = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 20;

    ;WITH filtered AS (
        SELECT
            ss.SizeId,
            ss.Barcode,
            ss.StyleName,
            ss.ProductName,
            ss.Color,
            ss.Size,
            ss.ProductCode,
            s.PriceTL,
            s.PriceEUR,
            s.PriceUSD,
            StockQty = ISNULL(st.StockQty, 0),
            Pos = sz.Pos,
            GroupKey = CASE
                WHEN NULLIF(LTRIM(RTRIM(ss.ProductCode)), N'') IS NULL
                    THEN N'size:' + CONVERT(NVARCHAR(20), ss.SizeId)
                ELSE ss.ProductCode
            END
        FROM dbo.V_ProductSize ss
        INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
        LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
        LEFT JOIN dbo.V_SizeSetSize sz
            ON sz.SizeSetId = ss.SizeSetId
           AND sz.SizeValue = ss.Size
        WHERE ss.SizeId IS NOT NULL
          AND (
              @Search IS NULL
           OR @Search = N''
           OR ss.ProductName LIKE N'%' + @Search + N'%'
           OR ss.StyleName LIKE N'%' + @Search + N'%'
           OR ss.ProductGroupName LIKE N'%' + @Search + N'%'
           OR ss.ProductCategoryName LIKE N'%' + @Search + N'%'
           OR ss.MainCategoryName LIKE N'%' + @Search + N'%'
           OR ss.Color LIKE N'%' + @Search + N'%'
           OR ss.Barcode LIKE N'%' + @Search + N'%')
    ),
    numbered AS (
        SELECT
            *,
            rn = ROW_NUMBER() OVER (
                ORDER BY StyleName, ProductName, Pos, SizeId
            )
        FROM filtered
    ),
    page_groups AS (
        SELECT DISTINCT GroupKey
        FROM numbered
        WHERE rn > (@Page - 1) * @PageSize
          AND rn <= @Page * @PageSize
    )
    SELECT
        f.SizeId,
        f.Barcode,
        f.StyleName,
        f.ProductName,
        f.Color,
        f.Size,
        f.ProductCode,
        f.PriceTL,
        f.PriceEUR,
        f.PriceUSD,
        f.StockQty,
        f.Pos
    FROM filtered f
    INNER JOIN page_groups g ON g.GroupKey = f.GroupKey
    ORDER BY f.StyleName, f.ProductName, f.Pos, f.SizeId;
END
GO
