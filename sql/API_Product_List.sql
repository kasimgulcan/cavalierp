CREATE OR ALTER PROCEDURE dbo.API_Product_List
    @Search NVARCHAR(100) = NULL,
    @CurrencyId INT,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 20;

    SELECT
        ss.SizeId,
        ss.Barcode,
        s.ProductName AS Product,
        ss.VariantCode,
        ListPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        UnitPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        StockQty = ISNULL(st.StockQty, 0),
        CurrencyId = @CurrencyId
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.SizeId IS NOT NULL
      AND (
          @Search IS NULL
       OR @Search = N''
       OR s.ProductName LIKE N'%' + @Search + N'%'
       OR ss.Barcode LIKE N'%' + @Search + N'%')
    ORDER BY s.ProductName, ss.SizeId
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
