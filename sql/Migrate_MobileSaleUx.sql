-- Mobile sale UX (30.08.2026)
-- Applies on top of sql/db.sql. Does not recreate existing objects.
--
-- 1) Kuruş: satış net tutarı 2 ondalık
-- 2) Refresh token: Role döndür
-- 3) Ürün arama: ürün grubu / kategori / renk contains
-- 4) Satış güncelleme: müşteri, not, ödeme tipi tam yazılabilir (NULL dahil)
-- 5) Promosyon ödeme tipi

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fn_Sale_NetTotal]
(
    @Subtotal DECIMAL(18, 2),
    @DiscountPercent DECIMAL(5, 2),
    @DiscountFixedAmount DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    IF @Subtotal IS NULL OR @Subtotal <= 0
        RETURN 0;

    DECLARE @PercentAmt DECIMAL(18, 2) = 0;
    DECLARE @AfterPercent DECIMAL(18, 2) = @Subtotal;
    DECLARE @FixedAmt DECIMAL(18, 2) = 0;

    IF @DiscountPercent > 0
        SET @PercentAmt = ROUND(@Subtotal * @DiscountPercent / 100.0, 2);

    SET @AfterPercent = @Subtotal - @PercentAmt;
    IF @AfterPercent < 0
        SET @AfterPercent = 0;

    IF @DiscountFixedAmount > 0
    BEGIN
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 2);
        IF @FixedAmt > @AfterPercent
            SET @FixedAmt = @AfterPercent;
    END
    ELSE IF @DiscountFixedAmount < 0
    BEGIN
        -- Yuvarlama düzeltmesi: yüzde sonrası nete eklenir, liste fiyatını aşamaz.
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 2);
        DECLARE @MaxAddBack DECIMAL(18, 2) = @Subtotal - @AfterPercent;
        IF @FixedAmt < -@MaxAddBack
            SET @FixedAmt = -@MaxAddBack;
    END

    RETURN @AfterPercent - @FixedAmt;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Auth_RefreshToken]
    @RefreshToken NVARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.Status, u.Role
    FROM dbo.RefreshTokens rt
    INNER JOIN dbo.Users u ON u.UserId = rt.UserId
    WHERE rt.Token = @RefreshToken
      AND rt.ExpiresAt > GETDATE()
      AND u.Status <> N'Rejected';
END
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

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_Update]
    @SaleId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX) = NULL,
    @DiscountPercent DECIMAL(5, 2) = NULL,
    @DiscountFixedAmount DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    IF @DiscountPercent IS NOT NULL AND @DiscountPercent < 0 SET @DiscountPercent = 0;
    IF @DiscountPercent IS NOT NULL AND @DiscountPercent > 100 SET @DiscountPercent = 100;

    BEGIN TRANSACTION;

    UPDATE dbo.Sales
    SET
        Customer = @Customer,
        Note = @Note,
        PaymentTypeId = @PaymentTypeId,
        DiscountPercent = COALESCE(@DiscountPercent, DiscountPercent),
        DiscountFixedAmount = COALESCE(@DiscountFixedAmount, DiscountFixedAmount)
    WHERE SaleId = @SaleId;

    IF @Lines IS NOT NULL
    BEGIN
        DELETE FROM dbo.SaleLines
        WHERE SaleId = @SaleId;

        INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
        SELECT
            @SaleId,
            j.SizeId,
            j.Product,
            j.Quantity,
            j.UnitPrice,
            j.ListPrice
        FROM OPENJSON(@Lines)
        WITH (
            SizeId INT '$.SizeId',
            Product NVARCHAR(300) '$.Product',
            Quantity INT '$.Quantity',
            UnitPrice DECIMAL(18, 2) '$.UnitPrice',
            ListPrice DECIMAL(18, 2) '$.ListPrice'
        ) AS j
        WHERE j.Quantity > 0;

        IF NOT EXISTS (SELECT 1 FROM dbo.SaleLines WHERE SaleId = @SaleId)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'Satış en az bir kalem içermelidir.', 16, 1);
            RETURN;
        END
    END

    COMMIT TRANSACTION;

    DECLARE @Subtotal DECIMAL(18, 2);
    DECLARE @Percent DECIMAL(5, 2);
    DECLARE @Fixed DECIMAL(18, 2);

    SELECT
        @Subtotal = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        @Percent = DiscountPercent,
        @Fixed = DiscountFixedAmount
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    SELECT
        @SaleId AS SaleId,
        SubtotalAmount = @Subtotal,
        DiscountPercent = @Percent,
        DiscountFixedAmount = @Fixed,
        TotalAmount = dbo.fn_Sale_NetTotal(@Subtotal, @Percent, @Fixed);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM dbo.PaymentTypes WHERE Name = N'Promosyon'
)
BEGIN
    INSERT INTO dbo.PaymentTypes (Name) VALUES (N'Promosyon');
END
GO
