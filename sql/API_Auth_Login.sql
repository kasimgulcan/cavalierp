CREATE OR ALTER PROCEDURE dbo.API_Auth_Login
    @Email NVARCHAR(256),
    @Password NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role
    FROM dbo.Users u
    WHERE u.Email = @Email
      AND u.PasswordHash = HASHBYTES('SHA2_256', @Password)
      AND u.Status <> N'Rejected';
END
GO
