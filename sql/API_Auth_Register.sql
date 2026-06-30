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
