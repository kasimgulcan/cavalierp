CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_List
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Status NVARCHAR(20) = NULL,
    @Page INT = 1,
    @PageSize INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 30;

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
        LineCount = (
            SELECT COUNT(*)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE (@DateFrom IS NULL OR CAST(o.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(o.CreatedAt AS DATE) <= @DateTo)
      AND (@Status IS NULL OR @Status = N'' OR o.Status = @Status)
    ORDER BY o.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
