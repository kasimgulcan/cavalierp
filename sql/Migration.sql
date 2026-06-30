/*
================================================================================
 CavalierShop — Migration (tek dosya, sıfırdan kurulum)
================================================================================
 Mobil API tabloları + stok + sipariş talepleri + tüm API_* stored procedure'leri

 NOT: Products, Sizes, Customers, Currencies, SizePrices, Style, V_ProductSize
      mevcut ERP şemasında varsayılır (bu script oluşturmaz).

 Stok modeli:
   - StockEntries  → stok girişleri (+)
   - SaleLines     → satış çıkışları (−)
   - V_SizeStock   → giriş − satış

 Kullanım: SSMS'te tamamını seçip Execute (F5)
 UYARI: DROP bölümü bu script'in yönettiği tabloları ve verilerini siler!
================================================================================
*/

SET NOCOUNT ON;
GO

/* ============================================================================
   1. DROP — bağımlılık sırasına göre (en alttan yukarı)
   ============================================================================ */

PRINT '--- DROP stored procedures ---';
GO

IF OBJECT_ID(N'dbo.API_OrderRequest_Create', N'P') IS NOT NULL DROP PROCEDURE dbo.API_OrderRequest_Create;
IF OBJECT_ID(N'dbo.API_Product_List', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Product_List;
IF OBJECT_ID(N'dbo.API_Sale_Create', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Sale_Create;
IF OBJECT_ID(N'dbo.API_Product_GetByBarcode', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Product_GetByBarcode;
IF OBJECT_ID(N'dbo.API_Lookup_PaymentTypes', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Lookup_PaymentTypes;
IF OBJECT_ID(N'dbo.API_Lookup_Customers', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Lookup_Customers;
IF OBJECT_ID(N'dbo.API_Get_Currency', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Get_Currency;
IF OBJECT_ID(N'dbo.API_Membership_Reject', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Membership_Reject;
IF OBJECT_ID(N'dbo.API_Membership_Approve', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Membership_Approve;
IF OBJECT_ID(N'dbo.API_Membership_ListPending', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Membership_ListPending;
IF OBJECT_ID(N'dbo.API_Auth_DeleteAccount', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Auth_DeleteAccount;
IF OBJECT_ID(N'dbo.API_Auth_GetProfile', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Auth_GetProfile;
IF OBJECT_ID(N'dbo.API_Auth_RefreshToken', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Auth_RefreshToken;
IF OBJECT_ID(N'dbo.API_Auth_Login', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Auth_Login;
IF OBJECT_ID(N'dbo.API_Auth_Register', N'P') IS NOT NULL DROP PROCEDURE dbo.API_Auth_Register;
GO

PRINT '--- DROP views ---';
GO

IF OBJECT_ID(N'dbo.V_SizeStock', N'V') IS NOT NULL DROP VIEW dbo.V_SizeStock;
IF OBJECT_ID(N'dbo.vw_SizeStock', N'V') IS NOT NULL DROP VIEW dbo.vw_SizeStock;
GO

PRINT '--- DROP tables ---';
GO

IF OBJECT_ID(N'dbo.OrderRequestLines', N'U') IS NOT NULL DROP TABLE dbo.OrderRequestLines;
IF OBJECT_ID(N'dbo.OrderRequests', N'U') IS NOT NULL DROP TABLE dbo.OrderRequests;
IF OBJECT_ID(N'dbo.SaleLines', N'U') IS NOT NULL DROP TABLE dbo.SaleLines;
IF OBJECT_ID(N'dbo.Sales', N'U') IS NOT NULL DROP TABLE dbo.Sales;
IF OBJECT_ID(N'dbo.StockEntries', N'U') IS NOT NULL DROP TABLE dbo.StockEntries;
IF OBJECT_ID(N'dbo.StockMoveLines', N'U') IS NOT NULL DROP TABLE dbo.StockMoveLines;
IF OBJECT_ID(N'dbo.StockMoveHeaders', N'U') IS NOT NULL DROP TABLE dbo.StockMoveHeaders;
IF OBJECT_ID(N'dbo.RefreshTokens', N'U') IS NOT NULL DROP TABLE dbo.RefreshTokens;
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID(N'dbo.PaymentTypes', N'U') IS NOT NULL DROP TABLE dbo.PaymentTypes;
GO

/* ============================================================================
   2. CREATE TABLES
   ============================================================================ */

PRINT '--- CREATE PaymentTypes ---';
GO

CREATE TABLE dbo.PaymentTypes
(
    PaymentTypeId INT           IDENTITY(1, 1) NOT NULL,
    Name          NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_PaymentTypes PRIMARY KEY CLUSTERED (PaymentTypeId),
    CONSTRAINT UQ_PaymentTypes_Name UNIQUE (Name)
);
GO

INSERT INTO dbo.PaymentTypes (Name)
VALUES
    (N'Nakit'),
    (N'Kredi Kartı'),
    (N'Havale / EFT');
GO

PRINT '--- CREATE Users ---';
GO

CREATE TABLE dbo.Users
(
    UserId        INT            IDENTITY(1, 1) NOT NULL,
    Email         NVARCHAR(256)  NOT NULL,
    PasswordHash  VARBINARY(64)  NOT NULL,
    Status        NVARCHAR(20)   NOT NULL CONSTRAINT DF_Users_Status DEFAULT (N'Pending'),
    Role          NVARCHAR(20)   NOT NULL CONSTRAINT DF_Users_Role DEFAULT (N'Member'),
    CreatedAt     DATETIME       NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (GETDATE()),
    UpdatedAt     DATETIME       NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Status CHECK (Status IN (N'Pending', N'Approved', N'Rejected', N'Deleted')),
    CONSTRAINT CK_Users_Role CHECK (Role IN (N'Member', N'Staff'))
);
GO

CREATE NONCLUSTERED INDEX IX_Users_Status
    ON dbo.Users (Status)
    INCLUDE (Email, Role, CreatedAt);
GO

PRINT '--- CREATE RefreshTokens ---';
GO

CREATE TABLE dbo.RefreshTokens
(
    RefreshTokenId INT            IDENTITY(1, 1) NOT NULL,
    UserId         INT            NOT NULL,
    Token          NVARCHAR(512)  NOT NULL,
    ExpiresAt      DATETIME       NOT NULL,
    CreatedAt      DATETIME       NOT NULL CONSTRAINT DF_RefreshTokens_CreatedAt DEFAULT (GETDATE()),
    CONSTRAINT PK_RefreshTokens PRIMARY KEY CLUSTERED (RefreshTokenId),
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId)
        REFERENCES dbo.Users (UserId),
    CONSTRAINT UQ_RefreshTokens_Token UNIQUE (Token)
);
GO

CREATE NONCLUSTERED INDEX IX_RefreshTokens_UserId
    ON dbo.RefreshTokens (UserId, ExpiresAt DESC);
GO

PRINT '--- CREATE StockEntries ---';
GO

CREATE TABLE dbo.StockEntries
(
    StockEntryId INT            IDENTITY(1, 1) NOT NULL,
    SizeId       INT            NOT NULL,
    Quantity     INT            NOT NULL,
    UserId       INT            NULL,
    Note         NVARCHAR(500)  NULL,
    CreatedAt    DATETIME       NOT NULL CONSTRAINT DF_StockEntries_CreatedAt DEFAULT (GETDATE()),
    CONSTRAINT PK_StockEntries PRIMARY KEY CLUSTERED (StockEntryId),
    CONSTRAINT CK_StockEntries_Quantity CHECK (Quantity > 0)
);
GO

CREATE NONCLUSTERED INDEX IX_StockEntries_SizeId
    ON dbo.StockEntries (SizeId);
GO

CREATE NONCLUSTERED INDEX IX_StockEntries_CreatedAt
    ON dbo.StockEntries (CreatedAt DESC);
GO

PRINT '--- CREATE Sales / SaleLines ---';
GO

CREATE TABLE dbo.Sales
(
    SaleId        INT            IDENTITY(1, 1) NOT NULL,
    UserId        INT            NOT NULL,
    CurrencyId    INT            NOT NULL,
    Customer      NVARCHAR(200)  NULL,
    PaymentTypeId INT            NULL,
    Note          NVARCHAR(500)  NULL,
    CreatedAt     DATETIME       NOT NULL CONSTRAINT DF_Sales_CreatedAt DEFAULT (GETDATE()),
    CONSTRAINT PK_Sales PRIMARY KEY CLUSTERED (SaleId),
    CONSTRAINT FK_Sales_Users FOREIGN KEY (UserId)
        REFERENCES dbo.Users (UserId),
    CONSTRAINT FK_Sales_Currencies FOREIGN KEY (CurrencyId)
        REFERENCES dbo.Currencies (CurrencyId),
    CONSTRAINT FK_Sales_PaymentTypes FOREIGN KEY (PaymentTypeId)
        REFERENCES dbo.PaymentTypes (PaymentTypeId)
);
GO

CREATE NONCLUSTERED INDEX IX_Sales_CreatedAt
    ON dbo.Sales (CreatedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_Sales_UserId
    ON dbo.Sales (UserId, CreatedAt DESC);
GO

CREATE TABLE dbo.SaleLines
(
    SaleLineId INT             IDENTITY(1, 1) NOT NULL,
    SaleId     INT             NOT NULL,
    SizeId     INT             NOT NULL,
    Product    NVARCHAR(300)   NOT NULL,
    Quantity   INT             NOT NULL,
    UnitPrice  DECIMAL(18, 2)  NOT NULL,
    ListPrice  DECIMAL(18, 2)  NOT NULL,
    LineTotal  AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT PK_SaleLines PRIMARY KEY CLUSTERED (SaleLineId),
    CONSTRAINT FK_SaleLines_Sales FOREIGN KEY (SaleId)
        REFERENCES dbo.Sales (SaleId)
        ON DELETE CASCADE,
    CONSTRAINT CK_SaleLines_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_SaleLines_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_SaleLines_ListPrice CHECK (ListPrice >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_SaleLines_SaleId
    ON dbo.SaleLines (SaleId);
GO

CREATE NONCLUSTERED INDEX IX_SaleLines_SizeId
    ON dbo.SaleLines (SizeId);
GO

PRINT '--- CREATE OrderRequests / OrderRequestLines ---';
GO

CREATE TABLE dbo.OrderRequests
(
    OrderRequestId INT            IDENTITY(1, 1) NOT NULL,
    UserId         INT            NOT NULL,
    CurrencyId     INT            NOT NULL,
    Customer       NVARCHAR(200)  NULL,
    Note           NVARCHAR(500)  NULL,
    Status         NVARCHAR(20)   NOT NULL CONSTRAINT DF_OrderRequests_Status DEFAULT (N'Pending'),
    CreatedAt      DATETIME       NOT NULL CONSTRAINT DF_OrderRequests_CreatedAt DEFAULT (GETDATE()),
    CONSTRAINT PK_OrderRequests PRIMARY KEY CLUSTERED (OrderRequestId),
    CONSTRAINT FK_OrderRequests_Users FOREIGN KEY (UserId)
        REFERENCES dbo.Users (UserId),
    CONSTRAINT FK_OrderRequests_Currencies FOREIGN KEY (CurrencyId)
        REFERENCES dbo.Currencies (CurrencyId),
    CONSTRAINT CK_OrderRequests_Status CHECK (Status IN (N'Pending', N'Accepted', N'Rejected', N'Converted'))
);
GO

CREATE NONCLUSTERED INDEX IX_OrderRequests_UserId_CreatedAt
    ON dbo.OrderRequests (UserId, CreatedAt DESC);
GO

CREATE TABLE dbo.OrderRequestLines
(
    OrderRequestLineId INT             IDENTITY(1, 1) NOT NULL,
    OrderRequestId     INT             NOT NULL,
    SizeId             INT             NOT NULL,
    Product            NVARCHAR(300)   NOT NULL,
    Quantity           INT             NOT NULL,
    UnitPrice          DECIMAL(18, 2)  NOT NULL,
    ListPrice          DECIMAL(18, 2)  NOT NULL,
    LineTotal          AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT PK_OrderRequestLines PRIMARY KEY CLUSTERED (OrderRequestLineId),
    CONSTRAINT FK_OrderRequestLines_OrderRequests FOREIGN KEY (OrderRequestId)
        REFERENCES dbo.OrderRequests (OrderRequestId) ON DELETE CASCADE,
    CONSTRAINT CK_OrderRequestLines_Quantity CHECK (Quantity > 0)
);
GO

/* ============================================================================
   3. CREATE VIEWS
   ============================================================================ */

PRINT '--- CREATE V_SizeStock ---';
GO

CREATE VIEW dbo.V_SizeStock
AS
WITH InStock AS (
    SELECT SizeId, SUM(Quantity) AS Qty
    FROM dbo.StockEntries
    GROUP BY SizeId
),
OutStock AS (
    SELECT sl.SizeId, SUM(sl.Quantity) AS Qty
    FROM dbo.SaleLines sl
    GROUP BY sl.SizeId
)
SELECT
    COALESCE(i.SizeId, o.SizeId) AS SizeId,
    ISNULL(i.Qty, 0) - ISNULL(o.Qty, 0) AS StockQty
FROM InStock i
FULL OUTER JOIN OutStock o ON o.SizeId = i.SizeId;
GO

/* ============================================================================
   4. CREATE STORED PROCEDURES
   ============================================================================ */

PRINT '--- CREATE API_Auth_* ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_Register
    @Email NVARCHAR(256),
    @Password NVARCHAR(256),
    @AcceptedTerms BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @AcceptedTerms <> 1
    BEGIN
        RAISERROR('Terms must be accepted.', 16, 1);
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
    BEGIN
        RAISERROR('Email already registered.', 16, 1);
        RETURN;
    END
    INSERT INTO dbo.Users (Email, PasswordHash, Status, Role, CreatedAt)
    VALUES (@Email, HASHBYTES('SHA2_256', @Password), N'Pending', N'Member', GETDATE());

    SELECT
        CAST(SCOPE_IDENTITY() AS INT) AS UserId,
        @Email AS Email,
        N'Pending' AS Status,
        N'Member' AS Role;
END
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_Login
    @Email NVARCHAR(256),
    @Password NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role
    FROM dbo.Users u
    WHERE u.Email = @Email
      AND u.PasswordHash = HASHBYTES('SHA2_256', @Password)
      AND u.Status <> N'Rejected';
END
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_RefreshToken
    @RefreshToken NVARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role
    FROM dbo.RefreshTokens rt
    INNER JOIN dbo.Users u ON u.UserId = rt.UserId
    WHERE rt.Token = @RefreshToken
      AND rt.ExpiresAt > GETDATE()
      AND u.Status <> N'Rejected';
END
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_GetProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role, u.CreatedAt
    FROM dbo.Users u
    WHERE u.UserId = @UserId;
END
GO

CREATE OR ALTER PROCEDURE dbo.API_Auth_DeleteAccount
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Users
    SET Status = N'Deleted', Email = CONCAT(N'deleted_', @UserId, N'_', Email)
    WHERE UserId = @UserId AND Status <> N'Deleted';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- CREATE API_Membership_* ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Membership_ListPending
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role, u.CreatedAt
    FROM dbo.Users u
    WHERE u.Status = N'Pending'
    ORDER BY u.CreatedAt;
END
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

CREATE OR ALTER PROCEDURE dbo.API_Membership_Reject
    @UserId INT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Users
    SET Status = N'Rejected'
    WHERE UserId = @UserId AND Status = N'Pending';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT '--- CREATE API_Get_Currency / Lookups ---';
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

CREATE OR ALTER PROCEDURE dbo.API_Lookup_Customers
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.CustomerId, c.Name
    FROM dbo.Customers c
    WHERE @Search IS NULL OR c.Name LIKE N'%' + @Search + N'%'
    ORDER BY c.Name;
END
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

PRINT '--- CREATE API_Product_* / API_Sale_Create / API_OrderRequest_Create ---';
GO

CREATE OR ALTER PROCEDURE dbo.API_Product_GetByBarcode
    @Barcode NVARCHAR(50),
    @CurrencyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        ss.SizeId,
        ss.Barcode,
        s.ProductName AS Product,
        ss.VariantCode,
        ListPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        UnitPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        StockQty = ISNULL(st.StockQty, 0),
        CurrencyId = @CurrencyId
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.Barcode = @Barcode;
END
GO

CREATE OR ALTER PROCEDURE dbo.API_Product_List
    @Search NVARCHAR(100) = NULL,
    @CurrencyId INT,
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
        s.ProductName AS Product,
        ss.VariantCode,
        ListPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        UnitPrice = CASE @CurrencyId
            WHEN 1 THEN s.PriceTL
            WHEN 2 THEN s.PriceEUR
            WHEN 3 THEN s.PriceUSD
        END,
        StockQty = ISNULL(st.StockQty, 0),
        CurrencyId = @CurrencyId
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.SizeId IS NOT NULL
      AND (
          @Search IS NULL
       OR @Search = N''
       OR s.ProductName LIKE N'%' + @Search + N'%'
       OR ss.Barcode LIKE N'%' + @Search + N'%')
    ORDER BY s.ProductName, ss.SizeId
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

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

PRINT '=== CavalierShop migration completed ===';
GO
