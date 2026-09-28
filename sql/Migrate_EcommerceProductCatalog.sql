-- Ecommerce product catalog snapshot (05.09.2026)
-- Wrapper: GetSKU + GetSKU_ModelReference (üç result set).

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.GetSKUSnapshot
    @Since datetimeoffset(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.GetSKU @Since = @Since;
    EXEC dbo.GetSKU_ModelReference @Since = @Since;
END
GO
