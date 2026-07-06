/*
================================================================================
 CavalierShop — Tablo şema migration (ALTER TABLE)
================================================================================
 Canlı veritabanında tablo değişiklikleri bu dosyada idempotent ALTER olarak
 tutulur. Veri silmez.

 SP tanımları: sql/Migrate_StoredProcedures.sql

 Kullanım: SSMS'te CavaliERP veritabanında Execute (F5)
================================================================================
*/

SET NOCOUNT ON;
GO

PRINT '--- Sales.OrderRequestId ---';
GO

IF COL_LENGTH('dbo.Sales', 'OrderRequestId') IS NULL
BEGIN
    ALTER TABLE dbo.Sales ADD OrderRequestId INT NULL;
    PRINT 'Sales.OrderRequestId column added.';
END
ELSE
    PRINT 'Sales.OrderRequestId already exists.';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_Sales_OrderRequests'
      AND parent_object_id = OBJECT_ID(N'dbo.Sales')
)
BEGIN
    ALTER TABLE dbo.Sales
    ADD CONSTRAINT FK_Sales_OrderRequests
        FOREIGN KEY (OrderRequestId) REFERENCES dbo.OrderRequests (OrderRequestId);
    PRINT 'FK_Sales_OrderRequests created.';
END
ELSE
    PRINT 'FK_Sales_OrderRequests already exists.';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Sales_OrderRequestId'
      AND object_id = OBJECT_ID(N'dbo.Sales')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Sales_OrderRequestId
        ON dbo.Sales (OrderRequestId)
        WHERE OrderRequestId IS NOT NULL;
    PRINT 'IX_Sales_OrderRequestId created.';
END
ELSE
    PRINT 'IX_Sales_OrderRequestId already exists.';
GO

PRINT '--- Sales.DiscountPercent / DiscountFixedAmount ---';
GO

IF COL_LENGTH('dbo.Sales', 'DiscountPercent') IS NULL
BEGIN
    ALTER TABLE dbo.Sales
    ADD DiscountPercent DECIMAL(5, 2) NOT NULL
        CONSTRAINT DF_Sales_DiscountPercent DEFAULT (0);
    PRINT 'Sales.DiscountPercent column added.';
END
ELSE
    PRINT 'Sales.DiscountPercent already exists.';
GO

IF COL_LENGTH('dbo.Sales', 'DiscountFixedAmount') IS NULL
BEGIN
    ALTER TABLE dbo.Sales
    ADD DiscountFixedAmount DECIMAL(18, 2) NOT NULL
        CONSTRAINT DF_Sales_DiscountFixedAmount DEFAULT (0);
    PRINT 'Sales.DiscountFixedAmount column added.';
END
ELSE
    PRINT 'Sales.DiscountFixedAmount already exists.';
GO

PRINT '=== Table migration completed ===';
GO
