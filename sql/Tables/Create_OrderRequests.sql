-- CavalierShop — Sipariş talepleri (stok düşmez)

IF OBJECT_ID(N'dbo.OrderRequestLines', N'U') IS NOT NULL
    DROP TABLE dbo.OrderRequestLines;
GO

IF OBJECT_ID(N'dbo.OrderRequests', N'U') IS NOT NULL
    DROP TABLE dbo.OrderRequests;
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
