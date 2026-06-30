CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_Create
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @Lines NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @OrderRequestId INT;

    INSERT INTO dbo.OrderRequests (UserId, CurrencyId, Customer, Note, Status, CreatedAt)
    VALUES (@UserId, @CurrencyId, @Customer, @Note, N'Pending', GETDATE());

    SET @OrderRequestId = SCOPE_IDENTITY();

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
    ) AS j;

    COMMIT TRANSACTION;

    SELECT
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(ol.LineTotal) FROM dbo.OrderRequestLines ol WHERE ol.OrderRequestId = @OrderRequestId) AS TotalAmount;
END
GO
