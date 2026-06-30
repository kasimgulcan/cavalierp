CREATE OR ALTER PROCEDURE dbo.API_Lookup_PaymentTypes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pt.PaymentTypeId, pt.Name
    FROM dbo.PaymentTypes pt
    ORDER BY pt.Name;
END
GO
