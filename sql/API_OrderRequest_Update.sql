CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_Update
    @OrderRequestId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @Status NVARCHAR(20) = NULL,
    @Lines NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(20);

    SELECT @CurrentStatus = Status
    FROM dbo.OrderRequests
    WHERE OrderRequestId = @OrderRequestId;

    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    IF @CurrentStatus IN (N'Converted', N'Rejected')
    BEGIN
        RAISERROR(N'Tamamlanmış veya reddedilmiş talepler düzenlenemez.', 16, 1);
        RETURN;
    END

    IF @Status IS NOT NULL
       AND @Status NOT IN (N'Pending', N'Accepted', N'Rejected')
    BEGIN
        RAISERROR(N'Geçersiz durum.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.OrderRequests
    SET
        Customer = COALESCE(@Customer, Customer),
        Note = COALESCE(@Note, Note),
        Status = COALESCE(@Status, Status)
    WHERE OrderRequestId = @OrderRequestId;

    IF @Lines IS NOT NULL AND @Status <> N'Rejected'
    BEGIN
        DELETE FROM dbo.OrderRequestLines
        WHERE OrderRequestId = @OrderRequestId;

        INSERT INTO dbo.OrderRequestLines (OrderRequestId, SizeId, Product, Quantity, UnitPrice, ListPrice)
        SELECT
            @OrderRequestId,
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

        IF NOT EXISTS (SELECT 1 FROM dbo.OrderRequestLines WHERE OrderRequestId = @OrderRequestId)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'Sipariş en az bir kalem içermelidir.', 16, 1);
            RETURN;
        END
    END

    COMMIT TRANSACTION;

    SELECT
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(ol.LineTotal) FROM dbo.OrderRequestLines ol WHERE ol.OrderRequestId = @OrderRequestId) AS TotalAmount;
END
GO
