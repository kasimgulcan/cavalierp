CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_Convert
    @UserId INT,
    @OrderRequestId INT,
    @PaymentTypeId INT = NULL,
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(20);
    DECLARE @CurrencyId INT;
    DECLARE @Customer NVARCHAR(200);
    DECLARE @OrderNote NVARCHAR(500);
    DECLARE @SaleId INT;

    SELECT
        @Status = Status,
        @CurrencyId = CurrencyId,
        @Customer = Customer,
        @OrderNote = Note
    FROM dbo.OrderRequests
    WHERE OrderRequestId = @OrderRequestId;

    IF @Status IS NULL
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    IF @Status = N'Converted'
    BEGIN
        RAISERROR(N'Sipariş talebi zaten satışa dönüştürülmüş.', 16, 1);
        RETURN;
    END

    IF @Status = N'Rejected'
    BEGIN
        RAISERROR(N'Reddedilmiş sipariş talebi satışa dönüştürülemez.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM dbo.OrderRequestLines ol
        LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ol.SizeId
        WHERE ol.OrderRequestId = @OrderRequestId
          AND ISNULL(st.StockQty, 0) < ol.Quantity
    )
    BEGIN
        RAISERROR(N'Yetersiz stok. Satış tamamlanamadı.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    INSERT INTO dbo.Sales (UserId, CurrencyId, Customer, PaymentTypeId, Note, CreatedAt)
    VALUES (
        @UserId,
        @CurrencyId,
        @Customer,
        @PaymentTypeId,
        COALESCE(@Note, @OrderNote),
        GETDATE()
    );

    SET @SaleId = SCOPE_IDENTITY();

    INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
    SELECT
        @SaleId,
        ol.SizeId,
        ol.Product,
        ol.Quantity,
        ol.UnitPrice,
        ol.ListPrice
    FROM dbo.OrderRequestLines ol
    WHERE ol.OrderRequestId = @OrderRequestId;

    UPDATE dbo.OrderRequests
    SET Status = N'Converted'
    WHERE OrderRequestId = @OrderRequestId;

    COMMIT TRANSACTION;

    SELECT
        @SaleId AS SaleId,
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId) AS TotalAmount;
END
GO
