-- Satış bayrakları: eski uygulama bozulmadan çoklu bayrak.
--
-- Eski sürüm (onay beklerken de) yalnızca şunları yazar ve okur:
--   0 yok, 1 ödeme takip, 2 üretim, 3 genel takip.
-- Bu script mevcut satırları güncellemez. 3 genel takip olarak kalır.
--
-- Yeni sürüm tek bayrağı aynı kodlarla yazar (1, 2, 3), böylece eski sürüm
-- onları göstermeye ve filtrelemeye devam eder.
-- İki veya daha fazla bayrakta değer 128 + bitlerdir:
--   ödeme = 1, üretim = 2, genel takip = 4, sonrakiler = 8, 16, 32, 64.
--   Örnek: ödeme + üretim = 131.
-- Eski sürüm bu değeri tanımaz. Kaydı tekrar yazsa da sunucu çoklu bayrağı silmez.
--
-- Eski sürüm liste filtresinde Flag ile birebir eşitlik aramaya devam eder.
-- Yeni sürüm FlagMask gönderir; seçilen bitlerden herhangi biri yeter.
-- FlagMask genel takip biti 4'tür ve eski kod 3 ile de eşleşir.
--
-- Script onaydan önce uygulanabilir. Eski sürüm FlagMask göndermez;
-- yeni dal mevcut veride ekstra satır döndürmez.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_Create]
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX),
    @Note NVARCHAR(500) = NULL,
    @OrderRequestId INT = NULL,
    @DiscountPercent DECIMAL(5, 2) = 0,
    @DiscountFixedAmount DECIMAL(18, 2) = 0,
    @Flag TINYINT = 0,
    @FlagMask TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @DiscountPercent < 0 SET @DiscountPercent = 0;
    IF @DiscountPercent > 100 SET @DiscountPercent = 100;
    --IF @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

    DECLARE @StoredFlag TINYINT = COALESCE(@FlagMask, @Flag);
    IF @StoredFlag IS NULL OR @StoredFlag BETWEEN 4 AND 127
        SET @StoredFlag = 0;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        DECLARE @OrderStatus NVARCHAR(20);

        SELECT @OrderStatus = Status
        FROM dbo.OrderRequests
        WHERE OrderRequestId = @OrderRequestId;

        IF @OrderStatus IS NULL
        BEGIN
            RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
            RETURN;
        END

        IF @OrderStatus IN (N'Converted', N'Rejected')
        BEGIN
            RAISERROR(N'Bu talep satışa dönüştürülemez.', 16, 1);
            RETURN;
        END
    END

    BEGIN TRANSACTION;

    DECLARE @SaleId INT;

    INSERT INTO dbo.Sales (
        UserId, CurrencyId, Customer, PaymentTypeId, Note, OrderRequestId,
        DiscountPercent, DiscountFixedAmount, Flag, CreatedAt
    )
    VALUES (
        @UserId, @CurrencyId, @Customer, @PaymentTypeId, @Note, @OrderRequestId,
        @DiscountPercent, @DiscountFixedAmount, @StoredFlag, GETDATE()
    );

    SET @SaleId = SCOPE_IDENTITY();

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
    ) AS j;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        UPDATE dbo.OrderRequests
        SET Status = N'Converted'
        WHERE OrderRequestId = @OrderRequestId;
    END

    COMMIT TRANSACTION;

    SELECT
        @SaleId AS SaleId,
        @OrderRequestId AS OrderRequestId,
        SubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        DiscountPercent = @DiscountPercent,
        DiscountFixedAmount = @DiscountFixedAmount,
        Flag = @StoredFlag,
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId),
            @DiscountPercent,
            @DiscountFixedAmount
        );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_List]
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Page INT = 1,
    @PageSize INT = 30,
    @Flag TINYINT = NULL,
    @FlagAny BIT = NULL,
    @FlagMask TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 30;

    SELECT
        s.SaleId,
        s.UserId,
        u.Username AS StaffEmail,
        s.CurrencyId,
        s.Customer,
        s.Note,
        s.PaymentTypeId,
        s.OrderRequestId,
        s.CreatedAt,
        s.DiscountPercent,
        s.DiscountFixedAmount,
        s.Flag,
        SubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = s.SaleId
        ),
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = s.SaleId),
            s.DiscountPercent,
            s.DiscountFixedAmount
        ),
        LineCount = (
            SELECT COUNT(*)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = s.SaleId
        )
    FROM dbo.Sales s
    INNER JOIN dbo.Users u ON u.UserId = s.UserId
    WHERE (@DateFrom IS NULL OR CAST(s.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(s.CreatedAt AS DATE) <= @DateTo)
      AND (@Flag IS NULL OR s.Flag = @Flag)
      AND (
            @FlagMask IS NULL
            OR ((@FlagMask & 1) <> 0 AND (s.Flag = 1 OR (s.Flag >= 128 AND (s.Flag & 1) <> 0)))
            OR ((@FlagMask & 2) <> 0 AND (s.Flag = 2 OR (s.Flag >= 128 AND (s.Flag & 2) <> 0)))
            OR ((@FlagMask & 4) <> 0 AND (s.Flag = 3 OR (s.Flag >= 128 AND (s.Flag & 4) <> 0)))
            OR ((@FlagMask & 8) <> 0 AND s.Flag >= 128 AND (s.Flag & 8) <> 0)
            OR ((@FlagMask & 16) <> 0 AND s.Flag >= 128 AND (s.Flag & 16) <> 0)
            OR ((@FlagMask & 32) <> 0 AND s.Flag >= 128 AND (s.Flag & 32) <> 0)
            OR ((@FlagMask & 64) <> 0 AND s.Flag >= 128 AND (s.Flag & 64) <> 0)
          )
      AND (@FlagAny IS NULL OR @FlagAny = 0 OR s.Flag <> 0)
    ORDER BY s.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_SetFlags]
    @SaleId INT,
    @Flag TINYINT = NULL,
    @FlagMask TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    DECLARE @CurrentFlag TINYINT;
    SELECT @CurrentFlag = Flag
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    DECLARE @StoredFlag TINYINT = @CurrentFlag;

    IF @FlagMask IS NOT NULL
        SET @StoredFlag = @FlagMask;
    ELSE IF @Flag IS NOT NULL AND NOT (@CurrentFlag >= 128 AND @Flag <= 3)
        SET @StoredFlag = @Flag;

    IF @StoredFlag BETWEEN 4 AND 127
        SET @StoredFlag = @CurrentFlag;

    UPDATE dbo.Sales
    SET Flag = @StoredFlag
    WHERE SaleId = @SaleId;

    SELECT SaleId, Flag
    FROM dbo.Sales
    WHERE SaleId = @SaleId;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_Update]
    @SaleId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX) = NULL,
    @DiscountPercent DECIMAL(5, 2) = NULL,
    @DiscountFixedAmount DECIMAL(18, 2) = NULL,
    @Flag TINYINT = NULL,
    @FlagMask TINYINT = NULL
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
    --IF @DiscountFixedAmount IS NOT NULL AND @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

    DECLARE @CurrentFlag TINYINT;
    SELECT @CurrentFlag = Flag
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    DECLARE @StoredFlag TINYINT = @CurrentFlag;

    IF @FlagMask IS NOT NULL
        SET @StoredFlag = @FlagMask;
    ELSE IF @Flag IS NOT NULL AND NOT (@CurrentFlag >= 128 AND @Flag <= 3)
        SET @StoredFlag = @Flag;

    IF @StoredFlag BETWEEN 4 AND 127
        SET @StoredFlag = @CurrentFlag;

    BEGIN TRANSACTION;

    UPDATE dbo.Sales
    SET
        Customer = @Customer,
        Note = @Note,
        PaymentTypeId = @PaymentTypeId,
        DiscountPercent = COALESCE(@DiscountPercent, DiscountPercent),
        DiscountFixedAmount = COALESCE(@DiscountFixedAmount, DiscountFixedAmount),
        Flag = @StoredFlag
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
    DECLARE @FlagValue TINYINT;

    SELECT
        @Subtotal = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        @Percent = DiscountPercent,
        @Fixed = DiscountFixedAmount,
        @FlagValue = Flag
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    SELECT
        @SaleId AS SaleId,
        SubtotalAmount = @Subtotal,
        DiscountPercent = @Percent,
        DiscountFixedAmount = @Fixed,
        Flag = @FlagValue,
        TotalAmount = dbo.fn_Sale_NetTotal(@Subtotal, @Percent, @Fixed);
END
GO
