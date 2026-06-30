CREATE OR ALTER PROCEDURE dbo.API_Product_GetByBarcode
    @Barcode NVARCHAR(50),
    @CurrencyId INT
AS
BEGIN
    SET NOCOUNT ON;
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
    WHERE ss.Barcode = @Barcode;
END
GO
