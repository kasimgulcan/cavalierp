-- CSM.Stok — Ödeme tipleri (tüm tenant'lar için ortak)

IF OBJECT_ID(N'dbo.PaymentTypes', N'U') IS NOT NULL
    DROP TABLE dbo.PaymentTypes;
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
