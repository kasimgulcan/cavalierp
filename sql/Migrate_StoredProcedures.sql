/*
================================================================================
 CavalierShop — Stored Procedure migration (CREATE OR ALTER)
================================================================================
 Tum mobil API_* stored procedure tanimlari bu dosyada tutulur.
 Tablo verisine dokunmaz; canli veritabaninda guvenle calistirilabilir.

 Tablo degisiklikleri: sql/Migration.sql (ALTER TABLE)

 Kullanim: SSMS'te CavaliERP veritabaninda Execute (F5)
================================================================================
*/

SET NOCOUNT ON;
GO

PRINT '=== CREATE OR ALTER stored procedures ===';
GO

PRINT '--- API_Auth_Register ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_Register
    @Username NVARCHAR(50),
    @Password NVARCHAR(256),
    @AcceptedTerms BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Username = LTRIM(RTRIM(@Username));

    IF @AcceptedTerms <> 1
    BEGIN
        RAISERROR(N'Kullanım şartları kabul edilmelidir.', 16, 1);
        RETURN;
    END

    IF LEN(@Username) < 2
    BEGIN
        RAISERROR(N'Kullanıcı adı en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF LEN(@Password) < 2
    BEGIN
        RAISERROR(N'Şifre en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF @Username LIKE N'%[^a-zA-Z0-9_]%'
    BEGIN
        RAISERROR(N'Geçersiz kullanıcı adı formatı.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM dbo.Users
        WHERE Username COLLATE SQL_Latin1_General_CP1_CI_AS = @Username COLLATE SQL_Latin1_General_CP1_CI_AS
    )
    BEGIN
        RAISERROR(N'Bu kullanıcı adı zaten kayıtlı.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Users (Username, PasswordHash, Status, Role, CreatedAt)
    VALUES (@Username, HASHBYTES('SHA2_256', @Password), N'Pending', N'Member', GETDATE());

    SELECT
        CAST(SCOPE_IDENTITY() AS INT) AS UserId,
        @Username AS Username,
        N'Pending' AS Status,
        N'Member' AS Role;
END
GO

PRINT '--- API_Auth_Login ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_Login
    @Username NVARCHAR(50),
    @Password NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Username = LTRIM(RTRIM(@Username));

    SELECT u.UserId, u.Username, u.Status, u.Role
    FROM dbo.Users u
    WHERE u.Username COLLATE SQL_Latin1_General_CP1_CI_AS = @Username COLLATE SQL_Latin1_General_CP1_CI_AS
      AND u.PasswordHash = HASHBYTES('SHA2_256', @Password)
      AND u.Status <> N'Rejected';
END
GO

PRINT '--- API_Auth_RefreshToken ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_RefreshToken
    @RefreshToken NVARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.Status
    FROM dbo.RefreshTokens rt
    INNER JOIN dbo.Users u ON u.UserId = rt.UserId
    WHERE rt.Token = @RefreshToken
      AND rt.ExpiresAt > GETDATE()
      AND u.Status <> N'Rejected';
END
GO

PRINT '--- API_Auth_GetProfile ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_GetProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.Status, u.Role, u.CreatedAt
    FROM dbo.Users u
    WHERE u.UserId = @UserId;
END
GO

PRINT '--- API_Auth_DeleteAccount ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_DeleteAccount
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: soft-delete vs hard-delete per existing schema
    UPDATE dbo.Users
    SET
        Status = N'Deleted',
        Username = CONCAT(N'deleted_', @UserId, N'_', Username),
        Email = CASE
            WHEN Email IS NOT NULL THEN CONCAT(N'deleted_', @UserId, N'_', Email)
            ELSE NULL
        END
    WHERE UserId = @UserId AND Status <> N'Deleted';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- API_Auth_ChangePassword ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_ChangePassword
    @UserId INT,
    @CurrentPassword NVARCHAR(256),
    @NewPassword NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(@NewPassword) < 2
    BEGIN
        RAISERROR(N'Yeni şifre en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF @CurrentPassword = @NewPassword
    BEGIN
        RAISERROR(N'Yeni şifre mevcut şifreden farklı olmalıdır.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Users u
        WHERE u.UserId = @UserId
          AND u.PasswordHash = HASHBYTES('SHA2_256', @CurrentPassword)
          AND u.Status <> N'Rejected'
          AND u.Status <> N'Deleted'
    )
    BEGIN
        RAISERROR(N'Mevcut şifre hatalı.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Users
    SET PasswordHash = HASHBYTES('SHA2_256', @NewPassword)
    WHERE UserId = @UserId;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- API_Membership_ListPending ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Membership_ListPending
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Users table
    SELECT u.UserId, u.Username, u.Status, u.CreatedAt
    FROM dbo.Users u
    WHERE u.Status = 'Pending'
    ORDER BY u.CreatedAt;
END
GO

PRINT '--- API_Membership_Approve ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Membership_Approve
    @UserId INT,
    @Role NVARCHAR(20) = N'Member'
AS
BEGIN
    SET NOCOUNT ON;
    IF @Role NOT IN (N'Member', N'Staff')
        SET @Role = N'Member';

    UPDATE dbo.Users
    SET Status = N'Approved', Role = @Role
    WHERE UserId = @UserId AND Status = N'Pending';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- API_Membership_Reject ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Membership_Reject
    @UserId INT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Users table; optional rejection reason column
    UPDATE dbo.Users
    SET Status = 'Rejected'
    WHERE UserId = @UserId AND Status = 'Pending';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- API_Get_Currency ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Get_Currency
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.CurrencyId, c.Code, c.Name
    FROM dbo.Currencies c
    ORDER BY c.CurrencyId;
END
GO

PRINT '--- API_Lookup_Customers ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Lookup_Customers
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Customers table
    SELECT c.CustomerId, c.Name
    FROM dbo.Customers c
    WHERE @Search IS NULL OR c.Name LIKE N'%' + @Search + N'%'
    ORDER BY c.Name;
END
GO

PRINT '--- API_Lookup_PaymentTypes ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Lookup_PaymentTypes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pt.PaymentTypeId, pt.Name
    FROM dbo.PaymentTypes pt
    ORDER BY pt.Name;
END
GO

PRINT '--- API_Product_GetByBarcode ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Product_GetByBarcode
    @Barcode NVARCHAR(50),
    @CurrencyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
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
        StockQty = ISNULL(st.StockQty, 0)
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.Barcode = @Barcode;
END
GO

PRINT '--- API_Product_List ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Product_List
    @Search NVARCHAR(100) = NULL,
    @CurrencyId INT = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 20;

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
        StockQty = ISNULL(st.StockQty, 0)
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.SizeId IS NOT NULL
      AND (
          @Search IS NULL
       OR @Search = N''
       OR ss.ProductName LIKE N'%' + @Search + N'%'
       OR ss.StyleName LIKE N'%' + @Search + N'%'
       OR ss.Barcode LIKE N'%' + @Search + N'%')
    ORDER BY ss.StyleName, ss.ProductName, ss.SizeId
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT '--- fn_Sale_NetTotal ---';
GO

CREATE OR ALTER FUNCTION dbo.fn_Sale_NetTotal
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
        SET @PercentAmt = ROUND(@Subtotal * @DiscountPercent / 100.0, 0);

    SET @AfterPercent = @Subtotal - @PercentAmt;
    IF @AfterPercent < 0
        SET @AfterPercent = 0;

    IF @DiscountFixedAmount > 0
    BEGIN
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 0);
        IF @FixedAmt > @AfterPercent
            SET @FixedAmt = @AfterPercent;
    END

    RETURN @AfterPercent - @FixedAmt;
END
GO

PRINT '--- API_Sale_Create ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Sale_Create
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX),
    @Note NVARCHAR(500) = NULL,
    @OrderRequestId INT = NULL,
    @DiscountPercent DECIMAL(5, 2) = 0,
    @DiscountFixedAmount DECIMAL(18, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @DiscountPercent < 0 SET @DiscountPercent = 0;
    IF @DiscountPercent > 100 SET @DiscountPercent = 100;
    IF @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

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
        DiscountPercent, DiscountFixedAmount, CreatedAt
    )
    VALUES (
        @UserId, @CurrencyId, @Customer, @PaymentTypeId, @Note, @OrderRequestId,
        @DiscountPercent, @DiscountFixedAmount, GETDATE()
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
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId),
            @DiscountPercent,
            @DiscountFixedAmount
        );
END
GO

PRINT '--- API_OrderRequest_Create ---';
GO

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

    IF EXISTS (
        SELECT 1 FROM dbo.Users
        WHERE UserId = @UserId AND Role = N'Staff'
    )
    BEGIN
        RAISERROR(N'Personel hesapları sipariş talebi oluşturamaz.', 16, 1);
        RETURN;
    END

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

PRINT '--- API_OrderRequest_List ---';
GO

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
        u.Username AS MemberEmail,
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

PRINT '--- API_OrderRequest_Get ---';
GO

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
        u.Username AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        ConvertedSaleId = (
            SELECT TOP 1 s.SaleId
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleDiscountPercent = (
            SELECT TOP 1 s.DiscountPercent
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleDiscountFixedAmount = (
            SELECT TOP 1 s.DiscountFixedAmount
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleSubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.Sales s
            INNER JOIN dbo.SaleLines sl ON sl.SaleId = s.SaleId
            WHERE s.OrderRequestId = o.OrderRequestId
        ),
        ConvertedSaleNetTotal = (
            SELECT TOP 1 dbo.fn_Sale_NetTotal(
                (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = s.SaleId),
                s.DiscountPercent,
                s.DiscountFixedAmount
            )
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
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
                StockQty = ISNULL(st.StockQty, 0),
                ps.ProductCode,
                ps.StyleName,
                ps.Color,
                ps.Size
            FROM dbo.OrderRequestLines ol
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ol.SizeId
            LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = ol.SizeId
            WHERE ol.OrderRequestId = o.OrderRequestId
            FOR JSON PATH
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.OrderRequestId = @OrderRequestId;
END
GO

PRINT '--- API_OrderRequest_Update ---';
GO

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

    IF @Status IS NOT NULL AND @Status <> N'Rejected'
    BEGIN
        RAISERROR(N'Yalnızca reddetme işlemi desteklenir.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.OrderRequests
    SET
        Customer = COALESCE(@Customer, Customer),
        Note = COALESCE(@Note, Note),
        Status = COALESCE(@Status, Status)
    WHERE OrderRequestId = @OrderRequestId;

    IF @Lines IS NOT NULL AND (@Status IS NULL OR @Status <> N'Rejected')
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

PRINT '--- API_OrderRequest_Convert ---';
GO

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

    IF @Status NOT IN (N'Pending', N'Accepted')
    BEGIN
        RAISERROR(N'Bu talep satışa dönüştürülemez.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.OrderRequestLines
        WHERE OrderRequestId = @OrderRequestId
    )
    BEGIN
        RAISERROR(N'Sipariş talebi en az bir kalem içermelidir.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    INSERT INTO dbo.Sales (UserId, CurrencyId, Customer, PaymentTypeId, Note, OrderRequestId, CreatedAt)
    VALUES (
        @UserId,
        @CurrencyId,
        @Customer,
        @PaymentTypeId,
        COALESCE(@Note, @OrderNote),
        @OrderRequestId,
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

PRINT '--- API_OrderRequest_ListMine ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_ListMine
    @UserId INT,
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
        u.Username AS MemberEmail,
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
    WHERE o.UserId = @UserId
      AND (@DateFrom IS NULL OR CAST(o.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(o.CreatedAt AS DATE) <= @DateTo)
      AND (@Status IS NULL OR @Status = N'' OR o.Status = @Status)
    ORDER BY o.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT '--- API_OrderRequest_GetMine ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_OrderRequest_GetMine
    @UserId INT,
    @OrderRequestId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.OrderRequests
        WHERE OrderRequestId = @OrderRequestId AND UserId = @UserId
    )
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Username AS MemberEmail,
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
                ps.ProductCode,
                ps.StyleName,
                ps.Color,
                ps.Size
            FROM dbo.OrderRequestLines ol
            LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = ol.SizeId
            WHERE ol.OrderRequestId = o.OrderRequestId
            FOR JSON PATH
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.OrderRequestId = @OrderRequestId
      AND o.UserId = @UserId;
END
GO

PRINT '--- API_Sale_List ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Sale_List
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Page INT = 1,
    @PageSize INT = 30
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
    ORDER BY s.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT '--- API_Sale_Get ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Sale_Get
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
                sl.Quantity,
                sl.UnitPrice,
                sl.ListPrice,
                sl.LineTotal,
                StockQty = ISNULL(st.StockQty, 0)
            FROM dbo.SaleLines sl
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = sl.SizeId
            WHERE sl.SaleId = s.SaleId
            FOR JSON PATH
        )
    FROM dbo.Sales s
    INNER JOIN dbo.Users u ON u.UserId = s.UserId
    WHERE s.SaleId = @SaleId;
END
GO

PRINT '--- API_Sale_Update ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Sale_Update
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
    IF @DiscountFixedAmount IS NOT NULL AND @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

    BEGIN TRANSACTION;

    UPDATE dbo.Sales
    SET
        Customer = COALESCE(@Customer, Customer),
        Note = COALESCE(@Note, Note),
        PaymentTypeId = COALESCE(@PaymentTypeId, PaymentTypeId),
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

PRINT '--- API_Sale_Delete ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Sale_Delete
    @SaleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrderRequestId INT;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT @OrderRequestId = OrderRequestId
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    BEGIN TRANSACTION;

    DELETE FROM dbo.SaleLines
    WHERE SaleId = @SaleId;

    DELETE FROM dbo.Sales
    WHERE SaleId = @SaleId;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        UPDATE dbo.OrderRequests
        SET Status = N'Pending'
        WHERE OrderRequestId = @OrderRequestId
          AND Status = N'Converted';
    END

    COMMIT TRANSACTION;

    SELECT @SaleId AS SaleId;
END
GO

PRINT '--- API_Report_SalesByProduct ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Report_SalesByProduct
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sl.Product,
        ps.StyleName,
        ps.ProductCode,
        ps.Color,
        sl.SizeId,
        ps.Size AS SizeLabel,
        SUM(sl.Quantity) AS Quantity,
        SUM(sl.LineTotal) AS Amount
    FROM dbo.SaleLines sl
    INNER JOIN dbo.Sales s ON s.SaleId = sl.SaleId
    LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = sl.SizeId
    WHERE (@DateFrom IS NULL OR CAST(s.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(s.CreatedAt AS DATE) <= @DateTo)
    GROUP BY
        sl.Product,
        ps.StyleName,
        ps.ProductCode,
        ps.Color,
        sl.SizeId,
        ps.Size
    ORDER BY
        ps.StyleName,
        sl.Product,
        ps.Size;
END
GO

PRINT '--- API_Stock_Entry ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Stock_Entry
    @UserId INT,
    @SizeId INT,
    @Quantity INT,
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Quantity <= 0
    BEGIN
        RAISERROR(N'Miktar 0''dan büyük olmalıdır.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.V_ProductSize WHERE SizeId = @SizeId)
    BEGIN
        RAISERROR(N'Ürün bulunamadı.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.StockEntries (SizeId, Quantity, UserId, Note)
    VALUES (@SizeId, @Quantity, @UserId, @Note);

    SELECT
        SCOPE_IDENTITY() AS StockEntryId,
        @SizeId AS SizeId,
        ISNULL((SELECT StockQty FROM dbo.V_SizeStock WHERE SizeId = @SizeId), 0) AS StockQty;
END
GO

PRINT '=== Stored procedure migration completed ===';
GO
