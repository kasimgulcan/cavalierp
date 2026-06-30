-- CSM.Stok — Sales + SaleLines (mobil satış kaydı)
-- Önce: Create_Users.sql, Create_PaymentTypes.sql (Currencies mevcut ERP tablosu)

IF OBJECT_ID(N'dbo.Sales', N'U') IS NOT NULL
    DROP TABLE dbo.Sales;
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

IF OBJECT_ID(N'dbo.SaleLines', N'U') IS NOT NULL
    DROP TABLE dbo.SaleLines;
GO

CREATE TABLE dbo.SaleLines
(
    SaleLineId INT            IDENTITY(1, 1) NOT NULL,
    SaleId     INT            NOT NULL,
    SizeId     INT            NOT NULL,
    Product    NVARCHAR(300)  NOT NULL,
    Quantity   INT            NOT NULL,
    UnitPrice  DECIMAL(18, 2) NOT NULL,
    ListPrice  DECIMAL(18, 2) NOT NULL,
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
