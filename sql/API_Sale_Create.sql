CREATE OR ALTER PROCEDURE dbo.API_Sale_Create
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX),
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @SaleId INT;

    INSERT INTO dbo.Sales (UserId, CurrencyId, Customer, PaymentTypeId, Note, CreatedAt)
    VALUES (@UserId, @CurrencyId, @Customer, @PaymentTypeId, @Note, GETDATE());

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

    COMMIT TRANSACTION;

    SELECT
        @SaleId AS SaleId,
        (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId) AS TotalAmount;
END
GO
