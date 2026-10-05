-- Satış düzenlerken satırda katalog adı, beden ve ürün kodu görünsün.
-- Eski sürüm ek JSON alanlarını yok sayar. Product kolonu değişmez.
-- Yeni sürüm bu alanlarla fotoğrafı ürün kodundan tamamlar.

CREATE OR ALTER PROCEDURE [dbo].[API_Sale_Get]
    @SaleId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

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
        Lines = (
            SELECT
                sl.SaleLineId,
                sl.SizeId,
                sl.Product,
                ps.ProductName,
                ps.ProductCode,
                ps.StyleName,
                ps.Color,
                ps.Size,
                sl.Quantity,
                sl.UnitPrice,
                sl.ListPrice,
                sl.LineTotal,
                StockQty = ISNULL(st.StockQty, 0)
            FROM dbo.SaleLines sl
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = sl.SizeId
            LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = sl.SizeId
            WHERE sl.SaleId = s.SaleId
            FOR JSON PATH
        )
    FROM dbo.Sales s
    INNER JOIN dbo.Users u ON u.UserId = s.UserId
    WHERE s.SaleId = @SaleId;
END
GO
