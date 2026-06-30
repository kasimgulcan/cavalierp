-- CSM.Stok — Stok girişleri
-- Satış çıkışları SaleLines üzerinden; güncel stok V_SizeStock view'ında hesaplanır.
-- Önce Sales/SaleLines tabloları oluşturulmuş olmalı (view için).

IF OBJECT_ID(N'dbo.StockEntries', N'U') IS NOT NULL
    DROP TABLE dbo.StockEntries;
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

IF OBJECT_ID(N'dbo.V_SizeStock', N'V') IS NOT NULL
    DROP VIEW dbo.V_SizeStock;
IF OBJECT_ID(N'dbo.vw_SizeStock', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SizeStock;
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
