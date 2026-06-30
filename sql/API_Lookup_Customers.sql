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
