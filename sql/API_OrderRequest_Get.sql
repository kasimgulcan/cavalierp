CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_Get
    @OrderRequestId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.OrderRequests WHERE OrderRequestId = @OrderRequestId)
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Email AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        TotalAmount = (
            SELECT SUM(ol.LineTotal)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        ),
        Lines = (
            SELECT
                ol.OrderRequestLineId,
                ol.SizeId,
                ol.Product,
                ol.Quantity,
                ol.UnitPrice,
                ol.ListPrice,
                ol.LineTotal,
                StockQty = ISNULL(st.StockQty, 0)
            FROM dbo.OrderRequestLines ol
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ol.SizeId
            WHERE ol.OrderRequestId = o.OrderRequestId
            FOR JSON PATH
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.OrderRequestId = @OrderRequestId;
END
GO
