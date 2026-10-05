-- Satış tarihi düzenlenebilir.
-- @CreatedAt boşsa eski davranış durur: oluşturmada GETDATE(), güncellemede kolon.
-- Dolu değer sunucu saatinden 2 dakikadan ileriyse reddedilir.
-- Eski uygulama parametreyi göndermez. Yeni sürüm onayından önce çalıştırılabilir.

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
    @FlagMask TINYINT = NULL,
    @CreatedAt DATETIME = NULL
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

    IF @CreatedAt IS NOT NULL AND @CreatedAt > DATEADD(MINUTE, 2, GETDATE())
    BEGIN
        RAISERROR(N'İleri tarih seçilemez.', 16, 1);
        RETURN;
    END

    DECLARE @StoredAt DATETIME = COALESCE(@CreatedAt, GETDATE());

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
        @DiscountPercent, @DiscountFixedAmount, @StoredFlag, @StoredAt
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
        CreatedAt = @StoredAt,
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId),
            @DiscountPercent,
            @DiscountFixedAmount
        );
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
    @FlagMask TINYINT = NULL,
    @CreatedAt DATETIME = NULL
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

    IF @CreatedAt IS NOT NULL AND @CreatedAt > DATEADD(MINUTE, 2, GETDATE())
    BEGIN
        RAISERROR(N'İleri tarih seçilemez.', 16, 1);
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

    BEGIN TRANSACTION;

    UPDATE dbo.Sales
    SET
        Customer = @Customer,
        Note = @Note,
        PaymentTypeId = @PaymentTypeId,
        DiscountPercent = COALESCE(@DiscountPercent, DiscountPercent),
        DiscountFixedAmount = COALESCE(@DiscountFixedAmount, DiscountFixedAmount),
        Flag = @StoredFlag,
        CreatedAt = COALESCE(@CreatedAt, CreatedAt)
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
    DECLARE @CreatedAtValue DATETIME;

    SELECT
        @Subtotal = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        @Percent = DiscountPercent,
        @Fixed = DiscountFixedAmount,
        @FlagValue = Flag,
        @CreatedAtValue = CreatedAt
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    SELECT
        @SaleId AS SaleId,
        SubtotalAmount = @Subtotal,
        DiscountPercent = @Percent,
        DiscountFixedAmount = @Fixed,
        Flag = @FlagValue,
        CreatedAt = @CreatedAtValue,
        TotalAmount = dbo.fn_Sale_NetTotal(@Subtotal, @Percent, @Fixed);
END
GO
