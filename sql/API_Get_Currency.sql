CREATE OR ALTER PROCEDURE dbo.API_Get_Currency
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.CurrencyId, c.Code, c.Name
    FROM dbo.Currencies c
    ORDER BY c.CurrencyId;
END
GO
